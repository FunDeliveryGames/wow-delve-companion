local _, AddonTbl = ...

--- UISkin core: restyles an addon's frames to match a supported UI suite (ElvUI, EllesmereUI). Does nothing without one.
---
--- This folder (`Core`) is portable: it is copied verbatim into every addon that uses it. It must never reference the
--- host addon (its namespace, saved variables, logger, config). Everything addon-specific is injected through `Init`
--- or registered as recipes. Change it in one copy, then copy it to the others. See `README.md`.

--#region Constants

--- Seconds after PLAYER_LOGIN to wait for the selected adapter. Both supported suites report by PLAYER_LOGIN.
--- Requests made in the meantime are queued, so a generous value costs nothing.
---@type number
local READY_TIMEOUT_SEC = 5

---@type string
local LOG_PREFIX = "[UISkin] "
--#endregion

--#region Types

---@alias UISkinState "pending"|"ready"|"none"

--- Stable id of a supported UI suite (`UISkin.Suite`). Keys per-suite recipe variants.
---@alias UISkinSuite "ElvUI"|"EllesmereUI"

--- Blizzard window a recipe's frame lives in. Adapters use it to follow the suite's own per-window toggles,
--- so addon frames are skinned exactly when the window around them is. `standalone` = the addon's own windows.
--- To add a host: add it to `UISkin.Host` and map it in the adapters that have per-window toggles (ElvUI).
---@alias UISkinHost "journal"|"picker"|"standalone"|"settings"

--- Contract implemented by each UI suite adapter (`Core/Adapters`).
---@class UISkinAdapter
---@field id UISkinSuite
---@field name string Display name of the suite.
---@field IsAvailable fun(self: UISkinAdapter): boolean The suite is loaded and exposes its skinning API.
---@field Register fun(self: UISkinAdapter, onReady: fun()) Hook into the suite. `onReady` is called once its API can be used.
---@field IsHostEnabled fun(self: UISkinAdapter, host: UISkinHost?): boolean Whether the suite skins the given window.
---@field GetTabLayout fun(self: UISkinAdapter, host: UISkinHost, tab: Frame): FramePoint?, FramePoint?, number?, number? Tab chain the suite keeps in a window. `nil`: the suite doesn't keep its own chain there.
---@field OnLooksChanged fun(self: UISkinAdapter, callback: fun())? Live theme changes.
---@field Window fun(self: UISkinAdapter, frame: Frame) A top-level window (DefaultPanelTemplate etc.).
---@field Panel fun(self: UISkinAdapter, frame: Frame) A backdrop drawn behind the frame. Its own textures are kept.
---@field StripPanel fun(self: UISkinAdapter, frame: Frame, opaque: boolean?) Remove the frame's own art and make it a panel.
---@field Inset fun(self: UISkinAdapter, frame: Frame) A frame inheriting InsetFrameTemplate*.
---@field Button fun(self: UISkinAdapter, button: Button)
---@field Tab fun(self: UISkinAdapter, tab: Button)
---@field SetTabSelected fun(self: UISkinAdapter, tab: Button, selected: boolean)?
---@field CloseButton fun(self: UISkinAdapter, button: Button)
---@field Checkbox fun(self: UISkinAdapter, checkbox: CheckButton)
---@field ScrollBar fun(self: UISkinAdapter, scrollBar: Frame) MinimalScrollBar / WowTrimScrollBar.
---@field Icon fun(self: UISkinAdapter, icon: Texture, parent: Frame) Square crop with a thin border.
---@field IconQualityBorder fun(self: UISkinAdapter, border: Texture, icon: Texture) The icon's border follows this quality ring (shown + vertex color). Call after `Icon`.
---@field StatusBar fun(self: UISkinAdapter, bar: StatusBar) Flat bar with the suite's own fill color and backdrop.
---@field Font fun(self: UISkinAdapter, fontString: FontString) The suite's UI font, same size.
---@field TextColor fun(self: UISkinAdapter, fontString: FontString) The text color the suite uses in its windows.
---@field GetAccentColor fun(self: UISkinAdapter): number, number, number
---@field GetHighlightColor fun(self: UISkinAdapter): number, number, number, number

