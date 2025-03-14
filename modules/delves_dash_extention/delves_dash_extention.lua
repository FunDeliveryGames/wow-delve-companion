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

--============ GildedStash Frame ======================

DelveCompanionGildedStashFrameMixin = {}

function DelveCompanionGildedStashFrameMixin:OnLoad()
    -- log("GildedStash OnLoad start")
    self.name:SetText(C_Spell.GetSpellName(addon.config.GILDED_STASH_SPELL_CODE))
    for i = 1, addon.config.GILDED_STASH_WEEKLY_CAP, 1 do
        local stash = CreateFrame("Frame", nil, self.container,
            "DelveCompanionDashboardOverviewGildedStashTemplate")
        stash.layoutIndex = i
        stash.icon:SetTexture(C_Spell.GetSpellTexture(addon.config.GILDED_STASH_SPELL_CODE))
    end
    self.container:Layout()
end

function DelveCompanionGildedStashFrameMixin:OnShow()
    -- log("GildedStash OnShow start")
    local desc = C_Spell.GetSpellDescription(addon.config.GILDED_STASH_SPELL_CODE)
    local collectedCount = tonumber(strsub(strmatch(desc, "%d/%d"), 1, 1))

    for _, stash in pairs(self.container:GetLayoutChildren()) do
        if collectedCount >= stash.layoutIndex then
            stash.checkMark:Show()
            stash.fadeBg:Hide()
            stash.redX:Hide()
        else
            stash.checkMark:Hide()
            stash.fadeBg:Show()
            stash.redX:Show()
        end
    end
end

function DelveCompanionGildedStashFrameMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetSpellByID(addon.config.GILDED_STASH_SPELL_CODE)
    GameTooltip:AddLine(addon.lockit["ui-gilded-stash-bountiful-note"], 1, 1, 1)
    GameTooltip:Show()
end

function DelveCompanionGildedStashFrameMixin:OnLeave()
    GameTooltip:Hide()
end

--============ Delves DashboardOverview ======================

DelveCompanionDashboardOverviewMixin = {}

function DelveCompanionDashboardOverviewMixin:OnLoad()
    --log("DashboardOverview OnLoad start")
    self.PanelTitle:Hide()
    self.PanelDescription:Hide()
end

function DelveCompanionDashboardOverviewMixin:OnShow()
    --log("DashboardOverview OnShow start")
end

--============ Init ======================

function DelveCompanion_DevlesDashExtension_Init()
    if addon.lootInfoFrame == nil then
        local lootInfoFrame = CreateFrame("Frame", "$parentLootInfoFrame", DelvesDashboardFrame,
            "DelveCompanionLootInfoFrameTemplate")

        addon.lootInfoFrame = lootInfoFrame
    end

    if DelveCompanionCharacterData.gvDetailsEnabled and addon.gvDetailsFrame == nil then
        local gvPanel = DelvesDashboardFrame.ButtonPanelLayoutFrame.GreatVaultButtonPanel

        local gvDetailsFrame = CreateFrame("Frame", "GVDetailsFrame", gvPanel,
            "DelveCompanionGreatVaultDetailsTemplate")
        gvDetailsFrame.gvButton:SetTextToFit(_G["RAF_VIEW_ALL_REWARDS"])

        addon.CacheGreatVaultRewards()
        addon.gvDetailsFrame = gvDetailsFrame

        addon.eventsCatcherFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    end

    if addon.delvesDashOverview == nil then
        local dashOverview = CreateFrame("Frame", "$parentDashboardOverview",
            DelvesDashboardFrame.ButtonPanelLayoutFrame, "DelveCompanionDashboardOverviewTemplate")
        DelvesDashboardFrame.ButtonPanelLayoutFrame.spacing = -20
        DelvesDashboardFrame.ButtonPanelLayoutFrame:Layout()

        addon.delvesDashOverview = dashOverview
    end
end
