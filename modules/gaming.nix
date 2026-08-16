{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = false;
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    gamemode
    vulkan-tools
    protontricks
    protonup-qt
  ];
}
