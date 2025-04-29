local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@class CodeType
---@field Item string Alias for `item`.
---@field Spell string Alias for `spell`.
---@field Currency string Alias for `currency`.
---@field Achievement string Alias for `achievement`.
local CodeType = {
    Item = "item",
    Spell = "spell",
    Currency = "currency",
    Achievement = "achievement"
}
setmetatable(CodeType, {
    __tostring = function()
        return "CodeType"
    end
})

---@class DependencyAddonName
---@field delvesDashboardUI string `Blizzard_DelvesDashboardUI`
---@field encounterJournal string `Blizzard_EncounterJournal`
---@field rio string `RaiderIO`
local DependencyAddonName = {
    delvesDashboardUI = "Blizzard_DelvesDashboardUI",
    encounterJournal = "Blizzard_EncounterJournal",
    rio = "RaiderIO"
}


---@class WaypointTrackingType
local WaypointTrackingType = {
    superTrack = 1,
    tomtom = 2
}

---@class CompanionWidgetLayout
local CompanionWidgetLayout = {
    default = 0,
    horizontal = 1,
    vertical = 2
}

---@class AddonEvents
local Events = {
    ON_SETTING_CHANGED = "DelveCompanion.OnSettingChanged"
}

--- Enum-like tables used across addon modules.
---@class (exact) Enums
---@field Events AddonEvents
---@field CodeType CodeType Game entity ID type used to retrieve its data from the Blizzard API. Primarly used for displaying tooltips of the corresponding type.
---@field DependencyAddonName DependencyAddonName Table of Blizzard AddOns which are loaded on demand. Used to initialize addon modules.
---@field WaypointTrackingType WaypointTrackingType
---@field CompanionWidgetLayout CompanionWidgetLayout
local Enums = {
    CodeType = CodeType,
    DependencyAddonName = DependencyAddonName,
    WaypointTrackingType = WaypointTrackingType,
    Events = Events,
    CompanionWidgetLayout = CompanionWidgetLayout
}
DelveCompanion.Enums = Enums
