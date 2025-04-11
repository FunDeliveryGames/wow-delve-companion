local addonName, addon = ...
local log = addon.log
local enums = addon.enums
local lockit = addon.lockit

--#region Constants

local TOM_TOM_WAYPOINT_DISTANCE_CLEAR = 10
--#endregion

DelveCompanionDelveTrackingButtonMixin = {}

function DelveCompanionDelveTrackingButtonMixin:PrepareTracking()
    self.isTracking = false

    local delveMap = C_Map.GetMapInfo(self.config.uiMapID)

    self.delveName = delveMap.name
    self.parentMapName = C_Map.GetMapInfo(delveMap.parentMapID).name
end

function DelveCompanionDelveTrackingButtonMixin:UpdateTooltip()
    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_TOP")
    tooltip:ClearLines()

    GameTooltip_AddNormalLine(tooltip, self.delveName, true)
    GameTooltip_AddHighlightLine(tooltip, self.parentMapName, true)
    GameTooltip_AddBlankLineToTooltip(tooltip)

    local text = lockit["ui-delve-instance-button-tooltip-click-instruction"]
    if self.isTracking then
        GameTooltip_AddHighlightLine(tooltip, lockit["ui-delve-instance-button-tooltip-current-text"], true)
        text = lockit["ui-delve-instance-button-tooltip-current-instruction"]
    end
    GameTooltip_AddInstructionLine(tooltip, text, true)

    tooltip:Show()
end

function DelveCompanionDelveTrackingButtonMixin:SetTracking()
    self.isTracking = true
    self.WaypointIcon:Show()
end

function DelveCompanionDelveTrackingButtonMixin:ClearTracking()
    self.isTracking = false
    self.WaypointIcon:Hide()
end

function DelveCompanionDelveTrackingButtonMixin:ClearTomTomWaypoint()
    TomTom:RemoveWaypoint(self.tomtom)
    self.tomtom = nil
    self:ClearTracking()
end

function DelveCompanionDelveTrackingButtonMixin:HandleTrackingClick()
    if self.isTracking then
        if DelveCompanionAccountData.useTomTomWaypoints and TomTom then
            self:ClearTomTomWaypoint()
        else
            C_SuperTrack.ClearSuperTrackedMapPin()
        end
    else
        if DelveCompanionAccountData.useTomTomWaypoints and TomTom then
            local mapInfo = C_Map.GetMapInfo(self.config.uiMapID)
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.parentMapID, self.poiID)

            local defaultCallbacks = TomTom:DefaultCallbacks({})
            defaultCallbacks.distance[TOM_TOM_WAYPOINT_DISTANCE_CLEAR] = function(...)
                self:ClearTomTomWaypoint()
            end

            self.tomtom = TomTom:AddWaypoint(mapInfo.parentMapID, poiInfo.position.x, poiInfo.position.y, {
                title = self.delveName,
                from = lockit["ui-addon-name"],
                persistent = false,
                callbacks = defaultCallbacks
            })
            self:SetTracking()
        else
            C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, self.poiID)
        end
    end
    self:UpdateTooltip()
end

function DelveCompanionDelveTrackingButtonMixin:CheckTomTomWaypoint()
    if TomTom and self.tomtom and TomTom:IsValidWaypoint(self.tomtom) then
        self:SetTracking()
    else
        self:ClearTomTomWaypoint()
    end
end

function DelveCompanionDelveTrackingButtonMixin:OnSuperTrackChanged()
    if C_SuperTrack.IsSuperTrackingAnything() then
        local type, typeID = C_SuperTrack.GetSuperTrackedMapPin()
        if type == Enum.SuperTrackingMapPinType.AreaPOI and typeID == self.poiID then
            self:SetTracking()
        else
            self:ClearTracking()
        end
    else
        self:ClearTracking()
    end
end
