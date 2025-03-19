local addonName, addon = ...
local log = addon.log
local enums = addon.enums
local lockit = addon.lockit

--============ DelveCompanionIconWithTextAndTooltip ======================

DelveCompanionIconWithLabelAndTooltipMixin = {}

function DelveCompanionIconWithLabelAndTooltipMixin:OnLoad()
    -- log("DelveCompanionIconWithTextAndTooltip OnLoad start")
    self.Icon:SetSize(self.iconSizeX, self.iconSizeY)

    if not self.displayLabel then
        self.Label:Hide()
    end

    if self.useAutoScaling then
        Mixin(self.Label, AutoScalingFontStringMixin)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnShow()
    -- log("DelveCompanionIconWithTextAndTooltip OnShow start")

    local texture = nil
    local type, code = self.frameType, self.frameCode
    if type == enums.CodeType.Item then
        texture = C_Item.GetItemIconByID(code)
    elseif type == enums.CodeType.Spell then
        texture = C_Spell.GetSpellTexture(code)
    elseif type == enums.CodeType.Currency then
        texture = C_CurrencyInfo.GetCurrencyInfo(code).iconFileID
    elseif type == enums.CodeType.Achievement then
        _, _, _, _, _, _, _, _, _, texture = GetAchievementInfo(code)
    else
        log(lockit["ui-debug-unexpected-enum-element"], tostring(enums.CodeType), type)
    end

    if texture then
        self.Icon:SetTexture(texture)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    local type, code = self.frameType, self.frameCode
    if type == enums.CodeType.Item then
        GameTooltip:SetItemByID(code)
    elseif type == enums.CodeType.Spell then
        GameTooltip:SetSpellByID(code)
    elseif type == enums.CodeType.Currency then
        GameTooltip:SetCurrencyByID(code)
    elseif type == enums.CodeType.Achievement then
        GameTooltip:SetAchievementByID(code)
    else
        log(lockit["ui-debug-unexpected-enum-element"], tostring(enums.CodeType), type)
    end
    GameTooltip:Show()
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnLeave()
    GameTooltip:Hide()
end

--============ Settings ======================
DelveCompanionSettingsFrameMixin = {}

function DelveCompanionSettingsFrameMixin:OnLoad()
    -- log("SettingsFrame OnLoad start...")
    if not DelveCompanionCharacterData then
        DelveCompanionCharacterData = {
            gvDetailsEnabled = true,
            keysCapTooltipEnabled = true,
            dashOverviewEnabled = true,
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

    self.ReloadButton:SetText(format(lockit["ui-settings-apply-button"], _G["SETTINGS_APPLY"], _G["RELOADUI"]))

    self:Hide()
end
