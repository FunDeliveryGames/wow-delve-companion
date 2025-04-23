if GetLocale() ~= "zhCN" then
    return
end

local _, Addon = ...
---@type Logger
local Logger = Addon.Logger
local lockit = Addon.lockit
--====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================

-- Common

lockit["ui-common-bountiful-delve"] = "丰裕地下堡"

-- Delves List

lockit["ui-delve-instance-button-tooltip-click-instruction"] = "<Shift + 左键：设置地下堡的路径点>"
lockit["ui-delve-instance-button-tooltip-current-text"] = "路径点设置"
lockit["ui-delve-instance-button-tooltip-current-instruction"] = "<Shift + 左键：清空路径点>"

-- Delves UI

lockit["ui-gilded-stash-cannot-retrieve-data"] = "在卡兹阿加地区时可获取鎏金藏匿物进度"
lockit["ui-gilded-stash-bountiful-note"] = "仅出现在 |cnNORMAL_FONT_COLOR:难度 11|r 丰裕地下堡|A:delves-bountiful:16:16|a。"
lockit["ui-no-active-bountiful"] = "任意难度11丰裕地下堡可激活进度"

-- Loot Info

lockit["ui-loot-info-description"] = "完成地下堡获取战利品："

-- Keys Info

lockit["ui-bountiful-keys-count-caches-prefix"] = "宝箱里获取的钥匙数量"

-- Settings
lockit["ui-settings-missing-addon-title"] = "缺少必需的插件：%s" -- %s: name of the missing AddOn, e.g. DelveCompanion

lockit["ui-settings-section-title-account"] = "账号设置"
lockit["ui-settings-ach-widgets"] = "冒险指南-地下堡：显示地下堡成就进度（故事和探索）。"
lockit["ui-settings-tomtom-description"] = "路径点风格：使用 TomTom 路径点替代暴雪导航点。"

lockit["ui-settings-section-title-character"] = "角色设置"
lockit["ui-settings-gv-details"] = "地下堡：显示详细的宏伟宝库奖励。"
lockit["ui-settings-dashboard-overview"] = "地下堡：显示地下堡的其他概要（鎏金藏匿物，丰裕地下堡）。"
lockit["ui-settings-keys-cap"] = "鼠标提示：显示每周宝箱获取的钥匙数量。"
lockit["ui-settings-translation-title"] = "特别鸣谢翻译贡献者："
