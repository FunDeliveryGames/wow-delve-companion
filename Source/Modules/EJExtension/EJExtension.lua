local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

---@type number
local EJ_TABS_COUNT = 8

--- Blizzard functions after which UI suites re-chain the stock tabs (ElvUI's `RepositionTabs` hooks them).
---@type string[]
local EJ_TAB_REFRESH_FUNCTIONS = {
    "EncounterJournal_CheckAndDisplaySuggestedContentTab",
    "EncounterJournal_CheckAndDisplayTradingPostTab"
}

--- The stock Encounter Journal tab chain. Used unless the active UI suite chains the tabs its own way (ElvUI).
local DEFAULT_TAB_LAYOUT = { point = "LEFT", relativePoint = "RIGHT", x = 3, y = 0 }
--#endregion

---@class (exact) EJExtension
---@field DelvesList DelvesList
---@field DelveEncounter DelveEncounter
---@field tabRefreshHooked boolean? Whether `EJ_TAB_REFRESH_FUNCTIONS` are hooked.
local EJExtension = {}
DelveCompanion.EJExtension = EJExtension

---@param self EJExtension
function EJExtension:Init()
    -- Logger:Log("[EJExtension] Init started...")

    ---@type Frame
    local EncounterJournal = EncounterJournal

    if not EncounterJournal then
        Logger:Log("[EJExtension] EncounterJournal is nil. Cannot init!")
        return
    end

    -- DelvesList
    do
        self.DelvesList:Init(EncounterJournal)

        -- TODO: Check later whether Blizz has changed smth that is a root cause of the issue #75
        -- PanelTemplates_SetNumTabs(EncounterJournal, EJ_TABS_COUNT)
    end

    -- JourneysFrame
    do
        self.DelveEncounter:Init(EncounterJournal.JourneysFrame)
    end

    EncounterJournal:HookScript("OnShow",
        function()
            EJExtension:EJ_OnShowHook()
        end
    )

    hooksecurefunc("EJ_ContentTab_Select",
        function(id)
            EJExtension:OnContentTabSet(id)
        end
    )
end

--- Insert the Delves tab after the Suggested Content tab. The spacing follows the active UI suite, if any.
---@param self EJExtension
function EJExtension:LayoutTabs()
    ---@type Frame
    local EncounterJournal = EncounterJournal
    local delvesTab = self.DelvesList.TabButton
    if not (EncounterJournal and delvesTab) then
        return
    end

    local UISkin = DelveCompanion.UISkin
    local point, relativePoint, offsetX, offsetY = UISkin:GetTabLayout(UISkin.Host.journal, delvesTab)
    if not point then
        point, relativePoint = DEFAULT_TAB_LAYOUT.point, DEFAULT_TAB_LAYOUT.relativePoint
        offsetX, offsetY = DEFAULT_TAB_LAYOUT.x, DEFAULT_TAB_LAYOUT.y
    end

    ---@param tab Button?
    ---@param relativeTo Button?
    local function SetTabAnchor(tab, relativeTo)
        if not (tab and relativeTo) then
            return
        end

        tab:ClearAllPoints()
        tab:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
    end

    SetTabAnchor(delvesTab, EncounterJournal.suggestTab)
    SetTabAnchor(EncounterJournal.dungeonsTab, delvesTab)
    SetTabAnchor(EncounterJournal.raidsTab, EncounterJournal.dungeonsTab)
    SetTabAnchor(EncounterJournal.TutorialsTab, EncounterJournal.raidsTab)

    -- Suites may resize the stock tabs (e.g. EllesmereUI trims their height).
    if UISkin:IsActive() and EncounterJournal.dungeonsTab then
        delvesTab:SetHeight(EncounterJournal.dungeonsTab:GetHeight())
    end
end

--- With a UI suite, re-apply the tab layout after the suite re-chains the stock tabs.
--- Installed on the first OnShow, after the suites' Encounter Journal skins, so these hooks run after theirs.
---@param self EJExtension
function EJExtension:HookTabRefresh()
    if self.tabRefreshHooked or not DelveCompanion.UISkin:IsActive() then
        return
    end
    self.tabRefreshHooked = true

    for _, functionName in ipairs(EJ_TAB_REFRESH_FUNCTIONS) do
        if type(_G[functionName]) == "function" then
            hooksecurefunc(functionName, function()
                EJExtension:LayoutTabs()
            end)
        end
    end
end

---@param self EJExtension
function EJExtension:EJ_OnShowHook()
    -- Logger:Log("[EJExtension] OnShow hook")

    ---@type Frame
    local EncounterJournal = EncounterJournal

    self:LayoutTabs()
    if DelveCompanion.UISkin:IsActive() then
        self:HookTabRefresh()

        -- A suite may re-chain the tabs later in the same OnShow.
        RunNextFrame(function()
            self:LayoutTabs()
        end)
    end

    -- Being closed, EncounterJournal remembers the last opened tab.
    -- While OnContentTabSet is called before OnShow, the expansion dropdown gets reset somewhere in between.
    -- And if the last tab is the Delves tab, the dropdown will contain all expansions. So it should be set here for Delves.
    if EncounterJournal.selectedTab == self.DelvesList.TabButton:GetID() then
        self.DelvesList:SetupExpansionDropdownForDelves(EncounterJournal, ExpansionDropdown_Select)
    end
end

---@param self EJExtension
function EJExtension:OnExpansionDropdownSelected(tier)
    EJ_SelectTier(tier)

    local EncounterJournal = EncounterJournal

    local tierData = GetEJTierData(tier)
    do
        -- JourneysFrame has an internal variable to control the current displayed expansion. It should be set to properly reflect expansion switch done on the Delves tab.

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
        self.DelvesList.Frame:Refresh()
    end
end

local function ExpansionDropdown_Select(tier)
    EJExtension:OnExpansionDropdownSelected(tier)
end

---@param self EJExtension
function EJExtension:OnContentTabSet(id)
    -- Logger:Log("EJ_ContentTab_Select Hook. Tab ID: %d", id)

    local EncounterJournal = EncounterJournal

    if id ~= self.DelvesList.TabButton:GetID() then
        self.DelvesList.Frame:Hide()
        PanelTemplates_DeselectTab(self.DelvesList.TabButton)
        DelveCompanion.UISkin:SetTabSelected(DelveCompanion.UISkin.Host.journal, self.DelvesList.TabButton, false)

        return
    end

    EJ_HideNonInstancePanels()
    EncounterJournal_ShowGreatVaultButton()

    -- If the Delves tab is opened with an earlier expansion selected, set the selected EJ Tier to the current expansion.
    if EJ_GetCurrentTier() < self.DelvesList.delvesMinTier then
        ExpansionDropdown_Select(GetServerExpansionLevel() + 1)
    end
    self.DelvesList:SetupExpansionDropdownForDelves(EncounterJournal, ExpansionDropdown_Select)
    EncounterJournal_EnableExpansionDropdown(-40, -30, EncounterJournal)
    EncounterJournal.instanceSelect.ExpansionDropdown:SetShown(true)
    EncounterJournal.instanceSelect.Title:SetShown(false)

    self.DelvesList.Frame:Show()
    PanelTemplates_SelectTab(self.DelvesList.TabButton)
    DelveCompanion.UISkin:SetTabSelected(DelveCompanion.UISkin.Host.journal, self.DelvesList.TabButton, true)
end
