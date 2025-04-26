local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

--#region Constants

local SETTINGS_CATEGORY_ID = tostring(addonName)
--#endregion

--- Global function to open addon settings. Used in `TOC` file for [AddonCompartmentFunc](https://warcraft.wiki.gg/wiki/TOC_format#AddonCompartmentFunc).
function DelveCompanionShowSettings()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(SETTINGS_CATEGORY_ID)
    end
end

--- Class for managing addon settings.
---@class AddonSettings
local AddonSettings = {}
DelveCompanion.AddonSettings = AddonSettings

-- TODO: Explore a new Settings API. Maybe Settings.RegisterAddOnSetting is more convenient way to setup settings.
function AddonSettings:Init()
    -- Logger.Log("Start initing Settings...")
    local settingsFrame = CreateFrame("Frame", SETTINGS_CATEGORY_ID, nil, "DelveCompanionSettingsFrame")
    settingsFrame.name = SETTINGS_CATEGORY_ID
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(settingsFrame, settingsFrame.name)
        category.ID = settingsFrame.name
        Settings.RegisterAddOnCategory(category)
    end
    -- Logger.Log("Settings inited")
end
