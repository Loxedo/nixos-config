{ pkgs, inputs, ... }:

{
  home.username = "loxedo";
  home.homeDirectory = "/home/loxedo";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    kitty
    rofi-wayland
    waybar
    wlogout
    swaylock
    playerctl
    brightnessctl
    pamixer
    imagemagick
    libnotify
    jq
    ripgrep
    fd
    fzf
    git
    wget
    curl
    unzip
    p7zip
    mpd
    mpc
    ncmpcpp
    neofetch
    lm_sensors
    btop
    fastfetch
    networkmanagerapplet
    blueman
  ];

  programs.git.enable = true;
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;
  };

  # Crystal Aura is tracked as a flake input. We materialize it as the
  # Awesome-compatible configuration directory for SomeWM.
  xdg.configFile."awesome" = {
    source = inputs.crystal;
    recursive = true;
  };

  # Wayland-specific overrides live outside upstream Crystal so upgrades are
  # isolated and easy to review.
  xdg.configFile."somewm/aura-override.lua".text = ''
    -- Local Wayland adaptation placeholder.
    -- Keep this separate from upstream Crystal Aura so upstream updates remain clean.
  '';

  # Per-user launcher helper for explicit NVIDIA offload.
  home.file.".local/bin/nvidia-run" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec nvidia-offload "$@"
    '';
  };
}
