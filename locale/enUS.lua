local _, addon = ...
local log = addon.log
local lockit = addon.lockit

--[[
Lockit rules:
- The default locale: enUS. It contains all the keys used by the addon.
- Other languages override existing keys with a corresponding translation.
- The main intent: all locales should follow in-game terms, tiltes, names, etc. Situations when this rule can be broken:
--- To fit the text into UI. However, each case is considered separately to find the best solution.
--- There is another "word" widely used in a community to name something. E.g. `iLvl` is a common substitution for `Item Level` regardless of the language.
- Key names should have prefixes to indicate a kind of a key:
--- ui
--- debug
--- data
--- config
- Keys can have a description of the context if it matters.
- "Do not translate" tag is used to indicate only-English locales.
]]
--====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================
-- Common
lockit["ui-addon-name"] = "Delve Companion" -- Do not translate
lockit["ui-common-bountiful-delve"] = "Bountiful Delve"

-- Delves List
lockit["ui-delve-instance-button-tooltip-click-instruction"] = "<Shift + Left Click to set waypoint to the delve>"
lockit["ui-delve-instance-button-tooltip-current-text"] = "Waypoint set."
lockit["ui-delve-instance-button-tooltip-current-instruction"] = "<Shift + Left Click to clear waypoint>"

-- Delves UI
lockit["ui-gilded-stash-cannot-retrieve-data"] = "Visit Khaz Algar zones to see the progress"
lockit["ui-gilded-stash-bountiful-note"] =
"Appears only in |cnNORMAL_FONT_COLOR:Tier 11|r Bountiful Delves|A:delves-bountiful:16:16|a."
lockit["ui-no-active-bountiful"] = "No active delves"
lockit["ui-loot-info-button-tooltip-instruction"] = "<Click to display Delves' Loot info>"

-- Loot Info
lockit["ui-loot-info-description"] = "Complete a delve to get:"

-- Keys Info
lockit["ui-bountiful-keys-count-caches-prefix"] = "Keys from caches"

-- Settings
lockit["ui-settings-missing-addon-title"] = "Required AddOn is missing: %s" -- %s: AddonName, e.g. DelveCompanion

lockit["ui-settings-section-title-account"] = "Account-Wide"
lockit["ui-settings-ach-widgets"] = "Delves list: Display progress of achievements (Stories and Chests)."
lockit["ui-settings-tomtom-description"] = "Use Tom Tom waypoints instead of the Blizzard's Map Pin."

lockit["ui-settings-section-title-character"] = "Character-Wide"
lockit["ui-settings-gv-details"] = "Delves UI: Display detailed Great Vault section."
lockit["ui-settings-dashboard-overview"] = "Delves UI: Display Overview section (Gilded Stash, Bountiful Delves)."
lockit["ui-settings-keys-cap"] = "Display weekly limits info in tooltips."
lockit["ui-settings-translation-title"] = "Special thanks for the translation contribution:"

-- Debug
lockit["debug-unexpected-enum-element"] = "Enum `%s` doesn't contain element: %s."
