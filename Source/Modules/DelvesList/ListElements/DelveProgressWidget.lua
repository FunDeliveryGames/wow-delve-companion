local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger

--- Delve widget displayed for each Delve button in the Delves list.
---@class (exact) DelvesProgressWidget : DelvesProgressWidgetXml
DelveCompanion_DelveProgressWidgetMixin = {}

function DelveCompanion_DelveProgressWidgetMixin:ToggleShown(isShown)
    if isShown then
        self:Show()
    else
        self:Hide()
    end
end

function DelveCompanion_DelveProgressWidgetMixin:OnLoad()
    EventRegistry:RegisterCallback(DelveCompanion.Enums.Events.ON_SETTING_CHANGED, function(_, changedVarKey, newValue)
        if not changedVarKey == "delveProgressWidgetsEnabled" then
            return
        end

        self:ToggleShown(newValue)
    end, self)

    self:ToggleShown(DelveCompanionAccountData.delveProgressWidgetsEnabled)
end

--#region Xml annotations

--- `DelveCompanionDelveProgressWidgetTemplate`
---@class DelvesProgressWidgetXml : Frame
---@field Story IconWithLabelAndTooltip
---@field Chest IconWithLabelAndTooltip
--#endregion
