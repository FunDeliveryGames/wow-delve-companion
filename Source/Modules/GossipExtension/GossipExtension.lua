local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

local EVENT_FRAME_NAME = "DelveCompanionGossipExtensionFrame"

local DELVE_PICKER_GOSSIP_NAME = "delves-difficulty-picker"
--#endregion

---@class (exact) GossipExtension
---@field eventFrame Frame
local GossipExtension = {}
DelveCompanion.GossipExtension = GossipExtension

---@param self GossipExtension
function GossipExtension:EnterDelve(tier)
    local delay = DelveCompanionAccountData.delveAutoEnterDelaySec

    Logger:Log("[GossipExtension] Entering Tier %d in %d secs.", tier, delay)
    C_Timer.After(delay, function(cb)
        C_GossipInfo.SelectOptionByIndex(tier - 1)
    end)
end

---@param self GossipExtension
---@return boolean canEnter Whether the Delve can be entered.
function GossipExtension:CanAutoEnter(tier)
    local options = C_GossipInfo.GetOptions()
    if not options then
        return false
    end

    local canEnter = false

    if C_PartyInfo.IsDelveInProgress() then
        Logger:Log("[GossipExtension] There is a Delve in progress.")
        canEnter = true
    else
        local optionIndex = tier - 1
        for index, optionInfo in ipairs(options) do
            if optionInfo.orderIndex == optionIndex and optionInfo.status == Enum.GossipOptionStatus.Available then
                Logger:Log("[GossipExtension] Required Tier %d is Available.", tier)
                canEnter = true
                break
            end
        end
    end

    do
        local isBountiful = FindInTableIf(options[1].rewards, function(reward)
            return reward.id == Config.BOUNTIFUL_COFFER_ITEM_CODE
        end)

        if isBountiful then
            local keysCount = C_CurrencyInfo.GetCurrencyInfo(Config.BOUNTIFUL_KEY_CURRENCY_CODE).quantity
            local shardsCount = C_CurrencyInfo.GetCurrencyInfo(Config.KEY_SHARDS_CURRENCY_CODE).quantity

            canEnter = keysCount > 0 or shardsCount >= Config.SHARDS_FOR_KEY
            Logger:Log("[GossipExtension] Bountiful Delve, canEnter: %s.", tostring(canEnter))
        end
    end

    return canEnter
end

---@param self GossipExtension
function GossipExtension:ProcessEvent(eventName, arg1, ...)
    if eventName == "GOSSIP_SHOW" then
        if arg1 ~= DELVE_PICKER_GOSSIP_NAME then
            return
        end
        Logger:Log("[GossipExtension] Delve Gossip shown...")

        -- Check story
        -- Display an indicator

        if DelveCompanionAccountData.delveAutoEnterEnabled then
            local tier = DelveCompanionAccountData.delveAutoEnterTier
            if self:CanAutoEnter(tier) then
                self:EnterDelve(tier)
            end
        end
    end
end

---@param self GossipExtension
function GossipExtension:Init()
    -- Logger:Log("[GossipExtension] Init started...")

    local frame = CreateFrame("Frame", EVENT_FRAME_NAME, UIParent)
    frame:RegisterEvent("GOSSIP_SHOW")
    frame:SetScript("OnEvent", function(owner, eventName, arg1, ...)
        C_Timer.After(0.5, function(...)
            self:ProcessEvent(eventName, arg1, ...)
        end)
    end)
    self.eventFrame = frame
end
