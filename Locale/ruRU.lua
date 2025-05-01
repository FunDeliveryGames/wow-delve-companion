if GetLocale() ~= "ruRU" then return end

local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit
-- ====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================

-- Общие

Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE = "Многообещающая Вылазка"
Lockit.UI_COMMON_MISSING_ADDON_TITLE = "Отсутствует необходимый аддон: %s" -- %s: Имя аддона. Например, DelveCompanion

-- Список вылазок

Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION = "<Shift + ЛКМ, чтобы установить точку маршрута к вылазке>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT = "Точка маршрута установлена."
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION = "<Shift + ЛКМ, чтобы сбросить точку маршрута>"

-- Интерфейс вылазок

Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA = "Посетите Каз Алгар, чтобы увидеть прогресс"
Lockit.UI_GILDED_STASH_BOUNTIFUL_NOTE = "Появляется только на |cnNORMAL_FONT_COLOR:11-ом Уровне|r Многообещающих Вылазок|A:delves-bountiful:16:16|a."
Lockit.UI_NO_ACTIVE_BOUNTIFUL = "Нет активных вылазок"
Lockit.UI_LOOT_INFO_BUTTON_TOOLTIP_INSTRUCTION = "<Нажмите, чтобы отобразить информацию о добыче Вылазок>"

-- Информация о добыче

Lockit.UI_LOOT_INFO_DESCRIPTION = "Завершите вылазку, чтобы получить:"

-- Информация о ключах

Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX = "Ключей из тайников"

-- Compartment

Lockit.UI_COMPARTMENT_DESCRIPTION_LEFT_CLICK = "Left Click to open information window."
Lockit.UI_COMPARTMENT_DESCRIPTION_RIGHT_CLICK = "Right Click to change options."

-- Настройки

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "Параметры аккаунта"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_NAME = "Delve's Progress Info"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_TOOLTIP = "Список вылазок: Отображать прогресс достижений (истории и сундуки)."
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

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "Параметры персонажа"
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

Lockit.UI_SETTINGS_TRANSLATION_TITLE = "Особая благодарность за помощь с переводом:"
