local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit

--#region Constants

local TOGGLE_CONTAINER_MAX_WIDTH = 600
--#endregion

DelveCompanionSettingsFrameMixin = {}

function DelveCompanionSettingsFrameMixin:OnShow()
    if not addon.tomTomAvailable then
        self.AccountTogglesContainer.useTomTomCheckButton:SetChecked(false)
        self.AccountTogglesContainer.useTomTomCheckButton:SetEnabled(false)
        self.AccountTogglesContainer.useTomTomCheckButton:SetScript("OnEnter", function()
            local tooltip = GameTooltip
            tooltip:SetOwner(self.AccountTogglesContainer.useTomTomCheckButton, "ANCHOR_TOP")
            GameTooltip_AddNormalLine(tooltip, format(lockit["ui-settings-missing-addon-title"], "TomTom"), true)
            tooltip:Show()
        end)
        self.AccountTogglesContainer.useTomTomCheckButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        self.AccountTogglesContainer.useTomTomCheckButton.Text:SetFontObject("GameFontDisable")
    end
end

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
