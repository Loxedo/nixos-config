{ pkgs, ... }:
{
  networking.networkmanager.enable = true;
  networking.useDHCP = false;

  # Wired Ethernet remains fully available. Wi-Fi is kept installed and
  # manageable, but the radio starts disabled so it consumes no radio power
  # during normal LAN use. `nmcli radio wifi on` enables it immediately.
  systemd.services.disable-wifi-at-boot = {
    description = "Disable Wi-Fi radio at boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    requires = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.networkmanager}/bin/nmcli radio wifi off";
      RemainAfterExit = true;
    };
  };
}
