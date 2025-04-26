if GetLocale() ~= "ruRU" then
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

-- Общие

Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE = "Многообещающая Вылазка"

-- Список вылазок

Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION = "<Shift + ЛКМ, чтобы установить точку маршрута к вылазке>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT = "Точка маршрута установлена."
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION = "<Shift + ЛКМ, чтобы сбросить точку маршрута>"

-- Интерфейс вылазок

Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA = "Посетите Каз Алгар, чтобы увидеть прогресс"
Lockit.UI_GILDED_STASH_BOUNTIFUL_NOTE =
"Появляется только на |cnNORMAL_FONT_COLOR:11-ом Уровне|r Многообещающих Вылазок|A:delves-bountiful:16:16|a."
Lockit.UI_NO_ACTIVE_BOUNTIFUL = "Нет активных вылазок"
Lockit.UI_LOOT_INFO_BUTTON_TOOLTIP_INSTRUCTION = "<Нажмите, чтобы отобразить информацию о добыче Вылазок>"

-- Информация о добыче

Lockit.UI_LOOT_INFO_DESCRIPTION = "Завершите вылазку, чтобы получить:"

-- Информация о ключах

Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX = "Ключей из тайников"

-- Настройки

Lockit.UI_SETTINGS_MISSING_ADDON_TITLE =
"Отсутствует необходимый аддон: %s" -- %s: Имя аддона. Например, DelveCompanion

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "Параметры аккаунта:"
Lockit.UI_SETTINGS_ACH_WIDGETS = "Список вылазок: Отображать прогресс достижений (истории и сундуки)."
Lockit.UI_SETTINGS_TOMTOM_DESCRIPTION = "Использовать путевые точки TomTom вместо маркеров карты Blizzard."

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "Параметры персонажа:"
Lockit.UI_SETTINGS_GV_DETAILS = "Интерфейс вылазок: Отображать подробные детали Великого Хранилища."
Lockit.UI_SETTINGS_DASHBOARD_OVERVIEW =
"Интерфейс вылазок: Отображать раздел обзора (Позолоченный тайник, Многообещающая Вылазка)."
Lockit.UI_SETTINGS_KEYS_CAP = "Отображать еженедельные лимиты в подсказках."
Lockit.UI_SETTINGS_TRANSLATION_TITLE = "Особая благодарность за помощь с переводом:"
