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
-- GameTooltip:SetWeeklyReward(itemDBID)

function DelveCompanionGreatVaultDetailsMixin:OnLoad()
    self.rewardInfoStrings = {}
    local offsetY = GREAT_VAULT_DETAILS_FRAME_PADDING
    for i = WeeklyRewardsUtil.GetMaxNumRewards(addon.config.ACTIVITY_TYPE), 1, -1 do
        local rewFrame = CreateFrame("Frame", nil, self.content, "DelveCompanionGreatVaultItemTemplate")
        rewFrame:SetPoint("BOTTOM", 0, offsetY)
        offsetY = offsetY + rewFrame:GetHeight() + GREAT_VAULT_DETAILS_FRAME_PADDING

        table.insert(self.rewardInfoStrings, i, rewFrame.itemInfo)
    end

    self:GetParent():HookScript("OnShow", function()
        if WeeklyRewardsUtil.HasUnlockedRewards(addon.config.ACTIVITY_TYPE) and not C_WeeklyRewards.CanClaimRewards() then
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

DelveCompanionOverviewGildedStashFrameMixin = {}

function DelveCompanionOverviewGildedStashFrameMixin:OnLoad()
    -- log("GildedStash OnLoad start")

    self.Name:SetText(C_Spell.GetSpellName(addon.config.GILDED_STASH_SPELL_CODE))
    for i = 1, addon.config.GILDED_STASH_WEEKLY_CAP, 1 do
        local stash = CreateFrame("Frame", nil, self.Container,
            "DelveCompanionDashboardOverviewGildedStashTemplate")
        stash.layoutIndex = i
        stash.Icon:SetTexture(C_Spell.GetSpellTexture(addon.config.GILDED_STASH_SPELL_CODE))
    end
    self.Container:Layout()
end

function DelveCompanionOverviewGildedStashFrameMixin:OnShow()
    -- log("GildedStash OnShow start")
end

function DelveCompanionOverviewGildedStashFrameMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetSpellByID(addon.config.GILDED_STASH_SPELL_CODE)
    GameTooltip:AddLine(lockit["ui-gilded-stash-bountiful-note"], 1, 1, 1, true)
    GameTooltip:Show()
end

function DelveCompanionOverviewGildedStashFrameMixin:OnLeave()
    GameTooltip:Hide()
end

--============ Bountiful Frame ======================

DelveCompanionOverviewBountifulButtonMixin = {}

function DelveCompanionOverviewBountifulButtonMixin:UpdateTracking()
    local function Set()
        self.isTracking = true
        self.WaypointIcon:Show()
    end

    local function Clear()
        self.isTracking = false
        self.WaypointIcon:Hide()
    end

    if not C_SuperTrack.IsSuperTrackingAnything() then
        Clear()
    end

    local type, typeID = C_SuperTrack.GetSuperTrackedMapPin()
    if type ~= Enum.SuperTrackingMapPinType.AreaPOI then
        Clear()
    elseif typeID ~= self.poiID then
        Clear()
    else
        Set()
    end
end

function DelveCompanionOverviewBountifulButtonMixin:OnLoad()
    self:SetScript("OnEvent", DelveCompanionOverviewBountifulButtonMixin.UpdateTracking)
end

function DelveCompanionOverviewBountifulButtonMixin:OnShow()
    self:RegisterEvent("SUPER_TRACKING_CHANGED")
    self:UpdateTracking()
end

function DelveCompanionOverviewBountifulButtonMixin:OnHide()
    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
end

function DelveCompanionOverviewBountifulButtonMixin:UpdateTooltip()
    local text = lockit["ui-delve-instance-button-tooltip-click-text"]
    if self.isTracking then
        text = lockit["ui-delve-instance-button-tooltip-current-text"]
    end

    GameTooltip:ClearLines()
    GameTooltip:AddLine(self.delveName);
    GameTooltip:AddLine(self.parentMapName, 1, 1, 1);
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(text, 1, 1, 1, true)
    GameTooltip:Show()
end

function DelveCompanionOverviewBountifulButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP");
    self:UpdateTooltip()
end

function DelveCompanionOverviewBountifulButtonMixin:OnLeave()
    GameTooltip:Hide()
end

function DelveCompanionOverviewBountifulButtonMixin:OnClick()
    if IsShiftKeyDown() then
        if self.isTracking then
            C_SuperTrack.ClearSuperTrackedMapPin()
        else
            C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, self.poiID)
        end
        self:UpdateTooltip()
    end
end

DelveCompanionOverviewBountifulFrameMixin = {}

