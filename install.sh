#!/usr/bin/env bash
set -euo pipefail

# Clean-install workflow for this Acer Nitro ANV15-51.
#
# This machine is intentionally configured as a single-disk NixOS system.
# The installer discovers the internal NVMe disk, shows it, asks for an
# explicit confirmation, then lets Disko destroy/repartition that disk.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if [[ $EUID -eq 0 ]]; then
  echo "Run ./install.sh as the live-user account; sudo is used where needed." >&2
  exit 1
fi

for cmd in nix lsblk; do
  command -v "$cmd" >/dev/null || {
    echo "Missing required command: $cmd" >&2
    exit 1
  }
done

if ! nix --extra-experimental-features 'nix-command flakes' --version >/dev/null 2>&1; then
  echo "Nix with flakes support is required." >&2
  exit 1
fi

mapfile -t nvme_disks < <(
  lsblk -dnpo NAME,TYPE | awk '$2 == "disk" && $1 ~ /^\/dev\/nvme[0-9]+n[0-9]+$/ {print $1}'
)

if [[ ${#nvme_disks[@]} -ne 1 ]]; then
  echo "Expected exactly one internal NVMe disk, found ${#nvme_disks[@]}." >&2
  echo
  lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,MODEL,MOUNTPOINTS
  exit 1
fi

disk="${nvme_disks[0]}"
expected_disk="/dev/nvme0n1"

if [[ "$disk" != "$expected_disk" ]]; then
  echo "Detected $disk, but this host configuration targets $expected_disk." >&2
  echo "Refusing to continue rather than risk formatting the wrong device." >&2
  exit 1
fi

echo
printf 'Target disk: %s\n' "$disk"
echo
echo 'Current disk layout:'
lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,MODEL,MOUNTPOINTS "$disk"
echo
echo '!!! WARNING !!!'
echo "Disko will DESTROY the partition table on $disk and recreate it."
echo 'All data currently on that disk will be lost.'
echo
echo "The NixOS layout is: 1 GiB EFI + Btrfs using the remaining space."
echo
echo "Type exactly: ERASE-NVME0N1"
read -r -p '> ' confirmation

if [[ "$confirmation" != 'ERASE-NVME0N1' ]]; then
  echo 'Installation cancelled.'
  exit 0
fi

sudo umount -R /mnt 2>/dev/null || true

# Disko owns partitioning, formatting, and mounting. Do not run wipefs here:
# having a single tool own the disk lifecycle avoids two competing layouts.
echo
echo 'Partitioning and formatting with Disko...'
sudo nix --extra-experimental-features 'nix-command flakes' run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  --flake "$repo_root#nitro-v15"

mountpoint -q /mnt || {
  echo 'Disko completed without mounting /mnt; aborting.' >&2
  exit 1
}

echo
echo 'Generating installer hardware metadata...'
sudo mkdir -p /mnt/etc/nixos
sudo nixos-generate-config --root /mnt --no-filesystems

# Keep the generated files for reference, but make the repository flake the
# authoritative system configuration.
sudo cp -a "$repo_root/." /mnt/etc/nixos/

if [[ ! -f /mnt/etc/nixos/flake.nix ]]; then
  echo 'Flake was not copied into /mnt/etc/nixos.' >&2
  exit 1
fi

echo
echo 'Installing NixOS from the flake...'
sudo nixos-install \
  --no-root-password \
  --flake /mnt/etc/nixos#nitro-v15

echo
echo 'Installation finished successfully.'
echo 'Reboot, remove the live USB, and boot NixOS.'
