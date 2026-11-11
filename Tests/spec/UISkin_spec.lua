---@diagnostic disable: undefined-global
local T, Harness = ...

local Case = T.Suite("UISkin")

--- The portable core. Loaded on its own, into a blank addon table: it must not need Delve Companion.
local CORE_DIR = "Source/Utility/UISkin/Core"
local CORE_FILES = { CORE_DIR .. "/UISkin.lua", CORE_DIR .. "/Ops.lua" }

--- Load the UISkin core only (no real adapters or recipes).
local function Start()
    local h = Harness.New()
    local addonTable = {}
    for _, file in ipairs(CORE_FILES) do
        h:LoadFile(file, "TestAddon", addonTable)
    end

    return h, addonTable.UISkin
end

--- Init options with skinning enabled in the (injected) saves.
local function Enabled(extra)
    local options = { savedVariables = { skinEnabled = true }, saveKey = "skinEnabled" }
    for key, value in pairs(extra or {}) do
        options[key] = value
    end
    return options
end

--- Fake suite adapter. `options.hosts[host] = false` disables a window.
local function FakeAdapter(options)
    options = options or {}

    local adapter = {
        id = options.id or "Fake",
        name = options.name or "Fake",
        available = options.available ~= false,
        hosts = options.hosts or {},
        readyNow = options.readyNow,
        registerError = options.registerError,
        registered = 0,
        accent = { 1, 0, 0 },
        tabSelections = {}
    }

    function adapter:IsAvailable()
        return self.available
    end

    function adapter:Register(onReady)
        self.registered = self.registered + 1
        if self.registerError then
            error(self.registerError)
        end

        self.onReady = onReady
        if self.readyNow then
            onReady()
        end
    end

    function adapter:IsHostEnabled(host)
        return self.hosts[host] ~= false
    end

    function adapter:GetTabLayout(host)
        if host == "journal" then
            return "TOPLEFT", "TOPRIGHT", -5, 0
        end
    end

    function adapter:SetTabSelected(tab, selected)
        self.tabSelections[#self.tabSelections + 1] = { tab, selected }
    end

    function adapter:OnLooksChanged(callback)
        self.onLooksChanged = callback
    end

    function adapter:GetAccentColor()
        return self.accent[1], self.accent[2], self.accent[3]
    end

    return adapter
end

--- Register a recipe that records the frames it was applied to.
local function Recorder(UISkin, name, host)
    local calls = {}
    UISkin:RegisterRecipe(name, host, function(skin, frame)
        calls[#calls + 1] = frame
    end)
    return calls
end

--- Texture stub recording its color.
local function FakeTexture()
    local texture = {}
    function texture:SetColorTexture(r, g, b, a)
        self.color = { r, g, b, a }
    end
    return texture
end

--#region Independence

Case("the core doesn't reference the host addon", function()
    local include = assert(io.open(Harness.root .. "/" .. CORE_DIR .. "/Include.xml", "r"))
    local files = {}
    for file in include:read("*a"):gmatch('file="([^"]+)"') do
        files[#files + 1] = CORE_DIR .. "/" .. file:gsub("\\", "/")
    end
    include:close()
    T.True(#files >= 4, "core files are listed in Include.xml")

    for _, file in ipairs(files) do
        local handle = assert(io.open(Harness.root .. "/" .. file, "r"))
        local source = handle:read("*a")
        handle:close()

        T.Nil(source:find("DelveCompanion", 1, true), file .. " references DelveCompanion")
    end
end)

Case("exports itself to the addon table only", function()
    local h, UISkin = Start()

    T.NotNil(UISkin)
    T.NotNil(UISkin.Ops, "Ops.lua attaches the shared operations")
    T.Nil(rawget(h.env, "UISkin"), "no global")
end)
--#endregion

--#region Settings

Case("stays off without an available UI suite", function()
    local _, UISkin = Start()
    local adapter = FakeAdapter({ available = false })
    UISkin:RegisterAdapter(adapter)
    local calls = Recorder(UISkin, "Panel")

    UISkin:Init(Enabled())
    UISkin:Apply("Panel", {})

    T.Equals(UISkin:GetState(), "none")
    T.Equals(adapter.registered, 0, "the suite is not hooked")
    T.Equals(#calls, 0)
    T.False(UISkin:IsActive())
    T.Nil(UISkin:GetAdapterName())
end)

Case("stays off when disabled under the injected save key", function()
    local _, UISkin = Start()
    local adapter = FakeAdapter()
    UISkin:RegisterAdapter(adapter)

    UISkin:Init({ savedVariables = { mySkin = false, skinEnabled = true }, saveKey = "mySkin" })

    T.Equals(UISkin:GetState(), "none")
    T.Equals(adapter.registered, 0)
end)

Case("an unset toggle uses the injected default", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter())

    UISkin:Init({ savedVariables = {}, saveKey = "skinEnabled", defaultEnabled = false })

    T.Equals(UISkin:GetState(), "none")
end)

Case("enabled by default (unset toggle, or no options at all)", function()
    local _, UISkin = Start()
    local adapter = FakeAdapter()
    UISkin:RegisterAdapter(adapter)
    UISkin:Init({ savedVariables = {}, saveKey = "skinEnabled" })
    T.Equals(UISkin:GetState(), "pending")
    T.Equals(adapter.registered, 1)

    local _, bare = Start()
    bare:RegisterAdapter(FakeAdapter())
    bare:Init()
    T.Equals(bare:GetState(), "pending")
end)

Case("initializes once", function()
    local _, UISkin = Start()
    local adapter = FakeAdapter()
    UISkin:RegisterAdapter(adapter)

    UISkin:Init(Enabled())
    UISkin:Init(Enabled())

    T.Equals(adapter.registered, 1)
end)
--#endregion

--#region Lifecycle

Case("queues requests until the suite is ready, then runs them in order", function()
    local _, UISkin = Start()
    local adapter = FakeAdapter()
    UISkin:RegisterAdapter(adapter)
    local calls = Recorder(UISkin, "Panel")
    local early, late, after = {}, {}, {}

    UISkin:Apply("Panel", early) -- Before Init.
    UISkin:Init(Enabled())
    UISkin:Apply("Panel", late)
    T.Equals(#calls, 0, "nothing runs while pending")

    adapter.onReady()
    T.True(UISkin:IsActive())
    T.ListEquals(calls, { early, late })

    UISkin:Apply("Panel", after)
    T.ListEquals(calls, { early, late, after }, "runs immediately once ready")
end)

Case("a suite ready during registration is used immediately", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ readyNow = true }))
    local calls = Recorder(UISkin, "Panel")
    local frame = {}

    UISkin:Init(Enabled())
    UISkin:Apply("Panel", frame)

    T.True(UISkin:IsActive())
    T.ListEquals(calls, { frame })
end)

Case("drops queued requests when the suite never reports ready", function()
    local h, UISkin = Start()
    local adapter = FakeAdapter()
    UISkin:RegisterAdapter(adapter)
    local calls = Recorder(UISkin, "Panel")

    UISkin:Init(Enabled()) -- Already logged in: the timeout starts now.
    UISkin:Apply("Panel", {})
    h:Advance(1)
    T.Equals(UISkin:GetState(), "pending", "still waiting shortly after login")

    h:Advance(10)
    T.Equals(UISkin:GetState(), "none")

    adapter.onReady()
    UISkin:Apply("Panel", {})
    T.Equals(UISkin:GetState(), "none", "a late ready is ignored")
    T.Equals(#calls, 0)
end)

Case("initialized before login, waits for PLAYER_LOGIN before giving up", function()
    local h, UISkin = Start()
    h.world.loggedIn = false
    UISkin:RegisterAdapter(FakeAdapter())

    UISkin:Init(Enabled())
    h:Advance(60)
    T.Equals(UISkin:GetState(), "pending", "no timeout before login")

    h:FireEvent("PLAYER_LOGIN")
    h:Advance(1)
    T.Equals(UISkin:GetState(), "pending", "still waiting shortly after login")

    h:Advance(10)
    T.Equals(UISkin:GetState(), "none")
end)

Case("the login timeout does nothing once ready", function()
    local h, UISkin = Start()
    local adapter = FakeAdapter()
    UISkin:RegisterAdapter(adapter)

    UISkin:Init(Enabled())
    adapter.onReady()
    h:Advance(10)

    T.True(UISkin:IsActive())
end)

Case("uses the first available adapter", function()
    local _, UISkin = Start()
    local missing = FakeAdapter({ name = "Missing", available = false })
    local first = FakeAdapter({ name = "First" })
    local second = FakeAdapter({ name = "Second" })
    UISkin:RegisterAdapter(missing)
    UISkin:RegisterAdapter(first)
    UISkin:RegisterAdapter(second)

    UISkin:Init(Enabled())

    T.Equals(UISkin:GetAdapterName(), "First")
    T.Equals(second.registered, 0)
end)

Case("a registration error turns skinning off", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ registerError = "no Skins module" }))
    local calls = Recorder(UISkin, "Panel")

    UISkin:Init(Enabled())
    UISkin:Apply("Panel", {})

    T.Equals(UISkin:GetState(), "none")
    T.Equals(#calls, 0)
end)
--#endregion

--#region Applying

Case("runs each recipe once per frame", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ readyNow = true }))
    local panelCalls = Recorder(UISkin, "Panel")
    local iconCalls = Recorder(UISkin, "Icon")
    local frame = {}

    UISkin:Init(Enabled())
    UISkin:Apply("Panel", frame)
    UISkin:Apply("Panel", frame)
    UISkin:Apply("Icon", frame)

    T.Equals(#panelCalls, 1, "a repeated request is a no-op")
    T.Equals(#iconCalls, 1, "another recipe on the same frame still runs")
end)

Case("a failing recipe doesn't propagate and isn't retried", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ readyNow = true }))
    local attempts = 0
    UISkin:RegisterRecipe("Boom", nil, function()
        attempts = attempts + 1
        error("API changed")
    end)
    local calls = Recorder(UISkin, "Panel")
    local frame = {}

    UISkin:Init(Enabled())
    UISkin:Apply("Boom", frame)
    UISkin:Apply("Boom", frame)
    UISkin:Apply("Panel", frame)

    T.Equals(attempts, 1)
    T.NotNil(string.find(UISkin:GetFailure("Boom"), "API changed", 1, true), "the error is kept for debugging")
    T.Equals(#calls, 1, "other recipes keep working")
end)

