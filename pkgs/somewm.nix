{ pkgs, src, version, wlrootsVersion }:

let
  lua = pkgs.lua5_3;
  lgi = pkgs.lua53Packages.lgi;
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
    systemd
    xwayland
  ];

  preConfigure = ''
    export PKG_CONFIG_SYSTEMD_SYSTEMDUSERUNITDIR="$out/lib/systemd/user"
    export PKG_CONFIG_SYSTEMD_SYSTEMDSYSTEMUNITDIR="$out/lib/systemd/system"
  '';

  LUA_PATH = "${lgi}/share/lua/5.3/?.lua;${lgi}/share/lua/5.3/?/init.lua;;";
  LUA_CPATH = "${lgi}/lib/lua/5.3/?.so;${lgi}/lib/lua/5.3/lgi/?.so;;";

  mesonBuildType = "release";

  mesonFlags = [
    "-Db_sanitize=none"
    "-Dwlroots_version=${wlrootsVersion}"
    "-Dxwayland=enabled"
    "-Dpam=enabled"
    "-Dlua_pkg=lua5.3"
  ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck

    ./tests/test-check-mode.sh "$out/bin/somewm"
    LIBSEAT_BACKEND=noop ./tests/test-signal-term.sh "$out/bin/somewm"

    runHook postCheck
  '';

  meta = with pkgs.lib; {
    description = "Lua-scriptable Wayland compositor compatible with AwesomeWM";
    homepage = "https://somewm.org/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "somewm";
  };
}