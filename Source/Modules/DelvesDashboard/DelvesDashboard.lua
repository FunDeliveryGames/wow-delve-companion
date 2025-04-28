local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

---@class (exact) DelvesDashboard
---@field LootInfo LootInfoFrame
---@field GVDetails GVDetailsFrame
---@field Overview DashOverview
---@field Companion DashboardCompanion
local DelvesDashboard = {}
DelveCompanion.DelvesDashboard = DelvesDashboard

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
        DelvesDashboard.LootInfo:Show()
    end)

    button:HookScript("OnEnter", function()
        if DelvesDashboard.LootInfo:IsShown() then
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

    do
        ---@type LootInfoFrame
        local lootInfoFrame = CreateFrame("Frame",
            "$parent.LootInfoFrame", DelvesDashboardFrame,
            "DelveCompanionLootInfoFrameTemplate")
        DelvesDashboard.LootInfo = lootInfoFrame

        CreateLootInfoButton(DelvesDashboardFrame)
        DelvesDashboardFrame:HookScript("OnHide", function()
            DelvesDashboard.LootInfo:Hide()
        end)
    end

    do
        local compPanel = DelvesDashboardFrame.ButtonPanelLayoutFrame.CompanionConfigButtonPanel
        DelvesDashboard.Companion:Init(compPanel)
    end

    if DelveCompanionCharacterData.gvDetailsEnabled then
        local gvPanel = DelvesDashboardFrame.ButtonPanelLayoutFrame.GreatVaultButtonPanel

        ---@type GVDetailsFrame
        local gvDetailsFrame = CreateFrame("Frame",
            "$parent.CustomDetails", gvPanel,
            "DelveCompanionGreatVaultDetailsFrame")

        DelvesDashboard.GVDetails = gvDetailsFrame
    end

    if DelveCompanionCharacterData.dashOverviewEnabled then
        local dashOverview = CreateFrame("Frame", "$parentDashboardOverview",
            DelvesDashboardFrame.ButtonPanelLayoutFrame, "DelveCompanionDashboardOverviewFrame")
        DelvesDashboard.Overview = dashOverview

        DelvesDashboardFrame.ButtonPanelLayoutFrame.spacing = -20
    end
    DelvesDashboardFrame.ButtonPanelLayoutFrame:Layout()
end

EventUtil.ContinueOnAddOnLoaded(DelveCompanion.Enums.DependencyAddonName.delvesDashboardUI, InitDelvesDashboard)
