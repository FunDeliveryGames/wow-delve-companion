local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit

DelveCompanionSettingsToggleMixin = {}

function DelveCompanionSettingsToggleMixin:OnShow()
    -- log("SettingToggle OnShow start...")

    local save = self.saveType == "account" and DelveCompanionAccountData or DelveCompanionCharacterData
    if save[self.saveVar] == nil then
        save[self.saveVar] = self.defaultValue
    end
    self:SetChecked(save[self.saveVar])

    self:HookScript("OnClick", function(cb)
        save[self.saveVar] = cb:GetChecked()
    end)

    self.Text:SetText(lockit[self.localeKey])
    self.Text:SetWidth(self:GetParent().maximumWidth)
end
