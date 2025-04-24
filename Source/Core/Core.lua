local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

-- TODO: Explore a new Settings API. Maybe Settings.RegisterAddOnSetting is more convenient way to setup settings.
DelveCompanion.InitSettings = function()
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

DelveCompanion.eventsCatcherFrame = CreateFrame("Frame")
DelveCompanion.eventsCatcherFrame:RegisterEvent("ADDON_LOADED")
DelveCompanion.eventsCatcherFrame:RegisterEvent("PLAYER_LOGIN")
-- addon.eventsCatcherFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- addon.eventsCatcherFrame:RegisterEvent("GOSSIP_SHOW")
-- addon.eventsCatcherFrame:RegisterEvent("UPDATE_UI_WIDGET")
-- addon.eventsCatcherFrame:RegisterEvent("LOOT_OPENED")

--- TODO: split creation and parenting to reduce load dependencies. Check LoadAddon.
DelveCompanion.eventsCatcherFrame:SetScript(
    "OnEvent",
    function(self, event, arg1, arg2, ...)
        if event == "ADDON_LOADED" then
            local Enums = DelveCompanion.Enums
            local loadedName = arg1

            if loadedName == Enums.DependencyAddonName.delvesDashboardUI then
                if DelvesDashboardFrame == nil then
                    Logger.Log("DelvesDashboardFrame is nil. Delves UI extension is not inited.")
                    return
                end

                if DelveCompanion.Variables.maxLevelReached then
                    DelveCompanion_DelvesDashExtension_Init()
                end
            elseif loadedName == Enums.DependencyAddonName.encounterJournal then
                if EncounterJournal == nil then
                    Logger.Log("EncounterJournal is nil. Delves tab is not inited.")
                    return
                end

                DelveCompanion_DelvesListFrame_Init()
            else
                return
            end
        elseif event == "PLAYER_LOGIN" then
            DelveCompanion.InitSettings()
            -- elseif event == "PLAYER_ENTERING_WORLD" then
        elseif event == "WEEKLY_REWARDS_UPDATE" then
            if DelveCompanion.gvDetailsFrame:IsShown() then
                DelveCompanion.gvDetailsFrame:Refresh()
            else
                DelveCompanion.gvDetailsFrame.shouldRefresh = true
            end
            return
            -- elseif event == "GOSSIP_SHOW" then
            --     if arg1 == "delves-difficulty-picker" then
            --         local options = DelvesDifficultyPickerFrame:GetOptions()
            --         for key, value in pairs(options) do
            --             Logger.Log("%s: %s", key, tostring(value.gossipOptionID))
            --         end

            --         for key, value in pairs(DelvesDifficultyPickerFrame.DelveModifiersWidgetContainer.widgetFrames) do
            --             Logger.Log("%s: %s (index: %d)", key, tostring(value),
            --                 C_UIWidgetManager.GetSpellDisplayVisualizationInfo(key).orderIndex)
            --         end
            --     end
        elseif event == "QUEST_LOG_UPDATE" then
            DelveCompanion:CacheKeysCount()
            return
            -- elseif event == "UPDATE_UI_WIDGET" then
            --     local wi = arg1
            --     for key, value in pairs(wi) do
            --         Logger.Log("%s: %s", key, tostring(value))
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

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    DelveCompanion:OnAddonLoaded()
end)
