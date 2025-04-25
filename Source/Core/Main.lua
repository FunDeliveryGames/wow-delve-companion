local addonName, AddonTbl = ...

--- Addon master-table containing all functions and variables it uses.
---@class DelveCompanion
---@field Logger Logger
---@field Config Config
---@field Lockit Lockit
---@field Enums Enums
---@field Variables Variables
---@field AddonSettings AddonSettings
---@field DelvesList DelvesList
local DelveCompanion = {}
AddonTbl.DelveCompanion = DelveCompanion

--- Init Delves runtime data.
---@param self DelveCompanion
---@return nil
function DelveCompanion:InitDelvesData()
    ---@type DelveData[]
    local delvesData = {}

    for _, delveConfig in ipairs(self.Config.DELVES_CONFIG) do
        local delveMap = C_Map.GetMapInfo(delveConfig.uiMapID)

        --- Shared table containing runtime Delve data.
        ---@class (exact) DelveData
        ---@field config DelveConfig [DelveConfig](lua://DelveConfig) table associated with this Delve.
        ---@field poiID number? Current [areaPoiID](https://wago.tools/db2/areapoi) of this Delve.
        ---@field tomtom any? Reference to TomTom waypoint set for the Delve. `nil` if not set.
        ---@field delveName string Localized name of the Delve.
        ---@field parentMapName string Localized name of the map this Delve located in.
        ---@field isTracking boolean Whether player is tracking this Delve.
        ---@field isBountiful boolean Whether this Delve is bountiful now.
        local data = {
            config = delveConfig,
            poiID = nil,
            tomtom = nil,
            delveName = delveMap.name,
            parentMapName = C_Map.GetMapInfo(delveMap.parentMapID).name,
            isTracking = false,
            isBountiful = false
        }

        table.insert(delvesData, data)
    end

    self.Variables.delvesData = delvesData
end

--- Iterate through all Delves and update their runtime data.
---@param self DelveCompanion
---@return nil
function DelveCompanion:UpdateDelvesData()
    -- Logger.Log("Start updating Delves data...")
    for _, delveData in ipairs(self.Variables.delvesData) do
        local delveConfig = delveData.config
        local parentMapID = C_Map.GetMapInfo(delveConfig.uiMapID).parentMapID
        local poiIDs = delveConfig.poiIDs

        if poiIDs.bountiful and C_AreaPoiInfo.GetAreaPOIInfo(parentMapID, poiIDs.bountiful) then
            delveData.poiID = poiIDs.bountiful
            delveData.isBountiful = true
        else
            delveData.poiID = poiIDs.regular
            delveData.isBountiful = false
        end
    end
    -- Logger.Log("Finished updating Delves data")
end

--- Cache number of [Restored Coffer Keys](https://www.wowhead.com/currency=3028/restored-coffer-key) player has got from Caches this week.
---@param self DelveCompanion
---@return nil
function DelveCompanion:CacheKeysCount()
    local keysCollected = 0
    for _, questId in ipairs(self.Config.BOUNTIFUL_KEY_QUESTS_DATA) do
        if C_QuestLog.IsQuestFlaggedCompleted(questId) then
            keysCollected = keysCollected + 1
        end
    end

    self.Variables.keysCollected = keysCollected
end

--- Tries to retrieve `uiMapID` of the parent map with `Enum.UIMapType.Continent` for the given [uiMapID](https://warcraft.wiki.gg/wiki/UiMapID).
---@param self DelveCompanion
---@param mapID number [uiMapID](https://warcraft.wiki.gg/wiki/UiMapID) for which the Continent is retrieved.
---@return number|nil # Retrieved `uiMapID` of the Continent or `nil` otherwise.
function DelveCompanion:GetContinentMapIDForMap(mapID)
    if not mapID then
        return nil
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    while mapInfo and mapInfo.mapType ~= Enum.UIMapType.Continent do
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end

    if mapInfo then
        return mapInfo.mapID
    end

    return nil
end

--- Init [SavedVariables](https://warcraft.wiki.gg/wiki/TOC_format#SavedVariables) if they're not available (e.g. the 1st addon load).
---@param self DelveCompanion
---@return nil
function DelveCompanion:InitAccountSave()
    --- Account Save Data
    ---@class (exact) DelveCompanionAccountData
    ---@field achievementWidgetsEnabled boolean
    ---@field useTomTomWaypoints boolean
    DelveCompanionAccountData = {
        achievementWidgetsEnabled = true,
        useTomTomWaypoints = false
    }
end

--- Init [SavedVariablesPerCharacter](https://warcraft.wiki.gg/wiki/TOC_format#SavedVariablesPerCharacter) if they're not available (e.g. the 1st addon load).
---@param self DelveCompanion
---@return nil
function DelveCompanion:InitCharacterSave()
    --- Character Save Data
    ---@class (exact) DelveCompanionCharacterData
    ---@field gvDetailsEnabled boolean
    ---@field keysCapTooltipEnabled boolean
    ---@field dashOverviewEnabled boolean
    DelveCompanionCharacterData = {
        gvDetailsEnabled = true,
        keysCapTooltipEnabled = true,
        dashOverviewEnabled = true
    }
end

--#region Shared annotations

--- Utility class representing map coordinates.
---@class MapCoord
---@field x number X-coordinate on the map [0.0–100.0].
---@field y number Y-coordinate on the map [0.0–100.0].

--#endregion
