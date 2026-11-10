local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Definitions
local Definitions = DelveCompanion.Definitions

local LRT = LibStub("LibResetTracker-1.0")

--- Owns the active Story Variant of each Delve and whether it is completed for the story achievement.
--- The variant is read from the tooltip widgets of the Delve's POI, so this provider runs after PoiProvider (it reads `poiID`).
---@class StoryProvider : DelvesDataProvider
local StoryProvider = {
    name = "Story",
    fields = { "storyVariant", "storyStatus" },
    events = { "AREA_POIS_UPDATED", "PLAYER_ENTERING_WORLD", "CRITERIA_EARNED", "ACHIEVEMENT_EARNED" },
    resets = { "Daily" }
}

--- Daily period start (LibResetTracker) when each Delve's variant was last read successfully. Keyed by record ID.
--- Variants rotate daily: a value read in the current period is still valid when a later read fails (e.g. the data isn't loaded inside a Delve).
---@type table<number, number>
local readPeriods = {}

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

---@param self DelvesDataProvider
---@param record DelveRecord
function StoryProvider:InitRecord(record)
    record.storyVariant = nil
    record.storyStatus = Definitions.DelveStoryStatus.Unknown
end

--- Only achievement events of tracked story achievements are relevant, and only for that Delve.
---@param self DelvesDataProvider
---@param svc DelvesData
---@param event string
---@param achievementID number?
function StoryProvider:FilterEvent(svc, event, achievementID)
    if event == "CRITERIA_EARNED" or event == "ACHIEVEMENT_EARNED" then
        local record = achievementID and svc:GetByStoryAchievement(achievementID)
        return record and { record } or false
    end

    return true
end

--- Read the active Story Variant label from the POI tooltip widgets.
---@param record DelveRecord
---@return string? variant `nil` if not found.
---@return boolean isSecret Whether the label exists but is a secret value.
local function ReadStoryVariant(record)
    if not record.parentMapID then
        return nil, false
    end

    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(record.parentMapID, record.poiID)
    if not (poiInfo and poiInfo.tooltipWidgetSet) then
        return nil, false
    end

    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(poiInfo.tooltipWidgetSet)
    if not widgets then
        return nil, false
    end

    for _, widgetInfo in ipairs(widgets) do
        if widgetInfo.widgetType == Enum.UIWidgetVisualizationType.TextWithState then
            local visInfo = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(widgetInfo.widgetID)

            if visInfo and visInfo.orderIndex == 0 then
                if IsSecret(visInfo.text) then
                    return nil, true
                end

                return visInfo.text, false
            end
        end
    end

    return nil, false
end

--- Some Story Variants are not part of the story achievement (they were added during the expansion).
--- The goal is to highlight achievement progress, so such variants are `NotTracked` and displayed as completed.
---@param record DelveRecord
---@param variant string?
---@return number status A value of DelveStoryStatus.
local function ResolveStatus(record, variant)
    local statuses = Definitions.DelveStoryStatus

    if type(variant) ~= "string" or variant == "" then
        return statuses.Unknown
    end

    local achievementID = record.config.achievements and record.config.achievements.story
    if not achievementID then
        return statuses.NotTracked
    end

    local lowerVariant = string.lower(variant)
    for index = 1, GetAchievementNumCriteria(achievementID) or 0 do
        local criteriaString, _, completed = GetAchievementCriteriaInfo(achievementID, index)

        -- Plain search: criteria and variant labels are game strings, not Lua patterns.
        if type(criteriaString) == "string" and criteriaString ~= "" and not IsSecret(criteriaString)
            and string.find(lowerVariant, string.lower(criteriaString), 1, true)
        then
            return completed and statuses.Completed or statuses.NotCompleted
        end
    end

    return statuses.NotTracked
end

---@param self DelvesDataProvider
---@param svc DelvesData
---@param ctx DelvesDataContext
---@param records DelveRecord[]
function StoryProvider:Refresh(svc, ctx, records)
    local currentPeriod = LRT:GetPeriodStart(LRT.Period.Daily)

    for _, record in ipairs(records) do
        local variant, isSecret = ReadStoryVariant(record)

        if variant ~= nil then
            readPeriods[record.id] = currentPeriod or 0
            ctx:Set(record, "storyVariant", variant)
            ctx:Set(record, "storyStatus", ResolveStatus(record, variant))
        else
            local readPeriod = readPeriods[record.id]
            local isStale = readPeriod == nil or (currentPeriod ~= nil and readPeriod ~= currentPeriod)

            if isStale and not isSecret then
                -- Never read, or read before the last daily reset: the variant has rotated since.
                readPeriods[record.id] = nil
                ctx:Set(record, "storyVariant", nil)
                ctx:Set(record, "storyStatus", Definitions.DelveStoryStatus.Unknown)
            elseif record.storyVariant ~= nil then
                -- Keep the variant read earlier today, but re-check completion (e.g. CRITERIA_EARNED inside the Delve).
                ctx:Set(record, "storyStatus", ResolveStatus(record, record.storyVariant))
            end
        end
    end
end

DelveCompanion.DelvesData:RegisterProvider(StoryProvider)
