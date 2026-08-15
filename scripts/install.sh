#!/usr/bin/env bash
set -euo pipefail

# This script intentionally stops before destructive partitioning until the
# target disk and filesystem layout are explicitly reviewed.

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as a normal user, not directly as root."
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

command -v nix >/dev/null || { echo "nix is required"; exit 1; }
command -v git >/dev/null || { echo "git is required"; exit 1; }

printf '%s\n' 'NixOS clean installer scaffold'
printf '%s\n' 'Detected target model: Acer Nitro ANV15-51'
printf '%s\n' 'Expected GPUs: Intel 00:02.0 + NVIDIA 01:00.0'
printf '%s\n' 'Expected displays: eDP-1 165Hz + HDMI-A-2 74.97Hz'
printf '%s\n' ''
printf '%s\n' 'SAFETY: destructive disk operations are not implemented yet.'
printf '%s\n' 'Before enabling them, review the final storage layout in this repository.'

nix flake check .

printf '%s\n' 'Flake checks passed. The destructive install stage is deliberately not enabled yet.'
