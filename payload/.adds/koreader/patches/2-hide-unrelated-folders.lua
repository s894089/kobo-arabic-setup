--[[
    Hide non-book folders from KOReader's file browser.

    A Kobo's root holds a few folders that are never books: fonts/ (fonts for
    Kobo's own reader), and the Exported Annotations / Exported Notebooks /
    My Notebooks folders that Kobo's notebook feature creates. KOReader already
    hides things like "System Volume Information" through a hard-coded list in
    frontend/ui/widget/filechooser.lua (FileChooser.exclude_dirs) — but that
    list is a constant, there is no setting for it, so the only way to add to
    it is this patch.

    Only the folder NAMES below are hidden, and only at the level they appear;
    nothing is deleted or moved, and the folders keep working for whatever
    made them. wallpapers/ is deliberately NOT here: it should stay visible.
    To hide another folder, add its exact name to HIDE. To see everything
    again, delete this file. ("Show hidden files" does not undo this: that
    toggle only covers dot-folders.)
]]

local FileChooser = require("ui/widget/filechooser")
local logger = require("logger")

local HIDE = {
    "fonts",
    "Exported Annotations",
    "Exported Notebooks",
    "My Notebooks",
}

if type(FileChooser) ~= "table" or type(FileChooser.exclude_dirs) ~= "table" then
    logger.warn("hide-unrelated-folders: no FileChooser.exclude_dirs, skipping")
    return
end

-- exclude_dirs holds Lua patterns matched against the bare entry name.
-- Escape every magic character so a name is matched literally, then anchor it.
local added = 0
for _, name in ipairs(HIDE) do
    local pattern = "^" .. name:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "$"
    local present = false
    for _, p in ipairs(FileChooser.exclude_dirs) do
        if p == pattern then present = true; break end
    end
    if not present then
        table.insert(FileChooser.exclude_dirs, pattern)
        added = added + 1
    end
end

logger.info("hide-unrelated-folders: hiding", added, "folder name(s) from the file browser")
