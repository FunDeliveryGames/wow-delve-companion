local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@class CodeType
---@field Item string Alias for `item`.
---@field Spell string Alias for `spell`.
---@field Currency string Alias for `currency`.
---@field Achievement string Alias for `achievement`.
---@field Toy string Alias for `toy`.
local CodeType = {
    Item = "item",
    Spell = "spell",
    Currency = "currency",
    Achievement = "achievement",
    Toy = "toy"
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
---@field tomtom string `TomTom`
local DependencyAddonName = {
    delvesDashboardUI = "Blizzard_DelvesDashboardUI",
    encounterJournal = "Blizzard_EncounterJournal",
    rio = "RaiderIO",
    tomtom = "TomTom"
}

---@class Link
---@field name string
---@field url string

---@class Links
---@field CurseForge Link
---@field Wago Link
---@field WoWInt Link
---@field GitHub Link
local Links = {
    CurseForge = {
        name = "CurseForge",
        url = "https://www.curseforge.com/wow/addons/delve-companion"
    },
    Wago = {
        name = "Wago.io",
        url = "https://addons.wago.io/addons/delve-companion"
    },
    WoWInt = {
        name = "WoW Interface",
        url = "https://www.wowinterface.com/downloads/fileinfo.php?id=26915#info"
    },
    GitHub = {
        name = "GitHub",
        url = "https://github.com/FunDeliveryGames/wow-delve-companion"
    }
}

---@class ButtonAlias
local ButtonAlias = {
    leftClick = "LeftButton",
    rightClick = "RightButton"
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
---@field ButtonAlias ButtonAlias
---@field Links Links
local Enums = {
    CodeType = CodeType,
    DependencyAddonName = DependencyAddonName,
    WaypointTrackingType = WaypointTrackingType,
    Events = Events,
    CompanionWidgetLayout = CompanionWidgetLayout,
    ButtonAlias = ButtonAlias,
    Links = Links
}
DelveCompanion.Enums = Enums
