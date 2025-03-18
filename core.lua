local addonName, addon = ...
local log = addon.log
local enums = addon.enums

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

-- TODO: Explore a new Settings API. Maybe Settings.RegisterAddOnSetting is more convenient way to setup settings.
addon.InitSettings = function()
    local addonNameStr = tostring(addonName) -- TODO: explore why addonName can be a table instead of a string
    local settingsFrame = CreateFrame("Frame", addonNameStr, nil, "DelveCompanionSettingsFrame")
    settingsFrame.name = addonNameStr
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(settingsFrame, settingsFrame.name)
        category.ID = settingsFrame.name
        Settings.RegisterAddOnCategory(category)
    end
end

addon.Init = function()
    addon.InitSettings()

    local playerLevel = UnitLevel("player")
    local maxLevel = GetMaxLevelForExpansionLevel(GetServerExpansionLevel())
    addon.maxLevelReached = playerLevel == maxLevel
end

function DelveCompanionShowSettings()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(tostring(addonName))
    end
end

-- Addon Boot

addon.eventsCatcherFrame = CreateFrame("Frame")
addon.eventsCatcherFrame:RegisterEvent("ADDON_LOADED")
-- addon.eventsCatcherFrame:RegisterEvent("PLAYER_LOGIN")
-- addon.eventsCatcherFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- addon.eventsCatcherFrame:RegisterEvent("LOOT_OPENED")
--- TODO: split creation and parenting to reduce load dependencies. Check LoadAddon.
addon.eventsCatcherFrame:SetScript(
    "OnEvent",
    function(_, event, arg1, arg2)
        if event == "ADDON_LOADED" then
            local loadedName = arg1
            if loadedName == addonName then
                addon.Init()

                if addon.maxLevelReached == false then
                    return
                end
                DelveCompanion_TooltipExtension_Init()
            elseif loadedName == enums.DependencyAddonNames.delvesDashboardUI then
                if DelvesDashboardFrame == nil then
                    log("DelvesDashboardFrame is nil. Delves UI extention is not inited.")
                    return
                end

                if addon.maxLevelReached == false then
                    return
                end

                DelveCompanion_DelvesDashExtension_Init()
            elseif loadedName == enums.DependencyAddonNames.encounterJournal then
                if EncounterJournal == nil then
                    log("EncounterJournal is nil. Delves tab is not inited.")
                    return
                end

                DelveCompanion_DelvesListFrame_Init()
            else
                return
            end
            -- elseif event == "PLAYER_LOGIN" then
            -- elseif event == "PLAYER_ENTERING_WORLD" then
        elseif event == "WEEKLY_REWARDS_UPDATE" then
            if addon.gvDetailsFrame:IsShown() then
                addon.gvDetailsFrame:Refresh()
            else
                addon.gvDetailsFrame.shouldRefresh = true
            end
        elseif event == "QUEST_LOG_UPDATE" then
            addon.CacheKeysData()
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
