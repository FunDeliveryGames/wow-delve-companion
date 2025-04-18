local addonName, addon = ...

addon.enableLogs = true
addon.log = function(stringText, ...)
    if not addon.enableLogs then
        return
    end

    print(string.format(stringText, ...))
end

addon.logTable = function(table, ...)
    if type(table) ~= "table" then
        return
    end

    for key, value in pairs(table) do
        addon.log("Key: %s | Value: %s", key, tostring(value))
    end
end
