#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

command -v nix >/dev/null || { echo 'nix is required'; exit 1; }
command -v bash >/dev/null || { echo 'bash is required'; exit 1; }

bash -n install.sh
bash -n scripts/hardware-check.sh

# The repository intentionally has one installation entrypoint.
if [[ -e scripts/install.sh ]]; then
  echo 'ERROR: scripts/install.sh must not exist.' >&2
  exit 1
fi

# Keep the Crystal port free of commands that require an X11 session.
if grep -RInE '(^|[^A-Za-z])(picom|i3lock|xrandr|xset|xrdb|redshift)([^A-Za-z]|$)' home/loxedo/crystal; then
  echo 'ERROR: X11-only command found in the Crystal Aura port.' >&2
  exit 1
fi

nix flake check

echo 'Static validation passed.'
