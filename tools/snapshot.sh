#!/bin/bash
# klipshell snapshot — git-free rollback net.
# Writes a timestamped tar of the whole checkout to a durable state dir and
# prunes to the newest 20. klipshell is not under version control, so this is
# the only revert source. Run before any risky multi-file pass.
#
# Usage: ./tools/snapshot.sh [label]
#   ./tools/snapshot.sh pre-refactor

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SNAPSHOT_DIR="${KLIPSHELL_SNAPSHOT_DIR:-$HOME/.local/state/klipshell/snapshots}"
LABEL="${1:-manual}"
KEEP=20

mkdir -p "$SNAPSHOT_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$SNAPSHOT_DIR/klipshell-$STAMP-$LABEL.tar.gz"

tar czf "$OUT" \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  -C "$(dirname "$REPO")" "$(basename "$REPO")"

echo "snapshot: $OUT"
echo "sha256:   $(sha256sum "$OUT" | cut -d' ' -f1)"
echo "size:     $(du -h "$OUT" | cut -f1)"

ls -1t "$SNAPSHOT_DIR" | tail -n +$((KEEP + 1)) | while read -r old; do
  rm -- "$SNAPSHOT_DIR/$old"
done
