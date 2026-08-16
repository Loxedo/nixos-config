{ ... }:
{
  # This host is a single-disk installation. The installer verifies that the
  # detected device is /dev/nvme0n1 before invoking Disko.
  disko.devices.disk.nixos = {
    type = "disk";
    device = "/dev/nvme0n1";

    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          size = "100%";
          type = "8300";
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
              "@cache" = {
                mountpoint = "/var/cache";
                mountOptions = [ "compress=zstd:3" "noatime" ];
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = [ "compress=zstd:3" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
