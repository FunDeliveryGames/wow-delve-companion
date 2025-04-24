local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

--- Table containing all addon runtime variables.
---@class Variables
---@field delvesData DelveData[] Table containing all Delves' runtime data (see [DelveData](lua://DelveData)).
---@field maxLevelReached boolean Whether player has reached max level of the current expansion.
---@field keysCollected integer Number of [Restored Coffer Keys](https://www.wowhead.com/currency=3028/restored-coffer-key) player has collected this week.
local Variables = {
    delvesData = {},
    maxLevelReached = false,
    keysCollected = 0
}
DelveCompanion.Variables = Variables
