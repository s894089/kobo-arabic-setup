#!/usr/bin/env bash
#
#  Copies the shared book library onto a Kobo.
#  Adds books; never deletes anything already on the device, and never touches
#  .sdr folders (your highlights, notes and reading positions).
#
#  Usage:  ./install-library.sh --dry-run
#          ./install-library.sh
#          ./install-library.sh --folder "روايات"     one folder only
#
set -euo pipefail
trap 'rc=$?; [ $rc -ne 0 ] && printf "\n\033[31m✗ Aborted at line $LINENO (exit $rc).\033[0m\n" >&2; exit $rc' ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOKS="$ROOT/library"
# ─── find the Kobo, on any platform ───────────────────────────────────────────
# macOS      /Volumes/KOBOeReader
# Linux      /media/$USER/KOBOeReader, /run/media/$USER/KOBOeReader, /mnt/...
# WSL        /mnt/d, /mnt/e ...        (Windows drive letters)
# Git Bash   /d, /e ...
# Override any of this with:  KOBO_MOUNT=/path/to/kobo
detect_kobo() {
  local c
  for c in "/Volumes/KOBOeReader" \
           "/media/$USER/KOBOeReader" "/run/media/$USER/KOBOeReader" \
           "/media/KOBOeReader" "/mnt/KOBOeReader"; do
    [ -f "$c/.kobo/version" ] && { printf '%s' "$c"; return 0; }
  done
  for c in /mnt/? /?; do            # WSL and Git Bash drive letters
    [ -f "$c/.kobo/version" ] && { printf '%s' "$c"; return 0; }
  done
  return 1
}
DEVICE="${KOBO_MOUNT:-$(detect_kobo || echo /Volumes/KOBOeReader)}"
DRY=0; ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --folder)  ONLY="${2:-}"; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac; shift
done

g=$'\033[32m'; y=$'\033[33m'; r=$'\033[31m'; b=$'\033[1m'; o=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$g" "$o" "$*"; }
die(){ printf '%s✗%s %s\n' "$r" "$o" "$*" >&2; exit 1; }
step(){ printf '\n%s▸ %s%s\n' "$b" "$*" "$o"; }
safe_size(){ du -sh "$1" 2>/dev/null | cut -f1 | tr -d ' ' || echo '?'; }
safe_size_k(){ du -sk "$1" 2>/dev/null | cut -f1 | tr -d ' ' || echo 0; }

RSYNC_PROGRESS=()
if rsync --info=progress2 --version >/dev/null 2>&1; then
  RSYNC_PROGRESS=(--info=progress2 --no-inc-recursive)
else RSYNC_PROGRESS=(--progress); fi

step "Checking"
command -v rsync >/dev/null || die "rsync not found."
[ -d "$BOOKS" ] || die "library/ not found next to this script."
[ -d "$DEVICE" ] || die "No Kobo found. Plug it in, unlock it, tap Connect.\n   If it is somewhere unusual:  KOBO_MOUNT=/path/to/kobo $0"
[ -f "$DEVICE/.kobo/version" ] || die "$DEVICE is not a Kobo — refusing to touch it."
ok "Kobo detected"

SRCDIR="$BOOKS"; [ -n "$ONLY" ] && { SRCDIR="$BOOKS/$ONLY"; [ -d "$SRCDIR" ] || die "No such folder: $ONLY"; }
NEED_K=$(safe_size_k "$SRCDIR")
FREE_K=$(df -k "$DEVICE" 2>/dev/null | awk 'NR==2{print $4}' || echo 0)
NBOOKS=$(find "$SRCDIR" -type f ! -name 'README.md' ! -name '.gitkeep' ! -name '._*' 2>/dev/null | wc -l | tr -d ' ')
if [ "$NBOOKS" -eq 0 ]; then
  printf '\n%sThe library folder is empty — nothing to copy.%s\n' "$y" "$o"
  say "  Put your book folders into:  $BOOKS"
  say "  One folder per subject, then run this again."
  say "  Your device has NOT been touched."
  exit 0
fi
printf '  %s books · %s\n' "$NBOOKS" "$(safe_size "$SRCDIR")"
printf '  device has %s MB free\n' "$((FREE_K/1024))"
[ "$FREE_K" -gt "$((NEED_K + 100000))" ] || die "Not enough space on the device."

if [ "$DRY" = 1 ]; then
  step "Dry run — nothing will be written"
  TMP="$(mktemp)"
  rsync -an --itemize-changes "$SRCDIR/" "$DEVICE/${ONLY:+$ONLY/}" > "$TMP" 2>&1 || true
  NEW=$(grep -c '^>f+' "$TMP" 2>/dev/null || echo 0)
  head -25 "$TMP"; printf '\n  %s new file(s) would be copied.\n' "$NEW"
  rm -f "$TMP"; exit 0
fi

cat <<WARN

  ${y}Before you agree:${o}
    • $NBOOKS books will be COPIED onto the device.
    • Nothing already there is deleted — this only adds.
    • .sdr folders (highlights, notes, positions) are never touched.
    • Books with the same name are overwritten by this copy.
    • Do not unplug until it says Done.

WARN
printf '  Type COPY to continue, or press Enter to cancel: '
read -r a; [ "$a" = "COPY" ] || die "Cancelled — nothing was changed."

step "Copying books"
rsync -a "${RSYNC_PROGRESS[@]}" \
  --exclude '*.sdr/' --exclude '._*' --exclude '.DS_Store' \
  --exclude 'README.md' --exclude '.gitkeep' \
  "$SRCDIR/" "$DEVICE/${ONLY:+$ONLY/}" 2>&1 \
  | while IFS= read -r line; do
      case "$line" in *%*) printf '\r  %s' "$(printf '%s' "$line" | tr -s ' ' | cut -c1-70)";; esac
    done
printf '\r  %-72s\n' "copy complete."

step "Clearing macOS sidecar files"
command -v dot_clean >/dev/null && dot_clean -m "$DEVICE" 2>/dev/null || true
find "$DEVICE" -name '._*' -delete 2>/dev/null || true
find "$DEVICE" -name '.DS_Store' -delete 2>/dev/null || true
ok "clean"

sync
step "Done"
echo "  1. Eject the Kobo"
echo "  2. NickelMenu → Import books   (Kobo rescans; this can take a few minutes)"
