{ pkgs, src, lgiSrc, version, wlrootsVersion }:

let
  lgi = import ./lgi-upstream.nix {
    inherit pkgs;
    src = lgiSrc;
  };
in
pkgs.stdenv.mkDerivation {
  pname = "somewm";
  inherit version src;

  nativeBuildInputs = with pkgs; [
    meson
    ninja
    pkg-config
    wayland-scanner
    git
    gobject-introspection
  ];

  buildInputs = with pkgs; [
    wayland
    wayland-protocols
    libinput
    libdrm
    libxkbcommon
    dbus
    glib
    cairo
    pango
    gdk-pixbuf
    pam
    lua5_1
    pixman
    libdisplay-info
    udev
    seatd
    libxcb-wm
  ] ++ [ lgi ];

  # SomeWM's configure step compiles and runs lgi-check against Lua 5.1.
  # LGI installs its C module one directory below the Lua module root.
  LUA_PATH = "${lgi}/share/lua/5.1/?.lua;${lgi}/share/lua/5.1/?/init.lua";
  LUA_CPATH = "${lgi}/lib/lua/5.1/lgi/?.so";

  mesonBuildType = "release";

  mesonFlags = [
    "-Db_sanitize=none"
    "-Dwlroots_version=${wlrootsVersion}"
    "-Dxwayland=enabled"
    "-Dpam=enabled"
  ];

  doCheck = false;

  meta = with pkgs.lib; {
    description = "Lua-scriptable Wayland compositor compatible with AwesomeWM";
    homepage = "https://somewm.org/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "somewm";
  };
}
