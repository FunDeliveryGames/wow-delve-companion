local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

---@type string
local INFO_WIDGET_SAVE_KEY = "delvesListInfoWidgetsEnabled"

---@type number Opening the list refreshes Delves data if the last full refresh is older than this.
local DATA_MAX_AGE_SEC = 30
--#endregion

--- A list with all Delves displayed in the EncounterJournal.
---@class (exact) DelvesListFrame : DelvesListXml
---@field expansionLevel number? LE_EXPANSION currently listed.
---@field isRefreshing boolean? Set while `Refresh` runs, to skip the list rebuild requested by its own data refresh.
DelveCompanion_DelvesListFrameMixin = {}

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:UpdateKeysWidget()
    local widget = self.KeysWidget
    local keyCurrInfo = C_CurrencyInfo.GetCurrencyInfo(Config.BOUNTIFUL_KEY_CURRENCY_CODE)
    if not keyCurrInfo then
        widget:Hide()
        return
    end

    widget:SetLabelText(keyCurrInfo.quantity)
    local color = ColorManager.GetColorDataForItemQuality(keyCurrInfo.quality)
    widget:DisplayBorderForQuality(color)
    widget:Show()

    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:Refresh()
    self.isRefreshing = true
    DelveCompanion.DelvesData:EnsureFresh(DATA_MAX_AGE_SEC)
    self.isRefreshing = false

    ---@type EJTierData
    local tierData = GetEJTierData(EJ_GetCurrentTier())

    do
        local bgAtlasId = tierData.backgroundAtlas
        self.Background:SetAtlas(bgAtlasId, true)
    end

    self:ListDelves(tierData.expansionLevel)

    self:UpdateKeysWidget()
    self.DelveOBotWidget:SetShown(tContains(Config.DELVE_O_BOT_EXPANSIONS, tierData.expansionLevel))

    do
        self.ModifiersContainer.Nemesis:SetFrameInfo(
            DelveCompanion.Definitions.CodeType.Spell,
            Config.AFFIXES.Nemesis[LE_EXPANSION_LEVEL_CURRENT])
        self.ModifiersContainer:SetShown(tierData.expansionLevel == LE_EXPANSION_LEVEL_CURRENT)
    end
end

---@param self DelvesListFrame
---@param expansionLevel number LE_EXPANSION number.
---@param retainScrollPosition boolean? Keep the scroll position (used when only the data changed).
function DelveCompanion_DelvesListFrameMixin:ListDelves(expansionLevel, retainScrollPosition)
    self.expansionLevel = expansionLevel

    local dataProvider = CreateDataProvider()

    for _, zone in ipairs(DelveCompanion.DelvesData:GetZones(expansionLevel)) do
        dataProvider:Insert({ areaName = zone.name })

        for _, record in ipairs(zone.delves) do
            dataProvider:Insert(record)
        end
    end

    self.DelvesList:Show() -- Scrollbox children will not have resolvable rects unless the scrollbox is shown first
    if retainScrollPosition then
        self.DelvesList:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
    else
        self.DelvesList:SetDataProvider(dataProvider)
    end
end

--- Rebuild the list when Delves data changes while it's displayed.
---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnDelvesDataUpdated()
    if self.isRefreshing or not self.expansionLevel then
        return
    end

    self:ListDelves(self.expansionLevel, true)
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnLoad()
    -- Logger:Log("[DelvesListFrame] OnLoad start")

    self.Title:SetText(_G["DELVES_LABEL"])

    self.KeysWidget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Currency, Config.BOUNTIFUL_KEY_CURRENCY_CODE)

    do
        local container = self.ModifiersContainer

        container.ModifiersLabel:SetText(Lockit.UI_DELVES_LIST_MODIFIERS_TEXT)
        container.Nemesis.Icon:SetPoint("CENTER", -1, 1)
        container:Layout()
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

        --- By default, ScrollBox uses the size from templates for extents. However, Delve InstanceButton size may vary depending on the selected options.
        --- So a calculator is required to tell ScrollBox of what size its elements are rebuilding the layout.
        view:SetElementSizeCalculator(function(index, elementData)
            if elementData.areaName then
                return view:GetTemplateSizeFromElementData(elementData)
            else
                local templateWidth, _ = view:GetTemplateSizeFromElementData(elementData)
                local totalHeight = C_XMLUtil.GetTemplateInfo("DelveCompanionDelveInstanceButtonTemplate").height
                    + (DelveCompanionAccountData[INFO_WIDGET_SAVE_KEY]
                        and C_XMLUtil.GetTemplateInfo("DelveCompanionDLDelveInfoWidgetTemplate").height
                        or 0)
                return templateWidth, totalHeight
            end
        end)

        do
            --- Setup Map header.
            ---@param frame DelvesMapHeader
            local function DelveMapHeaderInitializer(frame, elementData)
                DelveCompanion.UISkin:Apply("DelveMapHeader", frame)
                frame:Init(elementData.areaName)
            end

            --- Setup Delve InstanceButton.
            ---@param frame DelveListElement
            ---@param record DelveRecord
            local function DelveListElementInitializer(frame, record)
                DelveCompanion.UISkin:Apply("DelveInstanceButton", frame.InstanceButton)
                frame:Init(record)
            end

            ---Select initializer depending on elementData content.
            ---@param factory table
            ---@param elementData table Can be either a header or a Delve.
            local function DelvesListFactory(factory, elementData)
                if elementData.areaName then
                    factory("DelveCompanionDelveMapHeaderTemplate", DelveMapHeaderInitializer)
                else
                    factory("DelveCompanionDelveListElementTemplate", DelveListElementInitializer)
                end
            end
            view:SetElementFactory(DelvesListFactory)
        end
        ScrollUtil.InitScrollBoxListWithScrollBar(self.DelvesList, self.ScrollBar, view)
    end

    DelveCompanion.UISkin:Apply("DelvesListFrame", self)
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnEvent(event, ...)
    -- Logger:Log("[DelvesListFrame] OnEvent start")

    self:UpdateKeysWidget()
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnShow()
    -- Logger:Log("[DelvesListFrame] OnShow start")

    self:Refresh()

    EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.DELVES_DATA.UPDATED,
        self.OnDelvesDataUpdated, self)
end

---@param self DelvesListFrame
function DelveCompanion_DelvesListFrameMixin:OnHide()
    --Logger:Log("[DelvesListFrame] OnHide start")

    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    EventRegistry:UnregisterCallback(DelveCompanion.Definitions.Events.DELVES_DATA.UPDATED, self)
end

--#region Xml annotations

---@class (exact) ModifiersContainerXml : HorizontalLayoutFrame
---@field ModifiersLabel FontString
---@field Nemesis CustomActionWidget

--- `DelveCompanionDelvesListFrameTemplate`
---@class (exact) DelvesListXml : Frame
---@field Background Texture
---@field Title FontString
---@field KeysWidget CustomActionWidget
---@field DelveOBotWidget DelveOBotWidget
---@field ModifiersContainer ModifiersContainerXml
---@field DelvesList Frame
---@field ScrollBar EventFrame
--#endregion
