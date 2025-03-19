local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit
local enums = addon.enums
--=========== CONSTANTS ============================
local EJ_DELVES_TAB_BUTTON_ID = 6
local EJ_TABS_NUMBER = 6

local DELVES_LIST_VIEW_COLS = 4
local DELVES_LIST_VIEW_BUTTONS_OFFSET = 12
local DELVES_LIST_VIEW_BUTTONS_PADDING = 5

--============ DelveInstanceButton ======================

DelveCompanionDelveInstanceButtonMixin = {}

function DelveCompanionDelveInstanceButtonMixin:Update(isBountiful)
    local poiIDs = self.config.poiIDs
    if isBountiful then
        self.poiID = poiIDs.bountiful
        self.bountifulIcon:Show()
    else
        self.poiID = poiIDs.regular
        self.bountifulIcon:Hide()
    end

    if not C_SuperTrack.IsSuperTrackingAnything() then
        addon.ClearTrackedDelve(self)
    elseif C_SuperTrack.IsSuperTrackingMapPin then
        local type, typeID = C_SuperTrack.GetSuperTrackedMapPin()
        if type == Enum.SuperTrackingMapPinType.AreaPOI and (typeID == poiIDs.regular or typeID == poiIDs.bountiful) then
            addon.SetTrackedDelve(self)
        end
    end
end

function DelveCompanionDelveInstanceButtonMixin:UpdateTooltip()
    local text = lockit["ui-delve-instance-button-tooltip-click-text"]
    if self.isTracking then
        text = lockit["ui-delve-instance-button-tooltip-current-text"]
    end

    GameTooltip:SetText(text, 1, 1, 1)
    GameTooltip:Show()
end

function DelveCompanionDelveInstanceButtonMixin:OnEnter()
    if addon.maxLevelReached == false then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    self:UpdateTooltip()
end

function DelveCompanionDelveInstanceButtonMixin:OnLeave()
    GameTooltip:Hide()
end

function DelveCompanionDelveInstanceButtonMixin:OnClick()
    if addon.maxLevelReached == false then
        return
    end

    if IsShiftKeyDown() then
        if self.isTracking then
            C_SuperTrack.ClearSuperTrackedMapPin()
            addon.ClearTrackedDelve(self)
        else
            C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, self.poiID)
            addon.SetTrackedDelve(self)
        end
        self:UpdateTooltip()
    end
end

--============ DelvesListFrame ======================

DelveCompanionDelvesListMixin = {}

function DelveCompanionDelvesListMixin:CreateMapHeader(parent, mapName)
    local header = CreateFrame("Frame", nil, parent, "DelveCompanionMapHeaderTemplate")
    header.mapName:SetText(mapName)

    return header
end

function DelveCompanionDelvesListMixin:CreateDelveInstanceButton(parent, config)
    local item = CreateFrame("Button", nil, parent, "DelveCompanionDelveInstanceButtonTemplate")
    item.config = config
    item.isTracking = false

    local delveMap = C_Map.GetMapInfo(config.uiMapID)
    item.delveName:SetText(delveMap.name)
    if C_Texture.GetAtlasInfo(config.atlasBgID) ~= nil then
        item.artBg:SetAtlas(config.atlasBgID)
    end

    return item
end

function DelveCompanionDelvesListMixin:UpdateKeysWidget()
    local keyCurrInfo = C_CurrencyInfo.GetCurrencyInfo(addon.config.BOUNTIFUL_KEY_CURRENCY_CODE)
    if not keyCurrInfo then
        self.KeysWidget:Hide()
        return
    end

    self.KeysWidget:SetIconFromTexture(keyCurrInfo.iconFileID)
    self.KeysWidget:SetLabelText(keyCurrInfo.quantity)

    self.KeysWidget:Show()
end

function DelveCompanionDelvesListMixin:OnLoad()
    --log("DelvesList OnLoad start")
    self.Title:SetText(_G["DELVES_LABEL"])
    self.KeysWidget:SetFrameInfo(enums.CodeType.Currency, addon.config.BOUNTIFUL_KEY_CURRENCY_CODE)

    local offsetX, offsetY = DELVES_LIST_VIEW_BUTTONS_OFFSET, 0
    local instanceButtons = {}
    for _, mapID in ipairs(addon.config.DELVES_MAPS_DATA) do
        local areaName = C_Map.GetMapInfo(mapID).name
        local header = DelveCompanionDelvesListMixin:CreateMapHeader(self.DelvesListScroll.Content, areaName)
        header:SetPoint("TOPLEFT", self.DelvesListScroll.Content, "TOPLEFT", 0, -offsetY)

        offsetY = offsetY + header:GetHeight() + DELVES_LIST_VIEW_BUTTONS_PADDING

        local count = 0
        local cellHeight = 0
        local prevRow = 0
        for _, delveConfig in ipairs(addon.config.DELVES_REGULAR_DATA) do
            local parentMapID = C_Map.GetMapInfo(delveConfig.uiMapID).parentMapID

            if parentMapID == mapID then
                local instanceButton = DelveCompanionDelvesListMixin:CreateDelveInstanceButton(
                    self.DelvesListScroll.Content,
                    delveConfig)
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
            end
        end
        offsetY = offsetY + cellHeight + DELVES_LIST_VIEW_BUTTONS_OFFSET * 2 +
            DELVES_LIST_VIEW_BUTTONS_PADDING * (prevRow + 1)
    end

    self.instanceButtons = instanceButtons
end

function DelveCompanionDelvesListMixin:OnShow()
    --log("DelvesList OnShow start")
    addon.CacheActiveBountiful()

    for _, instanceButton in ipairs(self.instanceButtons) do
        local isBountiful = FindValueInTableIf(addon.activeBountifulDelves, function(bountifulID)
            return bountifulID == instanceButton.config.poiIDs.bountiful
        end)
        instanceButton:Update(isBountiful)
    end

    if addon.maxLevelReached then
        self:UpdateKeysWidget()
        addon.eventsCatcherFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    else
        self.KeysWidget:Hide()
    end
end

function DelveCompanionDelvesListMixin:OnHide()
    --log("DelvesList OnHide start")
    addon.eventsCatcherFrame:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
end

--============ Init ======================
function DelveCompanion_DelvesListFrame_Init()
    local button = CreateFrame("Button", "$parent.DelvesTab", EncounterJournal,
        "BottomEncounterTierTabTemplate")
    button:SetPoint("LEFT", EncounterJournal.LootJournalTab, "RIGHT", -15, 0)
    button:SetText(_G["DELVES_LABEL"])
    button:SetID(EJ_DELVES_TAB_BUTTON_ID)
    button:SetParentKey("devlesTab")
    PanelTemplates_SetNumTabs(EncounterJournal, EJ_TABS_NUMBER)

    addon.delvesListFrame = CreateFrame("Frame", "$parent.DelvesListFrame", EncounterJournal,
        "DelveCompanionDelvesListFrameTemplate")

    EventRegistry:RegisterCallback("EncounterJournal.TabSet",
        function(_, EncounterJournal, tabID)
            if tabID == EJ_DELVES_TAB_BUTTON_ID then
                -- EncounterJournal.instanceSelect.Title:SetText(_G["DELVES_LABEL"])
                EJ_HideNonInstancePanels()
                addon.delvesListFrame:Show()
            else
                addon.delvesListFrame:Hide()
            end
        end,
        addon)
end
