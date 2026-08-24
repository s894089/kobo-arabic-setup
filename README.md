# Kobo Arabic Reading Setup

A one-command setup for reading Arabic on a Kobo: KOReader with Arabic
typefaces, Arabic↔English dictionaries, and a curated set of plugins.

**Your books, reading positions, highlights and statistics are never touched.**

---

## What it installs

| | |
|---|---|
| **KOReader** | v2026.07.1 — a far better reader than Kobo's own, especially for PDFs |
| **Amiri** | Classical naskh typeface, plus **AmiriQuran** for fully-vocalised text |
| **Arabic→English** | 26,578 words, with inflection matching (so `والكتاب` resolves to `كتاب`) |
| **English→Arabic** | 87,423 words |
| **Project: Title** | v3.8.3 — a much better library screen |
| **App Store** | Browse and update KOReader plugins on the device itself |
| **LocalSend** | Wireless file transfer, no cable and no server |

It also sets Arabic as the text language for correct justification and
hyphenation, and trims Kobo's bundled dictionaries down to English only.

The interface stays in **English**. Only the *text rendering* language changes.

---

## Prerequisites

1. **A Kobo already running [NickelMenu](https://pgaskin.net/NickelMenu/).**
   This setup installs KOReader; it does not install NickelMenu. Since
   NickelMenu is the only way to launch KOReader, without it you would have
   installed a reader you cannot open.
2. **A shell with `rsync`, `git` and `python3`.** See your platform below.
3. **~200 MB free** on the device.
4. The Kobo **plugged in, unlocked, and set to Connect**.

### macOS

Everything is already there. `rsync`, `git` and `python3` ship with the system
(you may be prompted to install Xcode command line tools the first time).

The Kobo appears at `/Volumes/KOBOeReader` and is found automatically.

### Linux

Install the tools if you don't have them:

```bash
sudo apt install git rsync python3          # Debian, Ubuntu
sudo dnf install git rsync python3          # Fedora
```

The Kobo usually mounts at `/media/$USER/KOBOeReader` or
`/run/media/$USER/KOBOeReader`; both are found automatically.

### Windows

The scripts are bash, so you need one of these:

**Option A — WSL (recommended).** In PowerShell as administrator:

```powershell
wsl --install
```

Reboot, open **Ubuntu** from the Start menu, then:

```bash
sudo apt update && sudo apt install git rsync python3
```

Your Kobo appears in WSL as a drive letter under `/mnt`. If it is drive `E:`
it will be `/mnt/e`, and the scripts find it automatically.

**Option B — Git Bash.** Install [Git for Windows](https://git-scm.com/download/win),
which gives you a bash shell. Note that Git Bash does **not** include `rsync`,
so you would have to add it separately — WSL is the easier path.

In Git Bash the Kobo is `/e` for drive `E:`, also found automatically.

**If your device is not found**, point at it directly:

```bash
KOBO_MOUNT=/mnt/e ./install.sh
```

## Install

```bash
git clone <repository-url> kobo-arabic-setup
cd kobo-arabic-setup

./bootstrap.sh           # optional: move to /opt/kobo/koreader, asks for your password once
./install.sh --dry-run   # see exactly what would change, write nothing
./install.sh             # do it — backs up first, asks you to type INSTALL
```

Then: eject the Kobo → reboot it → *NickelMenu → KOReader+*

### Adding books

The `library/` folder ships **empty**, so cloning never touches your books.
Drop your own book folders into it — one folder per subject — then:

```bash
./install-library.sh --dry-run
./install-library.sh
```

It only adds. Nothing already on the device is deleted, and `.sdr` folders
(your highlights, notes and reading positions) are never touched. If the folder
is empty the installer says so and exits without touching anything.

First launch is slow while it rebuilds its cover cache. That is normal.

### Undo

```bash
./install.sh --restore
```

Every run backs up the device's `.adds/` and `.kobo/dict/` to `backups/<timestamp>/`
**before** writing anything. `--restore` puts the most recent one back.

---

## What is kept, what is replaced

**Replaced** — `.adds/koreader/`, `.adds/nm/menu`, `.kobo/dict/`, `fonts/`

**Kept, always** — your books · every `.sdr` folder (reading positions and
highlights) · `statistics.sqlite3` · `history.lua` · vocabulary builder ·
KoInsight server settings

The installer uses `rsync --delete` so that plugins this setup drops are
genuinely removed rather than left behind — but every personal file above is
excluded from both the copy and the delete.

---

## A note on `.sdr` folders

KOReader stores each book's reading position, highlights and per-book layout in
a `.sdr` folder **next to the book, matched by filename**. If you rename or move
a book, rename its `.sdr` folder identically or you will lose your highlights.
This installer never touches them.

---

## Credits and licences

- [KOReader](https://github.com/koreader/koreader) — AGPL-3.0
- [Project: Title](https://github.com/joshuacant/ProjectTitle) by joshuacant
- [App Store](https://github.com/omer-faruq/appstore.koplugin) by omer-faruq
- [LocalSend for KOReader](https://github.com/kaikozlov/localsend.koplugin) by kaikozlov
- [Amiri](https://github.com/aliftype/amiri) by Khaled Hosny — SIL OFL 1.1
- [Project: Title](https://github.com/joshuacant/ProjectTitle) — pin the release that names your KOReader version
- Arabic→English dictionary — [wiktionary_stardict](https://github.com/xxyzz/wiktionary_stardict), Wiktionary data, CC BY-SA 4.0
- English→Arabic dictionary — converted from [Arabeyes](https://www.arabeyes.org/) data

The scripts in this repository are MIT. Bundled third-party software keeps its
own licence, included alongside it.
