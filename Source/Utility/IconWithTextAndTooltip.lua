local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit

local DEFAULT_LABEL_OFFSET_X = -5
local DEFAULT_LABEL_OFFSET_Y = 0
local DEFAULT_LABEL_ANCHOR = "LEFT"

---@class (exact) IconWithLabelAndTooltip : IconWithLabelAndTooltipXml
---@field iconSizeX number
---@field iconSizeY number
---@field displayLabel boolean
---@field frameType string
---@field frameCode number
---@field useAutoScaling boolean
---@field atlasTexture string?
---@field useMask boolean?
---@field maskSizeOffset number?
---@field labelRelPoint string?
---@field labelOffsetX number?
---@field labelOffsetY number?
---@field fontOverride string?
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

    local Enums = DelveCompanion.Enums
    if type == Enums.CodeType.Item then
        texture = C_Item.GetItemIconByID(code)
    elseif type == Enums.CodeType.Spell then
        texture = C_Spell.GetSpellTexture(code)
    elseif type == Enums.CodeType.Currency then
        texture = C_CurrencyInfo.GetCurrencyInfo(code).iconFileID
    elseif type == Enums.CodeType.Achievement then
        texture = select(10, GetAchievementInfo(code))
    else
        Logger.Log(Lockit.DEBUG_UNEXPECTED_ENUM_ELEMENT, tostring(Enums.CodeType), type)
    end

    if texture then
        self.Icon:SetTexture(texture)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:SetFrameInfo(frameType, frameCode)
    if frameType and FindInTable(DelveCompanion.Enums.CodeType, frameType) then
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

    local Enums = DelveCompanion.Enums
    if type == Enums.CodeType.Item then
        GameTooltip:SetItemByID(code)
    elseif type == Enums.CodeType.Spell then
        GameTooltip:SetSpellByID(code)
    elseif type == Enums.CodeType.Currency then
        GameTooltip:SetCurrencyByID(code)
    elseif type == Enums.CodeType.Achievement then
        -- GameTooltip:SetAchievementByID(code)
        GameTooltip:SetHyperlink(GetAchievementLink(code))
    else
        Logger.Log(Lockit.DEBUG_UNEXPECTED_ENUM_ELEMENT, tostring(Enums.CodeType), type)
    end
    GameTooltip:Show()
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnLeave()
    GameTooltip:Hide()
end

--#region IconWithLabelAndTooltipXml annotations

---@class IconWithLabelAndTooltipXml : Frame
---@field Icon Texture
---@field CircleMask MaskTexture
---@field Label FontString
---@field ClickCatcher Button
--#endregion
