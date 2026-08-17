{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "lua-pam";
  version = "local";

  src = ./lua-pam;

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.lua5_3 pkgs.pam ];

  buildPhase = ''
    runHook preBuild
    $CXX -shared -fPIC \
      -I${pkgs.lua5_3}/include \
      -I${pkgs.pam}/include \
      main.cpp \
      -L${pkgs.lua5_3}/lib -llua \
      -L${pkgs.pam}/lib -lpam \
      -o liblua_pam.so
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/lua/5.3
    install -Dm755 liblua_pam.so $out/lib/lua/5.3/liblua_pam.so
    runHook postInstall
  '';
}
