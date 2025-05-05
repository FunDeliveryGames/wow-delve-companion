local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

---@type number
local DEFAULT_LABEL_OFFSET_X = -5
---@type number
local DEFAULT_LABEL_OFFSET_Y = 0
---@type FramePoint
local DEFAULT_LABEL_ANCHOR = "LEFT"
---@type TooltipAnchor
local DEFAULT_TOOLTIP_ANCHOR = "ANCHOR_TOP"
--#endregion

---@class (exact) CustomActionWidget : CustomActionWidgetXml
---@field iconSizeX number
---@field iconSizeY number
---@field displayLabel boolean
---@field frameType CodeType
---@field frameCode number
---@field useAutoScaling boolean
---@field atlasTexture string?
---@field useMask boolean?
---@field maskSizeOffset number?
---@field tooltipAnchor TooltipAnchor?
---@field labelRelPoint FramePoint?
---@field labelOffsetX number?
---@field labelOffsetY number?
---@field fontOverride string?
DelveCompanionCustomActionWidgetMixin = {}

--- Set `OnClick` script.
---@param self CustomActionWidget
---@param func function
function DelveCompanionCustomActionWidgetMixin:SetOnClick(func)
    if func == nil then
        return
    end

    local relKey = self.useMask and self.CircleMask or self
    self.ClickCatcher:SetAllPoints(relKey)
    self.ClickCatcher:SetSize(relKey:GetSize())
    self.ClickCatcher:SetScript("OnClick", func)

    self.InsecureAction:SetEnabled(false)
    self.ClickCatcher:SetEnabled(true)
end

--- Set InsecureAction button attributes.
---@param self CustomActionWidget
---@param attributes { [string]: string }
function DelveCompanionCustomActionWidgetMixin:SetInsecureAction(attributes)
    local relKey = self.useMask and self.CircleMask or self
    self.InsecureAction:SetAllPoints(relKey)
    self.InsecureAction:SetSize(relKey:GetSize())

    for type, value in pairs(attributes) do
        self.InsecureAction:SetAttribute(type, value)
    end

    self.ClickCatcher:SetEnabled(false)
    self.InsecureAction:SetEnabled(true)
end

---@param self CustomActionWidget
---@param text string|integer|number
function DelveCompanionCustomActionWidgetMixin:SetLabelText(text)
    if text then
        self.Label:SetText(tostring(text))
    end
end

---@param self CustomActionWidget
local function SetFromAtlas(self)
    if self.atlasTexture then
        self.Icon:SetAtlas(self.atlasTexture)
    end
end

---@param self CustomActionWidget
local function SetFromTexture(self)
    local texture = nil
    local type, code = self.frameType, self.frameCode

    if not code then
        return
    end

    local enums = DelveCompanion.Enums
    if type == enums.CodeType.Item then
        texture = C_Item.GetItemIconByID(code)
    elseif type == enums.CodeType.Spell then
        texture = C_Spell.GetSpellTexture(code)
    elseif type == enums.CodeType.Currency then
        texture = C_CurrencyInfo.GetCurrencyInfo(code).iconFileID
    elseif type == enums.CodeType.Achievement then
        texture = select(10, GetAchievementInfo(code))
    else
        Logger.Log(Lockit.DEBUG_UNEXPECTED_ENUM_ELEMENT, tostring(enums.CodeType), type)
    end

    if texture then
        self.Icon:SetTexture(texture)
    end
end

--- Set what kind of game entity this Frame displays. Used to display a proper tooltip.
---@param self CustomActionWidget
---@param frameType string Game entity type from [CodeType](lua://CodeType).
---@param frameCode number Corresponding in-game ID (e.g. `Item` ID).
function DelveCompanionCustomActionWidgetMixin:SetFrameInfo(frameType, frameCode)
    if not (frameType and FindInTable(DelveCompanion.Enums.CodeType, frameType) and frameCode) then
        return
    end

    self.frameType = frameType
    self.frameCode = frameCode
end

---@param self CustomActionWidget
function DelveCompanionCustomActionWidgetMixin:OnLoad()
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

    ---@type FramePoint
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

    self.ClickCatcher:SetEnabled(false)
    self.InsecureAction:SetEnabled(false)
end

---@param self CustomActionWidget
function DelveCompanionCustomActionWidgetMixin:OnShow()
    -- Logger.Log("DelveCompanionIconWithTextAndTooltip OnShow start")

    if self.atlasTexture then
        SetFromAtlas(self)
    else
        SetFromTexture(self)
    end
end

---@param self CustomActionWidget
function DelveCompanionCustomActionWidgetMixin:OnHide()
    -- Logger.Log("DelveCompanionIconWithTextAndTooltip OnHide start")
end

---@param self CustomActionWidget
function DelveCompanionCustomActionWidgetMixin:OnEnter()
    local type, code = self.frameType, self.frameCode
    if not (type and code) then
        return
    end

    local tooltip = GameTooltip
    tooltip:SetOwner(self, self.tooltipAnchor or DEFAULT_TOOLTIP_ANCHOR)

    local enums = DelveCompanion.Enums
    if type == enums.CodeType.Item then
        tooltip:SetItemByID(code)
    elseif type == enums.CodeType.Spell then
        tooltip:SetSpellByID(code)
    elseif type == enums.CodeType.Currency then
        tooltip:SetCurrencyByID(code)
    elseif type == enums.CodeType.Achievement then
        tooltip:SetHyperlink(GetAchievementLink(code))
    else
        Logger.Log(Lockit.DEBUG_UNEXPECTED_ENUM_ELEMENT, tostring(enums.CodeType), type)
    end

    tooltip:Show()
end

---@param self CustomActionWidget
function DelveCompanionCustomActionWidgetMixin:OnLeave()
    GameTooltip:Hide()
end

--#region CustomActionWidgetXml annotations

---@class CustomActionWidgetXml : Frame
---@field Icon Texture
---@field CircleMask MaskTexture
---@field Label FontString
---@field ClickCatcher Button
---@field InsecureAction Button
--#endregion
