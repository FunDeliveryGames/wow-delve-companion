local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

---@class (exact) OverviewBountifulButton : OverviewBountifulButtonXml, DelveTrackingButton
---@field data DelveData
DelveCompanion_OverviewBountifulButtonMixin = CreateFromMixins(DelveCompanion_DelveTrackingButtonMixin)

---@param self OverviewBountifulButton
function DelveCompanion_OverviewBountifulButtonMixin:OnLoad()
    -- Logger.Log("OverviewBountifulButton OnLoad start")
    -- NOTE: BountifulButton is acquired from a FramePool so OnLoad is called only once per button lifetime.
    -- Only one-time initializations here.
end

---@param self OverviewBountifulButton
---@param data DelveData
---@param index number
function DelveCompanion_OverviewBountifulButtonMixin:Init(data, index)
    ---@diagnostic disable-next-line: inject-field
    self.layoutIndex = index
    self.data = data
end

---@param self OverviewBountifulButton
function DelveCompanion_OverviewBountifulButtonMixin:Update()
    if DelveCompanion.Variables.tomTomAvailable and DelveCompanionAccountData.trackingType == DelveCompanion.Definitions.WaypointTrackingType.tomtom then
        self:CheckTomTomWaypoint()
    else
        self:OnSuperTrackChanged()
    end

    self.WaypointIcon:SetShown(self.data.isTracking)
end

---@param self OverviewBountifulButton
function DelveCompanion_OverviewBountifulButtonMixin:OnEvent(event, ...)
    self:Update()
end

---@param self OverviewBountifulButton
function DelveCompanion_OverviewBountifulButtonMixin:OnShow()
    -- Logger.Log("OverviewBountifulButton OnShow start")

    self:RegisterEvent("SUPER_TRACKING_CHANGED")

    ---@type number
    local achIcon = select(10, GetAchievementInfo(self.data.config.achievements.story))
    self.ArtBg:SetTexture(achIcon)

    self:Update()
end

---@param self OverviewBountifulButton
function DelveCompanion_OverviewBountifulButtonMixin:OnHide()
    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
end

---@param self OverviewBountifulButton
function DelveCompanion_OverviewBountifulButtonMixin:OnEnter()
    self:UpdateTooltip()
end

---@param self OverviewBountifulButton
function DelveCompanion_OverviewBountifulButtonMixin:OnLeave()
    GameTooltip:Hide()
end

---@param self OverviewBountifulButton
function DelveCompanion_OverviewBountifulButtonMixin:OnClick()
    if IsShiftKeyDown() then
        self:ToggleTracking()
    end
end

--#region XML Annotations

--- `DelveCompanionOverviewBountifulButtonTemplate`
---@class (exact) OverviewBountifulButtonXml : Button
---@field layoutIndex number
---@field Background Texture
---@field ArtBg Texture
---@field WaypointIcon Texture

--#endregion
