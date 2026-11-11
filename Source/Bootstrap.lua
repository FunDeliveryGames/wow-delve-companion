local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config

--#region Constants

--- Account setting turning UISkin on/off. Read by UISkin once, on init.
---@type string
local UI_SKIN_SAVE_KEY = "uiSkinEnabled"
--#endregion

---@class (exact) Bootstrap
local Bootstrap = {}

-- Check whether any optional dependencies are loaded.
---@param self Bootstrap
function Bootstrap:ProcessOptionalDependencies()
    DelveCompanion.Variables.tomTomAvailable = TomTom ~= nil
    DelveCompanion.Variables.mpeAvailable = MapPinEnhanced ~= nil
    DelveCompanion.Variables.elvUIAvailable = ElvUI ~= nil
    DelveCompanion.Variables.ellesmereUIAvailable = EllesmereUI ~= nil
end

---@param self Bootstrap
function Bootstrap:OnAddonLoaded()
    -- Logger:Log("[DelveCompanion Bootstrap] OnAddonLoaded start...")

    self:ProcessOptionalDependencies() -- Should be before any other initializations!

    DelveCompanion.AddonSettings:ProcessAccountSave()
    DelveCompanion.AddonSettings:ProcessCharacterSave()

    -- Before any frame is created. Also waits for PLAYER_LOGIN to give up a suite that never reports ready.
    DelveCompanion.UISkin:Init({
        savedVariables = DelveCompanionAccountData,
        saveKey = UI_SKIN_SAVE_KEY,
        defaultEnabled = Config.DEFAULT_ACCOUNT_DATA[UI_SKIN_SAVE_KEY],
        log = function(message)
            Logger:Log("%s", message)
        end
    })

    DelveCompanion.InDelveWidget:PreloadFrame()

    -- Logger:Log("[DelveCompanion Bootstrap] OnAddonLoaded finish")
end

---@param self Bootstrap
function Bootstrap:OnPlayerLogin()
    -- Logger:Log("[DelveCompanion Bootstrap] OnPlayerLogin start...")

    DelveCompanion.AddonSettings:Init()
    DelveCompanion.MinimapIcon:Init()

    DelveCompanion.Variables.maxLevelReached =
        UnitLevel("player") == GetMaxLevelForExpansionLevel(Config.DELVES_MIN_EXPANSION)

    DelveCompanion.ProgressTracker:Init()
    DelveCompanion.InDelveWidget:Init()
    DelveCompanion.GossipExtension:Init()

    DelveCompanion.DelvesData:Init()
    DelveCompanion_TooltipExtension_Init()

    EventUtil.ContinueOnAddOnLoaded(DelveCompanion.Definitions.DependencyAddonName.encounterJournal,
        function()
            DelveCompanion.EJExtension:Init()
        end
    )

    -- Logger:Log("[DelveCompanion Bootstrap] OnPlayerLogin finish")
end

-- EventRegistry:RegisterFrameEventAndCallback("GOSSIP_SHOW", function(payload, arg1, arg2)
--     if arg1 == "delves-difficulty-picker" then
--         -- local options = DelvesDifficultyPickerFrame:GetOptions()
--         Logger:Log("=================")
--         Logger:Log("Modifiers info:")
--         Logger:LogTable(DelvesDifficultyPickerFrame.DelveModifiersWidgetContainer.widgetFrames)
--     end
-- end)

-- 1st
EventUtil.ContinueOnAddOnLoaded(addonName, function()
    Logger:Init()
    Bootstrap:OnAddonLoaded()
end)

-- 2nd
EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    Bootstrap:OnPlayerLogin()
end)
