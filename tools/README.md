# library/ — personal tooling, not part of the shared setup

`sync-library.sh` reorganises the books already on a Kobo: it moves and renames
them according to a plan file, carrying each book's `.sdr` folder (highlights,
notes, reading position) along with it.

It is driven by `library-plan.json`, which describes **one specific person's
library** — which book goes where, and which files are duplicates. That file is
gitignored, so cloning this repository gives you the tool but not someone
else's plan.

To use it you would need to write your own `library-plan.json`:

```json
{
  "move":    [["old/path.epub", "new/path.epub"]],
  "review":  [["unclear.pdf",   "_review/unclear.pdf"]],
  "delete":  ["duplicate.epub"],
  "mkdir":   ["History", "Novels"],
  "rmdir":   ["Old Folder"],
  "protect": ["Reading now", "Finished"]
}
```

`protect` folders are never touched: nothing moves out of them and nothing is
deleted from them.

Always run `./sync-library.sh --dry-run` first.
