local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

local function GetMapInfoText()
    local mapAmountWrapColor = _G["GREEN_FONT_COLOR"]
    local collectedCount = 0
    if C_QuestLog.IsQuestFlaggedCompleted(Config.BOUNTY_MAP_QUEST) then
        mapAmountWrapColor = _G["WHITE_FONT_COLOR"]
        collectedCount = 1
    end

    local weekText = strtrim(format(_G["CURRENCY_THIS_WEEK"], ""))
    local mapAmountText = mapAmountWrapColor:WrapTextInColorCode(format(_G["GENERIC_FRACTION_STRING"],
        collectedCount, Config.BOUNTY_MAP_MAX_PER_WEEK))
    local mapInfoText = format("%s%s", _G["NORMAL_FONT_COLOR"]:WrapTextInColorCode(weekText .. ": "), mapAmountText)

    return mapInfoText
end

local function GetKeysInfoText()
    local weekText = strtrim(format(_G["CURRENCY_THIS_WEEK"], Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX))
    local keysCollected = DelveCompanion.Variables.keysCollected
    local keysAmountWrapColor = keysCollected ~= Config.BOUNTIFUL_KEY_MAX_PER_WEEK
        and _G["GREEN_FONT_COLOR"]
        or _G["WHITE_FONT_COLOR"]

    local keysAmountText = keysAmountWrapColor:WrapTextInColorCode(format(_G["GENERIC_FRACTION_STRING"],
        keysCollected, Config.BOUNTIFUL_KEY_MAX_PER_WEEK))
    local keysInfoText = format("%s%s", _G["NORMAL_FONT_COLOR"]:WrapTextInColorCode(weekText .. ": "),
        keysAmountText)

    return keysInfoText
end

local function FindLineInTooltip(tooltip, lineToMatch)
    for i = 1, tooltip:NumLines(), 1 do
        local line = _G["GameTooltipTextLeft" .. i]
        if line and line:GetText() and strmatch(line:GetText(), lineToMatch) then
            return line
        end
    end

    return nil
end

local function EnableTooltipCapInfo()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip, ...)
        if tooltip:GetPrimaryTooltipData().id == Config.BOUNTIFUL_KEY_CURRENCY_CODE then
            local lineToMatch = format(_G["CURRENCY_TOTAL"], "", "%s*(.+)")
            local line = FindLineInTooltip(tooltip, lineToMatch)

            if line then
                local text = format(line:GetText() .. "\n%s", GetKeysInfoText())
                line:SetText(text)
            end
        end
    end)

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, ...)
        if tooltip:GetPrimaryTooltipData().id == Config.BOUNTY_MAP_ITEM_CODE then
            local lineToMatch = _G["ITEM_UNIQUE"]
            local line = FindLineInTooltip(tooltip, lineToMatch)

            if line then
                local text = format(line:GetText() .. "\n%s", GetMapInfoText())
                line:SetText(text)
            end
        elseif FindInTable(Config.BOUNTIFUL_KEY_SOURCE_CACHES_DATA, tooltip:GetPrimaryTooltipData().id) then
            GameTooltip_AddBlankLineToTooltip(tooltip)
            GameTooltip_AddHighlightLine(tooltip, GetKeysInfoText(), true)
        end
    end)
end

function DelveCompanion_TooltipExtension_Init()
    if not DelveCompanionCharacterData.keysCapTooltipEnabled then
        return
    end

    EnableTooltipCapInfo()
    EventRegistry:RegisterFrameEventAndCallback("QUEST_LOG_UPDATE", function()
        DelveCompanion:CacheKeysCount()
    end)
end
