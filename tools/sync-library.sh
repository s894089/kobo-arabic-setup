#!/usr/bin/env bash
#
#  PERSONAL — reorganises the books already on your Kobo, in place.
#  Do not publish this: library-plan.json describes your own library.
#
#  It replays the reorganisation directly on the device, so every .sdr folder
#  travels with its book. Your reading positions, highlights and notes survive
#  because they are moved and renamed alongside the file they belong to.
#
#  Usage:  ./sync-library.sh --dry-run   show every action, change nothing
#          ./sync-library.sh             do it
#
set -euo pipefail
trap 'rc=$?; [ $rc -ne 0 ] && printf "\n\033[31m✗ Aborted at line $LINENO (exit $rc). Nothing further was changed.\033[0m\n" >&2; exit $rc' ERR
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAN="$ROOT/library-plan.json"
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
BACKUPS="${KOBO_BACKUPS:-$(cd "$ROOT/.." && pwd)/backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

g=$'\033[32m'; y=$'\033[33m'; r=$'\033[31m'; b=$'\033[1m'; o=$'\033[0m'
die(){ printf '%s✗%s %s\n' "$r" "$o" "$*" >&2; exit 1; }

# Sizing helpers. On a Kobo, find/du exit non-zero because of unreadable system
# folders; under `set -e` that would abort the script silently. These never fail.
safe_count() { find "$1" -type f 2>/dev/null | wc -l | tr -d ' ' || echo 0; }
safe_size()  { du -sh  "$1" 2>/dev/null | cut -f1 | tr -d ' ' || echo '?'; }
safe_size_k(){ du -sk  "$1" 2>/dev/null | cut -f1 | tr -d ' ' || echo 0; }
ok(){  printf '%s✓%s %s\n' "$g" "$o" "$*"; }
step(){ printf '\n%s▸ %s%s\n' "$b" "$*" "$o"; }
warn(){ printf '%s!%s %s\n' "$y" "$o" "$*"; }

RSYNC_PROGRESS=()
if rsync --info=progress2 --version >/dev/null 2>&1; then
  RSYNC_PROGRESS=(--info=progress2 --no-inc-recursive)
else
  RSYNC_PROGRESS=(--progress)
fi

command -v python3 >/dev/null || die "python3 required"
[ -f "$PLAN" ] || die "library-plan.json missing"
[ -d "$DEVICE" ] || die "No Kobo at $DEVICE — plug it in and tap Connect."
[ -f "$DEVICE/.kobo/version" ] || die "$DEVICE is not a Kobo — refusing."
ok "Kobo detected at $DEVICE"

if [ "$DRY" = 0 ]; then
  step "Backing up the whole library first"
  mkdir -p "$BACKUPS/$STAMP-library" || die "Cannot write to $BACKUPS (set KOBO_BACKUPS to override)"
  B="$BACKUPS/$STAMP-library"

  # A full 4 GB copy every run is slow and mostly pointless: the books are only
  # being MOVED, and you already have them. What is irreplaceable is
  #   (a) the .sdr folders — your highlights, notes and reading positions
  #   (b) the files about to be DELETED
  # Both are small. We also record a full manifest so anything can be traced.
  say "  Backing up what is actually at risk, not all 4 GB of books."

  printf '  reading positions and highlights … '
  ( cd "$DEVICE" && find . -type d -name '*.sdr' -not -path './.adds/*' 2>/dev/null ) > "$B/sdr-list.txt" || true
  N_SDR=$(wc -l < "$B/sdr-list.txt" | tr -d ' ')
  ( cd "$DEVICE" && rsync -a --files-from="$B/sdr-list.txt" . "$B/sdr/" 2>/dev/null ) || true
  printf '%s folders\n' "$N_SDR"

  printf '  files scheduled for deletion    … '
  python3 - "$PLAN" "$DEVICE" "$B" <<'PYBK' || true
import json,os,sys,shutil,unicodedata
plan,dev,b=json.load(open(sys.argv[1],encoding='utf-8')),sys.argv[2],sys.argv[3]
N=lambda x: unicodedata.normalize('NFC',x)
real={}
for root,dirs,files in os.walk(dev):
    if any(p.startswith('.') for p in os.path.relpath(root,dev).split(os.sep)): continue
    for n in list(dirs)+files:
        rp=os.path.relpath(os.path.join(root,n),dev); real.setdefault(N(rp),rp)
