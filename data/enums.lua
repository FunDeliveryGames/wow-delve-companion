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

enums.DependencyAddonName = {
    delvesDashboardUI = "Blizzard_DelvesDashboardUI",
    encounterJournal = "Blizzard_EncounterJournal",
    weeklyRewards = "Blizzard_WeeklyRewards"
}

addon.enums = enums
