local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

--- Companion section improvements in Delves UI.
---@class (exact) DashboardCompanion
---@field ParentPanel CompanionConfigButtonPanel
---@field ExpBar DashboardExpBar
---@field ConfigWidget CompanionConfigWidget
local DashboardCompanion = {}

DelveCompanion.DelvesDashboard.Companion = DashboardCompanion

--- Create and set all required elements.
---@param CompanionPanel CompanionConfigButtonPanel Companion section Frame in Delves UI.
function DashboardCompanion:Init(CompanionPanel)
    DashboardCompanion.ParentPanel = CompanionPanel

    CompanionPanel.PanelTitle:SetHeight(30)
    CompanionPanel.PanelDescription:Hide()

    do
        ---@type DashboardExpBar
        local bar = CreateFrame("StatusBar", "$parent.CompanionExpBar", CompanionPanel,
            "DelveCompanionDashboardCompanionExpBarTemplate")

        DashboardCompanion.ExpBar = bar
    end

    do
        ---@type CompanionConfigWidget
        local configWidget = CreateFrame("Frame", "$parent.ConfigWidget", CompanionPanel,
            "DelveCompanionDashboardCompanionConfigWidgetTemplate")

        DashboardCompanion.ConfigWidget = configWidget
    end
end

--#region XML Annotations

--- CompanionConfigButtonPanel
---@class CompanionConfigButtonPanel : DelvesDashboardButtonPanelFrame
---@field layoutIndex number
---@field CompanionModelScene ModelScene
---@field CompanionConfigButton MagicButton

--#endregion
