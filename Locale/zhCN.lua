if GetLocale() ~= "zhCN" then
    return
end

local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit
--====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================

-- Common

Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE = "丰裕地下堡"

-- Delves List

Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION = "<Shift + 左键：设置地下堡的路径点>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT = "路径点设置"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION = "<Shift + 左键：清空路径点>"

-- Delves UI

Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA = "在卡兹阿加地区时可获取鎏金藏匿物进度"
Lockit.UI_GILDED_STASH_BOUNTIFUL_NOTE = "仅出现在 |cnNORMAL_FONT_COLOR:难度 11|r 丰裕地下堡|A:delves-bountiful:16:16|a。"
Lockit.UI_NO_ACTIVE_BOUNTIFUL = "任意难度11丰裕地下堡可激活进度"

-- Loot Info

Lockit.UI_LOOT_INFO_DESCRIPTION = "完成地下堡获取战利品："

-- Keys Info

Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX = "宝箱里获取的钥匙数量"

-- Settings
Lockit.UI_SETTINGS_MISSING_ADDON_TITLE = "缺少必需的插件：%s" -- %s: name of the missing AddOn, e.g. DelveCompanion

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "账号设置"
Lockit.UI_SETTINGS_ACH_WIDGETS = "冒险指南-地下堡：显示地下堡成就进度（故事和探索）。"
Lockit.UI_SETTINGS_TOMTOM_DESCRIPTION = "路径点风格：使用 TomTom 路径点替代暴雪导航点。"

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "角色设置"
Lockit.UI_SETTINGS_GV_DETAILS = "地下堡：显示详细的宏伟宝库奖励。"
Lockit.UI_SETTINGS_DASHBOARD_OVERVIEW = "地下堡：显示地下堡的其他概要（鎏金藏匿物，丰裕地下堡）。"
Lockit.UI_SETTINGS_KEYS_CAP = "鼠标提示：显示每周宝箱获取的钥匙数量。"
Lockit.UI_SETTINGS_TRANSLATION_TITLE = "特别鸣谢翻译贡献者："
