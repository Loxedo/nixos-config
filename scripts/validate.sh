#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

command -v nix >/dev/null || { echo "nix is required"; exit 1; }

nix flake check

# Wayland port sanity checks: the production entrypoint must not invoke the old
# X11 compositor or X11-only lock/compositor processes.
if grep -RInE '(^|[^A-Za-z])(picom|i3lock|xrandr|xset|xrdb|redshift)([^A-Za-z]|$)' home/loxedo/crystal; then
  echo "ERROR: X11-only command found in local Crystal Aura port." >&2
  exit 1
fi

echo "Static validation passed."
