local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

local TOM_TOM_WAYPOINT_DISTANCE_CLEAR = 10
local BOUNTIFUL_ICON_SEQUENCE = "|A:delves-bountiful:24:24|a"
local OVERCHARGED_ICON_SEQUENCE = "|TInterface\\Icons\\achievement_legionpvp2tier5:20|t"
--#endregion

---@class (exact) DelveTrackingButton
DelveCompanion_DelveTrackingButtonMixin = {}

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:UpdateTooltip()
    ---@type DelveData
    local data = self.data

    if not data then
        return
    end

    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_TOP")
    tooltip:ClearLines()

    local iconsSequence = ""

    if data.isBountiful then
        iconsSequence = string.join("", iconsSequence, BOUNTIFUL_ICON_SEQUENCE)
    end

    if data.isOvercharged then
        iconsSequence = string.join("", iconsSequence, OVERCHARGED_ICON_SEQUENCE)
    end

    -- Title + icons
    GameTooltip_AddColoredDoubleLine(tooltip,
        data.delveName, iconsSequence,
        _G["NORMAL_FONT_COLOR"], _G["NORMAL_FONT_COLOR"],
        true)
    -- Parent map
    GameTooltip_AddHighlightLine(tooltip, data.parentMapName, true)
    -- Active story + completion state
    do
        if not DelveCompanion.Variables.hideForMainline and data.storyVariant then
            local completionText = data.isStoryCompleted and Lockit.UI_DELVE_STORY_VARIANT_COMPLETED_SEQUENCE or
                Lockit.UI_DELVE_STORY_VARIANT_NOT_COMPLETED_SEQUENCE
            local completionColor = data.isStoryCompleted and _G["DIM_GREEN_FONT_COLOR"] or _G["WARNING_FONT_COLOR"]
            GameTooltip_AddColoredDoubleLine(tooltip, data.storyVariant, completionText,
                _G["NORMAL_FONT_COLOR"], completionColor, true)
        end
    end

    GameTooltip_AddBlankLineToTooltip(tooltip)

    -- Tracking instruction
    do
        local line = Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION
        if data.isTracking then
            GameTooltip_AddHighlightLine(tooltip, Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT, true)
            line = Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION
        end
        GameTooltip_AddInstructionLine(tooltip, line, true)
    end

    tooltip:Show()
end

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:SetTracking()
    self.data.isTracking = true
end

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:ClearTracking()
    self.data.isTracking = false
end

---@param self DelveInstanceButton|OverviewBountifulButton
---@param delveData DelveData
function DelveCompanion_DelveTrackingButtonMixin:SetTomTomWaypoint(delveData)
    local mapInfo = C_Map.GetMapInfo(delveData.config.uiMapID)
    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.parentMapID, delveData.poiID)

    -- Blizzard removes Nemesis Delves' POI from Map with the season change. Their POIInfo cannot be retrieved from API but they can still be entered.
    -- To set a waypoint, coordinates from the Config are used.
    local posX, posY = -1, -1
    if poiInfo then
        posX = poiInfo.position.x
        posY = poiInfo.position.y
    else
        posX = delveData.config.coordinates.x / 100
        posY = delveData.config.coordinates.y / 100
    end

    local callbacks = TomTom:DefaultCallbacks({})
    callbacks.distance[TOM_TOM_WAYPOINT_DISTANCE_CLEAR] = function(...)
        self:ClearTomTomWaypoint()
    end

    local options = {
        title = delveData.delveName,
        from = Lockit.UI_ADDON_NAME,
        persistent = false,
        callbacks = callbacks
    }

    delveData.tomtom = TomTom:AddWaypoint(
        mapInfo.parentMapID,
        posX, posY,
        options)

    self:SetTracking()
end

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:ClearTomTomWaypoint()
    if not DelveCompanion.Variables.tomTomAvailable then
        return
    end

    TomTom:RemoveWaypoint(self.data.tomtom)
    self.data.tomtom = nil
    self:ClearTracking()
end

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:ToggleTracking()
    ---@type DelveData
    local delveData = self.data

    if not delveData then
        return
    end

    if DelveCompanion.Variables.tomTomAvailable and DelveCompanionAccountData.trackingType == DelveCompanion.Definitions.WaypointTrackingType.tomtom then
        if delveData.isTracking then
            self:ClearTomTomWaypoint()
        else
            self:SetTomTomWaypoint(delveData)
        end
    else
        if delveData.isTracking then
            C_SuperTrack.ClearSuperTrackedMapPin()
        else
            C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, delveData.poiID)
        end
    end

    self:UpdateTooltip()
    self:Update()
end

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:CheckTomTomWaypoint()
    if not DelveCompanion.Variables.tomTomAvailable then
        return
    end

    local delveData = self.data
    if delveData and delveData.tomtom and TomTom:IsValidWaypoint(delveData.tomtom) then
        self:SetTracking()
    else
        self:ClearTomTomWaypoint()
    end
end

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:OnSuperTrackChanged()
    if C_SuperTrack.IsSuperTrackingAnything() then
        local type, typeID = C_SuperTrack.GetSuperTrackedMapPin()
        if type == Enum.SuperTrackingMapPinType.AreaPOI and typeID == self.data.poiID then
            self:SetTracking()
        else
            self:ClearTracking()
        end
    else
        self:ClearTracking()
    end
end
