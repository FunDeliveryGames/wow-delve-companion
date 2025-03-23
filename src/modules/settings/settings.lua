local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit

local TOGGLE_CONTAINER_MAX_WIDTH = 600

DelveCompanionSettingsToggleMixin = {}

function DelveCompanionSettingsToggleMixin:OnShow()
    -- log("SettingToggle OnShow start...")

    local save = self.saveType == "account" and DelveCompanionAccountData or DelveCompanionCharacterData
    self:SetChecked(save[self.saveVar])
    self:HookScript("OnClick", function(cb)
        save[self.saveVar] = cb:GetChecked()
    end)

    self.Text:SetText(lockit[self.localeKey])
    self.Text:SetWidth(self:GetParent().maximumWidth)
end

DelveCompanionSettingsFrameMixin = {}

function DelveCompanionSettingsFrameMixin:OnLoad()
    -- log("SettingsFrame OnLoad start...")

    self:SetAllPoints()
    self.TitlePanel.Title:SetText(lockit["ui-addon-name"])
    self.TitlePanel.Version:SetText(C_AddOns.GetAddOnMetadata(addonName, "Version"))

    self.AccountTogglesContainer.Title:SetText(lockit["ui-settings-section-title-account"])
    self.AccountTogglesContainer.maximumWidth = TOGGLE_CONTAINER_MAX_WIDTH
    self.AccountTogglesContainer:Layout()

    self.CharacterTogglesContainer.Title:SetText(lockit["ui-settings-section-title-character"])
    self.CharacterTogglesContainer.maximumWidth = TOGGLE_CONTAINER_MAX_WIDTH
    self.CharacterTogglesContainer:Layout()

    self.ReloadButton:SetText(format(_G["SETTINGS_SUBCATEGORY_FMT"], _G["SETTINGS_APPLY"], _G["RELOADUI"]))

    -- Localization section
    self.LocalizationFrame.Title:SetText(lockit["ui-settings-translation-title"])

    self:Hide()
end
