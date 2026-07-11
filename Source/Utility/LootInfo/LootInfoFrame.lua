local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region

--#endregion

---@class (exact) LootInfoFrame : LootInfoFrameXml
DelveCompanion_LootInfoFrameMixin = {}

local function GetLootRarity(ilvl)
    for _, rarityInfo in ipairs(Config.LOOT_RARITY) do
        if ilvl >= rarityInfo.from and ilvl <= rarityInfo.to then
            ---@type ItemQualityColorData
            local data = ColorManager.GetColorDataForItemQuality(rarityInfo.quality)
            return data.color:WrapTextInColorCode(ilvl)
        end
    end

    return tostring(ilvl)
end

---@param frame LootInfoElementXml
---@param lootData DelveLootData?
local function SetTierLoot(frame, lootData)
    if not lootData then
        frame.Text:SetText("-")
        frame.Text:Show()
        frame.Text:SetPoint("CENTER")

        return
    end

    if lootData.itemLevel and lootData.crests then
        frame.Text:SetText(GetLootRarity(lootData.itemLevel) .. " + " .. lootData.crests.count)

        local currency = Config.UPGRADE_CRESTS[lootData.crests.track]
        frame.CrestWidget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Currency, currency)
        local color = ColorManager.GetColorDataForItemQuality(C_CurrencyInfo.GetCurrencyInfo(currency).quality)
        frame.CrestWidget:DisplayBorderForQuality(color)

        frame.Text:SetPoint("CENTER", -5, -1)
        frame.CrestWidget:SetPoint("LEFT", frame.Text, "RIGHT", 3, 0)

        frame.Text:Show()
        frame.CrestWidget:Show()
    elseif lootData.itemLevel then
        frame.Text:SetText(GetLootRarity(lootData.itemLevel))
        frame.Text:SetPoint("CENTER", 0, -1)
        frame.Text:Show()
    else
        local currency = Config.UPGRADE_CRESTS[lootData.crests.track]
        frame.CrestWidget:SetFrameInfo(DelveCompanion.Definitions.CodeType.Currency, currency)
        local color = ColorManager.GetColorDataForItemQuality(C_CurrencyInfo.GetCurrencyInfo(currency).quality)
        frame.CrestWidget:DisplayBorderForQuality(color)

        frame.CrestWidget.displayLabel = true
        frame.CrestWidget:SetLabelText(lootData.crests.count)

        frame.CrestWidget:SetPoint("CENTER", 7, -1)
        frame.CrestWidget:Show()
    end
end

---@param self LootInfoFrame
function DelveCompanion_LootInfoFrameMixin:OnLoad()
    -- Logger:Log("LootInfo OnLoad start")

    ---@see DefaultPanelBaseTemplate Blizzard's template
    ---@diagnostic disable-next-line undefined-field
    self.TitleContainer.TitleText:SetText(_G["LOOT"])

    do
        self.ColumnHeaders.Tier:SetText(strtrim(format(_G["GARRISON_TIER"], "")))

        local container = self.ColumnHeaders.Container

        local bountiful = Item:CreateFromItemID(Config.BOUNTIFUL_COFFER_ITEM_CODE)
        bountiful:ContinueOnItemLoad(function()
            container.Bountiful.Text:SetText(bountiful:GetItemName())
            container.Bountiful.Icon:SetAtlas("delves-bountiful")
        end)

        local map = Item:CreateFromItemID(Config.BOUNTY_MAPS[LE_EXPANSION_MIDNIGHT])
        map:ContinueOnItemLoad(function()
            container.Map.Text:SetText(map:GetItemName())
            container.Map.Icon:SetTexture("interface/icons/icon_treasuremap")
        end)

        local nemesisSpell = Config.AFFIXES.Nemesis[LE_EXPANSION_MIDNIGHT]
        container.Nemesis.Text:SetText(C_Spell.GetSpellName(nemesisSpell))
        container.Nemesis.Icon:SetAtlas("delves-treasure-upgrade")

        container.Vault.Text:SetText(_G["DELVES_GREAT_VAULT_LABEL"])
        container.Vault.Icon:SetAtlas("GreatVault-32x32")

        container:Layout()
    end

    for tier = 1, #Config.DELVES_LOOT_INFO_DATA, 1 do
        ---@type LootInfoRowXml
        local rowFrame = CreateFrame("Frame", nil, self.Rows,
            "DelveCompanionLootInfoRowTemplate")
        rowFrame.layoutIndex = tier

        rowFrame.Tier:SetText(tostring(tier))
    end

    self.Rows:Layout()
end

---@param self LootInfoFrame
function DelveCompanion_LootInfoFrameMixin:OnShow()
    --Logger:Log("LootInfo OnShow start")

    ---@type LootInfoRowXml[]
    local rows = self.Rows:GetLayoutChildren()

    if not rows or #rows < 1 then
        self:Hide()
        return
    end

    for i, rowFrame in ipairs(rows) do
        local lootInfo = Config.DELVES_LOOT_INFO_DATA[i]

        local container = rowFrame.Container
        SetTierLoot(container.Bountiful, lootInfo.bountiful)
        SetTierLoot(container.Nemesis, lootInfo.nemesis or nil)
        SetTierLoot(container.Map, lootInfo.map or nil)
        SetTierLoot(container.Vault, lootInfo.vault)
    end
end

--#region XML Annotations

--- `DelveCompanionLootInfoHeaderTemplate`
---@class (exact) LootInfoHeaderXml : Frame, LayoutChild
---@field Icon Texture
---@field Text FontString

---@class (exact) LootInfoHeaderContainer : HorizontalLayoutFrame
---@field Bountiful LootInfoHeaderXml
---@field Nemesis LootInfoHeaderXml
---@field Map LootInfoHeaderXml
---@field Vault LootInfoHeaderXml

--- `DelveCompanionLootInfoColumnHeadersTemplate`
---@class (exact) LootInfoColumnHeadersXml : Frame
---@field Tier FontString
---@field Container LootInfoHeaderContainer

--- `DelveCompanionLootInfoElementTemplate`
---@class (exact) LootInfoElementXml : Frame, LayoutChild
---@field Text FontString
---@field CrestWidget CustomActionWidget

---@class (exact) LootInfoRowContainer : HorizontalLayoutFrame
---@field Bountiful LootInfoElementXml
---@field Nemesis LootInfoElementXml
---@field Map LootInfoElementXml
---@field Vault LootInfoElementXml

--- `DelveCompanionLootInfoRowTemplate`
---@class (exact) LootInfoRowXml : Frame, LayoutChild
---@field Tier FontString
---@field Container LootInfoRowContainer

--- `DelveCompanionLootInfoFrameTemplate`
---@class (exact) LootInfoFrameXml : Frame
---@field CloseButton Button
---@field ColumnHeaders LootInfoColumnHeadersXml
---@field Rows VerticalLayoutFrame
--#endregion
