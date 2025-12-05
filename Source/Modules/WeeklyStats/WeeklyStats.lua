local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

--#region Constants

---@type string Scenario name for Delves from [Wago](https://wago.tools/db2/Scenario?page=1).
local SCENARIO_DELVE_NAME = "Delves"
-- local SCENARIO_ID_DELVE = 3022

---@type number WidgetID with a Delve progress from [Wago](https://wago.tools/db2/UiWidget?page=1).
local WIDGET_ID_DELVE_SCENARIO = 6183

--#endregion

--- Class to save information about Delves completed during the week.
---@class (exact) WeeklyStats
local WeeklyStats = {}
DelveCompanion.WeeklyStats = WeeklyStats

local function OnScenarioCompleted(ownerID, ...)
    Logger.Log("Scenario has been completed")

    local info = C_ScenarioInfo.GetScenarioInfo()
    if info == nil then
        Logger.Log("Scenario info is nil")
        return
    end

    Logger.LogTable(info)

    if info.name ~= SCENARIO_DELVE_NAME then
        Logger.Log("Not a Delve?")
        return
    end

    local widgetInfo = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(WIDGET_ID_DELVE_SCENARIO)
    if widgetInfo then
        Logger.Log("Completed: %s - Tier %s",
            C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player")).name,
            widgetInfo.tierText)
    end
end

local function OnZoneChanged(ownerID, ...)
    local mapID = C_Map.GetBestMapForUnit("player")

    if mapID == nil then
        return
    end

    local isInDelve = DelveCompanion:GetDelveConfigByMapId(mapID) ~= nil

    if isInDelve then
        Logger.Log("Entered delve: %s", C_Map.GetMapInfo(mapID).name)
        EventRegistry:RegisterFrameEventAndCallback("SCENARIO_COMPLETED", OnScenarioCompleted, WeeklyStats)
    else
        EventRegistry:UnregisterFrameEventAndCallback("SCENARIO_COMPLETED", WeeklyStats)
    end

    -- Unsafe way...
    -- local delveDiff = 208

    -- Logger.Log("ZoneChanged...")
    -- C_Timer.After(1, function(cb)
    --     local diffId = select(3, GetInstanceInfo())
    --     Logger.Log("Diff ID: %d", diffId)

    --     if diffId == delveDiff then
    --         Logger.Log("Entered a delve: %s", C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player")).name)
    --     end

    --     EventRegistry:RegisterCallback("SCENARIO_CRITERIA_UPDATE", OnCriteriaUpdate)
    -- end)
end

function WeeklyStats:Init()
    Logger.Log("WeeklyStats Init...")

    EventRegistry:RegisterFrameEventAndCallback("SCENARIO_COMPLETED", OnScenarioCompleted)
end

-- Enable tracker entering a Delve
-- ZONE_CHANGED_NEW_AREA + GetInstanceInfo?
-- Check mapID to understand it's Delve? Or from Gossip?

-- Check story change or similar events
-- SCENARIO_CRITERIA_UPDATE
-- 2387: Scenario ID for Treasure Room, presumably the same for all Delves

-- When "finish" occurs - save Delve data
-- Wait for SCENARIO_COMPLETED

-- Reset stats on weekly basis
-- ??
