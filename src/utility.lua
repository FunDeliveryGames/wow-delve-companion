local addonName, addon = ...
local log = addon.log
local enums = addon.enums
local lockit = addon.lockit

--============ DelveCompanionIconWithTextAndTooltip ======================

DelveCompanionIconWithLabelAndTooltipMixin = {}

function DelveCompanionIconWithLabelAndTooltipMixin:SetLabelText(text)
    if text then
        self.Label:SetText(text)
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

    if self.useAutoScaling then
        Mixin(self.Label, AutoScalingFontStringMixin)
    end

    if self.useMask then
        self.CircleMask:SetPoint("TOPLEFT", self, "CENTER", self.maskSizeOffset, -self.maskSizeOffset);
        self.CircleMask:SetPoint("BOTTOMRIGHT", self, "CENTER", -self.maskSizeOffset, self.maskSizeOffset);
        self.CircleMask:Show()
        self.Icon:AddMaskTexture(self.CircleMask)
    end

    if self.labelRelPoint and self.labelPadding then
        self.Label:ClearAllPoints()
        local point = self.labelRelPoint


        -- local frame = CreateFrame("Frame")
        -- local str = frame:CreateFontString("test", "OVERLAY")
        -- str:SetFontObject("GameFontHighlightLarge")
        if point == "TOPLEFT" then
        elseif point == "TOPRIGHT" then
        elseif point == "BOTTOMLEFT" then
            self.Label:SetPoint("BOTTOMRIGHT", self.Icon, point, self.labelPadding, 0)
        elseif point == "BOTTOMRIGHT" then
        elseif point == "TOP" then
        elseif point == "BOTTOM" then
        elseif point == "LEFT" then
        elseif point == "RIGHT" then
        elseif point == "CENTER" then
        end
    else
        -- Set default anchor
        local relKey = self.useMask and self.CircleMask or self.Icon
        self.Label:ClearAllPoints()
        self.Label:SetPoint("RIGHT", relKey, "LEFT", -5, 0)
    end

    if self.fontOverride then
        self.Label:SetFontObject(self.fontOverride)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnShow()
    -- log("DelveCompanionIconWithTextAndTooltip OnShow start")

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
        _, _, _, _, _, _, _, _, _, texture = GetAchievementInfo(code)
    else
        log(lockit["ui-debug-unexpected-enum-element"], tostring(enums.CodeType), type)
    end

    if texture then
        self.Icon:SetTexture(texture)
    end
end

function DelveCompanionIconWithLabelAndTooltipMixin:OnHide()
    -- log("DelveCompanionIconWithTextAndTooltip OnHide start")
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
