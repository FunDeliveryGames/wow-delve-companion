local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

---@type number Showing the panel refreshes Delves data if the last full refresh is older than this.
local DATA_MAX_AGE_SEC = 30
--#endregion

---@class (exact) DelveEncounterBountifulFrame : DelveEncounterBountifulFrameXml
---@field bountifulButtonsPool table
DelveCompanion_DelveEncounterBountifulFrameMixin = {}

---@param self DelveEncounterBountifulFrame
function DelveCompanion_DelveEncounterBountifulFrameMixin:OnLoad()
    -- Logger:Log("[DelveEncounterBountifulFrame] OnLoad start")

    self.Title:SetText(Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE)

    self.ActiveDelves.NoBountifulLabel:SetText(Lockit.UI_NO_ACTIVE_BOUNTIFUL)
    self.bountifulButtonsPool = CreateFramePool("BUTTON", self.ActiveDelves.Container,
        "DelveCompanionDelveEncounterBountifulButtonTemplate")

    self.DelveOBotWidget.Cooldown:SetCountdownFont("GameFontHighlightSmall")
end

---@param self DelveEncounterBountifulFrame
function DelveCompanion_DelveEncounterBountifulFrameMixin:OnEvent(event, ...)
    -- Logger:Log("[DelveEncounterBountifulFrame] OnEvent start")
end

--- Rebuild the buttons of the Bountiful Delves of the displayed expansion.
---@param self DelveEncounterBountifulFrame
function DelveCompanion_DelveEncounterBountifulFrameMixin:RefreshDelves()
    self.bountifulButtonsPool:ReleaseAll()

    ---@type number
    local expansion = DelveCompanion.EJExtension.DelveEncounter:GetFactionData().expansionID
    if not expansion then
        return
    end

    local activeDelves = DelveCompanion.DelvesData:GetBountiful(expansion)

    ---@type boolean
    local useSmallSize = #activeDelves >= 5
    for index, record in ipairs(activeDelves) do
        ---@type DelveEncounterBountifulButton
        local button = self.bountifulButtonsPool:Acquire()
        button:Init(record, index, useSmallSize)
        button:Show()
    end

    self.ActiveDelves.Container:Layout()
    self.ActiveDelves.NoBountifulLabel:SetShown(#activeDelves == 0)

    self.Title:ClearAllPoints()
    if tContains(Config.DELVE_O_BOT_EXPANSIONS, expansion) then
        self.DelveOBotWidget:SetShown(true)
        self.Title:SetPoint("LEFT", self, "TOPLEFT", 5, -27)
        self.Title:SetJustifyH("LEFT")
    else
        self.DelveOBotWidget:SetShown(false)
        self.Title:SetPoint("TOP", 0, -15)
        self.Title:SetJustifyH("CENTER")
    end
end

---@param self DelveEncounterBountifulFrame
function DelveCompanion_DelveEncounterBountifulFrameMixin:OnShow()
    -- Logger:Log("[DelveEncounterBountifulFrame] OnShow start")

    DelveCompanion.DelvesData:EnsureFresh(DATA_MAX_AGE_SEC)
    self:RefreshDelves()

    EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.DELVES_DATA.UPDATED,
        self.RefreshDelves, self)
end

---@param self DelveEncounterBountifulFrame
function DelveCompanion_DelveEncounterBountifulFrameMixin:OnHide()
    -- Logger:Log("[DelveEncounterBountifulFrame] OnHide start")

    EventRegistry:UnregisterCallback(DelveCompanion.Definitions.Events.DELVES_DATA.UPDATED, self)
    self.bountifulButtonsPool:ReleaseAll()
end

--#region XML Annotations

--- `DelveCompanionDelveEncounterBountifulFrameTemplate.ActiveDelves`
---@class (exact) DelveEncounterBountifulFrameActiveDelvesXml : Frame
---@field NoBountifulLabel FontString
---@field Container HorizontalLayoutFrame

--- `DelveCompanionDelveEncounterBountifulFrameTemplate`
---@class (exact) DelveEncounterBountifulFrameXml : Frame
---@field Title FontString
---@field DelveOBotWidget DelveOBotWidget
---@field ActiveDelves DelveEncounterBountifulFrameActiveDelvesXml

--#endregion
