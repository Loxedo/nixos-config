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

    # systemd --user talks to the user's real bus at $XDG_RUNTIME_DIR/bus.
    # Do not run these commands inside dbus-run-session: that command creates
    # a separate private session bus which is not the systemd user-manager bus.
    user_bus="unix:path=''${XDG_RUNTIME_DIR:-}/bus"
    if [ -n "''${XDG_RUNTIME_DIR:-}" ] && [ -S "$XDG_RUNTIME_DIR/bus" ] && command -v systemctl >/dev/null 2>&1; then
      DBUS_SESSION_BUS_ADDRESS="$user_bus" systemctl --user import-environment \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_DESKTOP \
        XDG_SESSION_TYPE 2>/dev/null || true

      # SomeWM is launched from greetd rather than by the user manager, so
      # explicitly activate the graphical-session target on the real user bus.
      DBUS_SESSION_BUS_ADDRESS="$user_bus" systemctl --user start graphical-session.target 2>/dev/null || true

      DBUS_SESSION_BUS_ADDRESS="$user_bus" ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_DESKTOP \
        XDG_SESSION_TYPE 2>/dev/null || true
    fi

    # Some applications need a session D-Bus even when greetd did not create
    # one. dbus-run-session provides that bus for SomeWM and its children.
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
