{ ... }:
{
  systemd.oomd.enable = true;

  services.fwupd.enable = true;

  services.printing.enable = false;
  services.avahi.enable = false;
  services.modemmanager.enable = false;

  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.vfs_cache_pressure" = 50;
  };
}
