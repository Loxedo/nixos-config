{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;
  boot.loader.systemd-boot.configurationLimit = 10;
}
