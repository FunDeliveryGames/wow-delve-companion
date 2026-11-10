local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

--- Table containing internal variables, enums, etc.
---@class Definitions
local Definitions = {}
DelveCompanion.Definitions = Definitions

--- Game entity ID type used to retrieve its data from the Blizzard API. Primarly used for displaying tooltips of the corresponding type.
---@class (exact) CodeType
---@field Item string Alias for `item`.
---@field Spell string Alias for `spell`.
---@field Currency string Alias for `currency`.
---@field Achievement string Alias for `achievement`.
---@field Toy string Alias for `toy`.
Definitions.CodeType = {
    Item = "item",
    Spell = "spell",
    Currency = "currency",
    Achievement = "achievement",
    Toy = "toy"
}
setmetatable(Definitions.CodeType, {
    __tostring = function()
        return "CodeType"
    end
})

--- Table of Blizzard AddOns which are loaded on demand. Used to initialize addon modules.
---@class (exact) DependencyAddonName
---@field encounterJournal string `Blizzard_EncounterJournal`
---@field rio string `RaiderIO`
---@field tomtom string `TomTom`
---@field mpe string `MapPinEnhanced`
Definitions.DependencyAddonName = {
    encounterJournal = "Blizzard_EncounterJournal",
    rio = "RaiderIO",
    tomtom = "TomTom",
    mpe = "MapPinEnhanced"
}

---@class (exact) Link
---@field name string
---@field url string

---@class (exact) Links
---@field CurseForge Link
---@field Wago Link
---@field WoWInt Link
---@field GitHub Link
Definitions.Links = {
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

---@class (exact) ButtonAlias
---@field leftClick string
---@field rightClick string
Definitions.ButtonAlias = {
    leftClick = "LeftButton",
    rightClick = "RightButton"
}

---@class (exact) WaypointTrackingType
---@field superTrack number
---@field tomtom number
---@field mpe number
Definitions.WaypointTrackingType = {
    superTrack = 1,
    tomtom = 2,
    mpe = 3
}

---@class (exact) CompanionWidgetLayout
---@field horizontal number
---@field vertical number
Definitions.CompanionWidgetLayout = {
    horizontal = 1,
    vertical = 2
}

---@class (exact) InDelveWidgetDisplayRule Controls where [InDelveWidget](lua://InDelveWidget) is displayed.
---@field left number Widget is shown on the left side of Objective Tracker.
---@field right number Widget is shown on the right side of Objective Tracker.
---@field custom number Widget can be freely moved over the screen.
Definitions.InDelveWidgetDisplayRule = {
    left = 1,
    right = 2,
    custom = 3
}

---@class (exact) InDelveWidgetLayout Controls how [InDelveWidget](lua://InDelveWidget) buttons are arranged.
---@field vertical number
---@field horizontal number
Definitions.InDelveWidgetLayout = {
    vertical = 1,
    horizontal = 2
}

---@class AddonEvents
Definitions.Events = {
    SETTING_CHANGE = "DelveCompanion.SettingChange", -- Whenever any addon setting is changed.
    DELVE_INSTANCE_BUTTON_CLICK = "DelveCompanion.RequestDelveInfoFrame",
    PROGRESS_TRACKER = {
        DELVE_IN_PROGRESS = "DelveCompanion.DelveInProgress",             -- Delve has started.
        DELVE_RESPAWN_ACTIVATED = "DelveCompanion.DelveRespawnActivated", -- Respawn has been activated in the Delve.
        DELVE_COMPLETED = "DelveCompanion.DelveCompleted",                -- Delve has been completed.
        DELVE_EXITED = "DelveCompanion.DelveExited",                      -- Delve has been left.
    },
    DELVES_DATA = {
        -- Any DelveRecord field has changed. Payload: DelvesDataChanges.
        UPDATED = "DelveCompanion.DelvesData.Updated",
    }
}

--- Kind of a Delve. Derived from [DelveConfig](lua://DelveConfig) once at startup.
---@class (exact) DelveKind
---@field Regular number
---@field Nemesis number Level-gated boss Delve (`DelveConfig.nemesisInfo`).
---@field Labyrinth number `DelveConfig.labyrinthInfo`.
Definitions.DelveKind = {
    Regular = 1,
    Nemesis = 2,
    Labyrinth = 3
}

--- Completion state of the active Story Variant of a Delve.
---@class (exact) DelveStoryStatus
---@field Unknown number The Story Variant could not be read (e.g. its data is not loaded yet).
---@field NotCompleted number The variant is part of the story achievement and not completed.
---@field Completed number The variant is part of the story achievement and completed.
---@field NotTracked number The variant is not part of the story achievement (added mid-expansion), or the Delve has no story achievement. Displayed as completed.
Definitions.DelveStoryStatus = {
    Unknown = 0,
    NotCompleted = 1,
    Completed = 2,
    NotTracked = 3
}

---@class (exact) UpgradeTrackType
---@field adventurer number
---@field veteran number
---@field champion number
---@field hero number
---@field myth number
Definitions.UpgradeTrackType = {
    adventurer = 1,
    veteran = 2,
    champion = 3,
    hero = 4,
    myth = 5
}
