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
        -- Keys Info
        ["ui-bountiful-keys-count-owned-format"] = "%s %s: %d",
        -- DelvesList
        ["ui-delve-instance-button-tooltip-click-text"] = "Shift + Left Click to set waypoint to the Delve",
        ["ui-delve-instance-button-tooltip-current-text"] = "Waypoint set.\nShift + Left Click to clear waypoint.",

        -- LootInfo
        ["ui-loot-info-description"] = "Complete a delve to get:",
        ["ui-loot-info-bountilful-gear-title"] = "Bountiful"
    },
    {
        __index = function(_, ...)
            addon.log("Key is not found in the lockit: %s", ...);
        end
    }
)
