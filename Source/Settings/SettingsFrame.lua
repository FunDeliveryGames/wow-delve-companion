local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

--#endregion

DelveCompanionSettingsFrameMixin = {}

function DelveCompanionSettingsFrameMixin:OnLoad()
    -- Logger.Log("SettingsFrame OnLoad start...")

    self:SetAllPoints()
    self.TitlePanel.Text:SetText(Lockit.UI_ADDON_NAME)
    self.TitlePanel.Version:SetText(C_AddOns.GetAddOnMetadata(addonName, "Version"))

    -- Localization section
    self.LocalizationFrame.Title:SetText(Lockit.UI_SETTINGS_TRANSLATION_TITLE)
    self.LocalizationFrame:Layout()
end

function DelveCompanionSettingsFrameMixin:OnShow()
    -- Logger.Log("SettingsFrame OnShow start...")
end