Case("logs through the injected function", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ readyNow = true }))
    UISkin:RegisterRecipe("Boom", nil, function()
        error("100% broken") -- `%` in the message must survive formatting.
    end)
    local messages = {}

    UISkin:Init(Enabled({
        log = function(message)
            messages[#messages + 1] = message
        end
    }))
    UISkin:Apply("Boom", {})

    T.Equals(messages[1], "[UISkin] Using Fake skin.")
    T.NotNil(messages[2] and string.find(messages[2], "Recipe `Boom` failed: .*100%% broken"), "recipe failure")
end)

Case("skips recipes for windows the suite doesn't skin", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ readyNow = true, hosts = { picker = false } }))
    local journalCalls = Recorder(UISkin, "JournalButton", "journal")
    local pickerCalls = Recorder(UISkin, "PickerButton", "picker")

    UISkin:Init(Enabled())
    UISkin:Apply("JournalButton", {})
    UISkin:Apply("PickerButton", {})

    T.Equals(#journalCalls, 1)
    T.Equals(#pickerCalls, 0)
    T.True(UISkin:IsHostActive("journal"))
    T.False(UISkin:IsHostActive("picker"))
end)

--- Register per-suite variants that record which one ran.
local function VariantRecorder(UISkin, name, ids)
    local ran = {}
    local variants = {}
    for _, id in ipairs(ids) do
        variants[id] = function()
            ran[#ran + 1] = id
        end
    end
    UISkin:RegisterRecipe(name, nil, variants)
    return ran
end

Case("runs the active suite's variant of a recipe", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ id = "ElvUI", readyNow = true }))
    local ran = VariantRecorder(UISkin, "Button", { "default", "ElvUI", "EllesmereUI" })

    UISkin:Init(Enabled())
    UISkin:Apply("Button", {})

    T.ListEquals(ran, { "ElvUI" })
