## programs\.cwc\.enable

Whether to enable CwC, extensible Wayland compositor that highly influenced by Awesome window manager\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `



## programs\.cwc\.package



The cwc package to use\. Which package to install the CwC compositor\.



*Type:*
package



*Default:*
` pkgs.cwc `



## programs\.cwc\.withUWSM



Launch CwC with UWSM (Universal Wayland Session Manager) session manager\.
This has improved systemd support and is recommended for most users\.
This automatically starts appropiate targets like ` graphical-session.target `,
and ` wayland-session@CwC.target `\.

> [!Note]
> Some changes may need to be made to CwC config depending on your setup\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `


