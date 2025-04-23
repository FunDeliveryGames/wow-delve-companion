local addonName, DelveCompanion = ...
---@type Logger
local Logger = DelveCompanion.Logger
local enums = DelveCompanion.enums
local lockit = DelveCompanion.lockit

--============ DelveCompanionIconWithTextAndTooltip ======================

local DEFAULT_LABEL_OFFSET_X = -5
local DEFAULT_LABEL_OFFSET_Y = 0
local DEFAULT_LABEL_ANCHOR = "LEFT"
DelveCompanionIconWithLabelAndTooltipMixin = {}

function DelveCompanionIconWithLabelAndTooltipMixin:SetOnClick(func)
    local relKey = self.useMask and self.CircleMask or self
    self.ClickCatcher:SetAllPoints(relKey)
    self.ClickCatcher:SetSize(relKey:GetSize())
    self.ClickCatcher:SetScript("OnClick", func)
end

function DelveCompanionIconWithLabelAndTooltipMixin:SetLabelText(text)
    if text then
        self.Label:SetText(text)
    end
end

local function SetFromAtlas(self)
    if self.atlasTexture then
        self.Icon:SetAtlas(self.atlasTexture)
    end
end

local function SetFromTexture(self)
    local texture = nil
    local type, code = self.frameType, tonumber(self.frameCode)

    if not code then
        return
    end

    if type == enums.CodeType.Item then
        texture = C_Item.GetItemIconByID(code)
    elseif type == enums.CodeType.Spell then
        texture = C_Spell.GetSpellTexture(code)
    elseif type == enums.CodeType.Currency then
        texture = C_CurrencyInfo.GetCurrencyInfo(code).iconFileID
    elseif type == enums.CodeType.Achievement then
        texture = select(10, GetAchievementInfo(code))
    else
        Logger.Log(lockit["ui-debug-unexpected-enum-element"], tostring(enums.CodeType), type)
    end

    if texture then
        self.Icon:SetTexture(texture)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:SetFrameInfo(frameType, frameCode)
    if frameType and FindInTable(enums.CodeType, frameType) then
        self.frameType = frameType
    end

    if frameCode and tonumber(frameCode) then
        self.frameCode = tonumber(frameCode)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnLoad()
    -- Logger.Log("DelveCompanionIconWithTextAndTooltip OnLoad start")
    self.Icon:SetSize(self.iconSizeX, self.iconSizeY)

    if not self.displayLabel then
        self.Label:Hide()
    end

    if self.fontOverride then
        self.Label:SetFontObject(self.fontOverride)
    end

    if self.useAutoScaling then
        Mixin(self.Label, AutoScalingFontStringMixin)
    end

    if self.useMask then
        self.CircleMask:SetPoint("TOPLEFT", self, "CENTER", self.maskSizeOffset, -self.maskSizeOffset)
        self.CircleMask:SetPoint("BOTTOMRIGHT", self, "CENTER", -self.maskSizeOffset, self.maskSizeOffset)
        self.CircleMask:Show()
        self.Icon:AddMaskTexture(self.CircleMask)
    end

    local relPoint = self.labelRelPoint or DEFAULT_LABEL_ANCHOR
    local relKey = self.useMask and self.CircleMask or self.Icon
    local offsetX = self.labelOffsetX or DEFAULT_LABEL_OFFSET_X
    local offsetY = self.labelOffsetY or DEFAULT_LABEL_OFFSET_Y
    self.Label:ClearAllPoints()
    if relPoint == "TOPLEFT" then
        self.Label:SetPoint("TOPRIGHT", relKey, relPoint, offsetX, offsetY)
    elseif relPoint == "TOPRIGHT" then
        self.Label:SetPoint("TOPLEFT", relKey, relPoint, offsetX, offsetY)
    elseif relPoint == "BOTTOMLEFT" then
        self.Label:SetPoint("BOTTOMRIGHT", relKey, relPoint, offsetX, offsetY)
    elseif relPoint == "BOTTOMRIGHT" then
        self.Label:SetPoint("BOTTOMLEFT", relKey, relPoint, offsetX, offsetY)
    elseif relPoint == "TOP" then
        self.Label:SetPoint("BOTTOM", relKey, relPoint, offsetX, offsetY)
    elseif relPoint == "BOTTOM" then
        self.Label:SetPoint("TOP", relKey, relPoint, offsetX, offsetY)
    elseif relPoint == "RIGHT" then
        self.Label:SetPoint("LEFT", relKey, relPoint, offsetX, offsetY)
        self.Label:SetJustifyH("LEFT")
    elseif relPoint == "LEFT" then
        self.Label:SetPoint("RIGHT", relKey, relPoint, offsetX, offsetY)
    elseif relPoint == "CENTER" then
        self.Label:SetPoint("CENTER", relKey, relPoint, offsetX, offsetY)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnShow()
    -- Logger.Log("DelveCompanionIconWithTextAndTooltip OnShow start")

    if self.atlasTexture then
        SetFromAtlas(self)
    else
        SetFromTexture(self)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnHide()
    -- Logger.Log("DelveCompanionIconWithTextAndTooltip OnHide start")
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    local type, code = self.frameType, tonumber(self.frameCode)

    if not code then
        return
    end

    if type == enums.CodeType.Item then
        GameTooltip:SetItemByID(code)
    elseif type == enums.CodeType.Spell then
        GameTooltip:SetSpellByID(code)
    elseif type == enums.CodeType.Currency then
        GameTooltip:SetCurrencyByID(code)
    elseif type == enums.CodeType.Achievement then
        -- GameTooltip:SetAchievementByID(code)
        GameTooltip:SetHyperlink(GetAchievementLink(code))
    else
        Logger.Log(lockit["ui-debug-unexpected-enum-element"], tostring(enums.CodeType), type)
    end
    GameTooltip:Show()
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnLeave()
    GameTooltip:Hide()
end
