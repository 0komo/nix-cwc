{
  lib,
  stdenv,
  fetchFromGitHub,
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
}:

let
  luaEnv = luajit.withPackages (
    p: with p; [
      lgi
    ]
  );
in
stdenv.mkDerivation (self: {
  pname = "cwc";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "Cudiph";
    repo = "cwcwm";
    rev = "v${self.version}";
    hash = "sha256-qkhlxk2t1cBs3VO6VwJicuhxUa12w+FTvVoCSLpWX1Q=";
    leaveDotGit = true;
  };

  patches = lib.pipe (builtins.readDir ./.) [
    builtins.attrNames
   (builtins.filter (s: lib.hasSuffix ".patch" s))
   (map (s: ./${s} ))
  ];

  nativeBuildInputs = [
    git
    gobject-introspection
    meson
    ninja
    makeWrapper
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
    luajit
    luaEnv
    libinput
    libxkbcommon
    pango
    wlroots_0_19
    wayland
    wayland-scanner
    xxHash
    (with xorg; [
      libxcb
      xcbutilwm
    ])
    xwayland
  ];

  mesonFlags = [
    "-Dplugins=true"
    # fix missing drm_fourcc.h header
    "-Dc_args=-I${libdrm.dev}/include/libdrm"
  ];

  mesonBuildType = "release";

  postPatch = ''
    substituteInPlace ./{,src,cwctl}/meson.build \
      --replace-fail "/usr" "$out"

    substituteInPlace ./src/luac.c \
      --subst-var-by LUA_ENV "${luaEnv}"
  '';

  postConfigure = ''
    rm -fr .git
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "$out/share/cwc/plugins"
    )
  '';

  meta.mainProgram = "cwc";
})
