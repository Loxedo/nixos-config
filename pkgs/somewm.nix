{ pkgs, src, version, wlrootsVersion }:

let
  # Use nixpkgs' Lua 5.1 LGI package. This keeps LGI and Lua in the same
  # package set and avoids the previous custom LGI derivation/path mismatch.
  lgi = pkgs.lua51Packages.lgi;
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
    wlroots_0_19
    xcbutilwm
    xcbutil
  ] ++ [ lgi ];

  # SomeWM's configure step compiles and runs lgi-check against the Lua 5.1
  # library. Meson's cc.run() inherits the build environment, so expose the
  # exact LGI package that belongs to the Lua interpreter used by SomeWM.
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
