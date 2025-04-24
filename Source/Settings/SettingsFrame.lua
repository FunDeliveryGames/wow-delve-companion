local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

local TOGGLE_CONTAINER_MAX_WIDTH = 600
--#endregion

DelveCompanionSettingsFrameMixin = {}

function DelveCompanionSettingsFrameMixin:OnShow()
    if not DelveCompanion.Variables.tomTomAvailable then
        self.AccountTogglesContainer.useTomTomCheckButton:SetChecked(false)
        self.AccountTogglesContainer.useTomTomCheckButton:SetEnabled(false)
        self.AccountTogglesContainer.useTomTomCheckButton:SetScript("OnEnter", function()
            local tooltip = GameTooltip
            tooltip:SetOwner(self.AccountTogglesContainer.useTomTomCheckButton, "ANCHOR_TOP")
            GameTooltip_AddNormalLine(tooltip, format(Lockit.UI_SETTINGS_MISSING_ADDON_TITLE, "TomTom"), true)
            tooltip:Show()
        end)
        self.AccountTogglesContainer.useTomTomCheckButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        self.AccountTogglesContainer.useTomTomCheckButton.Text:SetFontObject("GameFontDisable")
    end
end

function DelveCompanionSettingsFrameMixin:OnLoad()
    -- Logger.Log("SettingsFrame OnLoad start...")

    self:SetAllPoints()
    self.TitlePanel.Title:SetText(Lockit.UI_ADDON_NAME)
    self.TitlePanel.Version:SetText(C_AddOns.GetAddOnMetadata(addonName, "Version"))

    self.AccountTogglesContainer.Title:SetText(Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT)
    self.AccountTogglesContainer.maximumWidth = TOGGLE_CONTAINER_MAX_WIDTH
    self.AccountTogglesContainer:Layout()

    self.CharacterTogglesContainer.Title:SetText(Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER)
    self.CharacterTogglesContainer.maximumWidth = TOGGLE_CONTAINER_MAX_WIDTH
    self.CharacterTogglesContainer:Layout()

    self.ReloadButton:SetText(format(_G["SETTINGS_SUBCATEGORY_FMT"], _G["SETTINGS_APPLY"], _G["RELOADUI"]))

    -- Localization section
    self.LocalizationFrame.Title:SetText(Lockit.UI_SETTINGS_TRANSLATION_TITLE)
    self.LocalizationFrame:Layout()

    self:Hide()
end
