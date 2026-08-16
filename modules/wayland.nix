{ pkgs, inputs, ... }:
let
  somewm = inputs.self.packages.${pkgs.system}.somewm-stable;
in
{
  environment.systemPackages = with pkgs; [
    somewm
    wl-clipboard
    wayland-utils
    wtype
    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    libsecret
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "wlr";
    config.common = {
      "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      "org.freedesktop.impl.portal.Screenshot" = "wlr";
    };
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd ${somewm}/bin/somewm";
        user = "greeter";
      };
    };
  };

  security.polkit.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
