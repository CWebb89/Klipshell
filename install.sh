#!/bin/bash
# klipshell install script — Moonraker dashboard/console for Quickshell.
# Writes only per-user config: matugen template registration, and the
# machine-local printer list on a fresh clone.
# Idempotent; safe to re-run. No root, no package installs.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"

echo "Installing klipshell from $REPO"

for tool in quickshell curl; do
  command -v "$tool" >/dev/null 2>&1 || echo "NOTE — missing tool: $tool"
done

# ── 1. matugen template (additive; never rewrites the rest of the config) ─
MGCONF="$HOME/.config/matugen/config.toml"
MGDIR="$HOME/.config/matugen"
MAT_TEMPLATE="$REPO/assets/matugen/klipshell-colors.json"

if command -v matugen >/dev/null 2>&1; then
  mkdir -p "$MGDIR/templates"
  cp -n "$MAT_TEMPLATE" "$MGDIR/templates/klipshell-colors.json"
  if ! grep -q "klipshell-colors.json" "$MGCONF" 2>/dev/null; then
    cp "$MGCONF" "$MGCONF.klipshell.bak" 2>/dev/null || true
    cat >> "$MGCONF" <<EOF

# added by klipshell install.sh
[templates.klipshell]
input_path = '~/.config/matugen/templates/klipshell-colors.json'
output_path = '~/.cache/matugen/klipshell-colors.json'
EOF
    echo "  registered matugen template (backup: $MGCONF.klipshell.bak)"
  fi
else
  echo "  matugen not found — colors won't update; edit src/theme/Colors.qml defaults"
fi

# ── 2. Printer list (machine-local; gitignored, never committed) ─────────
PRINTERS="$REPO/src/config/printers.json"
PRINTERS_EXAMPLE="$REPO/src/config/printers.example.json"

if [ ! -f "$PRINTERS" ]; then
  cp "$PRINTERS_EXAMPLE" "$PRINTERS"
  echo "  seeded src/config/printers.json — replace the example hosts with your own"
else
  echo "  src/config/printers.json exists — left alone"
fi

echo "Done."