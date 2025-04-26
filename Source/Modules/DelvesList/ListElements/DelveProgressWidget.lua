local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

--- Delve widget displayed for each Delve button in the Delves list.
---@class (exact) DelvesProgressWidget : DelvesProgressWidgetXml
DelveCompanion_DelveProgressWidgetMixin = {}

--#region DelvesProgressWidgetXml annotations

---@class DelvesProgressWidgetXml : Frame
---@field Story IconWithLabelAndTooltip
---@field Chest IconWithLabelAndTooltip
--#endregion
