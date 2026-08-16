{ pkgs, src, version, wlrootsVersion }:

let
  lgi = pkgs.lua51Packages.lgi;
  lua = pkgs.lua5_1;
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

  # SomeWM's release/1.4 branch performs a real C-based LGI probe during
  # Meson configuration. Keep Lua and LGI on the exact same Lua 5.1 package
  # set and expose both the Lua module tree and LGI's native module tree.
  LUA_PATH = "${lgi}/share/lua/5.1/?.lua;${lgi}/share/lua/5.1/?/init.lua;;";
  LUA_CPATH = "${lgi}/lib/lua/5.1/?.so;${lgi}/lib/lua/5.1/lgi/?.so;;";

  # Do not override PKG_CONFIG_PATH here. Nix's build environment already adds
  # every build input's pkgconfig directory; replacing it makes Meson unable to
  # discover wlroots, Wayland, Cairo, GLib, etc., which presents as misleading
  # "wlroots not found" errors even when the package is in buildInputs.

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
