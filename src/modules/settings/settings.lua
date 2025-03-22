local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit

DelveCompanionSettingsFrameMixin = {}

function DelveCompanionSettingsFrameMixin:OnLoad()
    -- log("SettingsFrame OnLoad start...")
    if not DelveCompanionCharacterData then
        DelveCompanionCharacterData = {
            gvDetailsEnabled = true,
            keysCapTooltipEnabled = true,
            dashOverviewEnabled = true,
            GildedStashData = {
                isInited = false,
                cachedCollectedCount = 0
            }
        }
    end

    self:SetAllPoints()
    self.TitlePanel.Title:SetText(lockit["ui-addon-name"])

    -- Prepare toggles
    self.TogglesContainer.gvDetailsCheckButton:SetChecked(DelveCompanionCharacterData.gvDetailsEnabled)
    self.TogglesContainer.gvDetailsCheckButton.Text:SetText(lockit["ui-settings-gv-details"])
    self.TogglesContainer.gvDetailsCheckButton:HookScript("OnClick", function(cb)
        DelveCompanionCharacterData.gvDetailsEnabled = cb:GetChecked()
    end)

    self.TogglesContainer.keysCapTooltipCheckButton:SetChecked(DelveCompanionCharacterData.keysCapTooltipEnabled)
    self.TogglesContainer.keysCapTooltipCheckButton.Text:SetText(lockit["ui-settings-keys-cap"])
    self.TogglesContainer.keysCapTooltipCheckButton:HookScript("OnClick", function(cb)
        DelveCompanionCharacterData.keysCapTooltipEnabled = cb:GetChecked()
    end)

    self.TogglesContainer.dashOverviewCheckButton:SetChecked(DelveCompanionCharacterData.dashOverviewEnabled)
    self.TogglesContainer.dashOverviewCheckButton.Text:SetText(lockit["ui-settings-dashboard-overview"])
    self.TogglesContainer.dashOverviewCheckButton:HookScript("OnClick", function(cb)
        DelveCompanionCharacterData.dashOverviewEnabled = cb:GetChecked()
    end)
    self.TogglesContainer:Layout()

    self.ReloadButton:SetText(format(_G["SETTINGS_SUBCATEGORY_FMT"], _G["SETTINGS_APPLY"], _G["RELOADUI"]))
    local buttonOffsetY = -(self.TogglesContainer:GetHeight() + 15)
    self.ReloadButton:SetPoint("TOPLEFT", self.TitlePanel, "BOTTOMLEFT", 0, buttonOffsetY)

    self.LocalizationFrame.Title:SetText(lockit["ui-settings-translation-title"])

    self:Hide()
end
