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

---@class (exact) DelveWaypointTracker
---@field isActive boolean Whether player has an active waypoint to a Delve.
---@field VerifyInput fun(self: DelveWaypointTracker) : boolean
---@field Update fun(data: DelveData)
---@field private SetState fun(self: DelveWaypointTracker, state: boolean)
---@field private Activate fun(data: DelveData)
---@field private Clear fun(data: DelveData)
DelveCompanion_DelveWaypointMixin = {}

--#region TomTom tracking

---@param tomtomWaypoint table
local function ClearTomTomWaypoint(tomtomWaypoint)
    if not DelveCompanion.Variables.tomTomAvailable then
        return
    end

    TomTom:RemoveWaypoint(tomtomWaypoint)
end

---@param delveData DelveData
local function SetTomTomWaypoint(delveData)
    if not DelveCompanion.Variables.tomTomAvailable then
        return
    end

    local mapInfo = C_Map.GetMapInfo(delveData.config.uiMapID)
    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.parentMapID, delveData.poiID)

    -- Blizzard removes Nemesis Delves' POI from Map with the season change. They can still be entered but their POIInfo cannot be retrieved from API.
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
        ClearTomTomWaypoint(delveData.tomtom)
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

---@param tomtomWaypoint table?
---@return boolean state -- Whether SuperTrack is active for a Delve
local function CheckTomTomWaypoint(tomtomWaypoint)
    if not DelveCompanion.Variables.tomTomAvailable or not tomtomWaypoint then
        return false
    end

    if TomTom:IsValidWaypoint(tomtomWaypoint) then
        return true
    else
        ClearTomTomWaypoint(tomtomWaypoint)
        return false
    end
end
--#endregion

--#region SuperTrack tracking

---@param poiID number -- Delve POI ID
---@return boolean -- Whether SuperTrack is active for a Delve
local function CheckSuperTrackPin(poiID)
    if C_SuperTrack.IsSuperTrackingAnything() then
        local type, typeID = C_SuperTrack.GetSuperTrackedMapPin()

        if type == Enum.SuperTrackingMapPinType.AreaPOI and typeID == poiID then
            return true
        else
            return false
        end
    else
        return false
    end
end
--#endregion

--- Set tracker methods depending on the selected [tracking type](lua://WaypointTrackingType).
---@param self DelveWaypointTracker
function DelveCompanion_DelveWaypointMixin:Prepare()
    self.Update = function(data)
        local state = false

        if DelveCompanionAccountData.trackingType == DelveCompanion.Definitions.WaypointTrackingType.tomtom then
            state = CheckTomTomWaypoint(data.tomtom)
            if state == false then
                data.tomtom = nil
            end
        else
            state = CheckSuperTrackPin(data.poiID)
        end

        self:SetState(state)
    end

    self.Activate = function(data)
        if DelveCompanionAccountData.trackingType == DelveCompanion.Definitions.WaypointTrackingType.tomtom then
            SetTomTomWaypoint(data)
        else
            C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, data.poiID)
        end

        self:SetState(true)
    end

    self.Clear = function(data)
        if DelveCompanionAccountData.trackingType == DelveCompanion.Definitions.WaypointTrackingType.tomtom then
            ClearTomTomWaypoint(data.tomtom)
        else
            C_SuperTrack.ClearSuperTrackedMapPin()
        end

        self:SetState(false)
    end
end

---@param self DelveWaypointTracker
---@param state boolean
function DelveCompanion_DelveWaypointMixin:SetState(state)
    self.isActive = state
end

---@param self DelveWaypointTracker
function DelveCompanion_DelveWaypointMixin:VerifyInput()
    return IsShiftKeyDown()
end

---@param self DelveWaypointTracker
---@param delveData DelveData
function DelveCompanion_DelveWaypointMixin:ToggleTracking(delveData)
    if not delveData then
        return
    end

    if self.isActive then
        self.Clear(delveData)
    else
        self.Activate(delveData)
    end
end

---@param self DelveWaypointTracker
---@param owner Frame
---@param anchor TooltipAnchor
---@param delveData DelveData
function DelveCompanion_DelveWaypointMixin:DisplayDelveTooltip(owner, anchor, delveData)
    if not delveData then
        return
    end

    local tooltip = GameTooltip
    tooltip:SetOwner(owner, anchor)
    tooltip:ClearLines()

    local iconsSequence = ""

    if delveData.isBountiful then
        iconsSequence = string.join("", iconsSequence, BOUNTIFUL_ICON_SEQUENCE)
    end

    if delveData.isOvercharged then
        iconsSequence = string.join("", iconsSequence, OVERCHARGED_ICON_SEQUENCE)
    end

    -- Title + icons
    GameTooltip_AddColoredDoubleLine(tooltip,
        delveData.delveName, iconsSequence,
        _G["NORMAL_FONT_COLOR"], _G["NORMAL_FONT_COLOR"],
        true)
    -- Parent map
    GameTooltip_AddHighlightLine(tooltip, delveData.parentMapName, true)
    -- Active story + completion state
    do
        if not DelveCompanion.Variables.hideForMainline and delveData.storyVariant then
            local completionText = delveData.isStoryCompleted and Lockit.UI_DELVE_STORY_VARIANT_COMPLETED_SEQUENCE or
                Lockit.UI_DELVE_STORY_VARIANT_NOT_COMPLETED_SEQUENCE
            local completionColor = delveData.isStoryCompleted and _G["DIM_GREEN_FONT_COLOR"]
                or _G["WARNING_FONT_COLOR"]
            GameTooltip_AddColoredDoubleLine(tooltip, delveData.storyVariant, completionText,
                _G["NORMAL_FONT_COLOR"], completionColor, true)
        end
    end

    GameTooltip_AddBlankLineToTooltip(tooltip)

    -- Tracking instruction
    do
        local line = Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION
        if self.isActive then
            GameTooltip_AddHighlightLine(tooltip, Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT, true)
            line = Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION
        end
        GameTooltip_AddInstructionLine(tooltip, line, true)
    end

    tooltip:Show()
end
