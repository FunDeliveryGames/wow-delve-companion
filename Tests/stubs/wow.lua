---@diagnostic disable: undefined-global, inject-field
--- WoW API stubs for offline tests (Lua 5.2+).
---
--- Every test creates a fresh harness: a separate global environment with a fake clock and a fake game world,
--- so addon files are loaded from scratch and tests can't affect each other.

local Harness = {}

--- Repository root, set by run.lua.
Harness.root = "."

--- 2026-01-01 00:00:00 UTC. A multiple of a day, so reset times are easy to reason about.
Harness.BASE_EPOCH = 1767225600
Harness.DAY = 86400
Harness.WEEK = 604800

local LIB_FILES = {
    "Libs/LibStub/LibStub.lua",
    "Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua",
    "Libs/LibResetTracker-1.0/LibResetTracker-1.0.lua"
}

--- Addon files needed by DelvesData, in TOC order.
local ADDON_FILES = {
    "Source/Core/Core.lua",
    "Source/Core/Logger.lua",
    "Locale/LockitMain.lua",
    "Data/Definitions.lua",
    "Data/Variables.lua",
    "Data/Config.lua",
    "Source/Services/DelvesData/DelvesData.lua",
    "Source/Services/DelvesData/DelveRecord.lua",
    "Source/Services/DelvesData/Providers/PoiProvider.lua",
    "Source/Services/DelvesData/Providers/StoryProvider.lua"
}

local function ShallowCopy(tbl)
    local copy = {}
    for key, value in pairs(tbl) do
        copy[key] = value
    end
    return copy
end

---@class TestHarness
local HarnessMixin = {}
local HarnessMeta = { __index = HarnessMixin }

--- Create a new isolated environment.
---@return TestHarness
function Harness.New()
    local h = setmetatable({}, HarnessMeta)

    h.errors = {}
    h.output = {}
    h.frames = {}
    h.calls = { GetDelvesForMap = 0, GetAreaPOIInfo = 0 }

    -- Fake clock. `time` = GetTime(), `server` = GetServerTime().
    h.clock = { time = 1000, server = Harness.BASE_EPOCH + 12 * 3600, timers = {}, seq = 0 }

    -- Fake world state.
    h.world = {
        loggedIn = true,
        inCombat = false,
        resetApiUnavailable = false,
        dailyResetOffset = 15 * 3600,                          -- Daily reset at 15:00 UTC.
        weeklyResetAnchor = Harness.BASE_EPOCH + 15 * 3600 + 3 * Harness.DAY, -- One of the weekly resets.
        maps = {},
        mapFallback = false,
        activeDelvePois = {},
        unavailableZones = {},
        variants = {},
        achievements = {},
        secretValues = {}
    }

    h.env = h:CreateEnv()
    h.addonTable = {}

    return h
end

--#region Clock

function HarnessMixin:Schedule(delay, fn, handle)
    local clock = self.clock
    clock.seq = clock.seq + 1
    clock.timers[#clock.timers + 1] = {
        due = clock.time + math.max(delay or 0, 0),
        seq = clock.seq,
        fn = fn,
        handle = handle
    }
end

--- Run timers that are due by `target`, in order, moving the clock to each timer's due time.
function HarnessMixin:RunTimersUntil(target)
    local clock = self.clock

    while true do
        local bestIndex, best = nil, nil
        for index, timer in ipairs(clock.timers) do
            if timer.due <= target and (best == nil or timer.due < best.due or (timer.due == best.due and timer.seq < best.seq)) then
                bestIndex, best = index, timer
            end
        end

        if not best then
            break
        end

        table.remove(clock.timers, bestIndex)
        if best.due > clock.time then
            local delta = best.due - clock.time
            clock.time = best.due
            clock.server = clock.server + delta
        end

        if not (best.handle and best.handle.cancelled) then
            if best.handle then
                best.fn(best.handle)
            else
                best.fn()
            end
        end
    end
end

--- Advance time by `seconds`, running timers as they become due.
function HarnessMixin:Advance(seconds)
    local target = self.clock.time + seconds
    self:RunTimersUntil(target)

    local delta = target - self.clock.time
    self.clock.time = target
    self.clock.server = self.clock.server + delta
end

--- Jump forward without running timers in between (client asleep), then run the overdue ones once.
function HarnessMixin:Sleep(seconds)
    self.clock.time = self.clock.time + seconds
    self.clock.server = self.clock.server + seconds
    self:RunTimersUntil(self.clock.time)
end

--- Set the server time directly (setup only, before timers exist).
function HarnessMixin:SetServerTime(epoch)
    self.clock.server = epoch
end

function HarnessMixin:ServerTime()
    return math.floor(self.clock.server)
end

--- Number of pending, non-cancelled timers.
function HarnessMixin:ActiveTimers()
    local count = 0
    for _, timer in ipairs(self.clock.timers) do
        if not (timer.handle and timer.handle.cancelled) then
            count = count + 1
        end
    end
    return count
