#!/bin/sh
set -eu

# Wayland replacement for Aura's old X11-heavy autorun script.
# NixOS now provides these helpers declaratively; this script only starts
# services that are genuinely useful to the session.

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null || true
fi
