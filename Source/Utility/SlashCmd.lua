local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Config
local Config = DelveCompanion.Config
---@type Lockit
local Lockit = DelveCompanion.Lockit

--#region Constants

---@type string Debug subcommand: `/delvecomp data` prints Delves data, `/delvecomp data reset` simulates a daily reset.
local DEBUG_DATA_COMMAND = "data"
---@type string
local DEBUG_DATA_RESET_ARG = "reset"
--#endregion

--- Name of an enum value, for debug output.
---@param enum table<string, number>
---@param value number
---@return string
local function GetEnumName(enum, value)
    for name, enumValue in pairs(enum) do
        if enumValue == value then
            return name
        end
    end

    return tostring(value)
end

--- Debug output of DelvesData. Not localized on purpose.
---@param arg string?
local function HandleDataCommand(arg)
    local DelvesData = DelveCompanion.DelvesData

    if arg == DEBUG_DATA_RESET_ARG then
        print("[DelveCompanion] Simulating a daily reset: refreshes in 5 and 60 seconds.")
        DelvesData:HandleReset("Daily")
        return
    end

    local lastUpdate = DelvesData:GetLastUpdate()
    print(string.format("[DelveCompanion] Delves data. Last full refresh: %s",
        lastUpdate and string.format("%.0f s ago", GetTime() - lastUpdate) or "never"))

    local kinds = DelveCompanion.Definitions.DelveKind
    local statuses = DelveCompanion.Definitions.DelveStoryStatus
    for record in DelvesData:IterateAll() do
        print(string.format("  [%d] %s (%d) | %s | bountiful: %s | poi: %s | story: %s (%s)",
            record.expansion, record.delveName, record.id,
            GetEnumName(kinds, record.kind),
            tostring(record.isBountiful), tostring(record.poiID),
            GetEnumName(statuses, record.storyStatus), tostring(record.storyVariant)))
    end
end

SLASH_DELVECOMPANION_SHOWDELVES1 = "/delvecompanion"
SLASH_DELVECOMPANION_SHOWDELVES2 = "/delvecomp"
SLASH_DELVECOMPANION_SHOWDELVES3 = "/delves"
SlashCmdList["DELVECOMPANION_SHOWDELVES"] = function(msg)
    local command, arg = strsplit(" ", strlower(strtrim(msg or "")), 2)
    if command == DEBUG_DATA_COMMAND then
        HandleDataCommand(arg)
        return
    end

    DelveCompanion_CompartmentOnClick(addonName, DelveCompanion.Definitions.ButtonAlias.leftClick)
end
