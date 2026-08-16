#!/usr/bin/env bash
set -euo pipefail

# Clean-install workflow for Acer Nitro ANV15-51.
#
# SAFETY CONTRACT:
#   - Never touches /dev/nvme0n1 as a whole.
#   - Never formats the EFI partition, Windows MSR or Windows NTFS partition.
#   - Only /dev/nvme0n1p2 (Linux Btrfs) may be reformatted.
#
# Review the printed partition table carefully before answering YES.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as the normal live-installer user; it uses sudo itself."
  exit 1
fi

command -v nix >/dev/null || { echo "nix is required"; exit 1; }
command -v lsblk >/dev/null || { echo "lsblk is required"; exit 1; }
command -v blkid >/dev/null || { echo "blkid is required"; exit 1; }

DISK="/dev/nvme0n1"
LINUX_PART="/dev/nvme0n1p2"
ESP="/dev/nvme0n1p1"
WINDOWS_PART="/dev/nvme0n1p4"

expected_partuuid="2d1d0aae-7888-488c-af75-a60b3ad1b866"
expected_esp_uuid="3372-27A9"
expected_windows_fs="ntfs"

printf '\n=== DETECTED DISK ===\n'
lsblk -e7 -o NAME,PATH,MODEL,SIZE,TYPE,FSTYPE,UUID,PARTUUID,MOUNTPOINTS "$DISK"

printf '\n=== SAFETY CHECKS ===\n'
[ "$(blkid -s PARTUUID -o value "$LINUX_PART")" = "$expected_partuuid" ] || {
  echo "ERROR: p2 PARTUUID does not match expected Linux partition." >&2
  exit 1
}

[ "$(blkid -s UUID -o value "$ESP")" = "$expected_esp_uuid" ] || {
  echo "ERROR: EFI UUID does not match expected Windows/NixOS ESP." >&2
  exit 1
}

[ "$(blkid -s TYPE -o value "$WINDOWS_PART")" = "$expected_windows_fs" ] || {
  echo "ERROR: p4 does not look like the expected Windows NTFS partition." >&2
  exit 1
}

printf '\nThis installer will ONLY erase/reformat: %s\n' "$LINUX_PART"
printf 'It will NOT touch: %s, %s, %s\n' "$ESP" /dev/nvme0n1p3 "$WINDOWS_PART"
printf '\nType exactly ERASE-LINUX-P2 to continue: '
read -r confirmation
[ "$confirmation" = "ERASE-LINUX-P2" ] || {
  echo "Aborted."
  exit 0
}

# Disko config targets p2 only. We use wipefs here because the clean install
# must remove the old Btrfs filesystem before Disko creates the declared layout.
sudo umount -R /mnt 2>/dev/null || true
sudo wipefs -a "$LINUX_PART"

sudo nix run github:nix-community/disko/latest -- \
  --mode format,mount \
  --flake "$repo_root#nitro-v15"

sudo mkdir -p /mnt/etc/nixos
sudo nixos-generate-config --root /mnt --no-filesystems
sudo cp -a "$repo_root/." /mnt/etc/nixos/

sudo nixos-install \
  --no-root-password \
  --flake /mnt/etc/nixos#nitro-v15

printf '\nInstallation finished. Reboot and select the NixOS entry.\n'
printf 'Windows remains on its existing NTFS partition and EFI loader.\n'
