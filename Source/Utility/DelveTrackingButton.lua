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
    if not addon.tomTomAvailable then
        return
    end

    TomTom:RemoveWaypoint(self.data.tomtom)
    self.data.tomtom = nil
    self:ClearTracking()
end

function DelveCompanionDelveTrackingButtonMixin:ToggleTracking()
    local delveData = self.data
    if delveData.isTracking then
        if addon.tomTomAvailable and DelveCompanionAccountData.useTomTomWaypoints then
            self:ClearTomTomWaypoint()
        else
            C_SuperTrack.ClearSuperTrackedMapPin()
        end
    else
        if addon.tomTomAvailable and DelveCompanionAccountData.useTomTomWaypoints then
            local mapInfo = C_Map.GetMapInfo(delveData.config.uiMapID)
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.parentMapID, delveData.poiID)

            -- Blizzard removes Boss Delve POIs from Map with the season change. They're still can be entered but the API doesn't provide their coordinates.
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
            self:SetTracking()
        else
            C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, delveData.poiID)
        end
    end
    self:UpdateTooltip()
end

function DelveCompanionDelveTrackingButtonMixin:CheckTomTomWaypoint()
    if not addon.tomTomAvailable then
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
