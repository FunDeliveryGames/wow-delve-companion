local _, addon = ...
local log = addon.log

local lockit = setmetatable(
    {
        -- Keys are added in the corresponding locale scripts
    },
    {
        __index = function(_, ...)
            addon.log("Key is not found in the lockit: %s!", ...)
        end
    }
)

addon.lockit = lockit
