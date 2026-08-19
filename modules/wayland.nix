{ pkgs, inputs, ... }:
let
  somewm = inputs.self.packages.${pkgs.system}.somewm-stable;

  somewmSession = pkgs.writeShellScriptBin "somewm-session" ''
    set -eu

    export XDG_SESSION_TYPE="wayland"
    export XDG_CURRENT_DESKTOP="SomeWM"
    export XDG_SESSION_DESKTOP="SomeWM"

    # Escape the shell parameter expansion so Nix leaves it for the script.
    cache_home="''${XDG_CACHE_HOME:-$HOME/.cache}"
    cache_dir="$cache_home/awesome"
    mkdir -p "$cache_dir/json" "$cache_dir/lock" "$HOME/Pictures/Screenshots"

    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user import-environment \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_DESKTOP \
        XDG_SESSION_TYPE 2>/dev/null || true
    fi

    # Propagate the compositor's Wayland environment to D-Bus-activated user
    # services and desktop portals. Without this, portals may start without a
    # valid WAYLAND_DISPLAY even though the compositor session itself is fine.
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      WAYLAND_DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_DESKTOP \
      XDG_SESSION_TYPE 2>/dev/null || true

    exec ${pkgs.dbus}/bin/dbus-run-session -- ${somewm}/bin/somewm
  '';
in
{
  environment.systemPackages = with pkgs; [
    somewmSession
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
    config.common = {
      # GTK implements the general portal interfaces; wlr is selected only
      # where it provides Wayland-native ScreenCast/Screenshot handling.
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" "gtk" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" "gtk" ];
    };
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${somewmSession}/bin/somewm-session";
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