n=0
for rel in plan['delete']:
    src=os.path.join(dev,real.get(N(rel),rel))
    if not os.path.exists(src): continue
    dst=os.path.join(b,'deleted',real.get(N(rel),rel))
    os.makedirs(os.path.dirname(dst),exist_ok=True)
    try:
        shutil.copytree(src,dst) if os.path.isdir(src) else shutil.copy2(src,dst); n+=1
    except OSError: pass
print(n, end='')
PYBK
  printf ' files\n'

  printf '  full manifest                   … '
  ( cd "$DEVICE" && find . -not -path './.adds/*' -not -path './System Volume Information/*' \
      -exec ls -ld {} \; 2>/dev/null > "$B/manifest.txt" ) || true
  printf '%s entries\n' "$(wc -l < "$B/manifest.txt" 2>/dev/null | tr -d ' ' || echo 0)"

  ok "Backup: $B ($(safe_size "$B"))"
  say "  Your books themselves are only moved, never deleted — they stay on the device."

  NMOVE=$(python3 -c "import json;p=json.load(open('$PLAN'));print(len(p['move'])+len(p['review']))")
  NDEL=$(python3 -c "import json;p=json.load(open('$PLAN'));print(len(p['delete']))")
  cat <<WARN

  ${y}Before you agree:${o}
    • $NMOVE books will be MOVED and RENAMED on the device.
    • $NDEL files will be DELETED — every one is copied into the backup first.
    • Each book's .sdr folder moves with it, so highlights and reading
      positions are preserved.
    • These folders are NOT touched: $(python3 -c "import json;print(' · '.join(json.load(open('$PLAN'))['protect']))")
    • Do not unplug the device until it says Done.

WARN
  printf '  Type YES to continue, or press Enter to cancel: '
  read -r a; [ "$a" = "YES" ] || die "Cancelled — nothing was changed."
fi

printf '  %sProtected — untouched:%s %s\n' "$g" "$o" \
  "$(python3 -c "import json;print(' · '.join(json.load(open('$PLAN'))['protect']))")"

step "Reorganising"
DRY=$DRY DEVICE="$DEVICE" PLAN="$PLAN" python3 <<'PY'
import json, os, shutil, sys, unicodedata
dev=os.environ['DEVICE']; dry=os.environ['DRY']=='1'
plan=json.load(open(os.environ['PLAN'],encoding='utf-8'))

# The device's filenames may differ from the plan's only by unicode
# normalisation or stray bidi marks. Build a lookup so we still find them.
BIDI=''.join(chr(c) for c in (0x200e,0x200f,0x202a,0x202b,0x202c,0x202d,0x202e,
                              0x2066,0x2067,0x2068,0x2069,0x200b,0xfeff))
def norm(s):
    s=unicodedata.normalize('NFC',s).replace('\xa0',' ')
    return ''.join(c for c in s if c not in BIDI)

real={}
for root,dirs,files in os.walk(dev):
    if any(p.startswith('.') for p in os.path.relpath(root,dev).split(os.sep)): continue
    for n in list(dirs)+files:
        rp=os.path.relpath(os.path.join(root,n),dev)
        real.setdefault(norm(rp),rp)

def dpath(rel):
    return os.path.join(dev, real.get(norm(rel), rel))

stats=dict(moved=0,sdr=0,deleted=0,missing=0,already=0,clash=0,failed=0)
total=len(plan['move'])+len(plan['review'])+len(plan['delete'])
done=[0]
def tick(label):
    done[0]+=1
    pct=int(done[0]*100/total) if total else 100
    sys.stdout.write(f"\r  [{pct:3d}%] {done[0]}/{total}  {label[:52]:<52}")
    sys.stdout.flush()
for c in plan['mkdir']:
    p=os.path.join(dev,c)
    if not os.path.isdir(p):
        print(f"  mkdir  {c}")
        if not dry: os.makedirs(p,exist_ok=True)

