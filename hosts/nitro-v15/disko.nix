{ ... }:
{
  # IMPORTANT: this is /dev/nvme0n1p2 only, not the whole NVMe disk.
  # p1 (EFI), p3 (Windows MSR) and p4 (Windows NTFS) are intentionally outside
  # the Disko target and remain untouched by the clean-install workflow.
  disko.devices.disk.nixos = {
    type = "disk";
    device = "/dev/disk/by-partuuid/2d1d0aae-7888-488c-af75-a60b3ad1b866";

    content = {
      type = "btrfs";
      extraArgs = [ "-L" "NIXOS" ];

      subvolumes = {
        "@root" = {
          mountpoint = "/";
          mountOptions = [ "compress=zstd:3" "noatime" ];
        };

        "@home" = {
          mountpoint = "/home";
          mountOptions = [ "compress=zstd:3" "noatime" ];
        };

        "@nix" = {
          mountpoint = "/nix";
          mountOptions = [ "compress=zstd:3" "noatime" ];
        };

        "@swap" = {
          mountpoint = "/swap";
          mountOptions = [ "noatime" ];
        };
      };
    };
  };
}
