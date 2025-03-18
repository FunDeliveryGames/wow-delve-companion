local addonName, addon = ...

local config = {}

config.MAX_LEVEL = 80
config.ACTIVITY_TYPE = Enum.WeeklyRewardChestThresholdType.World

config.BOUNTIFUL_KEY_CURRENCY_CODE = 3028
config.BOUNTIFUL_KEY_MAX_PER_WEEK = 4
config.BOUNTIFUL_KEY_QUESTS_DATA = {
    [1] = 84736,
    [2] = 84737,
    [3] = 84738,
    [4] = 84739,
}

config.GILDED_STASH_WEEKLY_CAP = 3
config.GILDED_STASH_SPELL_CODE = 1216211
config.BOUNTIFUL_COFFER_ITEM_CODE = 233071
-- Seasonal items
config.BOUNTY_MAP_ITEM_CODE = 233071
config.ECHO_ITEM_CODE = 235897
config.KEY_SHARD_ITEM_CODE = 236096
config.SHARDS_FOR_KEY = 100
--===

-- Table of maps which contain Delves
config.DELVES_MAPS_DATA = {
    [1] = 2248,
    [2] = 2214,
    [3] = 2215,
    [4] = 2255,
    [5] = 2346,
}

-- Table of Delves by their UI Map IDs
config.DELVES_REGULAR_DATA = {
    -- "Earthcrawl Mines"
    [1] = {
        uiMapID = 2269,
        poiIDs = {
            regular = 7863,
            bountiful = 7787
        },
        coordinates = {
            x = 38.6,
            y = 74.0
        },
        atlasBgID = "delve-entrance-background-earthcrawl-mines",
        achievements = {
            chest = 40806,
            story = 40527
        }
    },
    -- "Fungal Folly"
    [2] = {
        uiMapID = 2249,
        poiIDs = {
            regular = 7864,
            bountiful = 7779
        },
        coordinates = {
            x = 52.03,
            y = 65.77
        },
        atlasBgID = "delve-entrance-background-fungal-folly",
        achievements = {
            chest = 40803,
            story = 40525
        }
    },
    -- "Kriegval's Rest"
    [3] = {
        uiMapID = 2250,
        poiIDs = {
            regular = 7865,
            bountiful = 7781
        },
        coordinates = {
            x = 62.19,
            y = 42.70
        },
        atlasBgID = "delve-entrance-background-kriegvals-rest",
        achievements = {
            chest = 40807,
            story = 40526
        }
    },
    -- "The Waterworks"
    [4] = {
        uiMapID = 2251,
        poiIDs = {
            regular = 7866,
            bountiful = 7782
        },
        coordinates = {
            x = 46.42,
            y = 48.71
        },
        atlasBgID = "delve-entrance-background-the-waterworks",
        achievements = {
            chest = 40816,
            story = 40528
        }
    },
    -- "The Dread Pit"
    [5] = {
        uiMapID = 2302,
        poiIDs = {
            regular = 7867,
            bountiful = 7788
        },
        coordinates = {
            x = 74.2,
            y = 37.3
        },
        atlasBgID = "delve-entrance-background-the-dread-pit",
        achievements = {
            chest = 40812,
            story = 40529
        }
    },
    -- "Excavation Site 9"
    [6] = {
        uiMapID = 2396,
        poiIDs = {
            regular = 8143,
            bountiful = 8181
        },
        coordinates = {
            x = 75.96,
            y = 96.41
        },
        atlasBgID = "delve-entrance-background-the-undermine",
        achievements = {
            chest = 41100,
            story = 41098
        }
    },
    -- "The Sinkhole" (it has a second ID in Wago Tools: 2301)
    [7] = {
        uiMapID = 2300,
        poiIDs = {
            regular = 7870,
            bountiful = 7783
        },
        coordinates = {
            x = 50.6,
            y = 53.3
        },
        atlasBgID = "delve-entrance-background-the-sinkhole",
        achievements = {
            chest = 40813,
            story = 40532
        }
    },
    -- "Nightfall Sanctum"
    [8] = {
        uiMapID = 2277,
        poiIDs = {
            regular = 7868,
            bountiful = 7785
        },
        coordinates = {
            x = 34.32,
            y = 47.43
        },
        atlasBgID = "delve-entrance-background-nightfall-sanctum",
        achievements = {
            chest = 40809,
            story = 40530
        }
    },
    -- "Mycomancer Cavern"
    [9] = {
        uiMapID = 2312,
        poiIDs = {
            regular = 7869,
            bountiful = 7780
        },
        coordinates = {
            x = 71.3,
            y = 31.2
        },
        atlasBgID = "delve-entrance-background-mycomancer-cavern",
        achievements = {
            chest = 40808,
            story = 40531
        }
    },
    -- "Skittering Breach"
    [10] = {
        uiMapID = 2310,
        poiIDs = {
            regular = 7871,
            bountiful = 7789
        },
        coordinates = {
            x = 65.48,
            y = 61.74
        },
        atlasBgID = "delve-entrance-background-skittering-breach",
        achievements = {
            chest = 40810,
            story = 40533
        }
    },
    -- "The Spiral Weave" (it has a second ID in Wago Tools: 2347)
    [11] = {
        uiMapID = 2313,
        poiIDs = {
            regular = 7874,
            bountiful = 7790
        },
        coordinates = {
            x = 45.0,
            y = 19.0
        },
        atlasBgID = "delve-entrance-background-the-spiral-weave",
        achievements = {
            chest = 40814,
            story = 40536
        }
    },
    -- "The Underkeep"
    [12] = {
        uiMapID = 2299,
        poiIDs = {
            regular = 7872,
            bountiful = 7786
        },
        coordinates = {
            x = 51.85,
            y = 88.30
        },
        atlasBgID = "delve-entrance-background-the-underkeep",
        achievements = {
            chest = 40815,
            story = 40534
        }
    },
    -- "Tak-Rethan Abyss" (it has a second ID in Wago Tools: 2314)
    [13] = {
        uiMapID = 2259,
        poiIDs = {
            regular = 7873,
            bountiful = 7784
        },
        coordinates = {
            x = 55.0,
            y = 73.92
        },
        atlasBgID = "delve-entrance-background-tak-rethan-abyss",
        achievements = {
            chest = 40811,
            story = 40535
        }
    },
    -- "Sidestreet Sluice" (it has more IDs in Wago Tools: 2421, 2422, 2423)
    [14] = {
        uiMapID = 2420,
        poiIDs = {
            regular = 8140,
            bountiful = 8246
        },
        coordinates = {
            x = 35.12,
            y = 53.04
        },
        atlasBgID = "delves-entrance-background-sewers",
        achievements = {
            chest = 41101,
            story = 41099
        }
    },
    -- "Demolition Dome" (it has a second ID in Wago Tools: 2426)
    [15] = {
        uiMapID = 2425,
        poiIDs = {
            regular = 8142
        },
        coordinates = {
            x = 50.43,
            y = 11.82
        },
        atlasBgID = "delve-entrance-background-goblin-boss"
    },
    -- "Zekvir's Lair"
    -- TODO: SuperTrack works but it's not shown on map anymore. Place a map pin for it?
    [16] = {
        uiMapID = 2348,
        poiIDs = {
            regular = 7875
        },
        coordinates = {
            x = 32.74,
            y = 76.87
        },
        atlasBgID = "delve-entrance-background-zekvirs-lair"
    }
}

-- Table of loot by Delves Tier
config.DELVES_LOOT_INFO_DATA = {
    [1] = {
        bountifulLvl = 610,
        vaultLvl = 623
    },
    [2] = {
        bountifulLvl = 613,
        vaultLvl = 626
    },
    [3] = {
        bountifulLvl = 616,
        vaultLvl = 629
    },
    [4] = {
        bountifulLvl = 619,
        vaultLvl = 632
    },
    [5] = {
        bountifulLvl = 623,
        vaultLvl = 639
    },
    [6] = {
        bountifulLvl = 626,
        vaultLvl = 642
    },
    [7] = {
        bountifulLvl = 636,
        vaultLvl = 645
    },
    [8] = {
        bountifulLvl = 639,
        vaultLvl = 649
    },
    [9] = {
        bountifulLvl = 639,
        vaultLvl = 649
    },
    [10] = {
        bountifulLvl = 639,
        vaultLvl = 649
    },
    [11] = {
        bountifulLvl = 639,
        vaultLvl = 649
    },
}

addon.config = config
