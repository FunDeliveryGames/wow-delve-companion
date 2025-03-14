local addonName, addon = ...
local log = addon.log
local enums = addon.enums

--============ DelveCompanionIconWithTextAndTooltip ======================

DelveCompanionIconWithLabelAndTooltipMixin = {}

function DelveCompanionIconWithLabelAndTooltipMixin:OnLoad()
    -- log("DelveCompanionIconWithTextAndTooltip OnLoad start")
    self.Icon:SetSize(self.iconSizeX, self.iconSizeY)

    if not self.displayLabel then
        self.Label:Hide()
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
        log("[DelveCompanionIconWithTextAndTooltip] Unknown frameType: %s", type)
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
        log("[DelveCompanionIconWithTextAndTooltip] Unknown frameType: %s", type)
    end
    GameTooltip:Show()
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnLeave()
    GameTooltip:Hide()
end
