{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "usbhid" "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Detected hardware from Acer Nitro ANV15-51 audit.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e2b405ea-04bc-4de5-9f75-21005e57a5c6";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/e2b405ea-04bc-4de5-9f75-21005e57a5c6";
    fsType = "btrfs";
    options = [ "subvol=home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/e2b405ea-04bc-4de5-9f75-21005e57a5c6";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3372-27A9";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # The final installer intentionally recreates the filesystem layout. This
  # existing hardware file documents the current tested layout only.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
