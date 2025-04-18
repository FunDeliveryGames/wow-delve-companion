local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit
local enums = addon.enums

--============ LootInfoFrame ======================

DelveCompanionLootInfoFrameMixin = {}

function DelveCompanionLootInfoFrameMixin:OnLoad()
    -- log("LootInfo OnLoad start")
    self.TitleContainer.TitleText:SetText(_G["LOOT"])
    self.Header:SetText(lockit["ui-loot-info-description"])

    self.DelveTiers.Title:SetText(strtrim(format(_G["GARRISON_TIER"], "")))

    local bountiful = Item:CreateFromItemID(addon.config.BOUNTIFUL_COFFER_ITEM_CODE)
    bountiful:ContinueOnItemLoad(function()
        self.BountifulGear.Title:SetText(bountiful:GetItemName() .. CreateAtlasMarkup("delves-bountiful", 16, 16))
    end)

    self.VaultGear.Title:SetText(_G["DELVES_GREAT_VAULT_LABEL"] .. CreateAtlasMarkup("GreatVault-32x32", 16, 16))

    local tiersText, bountifulText, vaultText = "", "", ""
    for tier, lootInfo in ipairs(addon.config.DELVES_LOOT_INFO_DATA) do
        tiersText = tiersText .. tier .. "\n"
        bountifulText = bountifulText .. lootInfo.bountifulLvl .. "\n"
        vaultText = vaultText .. lootInfo.vaultLvl .. "\n"
    end

    self.DelveTiers.Text:SetText(tiersText)
    self.BountifulGear.Text:SetText(bountifulText)
    self.VaultGear.Text:SetText(vaultText)

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
        self.ItemInfoLabel:SetText(format(_G["GENERIC_FRACTION_STRING"], self.info.progress, self.info.threshold))
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

function DelveCompanionGreatVaultDetailsMixin:CanDisplayCustomState()
    return self:HasUnlockedRewards(addon.config.ACTIVITY_TYPE) and
        not (C_WeeklyRewards.HasAvailableRewards() or C_WeeklyRewards.HasGeneratedRewards())
end

function DelveCompanionGreatVaultDetailsMixin:Refresh()
    if self:CanDisplayCustomState() then
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

    self.WorldMapButton:SetText(_G["WORLDMAP_BUTTON"])
end

function DelveCompanionDashboardOverviewMixin:OnShow()
    --log("DashboardOverview OnShow start")
end

--============ GildedStash Frame ======================

DelveCompanionOverviewGildedStashFrameMixin = {}

function DelveCompanionOverviewGildedStashFrameMixin:PrepareContainerTooltip()
    self.Container:HookScript("OnEnter", function()
        local tooltip = GameTooltip
        tooltip:SetOwner(self.Container, "ANCHOR_TOP")

        GameTooltip_AddNormalLine(tooltip, self.tooltipDesc, true)
        GameTooltip_AddBlankLineToTooltip(tooltip)
        GameTooltip_AddHighlightLine(tooltip, lockit["ui-gilded-stash-bountiful-note"], true)
        tooltip:Show()
    end)
    self.Container:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

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
    self:PrepareContainerTooltip()

    self.ErrorLabel:SetText(lockit["ui-gilded-stash-cannot-retrieve-data"])
end

function DelveCompanionOverviewGildedStashFrameMixin:CanRetrieveGildedStashInfo()
    local currentMap = C_Map.GetBestMapForUnit("player")
    if not (currentMap and MapUtil.IsMapTypeZone(currentMap)) then
        return false
    end

    local continent = addon.GetContinentMapIDForMap(currentMap)
    return continent and continent == addon.config.KHAZ_ALGAR_MAP_ID
end

function DelveCompanionOverviewGildedStashFrameMixin:TryGetStashInfo()
    for _, delveData in ipairs(addon.delvesData) do
        local uiWidgetID = delveData.config.gildedStashUiWidgetID
        if uiWidgetID then
            local result = C_UIWidgetManager.GetSpellDisplayVisualizationInfo(uiWidgetID)
            if result then
                return result
            end
        end
    end

    return nil
end

function DelveCompanionOverviewGildedStashFrameMixin:OnShow()
    -- log("GildedStash OnShow start")

    if not self:CanRetrieveGildedStashInfo() then
        self.ErrorLabel:Show()
        self.Container:Hide()
        return
    end

    local stashDisplayInfo = self:TryGetStashInfo()
    if stashDisplayInfo then
        local tooltipDesc = stashDisplayInfo.spellInfo.tooltip
        local collectedCount = tonumber(strsub(strmatch(tooltipDesc, _G["GENERIC_FRACTION_STRING"]), 1, 1))
        self.tooltipDesc = tooltipDesc

        C_Timer.After(0.15, function()
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

            self.ErrorLabel:Hide()
            self.Container:Show()
        end)
    end

    -- if not DelveCompanionCharacterData.GildedStashData.isInited then
    --     log("Not inited, false")
    --     return false
    -- end
    -- DelveCompanionCharacterData.GildedStashData.cachedGildedStashCount = collectedCount
    -- DelveCompanionCharacterData.GildedStashData.isInited = true
end

--============ Bountiful Frame ======================

DelveCompanionOverviewBountifulButtonMixin = {}

function DelveCompanionOverviewBountifulButtonMixin:OnLoad()
    -- log("OverviewBountifulButton OnLoad start")
    -- NOTE: BountifulButton is acquired from a FramePool so OnLoad is called only once per button lifetime.
    -- Only one-time initializations here.
end

function DelveCompanionOverviewBountifulButtonMixin:OnEvent(event, ...)
    self:OnSuperTrackChanged()
end

