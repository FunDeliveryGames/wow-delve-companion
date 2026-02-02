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

---@type string
local SAVE_KEY = "inDelveWidgetEnabled"
--#endregion

---@class (exact) InDelveWidget
---@field frame InDelveWidgetFrame
local InDelveWidget = {}
DelveCompanion.InDelveWidget = InDelveWidget

---@param self InDelveWidget
---@param _ any
---@param isInProgress boolean Whether player has an active Delve.
function InDelveWidget:OnDelveInProgressChanged(_, isInProgress)
    -- Logger.Log("[InDelveWidget] OnProgressChanged. State: %s", tostring(isInProgress))

    if isInProgress and not self.frame.isSet then
        self:SetupWidget(false)
    elseif not isInProgress then
        self:HideWidget()
    end
end

---@param self InDelveWidget
function InDelveWidget:SetupWidget(isForced)
    -- Logger.Log("[InDelveWidget] Set up widget...")

    if not DelveCompanionAccountData.inDelveWidgetEnabled then
        return
    end

    local delveContinent = DelveCompanion:GetContinentMapIDForMap(C_Map.GetBestMapForUnit("player"))
    self.frame.delveExpansion = FindInTableIf(
        Config.DELVE_CONTINENTS,
        function(continentMapID)
            return continentMapID == delveContinent
        end
    )

    self.frame:PrepareWidget(isForced)
    self.frame:Show()
end

---@param self InDelveWidget
function InDelveWidget:HideWidget()
    -- Logger.Log("[InDelveWidget] Hide widget...")

    self.frame:Hide()
end

---@param self InDelveWidget
function InDelveWidget:Init()
    -- Logger.Log("[InDelveWidget] Init started...")

    local widgetFrame = CreateFrame("Frame", "DelveCompanionInDelveWidgetFrame",
        UIParent, "DelvelCompanionInDelveWidgetFrameTemplate")
    self.frame = widgetFrame

    do
        ---@param _ any
        ---@param isInProgress boolean
        local function OnDelveInProgressChanged(_, isInProgress)
            self:OnDelveInProgressChanged(_, isInProgress)
        end

        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_IN_PROGRESS,
            OnDelveInProgressChanged, self)
    end

    do
        local function OnSettingChanged(_, changedVarKey, isEnabled)
            if not (changedVarKey == SAVE_KEY) then
                return
            end
            -- Logger.Log("[InDelveWidget] OnSettingChanged. Enabled: %s...", tostring(isEnabled))

            if isEnabled then
                self:SetupWidget(true)
            else
                self:HideWidget()
            end
        end

        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.SETTING_CHANGE, OnSettingChanged, self)
    end

    if C_PartyInfo.IsDelveInProgress() then
        -- Logger.Log("[InDelveWidget] Already in Delve. Forced setup.")
        self:SetupWidget(true)
    end
end
