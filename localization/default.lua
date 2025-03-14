local _, addon = ...

--[[
Rules:
- Prefixes for different parts:
--- ui
--- debug
--- data
--- config
-
]]
addon.lockit = setmetatable(
    {
        -- Common
        ["ui-common-bountiful-delve"] = "Bountiful Delve",
        -- Keys Info
        ["ui-bountiful-keys-count-owned-format"] = "%s %s: %d",
        -- DelvesList
        ["ui-delve-instance-button-tooltip-click-text"] = "Shift + Left Click to set waypoint to the delve",
        ["ui-delve-instance-button-tooltip-current-text"] = "Waypoint set.\nShift + Left Click to clear waypoint.",

        -- LootInfo
        ["ui-loot-info-description"] = "Complete a delve to get:",
        ["ui-loot-info-bountilful-gear-title"] = "Bountiful", -- Replace with https://www.wowhead.com/item=228942/bountiful-coffer
        -- DashboardOverview
        ["ui-gilded-stash-bountiful-note"] =
        "Appears only in |cnNORMAL_FONT_COLOR:Tier 11|r Bountiful Delves|A:delves-bountiful:16:16|a",
        ["ui-no-active-bountiful"] = "No active delves"
    },
    {
        __index = function(_, ...)
            addon.log("Key is not found in the lockit: %s", ...);
        end
    }
)
