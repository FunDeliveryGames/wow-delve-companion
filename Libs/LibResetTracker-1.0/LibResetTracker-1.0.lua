--[[
LibResetTracker-1.0
Fires callbacks when the game's daily and weekly resets happen.

- Independent from any addon: no SavedVariables, no addon globals.
- Depends on LibStub and CallbackHandler-1.0.
- Timers run only while at least one callback is registered.

Usage:
    local LRT = LibStub("LibResetTracker-1.0")
    LRT.RegisterCallback(myAddon, LRT.Event.DailyReset, function(event, info) ... end)
    LRT.RegisterCallback(myAddon, LRT.Event.WeeklyReset, "MyMethodName")
    LRT.RegisterCallback(myAddon, LRT.Event.Reset, function(event, info) ... info.period ... end)

Events (`LRT.Event`):
    OnDailyReset  The daily period changed.
    OnWeeklyReset The weekly period changed.
    OnReset       Any period changed. Fired right after the period's own event; check `info.period`.

`info` (shared between handlers, do not modify):
    period              "Daily" | "Weekly"
    periodStart         Server epoch (seconds) at which the new period started.
    previousPeriodStart Server epoch at which the previously observed period started.

The weekly reset always coincides with a daily reset. In that case the order is:
`OnDailyReset`, `OnReset` (Daily), `OnWeeklyReset`, `OnReset` (Weekly).
See README.md for the full API.
]]

local MAJOR, MINOR = "LibResetTracker-1.0", 1

---@class LibResetTracker
---@field Period { Daily: string, Weekly: string }
---@field Event { Reset: string, DailyReset: string, WeeklyReset: string }
---@field callbacks table CallbackHandler registry.
---@field frame Frame
---@field timer table? Pending C_Timer handle.
---@field isRunning boolean
---@field knownStart table<string, number> Last observed period start per period name.
---@field usedEvents table<string, boolean> Callback events that currently have handlers.
---@field RegisterCallback fun(owner: table|string, event: string, method: function|string, arg: any?)
---@field UnregisterCallback fun(owner: table|string, event: string)
---@field UnregisterAllCallbacks fun(owner: table|string)
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then
    return
end

local CallbackHandler = LibStub("CallbackHandler-1.0")

-- Lua APIs
local floor, min, max = math.floor, math.min, math.max
local ipairs, next, type, tostring = ipairs, next, type, tostring

--#region Constants

local DAY_SEC = 86400
local WEEK_SEC = 604800
--- Delay after the expected reset moment before checking, to be sure the server-side values have changed.
local TIMER_GRACE_SEC = 2
--- Upper bound for any scheduled check. Corrects timer drift, client sleep and clock changes.
local HEARTBEAT_SEC = 600
--- Delay before retrying when the reset API is not available yet.
local RETRY_SEC = 5
--- Period starts are rounded to remove the 1 s jitter between server time and seconds-until-reset.
local ROUND_TO_SEC = 60
--#endregion

lib.Period = {
    Daily = "Daily",
    Weekly = "Weekly"
}

--- Callback event names.
lib.Event = {
    --- Fired for every period, right after the period's own event. `info.period` tells which one.
    Reset = "OnReset",
    DailyReset = "OnDailyReset",
    WeeklyReset = "OnWeeklyReset"
}

--- Periods in the order their callbacks are fired.
local PERIODS = {
    {
        name = lib.Period.Daily,
        length = DAY_SEC,
        event = lib.Event.DailyReset,
        GetSecondsUntil = function()
            return C_DateAndTime.GetSecondsUntilDailyReset()
        end
    },
    {
        name = lib.Period.Weekly,
        length = WEEK_SEC,
        event = lib.Event.WeeklyReset,
        GetSecondsUntil = function()
            return C_DateAndTime.GetSecondsUntilWeeklyReset()
        end
    }
}

local PERIODS_BY_NAME = {}
for _, period in ipairs(PERIODS) do
    PERIODS_BY_NAME[period.name] = period
end

--#region Upgrade-safe state

if lib.timer then
    lib.timer:Cancel()
    lib.timer = nil
end
lib.isRunning = false
lib.knownStart = lib.knownStart or {}
lib.usedEvents = lib.usedEvents or {}
lib.callbacks = lib.callbacks or CallbackHandler:New(lib)
lib.frame = lib.frame or CreateFrame("Frame")
lib.frame:UnregisterAllEvents()
--#endregion

--#region Internals

local function GetPeriodOrError(periodName)
    local period = PERIODS_BY_NAME[periodName]
    if not period then
        error(("%s: unknown period %q. Use LibResetTracker.Period."):format(MAJOR, tostring(periodName)), 3)
    end

    return period
