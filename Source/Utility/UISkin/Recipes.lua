local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type UISkin
local UISkin = AddonTbl.UISkin
DelveCompanion.UISkin = UISkin -- Modules reach the core through the addon namespace.

local Host = UISkin.Host
local Suite = UISkin.Suite
local Ops = UISkin.Ops

--- Delve Companion recipes for the portable UISkin core (`Core`).
--- Recipes restyle one kind of addon frame. Each is written against the adapter contract (see `UISkinAdapter`).
--- Rules:
--- - One function for all suites. Where suites genuinely differ, register per-suite variants
---   (`{ default = fn, [Suite.ElvUI] = fn }`) and put the shared steps in a local helper.
--- - Never `StripPanel` a frame whose own layers hold content art (icons, Delve art): hide the decorative
---   regions with `Ops.HideRegions` and use `Panel` instead.
--- - Never touch `InsecureAction` children or other clickable action buttons beyond their textures.

--#region Encounter Journal: Delves tab

UISkin:RegisterRecipe("DelvesTab", Host.journal, function(skin, tab)
    skin:Tab(tab)
end)

---@param skin UISkinAdapter
---@param frame DelvesListFrame
local function SkinDelvesList(skin, frame)
    skin:ScrollBar(frame.ScrollBar)
    skin:TextColor(frame.Title)
    skin:TextColor(frame.ModifiersContainer.ModifiersLabel)
end

UISkin:RegisterRecipe("DelvesListFrame", Host.journal, {
    default = SkinDelvesList,
    -- ElvUI removes the Encounter Journal background art.
    [Suite.ElvUI] = function(skin, frame)
        SkinDelvesList(skin, frame)
        Ops.HideRegions(frame.Background)
    end
})

---@param skin UISkinAdapter
---@param button DelveInstanceButton
local function SkinInstanceButtonBackdrop(skin, button)
    skin:Panel(Ops.CreateHolder(button, button.DelveArtBg, 1))
end

UISkin:RegisterRecipe("DelveInstanceButton", Host.journal, {
    default = SkinInstanceButtonBackdrop,
    -- ElvUI flattens the Encounter Journal instance buttons: no button art, a flat highlight.
    [Suite.ElvUI] = function(skin, button)
        Ops.HideRegions(button:GetNormalTexture(), button:GetPushedTexture(), button.DefaultBg)
        Ops.FlatHighlight(skin, button, button.DelveArtBg)
        SkinInstanceButtonBackdrop(skin, button)
    end
})

UISkin:RegisterRecipe("DelveMapHeader", Host.journal, function(skin, header)
    Ops.HideRegions(header.Background)
    skin:Panel(header)
end)
--#endregion

--#region Encounter Journal: Delves encounter (Journeys)

-- Bountiful / Consumables / Gilded Stash panels.
UISkin:RegisterRecipe("RewardCard", Host.journal, function(skin, frame)
    Ops.HideRegions(frame.RewardCardBG)
    skin:Panel(frame)
end)

UISkin:RegisterRecipe("BountifulButton", Host.journal, function(skin, button)
    Ops.HideRegions(button:GetNormalTexture(), button:GetPushedTexture(), button.Background)
    Ops.FlatHighlight(skin, button, button.ArtBg)
    skin:Panel(Ops.CreateHolder(button, button.ArtBg, 1))
end)

UISkin:RegisterRecipe("ExpBar", Host.journal, function(skin, bar)
    Ops.HideRegions(bar.LeftTexture, bar.MiddleTexture, bar.RightTexture, bar.Background)
    skin:StatusBar(bar) -- The suite's own fill color replaces the companion green.
end)

--- An option button in a companion slot dropdown. Mirrors how ElvUI skins the stock companion configuration.
UISkin:RegisterRecipe("CompanionConfigOption", Host.journal, function(skin, option)
    if not option.Icon then
        return
    end

    skin:Icon(option.Icon, option)
    if option.Border then
        skin:IconQualityBorder(option.Border, option.Icon)
    end
end)

--- The slots themselves keep the Blizzard art: the suites leave the stock companion slots unskinned too.
UISkin:RegisterRecipe("CompanionConfigPanel", Host.journal, function(skin, panel)
    local function SkinOptions(scrollBox)
        scrollBox:ForEachFrame(function(option)
            UISkin:Apply("CompanionConfigOption", option)
        end)
    end

    for _, slot in ipairs({ panel.RoleSlot, panel.FlavorSlot, panel.CombatSlot, panel.UtilitySlot }) do
        local list = slot.OptionsList
        if list then
            skin:StripPanel(list, true)

            -- Option buttons are created when the dropdown opens.
            local scrollBox = list.ScrollBox
            if scrollBox and scrollBox.ForEachFrame and scrollBox.Update then
                hooksecurefunc(scrollBox, "Update", SkinOptions)
            end
        end
    end
end)

UISkin:RegisterRecipe("JournalButton", Host.journal, function(skin, button)
    skin:Button(button)
end)
--#endregion

--#region Delves difficulty picker

UISkin:RegisterRecipe("PickerButton", Host.picker, function(skin, button)
    skin:Button(button)
end)

UISkin:RegisterRecipe("PickerCloseButton", Host.picker, function(skin, button)
    skin:CloseButton(button)
end)

UISkin:RegisterRecipe("PickerCheckbox", Host.picker, function(skin, checkbox)
    skin:Checkbox(checkbox)
end)
--#endregion

--#region Addon windows and widgets

--- Generic icon widget, used everywhere. Atlas-based widgets (e.g. Nemesis ring) keep their art.
UISkin:RegisterRecipe("ActionWidget", nil, function(skin, widget)
    if widget.atlasTexture then
        return
    end

    skin:Icon(widget.Icon, widget)
    skin:IconQualityBorder(widget.IconBorder, widget.Icon)
end)

UISkin:RegisterRecipe("LootInfoFrame", Host.standalone, function(skin, frame)
    skin:Window(frame)
    skin:CloseButton(frame.CloseButton)

    -- Column headers: the suite's text color instead of Blizzard's yellow.
    local headers = frame.RowsScroll.Content.ColumnHeaders
    local columns = headers.Container
    skin:TextColor(headers.Tier)
    for _, column in ipairs({ columns.Bountiful, columns.Nemesis, columns.GildedStash, columns.Map, columns.Vault }) do
        skin:TextColor(column.Text)
    end

    -- The horizontal scroll bar is a custom template (rotated MinimalScrollBar art), unknown to the suites:
    -- flatten its track and thumb. The step arrows are kept.
    local track = frame.RowsScroll.ScrollBar.Track
    local thumb = track.Thumb
    Ops.HideRegions(track.Begin, track.End, track.Middle, thumb.Begin, thumb.End, thumb.Middle)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints(track)
    trackBg:SetColorTexture(0, 0, 0, 0.4)

    local thumbFill = thumb:CreateTexture(nil, "ARTWORK")
    thumbFill:SetPoint("TOPLEFT", 0, -1)
    thumbFill:SetPoint("BOTTOMRIGHT", 0, 1)
    UISkin:PaintAccent(thumbFill, 0.8)
end)

UISkin:RegisterRecipe("InDelveWidget", Host.standalone, function(skin, frame)
    skin:Inset(frame)
end)

UISkin:RegisterRecipe("SettingsButton", Host.settings, function(skin, button)
    skin:Button(button)
end)
--#endregion
