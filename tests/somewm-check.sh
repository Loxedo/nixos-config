#!/usr/bin/env bash
set -euo pipefail

SOMEWM="${1:?usage: somewm-check.sh /path/to/somewm}"

if [[ ! -x "$SOMEWM" ]]; then
  echo "error: SomeWM executable not found: $SOMEWM" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

run_check() {
  local name="$1"
  local expected="$2"
  local config="$3"
  local output
  local status=0

  output=$("$SOMEWM" --check "$config" 2>&1) || status=$?

  if [[ "$status" -ne "$expected" ]]; then
    echo "FAIL: $name: expected exit $expected, got $status" >&2
    echo "$output" >&2
    exit 1
  fi

  printf 'PASS: %s\n' "$name"
}

cat > "$TMP_DIR/valid.lua" <<'EOF'
local x = 1
return x
EOF
run_check "valid config" 0 "$TMP_DIR/valid.lua"

cat > "$TMP_DIR/warning.lua" <<'EOF'
local cmd = "xclip -selection clipboard"
return cmd
EOF
run_check "warning detection" 1 "$TMP_DIR/warning.lua"

cat > "$TMP_DIR/critical.lua" <<'EOF'
local handle = io.popen("xrandr --query")
return handle
EOF
run_check "critical X11 detection" 2 "$TMP_DIR/critical.lua"

cat > "$TMP_DIR/syntax.lua" <<'EOF'
local x = {
  foo = "bar"
  baz = "qux"
}
EOF
run_check "syntax error detection" 2 "$TMP_DIR/syntax.lua"

printf '%s\n' 'SomeWM --check regression suite passed.'
