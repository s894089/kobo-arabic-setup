#!/usr/bin/env bash
#
#  Pulls your live Kobo's KOReader settings INTO payload/.adds/koreader/.
#  This is install.sh in reverse: instead of pushing the repo to a device,
#  it captures what your device actually has, so the repo stays an honest
#  mirror of your real setup.
#
#  Personal data is excluded automatically — the exact same list as
#  install.sh preserves on a device and .gitignore keeps out of git.
#  Nothing is committed or pushed; you review with `git diff` and decide.
#
#  Usage:  ./tools/sync-from-device.sh --dry-run
#          ./tools/sync-from-device.sh
#
set -euo pipefail
trap 'rc=$?; [ $rc -ne 0 ] && printf "\n\033[31m✗ Aborted at line $LINENO (exit %d).\033[0m\n" "$rc" >&2; exit $rc' ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAYLOAD="$ROOT/payload/.adds/koreader"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

g=$'\033[32m'; y=$'\033[33m'; r=$'\033[31m'; b=$'\033[1m'; o=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$g" "$o" "$*"; }
die(){ printf '%s✗%s %s\n' "$r" "$o" "$*" >&2; exit 1; }
step(){ printf '\n%s▸ %s%s\n' "$b" "$*" "$o"; }

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

step "Checking"
command -v rsync >/dev/null || die "rsync not found."
[ -f "$DEVICE/.kobo/version" ] || die "No Kobo found at $DEVICE. Plug it in, unlock it, tap Connect.
   Or point at it directly:  KOBO_MOUNT=/path/to/kobo $0"
ok "Kobo detected at $DEVICE"

# FAT32 reports every file as executable when mounted on macOS, so a plain
# rsync makes git see a permission-bit "change" on nearly every file with
# zero real content difference. Tell git to stop tracking file mode here.
git -C "$ROOT" config core.fileMode false

# Same exclusions as .gitignore — kept in one place here, referenced from there.
EXCLUDES=(
  --exclude 'settings/*.sqlite3' --exclude 'settings/*.sqlite3-shm' --exclude 'settings/*.sqlite3-wal'
  --exclude 'settings/lookup_history.lua' --exclude 'settings/wikipedia_history.lua'
  --exclude 'settings/battery_stats.lua*' --exclude 'settings/koinsight.lua*'
  --exclude 'history.lua' --exclude 'clipboard/' --exclude 'cache/'
  --exclude 'screenshots/' --exclude 'crash.log' --exclude '._*'
  --exclude 'ota/' --exclude '*.old' --exclude '*.oft' --exclude 'FSCK0000.*'
  --exclude 'fonts/noto/NotoSansCJKsc-Regular.otf'
)

if [ "$DRY" = 1 ]; then
  step "Dry run — comparing device to payload/, nothing written"
  rsync -an --delete --itemize-changes "${EXCLUDES[@]}" \
    "$DEVICE/.adds/koreader/" "$PAYLOAD/" | head -60
  say() { :; }
  exit 0
fi

step "Pulling your device's KOReader settings into the repo"
rsync -a --delete "${EXCLUDES[@]}" "$DEVICE/.adds/koreader/" "$PAYLOAD/"
# The pulled settings.reader.lua carries this device's identity. Strip it,
# same as every shareable payload build has always done.
python3 - "$PAYLOAD/settings.reader.lua" <<'PYEOF'
import sys, re
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
for k in ("device_id", "lastfile", "lastdir"):
    s = re.sub(r'^\s*\["%s"\].*\n' % k, "", s, flags=re.M)
# fonts/noto/NotoSansCJKsc-Regular.otf is deliberately excluded above, so a
# leftover reference to it here would make KOReader log a font-load error
# on every start. Drop the dangling entry, not the whole recently-selected list.
s = re.sub(r'^\s*\[\d+\] = "Noto Sans CJK SC",\n', "", s, flags=re.M)
open(p, "w", encoding="utf-8").write(s)
PYEOF

# Simple UI's config is worth sharing — the page layout, module sizes and bars
# are the whole point of shipping it. But it also carries a runtime cache under
# "simpleui_stale_books_v1": the path of whatever you're reading right now, plus
# every prefetched book path, author and MD5. That is reading data and must never
# reach a public repo. Strip that one key; Simple UI rebuilds it on first run,
# so nothing shareable is lost.
SUI="$PAYLOAD/settings/simpleui/sui_settings.lua"
[ -f "$SUI" ] && python3 - "$SUI" <<'PYEOF'
import sys
p = sys.argv[1]
out, depth, dropping = [], 0, False
for line in open(p, encoding="utf-8").read().splitlines(keepends=True):
    if not dropping and '["simpleui_stale_books_v1"]' in line:
        depth = line.count("{") - line.count("}")
        dropping = depth > 0          # a single-line value ends right here
        continue
    if dropping:
        depth += line.count("{") - line.count("}")
        if depth <= 0:
            dropping = False
        continue
    out.append(line)
open(p, "w", encoding="utf-8").write("".join(out))
PYEOF

ok "payload/.adds/koreader/ now matches your device (minus personal data)"

step "Done"
cd "$ROOT"
if [ -n "$(git status --porcelain -- payload/.adds/koreader 2>/dev/null)" ]; then
  echo "  Review the changes:  git -C \"$ROOT\" diff -- payload/.adds/koreader"
  echo "  Then commit and push when you're happy with them."
else
  echo "  No changes — the repo already matches your device."
fi
