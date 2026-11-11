local addonName, AddonTbl = ...

---@type UISkin
local UISkin = AddonTbl.UISkin

--#region Constants

--- ElvUI per-window toggles in `E.private.skins.blizzard`, matching the windows addon frames live in.
---@type table<UISkinHost, string>
local HOST_TOGGLES = {
    [UISkin.Host.journal] = "encounterjournal",
    [UISkin.Host.picker] = "lfg", -- ElvUI skins the Delves difficulty picker and companion frames under `lfg`.
    [UISkin.Host.settings] = "blizzardOptions"
}

--- ElvUI's own tab chains (e.g. `RepositionTabs` in its EncounterJournal skin), per window.
---@type table<UISkinHost, {point: FramePoint, relativePoint: FramePoint, x: number, y: number}>
local TAB_LAYOUTS = {
    [UISkin.Host.journal] = { point = "TOPLEFT", relativePoint = "TOPRIGHT", x = -5, y = 0 }
}

--- Highlight used by ElvUI for the Encounter Journal instance buttons.
local HIGHLIGHT_COLOR = { r = 0.8, g = 0.8, b = 0.8, a = 0.25 }

--- Name of the Skins module callback. The addon's folder name: unique per addon using this core.
---@type string
local CALLBACK_NAME = addonName
--#endregion

--- [ElvUI](https://github.com/tukui-org/ElvUI) adapter. Built on its Skins module (`E:GetModule("Skins")`).
---@class (exact) UISkinElvUIAdapter : UISkinAdapter
---@field E table? ElvUI engine, set once ready.
---@field S table? ElvUI Skins module, set once ready.
local Adapter = {
    id = UISkin.Suite.ElvUI,
    name = "ElvUI"
}

---@return table|nil engine
local function GetEngine()
    local elv = _G["ElvUI"]
    return type(elv) == "table" and elv[1] or nil
end

---@param self UISkinElvUIAdapter
function Adapter:IsAvailable()
    local engine = GetEngine()
    return engine ~= nil and type(engine.GetModule) == "function"
end

---@param self UISkinElvUIAdapter
---@param onReady fun()
function Adapter:Register(onReady)
    local engine = GetEngine()
    local skins = engine:GetModule("Skins", true)
    if not (skins and skins.AddCallback) then
        error("ElvUI Skins module is not available")
    end

    local function Ready()
        self.E = engine
        self.S = skins
        onReady()
    end

    -- Callbacks added before the Skins module initializes are run by it. Later ones are not, so run them here.
    if skins.Initialized then
        Ready()
    else
        skins:AddCallback(CALLBACK_NAME, Ready)
    end
end

---@param self UISkinElvUIAdapter
---@param host UISkinHost?
---@return boolean
function Adapter:IsHostEnabled(host)
    local private = self.E and self.E.private
    local blizzard = private and private.skins and private.skins.blizzard
    if blizzard == nil then
        -- Unknown settings layout: follow the user's choice of running ElvUI.
        return true
    end

    if blizzard.enable == false then
        return false
    end

    local toggle = host and HOST_TOGGLES[host]
    return toggle == nil or blizzard[toggle] ~= false
end

---@param self UISkinElvUIAdapter
function Adapter:GetTabLayout(host, tab)
    local layout = TAB_LAYOUTS[host]
    if not layout then
        return nil
    end

    return layout.point, layout.relativePoint, layout.x, layout.y
end

---@param self UISkinElvUIAdapter
function Adapter:Window(frame)
    if self.S.HandlePortraitFrame then
        self.S:HandlePortraitFrame(frame)
    else
        frame:StripTextures()
        frame:SetTemplate("Transparent")
    end
end

---@param self UISkinElvUIAdapter
function Adapter:Panel(frame)
    frame:CreateBackdrop("Transparent")
end

---@param self UISkinElvUIAdapter
function Adapter:StripPanel(frame, opaque)
    frame:StripTextures()
    if opaque then
        frame:SetTemplate()
    else
        frame:SetTemplate("Transparent")
    end
end

---@param self UISkinElvUIAdapter
function Adapter:Inset(frame)
    if frame.NineSlice then
        frame.NineSlice:SetAlpha(0)
    end
    self:StripPanel(frame)
end

---@param self UISkinElvUIAdapter
function Adapter:Button(button)
    self.S:HandleButton(button)
end

---@param self UISkinElvUIAdapter
function Adapter:Tab(tab)
    self.S:HandleTab(tab)
end

---@param self UISkinElvUIAdapter
function Adapter:CloseButton(button)
    self.S:HandleCloseButton(button)
end

---@param self UISkinElvUIAdapter
function Adapter:Checkbox(checkbox)
    self.S:HandleCheckBox(checkbox)
end

---@param self UISkinElvUIAdapter
function Adapter:ScrollBar(scrollBar)
    self.S:HandleTrimScrollBar(scrollBar)
end

---@param self UISkinElvUIAdapter
function Adapter:Icon(icon, parent)
    self.S:HandleIcon(icon, true)
end

---@param self UISkinElvUIAdapter
function Adapter:IconQualityBorder(border, icon)
    local backdrop = icon.backdrop
    if not (backdrop and self.S.HandleIconBorder) then
        return
    end

    -- `HandleIconBorder` hides the ring, so check it first.
    local shown = border:IsShown()
    self.S:HandleIconBorder(border, backdrop)

    -- It copies the ring's color even when the ring is hidden, and a ring that was never colored reports white
    -- (e.g. widgets without a quality). Use the default border until the addon colors or shows the ring:
    -- ElvUI's hooks follow those changes.
    if not shown then
        local color = self.E.media and self.E.media.bordercolor
        if type(color) == "table" then
            backdrop:SetBackdropBorderColor(unpack(color))
        end
    end
end

---@param self UISkinElvUIAdapter
function Adapter:StatusBar(bar)
    -- ElvUI's status bar texture and default fill color, on a backdrop.
    self.S:HandleStatusBar(bar)
end

---@param self UISkinElvUIAdapter
function Adapter:Font(fontString)
    -- Nothing to do: ElvUI restyles text through the Blizzard font objects ("Replace Blizzard Fonts").
end

---@param self UISkinElvUIAdapter
function Adapter:TextColor(fontString)
    -- Nothing to do: ElvUI's Blizzard window skins keep the stock text colors.
end

---@param self UISkinElvUIAdapter
function Adapter:GetAccentColor()
    local color = self.E.media and self.E.media.rgbvaluecolor
    if type(color) == "table" then
        return color.r or color[1], color.g or color[2], color.b or color[3]
    end

    return _G["NORMAL_FONT_COLOR"]:GetRGB()
end

---@param self UISkinElvUIAdapter
function Adapter:GetHighlightColor()
    return HIGHLIGHT_COLOR.r, HIGHLIGHT_COLOR.g, HIGHLIGHT_COLOR.b, HIGHLIGHT_COLOR.a
end

UISkin:RegisterAdapter(Adapter)
