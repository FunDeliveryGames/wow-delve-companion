local _, Addon = ...
---@type Logger
local Logger = Addon.Logger

local lockit = setmetatable(
    {
        -- Keys are populated in a corresponding locale script
    },
    {
        __index = function(_, ...)
            Logger.Log("Key is not found in the lockit: %s!", ...)
        end
    }
)

Addon.lockit = lockit
