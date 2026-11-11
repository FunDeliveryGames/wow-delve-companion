local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

--- Table containing all addon runtime variables.
---@class (exact) Variables
---@field LootInfoFrame LootInfoFrame Loot Info frame. Can be shown from different places.
---@field maxLevelReached boolean Whether player has reached max level of the current expansion.
---@field tomTomAvailable boolean Whether TomTom addon is loaded.
---@field mpeAvailable boolean Whether MapPinEnhanced addon is loaded.
---@field elvUIAvailable boolean Whether ElvUI addon is loaded.
---@field ellesmereUIAvailable boolean Whether EllesmereUI addon is loaded.
---@field isPTR boolean A flag used to check client version: Mainline or PTR.
local Variables = {
    LootInfoFrame = nil,
    maxLevelReached = false,
    tomTomAvailable = false,
    mpeAvailable = false,
    elvUIAvailable = false,
    ellesmereUIAvailable = false,
    isPTR = (select(4, GetBuildInfo())) >= 120107
}
DelveCompanion.Variables = Variables