--- Restyles one kind of addon frame. `frame` is the addon frame the recipe is written for.
---@alias UISkinRecipeFn fun(skin: UISkinAdapter, frame: any)

--- Per-suite versions of a recipe, keyed by `UISkin.Suite`. `default` serves the suites without their own version.
--- A suite with neither doesn't get the recipe.
---@alias UISkinRecipeVariants table<UISkinSuite|"default", UISkinRecipeFn>

---@class (exact) UISkinRecipe
---@field host UISkinHost?
---@field fn UISkinRecipeFn? Shared by all suites.
---@field variants UISkinRecipeVariants? Set instead of `fn`.

--- Injected by the host addon on `Init`.
---@class UISkinOptions
---@field savedVariables table? Table holding the on/off toggle. Read once, on `Init`.
---@field saveKey string? Key of the toggle in `savedVariables`.
---@field defaultEnabled boolean? Used when the toggle is unset. Default: `true`.
---@field log fun(message: string)? Debug output. Messages are already formatted. Default: none.
--#endregion

--#region Private data

---@class (exact) UISkinPrivate
---@field initialized boolean
---@field state UISkinState
---@field adapter UISkinAdapter? Selected adapter.
---@field adapters UISkinAdapter[] Registered adapters, in priority order.
---@field recipes table<string, UISkinRecipe>
---@field queue {[1]: string, [2]: Frame}[] Requests made before the adapter was ready.
---@field skinned table<Frame, table<string, boolean>> Recipes already applied per frame (weak keys).
---@field accentTextures table<Texture, number> Textures painted with the accent color, and their alpha (weak keys).
---@field failures table<string, string> Last error per recipe.
---@field log fun(message: string)?
local private = {
    initialized = false,
    state = "pending",
    adapter = nil,
    adapters = {},
    recipes = {},
    queue = {},
    skinned = setmetatable({}, { __mode = "k" }),
    accentTextures = setmetatable({}, { __mode = "k" }),
    failures = {},
    log = nil
}

---@param message string Format string.
---@param ... any
local function Log(message, ...)
    local log = private.log
    if not log then
        return
    end

    local ok, formatted = pcall(string.format, message, ...)
    pcall(log, LOG_PREFIX .. (ok and formatted or tostring(message)))
end
--#endregion

--- Public interface. Exported as `AddonTbl.UISkin`: private to the addon, so every addon has its own copy.
---
--- Usage: register recipes (`RegisterRecipe`), call `Init` on ADDON_LOADED, then `Apply(recipe, frame)` where frames
--- are created. A recipe is one function written against the adapter contract (`UISkinAdapter`), shared by every
--- suite. Only where suites genuinely need different treatment, register per-suite variants instead.
---@class (exact) UISkin
---@field Host table<string, UISkinHost>
---@field Suite table<string, UISkinSuite>
---@field Ops UISkinOps Shared operations for recipes and adapters (`Ops.lua`).
local UISkin = {
    Host = {
        journal = "journal",
        picker = "picker",
        standalone = "standalone",
        settings = "settings"
    },
    Suite = {
        ElvUI = "ElvUI",
        EllesmereUI = "EllesmereUI"
    },
    Ops = nil
}
AddonTbl.UISkin = UISkin

--#region Internals

local function Drop()
    private.state = "none"
    private.queue = {}
end

---@param texture Texture
---@param alpha number
local function Paint(texture, alpha)
    local r, g, b = private.adapter:GetAccentColor()
    texture:SetColorTexture(r, g, b, alpha)
end

local function RepaintAccent()
    for texture, alpha in pairs(private.accentTextures) do
        pcall(Paint, texture, alpha)
    end
end

