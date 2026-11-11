local addonName, AddonTbl = ...

--- Addon master-table containing references to all components.
---@class (exact) DelveCompanion
---@field Logger Logger
---@field Config Config
---@field Lockit Lockit
---@field Definitions Definitions
---@field Variables Variables
---@field DelvesData DelvesData
---@field AddonSettings DelveCompanionSettings
---@field EJExtension EJExtension
---@field ProgressTracker ProgressTracker
---@field InDelveWidget InDelveWidget
---@field MinimapIcon DelveCompanionMinimapIcon
---@field GossipExtension GossipExtension
---@field UISkin UISkin
local DelveCompanion = {}
AddonTbl.DelveCompanion = DelveCompanion

--- Check whether information about `Gilded Stash` can be retrieved.
---@param self DelveCompanion
---@return boolean
function DelveCompanion:CanRetrieveDelveWidgetIDInfo(expansion)
    local currentMap = C_Map.GetBestMapForUnit("player")
    if not (currentMap and MapUtil.IsMapTypeZone(currentMap)) then
        return false
    end

    local continent = DelveCompanion:GetContinentMapIDForMap(currentMap)
    return continent ~= nil and continent == self.Config.DELVE_CONTINENTS[expansion]
end

--- Try to retrieve `uiMapID` of the parent map with `Enum.UIMapType.Continent` for the given [uiMapID](https://warcraft.wiki.gg/wiki/UiMapID).
---@param self DelveCompanion
---@param mapID number [uiMapID](https://warcraft.wiki.gg/wiki/UiMapID) for which the Continent is retrieved.
---@return number|nil # Retrieved `uiMapID` of the Continent, or `nil` otherwise.
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

---@param self DelveCompanion
---@return LootInfoFrame
function DelveCompanion:GetLootInfoFrame()
    if not DelveCompanion.Variables.LootInfoFrame then
        ---@type LootInfoFrame
        local lootInfoFrame = CreateFrame("Frame",
            "$parent.LootInfoFrame", UIParent,
            "DelveCompanionLootInfoFrameTemplate")
        DelveCompanion.UISkin:Apply("LootInfoFrame", lootInfoFrame)

        DelveCompanion.Variables.LootInfoFrame = lootInfoFrame
    end

    return DelveCompanion.Variables.LootInfoFrame
end

-- Helper function to get the highest Delve tier available.
---@param self DelveCompanion
function DelveCompanion:GetDelvesMaxTier()
    return #DelveCompanion.Config.DELVES_LOOT_INFO_DATA
end
