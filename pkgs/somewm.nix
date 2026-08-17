{ pkgs, src, version, wlrootsVersion }:

let
  lua = pkgs.lua5_4;
  lgi = pkgs.lua54Packages.lgi;
  wlroots = pkgs."wlroots_${builtins.replaceStrings [ "." ] [ "_" ] wlrootsVersion}";
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
    lua
    pixman
    libdisplay-info
    udev
    seatd
    libxcb-wm
    xcbutil
    lgi
    wlroots
  ];

  # Somewm requiere Lua 5.2+ para constantes de C como LUA_OK. 
  # Se actualiza el entorno a Lua 5.4 y se exportan las rutas del modulo LGI 5.4.
  LUA_PATH = "${lgi}/share/lua/5.4/?.lua;${lgi}/share/lua/5.4/?/init.lua;;";
  LUA_CPATH = "${lgi}/lib/lua/5.4/?.so;${lgi}/lib/lua/5.4/lgi/?.so;;";

  mesonBuildType = "release";

  mesonFlags = [
    "-Db_sanitize=none"
    "-Dwlroots_version=${wlrootsVersion}"
    "-Dxwayland=enabled"
    "-Dpam=enabled"
    "-Dlua_pkg=lua5.4"
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