end

--- Compute the start of the current period.
---@return number|nil periodStart Server epoch, rounded to `ROUND_TO_SEC`. `nil` if the reset API is unavailable.
---@return number|nil secondsUntil Seconds until the next reset.
local function ComputeStart(period)
    local secondsUntil = period.GetSecondsUntil()
    if type(secondsUntil) ~= "number" then
        return nil, nil
    end

    local rawStart = GetServerTime() + secondsUntil - period.length
    return floor(rawStart / ROUND_TO_SEC + 0.5) * ROUND_TO_SEC, secondsUntil
end

local Check

local function Schedule(delaySec)
    if lib.timer then
        lib.timer:Cancel()
    end

    lib.timer = C_Timer.NewTimer(delaySec, function()
        lib.timer = nil
        Check()
    end)
end

--- Compare the current period starts with the known ones, fire callbacks for resets, and schedule the next check.
Check = function()
    if not (lib.isRunning and IsLoggedIn()) then
        return
    end

    local nextDelay = HEARTBEAT_SEC
    local toFire = {}

    for _, period in ipairs(PERIODS) do
        local start, secondsUntil = ComputeStart(period)

        if start == nil then
            nextDelay = min(nextDelay, RETRY_SEC)
        else
            local known = lib.knownStart[period.name]
            lib.knownStart[period.name] = start

            -- A real reset moves the start by a whole period. Smaller moves (e.g. a 1 h DST shift) only update the known value.
            if known and start - known > period.length / 2 then
                toFire[#toFire + 1] = {
                    event = period.event,
                    info = {
                        period = period.name,
                        periodStart = start,
                        previousPeriodStart = known
                    }
                }
            end

            nextDelay = min(nextDelay, max(secondsUntil, 0) + TIMER_GRACE_SEC)
        end
    end

    Schedule(nextDelay)

    -- Fire after the state is consistent, so handlers can query the library.
    for _, entry in ipairs(toFire) do
        lib.callbacks:Fire(entry.event, entry.info)
        lib.callbacks:Fire(lib.Event.Reset, entry.info)
    end
end

local function Start()
    if lib.isRunning then
        return
    end

    lib.isRunning = true
    -- A new run never reports resets that happened before it started.
    lib.knownStart = {}

    lib.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    if IsLoggedIn() then
        Check()
    else
        lib.frame:RegisterEvent("PLAYER_LOGIN")
    end
end

local function Stop()
    lib.isRunning = false

    if lib.timer then
        lib.timer:Cancel()
        lib.timer = nil
    end
    lib.frame:UnregisterAllEvents()
end

lib.frame:SetScript("OnEvent", function(frame, event)
    if event == "PLAYER_LOGIN" then
        frame:UnregisterEvent("PLAYER_LOGIN")
    end

    Check()
end)

lib.callbacks.OnUsed = function(_, _, event)
    lib.usedEvents[event] = true
    Start()
end

lib.callbacks.OnUnused = function(_, _, event)
    lib.usedEvents[event] = nil
    if next(lib.usedEvents) == nil then
        Stop()
    end
end
--#endregion

--#region Public API

--- Seconds until the next reset of the period.
---@param periodName string A value of `LibResetTracker.Period`.
---@return number|nil
function lib:GetSecondsUntil(periodName)
    local _, secondsUntil = ComputeStart(GetPeriodOrError(periodName))
    return secondsUntil
end

--- Server epoch at which the current period started. Stable within the period, so it can be stored in SavedVariables.
---@param periodName string A value of `LibResetTracker.Period`.
---@return number|nil
function lib:GetPeriodStart(periodName)
    return (ComputeStart(GetPeriodOrError(periodName)))
end

--- Server epoch of the next reset of the period.
---@param periodName string A value of `LibResetTracker.Period`.
---@return number|nil
function lib:GetNextReset(periodName)
    local period = GetPeriodOrError(periodName)
    local start = ComputeStart(period)
    return start and start + period.length or nil
end

--- Whether a reset of the period happened after `timestamp` (server epoch). Use it to detect resets that happened while logged out.
---@param periodName string A value of `LibResetTracker.Period`.
---@param timestamp number Server epoch, e.g. a `GetServerTime()` value stored in SavedVariables.
---@return boolean|nil # `nil` if the reset API is unavailable.
function lib:HasResetSince(periodName, timestamp)
    local start = ComputeStart(GetPeriodOrError(periodName))
    if start == nil or type(timestamp) ~= "number" then
        return nil
    end

    return timestamp < start
end
--#endregion

-- An older version may have had listeners. Restart with this version's logic.
if next(lib.usedEvents) ~= nil then
    Start()
end
