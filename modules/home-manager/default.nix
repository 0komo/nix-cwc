{
  mkPackageSet,
  ...
}:
{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.wayland.windowManager.cwc;
in
{
  options.wayland.windowManager.cwc = {
    enable = lib.mkEnableOption null // {
      description = ''
        Whether to enable configurations for CwC, extensible Wayland compositor
        that highly influenced by Awesome window manager.

        ::: {.note}
        This module only configures CwC on user-level, it does not do any changes to the system.
        NixOS users should use the NixOS module with {option}`programs.cwc.enable`
        to have CwC available as desktop session.
        :::
      '';
    };

    package = lib.mkPackageOption (mkPackageSet pkgs) "cwc" {
      nullable = true;
      extraDescription = "Set this to null if you want to use the NixOS module to install CwC.";
    };

    plugins = lib.mkOption {
      type = with lib.types; listOf (either package path);
      default = [ ];
      description = ''
        List of CwC plugins to use. Can be either packages or
        absolute path to plugins.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption null // {
        default = true;
        example = false;
        description = ''
          Whether to enable `cwc-session.target` on
          CwC setup. This links to `graphical-session.target`.
          Some important environment variables will be imported to systemd
          and D-Bus user environment before reaching target, including
          - `DISPLAY`
          - `CWC_SOCK`
          - `WAYLAND_DISPLAY`
          - `XDG_CURRENT_DESKTOP`
        '';
      };

      variables = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "DISPLAY"
          "CWC_SOCK"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
        ];
        example = [ "--all" ];
        description = ''
          Environment variables to be imported in the systemd and
          D-Bus user environment.
        '';
      };

      extraCommands = lib.mkOption {
        type = with lib.types; listOf str;
        default = map (s: "systemctl --user ${s} cwc-session.target") [
          "stop"
          "start"
        ];
        description = "Extra commands to be run after D-Bus activition.";
      };

      enableXdgAutostart = lib.mkEnableOption "autostart of application using {manpage}`systemd-xdg-autostart-generator(8)`";
    };

    extraConfig = lib.mkOption {
      type = with lib.types; either lines path;
      default = "";
      example = ''
        local cuteful = require("cuteful")
        local enum_modifier = cuteful.enum.modifier
        local enum_mouse_btn = cuteful.enum.mouse_btn
        local pointer = cwc.pointer

        pointer.bind(enum_modifier.LOGO, enum_mouse_btn.LEFT, pointer.move_interactive, pointer.stop_interactive)
        pointer.bind(enum_modifier.LOGO, enum_mouse_btn.RIGHT, pointer.resize_interactive, pointer.stop_interactive)
      '';
      description = ''
        Extra configuration to add to `~/.config/cwc/rc.lua`. Accepts
        string and path. When passing a path to a file, it'll attempt to
        load that file with `loadfile`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertations = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.cwc" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [
      cfg.package
      pkgs.xwayland
    ];

    xdg.configFile."cwc/rc.lua" =
      let
        onStartup = list: ''
          if cwc.is_startup() then
            ${lib.concatLines list}
          end
        '';

        variables = builtins.concatStringsSep " " cfg.systemd.variables;
        extraCommands = builtins.concatStringsSep " " (map (s: "&& ${s}") cfg.systemd.extraCommands);
        systemdActivation = ''
          cwc.spawn_program_with_shell [[
            ${pkgs.dbus}/bin/dbus-update-activition-environment --systemd ${variables} ${extraCommands}
          ]]
        '';

        plugins = lib.concatLines (
          map (
            x:
            let
              entry = if lib.types.package.check x then "${x}/lib/lib${x.pname}" else x;
            in
            "cwc.plugin.load [[${entry}]]"
          )
        );

        shouldGenerate = cfg.systemd.enable || cfg.extraConfig != "" || cfg.plugins != [ ];
      in
      lib.mkIf shouldGenerate ({
        text = lib.concatLines [
          (onStartup [
            (lib.optionalString cfg.systemd.enable systemdActivation)
            (lib.optionalString (cfg.plugins != [ ]) plugins)
          ])

          (lib.optionalString (cfg.extraConfig != "") (
            if builtins.isPath cfg.extraConfig then
              ''
                do
                  local procall = require("gears").protected_call
                  local fn = procall(assert, loadfile [[${cfg.extraConfig}]])
                  if fn then
                    fn()
                  end
                end
              ''
            else
              cfg.extraConfig
          ))
        ];

        onChange = lib.mkIf (cfg.package != null) ''
          _change() {
            local socks_location exit_code=0

            XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
            if [[ -f /tmp/cwc*.sock ]]; then
              socks_location=/tmp
            else
              socks_location="$XDG_RUNTIME_DIR"
            fi

            [[ -z "$socks_location" ]] && return

            for f in "$socks_location"/cwc*.sock; do
              ${cfg.package}/bin/cwctl -s "$f" -c "cwc.commit()" ||
                exit_code="$?"
              (( exit_code == 255 )) && return -1
            done
          }

          (_change)
        '';
      });

    xdg.portal.enable = cfg.package != null;
    xdg.portal.configPackages = lib.mkIf (cfg.package != null) (lib.mkDefault [ cfg.package ]);

    systemd.user.targets.cwc-session = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "CwC compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [
          "graphical-session-pre.target"
        ] ++ lib.optional cfg.systemd.enableXdgAutostart "xdg-desktop-autostart.target";
        After = [ "graphical-session-pre.target" ];
        Before = lib.mkIf cfg.systemd.enableXdgAutostart [ "xdg-desktop-autostart.target" ];
      };
    };
  };
}
