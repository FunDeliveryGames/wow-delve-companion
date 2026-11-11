local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

--#region Constants

---@type string
local NEMESIS_ACTIVE_ATLAS = "GM-icon-difficulty-mythicSelected-hover"
local NEMESIS_INACTIVE_ATLAS = "GM-icon-difficulty-mythic-pressed"
local LABYRINTH_ACTIVE_ATLAS = "overworld-active-64x64"
--#endregion

--- A button representing a Delve in the Delves list.
---@class (exact) DelveInstanceButton : DelveInstanceButtonXml
---@field data DelveRecord?
---@field waypointTracker WaypointTracker
DelveCompanion_DelveInstanceButtonMixin = {}

---@param self DelveInstanceButton
---@param data DelveRecord
function DelveCompanion_DelveInstanceButtonMixin:Init(data)
    self.data = data

    self.DelveName:SetText(data.delveName)
    if C_Texture.GetAtlasInfo(data.config.atlasBgID) ~= nil then
        self.DelveArtBg:SetAtlas(data.config.atlasBgID)
    end

    local waypointTracker = CreateFromMixins(DelveCompanion_WaypointTrackerMixin)
    waypointTracker:Prepare()
    self.waypointTracker = waypointTracker

    self.RightIconsContainer:Layout()
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:Refresh()
    local data = self.data
    if not data then
        return
    end

    local kinds = DelveCompanion.Definitions.DelveKind

    self.BountifulIcon:SetShown(data.isBountiful and data.kind ~= kinds.Labyrinth)
    self.LabyrinthIcon:SetShown(data.kind == kinds.Labyrinth and data.config.labyrinthInfo.isAvailable)

    if data.kind == kinds.Nemesis then
        self.NemesisIcon:Show()
        self.NemesisIcon:SetAtlas(data.config.nemesisInfo.isCurrentSeason
            and NEMESIS_ACTIVE_ATLAS
            or NEMESIS_INACTIVE_ATLAS)

        local isLocked = UnitLevel("player") < data.levelRequired
        self.LockIcon:SetShown(isLocked)
        self.DelveArtBg:SetDesaturated(isLocked)
    else
        self.DelveArtBg:SetDesaturated(false)
        self.NemesisIcon:Hide()
        self.LockIcon:Hide()
    end

    self.RightIconsContainer.NotCompletedStoryIcon:SetShown(
        data.storyStatus == DelveCompanion.Definitions.DelveStoryStatus.NotCompleted)

    self.waypointTracker.Update(self.data)
    self.RightIconsContainer.WaypointIcon:SetShown(self.waypointTracker.isActive)

    self.RightIconsContainer:Layout()
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnEvent(event, ...)
    self:Refresh()
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnShow()
    -- Logger:Log("[DelveInstanceButton] OnShow start")

    self:RegisterEvent("SUPER_TRACKING_CHANGED")
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnHide()
    -- Logger:Log("[DelveInstanceButton] OnHide start")

    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnEnter()
    -- Logger:Log("[DelveInstanceButton] OnEnter start")

    self.waypointTracker:DisplayDelveTooltip(self, "ANCHOR_TOP", self.data)
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnLeave()
    -- Logger:Log("[DelveInstanceButton] OnLeave start")

    securecall(GameTooltip.Hide, GameTooltip)
end

---@param self DelveInstanceButton
function DelveCompanion_DelveInstanceButtonMixin:OnClick()
    if self.waypointTracker:VerifyInput() then
        self.waypointTracker:ToggleTracking(self.data)
        self:Refresh()
        self.waypointTracker:DisplayDelveTooltip(self, "ANCHOR_TOP", self.data)
    else
        -- EventRegistry:TriggerEvent(DelveCompanion.Definitions.Events.DELVE_INSTANCE_BUTTON_CLICK, self.data)
    end
end

--#region XML Annotations

---@class (exact) RightIconsContainer : HorizontalLayoutFrame
---@field WaypointIcon Frame
---@field NotCompletedStoryIcon Frame

--- `DelveCompanionDelveInstanceButtonTemplate`
---@class (exact) DelveInstanceButtonXml : Button
---@field DefaultBg Texture
---@field DelveArtBg Texture
---@field DelveName FontString
---@field BountifulIcon Texture
---@field NemesisIcon Texture
---@field LabyrinthIcon Texture
---@field LockIcon Texture
---@field RightIconsContainer RightIconsContainer
--#endregion
