local addonName, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion
---@type Config
local Config = DelveCompanion.Config
---@type DelveCompanionAccountData
local AccSaveData = DelveCompanionAccountData

--#region Constants

local CONTROL_SAVE_KEY = "logsEnabled"
--#endregion

--- Utility class for printing debug information.
---@class Logger
local Logger = {}
DelveCompanion.Logger = Logger

-- Top-level toggle to control logging.
local logsEnabled = false

--- Log a formatted string to the console if logging is enabled.
--- Acts as a wrapper around `print(string.format(...))`.
---@param self Logger
---@param stringText string The format string. Supports placeholders like %s, %d, etc.
---@param ... any Arguments to be substituted into the format string.
function Logger:Log(stringText, ...)
    if not logsEnabled then
        return
    end

    print(string.format(stringText, ...))
end

--- Log the contents of a table as key-value pairs.
--- Only top-level entries are shown; nested tables and functions are not recursively expanded.
---@param self Logger
---@param tbl table The table to log.
---@param keyPattern string? Pattern used to match only specific keys.
function Logger:LogTable(tbl, keyPattern)
    if type(tbl) ~= "table" then
        return
    end

    self:Log("==== Table dump ====")
    for key, value in pairs(tbl) do
        local canPrint = true
        if keyPattern and not strmatch(key, keyPattern) then
            canPrint = false
        end

        if canPrint then
            self:Log("Key: %s | Value: %s", key, tostring(value))
        end
    end
    self:Log("==== End ====")
end

---@param self Logger
function Logger:Init()
    logsEnabled = AccSaveData ~= nil and AccSaveData.logsEnabled
        or Config.DEFAULT_ACCOUNT_DATA.logsEnabled

    do
        local function OnSettingChanged(_, changedVarKey, newValue)
            if changedVarKey == CONTROL_SAVE_KEY then
                logsEnabled = newValue
            end
        end

        EventRegistry:RegisterCallback(DelveCompanion.Definitions.Events.SETTING_CHANGE, OnSettingChanged, self)
    end
end
