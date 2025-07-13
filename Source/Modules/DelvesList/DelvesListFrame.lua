local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

local DELVES_LIST_VIEW_COLS = 4
local DELVES_LIST_VIEW_BUTTONS_OFFSET = 12
local DELVES_LIST_VIEW_BUTTONS_PADDING = 5
--#endregion

--- A list with all Delves displayed in the EncounterJournal.
---@class (exact) DelvesListFrame : DelvesListXml
---@field instanceButtons DelveInstanceButton[]
DelveCompanion_DelvesListFrameMixin = {}

---@param self DelvesListFrame
---@param parent Frame
---@param mapName string
---@return DelvesMapHeader
function DelveCompanion_DelvesListFrameMixin:CreateMapHeader(parent, mapName)
    ---@type DelvesMapHeader
    local header = CreateFrame("Frame", nil, parent, "DelveCompanionDelveMapHeaderTemplate")
    header.MapName:SetText(mapName)

    return header
end

---@param self DelvesListFrame
---@param parent Frame
---@param config DelveConfig
---@return DelvesProgressWidget
function DelveCompanion_DelvesListFrameMixin:CreateDelveProgressWidget(parent, config)
    ---@type DelvesProgressWidget
    local widget = CreateFrame("Frame", nil, parent, "DelveCompanionDelveProgressWidgetTemplate")

    local defs = DelveCompanion.Definitions

    -- Story progress
    do
        local achID = config.achievements.story
        widget.Story:SetFrameInfo(defs.CodeType.Achievement, achID)

        local totalCount = GetAchievementNumCriteria(achID)
        local completedCount = 0
        for index = 1, totalCount, 1 do
            ---@type boolean
            local completed = select(3, GetAchievementCriteriaInfo(achID, index))
            if completed then
                completedCount = completedCount + 1
            end
        end
        local text = format(_G["GENERIC_FRACTION_STRING"], completedCount, totalCount)
        if completedCount == totalCount then
            text = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(text)
        end
        widget.Story:SetLabelText(text)
        widget.Story:SetOnClick(function() OpenAchievementFrameToAchievement(achID) end)
    end

    -- Chest progress
    do
        local achID = config.achievements.chest
        widget.Chest:SetFrameInfo(defs.CodeType.Achievement, achID)

        ---@type number, number
        local quantity, reqQuantity = select(4, GetAchievementCriteriaInfo(achID, 1))
        local text = format(_G["GENERIC_FRACTION_STRING"], quantity, reqQuantity)
        if quantity == reqQuantity then
            text = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(text)
        end
        widget.Chest:SetLabelText(text)
        widget.Chest:SetOnClick(function() OpenAchievementFrameToAchievement(achID) end)
    end

    return widget
end

