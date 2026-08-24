# library/ — put the books here

This folder ships **empty**. Cloning the repository will not add, remove or
change any book on your device.

To use it, drop your book folders in here — one folder per subject — and run:

    ../install-library.sh --dry-run
    ../install-library.sh

    library/
      History/
        Some Book - Author.epub
      Novels/
        Another Book - Author.epub

The installer only **adds**. It never deletes anything already on the device,
and it never touches `.sdr` folders, which hold your highlights, notes and
reading positions.

If this folder is empty, the installer says so and exits without touching the
device.

## Why it is empty

A book collection is gigabytes, and single files can exceed GitHub's 100 MB
per-file limit, so it cannot travel through git. Books are shared separately —
on a USB disk or a cloud drive — and copied in here by hand.
