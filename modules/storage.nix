{ ... }:
{
  services.fstrim.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    # The host uses several sibling subvolumes on one Btrfs filesystem.
    # Scrub the top-level mounted filesystem once instead of scheduling
    # duplicate scrubs for every subvolume mount.
    fileSystems = [ "/" ];
    interval = "monthly";
  };
}
