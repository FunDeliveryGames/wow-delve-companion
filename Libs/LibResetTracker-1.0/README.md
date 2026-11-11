# LibResetTracker-1.0

A small embeddable library that tells you when the game's **daily** and **weekly** resets happen.

- No SavedVariables and no dependency on any particular addon.
- Requires [LibStub](https://www.curseforge.com/wow/addons/libstub) and [CallbackHandler-1.0](https://www.curseforge.com/wow/addons/callbackhandler).
- Timers run only while at least one callback is registered.

## Embedding

List it in your TOC after LibStub and CallbackHandler-1.0:

```
Libs\LibStub\LibStub.lua
Libs\CallbackHandler-1.0\CallbackHandler-1.0.lua
Libs\LibResetTracker-1.0\LibResetTracker-1.0.lua
```

Several addons can embed it. LibStub keeps a single instance (the highest `MINOR`).

## Callbacks

```lua
local LRT = LibStub("LibResetTracker-1.0")

LRT.RegisterCallback(myAddon, LRT.Event.DailyReset, function(event, info)
    -- refresh daily state
end)
LRT.RegisterCallback(myAddon, LRT.Event.WeeklyReset, "OnWeeklyReset") -- calls myAddon:OnWeeklyReset(event, info)

-- One handler for every period, e.g. when your code is keyed by period name.
LRT.RegisterCallback(myAddon, LRT.Event.Reset, function(event, info)
    if info.period == LRT.Period.Daily then
        -- ...
    end
end)

LRT.UnregisterCallback(myAddon, LRT.Event.DailyReset)
LRT.UnregisterAllCallbacks(myAddon)
```

Event names are available as constants in `LRT.Event`:

| Constant | Event | Fired when |
|---|---|---|
| `LRT.Event.DailyReset` | `OnDailyReset` | The daily period changed. |
| `LRT.Event.WeeklyReset` | `OnWeeklyReset` | The weekly period changed. |
| `LRT.Event.Reset` | `OnReset` | Any period changed, right after that period's own event. Check `info.period`. |

`info` is shared between handlers. Don't modify it.

| Field | Meaning |
|---|---|
| `period` | `"Daily"` or `"Weekly"` (`LRT.Period`). |
| `periodStart` | Server epoch (seconds) at which the new period started. |
| `previousPeriodStart` | Server epoch at which the previously observed period started. |

Notes:
- The weekly reset always coincides with a daily reset. The order is `OnDailyReset`, `OnReset` (Daily), `OnWeeklyReset`, `OnReset` (Weekly), all in the same frame. If you'd do the same work for both, subscribe to only one.
- Subscribe to either `OnReset` or the per-period events for the same work. Subscribing to both runs your handler twice per reset.
- If several resets were missed (client asleep, long loading screen), the callback fires **once**. Compare `periodStart` with `previousPeriodStart` if you need to know how many periods passed.
- Game data (quests, POIs, vault) can update a few seconds after the reset. Delay your refresh a little, or listen to the related game events as well.
- Resets that happened before your callback was registered, including while logged out, are not reported. Use `HasResetSince` for those.

## Functions

All functions take a period name: `LRT.Period.Daily` or `LRT.Period.Weekly`. They return `nil` while the game's reset API is unavailable (before login).

| Function | Returns |
|---|---|
| `LRT:GetSecondsUntil(period)` | Seconds until the next reset. |
| `LRT:GetPeriodStart(period)` | Server epoch at which the current period started. Stable within the period, so it works as a SavedVariables key. |
| `LRT:GetNextReset(period)` | Server epoch of the next reset. |
| `LRT:HasResetSince(period, timestamp)` | `true` if a reset happened after `timestamp` (a stored `GetServerTime()` value). |

Example: detect a weekly reset that happened while logged out.

```lua
local lastSeen = MyAddonDB.lastSeen
if lastSeen and LRT:HasResetSince(LRT.Period.Weekly, lastSeen) then
    wipe(MyAddonDB.weeklyProgress)
end
MyAddonDB.lastSeen = GetServerTime()
```

## How it works

- The current period start is computed as `GetServerTime() + secondsUntilReset - periodLength`, rounded to the minute.
- A reset is detected when the start moves forward by more than half a period. Timers only decide *when* to check. A 1-hour daylight-saving shift updates the stored start without firing.
- The next check is scheduled at `min(secondsUntilReset + 2 s, 600 s)`. The 600 s heartbeat corrects timer drift, client sleep and clock changes. The library also re-checks on `PLAYER_ENTERING_WORLD`.
