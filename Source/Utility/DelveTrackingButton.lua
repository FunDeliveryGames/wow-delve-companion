local addonName, addon = ...
local log = addon.log
local enums = addon.enums
local lockit = addon.lockit

--#region Constants

local TOM_TOM_WAYPOINT_DISTANCE_CLEAR = 10
--#endregion

DelveCompanionDelveTrackingButtonMixin = {}

function DelveCompanionDelveTrackingButtonMixin:UpdateTooltip()
    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_TOP")
    tooltip:ClearLines()

    GameTooltip_AddNormalLine(tooltip, self.data.delveName, true)
    GameTooltip_AddHighlightLine(tooltip, self.data.parentMapName, true)
    GameTooltip_AddBlankLineToTooltip(tooltip)

    local text = lockit["ui-delve-instance-button-tooltip-click-instruction"]
    if self.data.isTracking then
        GameTooltip_AddHighlightLine(tooltip, lockit["ui-delve-instance-button-tooltip-current-text"], true)
        text = lockit["ui-delve-instance-button-tooltip-current-instruction"]
    end
    GameTooltip_AddInstructionLine(tooltip, text, true)

    tooltip:Show()
end

function DelveCompanionDelveTrackingButtonMixin:SetTracking()
    self.data.isTracking = true
    self.WaypointIcon:Show()
end

function DelveCompanionDelveTrackingButtonMixin:ClearTracking()
    self.data.isTracking = false
    self.WaypointIcon:Hide()
end

function DelveCompanionDelveTrackingButtonMixin:ClearTomTomWaypoint()
    TomTom:RemoveWaypoint(self.data.tomtom)
    self.data.tomtom = nil
    self:ClearTracking()
end

function DelveCompanionDelveTrackingButtonMixin:ToggleTracking()
    local delveData = self.data
    if delveData.isTracking then
        if DelveCompanionAccountData.useTomTomWaypoints and TomTom then
            self:ClearTomTomWaypoint()
        else
            C_SuperTrack.ClearSuperTrackedMapPin()
        end
    else
        if DelveCompanionAccountData.useTomTomWaypoints and TomTom then
            local mapInfo = C_Map.GetMapInfo(delveData.config.uiMapID)
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.parentMapID, delveData.poiID)

            local callbacks = TomTom:DefaultCallbacks({})
            callbacks.distance[TOM_TOM_WAYPOINT_DISTANCE_CLEAR] = function(...)
                self:ClearTomTomWaypoint()
            end

            delveData.tomtom = TomTom:AddWaypoint(mapInfo.parentMapID, poiInfo.position.x, poiInfo.position.y, {
                title = delveData.delveName,
                from = lockit["ui-addon-name"],
                persistent = false,
                callbacks = callbacks
            })
            self:SetTracking()
        else
            C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, delveData.poiID)
        end
    end
    self:UpdateTooltip()
end

function DelveCompanionDelveTrackingButtonMixin:CheckTomTomWaypoint()
    local delveData = self.data
    if TomTom and delveData and delveData.tomtom and TomTom:IsValidWaypoint(delveData.tomtom) then
        self:SetTracking()
    else
        self:ClearTomTomWaypoint()
    end
end

function DelveCompanionDelveTrackingButtonMixin:OnSuperTrackChanged()
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
