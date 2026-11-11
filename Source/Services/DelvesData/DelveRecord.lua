local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Definitions
local Definitions = DelveCompanion.Definitions

--- Runtime data of a single Delve, owned by [DelvesData](lua://DelvesData).
--- One record per Delve, created once at startup and never replaced, so references stay valid.
--- **Read-only for consumers.** Static fields are set here; the other fields are written only by DelvesData providers.
---@class (exact) DelveRecord
---@field id number Delve [uiMapID](https://warcraft.wiki.gg/wiki/UiMapID). Unique key.
---@field expansion number LE_EXPANSION the Delve belongs to.
---@field kind number A value of [DelveKind](lua://DelveKind).
---@field config DelveConfig [DelveConfig](lua://DelveConfig) of the Delve.
---@field delveName string Localized name of the Delve.
---@field parentMapID number? uiMapID of the zone the Delve is located in.
---@field parentMapName string Localized name of that zone.
---@field levelRequired number Level required to enter. Only meaningful for Nemesis Delves (level-gated); `0` otherwise.
---@field poiID number Active [areaPoiID](https://wago.tools/db2/areapoi): the Bountiful one while the Delve is Bountiful. Owner: PoiProvider.
---@field isBountiful boolean Whether the Delve is Bountiful now. Owner: PoiProvider.
---@field storyVariant string? Localized label of the active Story Variant. `nil` if unknown. Owner: StoryProvider.
---@field storyStatus number A value of [DelveStoryStatus](lua://DelveStoryStatus). Owner: StoryProvider.

---@class DelveRecordBuilder
local Record = {}
DelveCompanion.DelvesData.Record = Record

--- Fields set by `Build`. Providers cannot own them.
---@type table<string, boolean>
Record.STATIC_FIELDS = {
    id = true,
    expansion = true,
    kind = true,
    config = true,
    delveName = true,
    parentMapID = true,
    parentMapName = true,
    levelRequired = true
}

---@param delveConfig DelveConfig
---@return number kind A value of DelveKind.
local function GetKind(delveConfig)
    local kinds = Definitions.DelveKind

    if delveConfig.nemesisInfo then
        return kinds.Nemesis
    end
    if delveConfig.labyrinthInfo then
        return kinds.Labyrinth
    end

    return kinds.Regular
end

--- Build a record with its static fields. Provider fields are set later by `provider:InitRecord`.
---@param delveConfig DelveConfig
---@param expansion number LE_EXPANSION.
---@return DelveRecord|nil # `nil` if the client has no map info for the Delve.
function Record.Build(delveConfig, expansion)
    local mapInfo = C_Map.GetMapInfo(delveConfig.uiMapID)
    if not mapInfo then
        return nil
    end

    ---@type number?
    local parentMapID = mapInfo.parentMapID
    if parentMapID == 0 then
        parentMapID = nil
    end
    local parentInfo = parentMapID and C_Map.GetMapInfo(parentMapID)
    local kind = GetKind(delveConfig)

    -- Provider fields are added by `provider:InitRecord`.
    ---@type DelveRecord
    ---@diagnostic disable-next-line: missing-fields
    local record = {
        id = delveConfig.uiMapID,
        expansion = expansion,
        kind = kind,
        config = delveConfig,
        delveName = mapInfo.name,
        parentMapID = parentMapID,
        parentMapName = parentInfo and parentInfo.name or "",
        levelRequired = kind == Definitions.DelveKind.Nemesis and GetMaxLevelForExpansionLevel(expansion) or 0
    }

    return record
end
