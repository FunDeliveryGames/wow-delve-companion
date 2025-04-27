local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

---@class (exact) DashboardExpBar : DashboardExpBarXml
---@field factionID number
---@field rankInfo FriendshipReputationRankInfo
---@field repInfo FriendshipReputationInfo
---@field ParentTitle FontString
DelveCompanion_DashboardExpBarMixin = {}

---@param self DashboardExpBar
---@return number current Exp obtained on this level
---@return number needed Exp required to reach the next level
function DelveCompanion_DashboardExpBarMixin:GetLevelProgress()
    local repInfo = self.repInfo

    local current = repInfo.standing - repInfo.reactionThreshold
    local needed = repInfo.nextThreshold - repInfo.reactionThreshold

    return current, needed
end

---@param self DashboardExpBar
function DelveCompanion_DashboardExpBarMixin:RefreshExpProgress()
    self.rankInfo = C_GossipInfo.GetFriendshipReputationRanks(self.factionID)
    self.repInfo = C_GossipInfo.GetFriendshipReputation(self.factionID)
end

---@param self DashboardExpBar
function DelveCompanion_DashboardExpBarMixin:OnLoad()
    -- Logger.Log("DashboardExpBar OnLoad start")

    self:SetStatusBarColor(_G["FACTION_GREEN_COLOR"]:GetRGB())
    self.factionID = C_DelvesUI.GetFactionForCompanion()
    self.ParentTitle = self:GetParent().PanelTitle
end

---@param self DashboardExpBar
function DelveCompanion_DashboardExpBarMixin:OnShow()
    -- Logger.Log("DashboardExpBar OnShow start")

    self:RefreshExpProgress()

    local companionRankInfo = self.rankInfo
    local companionRepInfo = self.repInfo

    ---@type number
    local barValue = 1
    local barText = format(_G["LEVEL_GAINED"], companionRankInfo.currentLevel)

    if companionRankInfo.currentLevel < companionRankInfo.maxLevel then
        local current, needed = self:GetLevelProgress()
        barValue = current / needed
    else
        barText = format("%s (%s)", barText, _G["GUILD_RECRUITMENT_MAXLEVEL"])
    end

    self:SetValue(barValue)
    self.BarText:SetText(barText)
end

---@param self DashboardExpBar
function DelveCompanion_DashboardExpBarMixin:OnEnter()
    -- Logger.Log("DashboardExpBar OnEnter start")

    self.ParentTitle:Hide()

    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_TOP")

    local rankInfo = self.rankInfo
    local repInfo = self.repInfo
    local wrapText = true

    if rankInfo.maxLevel > 0 then
        GameTooltip_SetTitle(tooltip,
            format("%s (%d / %d)", repInfo.name, rankInfo.currentLevel, rankInfo.maxLevel),
            HIGHLIGHT_FONT_COLOR)
    else
        GameTooltip_SetTitle(tooltip, repInfo.name, HIGHLIGHT_FONT_COLOR)
    end

    ReputationUtil.TryAppendAccountReputationLineToTooltip(tooltip, self.factionID)

    GameTooltip_AddBlankLineToTooltip(tooltip)
    GameTooltip_AddNormalLine(tooltip, repInfo.text, wrapText)
    if repInfo.nextThreshold then
        local current, needed = self:GetLevelProgress()
        GameTooltip_AddHighlightLine(tooltip,
            format("%s (%d / %d)", repInfo.reaction, current, needed),
            wrapText)
    else
        GameTooltip_AddHighlightLine(tooltip, repInfo.reaction, wrapText)
    end

    tooltip:Show()
end

---@param self DashboardExpBar
function DelveCompanion_DashboardExpBarMixin:OnLeave()
    -- Logger.Log("DashboardExpBar OnLeave start")

    GameTooltip:Hide()
    self.ParentTitle:Show()
end

--#region XML Annotations

--- DelveCompanionDashboardExpBarTemplate
---@class DashboardExpBarXml : StatusBar
---@field Background Texture
---@field BarText FontString

--#endregion
