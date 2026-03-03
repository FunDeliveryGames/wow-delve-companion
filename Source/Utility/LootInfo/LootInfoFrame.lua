local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

---@class (exact) LootInfoFrame : LootInfoFrameXml
DelveCompanion_LootInfoFrameMixin = {}

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

        container.Vault.Text:SetText(_G["DELVES_GREAT_VAULT_LABEL"])
        container.Vault.Icon:SetAtlas("GreatVault-32x32")

        local map = Item:CreateFromItemID(Config.BOUNTY_MAPS[LE_EXPANSION_MIDNIGHT])
        map:ContinueOnItemLoad(function()
            container.Map.Text:SetText(map:GetItemName())
            container.Map.Icon:SetTexture("interface/icons/icon_treasuremap")
        end)

        container:Layout()
    end

    for tier, lootInfo in ipairs(Config.DELVES_LOOT_INFO_DATA) do
        local rowFrame = CreateFrame("Frame", nil, self.Rows,
            "DelveCompanionLootInfoRowTemplate")
        rowFrame.layoutIndex = tier

        rowFrame.Tier:SetText(tier)

        local container = rowFrame.Container
        container.Bountiful.Text:SetText(lootInfo.bountifulLvl)
        container.Vault.Text:SetText(lootInfo.vaultLvl)
        container.Map.Text:SetText(lootInfo.mapLvl and lootInfo.mapLvl or "-")
    end

    self.Rows:Layout()
end

---@param self LootInfoFrame
function DelveCompanion_LootInfoFrameMixin:OnShow()
    --Logger:Log("LootInfo OnShow start")
end

--#region XML Annotations

--- `DelveCompanionColumnWithTitleTemplate`
---@class (exact) ColumnWithTitleXml : Frame
---@field Title FontString
---@field Text FontString

--- `DelveCompanionLootInfoFrameTemplate`
---@class (exact) LootInfoFrameXml : Frame
---@field Header FontString
---@field CloseButton Button
---@field DelveTiers ColumnWithTitleXml
---@field BountifulGear ColumnWithTitleXml
---@field VaultGear ColumnWithTitleXml
--#endregion
