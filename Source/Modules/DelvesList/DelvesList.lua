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

---@param _ any
---@param EncounterJournal Frame
---@param tabID integer
local function OnTabSet(_, EncounterJournal, tabID)
    if tabID == EJ_DELVES_TAB_BUTTON_ID then
        EJ_HideNonInstancePanels()
        DelveCompanion.DelvesList.frame:Show()
    else
        DelveCompanion.DelvesList.frame:Hide()
    end
end

---@return Button
local function CreateDelvesTabButton()
    local button = CreateFrame("Button", "$parent.DelvesTab", EncounterJournal,
        "BottomEncounterTierTabTemplate")
    button:SetPoint("LEFT", EncounterJournal.LootJournalTab, "RIGHT", -15, 0)
    button:SetText(_G["DELVES_LABEL"])
    button:SetID(EJ_DELVES_TAB_BUTTON_ID)
    button:SetParentKey("delvesTab")

    PanelTemplates_SetNumTabs(EncounterJournal, EJ_TABS_COUNT)

    EventRegistry:RegisterCallback("EncounterJournal.TabSet", OnTabSet, DelveCompanion.DelvesList)

    return button
end

local function InitDelvesList()
    if not EncounterJournal then
        Logger.Log("EncounterJournal is nil. Delves tab is not inited.")
        return
    end

    local delvesListFrame = CreateFrame("Frame", "$parent.DelvesListFrame", EncounterJournal,
        "DelveCompanionDelvesListFrameTemplate")
    local tabButton = CreateDelvesTabButton()

    DelveCompanion.DelvesList = {
        frame = delvesListFrame,
        button = tabButton
    }
end

EventUtil.ContinueOnAddOnLoaded(DelveCompanion.Enums.DependencyAddonName.encounterJournal, InitDelvesList)

--#region DelvesList annotations

---@class DelvesList
---@field frame DelvesListFrame
---@field button Button
--#endregion
