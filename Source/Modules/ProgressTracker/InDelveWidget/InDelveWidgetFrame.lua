local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

---@class (exact) DelveRespawnState
---@field Unknown number  -- Used for Reload UI and Logout cases in the midst of the Delve because there is no way to retrieve respawn state from the WoW API.
---@field NotActivated number
---@field Activated number
local RESPAWN_STATE = {
    Unknown = 0,
    NotActivated = 1,
    Activated = 2
}

---@type string[]
local SAVE_KEYS = {
    "inDelveWidgetDisplayRule",
    "inDelveWidgetLayout",
    "inDelveWidgetScale"
}

---@type string
local EDIT_MODE_ATLAS_PREFIX = "editmode-actionbar-highlight"

---@type table<string, table>
local EDIT_MODE_LAYOUT =
{
    ["TopRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = 8 },
    ["TopLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = 8 },
    ["BottomLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = -8 },
    ["BottomRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = -8 },
    ["TopEdge"] = { atlas = "_%s-NineSlice-EdgeTop" },
    ["BottomEdge"] = { atlas = "_%s-NineSlice-EdgeBottom" },
    ["LeftEdge"] = { atlas = "!%s-NineSlice-EdgeLeft" },
    ["RightEdge"] = { atlas = "!%s-NineSlice-EdgeRight" },
    ["Center"] = { atlas = "%s-NineSlice-Center", x = -8, y = 8, x1 = 8, y1 = -8, },
}
--#endregion

---@class (exact) InDelveWidgetFrame : InDelveWidgetFrameXml
---@field isSet boolean
---@field previewMode boolean
---@field isMovingWidget boolean
---@field delveExpansion number
---@field respawnState DelveRespawnState
---@field refreshToken number
---@field Lure InDelveWidgetItem
---@field Map InDelveWidgetItem
---@field Radar InDelveWidgetItem
DelveCompanion_InDelveWidgetFrameMixin = {}

---@param self InDelveWidgetFrame
function DelveCompanion_InDelveWidgetFrameMixin:OnLoad()
    -- Logger:Log("[InDelveWidgetFrame] OnLoad start")

    self:ResetWidget()

    -- Prepare widget buttons
    do
        local function CreateItem(name, parent, index)
            ---@type InDelveWidgetItem
            local widgetItem = CreateFrame("Frame", "$parent." .. name,
                parent,
                "DelvelCompanionInDelveWidgetItemTemplate")

            widgetItem.layoutIndex = index

            return widgetItem
        end

        local lure = CreateItem("Lure", self.Buttons, 1)
        self.Lure = lure
        local map = CreateItem("Map", self.Buttons, 2)
        self.Map = map
        local radar = CreateItem("Radar", self.Buttons, 3)
        self.Radar = radar
    end

    -- Handle Delve Respawn activation
    do
        local function OnDelveRespawnActivated()
            self.respawnState = RESPAWN_STATE.Activated
            self:Refresh()
        end

        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.PROGRESS_TRACKER.DELVE_RESPAWN_ACTIVATED,
            OnDelveRespawnActivated, self)
    end

    -- Settings change
    do
        local function OnSettingChanged(_, changedVarKey, newValue)
            if not tContains(SAVE_KEYS, changedVarKey) then
                return
            end
            -- Logger:Log("[InDelveWidgetFrame] OnSettingChanged. Enabled: %s...", tostring(newValue))

            self:Refresh()
        end

        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.SETTING_CHANGE, OnSettingChanged, self)
    end

    -- Set up a click catcher to move the widget
    do
        local catcher = self.DragCatcher
        NineSliceUtil.ApplyLayout(catcher, EDIT_MODE_LAYOUT, EDIT_MODE_ATLAS_PREFIX)

        local function OnMouseDown(owner, buttonName)
            if buttonName ~= DelveCompanion.Definitions.ButtonAlias.rightClick then
                return
            end

            self.isMovingWidget = true
            self:StartMoving()
        end

        local function OnMouseUp(owner, buttonName)
            if buttonName ~= DelveCompanion.Definitions.ButtonAlias.rightClick then
                return
            end

            if self.isMovingWidget then
                self:EndDrag()
            end
        end

        catcher:SetScript("OnMouseDown", OnMouseDown)
        catcher:SetScript("OnMouseUp", OnMouseUp)
    end
end

---@param self InDelveWidgetFrame
function DelveCompanion_InDelveWidgetFrameMixin:OnShow()
    -- Logger:Log("[InDelveWidgetFrame] OnShow start")

    self:Refresh()

    self:RegisterEvent("BAG_UPDATE")
end

---@param self InDelveWidgetFrame
function DelveCompanion_InDelveWidgetFrameMixin:OnEvent(event, ...)
    -- Logger:Log("[InDelveWidgetFrame] OnEvent start")

    if not self:IsShown() then
        return
    end

    self.refreshToken = (self.refreshToken or 0) + 1
    local token = self.refreshToken

    C_Timer.After(0.5, function()
        if not self:IsShown() or self.refreshToken ~= token then
            return
        end

        self:Refresh()
    end)
end

---@param self InDelveWidgetFrame
function DelveCompanion_InDelveWidgetFrameMixin:OnHide()
    -- Logger:Log("[InDelveWidgetFrame] OnHide start")

    -- Hiding ends the move without a mouse-up, so the drop is finished here
    if self.isMovingWidget then
        self:EndDrag()
    end

    self:ResetWidget()

    self:UnregisterEvent("BAG_UPDATE")
end

---@param self InDelveWidgetFrame
---@param isForced boolean
function DelveCompanion_InDelveWidgetFrameMixin:PrepareWidget(isForced)
    local expansion = self.previewMode and LE_EXPANSION_LEVEL_CURRENT or self.delveExpansion
    self.Lure:Set(Config.NEMESIS_LURE[expansion])
    self.Map:Set(Config.BOUNTY_MAPS[expansion])
    self.Radar:Set(Config.LOOT_RADAR_ITEM_CODE)

    self.respawnState = isForced and RESPAWN_STATE.Unknown or RESPAWN_STATE.NotActivated
    self.isSet = true
end

---@param self InDelveWidgetFrame
function DelveCompanion_InDelveWidgetFrameMixin:ResetWidget()
    self.isSet = false
    self.previewMode = false
    self.delveExpansion = nil
    self.respawnState = RESPAWN_STATE.Unknown
end

---@param self InDelveWidgetFrame
function DelveCompanion_InDelveWidgetFrameMixin:Refresh()
    if not self.isSet then
        return
    end

    self:SetFrameStrata(self.previewMode and "HIGH" or "MEDIUM")

    -- Update the scale before the anchoring below, whose offsets are in the frame's own scaled space
    self:SetScale(DelveCompanionAccountData.inDelveWidgetScale or 1)

    if DelveCompanionAccountData.inDelveWidgetDisplayRule == DelveCompanion.Definitions.InDelveWidgetDisplayRule.custom then
        self.DragCatcher:SetShown(self.previewMode)

        -- Re-anchoring mid-drag would snap the widget back under the cursor
        if not self.isMovingWidget then
            self:ClearAllPoints()

            local saved = DelveCompanionAccountData.inDelveWidgetPoint
            if type(saved) ~= "table" or not saved.point then
                saved = {
                    point = "CENTER",
                    relativeTo = "UIParent",
                    relativePoint = "CENTER",
                    x = 0,
                    y = 0,
                    scale = 1
                }
            end
            -- Offsets are in the frame's own scaled space, so divide out the saved scale
            local factor = (saved.scale or 1) / self:GetScale()
            self:SetPoint(saved.point or "CENTER",
                UIParent,
                saved.relativePoint or "CENTER",
                (saved.x or 0) * factor,
                (saved.y or 0) * factor)
        end
    else
        self.DragCatcher:Hide()
        self:ClearAllPoints()

        ---@type string
        local point =
            DelveCompanionAccountData.inDelveWidgetDisplayRule ==
            DelveCompanion.Definitions.InDelveWidgetDisplayRule.left
            and "TOPRIGHT"
            or "TOPLEFT"

        ---@type string
        local relativePoint =
            DelveCompanionAccountData.inDelveWidgetDisplayRule ==
            DelveCompanion.Definitions.InDelveWidgetDisplayRule.left
            and "BOTTOMLEFT"
            or "BOTTOMRIGHT"

        self:SetPoint(point, ScenarioObjectiveTracker.Header, relativePoint, 0, 0)
    end

    local expansion = self.delveExpansion
    -- Nemesis Lure
    do
        local frame = self.Lure

        if expansion == LE_EXPANSION_LEVEL_CURRENT then
            if (frame.itemCode) then
                local hasItemNow = C_Item.GetItemCount(frame.itemCode) > 0
                local shouldRemind = hasItemNow                                          -- Has the lure
                    and (not C_QuestLog.IsQuestFlaggedCompleted(Config.BOUNTY_MAP_QUEST)) -- Can get the bounty map this week
                    and (self.respawnState ~= RESPAWN_STATE.NotActivated)                 -- Respawn is activated
                -- WoW validates item use; weekly rewards and checkpoint tracking only gate reminders.
                frame:RefreshInteraction(hasItemNow)
                frame:RefreshAnim(shouldRemind and not frame.hasItem)

                frame.hasItem = hasItemNow
            end
        else
            frame:Hide()
        end
    end

    -- Bounty Map
    do
        local frame = self.Map

        if expansion == LE_EXPANSION_LEVEL_CURRENT then
            if (frame.itemCode) then
                local hasItemNow = C_Item.GetItemCount(frame.itemCode) > 0
                local activeBountySpell = DelveCompanion.Config.BOUNTY_ACTIVATED_SPELL[expansion]
                local isAvailable = hasItemNow                                       -- Has the bounty map
                    and C_UnitAuras.GetPlayerAuraBySpellID(activeBountySpell) == nil -- Doesn't have an active map buff
                frame:RefreshInteraction(isAvailable)
                frame:RefreshAnim(isAvailable and not frame.hasItem)

                frame.hasItem = hasItemNow
            end
        else
            frame:Hide()
        end
    end

    -- Loot Radar
    do
        local frame = self.Radar

        if (frame.itemCode) then
            local hasItemNow = C_Item.GetItemCount(frame.itemCode) > 0
            -- local activeRadarSpell = DelveCompanion.Config.LOOT_RADAR_ACTIVATED_SPELL
            local isAvailable = hasItemNow -- Has the radar
            --     and C_UnitAuras.GetPlayerAuraBySpellID(activeRadarSpell) == nil -- Doesn't have an active radar buff. IT DOES NOTHING as the aura is hidden at the moment.
            frame:RefreshInteraction(isAvailable)
            frame:RefreshAnim(isAvailable and not frame.hasItem)

            frame.hasItem = hasItemNow
        end
    end

    -- A preview must not arm a real /use on items the player still has
    if self.previewMode then
        for _, item in ipairs({ self.Lure, self.Map, self.Radar }) do
            item:RefreshInteraction(false)
            item:StopAnimation()
        end
    end

    do
        local buttons = self.Buttons

        if DelveCompanionAccountData.inDelveWidgetLayout == DelveCompanion.Definitions.InDelveWidgetLayout.vertical then
            Mixin(buttons, VerticalLayoutMixin)
        elseif DelveCompanionAccountData.inDelveWidgetLayout == DelveCompanion.Definitions.InDelveWidgetLayout.horizontal then
            Mixin(buttons, HorizontalLayoutMixin)
        end

        buttons:Layout()
        self:SetSize(buttons:GetSize())
    end
end

---@param self InDelveWidgetFrame
function DelveCompanion_InDelveWidgetFrameMixin:SavePosition()
    local point, _, relativePoint, x, y = self:GetPoint()

    ---@class (exact) InDelveWidgetPoint
    ---@field point FramePoint|nil
    ---@field relativeTo string|nil
    ---@field relativePoint FramePoint|nil
    ---@field x uiUnit|nil
    ---@field y uiUnit|nil
    ---@field scale number|nil
    local pointData = {
        point = point,
        relativeTo = "UIParent",
        relativePoint = relativePoint,
        x = x,
        y = y,
        scale = self:GetScale()
    }
    DelveCompanionAccountData.inDelveWidgetPoint = pointData
end

---@param self InDelveWidgetFrame
function DelveCompanion_InDelveWidgetFrameMixin:EndDrag()
    self:StopMovingOrSizing()
    self.isMovingWidget = false

    self:SavePosition()
end

--#region Xml annotations

--- `DelvelCompanionInDelveWidgetFrameTemplate`
---@class InDelveWidgetFrameXml : Frame
---@field Buttons VerticalLayoutFrame|HorizontalLayoutFrame Depends on the widget layout set in Options.
---@field DragCatcher Frame
--#endregion
