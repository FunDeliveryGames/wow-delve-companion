local addonName, DelveCompanion = ...
---@type Logger
local Logger = DelveCompanion.Logger
local enums = DelveCompanion.enums
local lockit = DelveCompanion.lockit

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

function DelveCompanionDelveTrackingButtonMixin:SetTomTomWaypoint(delveData)
    local mapInfo = C_Map.GetMapInfo(delveData.config.uiMapID)
    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.parentMapID, delveData.poiID)

    -- Blizzard removes Boss Delve POIs from Map with the season change. They can be entered but the API doesn't provide their POIInfo.
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
        from = lockit["ui-addon-name"],
        persistent = false,
        callbacks = callbacks
    }

    delveData.tomtom = TomTom:AddWaypoint(
        mapInfo.parentMapID,
        posX, posY,
        options)
end

function DelveCompanionDelveTrackingButtonMixin:ClearTomTomWaypoint()
    if not DelveCompanion.tomTomAvailable then
        return
    end

    TomTom:RemoveWaypoint(self.data.tomtom)
    self.data.tomtom = nil
    self:ClearTracking()
end

function DelveCompanionDelveTrackingButtonMixin:ToggleTracking()
    local delveData = self.data

    if not delveData then
        return
    end

    if DelveCompanion.tomTomAvailable and DelveCompanionAccountData.useTomTomWaypoints then
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

function DelveCompanionDelveTrackingButtonMixin:CheckTomTomWaypoint()
    if not DelveCompanion.tomTomAvailable then
        return
    end

    local delveData = self.data
    if delveData and delveData.tomtom and TomTom:IsValidWaypoint(delveData.tomtom) then
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
