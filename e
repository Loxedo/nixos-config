[1mdiff --git a/README.md b/README.md[m
[1mindex 6291935..06d769a 100644[m
[1m--- a/README.md[m
[1m+++ b/README.md[m
[36m@@ -1,41 +1,61 @@[m
[31m-# NixOS — Acer Nitro V15 / Crystal Aura / Wayland[m
[32m+[m[32m# Loxedo NixOS — Acer Nitro ANV15-51[m
 [m
[31m-Personal, reproducible NixOS configuration for the Acer Nitro ANV15-51.[m
[32m+[m[32mReproducible NixOS configuration for an Acer Nitro ANV15-51 with:[m
 [m
[31m-## Hardware profile[m
[32m+[m[32m- Intel Core i7-13620H + Intel iGPU[m
[32m+[m[32m- NVIDIA GeForce RTX 4050 Laptop GPU[m
[32m+[m[32m- 16 GiB DDR5[m
[32m+[m[32m- WD SN740 1 TB NVMe[m
[32m+[m[32m- Intel eDP-1: 1920x1080 @ 165 Hz[m
[32m+[m[32m- NVIDIA HDMI-A-2: 1920x1080 @ 74.97 Hz[m
[32m+[m[32m- Btrfs + separate root/home/nix/swap subvolumes[m
[32m+[m[32m- Wayland + SomeWM + Crystal Aura[m
[32m+[m[32m- PipeWire + EasyEffects + xdg-desktop-portal-wlr[m
[32m+[m[32m- Steam / Proton / GameMode / Gamescope[m
[32m+[m[32m- Razer OpenRazer / Polychromatic[m
[32m+[m[32m- Fish + Alacritty + Brave[m
[32m+[m[32m- Declarative Flatpak + GoofCord[m
 [m
[31m-- Acer Nitro ANV15-51, firmware V1.52[m
[31m-- Intel Core i7-13620H[m
[31m-- Intel UHD Graphics, PCI `0000:00:02.0`[m
[31m-- NVIDIA GeForce RTX 4050 Laptop, PCI `0000:01:00.0`[m
[31m-- 16 GiB DDR5, 2×8 GiB[m
[31m-- WD PC SN740 1 TB NVMe[m
[31m-- Internal BOE 1920×1080 @ 165 Hz (`eDP-1`)[m
[31m-- External Samsung LF22T35 1920×1080 @ 74.97 Hz (`HDMI-A-2`)[m
[31m-- Razer BlackWidow V4 X `1532:0293`[m
[31m-- Razer BlackShark V2 HS USB `1532:056e`[m
[31m-- Attack Shark wireless mouse receiver `1d57:fa60`[m
[32m+[m[32m## Storage safety[m
 [m
[31m-## Design[m
[32m+[m[32mThe machine dual-boots Windows. The Windows NTFS partition and MSR partition are[m
[32m+[m[32mintentionally preserved. Disko targets **only `/dev/nvme0n1p2`**, the Linux Btrfs[m
[32m+[m[32mpartition, while the existing EFI System Partition is reused without formatting.[m
 [m
[31m-- NixOS + flakes[m
[31m-- Home Manager as a NixOS module[m
[31m-- Wayland compositor: SomeWM[m
[31m-- Desktop configuration: Crystal Aura, consumed from its upstream Git reference[m
[31m-- NVIDIA open kernel modules + PRIME offload[m
[31m-- PipeWire/WirePlumber[m
[31m-- zram-first memory pressure handling[m
[31m-- Steam/GameMode/MangoHud[m
[32m+[m[32mThe installer refuses to continue unless the expected PARTUUID/EFI UUID/Windows[m
[32m+[m[32mfilesystem checks succeed and the user types the exact confirmation string.[m
 [m
[31m-## Important GPU topology[m
[32m+[m[32m## Development workflow[m
 [m
[31m-The internal eDP panel is attached to the Intel GPU while the external HDMI connector is attached to the RTX 4050. This is not a simple all-displays-on-iGPU Optimus layout and must be validated with the Wayland compositor before the destructive install stage.[m
[32m+[m[32m```bash[m
[32m+[m[32mnix flake check[m
[32m+[m[32msudo nixos-rebuild build --flake .#nitro-v15[m
[32m+[m[32m```[m
 [m
[31m-## Upstream sources[m
[32m+[m[32mFor a clean installation from a NixOS live USB:[m
 [m
[31m-- Crystal Aura: https://github.com/namishh/crystal/tree/aura[m
[31m-- SomeWM: https://github.com/trip-zip/somewm[m
[32m+[m[32m```bash[m
[32m+[m[32mgit clone https://github.com/Loxedo/nixos-config.git[m
[32m+[m[32mcd nixos-config[m
[32m+[m[32m./scripts/install.sh[m
[32m+[m[32m```[m
 [m
[31m-## Status[m
[32m+[m[32mDo not run the installer until the hardware/Wayland validation has been completed.[m
 [m
[31m-This is the initial reproducible scaffold. The installer intentionally does **not** format disks yet. The next hardening pass should validate SomeWM + NVIDIA multi-GPU presentation, complete the Crystal Aura Wayland adaptations, finalize the fresh Btrfs partition scheme, and then enable the destructive installation stage.[m
[32m+[m[32m## GPU policy[m
[32m+[m
[32m+[m[32m- Intel handles the normal desktop workload.[m
[32m+[m[32m- NVIDIA is available through PRIME render offload.[m
[32m+[m[32m- The external HDMI display is physically wired to NVIDIA, so the RTX remains awake[m
[32m+[m[32m  whenever that display is active.[m
[32m+[m[32m- Explicit dGPU execution is available through `nvidia-offload` / `nvidia-run`.[m
[32m+[m
[32m+[m[32m## Memory policy[m
[32m+[m
[32m+[m[32m- zram: up to 75% of physical RAM, high priority[m
[32m+[m[32m- NVMe swapfile: 32 GiB, low priority[m
[32m+[m[32m- `vm.swappiness=150`[m
[32m+[m[32m- `systemd-oomd` enabled[m
[32m+[m
[32m+[m[32mThis is intentionally aggressive for heavy multitasking, but interactive applications[m
[32m+[m[32mare not forced entirely into swap.[m
[1mdiff --git a/flake.nix b/flake.nix[m
[1mindex b96e0e9..ef9e4eb 100644[m
[1m--- a/flake.nix[m
[1m+++ b/flake.nix[m
[36m@@ -3,35 +3,53 @@[m
 [m
   inputs = {[m
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";[m
[32m+[m
     home-manager = {[m
       url = "github:nix-community/home-manager/release-26.05";[m
       inputs.nixpkgs.follows = "nixpkgs";[m
     };[m
 [m
[31m-    # Crystal Aura is consumed as an input rather than copied into this repo.[m
[31m-    # This keeps provenance clear and avoids duplicating upstream source.[m
[32m+[m[32m    disko = {[m
[32m+[m[32m      url = "github:nix-community/disko/latest";[m
[32m+[m[32m      inputs.nixpkgs.follows = "nixpkgs";[m
[32m+[m[32m    };[m
[32m+[m
[32m+[m[32m    nix-flatpak.url = "github:gmodena/nix-flatpak";[m
[32m+[m
     crystal.url = "github:namishh/crystal/aura";[m
 [m
[31m-    # SomeWM stable 1.4 branch is the Wayland/ Awesome-compatible target.[m
[31m-    # The package is maintained locally under pkgs/somewm.nix because it is not[m
[31m-    # assumed to exist in the selected nixpkgs channel.[m
[31m-    somewm.url = "github:trip-zip/somewm/release/1.4";[m
[32m+[m[32m    somewm-stable.url = "github:trip-zip/somewm/release/1.4";[m
[32m+[m[32m    somewm-dev.url = "github:trip-zip/somewm/main";[m
   };[m
 [m
[31m-  outputs = inputs@{ self, nixpkgs, home-manager, ... }:[m
[32m+[m[32m  outputs = inputs@{ self, nixpkgs, home-manager, disko, nix-flatpak, ... }:[m
     let[m
       system = "x86_64-linux";[m
[31m-      lib = nixpkgs.lib;[m
[32m+[m[32m      pkgs = import nixpkgs {[m
[32m+[m[32m        inherit system;[m
[32m+[m[32m        config.allowUnfree = true;[m
[32m+[m[32m      };[m
     in {[m
[31m-      packages.${system}.somewm = import ./pkgs/somewm.nix {[m
[31m-        pkgs = import nixpkgs { inherit system; };[m
[31m-        src = inputs.somewm;[m
[32m+[m[32m      packages.${system}.somewm-stable = import ./pkgs/somewm.nix {[m
[32m+[m[32m        inherit pkgs;[m
[32m+[m[32m        src = inputs.somewm-stable;[m
[32m+[m[32m        version = "1.4";[m
[32m+[m[32m        wlrootsVersion = "0.19";[m
       };[m
 [m
[31m-      nixosConfigurations.nitro-v15 = lib.nixosSystem {[m
[32m+[m[32m      packages.${system}.somewm-dev = import ./pkgs/somewm.nix {[m
[32m+[m[32m        inherit pkgs;[m
[32m+[m[32m        src = inputs.somewm-dev;[m
[32m+[m[32m        version = "2.0-dev";[m
[32m+[m[32m        wlrootsVersion = "0.20";[m
[32m+[m[32m      };[m
[32m+[m
[32m+[m[32m      nixosConfigurations.nitro-v15 = nixpkgs.lib.nixosSystem {[m
         inherit system;[m
         specialArgs = { inherit inputs; };[m
         modules = [[m
[32m+[m[32m          disko.nixosModules.disko[m
[32m+[m[32m          nix-flatpak.nixosModules.nix-flatpak[m
           ./hosts/nitro-v15[m
           home-manager.nixosModules.home-manager[m
           {[m
[36m@@ -42,5 +60,10 @@[m
           }[m
         ];[m
       };[m
[32m+[m
[32m+[m[32m      # The disk configuration intentionally targets only the existing Linux[m
[32m+[m[32m      # partition (p2) so the Windows NTFS partition, MSR and EFI system[m
[32m+[m[32m      # partition are never part of a destructive Disko operation.[m
[32m+[m[32m      diskoConfigurations.nitro-v15 = ./hosts/nitro-v15/disko.nix;[m
     };[m
 }[m
[1mdiff --git a/home/loxedo/default.nix b/home/loxedo/default.nix[m
[1mindex 710f6ff..a068d02 100644[m
[1m--- a/home/loxedo/default.nix[m
[1m+++ b/home/loxedo/default.nix[m
[36m@@ -1,16 +1,27 @@[m
[31m-{ pkgs, inputs, ... }:[m
[32m+[m[32m{ pkgs, inputs, lib, ... }:[m
 [m
[32m+[m[32mlet[m
[32m+[m[32m  crystalWayland = pkgs.runCommand "crystal-aura-wayland" {} ''[m
[32m+[m[32m    cp -R ${inputs.crystal}/. $out[m
[32m+[m[32m    rm -f $out/rc.lua[m
[32m+[m[32m    cp ${./crystal/rc.lua} $out/rc.lua[m
[32m+[m[32m    rm -f $out/main/autorun.sh[m
[32m+[m[32m    mkdir -p $out/main[m
[32m+[m[32m    cp ${./crystal/autorun.sh} $out/main/autorun.sh[m
[32m+[m[32m    chmod +x $out/main/autorun.sh[m
[32m+[m[32m  '';[m
[32m+[m[32min[m
 {[m
   home.username = "loxedo";[m
   home.homeDirectory = "/home/loxedo";[m
   home.stateVersion = "26.05";[m
 [m
   home.packages = with pkgs; [[m
[31m-    kitty[m
[32m+[m[32m    alacritty[m
[32m+[m[32m    brave[m
[32m+[m[32m    fishPlugins.fzf[m
     rofi-wayland[m
[31m-    waybar[m
     wlogout[m
[31m-    swaylock[m
     playerctl[m
     brightnessctl[m
     pamixer[m
[36m@@ -28,37 +39,41 @@[m
     mpd[m
     mpc[m
     ncmpcpp[m
[31m-    neofetch[m
[31m-    lm_sensors[m
     btop[m
     fastfetch[m
[32m+[m[32m    lm_sensors[m
     networkmanagerapplet[m
[31m-    blueman[m
   ];[m
 [m
   programs.git.enable = true;[m
[31m-  programs.zsh = {[m
[32m+[m
[32m+[m[32m  programs.fish = {[m
[32m+[m[32m    enable = true;[m
[32m+[m[32m    interactiveShellInit = ''[m
[32m+[m[32m      set -g fish_greeting[m
[32m+[m[32m      alias rebuild 'sudo nixos-rebuild switch --flake ~/nixos-config#nitro-v15'[m
[32m+[m[32m      alias update 'cd ~/nixos-config; nix flake update; sudo nixos-rebuild switch --flake .#nitro-v15'[m
[32m+[m[32m      alias nvidia-run 'nvidia-offload'[m
[32m+[m[32m      alias wifi-on 'nmcli radio wifi on'[m
[32m+[m[32m      alias wifi-off 'nmcli radio wifi off'[m
[32m+[m[32m      alias bt-on 'rfkill unblock bluetooth'[m
[32m+[m[32m    '';[m
[32m+[m[32m  };[m
[32m+[m
[32m+[m[32m  programs.alacritty = {[m
     enable = true;[m
[31m-    autosuggestion.enable = true;[m
[31m-    syntaxHighlighting.enable = true;[m
[31m-    history.size = 10000;[m
[32m+[m[32m    settings = {[m
[32m+[m[32m      window.opacity = 0.96;[m
[32m+[m[32m      font.normal.family = "JetBrainsMono Nerd Font";[m
[32m+[m[32m      font.size = 11;[m
[32m+[m[32m    };[m
   };[m
 [m
[31m-  # Crystal Aura is tracked as a flake input. We materialize it as the[m
[31m-  # Awesome-compatible configuration directory for SomeWM.[m
   xdg.configFile."awesome" = {[m
[31m-    source = inputs.crystal;[m
[32m+[m[32m    source = crystalWayland;[m
     recursive = true;[m
   };[m
 [m
[31m-  # Wayland-specific overrides live outside upstream Crystal so upgrades are[m
[31m-  # isolated and easy to review.[m
[31m-  xdg.configFile."somewm/aura-override.lua".text = ''[m
[31m-    -- Local Wayland adaptation placeholder.[m
[31m-    -- Keep this separate from upstream Crystal Aura so upstream updates remain clean.[m
[31m-  '';[m
[31m-[m
[31m-  # Per-user launcher helper for explicit NVIDIA offload.[m
   home.file.".local/bin/nvidia-run" = {[m
     executable = true;[m
     text = ''[m
[1mdiff --git a/hosts/nitro-v15/default.nix b/hosts/nitro-v15/default.nix[m
[1mindex 0a7c171..cdb2e88 100644[m
[1m--- a/hosts/nitro-v15/default.nix[m
[1m+++ b/hosts/nitro-v15/default.nix[m
[36m@@ -1,8 +1,8 @@[m
 { config, pkgs, lib, inputs, ... }:[m
[31m-[m
 {[m
   imports = [[m
     ./hardware.nix[m
[32m+[m[32m    ./disko.nix[m
     ../../modules/boot.nix[m
     ../../modules/graphics.nix[m
     ../../modules/wayland.nix[m
[36m@@ -12,6 +12,7 @@[m
     ../../modules/swap.nix[m
     ../../modules/gaming.nix[m
     ../../modules/razer.nix[m
[32m+[m[32m    ../../modules/flatpak.nix[m
     ../../modules/optimization.nix[m
   ];[m
 [m
[36m@@ -25,10 +26,10 @@[m
     isNormalUser = true;[m
     description = "Loxedo";[m
     extraGroups = [ "wheel" "networkmanager" "video" "render" "input" ];[m
[31m-    shell = pkgs.zsh;[m
[32m+[m[32m    shell = pkgs.fish;[m
   };[m
 [m
[31m-  programs.zsh.enable = true;[m
[32m+[m[32m  programs.fish.enable = true;[m
 [m
   security.sudo.wheelNeedsPassword = true;[m
 [m
[36m@@ -36,8 +37,10 @@[m
     settings = {[m
       experimental-features = [ "nix-command" "flakes" ];[m
       auto-optimise-store = true;[m
[32m+[m[32m      builders-use-substitutes = true;[m
       trusted-users = [ "root" "loxedo" ];[m
     };[m
[32m+[m
     gc = {[m
       automatic = true;[m
       dates = "weekly";[m
[36m@@ -45,6 +48,7 @@[m
     };[m
   };[m
 [m
[32m+[m[32m  programs.command-not-found.enable = false;[m
   documentation.nixos.enable = false;[m
 [m
   system.stateVersion = "26.05";[m
[1mdiff --git a/hosts/nitro-v15/hardware.nix b/hosts/nitro-v15/hardware.nix[m
[1mindex a5211f4..47cdd41 100644[m
[1m--- a/hosts/nitro-v15/hardware.nix[m
[1m+++ b/hosts/nitro-v15/hardware.nix[m
[36m@@ -1,5 +1,4 @@[m
[31m-{ config, lib, pkgs, modulesPath, ... }:[m
[31m-[m
[32m+[m[32m{ config, lib, modulesPath, ... }:[m
 {[m
   imports = [[m
     (modulesPath + "/installer/scan/not-detected.nix")[m
[36m@@ -8,38 +7,17 @@[m
   boot.initrd.availableKernelModules = [[m
     "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "usbhid" "sd_mod"[m
   ];[m
[31m-  boot.initrd.kernelModules = [ ];[m
   boot.kernelModules = [ "kvm-intel" ];[m
[31m-  boot.extraModulePackages = [ ];[m
 [m
[31m-  # Detected hardware from Acer Nitro ANV15-51 audit.[m
   hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;[m
 [m
[31m-  fileSystems."/" = {[m
[31m-    device = "/dev/disk/by-uuid/e2b405ea-04bc-4de5-9f75-21005e57a5c6";[m
[31m-    fsType = "btrfs";[m
[31m-    options = [ "subvol=@" ];[m
[31m-  };[m
[31m-[m
[31m-  fileSystems."/home" = {[m
[31m-    device = "/dev/disk/by-uuid/e2b405ea-04bc-4de5-9f75-21005e57a5c6";[m
[31m-    fsType = "btrfs";[m
[31m-    options = [ "subvol=home" ];[m
[31m-  };[m
[31m-[m
[31m-  fileSystems."/nix" = {[m
[31m-    device = "/dev/disk/by-uuid/e2b405ea-04bc-4de5-9f75-21005e57a5c6";[m
[31m-    fsType = "btrfs";[m
[31m-    options = [ "subvol=nix" ];[m
[31m-  };[m
[31m-[m
[32m+[m[32m  # Reuse the existing EFI System Partition. It is intentionally never formatted[m
[32m+[m[32m  # by our installer because it also contains the Windows boot manager.[m
   fileSystems."/boot" = {[m
     device = "/dev/disk/by-uuid/3372-27A9";[m
     fsType = "vfat";[m
[31m-    options = [ "fmask=0077" "dmask=0077" ];[m
[32m+[m[32m    options = [ "umask=0077" ];[m
   };[m
 [m
[31m-  # The final installer intentionally recreates the filesystem layout. This[m
[31m-  # existing hardware file documents the current tested layout only.[m
   nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";[m
 }[m
[1mdiff --git a/modules/audio.nix b/modules/audio.nix[m
[1mindex 184a520..fb2b904 100644[m
[1m--- a/modules/audio.nix[m
[1m+++ b/modules/audio.nix[m
[36m@@ -1,6 +1,7 @@[m
 { pkgs, ... }:[m
 {[m
   security.rtkit.enable = true;[m
[32m+[m[32m  programs.dconf.enable = true;[m
 [m
   services.pipewire = {[m
     enable = true;[m
[36m@@ -11,7 +12,10 @@[m
   };[m
 [m
   environment.systemPackages = with pkgs; [[m
[32m+[m[32m    easyeffects[m
[32m+[m[32m    qpwgraph[m
     pavucontrol[m
     wireplumber[m
[32m+[m[32m    helvum[m
   ];[m
 }[m
[1mdiff --git a/modules/boot.nix b/modules/boot.nix[m
[1mindex 6737814..02aa325 100644[m
[1m--- a/modules/boot.nix[m
[1m+++ b/modules/boot.nix[m
[36m@@ -3,4 +3,5 @@[m
   boot.loader.systemd-boot.enable = true;[m
   boot.loader.efi.canTouchEfiVariables = true;[m
   boot.loader.timeout = 3;[m
[32m+[m[32m  boot.loader.systemd-boot.configurationLimit = 10;[m
 }[m
[1mdiff --git a/modules/gaming.nix b/modules/gaming.nix[m
[1mindex 9ac4650..66d1bd6 100644[m
[1m--- a/modules/gaming.nix[m
[1m+++ b/modules/gaming.nix[m
[36m@@ -3,14 +3,17 @@[m
   programs.steam = {[m
     enable = true;[m
     gamescopeSession.enable = true;[m
[32m+[m[32m    remotePlay.openFirewall = false;[m
   };[m
 [m
   programs.gamemode.enable = true;[m
[32m+[m[32m  programs.gamescope.enable = true;[m
 [m
   environment.systemPackages = with pkgs; [[m
     mangohud[m
     gamemode[m
     vulkan-tools[m
     protontricks[m
[32m+[m[32m    protonup-qt[m
   ];[m
 }[m
[1mdiff --git a/modules/graphics.nix b/modules/graphics.nix[m
[1mindex f435cf3..f6e50a6 100644[m
[1m--- a/modules/graphics.nix[m
[1m+++ b/modules/graphics.nix[m
[36m@@ -1,13 +1,20 @@[m
[31m-{ config, pkgs, lib, ... }:[m
[32m+[m[32m{ pkgs, ... }:[m
 {[m
   hardware.graphics = {[m
     enable = true;[m
     enable32Bit = true;[m
   };[m
 [m
[32m+[m[32m  services.xserver.videoDrivers = [ "nvidia" ];[m
[32m+[m
   hardware.nvidia = {[m
     open = true;[m
     modesetting.enable = true;[m
[32m+[m[32m    nvidiaSettings = false;[m
[32m+[m
[32m+[m[32m    # Fine-grained runtime power management is useful when the HDMI display is[m
[32m+[m[32m    # disconnected. With HDMI-A-2 physically wired to the RTX, the dGPU will[m
[32m+[m[32m    # remain awake whenever that monitor is active.[m
     powerManagement.enable = true;[m
     powerManagement.finegrained = true;[m
 [m
[36m@@ -22,5 +29,6 @@[m
   environment.systemPackages = with pkgs; [[m
     vulkan-tools[m
     mesa-demos[m
[32m+[m[32m    nvtopPackages.nvidia[m
   ];[m
 }[m
[1mdiff --git a/modules/networking.nix b/modules/networking.nix[m
[1mindex 5cee8eb..3656d26 100644[m
[1m--- a/modules/networking.nix[m
[1m+++ b/modules/networking.nix[m
[36m@@ -1,5 +1,20 @@[m
[31m-{ ... }:[m
[32m+[m[32m{ pkgs, ... }:[m
 {[m
   networking.networkmanager.enable = true;[m
   networking.useDHCP = false;[m
[32m+[m
[32m+[m[32m  # Wired Ethernet remains fully available. Wi-Fi is kept installed and[m
[32m+[m[32m  # manageable, but the radio starts disabled so it consumes no radio power[m
[32m+[m[32m  # during normal LAN use. `nmcli radio wifi on` enables it immediately.[m
[32m+[m[32m  systemd.services.disable-wifi-at-boot = {[m
[32m+[m[32m    description = "Disable Wi-Fi radio at boot";[m
[32m+[m[32m    wantedBy = [ "multi-user.target" ];[m
[32m+[m[32m    after = [ "NetworkManager.service" ];[m
[32m+[m[32m    requires = [ "NetworkManager.service" ];[m
[32m+[m[32m    serviceConfig = {[m
[32m+[m[32m      Type = "oneshot";[m
[32m+[m[32m      ExecStart = "${pkgs.networkmanager}/bin/nmcli radio wifi off";[m
[32m+[m[32m      RemainAfterExit = true;[m
[32m+[m[32m    };[m
[32m+[m[32m  };[m
 }[m
[1mdiff --git a/modules/optimization.nix b/modules/optimization.nix[m
[1mindex a496fc2..5b40b95 100644[m
[1m--- a/modules/optimization.nix[m
[1m+++ b/modules/optimization.nix[m
[36m@@ -1,15 +1,17 @@[m
 { ... }:[m
 {[m
   systemd.oomd.enable = true;[m
[31m-[m
   services.fwupd.enable = true;[m
 [m
[32m+[m[32m  # Hardware/service policy for this machine.[m
   services.printing.enable = false;[m
   services.avahi.enable = false;[m
   services.modemmanager.enable = false;[m
 [m
[31m-  boot.kernel.sysctl = {[m
[31m-    "vm.swappiness" = 100;[m
[31m-    "vm.vfs_cache_pressure" = 50;[m
[32m+[m[32m  # Bluetooth remains installed for emergency/occasional use, but is never[m
[32m+[m[32m  # powered on automatically.[m
[32m+[m[32m  hardware.bluetooth = {[m
[32m+[m[32m    enable = true;[m
[32m+[m[32m    powerOnBoot = false;[m
   };[m
 }[m
[1mdiff --git a/modules/storage.nix b/modules/storage.nix[m
[1mindex c7d1151..9df994d 100644[m
[1m--- a/modules/storage.nix[m
[1m+++ b/modules/storage.nix[m
[36m@@ -1,4 +1,8 @@[m
 { ... }:[m
 {[m
   services.fstrim.enable = true;[m
[32m+[m[32m  services.btrfs.autoScrub = {[m
[32m+[m[32m    enable = true;[m
[32m+[m[32m    interval = "monthly";[m
[32m+[m[32m  };[m
 }[m
[1mdiff --git a/modules/swap.nix b/modules/swap.nix[m
[1mindex 781c347..017894a 100644[m
[1m--- a/modules/swap.nix[m
[1m+++ b/modules/swap.nix[m
[36m@@ -1,13 +1,26 @@[m
 { ... }:[m
 {[m
[32m+[m[32m  # 12 GiB maximum compressed swap in RAM, plus a 32 GiB SSD-backed swapfile.[m
[32m+[m[32m  # zram is given a higher priority so memory pressure first uses compression[m
[32m+[m[32m  # before falling back to the NVMe swapfile.[m
   zramSwap = {[m
     enable = true;[m
     algorithm = "zstd";[m
[31m-    memoryPercent = 50;[m
[32m+[m[32m    memoryPercent = 75;[m
     priority = 100;[m
   };[m
 [m
[31m-  # Deliberately not creating the 32 GiB swapfile yet. Once the clean-install[m
[31m-  # filesystem layout is finalized, the installer will provision the SSD swap[m
[31m-  # according to the final hibernation policy.[m
[32m+[m[32m  swapDevices = [[m
[32m+[m[32m    {[m
[32m+[m[32m      device = "/swap/swapfile";[m
[32m+[m[32m      size = 32 * 1024;[m
[32m+[m[32m      priority = 5;[m
[32m+[m[32m    }[m
[32m+[m[32m  ];[m
[32m+[m
[32m+[m[32m  boot.kernel.sysctl = {[m
[32m+[m[32m    "vm.swappiness" = 150;[m
[32m+[m[32m    "vm.page-cluster" = 0;[m
[32m+[m[32m    "vm.vfs_cache_pressure" = 50;[m
[32m+[m[32m  };[m
 }[m
[1mdiff --git a/modules/wayland.nix b/modules/wayland.nix[m
[1mindex 9244ae5..7de2238 100644[m
[1m--- a/modules/wayland.nix[m
[1m+++ b/modules/wayland.nix[m
[36m@@ -1,33 +1,48 @@[m
[31m-{ config, pkgs, inputs, ... }:[m
[31m-[m
[32m+[m[32m{ pkgs, inputs, ... }:[m
 let[m
[31m-  somewm = inputs.self.packages.${pkgs.system}.somewm or (import ../pkgs/somewm.nix { inherit pkgs; src = inputs.somewm; });[m
[31m-in {[m
[31m-  environment.systemPackages = [[m
[32m+[m[32m  somewm = inputs.self.packages.${pkgs.system}.somewm-stable;[m
[32m+[m[32min[m
[32m+[m[32m{[m
[32m+[m[32m  environment.systemPackages = with pkgs; [[m
     somewm[m
[31m-    pkgs.wl-clipboard[m
[31m-    pkgs.wayland-utils[m
[31m-    pkgs.wtype[m
[31m-    pkgs.xdg-utils[m
[31m-    pkgs.xdg-desktop-portal[m
[31m-    pkgs.xdg-desktop-portal-gtk[m
[32m+[m[32m    wl-clipboard[m
[32m+[m[32m    wayland-utils[m
[32m+[m[32m    wtype[m
[32m+[m[32m    xdg-utils[m
[32m+[m[32m    xdg-desktop-portal[m
[32m+[m[32m    xdg-desktop-portal-wlr[m
[32m+[m[32m    xdg-desktop-portal-gtk[m
[32m+[m[32m    libsecret[m
   ];[m
 [m
   xdg.portal = {[m
     enable = true;[m
[31m-    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];[m
[31m-    config.common.default = "gtk";[m
[32m+[m[32m    extraPortals = [[m
[32m+[m[32m      pkgs.xdg-desktop-portal-wlr[m
[32m+[m[32m      pkgs.xdg-desktop-portal-gtk[m
[32m+[m[32m    ];[m
[32m+[m[32m    config.common.default = "wlr";[m
[32m+[m[32m    config.common = {[m
[32m+[m[32m      "org.freedesktop.impl.portal.ScreenCast" = "wlr";[m
[32m+[m[32m      "org.freedesktop.impl.portal.Screenshot" = "wlr";[m
[32m+[m[32m    };[m
   };[m
 [m
   services.greetd = {[m
     enable = true;[m
     settings = {[m
       default_session = {[m
[31m-        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd somewm";[m
[32m+[m[32m        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd ${somewm}/bin/somewm";[m
         user = "greeter";[m
       };[m
     };[m
   };[m
 [m
   security.polkit.enable = true;[m
[32m+[m
[32m+[m[32m  environment.sessionVariables = {[m
[32m+[m[32m    NIXOS_OZONE_WL = "1";[m
[32m+[m[32m    ELECTRON_OZONE_PLATFORM_HINT = "auto";[m
[32m+[m[32m    MOZ_ENABLE_WAYLAND = "1";[m
[32m+[m[32m  };[m
 }[m
[1mdiff --git a/pkgs/somewm.nix b/pkgs/somewm.nix[m
[1mindex cdca1aa..ef7d506 100644[m
[1m--- a/pkgs/somewm.nix[m
[1m+++ b/pkgs/somewm.nix[m
[36m@@ -1,9 +1,7 @@[m
[31m-{ pkgs, src }:[m
[31m-[m
[32m+[m[32m{ pkgs, src, version, wlrootsVersion }:[m
 pkgs.stdenv.mkDerivation {[m
   pname = "somewm";[m
[31m-  version = "1.4";[m
[31m-  inherit src;[m
[32m+[m[32m  inherit version src;[m
 [m
   nativeBuildInputs = with pkgs; [[m
     meson[m
[36m@@ -36,7 +34,7 @@[m [mpkgs.stdenv.mkDerivation {[m
   mesonFlags = [[m
     "-Dbuildtype=release"[m
     "-Db_sanitize=none"[m
[31m-    "-Dwlroots_version=0.19"[m
[32m+[m[32m    "-Dwlroots_version=${wlrootsVersion}"[m
     "-Dxwayland=enabled"[m
     "-Dpam=enabled"[m
   ];[m
[1mdiff --git a/scripts/install.sh b/scripts/install.sh[m
[1mindex 9712c50..9544f2a 100755[m
[1m--- a/scripts/install.sh[m
[1m+++ b/scripts/install.sh[m
[36m@@ -1,28 +1,80 @@[m
 #!/usr/bin/env bash[m
 set -euo pipefail[m
 [m
[31m-# This script intentionally stops before destructive partitioning until the[m
[31m-# target disk and filesystem layout are explicitly reviewed.[m
[32m+[m[32m# Clean-install workflow for Acer Nitro ANV15-51.[m
[32m+[m[32m#[m
[32m+[m[32m# SAFETY CONTRACT:[m
[32m+[m[32m#   - Never touches /dev/nvme0n1 as a whole.[m
[32m+[m[32m#   - Never formats the EFI partition, Windows MSR or Windows NTFS partition.[m
[32m+[m[32m#   - Only /dev/nvme0n1p2 (Linux Btrfs) may be reformatted.[m
[32m+[m[32m#[m
[32m+[m[32m# Review the printed partition table carefully before answering YES.[m
[32m+[m
[32m+[m[32mrepo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"[m
[32m+[m[32mcd "$repo_root"[m
 [m
 if [ "$(id -u)" -eq 0 ]; then[m
[31m-  echo "Run this script as a normal user, not directly as root."[m
[32m+[m[32m  echo "Run this script as the normal live-installer user; it uses sudo itself."[m
   exit 1[m
 fi[m
 [m
[31m-repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"[m
[31m-cd "$repo_root"[m
[31m-[m
 command -v nix >/dev/null || { echo "nix is required"; exit 1; }[m
[31m-command -v git >/dev/null || { echo "git is required"; exit 1; }[m
[32m+[m[32mcommand -v lsblk >/dev/null || { echo "lsblk is required"; exit 1; }[m
[32m+[m[32mcommand -v blkid >/dev/null || { echo "blkid is required"; exit 1; }[m
[32m+[m
[32m+[m[32mDISK="/dev/nvme0n1"[m
[32m+[m[32mLINUX_PART="/dev/nvme0n1p2"[m
[32m+[m[32mESP="/dev/nvme0n1p1"[m
[32m+[m[32mWINDOWS_PART="/dev/nvme0n1p4"[m
[32m+[m
[32m+[m[32mexpected_partuuid="2d1d0aae-7888-488c-af75-a60b3ad1b866"[m
[32m+[m[32mexpected_esp_uuid="3372-27A9"[m
[32m+[m[32mexpected_windows_fs="ntfs"[m
[32m+[m
[32m+[m[32mprintf '\n=== DETECTED DISK ===\n'[m
[32m+[m[32mlsblk -e7 -o NAME,PATH,MODEL,SIZE,TYPE,FSTYPE,UUID,PARTUUID,MOUNTPOINTS "$DISK"[m
[32m+[m
[32m+[m[32mprintf '\n=== SAFETY CHECKS ===\n'[m
[32m+[m[32m[ "$(blkid -s PARTUUID -o value "$LINUX_PART")" = "$expected_partuuid" ] || {[m
[32m+[m[32m  echo "ERROR: p2 PARTUUID does not match expected Linux partition." >&2[m
[32m+[m[32m  exit 1[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m[ "$(blkid -s UUID -o value "$ESP")" = "$expected_esp_uuid" ] || {[m
[32m+[m[32m  echo "ERROR: EFI UUID does not match expected Windows/NixOS ESP." >&2[m
[32m+[m[32m  exit 1[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m[ "$(blkid -s TYPE -o value "$WINDOWS_PART")" = "$expected_windows_fs" ] || {[m
[32m+[m[32m  echo "ERROR: p4 does not look like the expected Windows NTFS partition." >&2[m
[32m+[m[32m  exit 1[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mprintf '\nThis installer will ONLY erase/reformat: %s\n' "$LINUX_PART"[m
[32m+[m[32mprintf 'It will NOT touch: %s, %s, %s\n' "$ESP" /dev/nvme0n1p3 "$WINDOWS_PART"[m
[32m+[m[32mprintf '\nType exactly ERASE-LINUX-P2 to continue: '[m
[32m+[m[32mread -r confirmation[m
[32m+[m[32m[ "$confirmation" = "ERASE-LINUX-P2" ] || {[m
[32m+[m[32m  echo "Aborted."[m
[32m+[m[32m  exit 0[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32m# Disko config targets p2 only. We use wipefs here because the clean install[m
[32m+[m[32m# must remove the old Btrfs filesystem before Disko creates the declared layout.[m
[32m+[m[32msudo umount -R /mnt 2>/dev/null || true[m
[32m+[m[32msudo wipefs -a "$LINUX_PART"[m
[32m+[m
[32m+[m[32msudo nix run github:nix-community/disko/latest -- \[m
[32m+[m[32m  --mode format,mount \[m
[32m+[m[32m  --flake "$repo_root#nitro-v15"[m
 [m
[31m-printf '%s\n' 'NixOS clean installer scaffold'[m
[31m-printf '%s\n' 'Detected target model: Acer Nitro ANV15-51'[m
[31m-printf '%s\n' 'Expected GPUs: Intel 00:02.0 + NVIDIA 01:00.0'[m
[31m-printf '%s\n' 'Expected displays: eDP-1 165Hz + HDMI-A-2 74.97Hz'[m
[31m-printf '%s\n' ''[m
[31m-printf '%s\n' 'SAFETY: destructive disk operations are not implemented yet.'[m
[31m-printf '%s\n' 'Before enabling them, review the final storage layout in this repository.'[m
[32m+[m[32msudo mkdir -p /mnt/etc/nixos[m
[32m+[m[32msudo nixos-generate-config --root /mnt --no-filesystems[m
[32m+[m[32msudo cp -a "$repo_root/." /mnt/etc/nixos/[m
 [m
[31m-nix flake check .[m
[32m+[m[32msudo nixos-install \[m
[32m+[m[32m  --no-root-password \[m
[32m+[m[32m  --flake /mnt/etc/nixos#nitro-v15[m
 [m
[31m-printf '%s\n' 'Flake checks passed. The destructive install stage is deliberately not enabled yet.'[m
[32m+[m[32mprintf '\nInstallation finished. Reboot and select the NixOS entry.\n'[m
[32m+[m[32mprintf 'Windows remains on its existing NTFS partition and EFI loader.\n'[m
