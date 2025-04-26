local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

---@class Lockit
local Lockit = setmetatable(
    {},
    {
        __index = function(_, ...)
            Logger.Log("Key is not found in the Lockit: `%s`!", ...)
        end
    }
)
DelveCompanion.Lockit = Lockit

--#region Lockit rules
--[[
- The default locale: enUS. It contains all the keys used by the addon.
- Other languages override existing keys with a corresponding translation.
- The main intent: all locales should follow in-game terms, tiltes, names, etc. Conditions when this rule can be broken:
--- To fit the text into UI. However, each case is considered separately to find the best solution.
--- There is another "word" widely used in a community to name something. E.g. `iLvl` is a common substitution for `Item Level` regardless of the language.
- Keys should have a prefixe to indicate a kind of a key:
--- UI
--- DATA
--- CONFIG
--- etc
- Keys may have a description to provide context where they are used if it matters.
]]
--#endregion

--#region DEFUALT LOCKIT (enUS)

-- Common

Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE = "Bountiful Delve"

-- Delves List

Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION = "<Shift + Left Click to set waypoint to the delve>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT = "Waypoint set."
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION = "<Shift + Left Click to clear the waypoint>"

-- Delves UI

Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA = "Visit Khaz Algar zones to see the progress"
Lockit.UI_GILDED_STASH_BOUNTIFUL_NOTE =
"Appears only in |cnNORMAL_FONT_COLOR:Tier 11|r Bountiful Delves|A:delves-bountiful:16:16|a."
Lockit.UI_NO_ACTIVE_BOUNTIFUL = "No active delves"
Lockit.UI_LOOT_INFO_BUTTON_TOOLTIP_INSTRUCTION = "<Click to display Delves' Loot info>"

-- Loot Info

Lockit.UI_LOOT_INFO_DESCRIPTION = "Complete a delve to get:"

-- Keys Info

Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX = "Keys from caches"

-- Settings

Lockit.UI_SETTINGS_MISSING_ADDON_TITLE =
"Required AddOn is missing: %s" -- %s: name of the missing AddOn, e.g. DelveCompanion

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "Account-Wide"
Lockit.UI_SETTINGS_ACH_WIDGETS = "Delves list: Display progress of achievements (Stories and Chests)."
Lockit.UI_SETTINGS_TOMTOM_DESCRIPTION = "Use Tom Tom waypoints instead of the Blizzard's Map Pin."

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "Character-Wide"
Lockit.UI_SETTINGS_GV_DETAILS = "Delves UI: Display detailed Great Vault section."
Lockit.UI_SETTINGS_DASHBOARD_OVERVIEW = "Delves UI: Display Overview section (Gilded Stash, Bountiful Delves)."
Lockit.UI_SETTINGS_KEYS_CAP = "Display weekly limits info in tooltips."
Lockit.UI_SETTINGS_TRANSLATION_TITLE = "Special thanks for the translation contribution:"
--#endregion

--#region Internal keys. These ARE NOT intended to be translated.

-- Shared

Lockit.UI_ADDON_NAME = "Delve Companion"

-- Debug

Lockit.DEBUG_UNEXPECTED_ENUM_ELEMENT = "Enum `%s` doesn't contain element: %s."
--#endregion
