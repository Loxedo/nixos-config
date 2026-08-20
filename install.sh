#!/usr/bin/env bash
set -euo pipefail

# Clean-install workflow for the Acer Nitro V15.
#
# Designed for a NixOS Live USB, including copy-to-RAM/iso-to-RAM boots.
# It deliberately does NOT pre-build the system in the live environment.
# The target filesystem is mounted first, and nixos-install is pointed at the
# target /mnt so the large closure is stored on the SSD instead of the
# RAM-backed live /nix.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if [[ $EUID -eq 0 ]]; then
  echo "Run ./install.sh as the live-user account; sudo is used where needed." >&2
  exit 1
fi

if [[ ! -d /sys/firmware/efi ]]; then
  echo "The NixOS live environment is not booted in UEFI mode." >&2
  echo "Reboot the installer USB using its UEFI boot entry and run ./install.sh again." >&2
  exit 1
fi

export NIX_CONFIG='experimental-features = nix-command flakes'

for cmd in nix lsblk nixos-install mountpoint sudo; do
  command -v "$cmd" >/dev/null || {
    echo "Missing required command: $cmd" >&2
    exit 1
  }
done

if ! nix --version >/dev/null 2>&1; then
  echo "A working Nix installation is required." >&2
  exit 1
fi

flake_ref="github:Loxedo/nixos-config#nitro-v15"

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
echo 'Current target disk:'
lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,MODEL,MOUNTPOINTS "$disk"
echo
echo '============================================================'
echo '              DESTRUCTIVE NIXOS INSTALL'
echo '============================================================'
echo
echo "The ENTIRE disk $disk will be erased and repartitioned."
echo 'The existing partition table and all data on this disk will be lost.'
echo 'Disko will create the declarative NixOS layout from hosts/nitro-v15/disko.nix.'
echo
echo 'After confirmation, the process is automatic:'
echo '  1. Unmount old filesystems.'
echo '  2. Destroy and repartition the NVMe with Disko.'
echo '  3. Mount /mnt, including the target /mnt/nix store.'
echo '  4. Install directly from the GitHub flake.'
echo '  5. Set the loxedo password.'
echo
echo 'The installer does NOT run a preflight build in the live ISO.'
echo 'This is what prevents the copy-to-RAM live environment from filling up.'
echo 'Type exactly: ERASE-NVME0N1'
read -r -p '> ' confirmation

if [[ "$confirmation" != 'ERASE-NVME0N1' ]]; then
  echo 'Installation cancelled.'
  exit 0
fi

sudo umount -R /mnt 2>/dev/null || true

# Read the pinned Disko revision from the local flake.lock. --impure is needed
# because this expression intentionally reads a local file from repo_root.
# This does not build the system or write to the live-store.
disko_rev="$(nix eval --impure --raw --no-write-lock-file --expr 'let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in lock.nodes.disko.locked.rev')"
disko_ref="github:nix-community/disko/${disko_rev}"

echo
echo "Using pinned Disko revision: $disko_rev"
echo 'Destroying, partitioning, formatting, and mounting the target disk...'
sudo env NIX_CONFIG="$NIX_CONFIG" nix run \
  --no-write-lock-file \
  "$disko_ref" -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  --flake "$repo_root#nitro-v15"

mountpoint -q /mnt || {
  echo 'Disko completed without mounting /mnt; aborting.' >&2
  exit 1
}

echo
echo 'Target filesystem is mounted.'
df -h /mnt /mnt/nix || true

echo
echo 'Installing NixOS directly from the GitHub flake...'
echo 'Build/store location: /mnt/nix/store (target SSD)'

# nixos-install may try to update the fetched GitHub flake lock file. During a
# clean install the flake is intentionally read-only, so explicitly disable
# lock-file writes. This also prevents the installer from trying to modify a
# GitHub-fetched flake in the live environment.
sudo env NIX_CONFIG="$NIX_CONFIG" nixos-install \
  --no-write-lock-file \
  --no-root-password \
  --flake "$flake_ref"

# The public repository does not contain a password hash. Set the password
# interactively inside the freshly installed system instead.
echo
echo 'Set the password for the loxedo user before rebooting.'
sudo nixos-enter --root /mnt -c 'passwd loxedo'

echo
echo '============================================================'
echo 'NixOS installation finished successfully.'
echo 'Reboot, remove the live USB, and boot the NVMe installation.'
echo '============================================================'
