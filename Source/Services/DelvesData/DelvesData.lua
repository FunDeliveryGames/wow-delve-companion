local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Definitions
local Definitions = DelveCompanion.Definitions

local LRT = LibStub("LibResetTracker-1.0")

--#region Constants

---@type number Refresh requests arriving within this window are merged into one refresh.
local COALESCE_DELAY_SEC = 0.5

---@type number[] Delays after a reset before refreshing. Server data updates a little after the reset itself.
local RESET_REFRESH_DELAYS_SEC = { 5, 60 }

---@type string
local COMBAT_END_EVENT = "PLAYER_REGEN_ENABLED"

---@type table<string, string> LibResetTracker callback event per period.
local RESET_EVENTS = {
    [LRT.Period.Daily] = "OnDailyReset",
    [LRT.Period.Weekly] = "OnWeeklyReset"
}
--#endregion

--#region Annotations

--- A zone (parent map) and the Delves located in it.
---@class (exact) DelvesZone
---@field mapID number Zone uiMapID.
---@field name string Localized zone name.
---@field delves DelveRecord[] Delves of the zone, in Config order.

--- Summary of a refresh, passed with `Definitions.Events.DELVES_DATA.UPDATED`. Shared between listeners: do not modify.
---@class (exact) DelvesDataChanges
---@field reason string Comma-separated reasons of the refresh (game events, `login`, `reset:Daily`, ...).
---@field delves table<number, boolean> uiMapIDs of the Delves with at least one changed field.
---@field fields table<string, boolean> Names of the changed fields.

--- Selects what to refresh. `nil` fields mean "all".
---@class (exact) DelvesDataFilter
---@field providers string[]? Provider names.
---@field records DelveRecord[]? Records.

--- A provider owns a set of DelveRecord fields and keeps them up to date.
--- Providers run in registration order and may read (never write) fields of providers registered before them.
---@class DelvesDataProvider
---@field name string Unique provider name.
---@field fields string[] Record fields this provider writes. Each field has exactly one owner.
---@field events string[]? Game events that trigger a refresh of this provider.
---@field resets string[]? LibResetTracker periods (`Daily`, `Weekly`) that trigger a refresh.
---@field InitRecord fun(self: DelvesDataProvider, record: DelveRecord)? Sets initial field values. Runs once per record, without change tracking.
---@field FilterEvent (fun(self: DelvesDataProvider, svc: DelvesData, event: string, ...: any): boolean|DelveRecord[]|nil)? `true` refreshes all records, a list refreshes only those, falsy skips the event. All records if omitted.
---@field Refresh fun(self: DelvesDataProvider, svc: DelvesData, ctx: DelvesDataContext, records: DelveRecord[]) Reads game data and writes fields via `ctx:Set`.
--#endregion

--- Single owner of all Delves runtime data.
---
--- - Consumers read [DelveRecord](lua://DelveRecord)s through the accessors below and never modify them.
--- - Data is refreshed by game events, daily resets (LibResetTracker) and explicit requests.
--- - `Definitions.Events.DELVES_DATA.UPDATED` (EventRegistry) fires after a refresh that changed something.
--- - New kinds of data are added with `RegisterProvider`, without touching consumers.
---@class DelvesData
---@field Record table Record builder. Defined in DelveRecord.lua.
local DelvesData = {}
DelveCompanion.DelvesData = DelvesData

--- Read-only empty list returned for unknown keys.
local EMPTY = setmetatable({}, {
    __newindex = function()
        error("DelvesData: lists returned by DelvesData are read-only.", 2)
    end
})

--#region State

local isInitialized = false

---@type DelveRecord[] All records: expansions ascending, then Config order.
local allRecords = {}
---@type table<number, DelveRecord>
local byID = {}
---@type table<number, DelveRecord[]>
local byExpansion = {}
---@type table<number, DelvesZone[]>
local zones = {}
---@type table<string, DelveRecord>
local byName = {}
---@type table<DelveRecord, string>
local normalizedNames = {}
---@type table<number, DelveRecord>
local byPoi = {}
---@type table<number, DelveRecord>
local byStoryAchievement = {}
---@type number[]
local parentMaps = {}
---@type number[]
local expansions = {}

---@type DelvesDataProvider[]
local providers = {}
---@type table<string, string> Field name -> owning provider name.
local fieldOwners = {}
---@type table<string, DelvesDataProvider[]>
local eventProviders = {}
---@type table<string, string[]> Reset period -> provider names.
local resetProviders = {}

local pendingWork = nil
local flushTimer = nil
local isWaitingForCombatEnd = false
---@type number? `GetTime()` of the last refresh that covered all providers and all records.
local lastFullRefreshTime = nil
---@type Frame
local eventFrame = nil
--#endregion

--#region Helpers

--- Normalize a name for comparisons: strip color codes, collapse spaces, trim, lowercase.
---@param text string?
---@return string?
local function Normalize(text)
    if type(text) ~= "string" then
        return nil
    end
    if issecretvalue and issecretvalue(text) then
        return nil
    end

    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]*:", ""):gsub("|r", ""):gsub("%s+", " ")
    text = strtrim(text)
    if text == "" then
        return nil
    end

    return string.lower(text)