function DelveCompanionOverviewBountifulButtonMixin:OnShow()
    -- log("OverviewBountifulButton OnShow start")
    self:RegisterEvent("SUPER_TRACKING_CHANGED")

    if DelveCompanionAccountData.useTomTomWaypoints then
        self:CheckTomTomWaypoint()
    else
        self:OnSuperTrackChanged()
    end
end

function DelveCompanionOverviewBountifulButtonMixin:OnHide()
    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
end

function DelveCompanionOverviewBountifulButtonMixin:OnEnter()
    self:UpdateTooltip()
end

function DelveCompanionOverviewBountifulButtonMixin:OnLeave()
    GameTooltip:Hide()
end

function DelveCompanionOverviewBountifulButtonMixin:OnClick()
    if IsShiftKeyDown() then
        self:ToggleTracking()
    end
end

DelveCompanionOverviewBountifulFrameMixin = {}

function DelveCompanionOverviewBountifulFrameMixin:OnLoad()
    -- log("OverviewBountifulFrame OnLoad start")
    self.Title:SetText(lockit["ui-common-bountiful-delve"])

    self.ActiveDelves.NoBountifulLabel:SetText(lockit["ui-no-active-bountiful"])
    self.bountifulButtonsPool = CreateFramePool("BUTTON", self.ActiveDelves.Container,
        "DelveCompanionOverviewBountifulButtonTemplate")
end

function DelveCompanionOverviewBountifulFrameMixin:OnEvent(event, ...)
    -- log("OverviewBountifulFrame OnEvent start")
end

function DelveCompanionOverviewBountifulFrameMixin:OnShow()
    -- log("OverviewBountifulFrame OnShow start")
    addon.CacheActiveBountiful()
    self.bountifulButtonsPool:ReleaseAll()
    self.ActiveDelves.NoBountifulLabel:Hide()

    for index, delveData in ipairs(addon.delvesData) do
        if delveData.isBountiful then
            local button = self.bountifulButtonsPool:Acquire()
            button.layoutIndex = index
            button.data = delveData

            local achIcon = select(10, GetAchievementInfo(delveData.config.achievements.story))
            button.ArtBg:SetTexture(achIcon)

            button:Show()
        end
    end

    local spaceAvailable = self.Title:GetBottom() - self.Divider:GetTop()
    self.ActiveDelves:SetHeight(spaceAvailable)
    self.ActiveDelves.Container.fixedHeight = spaceAvailable
    self.ActiveDelves.Container:Layout()

    if #self.ActiveDelves.Container:GetLayoutChildren() == 0 then
        self.ActiveDelves.NoBountifulLabel:Show()
    end
end

function DelveCompanionOverviewBountifulFrameMixin:OnHide()
    -- log("OverviewBountifulFrame OnHide start")
end

--============ Consumables Widget ======================
DelveCompanionOverviewConsumablesWidgetMixin = {}

function DelveCompanionOverviewConsumablesWidgetMixin:UpdateConsumables()
    addon.CacheKeysData()
    self.Keys.Label:SetText(C_CurrencyInfo.GetCurrencyInfo(addon.config.BOUNTIFUL_KEY_CURRENCY_CODE)
        .quantity)

    self.BountyMap.Label:SetText(C_Item.GetItemCount(addon.config.BOUNTY_MAP_ITEM_CODE))
    self.Echoes.Label:SetText(C_Item.GetItemCount(addon.config.ECHO_ITEM_CODE))

    local shardsCount = C_Item.GetItemCount(addon.config.KEY_SHARD_ITEM_CODE)
    local shardsLine = tostring(shardsCount)
    if shardsCount >= addon.config.SHARDS_FOR_KEY then
        shardsLine = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(tostring(shardsLine))
    end
    self.Shards.Label:SetText(shardsLine)
end

function DelveCompanionOverviewConsumablesWidgetMixin:OnLoad()
    -- log("OverviewConsumablesWidget OnLoad start")

    self.Keys:SetFrameInfo(enums.CodeType.Currency, addon.config.BOUNTIFUL_KEY_CURRENCY_CODE)
    self.Shards:SetFrameInfo(enums.CodeType.Item, addon.config.KEY_SHARD_ITEM_CODE)
    self.BountyMap:SetFrameInfo(enums.CodeType.Item, addon.config.BOUNTY_MAP_ITEM_CODE)
    self.Echoes:SetFrameInfo(enums.CodeType.Item, addon.config.ECHO_ITEM_CODE)
end

function DelveCompanionOverviewConsumablesWidgetMixin:OnEvent(event, ...)
    -- log("OverviewConsumablesWidget OnEvent start")
    C_Timer.After(0.5, function()
        self:UpdateConsumables()
    end)
end

function DelveCompanionOverviewConsumablesWidgetMixin:OnShow()
    -- log("OverviewConsumablesWidget OnShow start")
    self:UpdateConsumables()
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:RegisterEvent("BAG_UPDATE")
end

function DelveCompanionOverviewConsumablesWidgetMixin:OnHide()
    -- log("OverviewConsumablesWidget OnHide start")
    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:UnregisterEvent("BAG_UPDATE")
end

--============ Init ======================

function DelveCompanion_DelvesDashExtension_Init()
    local lootInfoFrame = CreateFrame("Frame", "$parent.LootInfoFrame", DelvesDashboardFrame,
        "DelveCompanionLootInfoFrame")
    addon.lootInfoFrame = lootInfoFrame

    if DelveCompanionCharacterData.gvDetailsEnabled then
        local gvPanel = DelvesDashboardFrame.ButtonPanelLayoutFrame.GreatVaultButtonPanel

        local gvDetailsFrame = CreateFrame("Frame",
            "$parent.CustomDetails",
            gvPanel,
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