---@param recipeName string
---@param frame Frame
local function Run(recipeName, frame)
    local recipe = private.recipes[recipeName]
    if not recipe then
        Log("Unknown recipe: %s", tostring(recipeName))
        return
    end

    local done = private.skinned[frame]
    if done and done[recipeName] then
        return
    end

    local adapter = private.adapter
    if not adapter then
        return
    end

    local okHost, hostEnabled = pcall(adapter.IsHostEnabled, adapter, recipe.host)
    if not (okHost and hostEnabled) then
        return
    end

    -- Marked before running, so a failing recipe isn't retried on every refresh.
    done = done or {}
    done[recipeName] = true
    private.skinned[frame] = done

    local variants = recipe.variants
    local fn = recipe.fn or (variants and (variants[adapter.id] or variants.default))
    if not fn then
        return -- This suite has no version of the recipe.
    end

    local ok, err = xpcall(function()
        fn(adapter, frame)
    end, function(message)
        return message
    end)

    if not ok then
        private.failures[recipeName] = tostring(err)
        Log("Recipe `%s` failed: %s", recipeName, tostring(err))
    end
end

--- Bound to the selected adapter on registration, so no other adapter can make the skin ready.
---@param adapter UISkinAdapter
local function OnAdapterReady(adapter)
    if private.state ~= "pending" or adapter ~= private.adapter then
        return
    end

    private.state = "ready"
    -- Log("Using %s skin.", adapter.name)

    if adapter.OnLooksChanged then
        pcall(adapter.OnLooksChanged, adapter, RepaintAccent)
    end

    local queue = private.queue
    private.queue = {}
    for _, request in ipairs(queue) do
        Run(request[1], request[2])
    end
end

--- Stop waiting for the adapter once the login has settled.
local function StartReadyTimeout()
    C_Timer.After(READY_TIMEOUT_SEC, function()
        if private.state == "pending" then
            Log("%s did not report ready. Skinning is off.", private.adapter and private.adapter.name or "No UI suite")
            Drop()
        end
    end)
end

local function StartReadyTimeoutOnLogin()
    if IsLoggedIn() then
        StartReadyTimeout()
        return
    end

    local loginFrame = CreateFrame("Frame")
    loginFrame:RegisterEvent("PLAYER_LOGIN")
    loginFrame:SetScript("OnEvent", function(frame)
        frame:UnregisterEvent("PLAYER_LOGIN")
        frame:SetScript("OnEvent", nil)
        StartReadyTimeout()
    end)
end

---@param options UISkinOptions
---@return boolean
local function IsEnabled(options)
    local save, key = options.savedVariables, options.saveKey
    if type(save) == "table" and key ~= nil and save[key] ~= nil then
        return save[key] == true
    end

    return options.defaultEnabled ~= false
end
--#endregion

--#region Registration

