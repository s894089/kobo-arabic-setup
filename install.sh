#!/usr/bin/env bash
#
#  Kobo Arabic Reading Setup — installer
#  Installs KOReader + plugins + Arabic fonts and dictionaries onto a Kobo.
#  Your books, reading positions, highlights and statistics are never touched.
#
#  Usage:   ./install.sh            install
#           ./install.sh --dry-run  show what would change, change nothing
#           ./install.sh --restore  put the most recent backup back
#
set -euo pipefail
trap 'rc=$?; [ $rc -ne 0 ] && printf "\n\033[31m✗ Aborted at line $LINENO (exit $rc). Nothing further was changed.\033[0m\n" >&2; exit $rc' ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$ROOT/payload"
BACKUPS="$ROOT/backups"
# Find the Kobo on any platform.
#   macOS     /Volumes/KOBOeReader
#   Linux     /media/$USER/KOBOeReader, /run/media/$USER/KOBOeReader
#   Windows   WSL: /mnt/d, /mnt/e …   Git Bash: /d, /e …
# Override with:  KOBO_MOUNT=/path/to/kobo
detect_kobo() {
  local c
  for c in "/Volumes/KOBOeReader" \
           "/media/${USER:-}/KOBOeReader" "/run/media/${USER:-}/KOBOeReader" \
           "/media/KOBOeReader" "/mnt/KOBOeReader"; do
    [ -f "$c/.kobo/version" ] && { printf '%s' "$c"; return 0; }
  done
  for c in /mnt/? /?; do
    [ -f "$c/.kobo/version" ] && { printf '%s' "$c"; return 0; }
  done
  return 1
}
DEVICE="${KOBO_MOUNT:-$(detect_kobo || echo /Volumes/KOBOeReader)}"
STAMP="$(date +%Y%m%d-%H%M%S)"
TMPD="$(mktemp -d)"; KEEPTMP=0
trap '[ "${KEEPTMP:-0}" = 1 ] || rm -rf "$TMPD"' EXIT

DRY=0; RESTORE=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --restore) RESTORE=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

c_ok=$'\033[32m'; c_warn=$'\033[33m'; c_err=$'\033[31m'; c_dim=$'\033[2m'; c_off=$'\033[0m'
say()  { printf '%s\n' "$*"; }

# ─── progress helpers ─────────────────────────────────────────────────────────
# rsync --info=progress2 gives a live percentage for the whole transfer.
# Older rsync (macOS ships 2.6.9) lacks it, so fall back to per-file output.
RSYNC_PROGRESS=()
if rsync --info=progress2 --version >/dev/null 2>&1; then
  RSYNC_PROGRESS=(--info=progress2 --no-inc-recursive)
else
  RSYNC_PROGRESS=(--progress)
fi

copy_with_progress() {   # copy_with_progress <label> <src> <dst> [extra rsync args...]
  local label="$1" src="$2" dst="$3"; shift 3
  local n size
  n="$(safe_count "$src")"; size="$(safe_size "$src")"
  printf '  %s — %s files, %s\n' "$label" "$n" "$size"
  rsync -a "${RSYNC_PROGRESS[@]}" "$@" "$src" "$dst" 2>&1 \
    | while IFS= read -r line; do
        case "$line" in
          *%*) printf '\r  %s' "$(printf '%s' "$line" | tr -s ' ' | cut -c1-70)" ;;
        esac
      done
  printf '\r  %-72s\n' "done."
}

confirm() {  # confirm <prompt>
  local prompt="$1" got
  printf '\n%s%s%s\n' "$c_warn" "$prompt" "$c_off"
  printf '  Continue? [y/N] '
  read -r got
  case "$got" in
    y|Y|yes|YES|Yes) ;;
    *) die "Cancelled — nothing was changed." ;;
  esac
}

ok()   { printf '%s✓%s %s\n' "$c_ok"  "$c_off" "$*"; }
warn() { printf '%s!%s %s\n' "$c_warn" "$c_off" "$*"; }
die()  { printf '%s✗%s %b\n' "$c_err" "$c_off" "$*" >&2; exit 1; }

# Sizing helpers. On a Kobo, find/du exit non-zero because of unreadable system
# folders; under `set -e` that would abort the script silently. These never fail.
safe_count() { find "$1" -type f 2>/dev/null | wc -l | tr -d ' ' || echo 0; }
safe_size()  { du -sh  "$1" 2>/dev/null | cut -f1 | tr -d ' ' || echo '?'; }
safe_size_k(){ du -sk  "$1" 2>/dev/null | cut -f1 | tr -d ' ' || echo 0; }
step() { printf '\n%s▸ %s%s\n' $'\033[1m' "$*" "$c_off"; }

