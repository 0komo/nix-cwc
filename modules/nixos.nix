{
  mkPackageSet,
  nixpkgsPath,
  ...
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.cwc;
in
{
  options.programs.cwc = {
    enable = lib.mkEnableOption "CwC, extensible Wayland compositor that highly influenced by Awesome window manager";

    package = lib.mkPackageOption (mkPackageSet pkgs) "cwc" {
      extraDescription = ''
        Which package to install the CwC compositor.
      '';
    };

    withUWSM = lib.mkEnableOption null // {
      description = ''
        Launch CwC with UWSM (Universal Wayland Session Manager) session manager.
        This has improved systemd support and is recommended for most users.
        This automatically starts appropiate targets like `graphical-session.target`,
        and `wayland-session@CwC.target`.

        ::: {.note}
        Some changes may need to be made to CwC config depending on your setup.
        :::
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ cfg.package ];

        xdg.portal.enable = true;
        xdg.portal.configPackages = lib.mkDefault [ cfg.package ];
      }

      (lib.mkIf cfg.withUWSM {
        programs.uwsm.enable = true;
        programs.uwsm.waylandCompositors = {
          cwc = {
            prettyName = "CwC";
            comment = "CwC compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/cwc";
          };
        };
      })

      (lib.mkIf (!cfg.withUWSM) {
        services.displayManager.sessionPackages = [ cfg.package ];
      })

      (import (nixpkgsPath + "/nixos/modules/programs/wayland/wayland-session.nix") {
        inherit lib pkgs;
      })
    ]
  );
}
