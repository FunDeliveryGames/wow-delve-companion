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

---@type string
local ENABLED_SAVE_KEY = "inDelveWidgetEnabled"
--#endregion

---@class (exact) InDelveWidget
---@field frame InDelveWidgetFrame
---@field setupInProgress boolean Used to prevent double call of the setup which may occur due to the timer delay.
local InDelveWidget = {}
DelveCompanion.InDelveWidget = InDelveWidget

--- It's called before PLAYER_LOGIN so WoW saves its position and handles repositioning between sessions.
---@param self InDelveWidget
function InDelveWidget:PreloadFrame()
    -- Logger:Log("[InDelveWidget] PreloadFrame...")

    ---@type InDelveWidgetFrame
    local widgetFrame = CreateFrame("Frame", "DelveCompanion.InDelveWidgetFrame",
        UIParent, "DelvelCompanionInDelveWidgetFrameTemplate")
    self.frame = widgetFrame
end

---@param self InDelveWidget
function InDelveWidget:Init()
    -- Logger:Log("[InDelveWidget] Init started...")

    self.setupInProgress = false

    do
        ---@param owner InDelveWidget
        local function RefreshInternal(owner)
            owner:Refresh(false)
        end

        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_IN_PROGRESS,
            RefreshInternal, self)
        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_EXITED,
            RefreshInternal, self)
    end

    do
        ---@param owner InDelveWidget
        local function OnSettingChanged(owner, changedVarKey, isEnabled)
            if not (changedVarKey == ENABLED_SAVE_KEY) then
                return
            end
            Logger:Log("[InDelveWidget] OnSettingChanged. Enabled: %s...", tostring(isEnabled))

            owner:Refresh(true)
        end

        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.SETTING_CHANGE, OnSettingChanged, self)
    end

    do
        local function OnOptionsVisibilityChanged()
            self:Refresh(true)
        end

        -- CategoryChanged does not fire when the panel reopens on the same page
        EventRegistry:RegisterCallback("Settings.CategoryChanged", OnOptionsVisibilityChanged, self)
        if SettingsPanel then
            SettingsPanel:HookScript("OnShow", OnOptionsVisibilityChanged)
            SettingsPanel:HookScript("OnHide", OnOptionsVisibilityChanged)
        end
    end

    if DelveCompanion.ProgressTracker.isDelveInProgress then
        -- Logger:Log("[InDelveWidget] Already in Delve. Forced setup.")
        self:Refresh(true)
    end
end

--- Whether the addon's own options page is on screen, which is when the widget is previewed.
--- So its size and position can be set outside a Delve.
---@return boolean
local function IsAddOnOptionsShown()
    if not (SettingsPanel and SettingsPanel:IsShown() and SettingsPanel.GetCurrentCategory) then
        return false
    end

    local settings = DelveCompanion.AddonSettings
    if not settings then
        return false
    end

    local current = SettingsPanel:GetCurrentCategory()
    return current ~= nil and current == settings.optionsCategory
end

---@param self InDelveWidget
---@param isForced boolean
function InDelveWidget:Refresh(isForced)
    -- Logger:Log("[InDelveWidget] Refresh...")

    local isInDelve = DelveCompanion.ProgressTracker.isDelveInProgress
    local isPreview = IsAddOnOptionsShown()

    if not DelveCompanionAccountData.inDelveWidgetEnabled or not (isInDelve or isPreview) then
        self:HideWidget()
        return
    end

    self.frame.previewMode = isPreview

    if self.frame.isSet then
        self.frame:Refresh()
        return
    end

    if self.setupInProgress then
        return
    end

    self.setupInProgress = true
    -- self.setupToken = (self.setupToken or 0) + 1
    -- local token = self.setupToken
    -- Timer is required for a case when player switches between characters while one of them is in a Delve.
    -- For unknown reason, the continent cannot be retrieved immediately logging back to the character in a Delve. And the widget gets broken.
    C_Timer.After(2,
        function()
            -- a newer setup bumps the token, so a cancelled timer cannot finish this one
            if not self.setupInProgress --[[or self.setupToken ~= token]] then
                return
            end

            local delveContinent = DelveCompanion:GetContinentMapIDForMap(C_Map.GetBestMapForUnit("player"))

            self.frame.delveExpansion = FindInTableIf(
                Config.DELVE_CONTINENTS,
                function(continentMapID)
                    return continentMapID == delveContinent
                end
            )

            self.frame:PrepareWidget(isForced)
            self.frame:Show()

            self.setupInProgress = false
        end
    )
end

---@param self InDelveWidget
function InDelveWidget:HideWidget()
    -- Logger:Log("[InDelveWidget] Hide widget...")

    self.setupInProgress = false
    self.frame:Hide()
end
