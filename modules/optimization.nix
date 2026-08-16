{ ... }:
{
  systemd.oomd.enable = true;
  services.fwupd.enable = true;

  # Hardware/service policy for this machine.
  services.printing.enable = false;
  services.avahi.enable = false;
  services.modemmanager.enable = false;

  # Bluetooth remains installed for emergency/occasional use, but is never
  # powered on automatically.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
}
