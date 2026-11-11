local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

---@class (exact) DelveEncounterConsumablesFrame : DelveEncounterConsumablesFrameXml
DelveCompanion_DelveEncounterConsumablesFrameMixin = {}

--- Update consumables with the actual player's state.
---@param self DelveEncounterConsumablesFrame
function DelveCompanion_DelveEncounterConsumablesFrameMixin:UpdateConsumables()
    -- Restored Coffer Keys
    do
        local keysCount = C_CurrencyInfo.GetCurrencyInfo(Config.BOUNTIFUL_KEY_CURRENCY_CODE).quantity
        local widget = self.Keys

        widget:SetLabelText(keysCount)
        widget.Icon:SetDesaturated(keysCount == 0)
    end

    ---@type number
    local expansion = DelveCompanion.EJExtension.DelveEncounter:GetFactionData().expansionID

    if expansion == LE_EXPANSION_WAR_WITHIN then
        self.Keys:Hide()

        do
            local echoCount = C_Item.GetItemCount(self.Echo.frameCode)
            local widget = self.Echo

            widget:SetLabelText(echoCount)
            widget.Icon:SetDesaturated(echoCount == 0)
            widget:Show()
        end

        self.Shards:Hide()
        self.BountyMap:Hide()
        self.ManaCrystals:Hide()
    elseif expansion == LE_EXPANSION_MIDNIGHT then
        self.Keys:Show()
        self.Echo:Hide()

        -- Coffer Key Shards
        do
            ---@type CurrencyInfo
            local shardsInfo = C_CurrencyInfo.GetCurrencyInfo(Config.KEY_SHARDS_CURRENCY_CODE)
            ---@type number
            local shardsCount = shardsInfo.quantity
            ---@type string
            local shardsLine = tostring(shardsCount)

            local widget = self.Shards

            if shardsCount >= Config.SHARDS_FOR_KEY then
                shardsLine = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(shardsLine)
                widget.Icon:SetDesaturated(false)
            else
                shardsLine = _G["HIGHLIGHT_FONT_COLOR"]:WrapTextInColorCode(shardsLine)
                widget.Icon:SetDesaturated(widget.frameType == DelveCompanion.Definitions.CodeType.Item and
                    true
                    or shardsInfo.quantityEarnedThisWeek >= shardsInfo.maxWeeklyQuantity
                )
            end
            widget:SetLabelText(shardsLine)
            widget:Show()
        end

        -- Bounty Map
        do
            local mapCode = Config.BOUNTY_MAPS[expansion]
            local widget = self.BountyMap

            widget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Item, mapCode)
            local color = ColorManager.GetColorDataForItemQuality(C_Item.GetItemQualityByID(mapCode))
            widget:DisplayBorderForQuality(color)

            local macroText = string.format("/use item:%s", mapCode)
            widget:SetInsecureAction({ type1 = "macro", macrotext = macroText })

            local mapsCount = C_Item.GetItemCount(mapCode)
            -- local mapsLine = tostring(mapsCount) -- TODO: re-enable if Tooltips stop being tainted...
            local mapsLine = string.format("%s", "|A:common-icon-redx:20:20|a")

            if mapsCount >= Config.BOUNTY_MAP_MAX_PER_WEEK then
                -- Has the Map in Inventory
                -- mapsLine = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(mapsLine) -- TODO: re-enable if Tooltips stop being tainted...
                mapsLine = string.format("%s", "|A:bag-main:20:20|a")
                widget.Icon:SetDesaturated(false)
            elseif C_QuestLog.IsQuestFlaggedCompleted(Config.BOUNTY_MAP_QUEST) then
                -- Looted and used already
                -- mapsLine = _G["DISABLED_FONT_COLOR"]:WrapTextInColorCode(mapsLine) -- TODO: re-enable if Tooltips stop being tainted...
                mapsLine = string.format("%s", "|A:common-icon-checkmark:20:20|a")
                widget.Icon:SetDesaturated(true)
            else
                -- Map to be looted
                -- mapsLine = _G["HIGHLIGHT_FONT_COLOR"]:WrapTextInColorCode(mapsLine) -- TODO: re-enable if Tooltips stop being tainted...
                mapsLine = string.format("%s", "|A:common-icon-redx:20:20|a")
                widget.Icon:SetDesaturated(false)
            end

            widget:SetLabelText(mapsLine)
            widget:Show()
        end

        -- Untainted Mana-Crystals
        do
            local crystalsInfo = C_CurrencyInfo.GetCurrencyInfo(Config.MANA_CRYSTALS_CURRENCY_CODE)
            local crystalsCount = crystalsInfo.discovered and crystalsInfo.quantity or 0
            local widget = self.ManaCrystals

            widget:SetLabelText(crystalsCount)
            widget.Icon:SetDesaturated(crystalsCount == 0
                and crystalsInfo.quantityEarnedThisWeek >= crystalsInfo.maxWeeklyQuantity)
            widget:Show()
        end
    end
