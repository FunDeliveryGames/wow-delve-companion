local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

local TOM_TOM_WAYPOINT_DISTANCE_CLEAR = 10
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

    GameTooltip_AddNormalLine(tooltip, data.delveName, true)
    GameTooltip_AddHighlightLine(tooltip, data.parentMapName, true)
    GameTooltip_AddBlankLineToTooltip(tooltip)

    local text = Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION
    if data.isTracking then
        GameTooltip_AddHighlightLine(tooltip, Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT, true)
        text = Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION
    end
    GameTooltip_AddInstructionLine(tooltip, text, true)

    tooltip:Show()
end

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:SetTracking()
    self.data.isTracking = true
    self.WaypointIcon:Show()
end

---@param self DelveInstanceButton|OverviewBountifulButton
function DelveCompanion_DelveTrackingButtonMixin:ClearTracking()
    self.data.isTracking = false
    self.WaypointIcon:Hide()
end

---@param self DelveInstanceButton|OverviewBountifulButton
---@param delveData DelveData
function DelveCompanion_DelveTrackingButtonMixin:SetTomTomWaypoint(delveData)
    local mapInfo = C_Map.GetMapInfo(delveData.config.uiMapID)
    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.parentMapID, delveData.poiID)

    -- Blizzard removes Boss Delve POIs from Map with the season change. They can be entered but the API doesn't provide their POIInfo.
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

    if DelveCompanion.Variables.tomTomAvailable and DelveCompanionAccountData.trackingType == DelveCompanion.Enums.WaypointTrackingType.tomtom then
        if delveData.isTracking then
            self:ClearTomTomWaypoint()
        else
            self:SetTomTomWaypoint(delveData)
            self:SetTracking()
        end
    else
        if delveData.isTracking then
            C_SuperTrack.ClearSuperTrackedMapPin()
        else
            C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, delveData.poiID)
        end
    end
    self:UpdateTooltip()
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
