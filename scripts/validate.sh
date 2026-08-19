#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

command -v nix >/dev/null || { echo 'nix is required'; exit 1; }
command -v bash >/dev/null || { echo 'bash is required'; exit 1; }
command -v sha256sum >/dev/null || { echo 'sha256sum is required'; exit 1; }

export NIX_CONFIG='experimental-features = nix-command flakes'

bash -n install.sh
bash -n scripts/hardware-check.sh
bash -n home/loxedo/crystal/autorun.sh

# Parse repository-owned Crystal Lua files with the exact Lua ABI used by SomeWM.
mapfile -d '' crystal_lua_files < <(
  find home/loxedo/crystal -type f -name '*.lua' -print0
)

nix shell nixpkgs#lua5_3 --command bash -c '
  set -euo pipefail
  for file do
    lua -e "assert(loadfile(arg[1]))" -- "$file"
  done
' bash "${crystal_lua_files[@]}"

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

# The SomeWM derivation must not replace Nix's generated PKG_CONFIG_PATH.
if grep -n '^[[:space:]]*PKG_CONFIG_PATH[[:space:]]*=' pkgs/somewm.nix; then
  echo 'ERROR: SomeWM must not override PKG_CONFIG_PATH.' >&2
  exit 1
fi

# Lockfile changes are intentional maintainer actions, never side effects of validation.
lock_before="$(sha256sum flake.lock)"

nix flake check --no-write-lock-file
nix build '.#nixosConfigurations.nitro-v15.config.system.build.toplevel' --no-link --no-write-lock-file
nix build '.#somewm-stable' --no-link --no-write-lock-file

lock_after="$(sha256sum flake.lock)"
if [[ "$lock_before" != "$lock_after" ]]; then
  echo 'ERROR: validation modified flake.lock.' >&2
  exit 1
fi

echo 'Static, Lua-syntax, lockfile, system-build, SomeWM test-suite, and package-build validation passed.'