# ─── prerequisites ────────────────────────────────────────────────────────────
step "Checking prerequisites"
command -v rsync >/dev/null || die "rsync not found. Install it and retry."
[ -d "$PAYLOAD" ] || die "payload/ missing next to this script. Is the repo complete?"
[ -d "$DEVICE" ]  || die "No Kobo found. Plug it in, unlock it, and tap Connect on its screen.\n   Looked in /Volumes, /media, /run/media, /mnt and drive letters.\n   If it is elsewhere:  KOBO_MOUNT=/path/to/kobo ./install.sh"
[ -f "$DEVICE/.kobo/version" ] || die "$DEVICE is mounted but is not a Kobo — refusing to touch it."

FW="$(cut -d, -f3 "$DEVICE/.kobo/version" 2>/dev/null || echo unknown)"
ok "Kobo detected — firmware $FW"

FREE_KB=$(df -k "$DEVICE" 2>/dev/null | awk 'NR==2{print $4}' || echo 0)
NEED_KB=$(safe_size_k "$PAYLOAD")
[ "$FREE_KB" -gt "$((NEED_KB + 200000))" ] \
  || die "Not enough space: need ~$((NEED_KB/1024)) MB, have $((FREE_KB/1024)) MB free."
ok "Space available: $((FREE_KB/1024)) MB free, need ~$((NEED_KB/1024)) MB"

# ─── restore mode ─────────────────────────────────────────────────────────────
if [ "$RESTORE" = 1 ]; then
  LAST="$(ls -1d "$BACKUPS"/*/ 2>/dev/null | tail -1 || true)"
  [ -n "$LAST" ] || die "No backups found in $BACKUPS"
  warn "About to restore $LAST over the device."
  printf '  Restore this backup? [y/N] '
  read -r a
  case "$a" in y|Y|yes|YES|Yes) ;; *) die "Cancelled — nothing was changed." ;; esac
  if [ -d "$LAST/.adds" ]; then
    rsync -a --delete "$LAST/.adds/" "$DEVICE/.adds/"
  else
    # the backup holds no .adds/, so this device had none before the install
    warn "This device had no .adds/ before installing — removing what was added."
    rm -rf "$DEVICE/.adds/koreader"
  fi
  [ -d "$LAST/.kobo/dict" ] && rsync -a --delete "$LAST/.kobo/dict/" "$DEVICE/.kobo/dict/"
  ok "Restored .adds/ and .kobo/dict/ from $(basename "${LAST%/}")"
  warn "Fonts added to fonts/ are left in place — delete them by hand if you want them gone."
  say  "Eject and reboot the Kobo."; exit 0
fi

