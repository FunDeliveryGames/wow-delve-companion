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

--#endregion

---@class (exact) InDelveWidget
---@field frame InDelveWidgetFrame
local InDelveWidget = {}
DelveCompanion.InDelveWidget = InDelveWidget

---@param self InDelveWidget
---@param _ any
---@param isInProgress boolean
function InDelveWidget:OnProgressChanged(_, isInProgress, delveMapID)
    Logger.Log("[InDelveWidget] OnProgressChanged. Delve: %d ||| State: %s", delveMapID, tostring(isInProgress))
    if isInProgress and not self.frame.isSet then
        self:SetupWidget(delveMapID, false)
    elseif not isInProgress then
        self:HideWidget()
    end
end

---@param self InDelveWidget
function InDelveWidget:SetupWidget(delveMapID, isForce)
    -- Logger.Log("[InDelveWidget] Set up widget...")
    local delveContinent = DelveCompanion:GetContinentMapIDForMap(delveMapID)
    self.frame.delveExpansion = FindInTableIf(
        Config.DELVE_CONTINENTS,
        function(continentMapID)
            return continentMapID == delveContinent
        end
    )

    self.frame:PrepareWidget(isForce)
    self.frame:Show()
end

---@param self InDelveWidget
function InDelveWidget:HideWidget()
    self.frame:Hide()
end

---@param self InDelveWidget
function InDelveWidget:Init()
    -- Logger.Log("[InDelveWidget] Init started...")

    local widgetFrame = CreateFrame("Frame", "DelveCompanionInDelveWidgetFrame",
        UIParent, "DelvelCompanionInDelveWidgetFrameTemplate")
    self.frame = widgetFrame

    if C_PartyInfo.IsDelveInProgress() then
        -- Logger.Log("[InDelveWidget] Already in Delve. Force setup.")
        self:SetupWidget(C_Map.GetBestMapForUnit("player"), true)
    end

    do
        ---@param _ any
        ---@param isInProgress boolean
        local function OnProgressChanged(_, isInProgress, delveMapID)
            -- Logger.Log("[InDelveWidget] OnProgressChanged detected. Delve (%d) state: %s.", delveMapID,
            --     tostring(isInProgress))
            self:OnProgressChanged(_, isInProgress, delveMapID)
        end

        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_IN_PROGRESS,
            OnProgressChanged, self)
    end
end
