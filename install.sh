#!/usr/bin/env bash
set -euo pipefail

# Generic clean-install workflow for NixOS (Acer Nitro ANV15-51)
#
# This script:
# 1. Detects or accepts your main disk
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

# Auto-detect main disk (largest NVMe or SSD)
echo "🔍 Detecting main disk..."
DISK=$(lsblk -nd -o NAME -S | grep -E '(nvme|sda|sdb|vda)' | head -1)

if [ -z "$DISK" ]; then
  echo "❌ Could not detect a disk. Please specify manually."
  read -rp "Enter disk (e.g., /dev/nvme0n1 or /dev/sda): " DISK
fi

DISK="/dev/$DISK"

if [ ! -b "$DISK" ]; then
  echo "❌ Disk $DISK not found!"
  exit 1
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║        DETECTED DISK LAYOUT            ║"
echo "╚════════════════════════════════════════╝"
lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$DISK" || true

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
