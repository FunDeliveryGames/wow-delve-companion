---@diagnostic disable: undefined-global
local T, Harness = ...

local Case = T.Suite("LibResetTracker-1.0")

local DAY, WEEK = Harness.DAY, Harness.WEEK
-- First daily reset of the fake calendar (15:00 UTC).
local R0 = Harness.BASE_EPOCH + 15 * 3600
local R1 = R0 + DAY

--- New harness with the server clock at `serverTime` and the library loaded.
local function StartAt(serverTime, setup)
    local h = Harness.New()
    h:SetServerTime(serverTime)
    if setup then
        setup(h)
    end
    local LRT = h:LoadLibs()
    return h, LRT
end

--- Register spies for both callbacks. Returns the shared call log.
local function Spy(LRT, owner)
    local log = {}
    owner = owner or {}

    LRT.RegisterCallback(owner, "OnDailyReset", function(event, info)
        log[#log + 1] = { event = event, info = info }
    end)
    LRT.RegisterCallback(owner, "OnWeeklyReset", function(event, info)
        log[#log + 1] = { event = event, info = info }
    end)

    return log, owner
end

local function CountEvent(log, event)
    local count = 0
    for _, entry in ipairs(log) do
        if entry.event == event then
            count = count + 1
        end
    end
    return count
end

Case("does not fire when it starts", function()
    local h, LRT = StartAt(R0 + 6 * 3600)
    local log = Spy(LRT)

    h:Advance(60)

    T.Equals(#log, 0)
    T.Equals(#h.errors, 0)
end)

Case("fires once at the daily reset with period starts", function()
    local h, LRT = StartAt(R1 - 100)
    local log = Spy(LRT)

    h:Advance(200)

    T.Equals(CountEvent(log, "OnDailyReset"), 1)
    T.Equals(CountEvent(log, "OnWeeklyReset"), 0)
    T.Equals(log[1].info.period, "Daily")
    T.Equals(log[1].info.periodStart, R1)
    T.Equals(log[1].info.previousPeriodStart, R0)

    h:Advance(3600)
    T.Equals(#log, 1, "no repeated callback")
end)

Case("on a weekly reset fires daily first, then weekly", function()
    local weekly = R0 + 3 * DAY -- Matches the harness weekly anchor.
    local h, LRT = StartAt(weekly - 100)
    local log = Spy(LRT)

    h:Advance(200)

    T.Equals(#log, 2)
    T.Equals(log[1].event, "OnDailyReset")
    T.Equals(log[2].event, "OnWeeklyReset")
    T.Equals(log[2].info.periodStart, weekly)
end)

Case("a check before the reset does nothing", function()
    local h, LRT = StartAt(R1 - 100)
    local log = Spy(LRT)

    h:Advance(50)
    h:FireEvent("PLAYER_ENTERING_WORLD")
    T.Equals(#log, 0, "early check")

    h:Advance(100)
    T.Equals(#log, 1, "after the reset")
end)

Case("fires once after the client slept through several resets", function()
    local h, LRT = StartAt(R0 + 6 * 3600)
    local log = Spy(LRT)

    h:Sleep(3 * DAY)

    T.Equals(CountEvent(log, "OnDailyReset"), 1)
    local info = log[1].info
    T.Equals(info.previousPeriodStart, R0)
    T.Equals(info.periodStart, R0 + 3 * DAY)
end)

Case("ignores a 1 hour daylight-saving shift of the reset time", function()
    local h, LRT = StartAt(R0 + 6 * 3600)
    local log = Spy(LRT)

    h.world.dailyResetOffset = h.world.dailyResetOffset + 3600
    h.world.weeklyResetAnchor = h.world.weeklyResetAnchor + 3600
    h:FireEvent("PLAYER_ENTERING_WORLD")
    T.Equals(#log, 0, "shift alone")

    h:Advance((R1 + 1800) - h:ServerTime())
    T.Equals(#log, 0, "old reset time")

    h:Advance((R1 + 3600 + 100) - h:ServerTime())
    T.Equals(CountEvent(log, "OnDailyReset"), 1, "shifted reset time")
end)

Case("query functions", function()
    local now = R0 + 6 * 3600
    local _, LRT = StartAt(now)

    T.Equals(LRT:GetPeriodStart(LRT.Period.Daily), R0)
    T.Equals(LRT:GetNextReset(LRT.Period.Daily), R1)
    T.Equals(LRT:GetSecondsUntil(LRT.Period.Daily), R1 - now)
    T.Equals(LRT:GetPeriodStart(LRT.Period.Weekly), R0 + 3 * DAY - WEEK)

    T.True(LRT:HasResetSince(LRT.Period.Daily, R0 - 10))
    T.False(LRT:HasResetSince(LRT.Period.Daily, R0 + 10))
    T.Nil(LRT:HasResetSince(LRT.Period.Daily, nil))

    T.Errors(function()
        LRT:GetPeriodStart("Monthly")
    end, "unknown period")
end)

Case("stops its timer when the last callback is removed", function()
    local h, LRT = StartAt(R0 + 6 * 3600)
    local _, owner = Spy(LRT)

    T.Equals(h:ActiveTimers(), 1, "running")
    T.True(LRT.frame:IsEventRegistered("PLAYER_ENTERING_WORLD"))

    LRT.UnregisterCallback(owner, "OnDailyReset")
    T.Equals(h:ActiveTimers(), 1, "still used by the weekly callback")

    LRT.UnregisterAllCallbacks(owner)
    T.Equals(h:ActiveTimers(), 0, "stopped")
    T.False(LRT.frame:IsEventRegistered("PLAYER_ENTERING_WORLD"))
end)

Case("waits for PLAYER_LOGIN before starting", function()
    local h, LRT = StartAt(R1 - 100, function(harness)
        harness.world.loggedIn = false
    end)
    local log = Spy(LRT)

    T.Equals(h:ActiveTimers(), 0, "not started")

    h.world.loggedIn = true
    h:FireEvent("PLAYER_LOGIN")
    T.Equals(h:ActiveTimers(), 1, "started")
    T.Equals(#log, 0, "no callback for the first snapshot")

    h:Advance(200)
    T.Equals(#log, 1)
end)

Case("retries while the reset API is unavailable", function()
    local h, LRT = StartAt(R1 - 100, function(harness)
        harness.world.resetApiUnavailable = true
    end)
    local log = Spy(LRT)

    h:Advance(5)
    T.Equals(h:ActiveTimers(), 1, "still retrying")

    h.world.resetApiUnavailable = false
    h:Advance(5)
    T.Equals(#log, 0, "first successful read is a snapshot")

    h:Advance(200)
    T.Equals(CountEvent(log, "OnDailyReset"), 1)
end)

Case("a newer embedded version takes over without duplicate timers", function()
    local h, LRT = StartAt(R1 - 100)
    local log = Spy(LRT)

    h:LoadFileWithReplacement("Libs/LibResetTracker-1.0/LibResetTracker-1.0.lua",
        'local MAJOR, MINOR = "LibResetTracker%-1%.0", 1', 'local MAJOR, MINOR = "LibResetTracker-1.0", 2')

    local upgraded, minor = h.env.LibStub("LibResetTracker-1.0")
    T.Equals(upgraded, LRT, "same library table")
    T.Equals(minor, 2)
    T.Equals(h:ActiveTimers(), 1, "one timer")

    h:Advance(200)
    T.Equals(CountEvent(log, "OnDailyReset"), 1, "existing callbacks kept")
end)
