---@diagnostic disable: undefined-global
local T, Harness = ...

local Case = T.Suite("DelvesData")

local DAY = Harness.DAY

-- Fixture Delves (uiMapIDs).
local EARTHCRAWL, TAKRETHAN, ZEKVIR, ATALAMAN, LABYRINTH = 2269, 2259, 2348, 2535, 2647

--- Fake world + fixture Config. Mirrors the real Config shapes (regular, Nemesis, Labyrinth).
local function SetupWorld(h)
    local world = h.world

    world.maps = {
        [2248] = { name = "Isle of Dorn", parentMapID = 2274 },
        [2214] = { name = "The Ringing Deeps", parentMapID = 2274 },
        [2255] = { name = "Azj-Kahet", parentMapID = 2274 },
        [2437] = { name = "Zul'Aman", parentMapID = 2537 },
        [EARTHCRAWL] = { name = "Earthcrawl Mines", parentMapID = 2248 },
        [TAKRETHAN] = { name = "Tak-Rethan Abyss", parentMapID = 2214 },
        [ZEKVIR] = { name = "Zekvir's Lair", parentMapID = 2255 },
        [ATALAMAN] = { name = "Atal'Aman", parentMapID = 2437 },
        [LABYRINTH] = { name = "The Labyrinth of Kindo'jan", parentMapID = 2437 }
    }

    world.activeDelvePois = {
        [2248] = { 7787 },       -- Earthcrawl Mines is Bountiful.
        [2214] = { 7873 },
        [2255] = {},
        [2437] = { 8443, 9035 }  -- Labyrinth is Bountiful.
    }

    h:SetVariant(7787, "Rescue the Miners")
    h:SetVariant(7873, "Spider-Trouble (Part 1)")
    h:SetVariant(7784, "Spider-Trouble (Part 1)")
    h:SetVariant(8443, "A New Seasonal Story")
    h:SetVariant(9035, "Labyrinth Story")

    h:SetAchievement(40527, { { "Rescue the Miners", true }, { "Other Story", false } })
    h:SetAchievement(40535, { { "spider-trouble (part 1)", false } })
    h:SetAchievement(61729, { { "Old Story", true } })
end

local FIXTURE_DELVE_MAPS = {
    [10] = { 2214, 2248 },
    [11] = { 2437 }
}

local FIXTURE_DELVES_CONFIG = {
    [10] = {
        { uiMapID = EARTHCRAWL, poiIDs = { regular = 7863, bountiful = 7787 }, achievements = { chest = 40806, story = 40527 } },
        { uiMapID = TAKRETHAN, poiIDs = { regular = 7873, bountiful = 7784 }, achievements = { chest = 40811, story = 40535 } },
        {
            uiMapID = ZEKVIR,
            poiIDs = { regular = 7875 },
            achievements = { bossSolo = 40433 },
            nemesisInfo = { isCurrentSeason = false, delveTooltipLine = "Nemesis~Season" }
        }
    },
    [11] = {
        { uiMapID = ATALAMAN, poiIDs = { regular = 8443, bountiful = 8444 }, achievements = { chest = 61863, story = 61729 } },
        {
            uiMapID = LABYRINTH,
            poiIDs = { regular = 9036, bountiful = 9035 },
            achievements = { chest = 63717, bossSolo = 63715 },
            labyrinthInfo = { isAvailable = true }
        }
    }
}

--- Load the addon with the fixture and initialize DelvesData.
---@param options { beforeInit: fun(h: TestHarness, addon: table)?, serverTime: number?, noInit: boolean? }?
local function Start(options)
    options = options or {}

    local h = Harness.New()
    if options.serverTime then
        h:SetServerTime(options.serverTime)
    end
    SetupWorld(h)

    local addon = h:LoadAddon()
    addon.Config.DELVE_MAPS = FIXTURE_DELVE_MAPS
    addon.Config.DELVES_CONFIG = FIXTURE_DELVES_CONFIG

    if options.beforeInit then
        options.beforeInit(h, addon)
    end
    if not options.noInit then
        addon.DelvesData:Init()
    end

    return h, addon, addon.DelvesData