---@param self DelvesListFrame
---@param parent Frame
---@param delveData DelveData
---@return DelveInstanceButton
function DelveCompanion_DelvesListFrameMixin:CreateDelveInstanceButton(parent, delveData)
    ---@type DelveInstanceButton
    local item = CreateFrame("Button", nil, parent, "DelveCompanionDelveInstanceButtonTemplate")
    item.data = delveData

    item.DelveName:SetText(delveData.delveName)
    if C_Texture.GetAtlasInfo(delveData.config.atlasBgID) ~= nil then
        item.DelveArtBg:SetAtlas(delveData.config.atlasBgID)
    end

    return item
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:InitDelvesList()
    local offsetX, offsetY = DELVES_LIST_VIEW_BUTTONS_OFFSET, 0

    ---@type DelveInstanceButton[]
    local instanceButtons = {}

    for _, mapID in ipairs(Config.MAPS_WITH_DELVES) do
        local areaName = C_Map.GetMapInfo(mapID).name
        local header = self:CreateMapHeader(self.DelvesListScroll.Content, areaName)
        header:SetPoint("TOPLEFT", self.DelvesListScroll.Content, "TOPLEFT", 0, -offsetY)

        offsetY = offsetY + header:GetHeight() + DELVES_LIST_VIEW_BUTTONS_PADDING

        local count = 0
        local cellHeight = 0
        local prevRow = 0
        for _, delveData in ipairs(DelveCompanion.Variables.delvesData) do
            local delveConfig = delveData.config
            local parentMapID = C_Map.GetMapInfo(delveConfig.uiMapID).parentMapID

            if parentMapID == mapID then
                ---@type DelveInstanceButton
                local instanceButton = self:CreateDelveInstanceButton(
                    self.DelvesListScroll.Content,
                    delveData)
                count = count + 1
                table.insert(instanceButtons, instanceButton)

                local cellWidth = instanceButton:GetWidth()
                cellHeight = instanceButton:GetHeight()

                local row = math.floor((count - 1) / DELVES_LIST_VIEW_COLS)
                local col = (count - 1) % DELVES_LIST_VIEW_COLS

                if row > prevRow then
                    offsetY = offsetY + cellHeight + DELVES_LIST_VIEW_BUTTONS_PADDING
                    prevRow = row
                end

                local anchorX = offsetX +
                    col * (cellWidth + DELVES_LIST_VIEW_BUTTONS_OFFSET)
                local anchorY = -(row * (cellHeight + DELVES_LIST_VIEW_BUTTONS_OFFSET) + DELVES_LIST_VIEW_BUTTONS_PADDING)

                instanceButton:SetPoint("TOPLEFT", header, "BOTTOMLEFT", anchorX,
                    anchorY)

                if delveConfig.achievements then
                    ---@type DelvesProgressWidget
                    local progressWidget = self:CreateDelveProgressWidget(self.DelvesListScroll.Content,
                        delveConfig)
                    progressWidget:SetPoint("TOPLEFT", instanceButton, "BOTTOMLEFT", 0, 0)
                end
            end
        end
        offsetY = offsetY + cellHeight + DELVES_LIST_VIEW_BUTTONS_OFFSET * 2 +
            DELVES_LIST_VIEW_BUTTONS_PADDING * (prevRow + 1)
    end

    self.instanceButtons = instanceButtons
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:UpdateKeysWidget()
    local keyCurrInfo = C_CurrencyInfo.GetCurrencyInfo(Config.BOUNTIFUL_KEY_CURRENCY_CODE)
    if not keyCurrInfo then
        self.KeysWidget:Hide()
        return
    end

    self.KeysWidget:SetLabelText(keyCurrInfo.quantity)

    self.KeysWidget:Show()
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnLoad()
    -- Logger.Log("DelvesList OnLoad start")

    self.Title:SetText(_G["DELVES_LABEL"])

    self.KeysWidget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Currency, Config.BOUNTIFUL_KEY_CURRENCY_CODE)

    do
        self.ModifiersContainer.ModifiersLabel:SetText(_G["MODIFIERS_COLON"])

        self.ModifiersContainer.OverchargedWidget:Show()
        self.ModifiersContainer.OverchargedWidget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Spell,
            Config.OVERCHARGED_SPELL_CODE)

        self.ModifiersContainer.AffixWidget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Spell,
            Config.NEMESIS_AFFIX_SPELL_CODE)
        self.ModifiersContainer:Layout()
    end

    self:InitDelvesList()
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnEvent(event, ...)
    self:UpdateKeysWidget()
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnShow()
    -- Logger.Log("DelvesList OnShow start")

    DelveCompanion:UpdateDelvesData()

    for _, instanceButton in ipairs(self.instanceButtons) do
        instanceButton:Update()
    end

    if DelveCompanion.Variables.maxLevelReached then
        self:UpdateKeysWidget()
        self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    else
        self.KeysWidget:Hide()
    end
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnHide()
    --Logger.Log("DelvesList OnHide start")
    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
end

--#region Xml annotations

---@class DelvesListScroll : ScrollFrame
---@field Content Frame

---@class DelvesListModifiersContainer : HorizontalLayoutFrame
---@field ModifiersLabel FontString
---@field OverchargedWidget CustomActionWidget
---@field AffixWidget CustomActionWidget

--- `DelveCompanionDelvesListFrameTemplate`
---@class DelvesListXml : Frame
---@field Title FontString
---@field KeysWidget CustomActionWidget
---@field DelveOBotWidget DelveOBotWidget
---@field ModifiersContainer DelvesListModifiersContainer
---@field DelvesListScroll DelvesListScroll
--#endregion
