{ config, lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "usbhid" "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Reuse the existing EFI System Partition. It is intentionally never formatted
  # by our installer because it also contains the Windows boot manager.
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3372-27A9";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
