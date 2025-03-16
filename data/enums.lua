local addonName, addon = ...

local enums = {}

enums.CodeType = setmetatable({
        Item = "item",
        Spell = "spell",
        Currency = "currency",
        Achievement = "achievement",
    },
    {
        __tostring = function()
            return "CodeType"
        end
    }
)


addon.enums = enums
