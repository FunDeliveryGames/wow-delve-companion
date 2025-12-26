local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

---@type string
local DELVES_TAB_PARENT_KEY = "DelvesTab"

---@type integer
local EJ_DELVES_TAB_BUTTON_ID = 7
---@type integer
local EJ_TABS_COUNT = 7
---@type integer
local EJ_DELVES_MIN_TIER = -1 -- Should be set when EncounterJournal is availalbe.

if DelveCompanion.Variables.isPTR then
    EJ_DELVES_TAB_BUTTON_ID = 8
    EJ_TABS_COUNT = 8
end
--#endregion

---@class DelvesList
---@field Frame DelvesListFrame
---@field TabButton Button
---@field InfoFrame DelvesInfoFrame
local DelvesList = {}
DelveCompanion.DelvesList = DelvesList

local function ExpansionDropdown_Select(tier)
    EJ_SelectTier(tier)

    local tierData = GetEJTierData(tier)
    -- JourneysFrame has an internal variable to control the current displayed expansion. It should be set to properly reflect expansion switch on Delves tab.
    do
        if EncounterJournal.JourneysFrame then
            -- If tier is greater than EJ_TIER_DATA, either we have "current season" selected, or an expansion is missing. Fall back on the current expansion.
            -- EJ_TIER_DATA is a local table so ExpansionEnumToEJTierDataTableId is used instead.
            if tier > #ExpansionEnumToEJTierDataTableId then
                EncounterJournal.JourneysFrame.expansionFilter = LE_EXPANSION_LEVEL_CURRENT
            else
                EncounterJournal.JourneysFrame.expansionFilter = tierData.expansionLevel
            end
        end
    end

    -- As it's a custom function for the dropdown, DelvesList is always shown here.
    do
        DelveCompanion.DelvesList.Frame:Refresh()
    end
end

local function SetupExpansionDropdownForDelves()
    local function IsSelected(tier)
        return tier == EJ_GetCurrentTier()
    end

    EncounterJournal.instanceSelect.ExpansionDropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:SetTag("MENU_EJ_EXPANSION")
        for tier = EJ_DELVES_MIN_TIER, EJ_GetNumTiers() do
            local text = EJ_GetTierInfo(tier)
            rootDescription:CreateRadio(text, IsSelected, ExpansionDropdown_Select, tier)
        end
    end)

    EncounterJournal.instanceSelect.ExpansionDropdown:SetShown(true)
end

local function EJ_OnContentTabSet(id)
    -- Logger.Log("EJ_ContentTab_Select Hook. Tab ID: %d", id)

    if id ~= EJ_DELVES_TAB_BUTTON_ID then
        DelveCompanion.DelvesList.Frame:Hide()

        if not DelveCompanion.Variables.isPTR then
            EncounterJournal.instanceSelect.ExpansionDropdown:ClearAllPoints()
            EncounterJournal.instanceSelect.ExpansionDropdown:SetPoint("TOPRIGHT",
                EncounterJournal.instanceSelect,
                "TOPRIGHT", -24, -10)
        end

        return
    end

    EJ_HideNonInstancePanels()

    if EJ_GetCurrentTier() < EJ_DELVES_MIN_TIER then
        ExpansionDropdown_Select(GetServerExpansionLevel() + 1)
    end

    SetupExpansionDropdownForDelves()

    if DelveCompanion.Variables.isPTR then
        EncounterJournal_EnableExpansionDropdown(-40, -30, EncounterJournal)

        EncounterJournal_ShowGreatVaultButton()
    else
        EncounterJournal.instanceSelect.ExpansionDropdown:ClearAllPoints()
        EncounterJournal.instanceSelect.ExpansionDropdown:SetPoint("TOPRIGHT", EncounterJournal,
            "TOPRIGHT", -40, -30)
        EncounterJournal_EnableExpansionDropdown()
    end

    DelveCompanion.DelvesList.Frame:Show()
end

local function EJ_OnPostShow()
    -- Logger.Log("EJ_OnPostShow")

    if EncounterJournal.selectedTab == EJ_DELVES_TAB_BUTTON_ID then
        SetupExpansionDropdownForDelves()
    end
end

--- Callback to handle a click on a delve in the list.
---@param _ any
---@param delveData DelveData
local function OnDelveButtonClicked(_, delveData)
    if delveData == nil then
        return
    end

    DelvesList.InfoFrame.data = delveData

    DelvesList.InfoFrame:Setup()
    DelvesList.InfoFrame:Show()
end

--- Create a tab button in EncounterJournal to open Delves list.
---@return Button
local function CreateDelvesTabButton()
    ---@type Button
    local button = CreateFrame("Button", "$parent." .. DELVES_TAB_PARENT_KEY, EncounterJournal,
        "BottomEncounterTierTabTemplate")
    button:SetParentKey(DELVES_TAB_PARENT_KEY)
    button:SetText(_G["DELVES_LABEL"])
    button:SetID(EJ_DELVES_TAB_BUTTON_ID)

    return button
end

--- Initialize Delves list.
local function InitDelvesList()
    ---@type Frame
    local EncounterJournal = EncounterJournal

    if not EncounterJournal then
        Logger.Log("EncounterJournal is nil. Delves tab cannot be created.")
        return
    end

    EJ_DELVES_MIN_TIER = GetEJTierDataTableID(LE_EXPANSION_WAR_WITHIN)

    do
        ---@type DelvesListFrame
        local delvesListFrame = CreateFrame("Frame", "$parent.DelvesListFrame", EncounterJournal,
            "DelveCompanionDelvesListFrameTemplate")
        DelvesList.Frame = delvesListFrame

        -- ---@type DelvesInfoFrame
        -- local infoFrame = CreateFrame("Frame", "$parent.DelveInfoFrame", delvesListFrame,
        --     "DelveCompanionDelveInfoFrameTemplate")
        -- DelvesList.InfoFrame = infoFrame

        -- EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.DELVE_INSTANCE_BUTTON_CLICK,
        --     OnDelveButtonClicked, DelveCompanion.DelvesList)
    end

    do
        ---@type Button
        local tabButton = CreateDelvesTabButton()
        DelvesList.TabButton = tabButton

        PanelTemplates_SetNumTabs(EncounterJournal, EJ_TABS_COUNT)
    end

    hooksecurefunc("EJ_ContentTab_Select", EJ_OnContentTabSet)
    EncounterJournal:HookScript("OnShow", EJ_OnPostShow)
end

EventUtil.ContinueOnAddOnLoaded(DelveCompanion.Definitions.DependencyAddonName.encounterJournal, InitDelvesList)
