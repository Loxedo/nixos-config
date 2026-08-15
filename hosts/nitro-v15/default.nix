{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/boot.nix
    ../../modules/graphics.nix
    ../../modules/wayland.nix
    ../../modules/audio.nix
    ../../modules/networking.nix
    ../../modules/storage.nix
    ../../modules/swap.nix
    ../../modules/gaming.nix
    ../../modules/razer.nix
    ../../modules/optimization.nix
  ];

  networking.hostName = "nitro-v15";

  time.timeZone = "America/Argentina/Buenos_Aires";
  i18n.defaultLocale = "es_AR.UTF-8";
  console.keyMap = "la-latin1";

  users.users.loxedo = {
    isNormalUser = true;
    description = "Loxedo";
    extraGroups = [ "wheel" "networkmanager" "video" "render" "input" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "loxedo" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 21d";
    };
  };

  documentation.nixos.enable = false;

  system.stateVersion = "26.05";
}
