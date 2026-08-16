{ pkgs, ... }:
{
  security.rtkit.enable = true;
  programs.dconf.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  environment.systemPackages = with pkgs; [
    easyeffects
    qpwgraph
    pavucontrol
    wireplumber
  ];
}
