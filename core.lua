local addonName, addon = ...
local log = addon.log

addon.CacheActiveBountiful = function()
    --log("Start fetching boutiful delves...")
    local activeBountifulDelves = {}
    for _, delveConfig in ipairs(addon.config.DELVES_REGULAR_DATA) do
        local parentMapID = C_Map.GetMapInfo(delveConfig.uiMapID).parentMapID
        local poiIDs = delveConfig.poiIDs

        if poiIDs.bountiful ~= nil then
            local bountifulDelve = C_AreaPoiInfo.GetAreaPOIInfo(parentMapID, poiIDs.bountiful)
            if bountifulDelve ~= nil then
                table.insert(activeBountifulDelves, poiIDs.bountiful)
            end
        end
    end

    addon.activeBountifulDelves = activeBountifulDelves
end

addon.SetTrackedDelve = function(instanceButton)
    if instanceButton == nil then
        log("[SetTrackedDelve] Cannot set SuperTrack. Missing button reference")
    end

    if addon.delvesListFrame.trackedDelveButton ~= nil and addon.delvesListFrame.trackedDelveButton ~= instanceButton then
        addon.delvesListFrame.trackedDelveButton.waypointIcon:Hide()
        addon.delvesListFrame.trackedDelveButton.isTracking = false
    end

    instanceButton.waypointIcon:Show()
    instanceButton.isTracking = true
    addon.delvesListFrame.trackedDelveButton = instanceButton
end

addon.ClearTrackedDelve = function(instanceButton)
    if instanceButton == nil then
        log("[ClearTrackedDelve] Cannot clear SuperTrack. Missing button reference")
    end

    instanceButton.waypointIcon:Hide()
    instanceButton.isTracking = false

    addon.delvesListFrame.trackedDelveButton = nil
end

addon.CacheKeysData = function()
    local keysCollected = 0
    for _, questId in ipairs(addon.config.BOUNTIFUL_KEY_QUESTS_DATA) do
        if C_QuestLog.IsQuestFlaggedCompleted(questId) then
            keysCollected = keysCollected + 1
        end
    end

    addon.keysCollected = keysCollected
end

addon.CacheGreatVaultRewards = function()
    local gvRewards = {}
    local activityInfo = C_WeeklyRewards.GetActivities(addon.activityType)
    if not activityInfo then return end

    for index, rewInfo in ipairs(activityInfo) do
        local itemLevel = 0
        local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(rewInfo.id)
        if itemLink then
            itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink) or 0
        end

        table.insert(gvRewards, index, { itemLevel = itemLevel, delveTier = rewInfo.level })
    end

    addon.gvRewards = gvRewards
end

-- TODO: polish
addon.CreateSettingsFrame = function()
    if addon.settingsFrame == nil then
        local settingsFrame = CreateFrame("Frame", "DelveCompanionSettingsFrame", UIParent,
            "DefaultPanelTemplate")
        settingsFrame:Hide()
        settingsFrame:SetSize(300, 200)
        settingsFrame:SetPoint("CENTER")
        settingsFrame.TitleContainer.TitleText:SetText(_G["SETTINGS"])

        CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButtonDefaultAnchors")

        local gvDetailsCheckButton = CreateFrame("CheckButton", nil, settingsFrame, "ChatConfigCheckButtonTemplate")
        gvDetailsCheckButton:SetPoint("TOPLEFT", 15, -40)
        gvDetailsCheckButton:SetChecked(DelveCompanionCharacterData.gvDetailsEnabled)
        gvDetailsCheckButton.Text:SetText("Enable Great Vault details")
        -- gvDetailsCheckButton.tooltip = "This is where you place MouseOver Text."
        gvDetailsCheckButton:HookScript("OnClick", function(self)
            DelveCompanionCharacterData.gvDetailsEnabled = self:GetChecked()
        end)

        local keysCapTooltipCheckButton = CreateFrame("CheckButton", nil, settingsFrame, "ChatConfigCheckButtonTemplate")
        keysCapTooltipCheckButton:SetPoint("TOPLEFT", 15, -80)
        keysCapTooltipCheckButton:SetChecked(DelveCompanionCharacterData.keysCapTooltipEnabled)
        keysCapTooltipCheckButton.Text:SetText("Display Keys weekly cap")
        -- gvDetailsCheckButton.tooltip = "This is where you place MouseOver Text."
        keysCapTooltipCheckButton:HookScript("OnClick", function(self)
            DelveCompanionCharacterData.keysCapTooltipEnabled = self:GetChecked()
        end)

        local reloadButton = CreateFrame("Button", nil, settingsFrame, "MagicButtonTemplate")
        reloadButton:SetSize(200, 30)
        reloadButton:SetPoint("BOTTOM", 0, 15)
        reloadButton:SetText(_G["RELOADUI"])
        reloadButton:SetScript("OnMouseUp", function()
            C_UI.Reload()
        end)

        addon.settingsFrame = settingsFrame
    end
end

addon.Init = function()
    if not DelveCompanionCharacterData then
        DelveCompanionCharacterData = {
            gvDetailsEnabled = true,
            keysCapTooltipEnabled = true
        }
    end

    addon.CreateSettingsFrame()

    addon.delvesListFrame = nil
    addon.lootInfoFrame = nil
    addon.activityType = Enum.WeeklyRewardChestThresholdType.World
end

function DelveCompanionShowSettings()
    addon.settingsFrame:Show()
end

local trackedAddonNames = {
    delvesDashboardUI = "Blizzard_DelvesDashboardUI",
    encounterJournal = "Blizzard_EncounterJournal"
}

-- Addon Boot

addon.eventsCatcherFrame = CreateFrame("Frame")
addon.eventsCatcherFrame:RegisterEvent("ADDON_LOADED")
-- eventsCatcherFrame:RegisterEvent("PLAYER_LOGIN")
-- eventsCatcherFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- eventsCatcherFrame:RegisterEvent("LOOT_OPENED")
--- TODO: split creation and parenting to reduce load dependencies. Check LoadAddon.
addon.eventsCatcherFrame:SetScript(
    "OnEvent",
    function(_, event, arg1, arg2)
        if event == "ADDON_LOADED" then
            local loadedName = arg1
            if loadedName == addonName then
                addon.Init()
                DelveCompanion_TooltipExtension_Init()
            elseif loadedName == trackedAddonNames.delvesDashboardUI then
                if DelvesDashboardFrame == nil then
                    log("DelvesDashboardFrame is nil. Delves UI extention is not inited.")
                    return
                end

                DelveCompanion_DelvesDashExtension_Init()
            elseif loadedName == trackedAddonNames.encounterJournal then
                if EncounterJournal == nil then
                    log("EncounterJournal is nil. Delves tab is not inited.")
                    return
                end

                DelveCompanion_DelvesListFrame_Init()
                -- elseif event == "PLAYER_LOGIN" then
                --     return
                -- elseif event == "PLAYER_ENTERING_WORLD" then
                --     return
            else
                return
            end
        elseif event == "QUEST_LOG_UPDATE" then
            addon.CacheKeysData()
            return
        elseif event == "WEEKLY_REWARDS_UPDATE" then
            addon.CacheGreatVaultRewards()
            return
            -- elseif event == "LOOT_OPENED" then
            --     for i = 1, GetNumLootItems() do
            --         local sources = { GetLootSourceInfo(i) }
            --         local _, name = GetLootSlotInfo(i)
            --         for j = 1, #sources, 2 do
            --             print(i, name, j, sources[j], sources[j + 1])
            --         end
            --     end
            --     return
        end
    end
)
