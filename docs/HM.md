## wayland\.windowManager\.cwc\.enable

Whether to enable configurations for CwC, extensible Wayland compositor
that highly influenced by Awesome window manager\.

> [!Note]
> This module only configures CwC on user-level, it does not do any changes to the system\.
> NixOS users should use the NixOS module with ` programs.cwc.enable `
> to have CwC available as desktop session\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `



## wayland\.windowManager\.cwc\.package



The cwc package to use\. Set this to null if you want to use the NixOS module to install CwC\.



*Type:*
null or package



*Default:*
` pkgs.cwc `



## wayland\.windowManager\.cwc\.extraConfig



Extra configuration to add to ` ~/.config/cwc/rc.lua `\. Accepts
string and path\. When passing a path to a file, it’ll attempt to
load that file with ` loadfile `\.



*Type:*
strings concatenated with “\\n” or absolute path



*Default:*
` "" `



*Example:*

```
''
  local cuteful = require("cuteful")
  local enum_modifier = cuteful.enum.modifier
  local enum_mouse_btn = cuteful.enum.mouse_btn
  local pointer = cwc.pointer
  
  pointer.bind(enum_modifier.LOGO, enum_mouse_btn.LEFT, pointer.move_interactive, pointer.stop_interactive)
  pointer.bind(enum_modifier.LOGO, enum_mouse_btn.RIGHT, pointer.resize_interactive, pointer.stop_interactive)
''
```



## wayland\.windowManager\.cwc\.plugins



List of CwC plugins to use\. Can be either packages or
absolute path to plugins\.



*Type:*
list of (package or absolute path)



*Default:*
` [ ] `



## wayland\.windowManager\.cwc\.systemd\.enable



Whether to enable ` cwc-session.target ` on
CwC setup\. This links to ` graphical-session.target `\.
Some important environment variables will be imported to systemd
and D-Bus user environment before reaching target, including

 - ` DISPLAY `
 - ` CWC_SOCK `
 - ` WAYLAND_DISPLAY `
 - ` XDG_CURRENT_DESKTOP `



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `



## wayland\.windowManager\.cwc\.systemd\.enableXdgAutostart



Whether to enable autostart of application using [` systemd-xdg-autostart-generator(8) `](https://www.freedesktop.org/software/systemd/man/systemd-xdg-autostart-generator.html)\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `



## wayland\.windowManager\.cwc\.systemd\.extraCommands



Extra commands to be run after D-Bus activition\.



*Type:*
list of string



*Default:*

```
[
  "systemctl --user stop cwc-session.target"
  "systemctl --user start cwc-session.target"
]
```



## wayland\.windowManager\.cwc\.systemd\.variables



Environment variables to be imported in the systemd and
D-Bus user environment\.



*Type:*
list of string



*Default:*

```
[
  "DISPLAY"
  "CWC_SOCK"
  "WAYLAND_DISPLAY"
  "XDG_CURRENT_DESKTOP"
]
```



*Example:*

```
[
  "--all"
]
```


