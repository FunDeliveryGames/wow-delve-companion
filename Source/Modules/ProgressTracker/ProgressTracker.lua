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

local EVENT_FRAME_NAME = "DelveCompanionProgressTrackingFrame"

local RESPAWN_SPELL = 433110
--#endregion

---@class (exact) ProgressTracker
---@field EventFrame Frame
---@field isDelveInProgress boolean
---@field lastSeenTieredEntranceGossip Enum.TieredEntranceType
local ProgressTracker = {}
DelveCompanion.ProgressTracker = ProgressTracker

local baseEvents = {
    "SCENARIO_CRITERIA_UPDATE",
    "ZONE_CHANGED_NEW_AREA",
    "DISPLAY_EVENT_TOAST_LINK"
}

---@param self ProgressTracker
function ProgressTracker:Init()
    -- Logger:Log("[ProgressTracker] Init started...")

    local frame = CreateFrame("Frame", EVENT_FRAME_NAME, UIParent)
    frame:RegisterEvent("SCENARIO_UPDATE")
    frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    frame:SetScript("OnEvent", function(owner, eventName, arg1, ...)
        C_Timer.After(0.5, function(...)
            self:ProcessEvent(eventName, arg1, ...)
        end)
    end)
    self.EventFrame = frame

    self:UpdateDelveStatus()
    if self.isDelveInProgress then
        -- If UI Reload or Login happens in the midst of the Delve, force register required events.
        FrameUtil.RegisterFrameForEvents(self.EventFrame, baseEvents)
    end
end

---@param self ProgressTracker
function ProgressTracker:UpdateDelveStatus()
    -- Logger:Log("[ProgressTracker] Detailed status check: InP: %s ||| IsC: %s",
    --     tostring(C_PartyInfo.IsDelveInProgress()),
    --     tostring(C_PartyInfo.IsDelveComplete()))

    self.isDelveInProgress = C_PartyInfo.IsDelveInProgress() and not C_PartyInfo.IsDelveComplete()

    Logger:Log("[ProgressTracker] DelveStatus: %s", tostring(self.isDelveInProgress))
end

---@param self ProgressTracker
function ProgressTracker:ProcessEvent(eventName, arg1, ...)
    -- Logger:Log("[ProgressTracker] Processing event: %s", eventName)

    self:UpdateDelveStatus()

    -- local widgetInfo = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(6183)
    if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        if arg1 ~= Enum.PlayerInteractionType.TieredEntrance then
            return
        end

        self.lastSeenTieredEntranceGossip = C_DelvesUI.GetTieredEntranceType()
    elseif eventName == "SCENARIO_UPDATE" then
        if self.isDelveInProgress then
            FrameUtil.RegisterFrameForEvents(self.EventFrame, baseEvents)

            EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_IN_PROGRESS)
        end
    elseif eventName == "SCENARIO_CRITERIA_UPDATE" then
        if C_PartyInfo.IsDelveComplete() then
            self.EventFrame:UnregisterEvent("SCENARIO_CRITERIA_UPDATE")

            EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_COMPLETE)
        end
    elseif eventName == "DISPLAY_EVENT_TOAST_LINK" then
        if string.match(arg1, RESPAWN_SPELL) ~= nil then
            EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_RESPAWN_ACTIVATED)

            self.EventFrame:UnregisterEvent("DISPLAY_EVENT_TOAST_LINK")
        end
    elseif eventName == "ZONE_CHANGED_NEW_AREA" then
        if not self.isDelveInProgress then
            FrameUtil.UnregisterFrameForEvents(self.EventFrame, baseEvents)

            EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_IN_PROGRESS)
        end
    end
end
