-- ./settings/bookshelf.lua
return {
    ["active_chip"] = "all",
    ["active_cursor"] = 1,
    ["active_page"] = 1,
    ["author_format"] = "first_last",
    ["aux_data_relocated_v2"] = true,
    ["bookshelf_fonts_seeded"] = true,
    ["bookshelf_ui_font"] = "RobotoCondensed-Regular.ttf",
    ["chip_flex_widths"] = true,
    ["drill_path"] = {},
    ["fullscreen_module_items"] = {
        [1] = {
            ["id"] = "hm_clock",
            ["module"] = "analogue_clock",
            ["type"] = "module",
        },
    },
    ["fullscreen_modules_seeded"] = true,
    ["hero_module_items"] = {
        [1] = {
            ["id"] = "hm_clock",
            ["module"] = "analogue_clock",
            ["type"] = "module",
        },
    },
    ["hero_modules_seeded"] = true,
    ["micro_modules_placement"] = "fullscreen",
    ["migrated"] = true,
    ["quote_of_day_daily_cache"] = {
        ["data"] = {
            ["author"] = "أحمد امين",
            ["chapter"] = "بقلم الدكتور فيليب حتى",
            ["filepath"] = "/mnt/onboard/أقرأ الآن/علمتني الحياة - أحمد أمين.epub",
            ["legacy"] = false,
            ["page"] = "/body/DocFragment[12]/body/p[5]/text().0",
            ["page_display"] = 31,
            ["pos0"] = "/body/DocFragment[12]/body/p[5]/text().0",
            ["text"] = "علمتني الحياة أن أعرب عن آرائي إذا طلب إلى ذلك في اعتدال ولباقة، وطبقا لما يمليه الضمير، ووفقا لما تتطلبه الأمانة الفكرية وذلك بغض النظر عما إذا كانت تلك…",
            ["title"] = "علمتني الحياة",
        },
        ["key"] = "d2026-09-09:0",
    },
    ["start_menu_items"] = {
        [1] = {
            ["id"] = "sm_quote",
            ["module"] = "quote_of_day",
            ["type"] = "module",
        },
        [2] = {
            ["action"] = {
                ["stats_calendar_view"] = true,
            },
            ["icon"] = "",
            ["id"] = "sm_cal",
            ["label"] = "Reading calendar",
            ["type"] = "action",
        },
        [3] = {
            ["action"] = {
                ["toggle_wifi"] = true,
            },
            ["icon"] = "",
            ["id"] = "sm_wifi",
            ["label"] = "Toggle Wi-Fi",
            ["type"] = "action",
        },
        [4] = {
            ["action"] = {
                ["night_mode"] = true,
            },
            ["icon"] = "",
            ["id"] = "sm_night",
            ["label"] = "Toggle night mode",
            ["type"] = "action",
        },
        [5] = {
            ["icon"] = "⚙",
            ["id"] = "sm_settings",
            ["internal"] = "settings",
            ["label"] = "Bookshelf menu",
            ["type"] = "action",
        },
        [6] = {
            ["icon"] = "",
            ["id"] = "sm_close",
            ["internal"] = "close",
            ["label"] = "Exit bookshelf",
            ["scope"] = "library",
            ["type"] = "action",
        },
        [7] = {
            ["icon"] = "",
            ["id"] = "sm_reader_home",
            ["label"] = "Close book",
            ["menu_path"] = {
                [1] = {
                    ["id"] = "filemanager",
                },
            },
            ["scope"] = "reader",
            ["type"] = "action",
        },
        [8] = {
            ["action"] = {
                ["suspend"] = true,
            },
            ["icon"] = "",
            ["id"] = "sm_sleep",
            ["label"] = "Sleep",
            ["type"] = "action",
        },
    },
    ["start_menu_seeded"] = true,
}
