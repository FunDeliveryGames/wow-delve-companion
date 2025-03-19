local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit

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
local GREAT_VAULT_REFRESH_ATTEMPT_FREQUENCY = 0.25

DelveCompanionGreatVaultItemMixin = {}

function DelveCompanionGreatVaultItemMixin:Update()
    if self.info.progress < self.info.threshold then
        self.ItemInfoLabel:SetText(format("%d/%d", self.info.progress, self.info.threshold))
        return
    end

    self.ItemInfoLabel:Hide()
    -- Curent level info
    -- log("Updating %s with id: %d", self:GetDebugName(), self.info.id)
    local itemLink, upgradeItemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(self.info.id)
    local itemLevel
    if itemLink then
        itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
    end

    if not itemLevel then
        -- log("Item level is not ready. Enable OnUpdate...")
        self.updateTimer = 0
        self:SetScript("OnUpdate", self.OnUpdate)
        return
    end

    self.ItemInfoLabel:SetText(format(_G["WEEKLY_REWARDS_ITEM_LEVEL_WORLD"], itemLevel, self.info.level))
    self.ItemInfoLabel:Show()

    -- Upgrade level info

    if self.info.level >= addon.config.GREAT_VAULT_UPGRADE_MAX_TIER then
        self.maxUpgraded = true
        -- log("Tooltip data: max level")
        return
    end

    local upgradeItemLevel
    if upgradeItemLink then
        upgradeItemLevel = C_Item.GetDetailedItemLevelInfo(upgradeItemLink)
    end

    if not upgradeItemLevel then
        -- log("Item upgrade level is not ready. Enable OnUpdate...")
        self.updateTimer = 0
        self:SetScript("OnUpdate", self.OnUpdate)
        return
    end

    local hasData, _, nextLevel, nextItemLevel = C_WeeklyRewards.GetNextActivitiesIncrease(
        self.info.activityTierID,
        self.info.level)

    self.maxUpgraded = false
    if hasData then
        self.nextLevel = nextLevel
        self.nextItemLevel = nextItemLevel
        -- log("Tooltip data: upgrade")
    else
        self.nextLevel = self.info.level + 1
        self.nextItemLevel = upgradeItemLevel
    end
end

function DelveCompanionGreatVaultItemMixin:OnUpdate(delta)
    self.updateTimer = self.updateTimer + delta
    if self.updateTimer >= GREAT_VAULT_REFRESH_ATTEMPT_FREQUENCY then
        self.updateTimer = 0
        self:SetScript("OnUpdate", nil)
        self:Update()
    end
end

function DelveCompanionGreatVaultItemMixin:ShowMaxUpgradeTooltip()
    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_RIGHT")

    GameTooltip_AddInstructionLine(tooltip, _G["WEEKLY_REWARDS_MAXED_REWARD"], true)

    -- log("Show tooltip: max upgrade")
    tooltip:Show()
end

function DelveCompanionGreatVaultItemMixin:ShowUpgradeTooltip()
    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_RIGHT")

    local improveLine = format(_G["WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL"], self.nextItemLevel)
    GameTooltip_AddInstructionLine(tooltip, improveLine, true)

    local reqLine = format(_G["WEEKLY_REWARDS_COMPLETE_WORLD"], self.nextLevel)
    GameTooltip_AddHighlightLine(tooltip, reqLine, true)

    -- log("Show tooltip: upgrade")
    tooltip:Show()
end

function DelveCompanionGreatVaultItemMixin:ShowLockedTooltip()
    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(tooltip, _G["WEEKLY_REWARDS_UNLOCK_REWARD"], nil, true)

    local reqLine = _G["GREAT_VAULT_REWARDS_WORLD_INCOMPLETE"]
    if self.layoutIndex == 2 then
        reqLine = _G["GREAT_VAULT_REWARDS_WORLD_COMPLETED_FIRST"]
    elseif self.layoutIndex == 3 then
        reqLine = _G["GREAT_VAULT_REWARDS_WORLD_COMPLETED_SECOND"]
    end

    local diff = self.info.threshold - self.info.progress
    GameTooltip_AddNormalLine(tooltip, format(reqLine, diff), true)

    -- log("Show tooltip: locked")
    tooltip:Show()
end

function DelveCompanionGreatVaultItemMixin:OnEnter()
    -- log("%s OnEnter start", self:GetDebugName())
    if not self.unlocked then
        self:ShowLockedTooltip()
    elseif self.maxUpgraded then
        self:ShowMaxUpgradeTooltip()
    else
        self:ShowUpgradeTooltip()
    end
end

function DelveCompanionGreatVaultItemMixin:OnLeave()
    GameTooltip:Hide()
end

--=======
DelveCompanionGreatVaultDetailsMixin = CreateFromMixins(WeeklyRewardMixin)

function DelveCompanionGreatVaultDetailsMixin:SetStateLoading()
    self:GetParent().PanelDescription:Hide()
    self:GetParent().GreatVaultButton:Hide()

    self.GVButton:Hide()
    self.Rewards:Hide()
    self.LoadingLabel:Show()
end

function DelveCompanionGreatVaultDetailsMixin:SetStateDefault()
    self:GetParent().PanelDescription:Show()
    self:GetParent().GreatVaultButton:Show()

    self.GVButton:Hide()
    self.Rewards:Hide()
    self.LoadingLabel:Hide()
