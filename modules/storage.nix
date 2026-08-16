{ ... }:
{
  services.fstrim.enable = true;
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };
}
