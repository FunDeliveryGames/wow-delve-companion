local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

--#endregion

---@class DelveEncounter
---@field CompanionFrame Button
---@field ExpBar JourneyEncounterExpBar
local DelveEncounter = {}
DelveCompanion.EJExtension.DelveEncounter = DelveEncounter

---@param self DelveEncounter
function DelveEncounter:OnShowHook()
    -- Logger.Log("[DelveEncounter] OnShowHook...")

    local companionFrame = self.CompanionFrame

    do
        local progressFrame = companionFrame:GetParent()
        local companionID = progressFrame.majorFactionData.playerCompanionID
        self.ExpBar.factionID = C_DelvesUI.GetFactionForCompanion(companionID)
        self.ExpBar:Show()
    end
end

---@param self DelveEncounter
function DelveEncounter:OnHideHook()
    -- Logger.Log("[DelveEncounter] OnHideHook...")

    self.ExpBar:Hide()
end

--- Initialize Delves list.
---@param self DelveEncounter
---@param JourneysFrame Frame
function DelveEncounter:Init(JourneysFrame)
    -- Logger.Log("[DelveEncounter] Init started...")

    ---@type Button
    local companionFrame = JourneysFrame.JourneyProgress.DelvesCompanionConfigurationFrame

    if not companionFrame then
        Logger.Log("[DelveEncounter] Companion frame is nil. Cannot init!")
        return
    end

    do
        companionFrame:ClearPoint("CENTER")
        companionFrame:SetPoint("LEFT", 30, 0)

        ---@type FontString
        local compName = companionFrame.CompanionConfigBtn.CompanionName
        compName:SetJustifyH("CENTER")
        compName:ClearAllPoints()
        compName:SetPoint("TOPLEFT", companionFrame.CompanionConfigBtn.Icon, "TOPRIGHT", 5, 15)

        ---@type JourneyEncounterExpBar
        local bar = CreateFrame("StatusBar", "$parent.CompanionExpBar", companionFrame,
            "DelveCompanionJourneyEncounterExpBarTemplate")
        bar:Init(compName)

        self.ExpBar = bar
    end

    companionFrame:HookScript("OnShow",
        function()
            self:OnShowHook()
        end
    )
    companionFrame:HookScript("OnHide",
        function()
            self:OnHideHook()
        end
    )
    self.CompanionFrame = companionFrame
end
