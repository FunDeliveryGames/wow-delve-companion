local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

--- Custom frame in Delves UI to display information about `Gilded Stash`, active `Boutiful Delves`, and Delve-related consumables.
---@class (exact) DashOverview : DashOverviewXml
DelveCompanion_DashboardOverviewMixin = {}

---@param self DashOverview
function DelveCompanion_DashboardOverviewMixin:ToggleShown(isShown)
    if isShown then
        self:Show()
    else
        self:Hide()
    end
end

---@param self DashOverview
function DelveCompanion_DashboardOverviewMixin:OnLoad()
    --Logger.Log("DashboardOverview OnLoad start")

    self.PanelTitle:Hide()
    self.PanelDescription:Hide()

    self.WorldMapButton:SetText(_G["WORLDMAP_BUTTON"])

    self:ToggleShown(DelveCompanionCharacterData.dashOverviewEnabled)
end

---@param self DashOverview
function DelveCompanion_DashboardOverviewMixin:OnShow()
    -- Logger.Log("DashboardOverview OnShow start")
end

--#region XML Annotations

--- `DelveCompanionDashboardOverviewFrame`
---@class DashOverviewXml : DelvesDashboardButtonPanelFrame
---@field layoutIndex number
---@field GildedStashFrame GildedStashFrame
---@field BountifulFrame OverviewBountifulFrame
---@field ConsumablesFrame OverviewConsumablesFrame
---@field WorldMapButton MagicButton

--#endregion
