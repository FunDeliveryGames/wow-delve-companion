local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--- Frame with Delve-related consumables.
---@class (exact) OverviewConsumablesFrame : OverviewConsumablesFrameXml
DelveCompanion_OverviewConsumablesFrameMixin = {}

--- Update consumables with the actual player's state.
---@param self OverviewConsumablesFrame
function DelveCompanion_OverviewConsumablesFrameMixin:UpdateConsumables()
    self.Keys:SetLabelText(C_CurrencyInfo.GetCurrencyInfo(Config.BOUNTIFUL_KEY_CURRENCY_CODE).quantity)

    self.BountyMap:SetLabelText(C_Item.GetItemCount(Config.BOUNTY_MAP_ITEM_CODE))
    self.Echoes:SetLabelText(C_Item.GetItemCount(Config.ECHO_ITEM_CODE))

    local shardsCount = C_Item.GetItemCount(Config.KEY_SHARD_ITEM_CODE)
    local shardsLine = tostring(shardsCount)
    if shardsCount >= Config.SHARDS_FOR_KEY then
        shardsLine = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(shardsLine)
    end
    self.Shards:SetLabelText(shardsLine)
end

---@param self OverviewConsumablesFrame
function DelveCompanion_OverviewConsumablesFrameMixin:OnLoad()
    -- Logger.Log("OverviewConsumablesFrame OnLoad start")

    local enums = DelveCompanion.Enums
    self.Keys:SetFrameInfo(enums.CodeType.Currency, Config.BOUNTIFUL_KEY_CURRENCY_CODE)
    self.Shards:SetFrameInfo(enums.CodeType.Item, Config.KEY_SHARD_ITEM_CODE)
    self.BountyMap:SetFrameInfo(enums.CodeType.Item, Config.BOUNTY_MAP_ITEM_CODE)
    self.Echoes:SetFrameInfo(enums.CodeType.Item, Config.ECHO_ITEM_CODE)
end

---@param self OverviewConsumablesFrame
function DelveCompanion_OverviewConsumablesFrameMixin:OnEvent(event, ...)
    -- Logger.Log("OverviewConsumablesFrame OnEvent start")

    C_Timer.After(0.5, function()
        self:UpdateConsumables()
    end)
end

---@param self OverviewConsumablesFrame
function DelveCompanion_OverviewConsumablesFrameMixin:OnShow()
    -- Logger.Log("OverviewConsumablesFrame OnShow start")

    DelveCompanion:CacheKeysCount()
    self:UpdateConsumables()

    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:RegisterEvent("BAG_UPDATE")
end

---@param self OverviewConsumablesFrame
function DelveCompanion_OverviewConsumablesFrameMixin:OnHide()
    -- Logger.Log("OverviewConsumablesFrame OnHide start")

    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:UnregisterEvent("BAG_UPDATE")
end

--#region XML Annotations

--- `DelveCompanionOverviewConsumablesFrameTemplate`
---@class OverviewConsumablesFrameXml : Frame
---@field Keys IconWithLabelAndTooltip
---@field Shards IconWithLabelAndTooltip
---@field BountyMap IconWithLabelAndTooltip
---@field Echoes IconWithLabelAndTooltip

--#endregion
