local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit
---@type Config
local Config = DelveCompanion.Config

--#region Constants

---@type string
local ADDON_SETTING_PREFIX = tostring(addonName) .. "_"
--#endregion

--- Class for managing addon settings.
---@class (exact) AddonSettings
---@field mainCategory table
local AddonSettings = {}
DelveCompanion.AddonSettings = AddonSettings

--- Global function to open addon settings. Used in `TOC` file for [AddonCompartmentFunc](https://warcraft.wiki.gg/wiki/TOC_format#AddonCompartmentFunc).
function DelveCompanionShowSettings()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(AddonSettings.mainCategory:GetID())
    end
end

--- This callback will be invoked whenever a setting is modified.
local function OnSettingChanged(setting, value)
    -- Logger.Log("OnChanged registered...")

    local variableName = gsub(setting:GetVariable(), ADDON_SETTING_PREFIX, "")
    EventRegistry:TriggerEvent(DelveCompanion.Enums.Events.ON_SETTING_CHANGED, variableName, value)
end

--- Create and register an addon Setting.
---@param category any
---@param varKey string
---@param varTbl DelveCompanionAccountData|DelveCompanionCharacterData
---@param defaultValue any
---@param displayText string
---@param onChangedCallback function
---@return unknown?
local function RegisterSetting(category, varKey, varTbl, defaultValue, displayText, onChangedCallback)
    if varTbl[varKey] == nil then
        Logger.Log("Save table `%s` contains unknown key: %s!", varTbl, varKey)
        return nil
    end

    local setting = Settings.RegisterAddOnSetting(
        category, ADDON_SETTING_PREFIX .. varKey,
        varKey, varTbl,
        type(defaultValue), displayText, defaultValue)
    setting:SetValueChangedCallback(onChangedCallback)

    return setting
end

--- Accound-wide settings.
---@param category any
---@param layout any
local function PrepareAccountSettings(category, layout)
    ---@type DelveCompanionAccountData
    local savedVarTbl = DelveCompanionAccountData

    --- Section header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT))

    do
        local savedVarKey = "achievementWidgetsEnabled"

        local setting = RegisterSetting(category, savedVarKey, savedVarTbl,
            Config.DEFAULT_ACCOUNT_DATA.achievementWidgetsEnabled,
            Lockit.UI_SETTINGS_ACH_WIDGETS, OnSettingChanged)

        local tooltip = Lockit.UI_SETTINGS_ACH_WIDGETS
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local savedVarKey = "trackingType"

        local setting = RegisterSetting(category, savedVarKey, savedVarTbl,
            Config.DEFAULT_ACCOUNT_DATA.trackingType,
            Lockit.UI_SETTINGS_TOMTOM_DESCRIPTION, OnSettingChanged)

        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add(DelveCompanion.Enums.WaypointTrackingType.superTrack, "Blizzard Map Pin",
                "Blizzard Super Track")
            if DelveCompanion.Variables.tomTomAvailable then
                container:Add(DelveCompanion.Enums.WaypointTrackingType.tomtom, "TomTom", "TomTom waypoints")
            end
            return container:GetData()
        end
        local tooltip = Lockit.UI_SETTINGS_TOMTOM_DESCRIPTION

        Settings.CreateDropdown(category, setting, GetOptions, tooltip)
    end
end

--- Character-wide settings.
---@param category any
---@param layout any
local function PrepareCharacterSettings(category, layout)
    ---@type DelveCompanionCharacterData
    local savedVarTbl = DelveCompanionCharacterData

    --- Section header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER))

    do
        local savedVarKey = "keysCapTooltipEnabled"

        local setting = RegisterSetting(category, savedVarKey, savedVarTbl,
            Config.DEFAULT_CHARACTER_DATA.keysCapTooltipEnabled,
            Lockit.UI_SETTINGS_KEYS_CAP, OnSettingChanged)

        local tooltip = Lockit.UI_SETTINGS_KEYS_CAP
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local controlSavedVarKey = "displayCompanionConfig"
        local dropdownSavedVarKey = "companionConfigLayout"

        local controlSetting = RegisterSetting(category, controlSavedVarKey, savedVarTbl,
            Config.DEFAULT_CHARACTER_DATA.displayCompanionConfig,
            Lockit.UI_SETTINGS_COMPANION_LAYOUT, OnSettingChanged)

        local dropdownSetting = RegisterSetting(category, dropdownSavedVarKey, savedVarTbl,
            Config.DEFAULT_CHARACTER_DATA.companionConfigLayout,
            Lockit.UI_SETTINGS_COMPANION_LAYOUT, OnSettingChanged)

        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add(DelveCompanion.Enums.CompanionWidgetLayout.horizontal,
                "Horizontal",
                "Horizontal Companion layout")
            container:Add(DelveCompanion.Enums.CompanionWidgetLayout.vertical,
                "Vertical",
                "Vertical Companion layout")

            return container:GetData()
        end
        local controlTooltip = Lockit.UI_SETTINGS_COMPANION_LAYOUT
        local dropdownTooltip = Lockit.UI_SETTINGS_COMPANION_LAYOUT

        local initializer = CreateSettingsCheckboxDropdownInitializer(
            controlSetting, controlTooltip, controlTooltip,
            dropdownSetting, GetOptions, dropdownTooltip, dropdownTooltip)
        layout:AddInitializer(initializer)
    end

    do
        local savedVarKey = "gvDetailsEnabled"

        local setting = RegisterSetting(category, savedVarKey, savedVarTbl,
            Config.DEFAULT_CHARACTER_DATA.gvDetailsEnabled,
            Lockit.UI_SETTINGS_GV_DETAILS, OnSettingChanged)

        local tooltip = Lockit.UI_SETTINGS_GV_DETAILS
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local savedVarKey = "dashOverviewEnabled"

        local setting = RegisterSetting(category, savedVarKey, savedVarTbl,
            Config.DEFAULT_CHARACTER_DATA.dashOverviewEnabled,
            Lockit.UI_SETTINGS_DASHBOARD_OVERVIEW, OnSettingChanged)

        local tooltip = Lockit.UI_SETTINGS_DASHBOARD_OVERVIEW
        Settings.CreateCheckbox(category, setting, tooltip)
    end
end

function AddonSettings:Init()
    -- Logger.Log("Start initing Settings...")

    do
        local settingsFrame = CreateFrame("Frame", "$parent.DelveCompanionSettings", nil, "DelveCompanionSettingsFrame")
        local category, _ = Settings.RegisterCanvasLayoutCategory(settingsFrame, Lockit.UI_ADDON_NAME)
        Settings.RegisterAddOnCategory(category)
        AddonSettings.mainCategory = category
    end

    do
        local category, layout = Settings.RegisterVerticalLayoutSubcategory(AddonSettings.mainCategory, _G["OPTIONS"])

        PrepareAccountSettings(category, layout)
        PrepareCharacterSettings(category, layout)

        Settings.RegisterAddOnCategory(category)
    end

    -- Logger.Log("Settings inited")
end