end

function DelveCompanionGreatVaultDetailsMixin:SetStateCustom()
    -- Hide the default Great Vault elements
    self:GetParent().PanelDescription:Hide()
    self:GetParent().GreatVaultButton:Hide()

    self.GVButton:Show()
    self.Rewards:Show()
    self.LoadingLabel:Hide()
end

function DelveCompanionGreatVaultDetailsMixin:Refresh()
    if self:HasUnlockedRewards(addon.config.ACTIVITY_TYPE) and not C_WeeklyRewards.CanClaimRewards() then
        -- log("Rewards availalbe.")

        local activitiesInfo = C_WeeklyRewards.GetActivities(addon.config.ACTIVITY_TYPE)
        if not activitiesInfo then
            log("Cannot get Activity info")
            return
        end

        for index, rewLabel in ipairs(self.Rewards:GetLayoutChildren()) do
            rewLabel.info = activitiesInfo[index]
            rewLabel.unlocked = self:GetNumUnlockedRewards() >= index
            rewLabel:Update()
        end

        self:SetStateCustom()
    else
        -- log("No rewards.")
        self:SetStateDefault()
    end
    self.shouldRefresh = false
end

function DelveCompanionGreatVaultDetailsMixin:OnLoad()
    -- log("GreatVaultDetails OnLoad start")
    for i = 1, self:GetMaxNumRewards(addon.config.ACTIVITY_TYPE), 1 do
        local rewFrame = CreateFrame("Frame", nil, self.Rewards, "DelveCompanionGreatVaultItemTemplate")
        rewFrame.layoutIndex = i
    end
    self.Rewards:Layout()

    self.LoadingLabel:SetText(_G["SEARCH_LOADING_TEXT"])
    self.GVButton:SetTextToFit(_G["RAF_VIEW_ALL_REWARDS"])

    self:SetScript("OnEvent", self.Refresh)
    self.shouldRefresh = true
end

function DelveCompanionGreatVaultDetailsMixin:OnShow()
    -- log("GreatVaultDetails OnShow start")
    if self.shouldRefresh then
        self:Refresh()
    end
end

function DelveCompanionGreatVaultDetailsMixin:OnHide()
    --log("GreatVaultDetails OnHide start")
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

--============ GildedStash Frame ======================

DelveCompanionOverviewGildedStashFrameMixin = {}

function DelveCompanionOverviewGildedStashFrameMixin:OnLoad()
    -- log("GildedStash OnLoad start")

    local stashSpell = Spell:CreateFromSpellID(addon.config.GILDED_STASH_SPELL_CODE)
    stashSpell:ContinueOnSpellLoad(function()
        self.Name:SetText(stashSpell:GetSpellName())
        for i = 1, addon.config.GILDED_STASH_WEEKLY_CAP, 1 do
            local stash = CreateFrame("Frame", nil, self.Container,
                "DelveCompanionDashboardOverviewGildedStashTemplate")
            stash.layoutIndex = i
            ---@diagnostic disable-next-line: undefined-field
            stash.Icon:SetTexture(stashSpell:GetSpellTexture())
        end
        self.Container:Layout()
    end)
end

function DelveCompanionOverviewGildedStashFrameMixin:OnShow()
    -- log("GildedStash OnShow start")

    local stashSpell = Spell:CreateFromSpellID(addon.config.GILDED_STASH_SPELL_CODE)
    stashSpell:ContinueOnSpellLoad(function()
        local desc = stashSpell:GetSpellDescription()
        local collectedCount = tonumber(strsub(strmatch(desc, "%d/%d"), 1, 1))

        for _, stash in pairs(self.Container:GetLayoutChildren()) do
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
    end)
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
    self:SetScript("OnEvent", self.UpdateTracking)
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
    GameTooltip:AddLine(self.parentMapName, 1, 1, 1, true);
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
    self.KeysInfo.BountyMap.Label:SetText(C_Item.GetItemCount(addon.config.BOUNTY_MAP_ITEM_CODE))
    self.KeysInfo.Echoes.Label:SetText(C_Item.GetItemCount(addon.config.ECHO_ITEM_CODE))
    local shardsCount = C_Item.GetItemCount(addon.config.KEY_SHARD_ITEM_CODE)
    local shardsLine = tostring(shardsCount)
    if shardsCount > addon.config.SHARDS_FOR_KEY then
        shardsLine = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(tostring(shardsLine))
    end
    self.KeysInfo.Shards.Label:SetText(shardsLine)

    self.WorldMapButton:SetText(_G["WORLDMAP_BUTTON"])
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
        addon.gvDetailsFrame = gvDetailsFrame
        addon.eventsCatcherFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    end

    if DelveCompanionCharacterData.dashOverviewEnabled then
        local dashOverview = CreateFrame("Frame", "$parentDashboardOverview",
            DelvesDashboardFrame.ButtonPanelLayoutFrame, "DelveCompanionDashboardOverviewFrame")

        DelvesDashboardFrame.ButtonPanelLayoutFrame.spacing = -20
        DelvesDashboardFrame.ButtonPanelLayoutFrame:Layout()

        addon.delvesDashOverview = dashOverview
    end
end