def relocate(src,dst,tag):
    s,d = dpath(src), os.path.join(dev,dst)
    if not os.path.exists(s):
        if os.path.exists(d): stats['already']+=1      # already done on an earlier run
        else:                 stats['missing']+=1
        return
    if os.path.abspath(s) == os.path.abspath(d):
        stats['already']+=1; return
    if dry: print(f"  {tag}   {src}\n      -> {dst}")
    else:   tick(os.path.basename(dst))
    if not dry:
        os.makedirs(os.path.dirname(d),exist_ok=True)
        if os.path.exists(d):
            stats['clash']+=1; print(f"\n  ! destination already exists, skipped: {dst}"); return
        try: shutil.move(s,d)
        except OSError as e:
            stats['failed']+=1; print(f"\n  ! could not move {src}: {e}"); return
    stats['moved']+=1
    # The book's .sdr folder must follow it. Several files (e.g. the .epub and
    # .pdf of one title) can share a single .sdr, so it may already have moved.
    ss = dpath(os.path.splitext(src)[0]+'.sdr')
    ds = os.path.join(dev, os.path.splitext(dst)[0]+'.sdr')
    if os.path.isdir(ss) and os.path.abspath(ss) != os.path.abspath(ds) and not os.path.exists(ds):
        print(f"\n      +sdr {os.path.basename(ds)}")
        if not dry:
            try:
                shutil.move(ss,ds); stats['sdr']+=1
            except OSError as e:
                print(f"\n  ! could not move {os.path.basename(ss)}: {e}")
        else:
            stats['sdr']+=1

for src,dst in plan['move']:   relocate(src,dst,'move')
for src,dst in plan['review']: relocate(src,dst,'flag')

for src in plan['delete']:
    p=dpath(src)
    if not os.path.exists(p): continue
    if dry: print(f"  del    {src}")
    else:   tick("removing "+os.path.basename(src))
    if not dry:
        shutil.rmtree(p) if os.path.isdir(p) else os.remove(p)
    stats['deleted']+=1

# Retired folders are removed outright. If anything unexpected is still inside,
# it is moved to _للمراجعة rather than deleted.
for c in plan['rmdir']:
    p=dpath(c)
    if not os.path.isdir(p): continue
    left=[f for f in os.listdir(p) if not f.startswith('.')]
    if left:
        salv=os.path.join(dev,'_للمراجعة')
        print(f"  {len(left)} unexpected item(s) in {c} -> _للمراجعة")
        if not dry:
            os.makedirs(salv,exist_ok=True)
            for f in left:
                t=os.path.join(salv,f)
                if os.path.exists(t): t=os.path.join(salv,c.replace('/','_')+'__'+f)
                shutil.move(os.path.join(p,f),t)
    print(f"  rmdir  {c}")
    if not dry:
        shutil.rmtree(p,ignore_errors=True)

if not dry: sys.stdout.write("\r"+" "*78+"\r")
print(f"\n  moved {stats['moved']} · .sdr carried {stats['sdr']} · deleted {stats['deleted']}")
print(f"  already in place {stats['already']} · not found {stats['missing']} · name clash {stats['clash']} · failed {stats['failed']}")
PY

if [ "$DRY" = 1 ]; then
  printf '\n%sDry run — nothing was changed.%s\n' "$y" "$o"; exit 0
fi

# macOS writes AppleDouble sidecars (._name.epub) onto the Kobo's FAT32 volume.
# Kobo lists many of them as phantom, unopenable books. Clear them every run.
step "Clearing macOS sidecar files"
N_JUNK=$(find "$DEVICE" -name '._*' 2>/dev/null | wc -l | tr -d ' ')
command -v dot_clean >/dev/null && dot_clean -m "$DEVICE" 2>/dev/null || true
find "$DEVICE" -name '._*' -delete 2>/dev/null || true
find "$DEVICE" -name '.DS_Store' -delete 2>/dev/null || true
rm -rf "$DEVICE/.Trashes" 2>/dev/null || true
ok "removed $N_JUNK sidecar file(s)"
sync
step "Done"
echo "  1. Eject the Kobo"
echo "  2. NickelMenu → Import books   (rescans the library)"
echo "  3. Your highlights and reading positions moved with their books."
