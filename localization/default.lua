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
        ["ui-addon-name"] = "Delve Companion",
        -- DelvesList
        ["ui-delve-instance-button-tooltip-click-text"] = "Shift + Left Click to set waypoint to the delve.",
        ["ui-delve-instance-button-tooltip-current-text"] = "Waypoint set.\nShift + Left Click to clear waypoint.",

        -- DashboardOverview
        ["ui-gilded-stash-bountiful-note"] =
        "Appears only in |cnNORMAL_FONT_COLOR:Tier 11|r Bountiful Delves|A:delves-bountiful:16:16|a.",
        ["ui-no-active-bountiful"] = "No active delves",
        -- LootInfo
        ["ui-loot-info-description"] = "Complete a delve to get:",
        ["ui-loot-info-bountilful-gear-title"] = "Bountiful", -- Replace with https://www.wowhead.com/item=228942/bountiful-coffer

        -- Keys Info
        ["ui-bountiful-keys-count-owned-format"] = "%s %s: %d",

        -- Settings
        ["ui-settings-apply-button"] = "%s (%s)",
        ["ui-settings-gv-details"] = "Delves UI: Enable informative Great Vault details.",
        ["ui-settings-dashboard-overview"] = "Delves UI: Enable Overview section (Gilded Stash, Bountiful Delves).",
        ["ui-settings-keys-cap"] = "Display Keys weekly cap in tooltips.",

        -- Debug
        ["debug-unexpected-enum-element"] = "Enum %s doesn't contain element: %s.",
    },
    {
        __index = function(_, ...)
            addon.log("Key is not found in the lockit: %s!", ...);
        end
    }
)
