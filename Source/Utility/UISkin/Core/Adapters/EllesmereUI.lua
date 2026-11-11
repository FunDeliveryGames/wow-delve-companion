local addonName, AddonTbl = ...

---@type UISkin
local UISkin = AddonTbl.UISkin

local Ops = UISkin.Ops

--#region Constants

--- Highlight alpha over a white overlay. EllesmereUI doesn't define a hover color for custom buttons.
local HIGHLIGHT_ALPHA = 0.15

--- Fill texture of EllesmereUI's own flat bars. `S.ApplyBarFill` only colors the fill.
local FLAT_BAR_TEXTURE = "Interface\\Buttons\\WHITE8X8"
--#endregion

--- [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI) adapter. Built on its public skinning API
--- (`EllesmereUI.RegisterSkin`, see its SKINNING_API.md). The callback runs only while the user keeps skinning
--- enabled for this addon (EUI options > Blizzard Skins+ > Window Skins > Third-Party Addons).
---@class (exact) UISkinEllesmereUIAdapter : UISkinAdapter
---@field S table? EllesmereUI skin API object, set once ready.
local Adapter = {
    id = UISkin.Suite.EllesmereUI,
    name = "EllesmereUI"
}

---@return table|nil
local function GetSuite()
    local suite = _G["EllesmereUI"]
    return type(suite) == "table" and suite or nil
end

---@param self UISkinEllesmereUIAdapter
function Adapter:IsAvailable()
    local suite = GetSuite()
    return suite ~= nil and type(suite.RegisterSkin) == "function"
end

---@param self UISkinEllesmereUIAdapter
---@param onReady fun()
function Adapter:Register(onReady)
    -- Registered under the addon's folder name, as the API asks: unique per addon using this core.
    GetSuite().RegisterSkin(addonName, function(skinApi)
        self.S = skinApi
        onReady()
    end)
end

---@param self UISkinEllesmereUIAdapter
---@param host UISkinHost?
---@return boolean
function Adapter:IsHostEnabled(host)
    local S = self.S
    if not S then
        return false
    end

    return S.IsEnabled == nil or S.IsEnabled() == true
end

---@param self UISkinEllesmereUIAdapter
function Adapter:GetTabLayout(host, tab)
    -- No chain of its own to follow: EllesmereUI re-chains a window's tabs with a 1 pixel seam once, when it skins the
    -- window, but Blizzard re-anchors the Encounter Journal tabs with its stock offsets on every show. The stock
    -- spacing is what the user sees.
    return nil
end

---@param self UISkinEllesmereUIAdapter
function Adapter:OnLooksChanged(callback)
    if self.S.OnLooksChanged then
        self.S.OnLooksChanged(callback)
    end
end

---@param self UISkinEllesmereUIAdapter
function Adapter:Window(frame)
    self.S.Shell(frame)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:Panel(frame)
    self.S.Panel(frame)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:StripPanel(frame, opaque)
    self.S.FadeRegions(frame)
    if frame.NineSlice and self.S.FadeNineSlice then
        self.S.FadeNineSlice(frame.NineSlice)
    end
    self.S.Panel(frame)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:Inset(frame)
    self.S.Inset(frame)
    self.S.Panel(frame)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:Button(button)
    self.S.Button(button)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:Tab(tab)
    self.S.Tab(tab)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:SetTabSelected(tab, selected)
    if self.S.SetTabSelection then
        self.S.SetTabSelection(tab, selected)
    end
end

---@param self UISkinEllesmereUIAdapter
function Adapter:CloseButton(button)
    self.S.CloseButton(button)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:Checkbox(checkbox)
    self.S.Checkbox(checkbox)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:ScrollBar(scrollBar)
    self.S.ScrollBar(scrollBar)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:Icon(icon, parent)
    -- EllesmereUI reads an icon's quality off its parent's `IconBorder` ring. Such icons get its square quality border
    -- (black until a quality shows) instead of the plain black one, so `IconQualityBorder` never stacks a second
    -- border: plain 1px textures can round to 2px at fractional scales and would show around the quality one.
    self.S.SquareIcon(icon, parent, parent ~= nil and parent["IconBorder"] ~= nil)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:IconQualityBorder(border, icon)
    local owner = border:GetParent()
    if not (owner and owner["IconBorder"] == border) then
        return -- EllesmereUI reads the quality from `IconBorder` only: the stock ring is kept.
    end

    -- Blizzard's ring is round and drawn for an uncropped icon: the squared icon sticks out of it, so EllesmereUI
    -- replaces it with its square border. The ring stays shown and colored (only faded), as both drive that border.
    border:SetAlpha(0)

    -- EllesmereUI follows `SetItemButtonQuality` only. The addon sets the ring directly, so repaint on its changes.
    -- Calling `SquareIcon` again repaints the existing border.
    local S = self.S --[[@as table]]
    local function Repaint()
        S.SquareIcon(icon, owner, true)
    end

    for _, method in ipairs({ "SetVertexColor", "Show", "Hide", "SetShown" }) do
        hooksecurefunc(border, method, Repaint)
    end
    Repaint()
end

---@param self UISkinEllesmereUIAdapter
function Adapter:StatusBar(bar)
    bar:SetStatusBarTexture(FLAT_BAR_TEXTURE)
    if self.S.ApplyBarFill then
        self.S.ApplyBarFill(bar) -- The house fill color, kept in sync with live theme changes.
    end

    -- `S.Panel` fades every texture of the frame it is given and keeps them faded on EllesmereUI's restrips.
    -- The bar's fill is one of its textures, so the backdrop goes on a holder behind the bar instead.
    self.S.Panel(Ops.CreateHolder(bar, bar, 1))
end

---@param self UISkinEllesmereUIAdapter
function Adapter:Font(fontString)
    self.S.Font(fontString)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:TextColor(fontString)
    self.S.White(fontString)
end

---@param self UISkinEllesmereUIAdapter
function Adapter:GetAccentColor()
    if self.S.GetAccentColor then
        return self.S.GetAccentColor()
    end

    return _G["NORMAL_FONT_COLOR"]:GetRGB()
end

---@param self UISkinEllesmereUIAdapter
function Adapter:GetHighlightColor()
    return 1, 1, 1, HIGHLIGHT_ALPHA
end

UISkin:RegisterAdapter(Adapter)
