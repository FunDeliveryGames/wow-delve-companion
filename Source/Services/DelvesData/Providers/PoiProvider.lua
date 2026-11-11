local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

--- Owns the active areaPoiID and the Bountiful state of each Delve.
--- A Delve is Bountiful while its Bountiful POI is among the active Delve POIs of its zone.
---@class PoiProvider : DelvesDataProvider
local PoiProvider = {
    name = "Poi",
    fields = { "poiID", "isBountiful" },
    events = { "AREA_POIS_UPDATED", "PLAYER_ENTERING_WORLD" },
    resets = { "Daily" }
}

---@param self DelvesDataProvider
---@param record DelveRecord
function PoiProvider:InitRecord(record)
    record.poiID = record.config.poiIDs.regular
    record.isBountiful = false
end

--- Set of active Delve POIs of a zone. `nil` if the data is unavailable.
---@param parentMapID number
---@return table<number, boolean>?
local function GetActivePois(parentMapID)
    local poiIDs = C_AreaPoiInfo.GetDelvesForMap(parentMapID)
    if type(poiIDs) ~= "table" or (issecrettable and issecrettable(poiIDs)) then
        return nil
    end

    local set = {}
    for _, poiID in ipairs(poiIDs) do
        set[poiID] = true
    end

    return set
end

---@param self DelvesDataProvider
---@param svc DelvesData
---@param ctx DelvesDataContext
---@param records DelveRecord[]
function PoiProvider:Refresh(svc, ctx, records)
    -- One API call per zone, not per Delve. `false` marks zones whose data is unavailable.
    ---@type table<number, table<number, boolean>|false>
    local activeByZone = {}

    for _, record in ipairs(records) do
        local parentMapID = record.parentMapID

        if parentMapID then
            local active = activeByZone[parentMapID]
            if active == nil then
                active = GetActivePois(parentMapID) or false
                activeByZone[parentMapID] = active
            end

            -- Unavailable data keeps the previous values instead of resetting them.
            if active then
                local poiIDs = record.config.poiIDs
                local isBountiful = poiIDs.bountiful ~= nil and active[poiIDs.bountiful] == true

                ctx:Set(record, "isBountiful", isBountiful)
                ctx:Set(record, "poiID", isBountiful and poiIDs.bountiful or poiIDs.regular)
            end
        end
    end
end

DelveCompanion.DelvesData:RegisterProvider(PoiProvider)
