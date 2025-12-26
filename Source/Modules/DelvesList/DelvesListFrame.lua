local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

--#endregion

--- A list with all Delves displayed in the EncounterJournal.
---@class (exact) DelvesListFrame : DelvesListXml
DelveCompanion_DelvesListFrameMixin = {}

---@param self DelvesListFrame
---@param parent Frame
---@param mapName string
---@return DelvesMapHeader
function DelveCompanion_DelvesListFrameMixin:CreateMapHeader(parent, mapName)
    ---@type DelvesMapHeader
    local header = CreateFrame("Frame", nil, parent, "DelveCompanionDelveMapHeaderTemplate")
    header:Init(mapName)

    return header
end

---@param self DelvesListFrame
---@param parent Frame
---@param config DelveConfig
---@return DelvesProgressWidget
function DelveCompanion_DelvesListFrameMixin:CreateDelveProgressWidget(parent, config)
    ---@type DelvesProgressWidget
    local widget = CreateFrame("Frame", nil, parent, "DelveCompanionDelveProgressWidgetTemplate")
    widget:Init(config.achievements.story, config.achievements.chest)

    return widget
end

---@param self DelvesListFrame
---@param parent Frame
---@param delveData DelveData
---@return DelveInstanceButton
function DelveCompanion_DelvesListFrameMixin:CreateDelveInstanceButton(parent, delveData)
    ---@type DelveInstanceButton
    local item = CreateFrame("Button", nil, parent, "DelveCompanionDelveInstanceButtonTemplate")
    item:Init(delveData)

    return item
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
function DelveCompanion_DelvesListFrameMixin:Refresh()
    local tierData = GetEJTierData(EJ_GetCurrentTier())

    if not DelveCompanion.Variables.isPTR then
        local tier = EJ_GetCurrentTier() > #ExpansionEnumToEJTierDataTableId
            and LE_EXPANSION_LEVEL_CURRENT
            or GetEJTierDataTableID(EJ_GetCurrentTier())
        tierData.expansionLevel = tier
    end

    do
        local bgAtlasId = tierData.backgroundAtlas
        self.Background:SetAtlas(bgAtlasId, true)
    end

    DelveCompanion:UpdateDelvesData(tierData.expansionLevel)
    self:ListDelves(tierData.expansionLevel)

    if DelveCompanion.Variables.maxLevelReached then
        self:UpdateKeysWidget()
        self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    else
        self.KeysWidget:Hide()
    end
end

---@param self DelvesListFrame
---@param expansionLevel number
function DelveCompanion_DelvesListFrameMixin:ListDelves(expansionLevel)
    local dataProvider = CreateDataProvider()

    for _, mapID in pairs(Config.DELVE_MAPS[expansionLevel]) do
        local areaName = C_Map.GetMapInfo(mapID).name
        dataProvider:Insert({ areaName = areaName })

        for _, delveData in pairs(DelveCompanion.Variables.delvesData[expansionLevel]) do
            local delveConfig = delveData.config
            local parentMapID = C_Map.GetMapInfo(delveConfig.uiMapID).parentMapID

            if parentMapID == mapID then
                dataProvider:Insert(delveData)
            end
        end
    end

    self.DelvesList:Show() -- Scrollbox children will not have resolvable rects unless the scrollbox is shown first
    self.DelvesList:SetDataProvider(dataProvider)
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnLoad()
    -- Logger.Log("DelvesList OnLoad start")

    self.Title:SetText(_G["DELVES_LABEL"])

    self.KeysWidget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Currency, Config.BOUNTIFUL_KEY_CURRENCY_CODE)

    do
        self.ModifiersContainer.ModifiersLabel:SetText(_G["MODIFIERS_COLON"])

        self.ModifiersContainer.AffixWidget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Spell,
            Config.NEMESIS_AFFIX_SPELL_CODE)
        self.ModifiersContainer:Layout()
    end

    do
        local topPadding = 5
        local bottomPadding = 8
        local leftPadding = 0
        local rightPadding = 0
        local horizSpacing = 15
        local vertSpacing = 10
        local view = CreateScrollBoxListSequenceView(
            topPadding, bottomPadding,
            leftPadding, rightPadding,
            horizSpacing, vertSpacing)

        --- Setup Delve instance button after creation
        ---@param frame DelvesMapHeader
        local function DelveMapHeaderInitializer(frame, elementData)
            frame:Init(elementData.areaName)
        end

        --- Setup Delve instance button after creation
        ---@param frame DelveInstanceButton
        ---@param delveData DelveData
        local function DelveInstanceButtonInitializer(frame, delveData)
            frame:Init(delveData)
            frame:Update()
        end

        local function DelvesListFactory(factory, elementData)
            if elementData.areaName then
                factory("DelveCompanionDelveMapHeaderTemplate", DelveMapHeaderInitializer)
            else
                factory("DelveCompanionDelveInstanceButtonTemplate", DelveInstanceButtonInitializer)
            end
        end

        view:SetElementFactory(DelvesListFactory)
        ScrollUtil.InitScrollBoxListWithScrollBar(self.DelvesList, self.ScrollBar, view)
    end
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnEvent(event, ...)
    self:UpdateKeysWidget()
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnShow()
    -- Logger.Log("DelvesList OnShow start")
    self:Refresh()
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnHide()
    --Logger.Log("DelvesList OnHide start")
    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
end

--#region Xml annotations

---@class ModifiersContainerXml : HorizontalLayoutFrame
---@field ModifiersLabel FontString
---@field AffixWidget CustomActionWidget

--- `DelveCompanionDelvesListFrameTemplate`
---@class DelvesListXml : Frame
---@field Background Texture
---@field Title FontString
---@field KeysWidget CustomActionWidget
---@field DelveOBotWidget DelveOBotWidget
---@field ModifiersContainer ModifiersContainerXml
---@field DelvesList Frame
---@field ScrollBar EventFrame
--#endregion
