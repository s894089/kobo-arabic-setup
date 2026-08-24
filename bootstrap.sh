#!/usr/bin/env bash
# One-time: move this setup to /opt/kobo/koreader. Needs your password (sudo).
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/opt/kobo/koreader"
echo "▸ Installing to $DEST"
sudo mkdir -p "$DEST"
sudo rsync -a --exclude backups/ "$SRC/" "$DEST/"
sudo mkdir -p "$DEST/backups"
sudo chown -R "$(id -u):$(id -g)" "$DEST"     # so backups can be written without sudo
echo "✓ Done."
echo
echo "  Run it with:   cd $DEST && ./install.sh --dry-run"
echo "  Then for real: ./install.sh"
