{ pkgs, ... }:
{
  hardware.openrazer = {
    enable = true;
    users = [ "loxedo" ];
    devicesOffOnScreensaver = false;
  };

  environment.systemPackages = with pkgs; [
    polychromatic
  ];
}
