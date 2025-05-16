local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

local EJ_DELVES_TAB_BUTTON_ID = 6
local EJ_TABS_COUNT = 6
--#endregion

--- Callback to handle tabs switch in EncounterJournal and show/hide Delves list.
---@param _ any
---@param EncounterJournal Frame
---@param tabID integer
local function OnTabSet(_, EncounterJournal, tabID)
    if tabID == EJ_DELVES_TAB_BUTTON_ID then
        EJ_HideNonInstancePanels()
        DelveCompanion.DelvesList.Frame:Show()
    else
        DelveCompanion.DelvesList.Frame:Hide()
    end
end

--- Create a tab button in EncounterJournal to open Delves list.
---@return Button
local function CreateDelvesTabButton()
    ---@type Button
    local button = CreateFrame("Button", "$parent.DelvesTab", EncounterJournal,
        "BottomEncounterTierTabTemplate")
    button:SetParentKey("DelvesTab")
    button:SetText(_G["DELVES_LABEL"])
    button:SetID(EJ_DELVES_TAB_BUTTON_ID)

    PanelTemplates_SetNumTabs(EncounterJournal, EJ_TABS_COUNT)

    EventRegistry:RegisterCallback("EncounterJournal.TabSet", OnTabSet, DelveCompanion.DelvesList)

    return button
end

--- Initialize Delves list and a tab button for it.
local function InitDelvesList()
    if not EncounterJournal then
        Logger.Log("EncounterJournal is nil. Delves tab cannot be created.")
        return
    end

    ---@class DelvesList
    ---@field Frame DelvesListFrame
    ---@field TabButton Button
    local DelvesList = {}

    ---@type DelvesListFrame
    local delvesListFrame = CreateFrame("Frame", "$parent.DelvesListFrame", EncounterJournal,
        "DelveCompanionDelvesListFrameTemplate")
    ---@type Button
    local tabButton = CreateDelvesTabButton()

    DelveCompanion.DelvesList = {
        Frame = delvesListFrame,
        TabButton = tabButton
    }
end

EventUtil.ContinueOnAddOnLoaded(DelveCompanion.Definitions.DependencyAddonName.encounterJournal, InitDelvesList)