end

--- Next daily reset at or after the current server time (epoch).
function HarnessMixin:NextDailyReset()
    local now = self:ServerTime()
    local untilReset = (self.world.dailyResetOffset - now) % Harness.DAY
    if untilReset == 0 then
        untilReset = Harness.DAY
    end
    return now + untilReset
end
--#endregion

--#region Events

--- Fire a game event on all frames registered for it.
function HarnessMixin:FireEvent(event, ...)
    local targets = {}
    for _, frame in ipairs(self.frames) do
        if frame.events[event] and frame.scripts.OnEvent then
            targets[#targets + 1] = frame
        end
    end

    for _, frame in ipairs(targets) do
        frame.scripts.OnEvent(frame, event, ...)
    end
end
--#endregion

--#region Loading

function HarnessMixin:LoadFile(relativePath, ...)
    local path = Harness.root .. "/" .. relativePath
    local chunk, err = loadfile(path, "t", self.env)
    if not chunk then
        error(("Cannot load %s: %s"):format(path, tostring(err)), 2)
    end
    return chunk(...)
end

--- Load a file's source with replacements applied (e.g. to simulate a newer library version).
function HarnessMixin:LoadFileWithReplacement(relativePath, pattern, replacement)
    local path = Harness.root .. "/" .. relativePath
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()

    local patched, count = source:gsub(pattern, replacement)
    assert(count > 0, "replacement pattern not found in " .. relativePath)

    local chunk = assert(load(patched, "=" .. relativePath, "t", self.env))
    return chunk()
end

function HarnessMixin:LoadLibs()
    for _, file in ipairs(LIB_FILES) do
        self:LoadFile(file)
    end
    return self.env.LibStub("LibResetTracker-1.0")
end

--- Load libs and the addon files used by DelvesData. Returns the addon master table.
function HarnessMixin:LoadAddon()
    self:LoadLibs()
    for _, file in ipairs(ADDON_FILES) do
        self:LoadFile(file, "DelveCompanion", self.addonTable)
    end
    return self.addonTable.DelveCompanion
end
--#endregion

--#region World helpers

--- Set the Story Variant shown in the tooltip of a POI. `nil` removes it.
function HarnessMixin:SetVariant(poiID, text)
    self.world.variants[poiID] = text
end

--- Set the criteria of an achievement: list of `{ name, completed }`.
function HarnessMixin:SetAchievement(achievementID, criteria)
    self.world.achievements[achievementID] = criteria
end
--#endregion

--#region Environment

function HarnessMixin:CreateEnv()
    local h = self
    local world = self.world
    local clock = self.clock

    local env = setmetatable({}, { __index = _G })
    env._G = env

    -- Lua 5.1 / WoW compatibility.
    env.unpack = table.unpack
    env.bit = bit32
    env.format = string.format
    env.strmatch = string.match
    env.strlower = string.lower
    env.strtrim = function(text)
        return (text:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    env.tContains = function(list, value)
        for _, item in ipairs(list) do
            if item == value then
                return true
            end
        end
        return false
    end
    -- WoW extends the table library; extend a copy so the real `table` stays untouched.
    env.table = setmetatable({
        count = function(tbl)
            local count = 0
            for _ in pairs(tbl) do
                count = count + 1
            end
            return count
        end
    }, { __index = table })
    env.print = function(...)
        local parts = {}
        for index = 1, select("#", ...) do
            parts[#parts + 1] = tostring((select(index, ...)))
        end
        h.output[#h.output + 1] = table.concat(parts, " ")
    end

    -- Errors.
    local function ReportError(err)
        h.errors[#h.errors + 1] = tostring(err)
    end
    env.geterrorhandler = function()
        return ReportError
    end
    env.securecallfunction = function(fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then
            ReportError(err)
        end
    end

    -- Secret values (Midnight).
    env.issecretvalue = function(value)
        return world.secretValues[value] == true
    end
    env.issecrettable = function()
        return false
    end

    -- Client state.
    env.IsLoggedIn = function()
        return world.loggedIn
    end
    env.InCombatLockdown = function()
        return world.inCombat
    end
    env.GetBuildInfo = function()
        return "12.0.5", "00000", "Jan 1 2026", 120105
    end
    env.GetMaxLevelForExpansionLevel = function(expansion)
        return 70 + (expansion - 9) * 10
    end

    -- Time.
    env.GetTime = function()
        return clock.time
    end
    env.GetServerTime = function()
        return math.floor(clock.server)
    end
    env.C_DateAndTime = {
        GetSecondsUntilDailyReset = function()
            if world.resetApiUnavailable then
                return nil
            end
            local now = math.floor(clock.server)
            local untilReset = (world.dailyResetOffset - now) % Harness.DAY
            return untilReset == 0 and Harness.DAY or untilReset
        end,
        GetSecondsUntilWeeklyReset = function()
            if world.resetApiUnavailable then
                return nil
            end
            local now = math.floor(clock.server)
            local untilReset = (world.weeklyResetAnchor - now) % Harness.WEEK
            return untilReset == 0 and Harness.WEEK or untilReset
        end
    }
    env.C_Timer = {
        After = function(delay, fn)
            h:Schedule(delay, fn, nil)
        end,
        NewTimer = function(delay, fn)
            local handle = { cancelled = false }
            function handle:Cancel()
                self.cancelled = true
            end
            function handle:IsCancelled()
                return self.cancelled
            end
            h:Schedule(delay, fn, handle)
            return handle
        end
    }

    -- Frames and events.
    env.CreateFrame = function()
        local frame = { events = {}, scripts = {} }
        function frame:RegisterEvent(event)
            self.events[event] = true
        end
        function frame:UnregisterEvent(event)
            self.events[event] = nil
        end
        function frame:UnregisterAllEvents()
            self.events = {}
        end
        function frame:IsEventRegistered(event)
            return self.events[event] == true
        end
        function frame:SetScript(name, fn)
            self.scripts[name] = fn
        end
        function frame:GetScript(name)
            return self.scripts[name]
        end
        h.frames[#h.frames + 1] = frame
        return frame
    end

    local callbacks = {}
    env.EventRegistry = {
        RegisterCallback = function(_, event, func, owner)
            callbacks[event] = callbacks[event] or {}
            callbacks[event][owner or func] = { func = func, owner = owner }
        end,
        UnregisterCallback = function(_, event, owner)
            if callbacks[event] then
                callbacks[event][owner] = nil
            end
        end,
        TriggerEvent = function(_, event, ...)
            local list = {}
            for _, entry in pairs(callbacks[event] or {}) do
                list[#list + 1] = entry
            end
            for _, entry in ipairs(list) do
                if entry.owner ~= nil then
                    entry.func(entry.owner, ...)
                else
                    entry.func(...)
                end
            end
        end
    }

    -- Constants.
    env.LE_EXPANSION_DRAGONFLIGHT = 9
    env.LE_EXPANSION_WAR_WITHIN = 10
    env.LE_EXPANSION_MIDNIGHT = 11
    env.LE_EXPANSION_LEVEL_CURRENT = 11
    env.Enum = {
        ItemQuality = { Rare = 3, Epic = 4, Legendary = 5, Artifact = 6 },
        UIWidgetVisualizationType = { TextWithState = 8 }
    }
    env.MODIFIERS_COLON = "Modifiers:"
    env.CRITERIA_COMPLETED = "Completed"
    env.CRITERIA_NOT_COMPLETED = "Not Completed"

    -- Maps and POIs.
    env.C_Map = {
        GetMapInfo = function(mapID)
            local info = world.maps[mapID]
            if info then
                local copy = ShallowCopy(info)
                copy.mapID = mapID
                return copy
            end
            if world.mapFallback and mapID then
                return { mapID = mapID, name = "Map " .. mapID, parentMapID = mapID == 1 and 0 or 1 }
            end
            return nil
        end
    }
    env.C_AreaPoiInfo = {
        GetDelvesForMap = function(parentMapID)
            h.calls.GetDelvesForMap = h.calls.GetDelvesForMap + 1
            if world.unavailableZones[parentMapID] then
                return nil
            end
            local list = {}
            for _, poiID in ipairs(world.activeDelvePois[parentMapID] or {}) do
                list[#list + 1] = poiID
            end
            return list
        end,
        GetAreaPOIInfo = function(_, poiID)
            h.calls.GetAreaPOIInfo = h.calls.GetAreaPOIInfo + 1
            if world.variants[poiID] == nil then
                return { areaPoiID = poiID }
            end
            -- The widget set ID equals the POI ID in this fake world.
            return { areaPoiID = poiID, tooltipWidgetSet = poiID }
        end
    }
    env.C_UIWidgetManager = {
        GetAllWidgetsBySetID = function(setID)
            if world.variants[setID] == nil then
                return nil
            end
            return {
                { widgetID = setID + 1000000, widgetType = 1 },               -- Unrelated widget.
                { widgetID = setID, widgetType = env.Enum.UIWidgetVisualizationType.TextWithState }
            }
        end,
        GetTextWithStateWidgetVisualizationInfo = function(widgetID)
            local text = world.variants[widgetID]
            if text == nil then
                return nil
            end
            return { text = text, orderIndex = 0 }
        end
    }

    -- Achievements.
    env.GetAchievementNumCriteria = function(achievementID)
        if achievementID == nil then
            error("Usage: GetAchievementNumCriteria(achievementID)")
        end
        local criteria = world.achievements[achievementID]
        return criteria and #criteria or 0
    end
    env.GetAchievementCriteriaInfo = function(achievementID, index)
        local criterion = world.achievements[achievementID] and world.achievements[achievementID][index]
        if not criterion then
            return nil
        end
        return criterion[1], 0, criterion[2]
    end

    return env
end
--#endregion

return Harness
