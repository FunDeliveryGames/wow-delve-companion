local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

local FRAME_NAME = "DelveCompanionProgressTrackingFrame"

local RESPAWN_SPELL = 433110
--#endregion

---@class ProgressTracker
---@field eventFrame Frame
local ProgressTracker = {}
DelveCompanion.ProgressTracker = ProgressTracker

local baseEvents = {
    "SCENARIO_CRITERIA_UPDATE",
    "ZONE_CHANGED_NEW_AREA",
    "DISPLAY_EVENT_TOAST_LINK"
}

---@param self ProgressTracker
function ProgressTracker:ProcessEvent(eventName, arg1, ...)
    Logger.Log("[ProgressTracker] Event: %s", eventName)

    local isInProgress = C_PartyInfo.IsDelveInProgress()
    local isComplete = C_PartyInfo.IsDelveComplete()
    -- local widgetInfo = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(6183)

    if eventName == "SCENARIO_UPDATE" then
        if isInProgress then
            FrameUtil.RegisterFrameForEvents(self.eventFrame, baseEvents)

            EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_IN_PROGRESS,
                true,
                C_Map.GetBestMapForUnit("player"))
        end
    elseif eventName == "SCENARIO_CRITERIA_UPDATE" then
        if isComplete then
            self.eventFrame:UnregisterEvent("SCENARIO_CRITERIA_UPDATE")

            EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_COMPLETE)
        end
    elseif eventName == "DISPLAY_EVENT_TOAST_LINK" then
        if string.match(arg1, RESPAWN_SPELL) ~= nil then
            EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_RESPAWN_ACTIVATED)

            self.eventFrame:UnregisterEvent("DISPLAY_EVENT_TOAST_LINK")
        end
    elseif eventName == "ZONE_CHANGED_NEW_AREA" then
        if not isInProgress then
            FrameUtil.UnregisterFrameForEvents(self.eventFrame, baseEvents)

            EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_IN_PROGRESS,
                false,
                nil)
        end
    end
end

---@param self ProgressTracker
function ProgressTracker:Init()
    -- Logger.Log("[ProgressTracker] Init started...")

    local frame = CreateFrame("Frame", FRAME_NAME, UIParent)
    frame:RegisterEvent("SCENARIO_UPDATE")
    frame:SetScript("OnEvent", function(owner, eventName, arg1, ...)
        C_Timer.After(0.25, function(...)
            self:ProcessEvent(eventName, arg1, ...)
        end)
    end)
    self.eventFrame = frame

    if C_PartyInfo.IsDelveInProgress() then
        -- If UI Reload or Logout happened in the midst of the Delve, force register required events.
        FrameUtil.RegisterFrameForEvents(self.eventFrame, baseEvents)
    end
end