function DelveCompanionOverviewBountifulFrameMixin:OnLoad()
    -- log("Bountiful OnLoad start")
    self.Title:SetText(lockit["ui-common-bountiful-delve"])

    -- local keyCurrInfo = C_CurrencyInfo.GetCurrencyInfo(addon.config.BOUNTIFUL_KEY_CURRENCY_CODE)
    -- self.KeysInfo.Keys.Icon:SetTexture(keyCurrInfo.iconFileID)
    self.KeysInfo.Keys.frameCode = addon.config.BOUNTIFUL_KEY_CURRENCY_CODE
    self.KeysInfo.Shards.frameCode = addon.config.KEY_SHARD_ITEM_CODE
    self.KeysInfo.BountyMap.frameCode = addon.config.BOUNTY_MAP_ITEM_CODE
    self.KeysInfo.Echoes.frameCode = addon.config.ECHO_ITEM_CODE

    self.ActiveDelves.NoBountifulLabel:SetText(lockit["ui-no-active-bountiful"])
    self.bountifulButtonsPool = CreateFramePool("BUTTON", self.ActiveDelves.Container,
        "DelveCompanionOverviewBountifulButtonTemplate")
end

function DelveCompanionOverviewBountifulFrameMixin:OnShow()
    -- log("Bountiful OnShow start")
    addon.CacheActiveBountiful()
    self.bountifulButtonsPool:ReleaseAll()

    if #addon.activeBountifulDelves ~= 0 then
        self.ActiveDelves.NoBountifulLabel:Hide()

        for index, poiID in ipairs(addon.activeBountifulDelves) do
            local config = FindValueInTableIf(addon.config.DELVES_REGULAR_DATA, function(delveConfig)
                return poiID == delveConfig.poiIDs.bountiful
            end)
            local _, _, _, _, _, _, _, _, _, achIcon = GetAchievementInfo(config.achievements.story)

            local button = self.bountifulButtonsPool:Acquire()
            button.layoutIndex = index
            button.ArtBg:SetTexture(achIcon)
            button.poiID = poiID
            button.isTracking = false

            local delveMap = C_Map.GetMapInfo(config.uiMapID)
            button.delveName = delveMap.name
            button.parentMapName = C_Map.GetMapInfo(delveMap.parentMapID).name
            button:Show()
        end

        self.ActiveDelves.Container:Layout()
    else
        self.ActiveDelves.NoBountifulLabel:Show()
    end

    addon.CacheKeysData()
    self.KeysInfo.Keys.Label:SetText(C_CurrencyInfo.GetCurrencyInfo(addon.config.BOUNTIFUL_KEY_CURRENCY_CODE).quantity)
    self.KeysInfo.Shards.Label:SetText(C_Item.GetItemCount(addon.config.KEY_SHARD_ITEM_CODE))
    self.KeysInfo.BountyMap.Label:SetText(C_Item.GetItemCount(addon.config.BOUNTY_MAP_ITEM_CODE))
    self.KeysInfo.Echoes.Label:SetText(C_Item.GetItemCount(addon.config.ECHO_ITEM_CODE))

    self.WorldMapButton:SetText(_G["WORLDMAP_BUTTON"])
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

    local stashSpell = Spell:CreateFromSpellID(addon.config.GILDED_STASH_SPELL_CODE)

    stashSpell:ContinueOnSpellLoad(function()
        local desc = stashSpell:GetSpellDescription()

        local collectedCount = tonumber(strsub(strmatch(desc, "%d/%d"), 1, 1))

        for _, stash in pairs(self.GildedStashFrame.Container:GetLayoutChildren()) do
            if collectedCount >= stash.layoutIndex then
                stash.CheckMark:Show()
                stash.FadeBg:Hide()
                stash.RedX:Hide()
            else
                stash.CheckMark:Hide()
                stash.FadeBg:Show()
                stash.RedX:Show()
            end
        end

        self.GildedStashFrame:Show()
    end)
end

--============ Init ======================

function DelveCompanion_DelvesDashExtension_Init()
    local lootInfoFrame = CreateFrame("Frame", "$parentLootInfoFrame", DelvesDashboardFrame,
        "DelveCompanionLootInfoFrame")

    addon.lootInfoFrame = lootInfoFrame

    if DelveCompanionCharacterData.gvDetailsEnabled then
        local gvPanel = DelvesDashboardFrame.ButtonPanelLayoutFrame.GreatVaultButtonPanel

        local gvDetailsFrame = CreateFrame("Frame", "GVDetailsFrame", gvPanel,
            "DelveCompanionGreatVaultDetailsFrame")
        gvDetailsFrame.gvButton:SetTextToFit(_G["RAF_VIEW_ALL_REWARDS"])

        addon.CacheGreatVaultRewards()
        addon.gvDetailsFrame = gvDetailsFrame

        addon.eventsCatcherFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    end

    if DelveCompanionCharacterData.dashOverviewEnabled then
        -- addon.CacheKeysData()
        local dashOverview = CreateFrame("Frame", "$parentDashboardOverview",
            DelvesDashboardFrame.ButtonPanelLayoutFrame, "DelveCompanionDashboardOverviewFrame")

        DelvesDashboardFrame.ButtonPanelLayoutFrame.spacing = -20
        DelvesDashboardFrame.ButtonPanelLayoutFrame:Layout()

        addon.delvesDashOverview = dashOverview
    end
end
