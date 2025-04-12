local addonName, addon = ...
local log = addon.log
local enums = addon.enums

addon.CacheActiveBountiful = function()
    -- log("Start fetching boutiful delves...")
    for _, delveData in ipairs(addon.delvesData) do
        local delveConfig = delveData.config
        local parentMapID = C_Map.GetMapInfo(delveConfig.uiMapID).parentMapID
        local poiIDs = delveConfig.poiIDs

        if poiIDs.bountiful ~= nil then
            local bountifulDelve = C_AreaPoiInfo.GetAreaPOIInfo(parentMapID, poiIDs.bountiful)
            if bountifulDelve ~= nil then
                delveData.poiID = poiIDs.bountiful
                delveData.isBountiful = true
            else
                delveData.poiID = poiIDs.regular
                delveData.isBountiful = false
            end
        end
    end
    -- log("Finished fetching boutiful delves...")
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

addon.GetContinentMapIDForMap = function(mapID)
    if not mapID then
        return nil
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    while mapInfo and mapInfo.mapType ~= Enum.UIMapType.Continent do
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end

    if mapInfo then
        return mapInfo.mapID
    end

    return nil
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

function DelveCompanionShowSettings()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(tostring(addonName))
    end
end

local function InitAccountSave()
    DelveCompanionAccountData = {
        achievementWidgetsEnabled = true,
        useTomTomWaypoints = false
    }
end

local function InitCharacterSave()
    DelveCompanionCharacterData = {
        gvDetailsEnabled = true,
        keysCapTooltipEnabled = true,
        dashOverviewEnabled = true
    }
end

local function PrepareDelvesData()
    local delvesData = {}

    for _, delveConfig in ipairs(addon.config.DELVES_REGULAR_DATA) do
        local delveMap = C_Map.GetMapInfo(delveConfig.uiMapID)

        local dataEl = {
            config = delveConfig,
            poiID = nil,
            tomtom = nil,
            delveName = delveMap.name,
            parentMapName = C_Map.GetMapInfo(delveMap.parentMapID).name,
            isTracking = false,
            isBountiful = false
        }

        table.insert(delvesData, dataEl)
    end

    addon.delvesData = delvesData
end

-- Addon Boot
addon.Init = function()
    if not DelveCompanionAccountData then
        InitAccountSave()
    end

    if not DelveCompanionCharacterData then
        InitCharacterSave()
    end

    addon.InitSettings()

    PrepareDelvesData()

    addon.maxLevelReached = UnitLevel("player") == addon.config.MAX_LEVEL
end


addon.eventsCatcherFrame = CreateFrame("Frame")
addon.eventsCatcherFrame:RegisterEvent("ADDON_LOADED")
-- addon.eventsCatcherFrame:RegisterEvent("PLAYER_LOGIN")
-- addon.eventsCatcherFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- addon.eventsCatcherFrame:RegisterEvent("GOSSIP_SHOW")
-- addon.eventsCatcherFrame:RegisterEvent("UPDATE_UI_WIDGET")
-- addon.eventsCatcherFrame:RegisterEvent("LOOT_OPENED")

--- TODO: split creation and parenting to reduce load dependencies. Check LoadAddon.
addon.eventsCatcherFrame:SetScript(
    "OnEvent",
    function(self, event, arg1, arg2, ...)
        if event == "ADDON_LOADED" then
            local loadedName = arg1
            if loadedName == addonName then
                addon.Init()

                if addon.maxLevelReached then
                    DelveCompanion_TooltipExtension_Init()
                end
            elseif loadedName == enums.DependencyAddonName.delvesDashboardUI then
                if DelvesDashboardFrame == nil then
                    log("DelvesDashboardFrame is nil. Delves UI extension is not inited.")
                    return
                end

                if addon.maxLevelReached then
                    DelveCompanion_DelvesDashExtension_Init()
                end
            elseif loadedName == enums.DependencyAddonName.encounterJournal then
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
            return
            -- elseif event == "GOSSIP_SHOW" then
            --     if arg1 == "delves-difficulty-picker" then
            --         local options = DelvesDifficultyPickerFrame:GetOptions()
            --         for key, value in pairs(options) do
            --             log("%s: %s", key, tostring(value.gossipOptionID))
            --         end

            --         for key, value in pairs(DelvesDifficultyPickerFrame.DelveModifiersWidgetContainer.widgetFrames) do
            --             log("%s: %s (index: %d)", key, tostring(value),
            --                 C_UIWidgetManager.GetSpellDisplayVisualizationInfo(key).orderIndex)
            --         end
            --     end
        elseif event == "QUEST_LOG_UPDATE" then
            addon.CacheKeysData()
            return
            -- elseif event == "UPDATE_UI_WIDGET" then
            --     local wi = arg1
            --     for key, value in pairs(wi) do
            --         log("%s: %s", key, tostring(value))
            --     end
            --     return
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
