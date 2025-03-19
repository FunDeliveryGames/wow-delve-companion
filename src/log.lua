local addonName, addon = ...

addon.enableLogs = true
addon.log = function(stringText, ...)
    if addon.enableLogs then
        print(string.format(stringText, ...))
    end
end
