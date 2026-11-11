local _, AddonTbl = ...

---@type UISkin
local UISkin = AddonTbl.UISkin

--- Shared operations for recipes and adapters. Suite-agnostic: plain WoW API only.
---@class UISkinOps
local Ops = {}
UISkin.Ops = Ops

--- Hide regions that Blizzard code or the addon may show again later. `nil` entries are skipped.
---@param ... Region?
function Ops.HideRegions(...)
    for index = 1, select("#", ...) do
        local region = select(index, ...)
        if region then
            region:SetAlpha(0)
        end
    end
end

--- Create a frame behind `parent`, covering `region` plus `outset` pixels, for a backdrop that must not cover
--- or fade the parent's own textures.
---@param parent Frame
---@param region Region
---@param outset number
---@return Frame
function Ops.CreateHolder(parent, region, outset)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("TOPLEFT", region, "TOPLEFT", -outset, outset)
    holder:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", outset, -outset)
    holder:SetFrameLevel(math.max(0, parent:GetFrameLevel() - 1))

    return holder
end

--- Replace a button highlight with a flat overlay covering `region`.
---@param skin UISkinAdapter
---@param button Button
---@param region Region
function Ops.FlatHighlight(skin, button, region)
    local highlight = button:GetHighlightTexture()
    if not highlight then
        return
    end

    highlight:SetColorTexture(skin:GetHighlightColor())
    highlight:ClearAllPoints()
    highlight:SetPoint("TOPLEFT", region, "TOPLEFT")
    highlight:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT")
end