end

--- Subscribe to UPDATED. Returns the list of received change sets.
local function SpyUpdates(h, addon)
    local received = {}
    h.env.EventRegistry:RegisterCallback(addon.Definitions.Events.DELVES_DATA.UPDATED, function(_, changes)
        received[#received + 1] = changes
    end, received)
    return received
end

local function Names(records)
    local names = {}
    for _, record in ipairs(records) do
        names[#names + 1] = record.delveName
    end
    return names
end

--#region Records and indexes

Case("builds records with static fields and kinds", function()
    local h, addon, DelvesData = Start()
    local kinds = addon.Definitions.DelveKind

    local earthcrawl = DelvesData:Get(EARTHCRAWL)
    T.Equals(earthcrawl.id, EARTHCRAWL)
    T.Equals(earthcrawl.expansion, 10)
    T.Equals(earthcrawl.kind, kinds.Regular)
    T.Equals(earthcrawl.delveName, "Earthcrawl Mines")
    T.Equals(earthcrawl.parentMapID, 2248)
    T.Equals(earthcrawl.parentMapName, "Isle of Dorn")
    T.Equals(earthcrawl.levelRequired, 0)

    local zekvir = DelvesData:Get(ZEKVIR)
    T.Equals(zekvir.kind, kinds.Nemesis)
    T.Equals(zekvir.levelRequired, 80, "Nemesis: max level of its expansion")

    T.Equals(DelvesData:Get(LABYRINTH).kind, kinds.Labyrinth)
    T.Equals(DelvesData:GetByPoi(7787), earthcrawl, "bountiful POI")
    T.Equals(DelvesData:GetByPoi(7863), earthcrawl, "regular POI")
    T.Equals(DelvesData:GetByStoryAchievement(40527), earthcrawl)
    T.Equals(#h.errors, 0)
end)

Case("keeps Config order for expansions, Delves and zones", function()
    local _, _, DelvesData = Start()

    T.ListEquals(DelvesData:GetExpansions(), { 10, 11 })
    T.ListEquals(Names(DelvesData:GetDelves(10)), { "Earthcrawl Mines", "Tak-Rethan Abyss", "Zekvir's Lair" })

    local zones = DelvesData:GetZones(10)
    T.Equals(#zones, 2)
    T.Equals(zones[1].name, "The Ringing Deeps", "DELVE_MAPS order, not Delve order")
    T.ListEquals(Names(zones[1].delves), { "Tak-Rethan Abyss" })
    T.Equals(zones[2].name, "Isle of Dorn")
    T.ListEquals(Names(zones[2].delves), { "Earthcrawl Mines" })

    local all = {}
    for record in DelvesData:IterateAll() do
        all[#all + 1] = record.id
    end
    T.ListEquals(all, { EARTHCRAWL, TAKRETHAN, ZEKVIR, ATALAMAN, LABYRINTH })
end)

Case("returns read-only empty lists for unknown expansions", function()
    local _, _, DelvesData = Start()

    T.Equals(#DelvesData:GetDelves(9), 0)
    T.Equals(#DelvesData:GetZones(9), 0)
    T.Equals(#DelvesData:GetBountiful(9), 0)
    T.Errors(function()
        DelvesData:GetDelves(9)[1] = true
    end, "read-only")
end)

Case("FindByEntranceName uses plain text, not Lua patterns", function()
    local _, _, DelvesData = Start()

    T.Equals(DelvesData:FindByEntranceName("Tak-Rethan Abyss"), DelvesData:Get(TAKRETHAN), "regression: '-' in the name")
    T.Equals(DelvesData:FindByEntranceName("  earthcrawl   MINES "), DelvesData:Get(EARTHCRAWL), "normalized")
    T.Equals(DelvesData:FindByEntranceName("|cffffd200Atal'Aman|r"), DelvesData:Get(ATALAMAN), "color codes")
    T.Equals(DelvesData:FindByEntranceName("Delve: Zekvir's Lair (Tier ?)"), DelvesData:Get(ZEKVIR), "substring")
    T.Equals(DelvesData:FindByEntranceName("Entrance: Tak-Rethan Abyss (Tier 8)"), DelvesData:Get(TAKRETHAN),
        "regression: '-' in a substring match")
    T.Nil(DelvesData:FindByEntranceName("Unknown Place"))
    T.Nil(DelvesData:FindByEntranceName(""))
    T.Nil(DelvesData:FindByEntranceName(nil))
end)

Case("FindByEntranceName prefers the longest contained name", function()
    local _, _, DelvesData = Start({
        beforeInit = function(h)
            h.world.maps[ZEKVIR].name = "Mines"
        end
    })

    T.Equals(DelvesData:FindByEntranceName("Earthcrawl Mines Entrance"), DelvesData:Get(EARTHCRAWL))
    T.Equals(DelvesData:FindByEntranceName("Mines"), DelvesData:Get(ZEKVIR), "exact match wins")
end)

Case("FindByEntranceName ignores secret values", function()
    local h, _, DelvesData = Start()
    h.world.secretValues["Earthcrawl Mines"] = true

    T.Nil(DelvesData:FindByEntranceName("Earthcrawl Mines"))
end)

Case("initializes with the real Config without errors", function()
    local h = Harness.New()
    h.world.mapFallback = true

    local addon = h:LoadAddon()
    local DelvesData = addon.DelvesData
    DelvesData:Init()

    T.Equals(#h.errors, 0, table.concat(h.errors, "\n"))
    for expansion, configs in pairs(addon.Config.DELVES_CONFIG) do
        T.Equals(#DelvesData:GetDelves(expansion), #configs, "record count for expansion " .. expansion)
    end
    for record in DelvesData:IterateAll() do
        T.Equals(DelvesData:FindByEntranceName(record.delveName), record)
    end
end)
--#endregion

--#region Providers

Case("PoiProvider sets Bountiful state with one API call per zone", function()
    local h, _, DelvesData = Start()

    T.True(DelvesData:Get(EARTHCRAWL).isBountiful)
    T.Equals(DelvesData:Get(EARTHCRAWL).poiID, 7787)
    T.False(DelvesData:Get(TAKRETHAN).isBountiful)
    T.Equals(DelvesData:Get(TAKRETHAN).poiID, 7873)
    T.False(DelvesData:Get(ZEKVIR).isBountiful, "no Bountiful POI")
    T.True(DelvesData:Get(LABYRINTH).isBountiful)

    T.ListEquals(Names(DelvesData:GetBountiful(10)), { "Earthcrawl Mines" })
    T.ListEquals(Names(DelvesData:GetBountiful(11)), { "The Labyrinth of Kindo'jan" })

    T.Equals(h.calls.GetDelvesForMap, 4, "4 zones for 5 Delves")
end)

Case("PoiProvider keeps values when zone data is unavailable", function()
    local h, _, DelvesData = Start()

    h.world.unavailableZones[2248] = true
    DelvesData:RefreshNow("test")

    T.True(DelvesData:Get(EARTHCRAWL).isBountiful)
end)

Case("StoryProvider resolves every status", function()
    local h, addon, DelvesData = Start()
    local statuses = addon.Definitions.DelveStoryStatus

    T.Equals(DelvesData:Get(EARTHCRAWL).storyStatus, statuses.Completed)
    T.Equals(DelvesData:Get(EARTHCRAWL).storyVariant, "Rescue the Miners")
    T.Equals(DelvesData:Get(TAKRETHAN).storyStatus, statuses.NotCompleted, "case-insensitive plain match with '-' and '()'")
    T.Equals(DelvesData:Get(ATALAMAN).storyStatus, statuses.NotTracked, "variant not in the achievement")
    T.Equals(DelvesData:Get(LABYRINTH).storyStatus, statuses.NotTracked, "no story achievement")
    T.Equals(DelvesData:Get(ZEKVIR).storyStatus, statuses.Unknown, "no story widget")
    T.Nil(DelvesData:Get(ZEKVIR).storyVariant)
    T.Equals(#h.errors, 0, "GetAchievementNumCriteria(nil) is never called")
end)

Case("StoryProvider keeps today's variant when a read fails, and expires it after the reset", function()
    local h, addon, DelvesData = Start()
    local statuses = addon.Definitions.DelveStoryStatus
    local earthcrawl = DelvesData:Get(EARTHCRAWL)

    h:SetVariant(7787, nil)
    DelvesData:RefreshNow("test")
    T.Equals(earthcrawl.storyVariant, "Rescue the Miners", "kept within the day")
    T.Equals(earthcrawl.storyStatus, statuses.Completed)

    h:Advance(h:NextDailyReset() - h:ServerTime() + 10)
    DelvesData:RefreshNow("test")
    T.Nil(earthcrawl.storyVariant, "expired after the reset")
    T.Equals(earthcrawl.storyStatus, statuses.Unknown)
end)

Case("StoryProvider re-checks completion of a kept variant", function()
    local h, addon, DelvesData = Start()
    local statuses = addon.Definitions.DelveStoryStatus

    -- Inside the Delve: the POI data is unavailable, then the story gets completed.
    h:SetVariant(7873, nil)
    h:SetAchievement(40535, { { "spider-trouble (part 1)", true } })
    h:FireEvent("CRITERIA_EARNED", 40535)
    h:Advance(1)

    T.Equals(DelvesData:Get(TAKRETHAN).storyStatus, statuses.Completed)
end)

Case("StoryProvider leaves fields unchanged for secret values", function()
    local h, addon, DelvesData = Start()

    h:SetVariant(7787, "Unreadable text")
    h.world.secretValues["Unreadable text"] = true
    h:Advance(h:NextDailyReset() - h:ServerTime() + 10) -- Even after the reset.
    DelvesData:RefreshNow("test")

    local earthcrawl = DelvesData:Get(EARTHCRAWL)
    T.Equals(earthcrawl.storyVariant, "Rescue the Miners")
    T.Equals(earthcrawl.storyStatus, addon.Definitions.DelveStoryStatus.Completed)
end)
--#endregion

--#region Refresh scheduling and events

Case("UPDATED fires only for real changes, with the changed Delves and fields", function()
    local h, addon, DelvesData = Start()
    local received = SpyUpdates(h, addon)

    DelvesData:RefreshNow("nothing")
    T.Equals(#received, 0, "no changes, no event")

    h.world.activeDelvePois[2214] = { 7784 }
    DelvesData:RefreshNow("bountiful")

    T.Equals(#received, 1)
    T.Equals(received[1].reason, "bountiful")
    T.KeysEqual(received[1].delves, { TAKRETHAN })
    T.KeysEqual(received[1].fields, { "isBountiful", "poiID" })
end)

Case("requests within the coalescing window run once, with merged reasons", function()
    local h, addon, DelvesData = Start()
    local received = SpyUpdates(h, addon)
    local before = h.calls.GetDelvesForMap

    h.world.activeDelvePois[2214] = { 7784 }
    DelvesData:RequestRefresh("a")
    DelvesData:RequestRefresh("b")
    DelvesData:RequestRefresh("a")
    DelvesData:RequestRefresh("c")

    h:Advance(0.4)
    T.Equals(h.calls.GetDelvesForMap, before, "not yet")

    h:Advance(0.2)
    T.Equals(h.calls.GetDelvesForMap, before + 4, "one full run")
    T.Equals(#received, 1)
    T.Equals(received[1].reason, "a,b,c")
end)

Case("refreshes wait until combat ends", function()
    local h, _, DelvesData = Start()
    local before = h.calls.GetDelvesForMap

    h.world.inCombat = true
    T.False(DelvesData:RefreshNow("now"), "postponed")
    DelvesData:RequestRefresh("later")
    h:Advance(2)
    T.Equals(h.calls.GetDelvesForMap, before, "nothing during combat")

    h.world.inCombat = false
    h:FireEvent("PLAYER_REGEN_ENABLED")
    T.Equals(h.calls.GetDelvesForMap, before + 4, "one merged run after combat")
end)

Case("game events trigger the right providers and records", function()
    local h, addon, DelvesData = Start()
    local received = SpyUpdates(h, addon)

    local maps, pois = h.calls.GetDelvesForMap, h.calls.GetAreaPOIInfo
    h:FireEvent("AREA_POIS_UPDATED")
    h:Advance(1)
    T.Equals(h.calls.GetDelvesForMap, maps + 4, "AREA_POIS_UPDATED: Poi provider, all zones")
    T.Equals(h.calls.GetAreaPOIInfo, pois + 5, "AREA_POIS_UPDATED: Story provider, all Delves")

    maps, pois = h.calls.GetDelvesForMap, h.calls.GetAreaPOIInfo
    h:SetAchievement(40535, { { "spider-trouble (part 1)", true } })
    h:FireEvent("CRITERIA_EARNED", 40535)
    h:Advance(1)
    T.Equals(h.calls.GetDelvesForMap, maps, "CRITERIA_EARNED: no POI refresh")
    T.Equals(h.calls.GetAreaPOIInfo, pois + 1, "CRITERIA_EARNED: only that Delve")
    T.KeysEqual(received[#received].delves, { TAKRETHAN })
    T.KeysEqual(received[#received].fields, { "storyStatus" })

    h:FireEvent("CRITERIA_EARNED", 12345)
    T.Equals(h:ActiveTimers(), 1, "unrelated achievement: nothing scheduled (only the reset tracker timer)")
end)

Case("a daily reset triggers refreshes after 5 and 60 seconds", function()
    local reset = Harness.BASE_EPOCH + 15 * 3600 + DAY
    local h, _, _ = Start({ serverTime = reset - 10 })
    local runs = function()
        return h.calls.GetDelvesForMap / 4
    end
    local afterLogin = runs()

    h:Advance(10 + 2 + 5) -- Reset detected ~2 s after the reset, refresh requested 5 s later.
    T.Equals(runs(), afterLogin, "requested, not flushed yet")

    h:Advance(1)
    T.Equals(runs(), afterLogin + 1, "first refresh")

    h:Advance(60)
    T.Equals(runs(), afterLogin + 2, "second refresh")
end)

Case("a reset refreshes only the providers subscribed to its period", function()
    local dailyReset = Harness.BASE_EPOCH + 15 * 3600 + DAY
    local weeklyReset = Harness.BASE_EPOCH + 15 * 3600 + 3 * DAY -- Matches the harness weekly anchor.
    local h, _, DelvesData = Start({ serverTime = dailyReset - 10 })

    local weeklyRuns = 0
    DelvesData:RegisterProvider({
        name = "WeeklyOnly",
        fields = {},
        resets = { "Weekly" },
        Refresh = function()
            weeklyRuns = weeklyRuns + 1
        end
    })
    h:Advance(1)
    T.Equals(weeklyRuns, 1, "refreshed on registration")

    h:Advance(dailyReset + 2 + 60 + 1 - h:ServerTime())
    T.Equals(weeklyRuns, 1, "a daily-only reset doesn't refresh it")

    h:Advance(weeklyReset + 2 + 5 + 1 - h:ServerTime())
    T.Equals(weeklyRuns, 2, "first refresh after the weekly reset")

    h:Advance(60)
    T.Equals(weeklyRuns, 3, "second refresh after the weekly reset")
    T.Equals(#h.errors, 0)
end)

Case("EnsureFresh respects the maximum age of the last full refresh", function()
    local h, _, DelvesData = Start()
    local before = h.calls.GetDelvesForMap

    h:Advance(10)
    T.False(DelvesData:EnsureFresh(30), "fresh enough")

    -- A partial refresh doesn't count as full.
    h:FireEvent("CRITERIA_EARNED", 40527)
    h:Advance(25)
    T.True(DelvesData:EnsureFresh(30), "older than 30 s")
    T.Equals(h.calls.GetDelvesForMap, before + 4)
    T.NotNil(DelvesData:GetLastUpdate())
end)
--#endregion

--#region Providers registration

Case("a failing provider doesn't break the others", function()
    local h, _, DelvesData = Start()

    DelvesData:RegisterProvider({
        name = "Faulty",
        fields = { "faultyField" },
        Refresh = function()
            error("boom")
        end
    })

    h.world.activeDelvePois[2214] = { 7784 }
    DelvesData:RefreshNow("test")

    T.True(DelvesData:Get(TAKRETHAN).isBountiful, "Poi provider still ran")
    T.True(#h.errors > 0 and string.find(h.errors[#h.errors], "boom", 1, true) ~= nil, "error reported")
end)

Case("providers can write only their own fields", function()
    local h, _, DelvesData = Start()

    DelvesData:RegisterProvider({
        name = "Rogue",
        fields = { "rogueField" },
        Refresh = function(_, _, ctx, records)
            ctx:Set(records[1], "isBountiful", true)
        end
    })
    DelvesData:RefreshNow("test", { providers = { "Rogue" } })

    T.True(string.find(h.errors[#h.errors] or "", "cannot write field", 1, true) ~= nil)
    T.True(DelvesData:Get(EARTHCRAWL).isBountiful, "unchanged (it was already true)")
    T.False(DelvesData:Get(TAKRETHAN).isBountiful)
end)

Case("RegisterProvider rejects duplicate and static fields", function()
    local _, _, DelvesData = Start()
    local refresh = function() end

    T.Errors(function()
        DelvesData:RegisterProvider({ name = "Dup", fields = { "isBountiful" }, Refresh = refresh })
    end, "already owned")
    T.Errors(function()
        DelvesData:RegisterProvider({ name = "Static", fields = { "delveName" }, Refresh = refresh })
    end, "static")
    T.Errors(function()
        DelvesData:RegisterProvider({ name = "Poi", fields = {}, Refresh = refresh })
    end, "already registered")
    T.Errors(function()
        DelvesData:RegisterProvider({ name = "BadReset", fields = {}, resets = { "Monthly" }, Refresh = refresh })
    end, "unknown reset period")
end)

Case("a provider registered after Init is initialized and refreshed", function()
    local h, addon, DelvesData = Start()
    local received = SpyUpdates(h, addon)

    DelvesData:RegisterProvider({
        name = "Extra",
        fields = { "extraFlag" },
        events = { "SOME_EVENT" },
        InitRecord = function(_, record)
            record.extraFlag = false
        end,
        Refresh = function(_, _, ctx, records)
            for _, record in ipairs(records) do
                ctx:Set(record, "extraFlag", true)
            end
        end
    })

    T.False(DelvesData:Get(EARTHCRAWL).extraFlag, "initialized")

    h:Advance(1)
    T.True(DelvesData:Get(EARTHCRAWL).extraFlag, "refreshed")
    T.KeysEqual(received[#received].fields, { "extraFlag" })

    T.True(h.frames[#h.frames].events["SOME_EVENT"] or false, "its events are registered")
end)
--#endregion
