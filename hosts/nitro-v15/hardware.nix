{
  config, lib, modulesPath, ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "usbhid" "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Disko owns the /boot filesystem declaration. Keeping another manual
  # fileSystems."/boot" definition here only duplicates the same option.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