end)

Case("falls back to the default variant", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ id = "EllesmereUI", readyNow = true }))
    local ran = VariantRecorder(UISkin, "Button", { "default", "ElvUI" })

    UISkin:Init(Enabled())
    UISkin:Apply("Button", {})

    T.ListEquals(ran, { "default" })
end)

Case("skips a recipe without a variant for the suite", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ id = "EllesmereUI", readyNow = true }))
    local ran = VariantRecorder(UISkin, "Button", { "ElvUI" })
    local frame = {}

    UISkin:Init(Enabled())
    UISkin:Apply("Button", frame)
    UISkin:Apply("Button", frame)

    T.Equals(#ran, 0)
    T.Nil(UISkin:GetFailure("Button"), "not an error")
end)

Case("rejects a recipe that is neither a function nor variants", function()
    local _, UISkin = Start()

    T.Errors(function()
        UISkin:RegisterRecipe("Broken", nil, "Panel")
    end, "must be a function or a table")
end)

Case("exposes the supported suite ids", function()
    local _, UISkin = Start()

    T.Equals(UISkin.Suite.ElvUI, "ElvUI")
    T.Equals(UISkin.Suite.EllesmereUI, "EllesmereUI")
end)

Case("ignores unknown recipes and nil frames", function()
    local _, UISkin = Start()
    UISkin:RegisterAdapter(FakeAdapter({ readyNow = true }))
    local calls = Recorder(UISkin, "Panel")

    UISkin:Init(Enabled())
    UISkin:Apply("Missing", {})
    UISkin:Apply("Panel", nil)

    T.Equals(#calls, 0)
end)

Case("accent textures follow live theme changes", function()
    local _, UISkin = Start()
    local adapter = FakeAdapter({ readyNow = true })
    UISkin:RegisterAdapter(adapter)
    local texture = FakeTexture()
    UISkin:RegisterRecipe("Thumb", nil, function()
        UISkin:PaintAccent(texture, 0.8)
    end)

    UISkin:Init(Enabled())
    UISkin:Apply("Thumb", {})
    T.ListEquals(texture.color, { 1, 0, 0, 0.8 })

    adapter.accent = { 0, 1, 0 }
    adapter.onLooksChanged()
    T.ListEquals(texture.color, { 0, 1, 0, 0.8 }, "repainted, alpha kept")
end)
--#endregion

--#region Tabs

Case("tab layout follows the suite only while it skins the window", function()
    local _, UISkin = Start()
    local adapter = FakeAdapter()
    UISkin:RegisterAdapter(adapter)
    UISkin:Init(Enabled())

    T.Nil(UISkin:GetTabLayout("journal", {}), "no layout while pending: the caller uses its own")

    adapter.onReady()
    local point, relativePoint, x, y = UISkin:GetTabLayout("journal", {})
    T.ListEquals({ point, relativePoint, x, y }, { "TOPLEFT", "TOPRIGHT", -5, 0 })
    T.Nil(UISkin:GetTabLayout("settings", {}), "no layout for a window the suite has none for")

    adapter.hosts.journal = false
    T.Nil(UISkin:GetTabLayout("journal", {}), "no layout when the window skin is off")
end)

Case("tab selection is forwarded only while the suite skins the window", function()
    local _, UISkin = Start()
    local adapter = FakeAdapter({ readyNow = true, hosts = { picker = false } })
    UISkin:RegisterAdapter(adapter)
    UISkin:Init(Enabled())
    local tab = {}

    UISkin:SetTabSelected("journal", tab, true)
    UISkin:SetTabSelected("picker", tab, false)

    T.Equals(#adapter.tabSelections, 1)
    T.ListEquals(adapter.tabSelections[1], { tab, true })
end)
--#endregion
