local _, addon = ...
local log = addon.log
local lockit = addon.lockit

--[[
Lockit rules:
- The default locale: enUS. It contains all the keys used by the addon.
- Other languages override existing keys with a corresponding translation.
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
lockit["ui-delve-instance-button-tooltip-click-text"] = "Shift + Left Click to set waypoint to the delve."
lockit["ui-delve-instance-button-tooltip-current-text"] = "Waypoint set.\nShift + Left Click to clear waypoint."

-- Delves UI
lockit["ui-gilded-stash-cannot-retrieve-data"] = "Visit Khaz Algar zones to see the progress"
lockit["ui-gilded-stash-bountiful-note"] =
"Appears only in |cnNORMAL_FONT_COLOR:Tier 11|r Bountiful Delves|A:delves-bountiful:16:16|a."
lockit["ui-no-active-bountiful"] = "No active delves"

-- Loot Info
lockit["ui-loot-info-description"] = "Complete a delve to get:"
lockit["ui-loot-info-bountilful-gear-title"] =
"Bountiful" -- Replace with https://www.wowhead.com/item=228942/bountiful-coffer

-- Keys Info
lockit["ui-bountiful-keys-count-caches-prefix"] = "Keys from caches"

-- Settings
lockit["ui-settings-gv-details"] = "Delves UI: Display detailed Great Vault section."
lockit["ui-settings-dashboard-overview"] = "Delves UI: Display Overview section (Gilded Stash, Bountiful Delves)."
lockit["ui-settings-keys-cap"] = "Display Keys obtained this week in tooltips."

-- Debug
lockit["debug-unexpected-enum-element"] = "Enum `%s` doesn't contain element: %s."
