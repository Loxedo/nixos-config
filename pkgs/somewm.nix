{ pkgs, src, version, wlrootsVersion }:

let
  lgi = pkgs.lua51Packages.lgi;
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
    lua5_1
    pixman
    libdisplay-info
    udev
    seatd
    libxcb-wm
    xcbutil
  ] ++ [ lgi wlroots ];

  LUA_PATH = "${lgi}/share/lua/5.1/?.lua;${lgi}/share/lua/5.1/?/init.lua;;";
  LUA_CPATH = "${lgi}/lib/lua/5.1/lgi/?.so;;";
  PKG_CONFIG_PATH = "${lgi}/lib/pkgconfig";

  mesonBuildType = "release";

  mesonFlags = [
    "-Db_sanitize=none"
    "-Dwlroots_version=${wlrootsVersion}"
    "-Dxwayland=enabled"
    "-Dpam=enabled"
    "-Dlua_pkg=lua5.1"
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