end

---@param self DelveEncounterConsumablesFrame
function DelveCompanion_DelveEncounterConsumablesFrameMixin:OnLoad()
    -- Logger:Log("[DelveEncounterConsumablesFrame] OnLoad start")

    local defs = DelveCompanion.Definitions
    do
        local widget = self.Keys
        local code = Config.BOUNTIFUL_KEY_CURRENCY_CODE

        widget:SetFrameInfo(defs.CodeType.Currency, code)
        local color = ColorManager.GetColorDataForItemQuality(C_CurrencyInfo.GetCurrencyInfo(code).quality)
        widget:DisplayBorderForQuality(color)
    end

    do
        local widget = self.Shards
        local code = Config.KEY_SHARDS_CURRENCY_CODE

        widget:SetFrameInfo(defs.CodeType.Currency, code)
        local color = ColorManager.GetColorDataForItemQuality(C_CurrencyInfo.GetCurrencyInfo(code).quality)
        widget:DisplayBorderForQuality(color)
    end

    do
        local widget = self.Echo
        local code = Config.ECHO_ITEM_CODE

        widget:SetFrameInfo(defs.CodeType.Item, code)
        local color = ColorManager.GetColorDataForItemQuality(C_Item.GetItemQualityByID(code))
        widget:DisplayBorderForQuality(color)
    end

    do
        local widget = self.ManaCrystals
        local code = Config.MANA_CRYSTALS_CURRENCY_CODE

        widget:SetFrameInfo(defs.CodeType.Currency, code)
        local color = ColorManager.GetColorDataForItemQuality(C_CurrencyInfo.GetCurrencyInfo(code).quality)
        widget:DisplayBorderForQuality(color)
    end
end

---@param self DelveEncounterConsumablesFrame
function DelveCompanion_DelveEncounterConsumablesFrameMixin:OnEvent(event, ...)
    -- Logger:Log("[DelveEncounterConsumablesFrame] OnEvent start")

    C_Timer.After(0.5, function()
        self:UpdateConsumables()
    end)
end

---@param self DelveEncounterConsumablesFrame
function DelveCompanion_DelveEncounterConsumablesFrameMixin:OnShow()
    -- Logger:Log("[DelveEncounterConsumablesFrame] OnShow start")

    self:UpdateConsumables()

    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:RegisterEvent("BAG_UPDATE")
end

---@param self DelveEncounterConsumablesFrame
function DelveCompanion_DelveEncounterConsumablesFrameMixin:OnHide()
    -- Logger:Log("[DelveEncounterConsumablesFrame] OnHide start")

    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:UnregisterEvent("BAG_UPDATE")
end

--#region XML Annotations

--- `DelveCompanionDelveEncounterConsumablesFrameTemplate`
---@class (exact) DelveEncounterConsumablesFrameXml : Frame
---@field Keys CustomActionWidget
---@field Shards CustomActionWidget
---@field Echo CustomActionWidget
---@field BountyMap CustomActionWidget
---@field ManaCrystals CustomActionWidget

--#endregion
