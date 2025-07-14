local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

--- A button representing a Delve in the Delves list.
---@class (exact) DelveInstanceButton : DelveInstanceButtonXml, DelveTrackingButton
---@field data DelveData?
DelveCompanion_DelveInstanceButtonMixin = CreateFromMixins(DelveCompanion_DelveTrackingButtonMixin)

---@param self DelveInstanceButton
---@param data DelveData
function DelveCompanion_DelveInstanceButtonMixin:Init(data)
    self.data = data

    self.DelveName:SetText(data.delveName)
    if C_Texture.GetAtlasInfo(data.config.atlasBgID) ~= nil then
        self.DelveArtBg:SetAtlas(data.config.atlasBgID)
    end
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:Update()
    self.BountifulIcon:SetShown(self.data.isBountiful)
    self.OverchargedIcon:SetShown(self.data.isOvercharged)
    if not DelveCompanion.Variables.hideForMainline then
        self.NotCompletedStoryIcon:SetShown(self.data.config.achievements and not self.data.isStoryCompleted)
    end

    if DelveCompanionAccountData.trackingType == DelveCompanion.Definitions.WaypointTrackingType.tomtom then
        self:CheckTomTomWaypoint()
    else
        self:OnSuperTrackChanged()
    end
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnEvent(event, ...)
    self:OnSuperTrackChanged()
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnShow()
    self:RegisterEvent("SUPER_TRACKING_CHANGED")
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnHide()
    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnEnter()
    if DelveCompanion.Variables.maxLevelReached == false then
        return
    end

    self:UpdateTooltip()
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnLeave()
    GameTooltip:Hide()
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnClick()
    if not DelveCompanion.Variables.maxLevelReached then
        return
    end

    if IsShiftKeyDown() then
        self:ToggleTracking()
    else
        -- EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.DELVE_INSTANCE_BUTTON_CLICK, self.data)
    end
end

--#region XML Annotations

--- `DelveCompanionDelveInstanceButtonTemplate`
---@class DelveInstanceButtonXml : Button
---@field DefaultBg Texture
---@field DelveArtBg Texture
---@field DelveName FontString
---@field BountifulIcon Texture
---@field OverchargedIcon Texture
---@field WaypointIcon Texture
---@field NotCompletedStoryIcon Texture
--#endregion
