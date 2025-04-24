local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit

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

    self.Text:SetText(Lockit[self.localeKey])
    self.Text:SetWidth(self:GetParent().maximumWidth)
end
