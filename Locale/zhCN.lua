if GetLocale() ~= "zhCN" then return end

local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit
-- ====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================

-- Common

Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE = "丰裕地下堡"
Lockit.UI_COMMON_MISSING_ADDON_TITLE = "缺少必需的插件：%s" -- %s: name of the missing AddOn, e.g. DelveCompanion

-- Delves List

Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION = "<Shift + 左键：设置地下堡的路径点>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT = "路径点设置"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION = "<Shift + 左键：清空路径点>"

-- Delves UI

Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA = "在卡兹阿加地区时可获取鎏金藏匿物进度"
Lockit.UI_GILDED_STASH_BOUNTIFUL_NOTE = "仅出现在 |cnNORMAL_FONT_COLOR:难度 11|r 丰裕地下堡|A:delves-bountiful:16:16|a。"
Lockit.UI_NO_ACTIVE_BOUNTIFUL = "今日所有丰裕地下堡已完成"
Lockit.UI_LOOT_INFO_BUTTON_TOOLTIP_INSTRUCTION = "<左键：显示地下堡战利品信息>"

-- Loot Info

Lockit.UI_LOOT_INFO_DESCRIPTION = "完成地下堡获取战利品："

-- Keys Info

Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX = "宝箱里获取的钥匙数量"

-- Compartment

Lockit.UI_COMPARTMENT_DESCRIPTION_LEFT_CLICK = "Left Click to open information window."
Lockit.UI_COMPARTMENT_DESCRIPTION_RIGHT_CLICK = "Right Click to change options."

-- Settings

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "账号设置"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_NAME = "Delve's Progress Info"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_TOOLTIP = "冒险指南-地下堡：显示地下堡成就进度（故事和探索）。"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_TOOLTIP = "Delves list: Display progress of achievements for each Delve (Stories and Chests)."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_NAME = "Waypoint Tracking Type"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_START = "Select which type of Waypoints are used for navigation.\n\nPossible options:"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_BLIZZARD = "- Blizzard's Map Pin (the defulat in-game navigation)"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_TOMTOM = "- TomTom Waypoints"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_TOMTOM_UNAVAILABLE_FORMAT = "%s (%s)."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_FORMAT = "%s\n%s\n%s"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_BLIZZARD_NAME = "Blizzard"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_BLIZZARD_DESCRIPTION = "Use the Blizzard's Map Pin."
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_TOMTOM_NAME = "TomTom"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_TOMTOM_DESCRIPTION = "Use TomTom Waypoints."

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "角色设置"
Lockit.UI_SETTING_TOOLTIP_EXTENSTION_NAME = "Extra Info in Tooltips"
Lockit.UI_SETTING_TOOLTIP_EXTENSTION_TOOLTIP = "Display additional information in tooltips (E.g. number of |cnITEM_EPIC_COLOR:Restored Coffer Keys|r received this week)."
Lockit.UI_SETTING_COMPANION_CONFIG_NAME = "Companion Config Widget"
Lockit.UI_SETTING_COMPANION_CONFIG_TOOLTIP = "Delves UI: Enable a widget which displays the current specialization and abilities of the Companion.\nIt can be used to modify the configuration directly from the Delves UI."
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_HORIZONTAL_NAME = "Horizontal layout"
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_HORIZONTAL_DESCRIPTION = "A compact layout with the buttons arranged horizontally. The Companion model is kept intact."
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_VERTICAL_NAME = "Vertical layout"
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_VERTICAL_DESCRIPTION = "A more detailed layout with the buttons arranged vertically. The Companion model is hidden."
Lockit.UI_SETTING_GV_DETAILS_NAME = "Custom Great Vault"
Lockit.UI_SETTING_GV_DETAILS_TOOLTIP = "Delves UI: Display Great Vault rewards and progress (relevant for Delves) directly in the Delves UI."
Lockit.UI_SETTING_DASHBOARD_OVERVIEW_NAME = "Delves Overview Section"
Lockit.UI_SETTING_DASHBOARD_OVERVIEW_TOOLTIP = "Delves UI: Display an additional Overview section. It contains information about Gilded Stash, available Bountiful Delves, and Delve-related currencies and items."

Lockit.UI_SETTINGS_TRANSLATION_TITLE = "特别鸣谢翻译贡献者："
