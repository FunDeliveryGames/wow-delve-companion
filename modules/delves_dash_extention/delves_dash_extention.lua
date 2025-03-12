local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit

local GREAT_VAULT_DETAILS_FRAME_PADDING = 3
--============ LootInfoFrame ======================

DelveCompanionLootInfoFrameMixin = {}

function DelveCompanionLootInfoFrameMixin:OnLoad()
    -- log("LootInfo OnLoad start")
    self.TitleContainer.TitleText:SetText(_G["LOOT"])
    self.header:SetText(lockit["ui-loot-info-description"])

    self.delveTiers.title:SetText(strtrim(format(_G["GREAT_VAULT_WORLD_TIER"], "")))
    self.bountifulGear.title:SetText(lockit["ui-loot-info-bountilful-gear-title"] ..
        CreateAtlasMarkup("delves-bountiful", 16, 16))
    self.vaultGear.title:SetText(_G["DELVES_GREAT_VAULT_LABEL"] .. CreateAtlasMarkup("GreatVault-32x32", 16, 16))

    local tiersText, bountifulText, vaultText = "", "", ""
    for tier, lootInfo in ipairs(addon.config.DELVES_LOOT_INFO_DATA) do
        tiersText = tiersText .. tier .. "\n"
        bountifulText = bountifulText .. lootInfo.bountifulLvl .. "\n"
        vaultText = vaultText .. lootInfo.vaultLvl .. "\n"
    end

    self.delveTiers.text:SetText(tiersText)
    self.bountifulGear.text:SetText(bountifulText)
    self.vaultGear.text:SetText(vaultText)

    self:GetParent():HookScript("OnShow", function()
        if self:GetParent().ButtonPanelLayoutFrame.GreatVaultButtonPanel.disabled then
            return
        end
        self:Show()
    end)
    self:GetParent():HookScript("OnHide", function()
        self:Hide()
    end)
end

function DelveCompanionLootInfoFrameMixin:OnShow()
    --log("LootInfo OnShow start")
end

--============ GreatVaultDetails ======================

DelveCompanionGreatVaultDetailsMixin = {}

function DelveCompanionGreatVaultDetailsMixin:OnLoad()
    self.rewardInfoStrings = {}
    local offsetY = GREAT_VAULT_DETAILS_FRAME_PADDING
    for i = WeeklyRewardsUtil.GetMaxNumRewards(addon.activityType), 1, -1 do
        local rewFrame = CreateFrame("Frame", nil, self.content, "DelveCompanionGreatVaultItemTemplate")
        rewFrame:SetPoint("BOTTOM", 0, offsetY)
        offsetY = offsetY + rewFrame:GetHeight() + GREAT_VAULT_DETAILS_FRAME_PADDING

        table.insert(self.rewardInfoStrings, i, rewFrame.itemInfo)
    end

    self:GetParent():HookScript("OnShow", function()
        if WeeklyRewardsUtil.HasUnlockedRewards(addon.activityType) and not C_WeeklyRewards.CanClaimRewards() then
            addon.CacheGreatVaultRewards()

            for index, gvReward in ipairs(addon.gvRewards) do
                local rewInfoText = _G["EMPTY"]
                if gvReward.itemLevel ~= 0 then
                    local levelString = _G["ITEM_LEVEL"]:format(gvReward.itemLevel)
                    local tierString = _G["GREAT_VAULT_WORLD_TIER"]:format(gvReward.delveTier)
                    rewInfoText = format("%s - (%s)", levelString, tierString)
                end

                self.rewardInfoStrings[index]:SetText(rewInfoText)
            end
            -- Hide the default Great Vault widget
            self:GetParent().GreatVaultButton:Hide()
            self:Show()
        else
            self:GetParent().GreatVaultButton:Show()
            self:Hide()
        end
    end)

    self:GetParent():HookScript("OnHide", function()
        self:Hide()
    end)
end

function DelveCompanionGreatVaultDetailsMixin:OnShow()
    --log("GreatVaultDetails OnShow start")
end

--============ Init ======================

function DelveCompanion_DevlesDashExtension_Init()
    if addon.lootInfoFrame == nil then
        local lootInfoFrame = CreateFrame("Frame", "$parentLootInfoFrame", DelvesDashboardFrame,
            "DelveCompanionLootInfoFrameTemplate")

        addon.lootInfoFrame = lootInfoFrame
    end

    local gvPanel = DelvesDashboardFrame.ButtonPanelLayoutFrame.GreatVaultButtonPanel

    if addon.gvDetailsFrame == nil then
        local gvDetailsFrame = CreateFrame("Frame", "GVDetailsFrame", gvPanel,
            "DelveCompanionGreatVaultDetailsTemplate")
        gvDetailsFrame.gvButton:SetTextToFit(_G["RAF_VIEW_ALL_REWARDS"])

        addon.CacheGreatVaultRewards()
        addon.gvDetailsFrame = gvDetailsFrame
    end
end
