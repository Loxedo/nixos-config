#!/usr/bin/env bash
set -euo pipefail

# Clean-install workflow for this Acer Nitro ANV15-51.
#
# This machine is intentionally configured as a single-disk NixOS system.
# The installer validates the complete flake before doing anything destructive,
# then discovers the internal NVMe disk, shows it, asks for an explicit
# confirmation, and lets Disko destroy/repartition that disk.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if [[ $EUID -eq 0 ]]; then
  echo "Run ./install.sh as the live-user account; sudo is used where needed." >&2
  exit 1
fi

# This configuration installs systemd-boot to an EFI System Partition, so the
# official installation workflow requires the live environment to be booted
# in UEFI mode. Do not allow a BIOS boot to reach the destructive Disko step.
if [[ ! -d /sys/firmware/efi ]]; then
  echo "The NixOS live environment is not booted in UEFI mode." >&2
  echo "Reboot the installer USB using its UEFI boot entry and run ./install.sh again." >&2
  exit 1
fi

# The installed NixOS system enables flakes declaratively, but that setting
# cannot affect the NixOS live ISO before the target system exists. Nix reads
# NIX_CONFIG for the current process tree, so this enables flakes for the live
# installer and every Nix command it launches without modifying the target.
export NIX_CONFIG='experimental-features = nix-command flakes'

for cmd in nix lsblk nixos-install nixos-generate-config mountpoint sha256sum sudo; do
  command -v "$cmd" >/dev/null || {
    echo "Missing required command: $cmd" >&2
    exit 1
  }
done

if ! nix --version >/dev/null 2>&1; then
  echo "A working Nix installation is required." >&2
  exit 1
fi

# Validation is not allowed to mutate the lockfile. If a flake input needs to
# change, that is an explicit repository maintenance action, not an installer
# side effect. This also makes the preflight and the installed system use the
# exact committed dependency graph.
lock_before="$(sha256sum flake.lock)"

# Run a complete preflight build before touching the disk. This is deliberate:
# a failure in SomeWM/LGI/wlroots or any other system package must stop the
# installer BEFORE the existing filesystem is destroyed.
echo
echo 'Running preflight build of the complete NixOS configuration...'
if ! nix build "$repo_root#nixosConfigurations.nitro-v15.config.system.build.toplevel" \
  --no-link \
  --no-write-lock-file; then
  echo
  echo 'Preflight build failed. The disk has NOT been modified.' >&2
  echo 'Fix the reported build error and run ./install.sh again.' >&2
  exit 1
fi

lock_after="$(sha256sum flake.lock)"
if [[ "$lock_before" != "$lock_after" ]]; then
  echo 'ERROR: preflight modified flake.lock; refusing to continue.' >&2
  exit 1
fi

echo
echo 'Preflight build passed.'

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

# SAFETY GUARD: this Disko configuration destroys the entire target disk.
# Never allow that mode to run when Windows partitions are present. The
# Windows NTFS partition, Microsoft Reserved partition, and Windows recovery
# partition must be preserved on the user's dual-boot machine. This guard is
# intentionally conservative: it refuses the install instead of guessing
# which existing Linux partition is safe to reuse.
windows_partitions="$(
  lsblk -nrpo NAME,FSTYPE,PARTTYPE "$disk" |
    awk 'tolower($2) == "ntfs" ||
         toupper($3) == "E3C9E316-0B5C-4DB8-817D-F92DF00215AE" ||
         toupper($3) == "DE94BBA4-06D1-4D40-A16A-BFD50179D6AC" ||
         toupper($3) == "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" { print $1 }'
)"

if [[ -n "$windows_partitions" ]]; then
  echo >&2
  echo 'REFUSING TO RUN DESTRUCTIVE DISKO INSTALL.' >&2
  echo "The target disk $disk contains Windows partitions:" >&2
  printf '  %s\n' "$windows_partitions" >&2
  echo >&2
  echo 'This install.sh uses Disko in destroy,format,mount mode and would erase the entire disk.' >&2
  echo 'The Windows NTFS/MSR/recovery partitions must be preserved.' >&2
  echo 'Use a partition-preserving Disko layout before continuing.' >&2
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

# Use the exact Disko revision pinned by this repository's flake.lock instead
# of silently switching to a different release at install time.
disko_rev="$(nix eval --raw --no-write-lock-file --expr 'let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in lock.nodes.disko.locked.rev')"
disko_ref="github:nix-community/disko/${disko_rev}"

echo
echo "Using pinned Disko revision: $disko_rev"
echo 'Partitioning and formatting with Disko...'
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
echo 'Generating installer hardware metadata...'
sudo mkdir -p /mnt/etc/nixos
sudo nixos-generate-config --root /mnt --no-filesystems

# Keep the generated files for reference, but make the repository flake the
# authoritative system configuration. Git metadata is not needed on the target.
sudo cp -a "$repo_root/." /mnt/etc/nixos/
sudo rm -rf /mnt/etc/nixos/.git

if [[ ! -f /mnt/etc/nixos/flake.nix ]]; then
  echo 'Flake was not copied into /mnt/etc/nixos.' >&2
  exit 1
fi

echo
echo 'Installing NixOS from the flake...'
sudo env NIX_CONFIG="$NIX_CONFIG" nixos-install \
  --no-root-password \
  --flake /mnt/etc/nixos#nitro-v15

# The declarative user intentionally has no password in the public repository.
# NixOS documents that such users cannot perform password logins until passwd
# is run. Set the real password interactively inside the freshly installed
# system before rebooting, rather than committing a password or hash to Git.
echo
echo 'Set the password for the loxedo user before rebooting.'
sudo nixos-enter --root /mnt -c 'passwd loxedo'

echo
echo 'Installation finished successfully.'
echo 'Reboot, remove the live USB, and boot NixOS.'
