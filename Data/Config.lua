local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

--- Table containing all addon external parameters, such as game entity IDs, Delves parameters, limits, etc.
---@class Config
local Config = {}
DelveCompanion.Config = Config

---@type integer Player's maximum level in the current expansion.
Config.EXPANSION_MAX_LEVEL = 80

--#region Great Vault

---@type integer Delves' Activity ID to retrieve Great Vault rewards state.
Config.ACTIVITY_TYPE = Enum.WeeklyRewardChestThresholdType.World
---@type integer Max tier of the Delve which upgrades Great Vault rewards.
Config.GREAT_VAULT_UPGRADE_MAX_TIER = 8
---@type integer Item ID of [Bountiful Coffer](https://www.wowhead.com/item=228942/bountiful-coffer).
Config.BOUNTIFUL_COFFER_ITEM_CODE = 228942
--#endregion

--#region Restored Coffer Key

---@type integer Currency ID of [Restored Coffer Key](https://www.wowhead.com/currency=3028/restored-coffer-key).
Config.BOUNTIFUL_KEY_CURRENCY_CODE = 3028
---@type integer Weekly cap of [Restored Coffer Keys](https://www.wowhead.com/currency=3028/restored-coffer-key) player can get from Caches like [Pinnacle Cache](https://www.wowhead.com/item=239118/pinnacle-cache).
Config.BOUNTIFUL_KEY_MAX_PER_WEEK = 4
---@type table<integer, number> Indexed table of Quest IDs used to track [Restored Coffer Keys](https://www.wowhead.com/currency=3028/restored-coffer-key) player has received during the week.
Config.BOUNTIFUL_KEY_QUESTS_DATA = {
    [1] = 84736,
    [2] = 84737,
    [3] = 84738,
    [4] = 84739
}
---@type table<integer, number> Indexed table of Caches containing [Restored Coffer Keys](https://www.wowhead.com/currency=3028/restored-coffer-key) (e.g. [Pinnacle Cache](https://www.wowhead.com/item=239118/pinnacle-cache)).
Config.BOUNTIFUL_KEY_SOURCE_CACHES_DATA = {
    -- TWW Season 1
    [1]  = 226263,
    [2]  = 226273,
    [3]  = 226264,
    [4]  = 224784,
    [5]  = 225571,
    [6]  = 225572,
    [7]  = 225573,
    [8]  = 228361,
    -- TWW Season 2
    [9]  = 239128,
    [10] = 239121,
    [11] = 239126,
    [12] = 239118,
    [13] = 239125,
    [14] = 239122,
    [15] = 239124,
    [16] = 238208,
    [17] = 235639,
    [18] = 235610,
    [19] = 239120
}
--#endregion

--#region Gilded Stash

---@type integer Spell ID of [Gilded Stash](https://www.wowhead.com/spell=1216211/gilded-stash).
Config.GILDED_STASH_SPELL_CODE = 1216211
---@type integer [Gilded Stash](https://www.wowhead.com/spell=1216211/gilded-stash) player can open per week.
Config.GILDED_STASH_WEEKLY_CAP = 3
--#endregion

--#region Delve-related entities which are updated every season

---@type integer Item ID of [Delver's Bounty](https://www.wowhead.com/item=233071/delvers-bounty).
Config.BOUNTY_MAP_ITEM_CODE = 233071
---@type integer Weekly cap of [Delver's Bounty](https://www.wowhead.com/item=233071/delvers-bounty).
Config.BOUNTY_MAP_MAX_PER_WEEK = 1
---@type integer Quest ID used to track whether player has looted [Delver's Bounty](https://www.wowhead.com/item=233071/delvers-bounty) during the week.
Config.BOUNTY_MAP_QUEST = 86371

---@type integer Item ID of [Radiant Echo](https://www.wowhead.com/item=235897/radiant-echo).
Config.ECHO_ITEM_CODE = 235897

---@type integer Item ID of [Coffer Key Shard](https://www.wowhead.com/item=236096/coffer-key-shard).
Config.KEY_SHARD_ITEM_CODE = 236096
---@type integer Number of [Coffer Key Shards](https://www.wowhead.com/item=236096/coffer-key-shard) required to assemble [Restored Coffer Key](https://www.wowhead.com/currency=3028/restored-coffer-key).
Config.SHARDS_FOR_KEY = 100
--#endregion

--#region Seasonal modifiers

---@type integer Spell ID of [Nemesis Strongbox](https://www.wowhead.com/spell=472952/nemesis-strongbox).
Config.NEMESIS_AFFIX_SPELL_CODE = 472952
--#endregion

--#region Delves data

---@type integer Khaz Algar [uiMapID](https://warcraft.wiki.gg/wiki/UiMapID).
Config.KHAZ_ALGAR_MAP_ID = 2274

---@type table<integer, number> Indexed table of [uiMapIDs](https://warcraft.wiki.gg/wiki/UiMapID) which contain Delves.
Config.MAPS_WITH_DELVES = {
    [1] = 2248,
    [2] = 2214,
    [3] = 2215,
    [4] = 2255,
    [5] = 2346
}

--- Table with Delve parameters.
---@class (exact) DelveConfig
---@field uiMapID number Delve [uiMapID](https://warcraft.wiki.gg/wiki/UiMapID).
---@field poiIDs {regular: number, bountiful: number?} Delve [areaPoiIDs](https://wago.tools/db2/areapoi).
---@field gildedStashUiWidgetID number? [UiWidgetID](https://wago.tools/db2/UiWidget) used to retrieve information about [Gilded Stash](https://www.wowhead.com/spell=1216211/gilded-stash) weekly progress.
---@field atlasBgID string [AtlasID](https://warcraft.wiki.gg/wiki/AtlasID) used to get Delve's background texture.
---@field achievements {chest: number, story: number}? Achievement IDs related to the Delve.
---@field coordinates MapCoord? Delve entrance coordinates. Used primarly for Boss Delves and TomTom waypoints.

---@type DelveConfig[] Indexed table of all Delves in the game and their parameters.
Config.DELVES_CONFIG = {
    -- "Earthcrawl Mines"
    [1] = {
        uiMapID = 2269,
        poiIDs = {
            regular = 7863,
            bountiful = 7787
        },
        gildedStashUiWidgetID = 6723,
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
        gildedStashUiWidgetID = 6728,
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
        gildedStashUiWidgetID = 6719,
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
        gildedStashUiWidgetID = 6720,
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
        gildedStashUiWidgetID = 6724,
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
        gildedStashUiWidgetID = 6659,
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
        gildedStashUiWidgetID = 6721,
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
        gildedStashUiWidgetID = 6727,
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
        gildedStashUiWidgetID = 6729,
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
        gildedStashUiWidgetID = 6725,
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
        gildedStashUiWidgetID = 6726,
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
        gildedStashUiWidgetID = 6794,
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
        gildedStashUiWidgetID = 6722,
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
        gildedStashUiWidgetID = 6718,
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

--- Table with Delve Loot information
---@class DelveLootInfo
---@field bountifulLvl integer Item Level player gets opening [Bountiful Coffer](https://www.wowhead.com/item=228942/bountiful-coffer).
---@field vaultLvl integer Item Level player gets from the Great Vault completing the corresponding Delve Tier.

--- Indexed table of Delves Loot information (index = Tier).
---@type DelveLootInfo[]
Config.DELVES_LOOT_INFO_DATA = {
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
    }
}
--#endregion
