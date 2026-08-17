{ pkgs, inputs, lib, ... }:

let
  luaPam = import ../../pkgs/lua-pam.nix { inherit pkgs; };

  crystalWayland = pkgs.runCommand "crystal-aura-wayland" {} ''
    cp -R ${inputs.crystal}/. $out
    chmod -R u+w "$out"

    rm -f "$out/rc.lua"
    cp ${./crystal/rc.lua} "$out/rc.lua"

    rm -f "$out/main/autorun.sh"
    mkdir -p "$out/main"
    cp ${./crystal/autorun.sh} "$out/main/autorun.sh"
    chmod +x "$out/main/autorun.sh"

    cp ${./crystal/scrotter.lua} "$out/ui/popups/scrotter.lua"

    mkdir -p "$out/ui/lock"
    cp ${./crystal/lock-init.lua} "$out/ui/lock/init.lua"

    # The upstream tree contains a prebuilt PAM module. Do not depend on that
    # binary: build the module with the exact Lua/PAM libraries from nixpkgs.
    rm -f "$out/liblua_pam.so"
    cp ${luaPam}/lib/lua/5.3/liblua_pam.so "$out/liblua_pam.so"
  '';

  somewm = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.somewm-stable;
in
{
  home.username = "loxedo";
  home.homeDirectory = "/home/loxedo";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    alacritty
    brave
    fishPlugins.fzf
    rofi
    wlogout
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
    btop
    fastfetch
    lm_sensors
    networkmanagerapplet
    grim
    slurp
    wl-clipboard
  ];

  programs.git.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
      alias rebuild 'sudo nixos-rebuild switch --flake ~/nixos-config#nitro-v15'
      alias update 'cd ~/nixos-config; nix flake update; sudo nixos-rebuild switch --flake .#nitro-v15'
      alias nvidia-run 'nvidia-offload'
      alias wifi-on 'nmcli radio wifi on'
      alias wifi-off 'nmcli radio wifi off'
      alias bt-on 'rfkill unblock bluetooth'
    '';
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.96;
      font.normal.family = "JetBrainsMono Nerd Font";
      font.size = 11;
    };
  };

  xdg.configFile."awesome" = {
    source = crystalWayland;
    recursive = true;
  };

  home.activation.createScreenshotDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Pictures/Screenshots"
  '';

  home.file.".local/bin/nvidia-run" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec nvidia-offload "$@"
    '';
  };
}
