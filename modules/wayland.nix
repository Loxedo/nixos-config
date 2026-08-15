{ config, pkgs, inputs, ... }:

let
  somewm = inputs.self.packages.${pkgs.system}.somewm or (import ../pkgs/somewm.nix { inherit pkgs; src = inputs.somewm; });
in {
  environment.systemPackages = [
    somewm
    pkgs.wl-clipboard
    pkgs.wayland-utils
    pkgs.wtype
    pkgs.xdg-utils
    pkgs.xdg-desktop-portal
    pkgs.xdg-desktop-portal-gtk
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd somewm";
        user = "greeter";
      };
    };
  };

  security.polkit.enable = true;
}
