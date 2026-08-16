#!/usr/bin/env bash
set -euo pipefail

# Generic clean-install workflow for NixOS (Acer Nitro ANV15-51)
#
# This script:
# 1. Detects the internal NVMe disk (never the Ventoy USB)
# 2. Shows the partition layout for review
# 3. Asks for confirmation before formatting
# 4. Uses Disko to partition and mount
# 5. Installs NixOS with your flake config
#
# SAFETY: Always review the partition table before confirming!

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Run this script as the normal live-installer user; it uses sudo itself."
  exit 1
fi

# Check dependencies
command -v nix >/dev/null || { echo "❌ nix is required"; exit 1; }
command -v lsblk >/dev/null || { echo "❌ lsblk is required"; exit 1; }
command -v blkid >/dev/null || { echo "❌ blkid is required"; exit 1; }
command -v udevadm >/dev/null || { echo "❌ udevadm is required"; exit 1; }

# The live USB is commonly /dev/sda when booted through Ventoy.
# Never auto-select sda/sdb/vda: on a clean NixOS live environment those can
# be the installer media. This machine uses an internal NVMe disk.
echo "🔍 Detecting internal NVMe disk..."
mapfile -t NVME_DISKS < <(lsblk -dn -o NAME,TYPE | awk '$2 == "disk" && $1 ~ /^nvme[0-9]+n[0-9]+$/ {print $1}')

if [ "${#NVME_DISKS[@]}" -eq 0 ]; then
  echo "❌ No internal NVMe disk was detected."
  echo ""
  echo "Available disks:"
  lsblk -e7 -d -o NAME,PATH,SIZE,TYPE,FSTYPE,MODEL
  echo ""
  read -rp "Enter the internal disk manually (for example /dev/nvme0n1): " DISK
else
  if [ "${#NVME_DISKS[@]}" -eq 1 ]; then
    DISK="/dev/${NVME_DISKS[0]}"
  else
    echo "Found multiple NVMe disks:"
    for i in "${!NVME_DISKS[@]}"; do
      candidate="/dev/${NVME_DISKS[$i]}"
      echo "  [$((i + 1))] $candidate $(lsblk -dn -o SIZE,MODEL "$candidate")"
    done
    echo ""
    read -rp "Select the NVMe disk to ERASE [1-${#NVME_DISKS[@]}]: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#NVME_DISKS[@]}" ]; then
      echo "❌ Invalid disk selection."
      exit 1
    fi
    DISK="/dev/${NVME_DISKS[$((choice - 1))]}"
  fi
fi

if [ ! -b "$DISK" ]; then
  echo "❌ Disk $DISK not found!"
  exit 1
fi

# Refuse to operate on common live-media devices when auto-detection was used.
case "$DISK" in
  /dev/sda|/dev/sdb|/dev/sdc|/dev/vda|/dev/vdb)
    echo "❌ Refusing to erase $DISK automatically. This may be the live USB."
    exit 1
    ;;
esac

echo ""
echo "╔════════════════════════════════════════╗"
echo "║        DETECTED DISK LAYOUT            ║"
echo "╚════════════════════════════════════════╝"
lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,MODEL,MOUNTPOINTS "$DISK" || true

echo ""
echo "⚠️  WARNING: This will ERASE the disk and create a new partition layout!"
echo "   Disk: $DISK"
echo ""
read -rp "Type 'yes' to continue, anything else to cancel: " confirm
if [ "$confirm" != "yes" ]; then
  echo "✅ Installation cancelled."
  exit 0
fi

echo ""
echo "🧹 Unmounting any existing mounts..."
sudo umount -R /mnt 2>/dev/null || true

echo "🗑️  Wiping disk..."
sudo wipefs -a "$DISK"

echo ""
echo "⚙️  Creating partitions with Disko..."
sudo nix run github:nix-community/disko/latest -- \
  --mode format,mount \
  --flake "$repo_root#nitro-v15" \
  --disk-devices /dev/disk/by-path/"$(udevadm info -q property "$DISK" | grep ID_PATH= | cut -d= -f2)" \
  2>/dev/null || sudo nix run github:nix-community/disko/latest -- \
  --mode format,mount \
  --flake "$repo_root#nitro-v15"

echo ""
echo "📋 Generating hardware configuration..."
sudo mkdir -p /mnt/etc/nixos
sudo nixos-generate-config --root /mnt --no-filesystems

echo "📁 Copying configuration to /mnt/etc/nixos..."
sudo cp -a "$repo_root/." /mnt/etc/nixos/

echo ""
echo "🚀 Installing NixOS..."
sudo nixos-install \
  --no-root-password \
  --flake /mnt/etc/nixos#nitro-v15

echo ""
echo "✅ Installation finished!"
echo "🔄 Reboot and select the NixOS entry in GRUB."
echo "   Command: sudo reboot"
