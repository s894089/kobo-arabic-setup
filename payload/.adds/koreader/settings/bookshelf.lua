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
    ["home_expanded"] = false,
    ["micro_modules_placement"] = "fullscreen",
    ["migrated"] = true,
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
    ["tabs"] = {
        [1] = {
            ["enabled"] = true,
            ["filter"] = {
                ["folders"] = {
                    ["exclude"] = {
                        ["/mnt/onboard/fonts"] = true,
                    },
                },
            },
            ["id"] = "all",
            ["label"] = "Home",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "filename",
                    ["reverse"] = false,
                },
            },
            ["source"] = {
                ["kind"] = "all",
            },
        },
        [2] = {
            ["enabled"] = true,
            ["filter"] = {
                ["folders"] = {
                    ["exclude"] = {
                        ["/mnt/onboard/fonts"] = true,
                    },
                },
            },
            ["id"] = "recent",
            ["label"] = "Recent",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "last_opened",
                    ["reverse"] = true,
                },
            },
            ["source"] = {
                ["kind"] = "recent",
            },
        },
        [3] = {
            ["enabled"] = false,
            ["filter"] = {
                ["folders"] = {
                    ["exclude"] = {
                        ["/mnt/onboard/fonts"] = true,
                    },
                },
            },
            ["id"] = "latest",
            ["label"] = "Latest",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "date_added",
                    ["reverse"] = true,
                },
            },
            ["source"] = {
                ["kind"] = "latest",
            },
        },
        [4] = {
            ["enabled"] = true,
            ["filter"] = {},
            ["id"] = "series",
            ["label"] = "Series",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "series_name",
                    ["reverse"] = false,
                },
            },
            ["source"] = {
                ["kind"] = "series",
            },
        },
        [5] = {
            ["enabled"] = false,
            ["filter"] = {},
            ["id"] = "authors",
            ["label"] = "Authors",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "author_surname",
                    ["reverse"] = false,
                },
            },
            ["source"] = {
                ["kind"] = "authors",
            },
        },
        [6] = {
            ["enabled"] = false,
            ["filter"] = {},
            ["id"] = "genres",
            ["label"] = "Genres",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "book_count",
                    ["reverse"] = true,
                },
            },
            ["source"] = {
                ["kind"] = "genres",
            },
        },
        [7] = {
            ["enabled"] = false,
            ["filter"] = {},
            ["id"] = "tags",
            ["label"] = "Tags",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "book_count",
                    ["reverse"] = true,
                },
            },
            ["source"] = {
                ["kind"] = "tags",
            },
        },
        [8] = {
            ["enabled"] = false,
            ["filter"] = {},
            ["id"] = "languages",
            ["label"] = "Languages",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "book_count",
                    ["reverse"] = true,
                },
            },
            ["source"] = {
                ["kind"] = "languages",
            },
        },
        [9] = {
            ["enabled"] = true,
            ["filter"] = {},
            ["id"] = "favorites",
            ["label"] = "Favorites",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "date_added",
                    ["reverse"] = true,
                },
            },
            ["source"] = {
                ["kind"] = "favorites",
            },
        },
        [10] = {
            ["enabled"] = true,
            ["filter"] = {},
            ["id"] = "custom_1",
            ["label"] = "New chip",
            ["sort_priority"] = {
                [1] = {
                    ["key"] = "title",
                    ["reverse"] = false,
                },
            },
            ["source"] = {
                ["kind"] = "all",
            },
        },
    },
}