end
--#endregion

--#region Indexes

local function AddRecord(record, parentMapSet)
    allRecords[#allRecords + 1] = record
    byID[record.id] = record

    local name = Normalize(record.delveName)
    if name then
        normalizedNames[record] = name
        if byName[name] == nil then
            byName[name] = record
        else
            Logger:Log("[DelvesData] Duplicate Delve name: %s", record.delveName)
        end
    end

    for _, poiID in pairs(record.config.poiIDs) do
        byPoi[poiID] = record
    end

    local storyAchievement = record.config.achievements and record.config.achievements.story
    if storyAchievement then
        byStoryAchievement[storyAchievement] = record
    end

    local parentMapID = record.parentMapID
    if parentMapID and not parentMapSet[parentMapID] then
        parentMapSet[parentMapID] = true
        parentMaps[#parentMaps + 1] = parentMapID
    end
end

local function BuildIndexes()
    for expansion in pairs(Config.DELVES_CONFIG) do
        expansions[#expansions + 1] = expansion
    end
    table.sort(expansions)

    local parentMapSet = {}
    for _, expansion in ipairs(expansions) do
        ---@type DelveRecord[]
        local list = {}

        for _, delveConfig in ipairs(Config.DELVES_CONFIG[expansion]) do
            local record = DelvesData.Record.Build(delveConfig, expansion)
            if record then
                list[#list + 1] = record
                AddRecord(record, parentMapSet)
            else
                Logger:Log("[DelvesData] Map info is unavailable for uiMapID %s.", tostring(delveConfig.uiMapID))
            end
        end
        byExpansion[expansion] = list

        ---@type DelvesZone[]
        local zoneList = {}
        for _, zoneMapID in ipairs(Config.DELVE_MAPS[expansion] or EMPTY) do
            local zoneInfo = C_Map.GetMapInfo(zoneMapID)
            ---@type DelvesZone
            local zone = {
                mapID = zoneMapID,
                name = zoneInfo and zoneInfo.name or "",
                delves = {}
            }

            for _, record in ipairs(list) do
                if record.parentMapID == zoneMapID then
                    zone.delves[#zone.delves + 1] = record
                end
            end

            zoneList[#zoneList + 1] = zone
        end
        zones[expansion] = zoneList
    end
end
--#endregion

--#region Refresh

--- Passed to `provider:Refresh`. The only way to write record fields.
---@class DelvesDataContext
---@field providerName string? Provider currently running.
---@field changes DelvesDataChanges
---@field hasChanges boolean
local ContextMixin = {}
local ContextMeta = { __index = ContextMixin }

--- Write a field of a record. Records the change if the value differs.
---@param self DelvesDataContext
---@param record DelveRecord
---@param field string Must be owned by the running provider.
---@param value any
function ContextMixin:Set(record, field, value)
    if fieldOwners[field] ~= self.providerName then
        error(("[DelvesData] Provider %q cannot write field %q."):format(tostring(self.providerName), tostring(field)), 2)
    end

    if record[field] ~= value then
        record[field] = value
        self.changes.delves[record.id] = true
        self.changes.fields[field] = true
        self.hasChanges = true
    end
end

--- Work = which providers to run, and for which records (`true` = all records).
local function NewWork()
    return {
        reasons = {},
        ---@type table<string, true|table<number, DelveRecord>>
        targets = {}
    }
end

---@param filter DelvesDataFilter?
local function AddToWork(work, reason, filter)
    if not tContains(work.reasons, reason) then
        work.reasons[#work.reasons + 1] = reason
    end

    local names = filter and filter.providers
    local records = filter and filter.records

    for _, provider in ipairs(providers) do
        if names == nil or tContains(names, provider.name) then
            local target = work.targets[provider.name]

            if records == nil then
                work.targets[provider.name] = true
            elseif target ~= true then
                target = target or {}
                for _, record in ipairs(records) do
                    target[record.id] = record
                end
                work.targets[provider.name] = target
            end
        end
    end
end

--- Records of a work target, in `allRecords` order.
local function CollectRecords(target)
    if target == true then
        return allRecords
    end

    local list = {}
    for _, record in ipairs(allRecords) do
        if target[record.id] then
            list[#list + 1] = record
        end
    end

    return list
end

local function Run(work)
    ---@type DelvesDataContext
    local ctx = setmetatable({
        providerName = nil,
        changes = {
            reason = table.concat(work.reasons, ","),
            delves = {},
            fields = {}
        },
        hasChanges = false
    }, ContextMeta)

    local isFull = #providers > 0
    for _, provider in ipairs(providers) do
        local target = work.targets[provider.name]
        if target ~= true then
            isFull = false
        end

        if target ~= nil then
            local records = CollectRecords(target)
            if #records > 0 then
                ctx.providerName = provider.name
                -- One faulty provider must not break the others.
                local ok, err = pcall(provider.Refresh, provider, DelvesData, ctx, records)
                if not ok then
                    geterrorhandler()(err)
                end
            end
        end
    end
    ctx.providerName = nil

    if isFull then
        lastFullRefreshTime = GetTime()
    end

    if ctx.hasChanges then
        Logger:Log("[DelvesData] Refresh (%s): %d Delve(s) changed.", ctx.changes.reason,
            table.count(ctx.changes.delves))

        EventRegistry:TriggerEvent(Definitions.Events.DELVES_DATA.UPDATED, ctx.changes)
    end
end

local function WaitForCombatEnd()
    if isWaitingForCombatEnd then
        return
    end

    isWaitingForCombatEnd = true
    eventFrame:RegisterEvent(COMBAT_END_EVENT)
end

local function Flush()
    flushTimer = nil
    if pendingWork == nil then
        return
    end

    -- Delves data doesn't change during combat, and Midnight APIs may return secret values there.
    if InCombatLockdown() then
        WaitForCombatEnd()
        return
    end

    local work = pendingWork
    pendingWork = nil
    Run(work)
end
--#endregion

--#region Triggers

local function OnEvent(_, event, ...)
    if event == COMBAT_END_EVENT and isWaitingForCombatEnd then
        isWaitingForCombatEnd = false
        if not eventProviders[COMBAT_END_EVENT] then
            eventFrame:UnregisterEvent(COMBAT_END_EVENT)
        end
        Flush()
    end

    local listeners = eventProviders[event]
    if not listeners then
        return
    end

    for _, provider in ipairs(listeners) do
        local target = true
        if provider.FilterEvent then
            target = provider:FilterEvent(DelvesData, event, ...)
        end

        if target == true then
            DelvesData:RequestRefresh(event, { providers = { provider.name } })
        elseif type(target) == "table" and #target > 0 then
            DelvesData:RequestRefresh(event, { providers = { provider.name }, records = target })
        end
    end
end

---@param provider DelvesDataProvider
local function InitProviderRecords(provider)
    if not provider.InitRecord then
        return
    end

    for _, record in ipairs(allRecords) do
        local ok, err = pcall(provider.InitRecord, provider, record)
        if not ok then
            geterrorhandler()(err)
        end
    end
end

---@param provider DelvesDataProvider
local function RegisterProviderTriggers(provider)
    for _, event in ipairs(provider.events or EMPTY) do
        local listeners = eventProviders[event]
        if not listeners then
            listeners = {}
            eventProviders[event] = listeners
            eventFrame:RegisterEvent(event)
        end
        listeners[#listeners + 1] = provider
    end

    for _, period in ipairs(provider.resets or EMPTY) do
        local names = resetProviders[period]
        if not names then
            names = {}
            resetProviders[period] = names

            LRT.RegisterCallback(DelvesData, RESET_EVENTS[period], function()
                DelvesData:HandleReset(period)
            end)
        end
        names[#names + 1] = provider.name
    end
end
--#endregion

--#region Lifecycle

--- Build records and indexes, subscribe to triggers, and run the first refresh. Call once at `PLAYER_LOGIN`.
---@param self DelvesData
function DelvesData:Init()
    if isInitialized then
        return
    end

    eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", OnEvent)

    BuildIndexes()
    for _, provider in ipairs(providers) do
        InitProviderRecords(provider)
        RegisterProviderTriggers(provider)
    end

    isInitialized = true
    self:RefreshNow("login")
end

---@param self DelvesData
---@return boolean
function DelvesData:IsInitialized()
    return isInitialized
end

--- Register a data provider. Providers registered after `Init` are initialized and refreshed right away.
---@param self DelvesData
---@param provider DelvesDataProvider
function DelvesData:RegisterProvider(provider)
    if type(provider) ~= "table" or type(provider.name) ~= "string" or type(provider.Refresh) ~= "function" then
        error("[DelvesData] RegisterProvider: provider must have `name` and `Refresh`.", 2)
    end

    for _, existing in ipairs(providers) do
        if existing.name == provider.name then
            error(("[DelvesData] Provider %q is already registered."):format(provider.name), 2)
        end
    end

    for _, field in ipairs(provider.fields or EMPTY) do
        if self.Record.STATIC_FIELDS[field] then
            error(("[DelvesData] Field %q is static and cannot be owned by a provider."):format(field), 2)
        end
        if fieldOwners[field] then
            error(("[DelvesData] Field %q is already owned by provider %q."):format(field, fieldOwners[field]), 2)
        end
    end

    for _, period in ipairs(provider.resets or EMPTY) do
        if not RESET_EVENTS[period] then
            error(("[DelvesData] unknown reset period %q."):format(tostring(period)), 2)
        end
    end

    for _, field in ipairs(provider.fields or EMPTY) do
        fieldOwners[field] = provider.name
    end
    providers[#providers + 1] = provider

    if isInitialized then
        InitProviderRecords(provider)
        RegisterProviderTriggers(provider)
        self:RequestRefresh("provider:" .. provider.name, { providers = { provider.name } })
    end
end

--#endregion

--#region Refresh API

--- Request a refresh. Requests within `COALESCE_DELAY_SEC` are merged. During combat the refresh waits until combat ends.
---@param self DelvesData
---@param reason string? Shown in logs and in `DelvesDataChanges.reason`.
---@param filter DelvesDataFilter?
function DelvesData:RequestRefresh(reason, filter)
    if not isInitialized then
        return
    end

    pendingWork = pendingWork or NewWork()
    AddToWork(pendingWork, reason or "request", filter)

    if flushTimer == nil and not isWaitingForCombatEnd then
        flushTimer = C_Timer.NewTimer(COALESCE_DELAY_SEC, Flush)
    end
end

--- Refresh immediately. During combat it falls back to `RequestRefresh`.
---@param self DelvesData
---@param reason string?
---@param filter DelvesDataFilter?
---@return boolean refreshed `false` if postponed (combat) or not initialized.
function DelvesData:RefreshNow(reason, filter)
    if not isInitialized then
        return false
    end

    if InCombatLockdown() then
        self:RequestRefresh(reason, filter)
        return false
    end

    local work = NewWork()
    AddToWork(work, reason or "now", filter)
    Run(work)

    return true
end

--- Refresh immediately unless a full refresh happened within `maxAgeSec`. A safety net for views that open rarely.
---@param self DelvesData
---@param maxAgeSec number
---@return boolean refreshed
function DelvesData:EnsureFresh(maxAgeSec)
    if lastFullRefreshTime and GetTime() - lastFullRefreshTime <= maxAgeSec then
        return false
    end

    return self:RefreshNow("ensure-fresh")
end

--- Schedule refreshes of providers subscribed to the reset period. Called by LibResetTracker; can be called manually for debugging.
---@param self DelvesData
---@param periodName string A value of `LibResetTracker.Period`.
function DelvesData:HandleReset(periodName)
    local names = resetProviders[periodName]
    if not names then
        return
    end

    local reason = "reset:" .. periodName
    for _, delay in ipairs(RESET_REFRESH_DELAYS_SEC) do
        C_Timer.After(delay, function()
            DelvesData:RequestRefresh(reason, { providers = names })
        end)
    end
end

--#endregion

--#region Read API (returned records and lists are read-only)

---@param self DelvesData
---@param mapID number Delve uiMapID.
---@return DelveRecord?
function DelvesData:Get(mapID)
    return byID[mapID]
end

---@param self DelvesData
---@param poiID number Regular or Bountiful areaPoiID of a Delve.
---@return DelveRecord?
function DelvesData:GetByPoi(poiID)
    return byPoi[poiID]
end

---@param self DelvesData
---@param achievementID number Story achievement ID.
---@return DelveRecord?
function DelvesData:GetByStoryAchievement(achievementID)
    return byStoryAchievement[achievementID]
end

--- Find the Delve whose name appears in a UI text (e.g. the Delve entrance header). Plain text matching, no Lua patterns.
--- Exact (normalized) match first, otherwise the longest Delve name contained in the text.
---@param self DelvesData
---@param text string?
---@return DelveRecord?
function DelvesData:FindByEntranceName(text)
    local normalized = Normalize(text)
    if not normalized then
        return nil
    end

    local exact = byName[normalized]
    if exact then
        return exact
    end

    local best, bestLength = nil, 0
    for _, record in ipairs(allRecords) do
        local name = normalizedNames[record]
        if name and #name > bestLength and string.find(normalized, name, 1, true) then
            best, bestLength = record, #name
        end
    end

    return best
end

--- LE_EXPANSIONs that have Delves, ascending.
---@param self DelvesData
---@return number[]
function DelvesData:GetExpansions()
    return expansions
end

--- Delves of the expansion, in Config order.
---@param self DelvesData
---@param expansion number LE_EXPANSION.
---@return DelveRecord[]
function DelvesData:GetDelves(expansion)
    return byExpansion[expansion] or EMPTY
end

--- Zones of the expansion with their Delves, in `Config.DELVE_MAPS` order.
---@param self DelvesData
---@param expansion number LE_EXPANSION.
---@return DelvesZone[]
function DelvesData:GetZones(expansion)
    return zones[expansion] or EMPTY
end

--- Bountiful Delves of the expansion, in Config order. Returns a new list.
---@param self DelvesData
---@param expansion number LE_EXPANSION.
---@return DelveRecord[]
function DelvesData:GetBountiful(expansion)
    local list = {}
    for _, record in ipairs(byExpansion[expansion] or EMPTY) do
        if record.isBountiful then
            list[#list + 1] = record
        end
    end

    return list
end

--- Iterate all records (expansions ascending, then Config order).
---@param self DelvesData
---@return fun(): DelveRecord?
function DelvesData:IterateAll()
    local index = 0
    return function()
        index = index + 1
        return allRecords[index]
    end
end

--- Unique zone uiMapIDs that contain Delves.
---@param self DelvesData
---@return number[]
function DelvesData:GetParentMaps()
    return parentMaps
end

--- `GetTime()` of the last refresh that covered all data. `nil` before the first one.
---@param self DelvesData
---@return number?
function DelvesData:GetLastUpdate()
    return lastFullRefreshTime
end

--#endregion
