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

Lockit.UI_COMPARTMENT_DESCRIPTION_LEFT_CLICK = "ЛКМ, чтобы открыть информационное окно."
Lockit.UI_COMPARTMENT_DESCRIPTION_RIGHT_CLICK = "ПКМ, чтобы изменить настройки."

-- Настройки

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "Параметры аккаунта"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_NAME = "Информация о прогрессе Вылазок"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_TOOLTIP = "Список вылазок: Отображать прогресс достижений (истории и сундуки)."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_NAME = "Тип отслеживания точки маршрута"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_START = "Выберите, какой тип путевых точек используется для навигации.\n\nВозможные варианты:"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_BLIZZARD = "- Отметка на карте Blizzard (стандартная внутриигровая навигация)"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_TOMTOM = "- Точки маршрута TomTom"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_TOMTOM_UNAVAILABLE_FORMAT = "%s (%s)."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_FORMAT = "%s\n%s\n%s"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_BLIZZARD_NAME = "Blizzard"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_BLIZZARD_DESCRIPTION = "Используйте отметки на карте Blizzard."
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_TOMTOM_NAME = "TomTom"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_TOMTOM_DESCRIPTION = "Используйте путевые точки TomTom."

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "Параметры персонажа"
Lockit.UI_SETTING_TOOLTIP_EXTENSION_NAME = "Дополнительная информация в подсказках"
Lockit.UI_SETTING_TOOLTIP_EXTENSION_TOOLTIP = "Отображать дополнительную информацию во всплывающих подсказках (например, количество |cnITEM_EPIC_COLOR:Отреставрированных ключей от сундука|r, полученных на этой неделе)."
Lockit.UI_SETTING_COMPANION_CONFIG_NAME = "Виджет конфигурации Companion"
Lockit.UI_SETTING_COMPANION_CONFIG_TOOLTIP = "Интерфейс Вылазок: включить виджет, отображающий текущую специализацию и способности компаньона.\nЕго можно использовать для изменения конфигурации непосредственно из интерфейса Вылазок."
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_HORIZONTAL_NAME = "Горизонтальная компоновка"
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_HORIZONTAL_DESCRIPTION = "Компактная раскладка с кнопками, расположенными горизонтально. Модель Companion осталась нетронутой."
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_VERTICAL_NAME = "Вертикальная компоновка"
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_VERTICAL_DESCRIPTION = "Более подробный макет с кнопками, расположенными вертикально. Модель Companion скрыта."
Lockit.UI_SETTING_GV_DETAILS_NAME = "Пользовательское Великое Хранилище"
Lockit.UI_SETTING_GV_DETAILS_TOOLTIP = "Интерфейс Вылазок: Отображение наград и прогресса Великого хранилища (актуально для Вылазок) непосредственно в интерфейсе Вылазок."
Lockit.UI_SETTING_DASHBOARD_OVERVIEW_NAME = "Обзорный раздел Вылазок"
Lockit.UI_SETTING_DASHBOARD_OVERVIEW_TOOLTIP = "Интерфейс Вылазок: Отображение дополнительного раздела «Обзор». Он содержит информацию о Позолоченных тайниках, доступных Многообещающим Вылазкам и валютах и ​​предметах, связанных с Вылазками."

Lockit.UI_SETTINGS_TRANSLATION_TITLE = "Особая благодарность за помощь с переводом:"
