local addonName, AddonTbl = ...

--- Addon metatable containing all functions and variables it uses.
---@class (exact) DelveCompanion
---@field Logger Logger
---@field Config Config
---@field Lockit Lockit
---@field Enums Enums
---@field Variables Variables
AddonTbl.DelveCompanion = {}

--#region Shared annotations

--- Utility class representing map coordinates.
---@class MapCoord
---@field x number X-coordinate on the map [0.0–100.0].
---@field y number Y-coordinate on the map [0.0–100.0].


--#endregion
