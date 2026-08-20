{ pkgs, src, version, wlrootsVersion }:

let
  lua = pkgs.lua5_3;
  lgi = pkgs.lua53Packages.lgi;
  wlroots = pkgs."wlroots_${builtins.replaceStrings [ "." ] [ "_" ] wlrootsVersion}";
  giTypelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.glib
    pkgs.cairo
    pkgs.pango
    pkgs.gdk-pixbuf
  ];
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
    makeWrapper
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

  # Build-time paths are needed for Meson/configuration and runtime LGI discovery.
  LUA_PATH = "${lgi}/share/lua/5.3/?.lua;${lgi}/share/lua/5.3/?/init.lua;;";
  LUA_CPATH = "${lgi}/lib/lua/5.3/?.so;${lgi}/lib/lua/5.3/lgi/?.so;;";

  postInstall = ''
    wrapProgram "$out/bin/somewm" \
      --set LUA_PATH "${lgi}/share/lua/5.3/?.lua;${lgi}/share/lua/5.3/?/init.lua;;" \
      --set LUA_CPATH "${lgi}/lib/lua/5.3/?.so;${lgi}/lib/lua/5.3/lgi/?.so;;" \
      --set GI_TYPELIB_PATH "${giTypelibPath}"

    env \
      LUA_PATH="${lgi}/share/lua/5.3/?.lua;${lgi}/share/lua/5.3/?/init.lua;;" \
      LUA_CPATH="${lgi}/lib/lua/5.3/?.so;${lgi}/lib/lua/5.3/lgi/?.so;;" \
      GI_TYPELIB_PATH="${giTypelibPath}" \
      ${lua}/bin/lua -e 'local lgi = require("lgi"); assert(lgi.GLib, "LGI loaded without GLib")'
  '';

  mesonBuildType = "release";

  mesonFlags = [
    "-Db_sanitize=none"
    "-Dwlroots_version=${wlrootsVersion}"
    "-Dxwayland=enabled"
    "-Dpam=enabled"
    "-Dlua_pkg=lua5.3"
  ];

  # SomeWM 1.4.3 does not ship the helper scripts used by the old package
  # check. Keep the check deterministic: verify that the build produced an
  # executable compositor instead of invoking unavailable test files.
  doCheck = true;
  checkPhase = ''
    runHook preCheck

    somewm_bin="$(find . -type f -name somewm -perm -u+x -print -quit)"
    if [ -z "$somewm_bin" ]; then
      echo "error: could not find the built SomeWM executable" >&2
      find . -maxdepth 3 -type f -perm -u+x -print >&2
      exit 1
    fi

    echo "SomeWM build check: found $somewm_bin"

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
