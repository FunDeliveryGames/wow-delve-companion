local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

--- `Frame` with a map name displayed in the `Delves list` to group Delves.
---@class (exact) DelvesMapHeader : DelvesMapHeaderXml

--#region XML Annotations

--- `DelveCompanionDelveMapHeaderTemplate`
---@class DelvesMapHeaderXml : Frame
---@field Background Texture
---@field MapName FontString Localized name of the map
--#endregion
