#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' '== GPU =='
lspci -D -nnk | grep -A5 -B2 -Ei 'VGA|3D|Display'

printf '%s\n' '== Displays =='
for f in /sys/class/drm/*/status; do
  printf '%s: ' "$f"
  cat "$f"
done

printf '%s\n' '== Storage =='
lsblk -e7 -o NAME,MODEL,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS

printf '%s\n' '== USB =='
lsusb

printf '%s\n' '== Razer =='
lsusb | grep -Ei 'razer|1d57:fa60' || true

printf '%s\n' '== Audio =='
wpctl status 2>/dev/null || true

printf '%s\n' '== Session =='
printf 'XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-}"
printf 'XDG_CURRENT_DESKTOP=%s\n' "${XDG_CURRENT_DESKTOP:-}"
