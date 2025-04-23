local addonName, DelveCompanion = ...
---@type Logger
local Logger = DelveCompanion.Logger
local lockit = DelveCompanion.lockit

DelveCompanionSettingsToggleMixin = {}

function DelveCompanionSettingsToggleMixin:OnShow()
    -- Logger.Log("SettingToggle OnShow start...")

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
