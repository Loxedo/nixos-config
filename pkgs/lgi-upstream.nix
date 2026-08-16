{ pkgs, src }:

pkgs.stdenv.mkDerivation {
  pname = "lua5.1-lgi";
  version = "0.9.2-unstable-2026-02-05";
  inherit src;

  nativeBuildInputs = [ pkgs.pkg-config ];

  buildInputs = [
    pkgs.lua5_1
    pkgs.gobject-introspection
    pkgs.glib
    pkgs.libffi
  ];

  makeFlags = [
    "PREFIX=$(out)"
    "LUA_VERSION=5.1"
    "LUA_CFLAGS=-I${pkgs.lua5_1}/include"
    "LUA_LIB=-L${pkgs.lua5_1}/lib -llua"
  ];

  buildPhase = ''
    make -C lgi all ${pkgs.lib.concatStringsSep " " makeFlags}
  '';

  installPhase = ''
    make -C lgi install PREFIX=$out LUA_VERSION=5.1 \
      LUA_CFLAGS="-I${pkgs.lua5_1}/include" \
      LUA_LIB="-L${pkgs.lua5_1}/lib -llua"
  '';

  dontConfigure = true;

  meta = with pkgs.lib; {
    description = "Dynamic Lua binding to GObject libraries using GObject-Introspection";
    homepage = "https://github.com/lgi-devs/lgi";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
