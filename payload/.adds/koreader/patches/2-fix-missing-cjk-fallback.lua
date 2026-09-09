--[[
    Drop the dangling CJK fallback font.

    KOReader hardcodes its fallback font chain in frontend/ui/font.lua:

        fallbacks = {
            [1] = "NotoSans-Regular.ttf",
            [2] = "NotoSansCJKsc-Regular.otf",   <-- 16 MB, deliberately not shipped
            [3] = "NotoSansArabicUI-Regular.ttf",
            ...
            [6] = "nerdfonts/symbols.ttf",
        }

    This setup excludes NotoSansCJKsc-Regular.otf on purpose: it is 16 MB, and
    an Arabic library has no use for Simplified Chinese. But the entry stays in
    the list, so every glyph that misses the primary font walks into a font load
    that cannot succeed. The result is a "Failed to load font" error logged
    dozens of times per boot, and glyphs that should have been picked up further
    down the chain (notably the nerdfonts symbol set at [6]) can render as an
    empty or "?" box instead.

    This patch removes that one entry and renumbers the list so it stays a
    proper sequential array, then fixes up the insert index that KOReader uses
    when the user adds their own extra fallbacks. If the font is ever shipped
    again, or upstream drops it from the list, this patch quietly does nothing.
]]

local Font = require("ui/font")
local logger = require("logger")

local MISSING = "NotoSansCJKsc-Regular.otf"

if type(Font) ~= "table" or type(Font.fallbacks) ~= "table" then
    logger.warn("fix-missing-cjk-fallback: no Font.fallbacks table, skipping")
    return
end

local kept, removed = {}, 0
for _, name in ipairs(Font.fallbacks) do
    if name == MISSING then
        removed = removed + 1
    else
        kept[#kept + 1] = name
    end
end

if removed == 0 then
    -- Already gone: font shipped, or upstream changed the list. Nothing to do.
    return
end

Font.fallbacks = kept

-- additional_fallback_insert_indice points at the slot where user-added
-- fallbacks go, and upstream sets it to sit just after the CJK entry. With that
-- entry gone, shift it back one so it keeps the same meaning, and clamp it so
-- it can never point past the end of the shortened list.
local idx = tonumber(Font.additional_fallback_insert_indice)
if idx then
    idx = idx - 1
    if idx < 1 then idx = 1 end
    if idx > #kept + 1 then idx = #kept + 1 end
    Font.additional_fallback_insert_indice = idx
end

logger.info("fix-missing-cjk-fallback: removed", removed, "dangling entry;",
            #kept, "fallbacks remain, insert index now",
            Font.additional_fallback_insert_indice)
