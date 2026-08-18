{ pkgs, src, version, wlrootsVersion }:

let
  lua = pkgs.lua5_3;
  lgi = pkgs.lua53Packages.lgi;
  wlroots = pkgs."wlroots_${builtins.replaceStrings [ "." ] [ "_" ] wlrootsVersion}";
  giTypelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.gdk-pixbuf
    pkgs.glib.out
    pkgs.gobject-introspection
    pkgs.pango
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

  # These variables are needed while configuring/building SomeWM. They do not
  # automatically become part of the installed program's runtime environment.
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

    somewm_bin="$(find . -type f -name somewm -perm -u+x -print -quit)"
    if [ -z "$somewm_bin" ]; then
      echo "error: could not find the built SomeWM executable" >&2
      find . -maxdepth 3 -type f -perm -u+x -print >&2
      exit 1
    fi

    ./tests/test-check-mode.sh "$somewm_bin"
    LIBSEAT_BACKEND=noop ./tests/test-signal-term.sh "$somewm_bin"

    runHook postCheck
  '';

  postFixup = ''
    wrapProgram "$out/bin/somewm" \
      --prefix LUA_PATH : "${lgi}/share/lua/5.3/?.lua;${lgi}/share/lua/5.3/?/init.lua" \
      --prefix LUA_CPATH : "${lgi}/lib/lua/5.3/?.so;${lgi}/lib/lua/5.3/lgi/?.so" \
      --prefix GI_TYPELIB_PATH : "${giTypelibPath}"
  '';

  meta = with pkgs.lib; {
    description = "Lua-scriptable Wayland compositor compatible with AwesomeWM";
    homepage = "https://somewm.org/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "somewm";
  };
}
