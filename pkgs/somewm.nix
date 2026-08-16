{ pkgs, src, version, wlrootsVersion }:
pkgs.stdenv.mkDerivation {
  pname = "somewm";
  inherit version src;

  nativeBuildInputs = with pkgs; [
    meson
    ninja
    pkg-config
    wayland-scanner
    git
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
    lgi
    pixman
    libdisplay-info
    udev
    seatd
  ];

  mesonFlags = [
    "-Dbuildtype=release"
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
