#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPO:?Set GITHUB_REPO=https://github.com/loxedo/nixos-config.git}"
git remote remove origin 2>/dev/null || true
git remote add origin "$GITHUB_REPO"
git push -u origin main