# ─── what will happen ─────────────────────────────────────────────────────────
step "Plan"
cat <<PLAN
  Device      : $DEVICE  (firmware $FW)
  Backup to   : $BACKUPS/$STAMP
  Will REPLACE: .adds/koreader/   (KOReader, plugins, fonts, dictionaries)
                .adds/nm/menu     (NickelMenu entries)
                .kobo/dict/       (Kobo's own dictionaries)
                fonts/            (Arabic fonts for Kobo's reader)
  Will KEEP   : your books, every .sdr folder (positions + highlights),
                reading statistics, history, vocabulary, KoInsight settings
PLAN

if [ "$DRY" = 1 ]; then
  step "Dry run — nothing will be written"
  rsync -an --delete --itemize-changes \
    --exclude 'cache/' --exclude 'screenshots/' --exclude 'crash.log' --exclude 'ota/' \
    --exclude 'history.lua' --exclude 'clipboard/' --exclude 'settings/statistics.sqlite3' \
    --exclude 'settings/bookinfo_cache.sqlite3' --exclude 'settings/vocabulary_builder.sqlite3' \
    --exclude 'settings/lookup_history.lua' --exclude 'settings/wikipedia_history.lua' \
    --exclude 'settings/battery_stats.lua*' --exclude 'settings/koinsight.lua*' \
    "$PAYLOAD/.adds/koreader/" "$DEVICE/.adds/koreader/" > "$TMPD/changes.txt" 2>&1 || true
  TOTAL=$(wc -l < "$TMPD/changes.txt" | tr -d ' ')
  ADD=$(grep -c '^>f+' "$TMPD/changes.txt" 2>/dev/null || echo 0)
  UPD=$(grep -c '^>f\.' "$TMPD/changes.txt" 2>/dev/null || echo 0)
  DEL=$(grep -c '^\*deleting' "$TMPD/changes.txt" 2>/dev/null || echo 0)
  head -40 "$TMPD/changes.txt"
  printf '\n  %s new · %s updated · %s deleted · %s lines total\n' "$ADD" "$UPD" "$DEL" "$TOTAL"
  say "${c_dim}(first 40 shown; full list: $TMPD/changes.txt)${c_off}"
  KEEPTMP=1; exit 0
fi

cat <<WARN

  ${c_warn}Before you agree:${c_off}
    • This REPLACES KOReader and its plugins on the device.
    • Plugins not in this setup will be DELETED.
    • Your books, highlights, reading positions and statistics are NOT touched.
    • A full backup is taken first; undo any time with:  ./install.sh --restore
    • Do not unplug the device until it says Done.

WARN
confirm "This will modify your Kobo."

# ─── 1. backup ────────────────────────────────────────────────────────────────
step "Backing up device configuration"
mkdir -p "$BACKUPS/$STAMP"
if [ -d "$DEVICE/.adds" ]; then
  rsync -a "${RSYNC_PROGRESS[@]}" "$DEVICE/.adds/" "$BACKUPS/$STAMP/.adds/" 2>&1 \
    | while IFS= read -r l; do case "$l" in *%*) printf '\r  %s' "$(printf '%s' "$l" | tr -s ' ' | cut -c1-70)";; esac; done
  printf '\r  %-72s\n' "backup complete."
else
  say "  nothing to back up — this device has no .adds/ yet (a fresh Kobo)"
fi
rsync -a "$DEVICE/.kobo/dict/" "$BACKUPS/$STAMP/.kobo/dict/" 2>/dev/null || true
cp "$DEVICE/.kobo/version" "$BACKUPS/$STAMP/kobo-version.txt" 2>/dev/null || true
ok "Backup: $BACKUPS/$STAMP ($(safe_size "$BACKUPS/$STAMP"))"

# ─── 2. install ───────────────────────────────────────────────────────────────
# --delete removes plugins this setup dropped; the excludes are your personal data,
# which rsync will neither overwrite nor delete.
step "Installing KOReader and plugins"
copy_with_progress "KOReader, plugins, fonts, dictionaries" \
  "$PAYLOAD/.adds/koreader/" "$DEVICE/.adds/koreader/" \
  --delete \
  --exclude 'cache/' --exclude 'screenshots/' --exclude 'crash.log' --exclude 'ota/' \
  --exclude 'history.lua' --exclude 'clipboard/' \
  --exclude 'settings/statistics.sqlite3' --exclude 'settings/bookinfo_cache.sqlite3' \
  --exclude 'settings/vocabulary_builder.sqlite3' --exclude 'settings/lookup_history.lua' \
  --exclude 'settings/wikipedia_history.lua' --exclude 'settings/battery_stats.lua*' \
  --exclude 'settings/koinsight.lua*' 
ok "KOReader $(cat "$PAYLOAD/.adds/koreader/git-rev" 2>/dev/null)"

step "Installing NickelMenu entries, fonts and dictionaries"
mkdir -p "$DEVICE/.adds/nm" "$DEVICE/fonts"
rsync -a "$PAYLOAD/.adds/nm/menu" "$DEVICE/.adds/nm/menu"
rsync -a "$PAYLOAD/fonts/"        "$DEVICE/fonts/"
rsync -a --delete "$PAYLOAD/.kobo/dict/" "$DEVICE/.kobo/dict/"
ok "Fonts and dictionaries in place"

# ─── books (only if library/ has any) ─────────────────────────────────────────
BOOKS="${KOBO_LIBRARY:-$ROOT/library}"
NBOOKS=0
if [ -d "$BOOKS" ]; then
  NBOOKS=$(find "$BOOKS" -type f \
             ! -name 'README.md' ! -name '.gitkeep' ! -name '._*' ! -name '.DS_Store' \
             2>/dev/null | wc -l | tr -d ' ' || echo 0)
fi

if [ "$NBOOKS" -gt 0 ]; then
  step "Copying books"
  say "  $NBOOKS book(s), $(safe_size "$BOOKS")"
  rsync -a "${RSYNC_PROGRESS[@]}" \
    --exclude '*.sdr/' --exclude '._*' --exclude '.DS_Store' \
    --exclude 'README.md' --exclude '.gitkeep' --exclude '.git/' \
    "$BOOKS/" "$DEVICE/" 2>&1 \
    | while IFS= read -r line; do
        case "$line" in *%*) printf '\r  %s' "$(printf '%s' "$line" | tr -s ' ' | cut -c1-70)";; esac
      done
  printf '\r  %-72s\n' "books copied."
else
  step "Books"
  say "  library/ is empty — no books copied. Your device's books are untouched."
  say "  ${c_dim}To add books: put folders into $BOOKS and run this again.${c_off}"
fi

step "Clearing macOS sidecar files"
command -v dot_clean >/dev/null && dot_clean -m "$DEVICE" 2>/dev/null || true
find "$DEVICE" -name '._*' -delete 2>/dev/null || true
find "$DEVICE" -name '.DS_Store' -delete 2>/dev/null || true
ok "device is clean of macOS sidecars"

sync
step "Done"
cat <<'NEXT'
  1. Eject the Kobo (drag to Trash, or Finder's eject arrow)
  2. Reboot it: NickelMenu → Reboot
  3. Open NickelMenu → KOReader+

  First launch is slow — it rebuilds its cover cache. That is expected.
  To undo:  ./install.sh --restore
NEXT