--- Register a UI suite adapter. The first available one (in registration order) is used.
---@param self UISkin
---@param adapter UISkinAdapter
function UISkin:RegisterAdapter(adapter)
    private.adapters[#private.adapters + 1] = adapter
end

--- Register a recipe applied with `Apply`.
---
--- `recipe` is one function for all suites, or per-suite variants:
--- `{ [UISkin.Suite.ElvUI] = fn, default = fn }`. Put the steps the variants share in a local helper.
---@param self UISkin
---@param name string
---@param host UISkinHost? Window the frames live in. `nil`: depends only on the suite's global toggle.
---@param recipe UISkinRecipeFn|UISkinRecipeVariants
function UISkin:RegisterRecipe(name, host, recipe)
    local recipeType = type(recipe)
    assert(recipeType == "function" or recipeType == "table",
        "UISkin:RegisterRecipe: `recipe` must be a function or a table of per-suite variants")

    if recipeType == "function" then
        private.recipes[name] = { host = host, fn = recipe }
    else
        private.recipes[name] = { host = host, variants = recipe }
    end
end
--#endregion

--#region Lifecycle

--- Select an adapter and hook into its suite. Call once on ADDON_LOADED, once the saved variables are ready.
--- Requests made earlier are queued. The adapter is given up 5 s after PLAYER_LOGIN if it doesn't report ready
--- (e.g. EllesmereUI skinning is off for this addon).
---@param self UISkin
---@param options UISkinOptions?
function UISkin:Init(options)
    if private.initialized then
        return
    end
    private.initialized = true

    options = options or {}
    assert(type(options) == "table", "UISkin:Init: `options` must be a table")
    private.log = type(options.log) == "function" and options.log or nil

    if not IsEnabled(options) then
        Drop()
        return
    end

    for _, adapter in ipairs(private.adapters) do
        local ok, isAvailable = pcall(adapter.IsAvailable, adapter)
        if ok and isAvailable then
            private.adapter = adapter
            break
        end
    end

    local adapter = private.adapter
    if not adapter then
        Drop()
        return
    end

    local ok, err = pcall(adapter.Register, adapter, function()
        OnAdapterReady(adapter)
    end)

    if not ok then
        Log("%s registration failed: %s", adapter.name, tostring(err))
        Drop()
        return
    end

    if private.state == "pending" then
        StartReadyTimeoutOnLogin()
    end
end
--#endregion

--#region Applying

--- Restyle `frame` with a recipe. Safe to call repeatedly (e.g. for pooled frames): each recipe runs once per frame.
---@param self UISkin
---@param recipeName string
---@param frame Frame?
function UISkin:Apply(recipeName, frame)
    local state = private.state
    if state == "none" or frame == nil then
        return
    end

    if state == "pending" then
        private.queue[#private.queue + 1] = { recipeName, frame }
        return
    end

    Run(recipeName, frame)
end

--- Paint a texture with the suite's accent color, and keep it in sync with live theme changes.
---@param self UISkin
---@param texture Texture
---@param alpha number?
function UISkin:PaintAccent(texture, alpha)
    if not private.adapter then
        return
    end

    alpha = alpha or 1
    private.accentTextures[texture] = alpha
    Paint(texture, alpha)
end
--#endregion

--#region Queries and helpers for modules

--- Whether a UI suite skin is in use.
---@param self UISkin
---@return boolean
function UISkin:IsActive()
    return private.state == "ready"
end

--- Whether a UI suite skin is in use and the suite skins the given window.
---@param self UISkin
---@param host UISkinHost?
---@return boolean
function UISkin:IsHostActive(host)
    local adapter = private.adapter
    if not (adapter and self:IsActive()) then
        return false
    end

    local ok, enabled = pcall(adapter.IsHostEnabled, adapter, host)
    return ok and enabled == true
end

---@param self UISkin
---@return UISkinState
function UISkin:GetState()
    return private.state
end

--- Name of the selected suite adapter, even while it's pending. `nil` if none was selected.
---@param self UISkin
---@return string?
function UISkin:GetAdapterName()
    return private.adapter and private.adapter.name or nil
end

--- Last error of a recipe, for debugging.
---@param self UISkin
---@param recipeName string
---@return string?
function UISkin:GetFailure(recipeName)
    return private.failures[recipeName]
end

--- How the suite chains the tabs of a window: `tab:SetPoint(point, previousTab, relativePoint, x, y)`.
--- Suites re-anchor the stock tabs of the windows they skin, so tabs added by the addon must follow them.
---@param self UISkin
---@param host UISkinHost Window the tabs belong to.
---@param tab Frame Used for pixel-exact spacing.
---@return FramePoint? point `nil` when no suite restyles the window: the caller uses its own layout.
---@return FramePoint? relativePoint
---@return number? x
---@return number? y
function UISkin:GetTabLayout(host, tab)
    local adapter = private.adapter
    if not (adapter and adapter.GetTabLayout and self:IsHostActive(host)) then
        return nil
    end

    local ok, point, relativePoint, x, y = pcall(adapter.GetTabLayout, adapter, host, tab)
    if ok and point then
        return point, relativePoint, x, y
    end

    return nil
end

--- Force the selected look of a tab the addon switches itself.
---@param self UISkin
---@param host UISkinHost Window the tab belongs to.
---@param tab Button
---@param selected boolean
function UISkin:SetTabSelected(host, tab, selected)
    local adapter = private.adapter
    if not (adapter and adapter.SetTabSelected and self:IsHostActive(host)) then
        return
    end

    pcall(adapter.SetTabSelected, adapter, tab, selected)
end
--#endregion
