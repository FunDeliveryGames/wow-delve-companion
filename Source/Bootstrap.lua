local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

local function OnPlayerLogin()
    -- Logger.Log("OnPlayerLogin start...")

    DelveCompanion.AddonSettings:Init()

    -- Logger.Log("OnPlayerLogin finish")
end

local function OnAddonLoaded()
    -- Logger.Log("OnAddonLoaded start...")

    DelveCompanion:InitAccountSave()
    DelveCompanion:InitCharacterSave()

    DelveCompanion:InitDelvesData()

    DelveCompanion.Variables.maxLevelReached = UnitLevel("player") == DelveCompanion.Config.EXPANSION_MAX_LEVEL
    DelveCompanion.Variables.tomTomAvailable = TomTom ~= nil

    if DelveCompanion.Variables.maxLevelReached then
        DelveCompanion_TooltipExtension_Init()
    end

    -- Logger.Log("OnAddonLoaded finish")
end

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", OnPlayerLogin)
EventUtil.ContinueOnAddOnLoaded(addonName, OnAddonLoaded)
