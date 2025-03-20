local addonName, addon = ...
local log = addon.log
local enums = addon.enums
local lockit = addon.lockit

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
        log(lockit["ui-debug-unexpected-enum-element"], tostring(enums.CodeType), type)
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
    -- log("DelveCompanionIconWithTextAndTooltip OnLoad start")
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
    -- log("DelveCompanionIconWithTextAndTooltip OnShow start")

    if self.atlasTexture then
        SetFromAtlas(self)
    else
        SetFromTexture(self)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnHide()
    -- log("DelveCompanionIconWithTextAndTooltip OnHide start")
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

    self.ReloadButton:SetText(format(_G["SETTINGS_SUBCATEGORY_FMT"], _G["SETTINGS_APPLY"], _G["RELOADUI"]))

    self:Hide()
end

--============ Delve Tracking Button ======================

DelveCompanionDelveTrackingButtonMixin = {}

function DelveCompanionDelveTrackingButtonMixin:SetTracking()
    self.isTracking = true
    self.WaypointIcon:Show()
end

function DelveCompanionDelveTrackingButtonMixin:ClearTracking()
    self.isTracking = false
    self.WaypointIcon:Hide()
end

function DelveCompanionDelveTrackingButtonMixin:OnSuperTrackChanged()
    if not C_SuperTrack.IsSuperTrackingAnything() then
        self:ClearTracking()
    end

    local type, typeID = C_SuperTrack.GetSuperTrackedMapPin()
    if type ~= Enum.SuperTrackingMapPinType.AreaPOI then
        self:ClearTracking()
    elseif typeID ~= self.poiID then
        self:ClearTracking()
    else
        self:SetTracking()
    end
end
