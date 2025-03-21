local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit

local function EnableKeysCapInfo()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip, ...)
        if tooltip:GetPrimaryTooltipData().id ~= addon.config.BOUNTIFUL_KEY_CURRENCY_CODE then
            return
        end

        local weekText = strtrim(format(_G["CURRENCY_THIS_WEEK"], lockit["ui-bountiful-keys-count-caches-prefix"]))
        local keysAmountWrapColor = addon.keysCollected ~= addon.config.BOUNTIFUL_KEY_MAX_PER_WEEK
            and _G["GREEN_FONT_COLOR"]
            or _G["WHITE_FONT_COLOR"]
        local keysAmountText = keysAmountWrapColor:WrapTextInColorCode(format("%d/%d", addon.keysCollected,
            addon.config.BOUNTIFUL_KEY_MAX_PER_WEEK))

        local line = _G["GameTooltipTextLeft4"]
        local text = format(line:GetText() .. "\n%s%s",
            _G["NORMAL_FONT_COLOR"]:WrapTextInColorCode(weekText .. ": "),
            keysAmountText)
        line:SetText(text)
    end)
    --- Chests with keys:
    --- https://wowhead.com/item=239128
    --- https://wowhead.com/item=239120
    --- https://wowhead.com/item=238208
    --- https://wowhead.com/item=239121
    --- https://wowhead.com/item=239118
end

function DelveCompanion_TooltipExtension_Init()
    if DelveCompanionCharacterData.keysCapTooltipEnabled then
        addon.eventsCatcherFrame:RegisterEvent("QUEST_LOG_UPDATE")
        EnableKeysCapInfo()
    end

    ---
    --- https://wowhead.com/item=233071 (Bounty Map)
end
