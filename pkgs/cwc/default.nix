{
  lib,
  stdenv,
  fetchFromGitHub,
  # Options
  withLuaEnv ? null,
  # Build-time dependencies
  git,
  gobject-introspection,
  makeWrapper,
  meson,
  ninja,
  pkg-config,
  python3Packages,
  wayland-protocols,
  wrapGAppsNoGuiHook,
  # Runtime dependencies
  cairo,
  gdk-pixbuf,
  hyprcursor,
  luajit,
  libdrm,
  libinput,
  libxkbcommon,
  pango,
  wlroots_0_19,
  wayland,
  wayland-scanner,
  xxHash,
  xorg,
  xwayland,
}@attrs:

let
  _unused = [ withLuaEnv ];

  inherit (builtins)
    readFile
    fromTOML
    substring
    elemAt
    ;
  luaEnv = attrs.withLuaEnv or luajit.withPackages (
    p: with p; [
      lgi
    ]
  );
  latestCommit = elemAt (fromTOML (readFile ../../commit.toml)).commits 0;

  mkLuaPath =
    env: isNativeMod:
    if isNativeMod then
      "${env}/lib/lua/5.1/?.so;;"
    else
      "${env}/share/lua/5.1/?.lua;${env}/share/lua/5.1/?/init.lua;;";
in
stdenv.mkDerivation (self: {
  name = "cwc";
  version = "0-unstable-${substring 0 6 latestCommit.rev}";

  src = fetchFromGitHub {
    owner = "Cudiph";
    repo = "cwcwm";
    inherit (latestCommit)
      rev
      hash
      ;
  };

  nativeBuildInputs = [
    git
    gobject-introspection
    makeWrapper
    meson
    ninja
    pkg-config
    python3Packages.python
    wayland-protocols
    wrapGAppsNoGuiHook
  ];

  buildInputs = lib.flatten [
    cairo
    gdk-pixbuf
    hyprcursor
    libdrm
    libinput
    libxkbcommon
    luajit
    pango
    wayland
    wayland-scanner
    wlroots_0_19
    (with xorg; [
      libxcb
      xcbutilwm
    ])
    xwayland
    xxHash
  ];

  mesonFlags = [
    "-Dplugins=true"
  ];

  mesonBuildType = "release";

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "$out/share/cwc/plugins"
      --prefix LUA_PATH ';' "${mkLuaPath self.passthru.luaEnv false}"
      --prefix LUA_CPATH ';' "${mkLuaPath self.passthru.luaEnv true}"
    )
  '';

  passthru = {
    inherit luaEnv;
  };

  meta.mainProgram = "cwc";
})
