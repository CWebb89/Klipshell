#!/bin/bash
# klipshell verification gate — the AGENTS.md command list as one command.
#
# Blocking (any failure exits 1): qmllint errors, shell syntax, the three
# test suites. Advisory: the same qmllint pass with warnings VISIBLE — a
# --silent clean run says nothing about warnings, so this surfaces them
# without failing the gate. test-transport exits 2 without a Hyprland seat
# and is reported as SKIP.
#
# Usage: ./tools/verify.sh

set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

fail=0

fail_step() {
  printf '%s\n' "$1" | sed 's/^/      /'
}

check() {
  local name="$1"; shift
  local out code
  out="$("$@" 2>&1)"; code=$?
  if [ "$code" -eq 0 ]; then
    echo "PASS  $name"
  elif [ "$code" -eq 2 ] && [ "$name" = "transport" ]; then
    echo "SKIP  $name (needs a Hyprland seat)"
  else
    echo "FAIL  $name"
    fail_step "$out"
    fail=1
  fi
}

check "qmllint (errors)"   bash -O globstar -c 'qmllint --silent shell.qml src/**/*.qml'
check "shell syntax"       bash -c 'bash -n install.sh && bash -n launch.sh'
check "gcode parser"       node src/gcode/test-parse.js
check "settings logic"     node src/config/test-settings.js
check "icon glyphs"        python3 tools/check-icons.py
check "transport"          python3 tools/test-transport.py

echo
echo "--- qmllint warnings (advisory, not a failure) ---"
warnings="$(bash -O globstar -c 'qmllint shell.qml src/**/*.qml' 2>&1 || true)"
summary="$(printf '%s\n' "$warnings" | grep -E '^(Warning|Error):' || true)"
if [ -n "$summary" ]; then
  printf '%s\n' "$summary" | sed 's/^/      /'
  printf '      (%s line(s); full qmllint output: qmllint shell.qml src/**/*.qml)\n' \
    "$(printf '%s\n' "$summary" | wc -l)"
else
  echo "      none"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "verify: OK"
else
  echo "verify: FAILED"
fi
exit "$fail"
