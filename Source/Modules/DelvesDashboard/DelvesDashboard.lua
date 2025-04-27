local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

--- Add a button to open Delves' Loot info.
---@param parent any
local function CreateLootInfoButton(parent)
    local button = CreateFrame("Button",
        "$parent.ShowLootInfoButton",
        parent,
        "DelveCompanionLootInfoButtonTemplate")

    button:SetText(_G["LOOT"])
    button:FitToText()

    button:HookScript("OnClick", function()
        GameTooltip:Hide()
        DelveCompanion.DelvesDashboard.LootInfo:Show()
    end)

    button:HookScript("OnEnter", function()
        if DelveCompanion.DelvesDashboard.LootInfo:IsShown() then
            return
        end

        local tooltip = GameTooltip
        tooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip_AddInstructionLine(tooltip, Lockit.UI_LOOT_INFO_BUTTON_TOOLTIP_INSTRUCTION, true)

        tooltip:Show()
    end)

    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function InitDelvesDashboard()
    if not DelveCompanion.Variables.maxLevelReached then
        return
    end

    local DelvesDashboardFrame = DelvesDashboardFrame
    if not DelvesDashboardFrame then
        Logger.Log("DelvesDashboardFrame is nil. Delves UI extension is not inited.")
        return
    end

    ---@class (exact) DelvesDashboard
    ---@field LootInfo LootInfoFrame
    ---@field GVDetails GVDetails
    ---@field Overview DashOverview
    local DelvesDashboard = {}
    DelveCompanion.DelvesDashboard = DelvesDashboard

    do
        ---@type LootInfoFrame
        local lootInfoFrame = CreateFrame("Frame",
            "$parent.LootInfoFrame", DelvesDashboardFrame,
            "DelveCompanionLootInfoFrameTemplate")
        DelvesDashboard.LootInfo = lootInfoFrame

        CreateLootInfoButton(DelvesDashboardFrame)
        DelvesDashboardFrame:HookScript("OnHide", function()
            DelveCompanion.DelvesDashboard.LootInfo:Hide()
        end)
    end

    do
        local compPanel = DelvesDashboardFrame.ButtonPanelLayoutFrame.CompanionConfigButtonPanel
        compPanel.PanelDescription:Hide()

        ---@type DashboardExpBar
        local bar = CreateFrame("StatusBar", "$parent.CompExpBar", compPanel, "DelveCompanionDashboardExpBarTemplate")
    end

    if DelveCompanionCharacterData.gvDetailsEnabled then
        local gvPanel = DelvesDashboardFrame.ButtonPanelLayoutFrame.GreatVaultButtonPanel

        ---@type GVDetails
        local gvDetailsFrame = CreateFrame("Frame",
            "$parent.CustomDetails", gvPanel,
            "DelveCompanionGreatVaultDetailsFrame")
        DelvesDashboard.GVDetails = gvDetailsFrame

        EventRegistry:RegisterFrameEventAndCallback("WEEKLY_REWARDS_UPDATE", function()
            if DelveCompanion.DelvesDashboard.GVDetails:IsShown() then
                DelveCompanion.DelvesDashboard.GVDetails:Refresh()
            else
                DelveCompanion.DelvesDashboard.GVDetails.shouldRefresh = true
            end
        end)
    end

    if DelveCompanionCharacterData.dashOverviewEnabled then
        local dashOverview = CreateFrame("Frame", "$parentDashboardOverview",
            DelvesDashboardFrame.ButtonPanelLayoutFrame, "DelveCompanionDashboardOverviewFrame")
        DelvesDashboard.Overview = dashOverview

        DelvesDashboardFrame.ButtonPanelLayoutFrame.spacing = -20
        DelvesDashboardFrame.ButtonPanelLayoutFrame:Layout()
    end
end

EventUtil.ContinueOnAddOnLoaded(DelveCompanion.Enums.DependencyAddonName.delvesDashboardUI, InitDelvesDashboard)
