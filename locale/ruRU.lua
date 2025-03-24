if GetLocale() ~= "ruRU" then
    return
end

local _, addon = ...
local log = addon.log
local lockit = addon.lockit
--====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================
-- Общие
lockit["ui-addon-name"] = "Delve Companion" -- Do not translate
lockit["ui-common-bountiful-delve"] = "Многообещающая Вылазка"

-- Список вылазок
lockit["ui-delve-instance-button-tooltip-click-instruction"] = "<Shift + ЛКМ, чтобы установить точку маршрута к вылазке>"
lockit["ui-delve-instance-button-tooltip-current-text"] = "Точка маршрута установлена."
lockit["ui-delve-instance-button-tooltip-current-instruction"] = "<Shift + ЛКМ, чтобы сбросить точку маршрута>"

-- Интерфейс вылазок
lockit["ui-gilded-stash-cannot-retrieve-data"] = "Посетите Каз Алгар, чтобы увидеть прогресс"
lockit["ui-gilded-stash-bountiful-note"] =
"Появляется только на |cnNORMAL_FONT_COLOR:11-ом Уровне|r Многообещающих Вылазок|A:delves-bountiful:16:16|a."
lockit["ui-no-active-bountiful"] = "Нет активных вылазок"

-- Информация о добыче
lockit["ui-loot-info-description"] = "Завершите вылазку, чтобы получить:"

-- Информация о ключах
lockit["ui-bountiful-keys-count-caches-prefix"] = "Ключей из тайников"

-- Настройки
lockit["ui-settings-section-title-account"] = "Параметры аккаунта:"
lockit["ui-settings-section-title-character"] = "Параметры персонажа:"
lockit["ui-settings-gv-details"] = "Интерфейс вылазок: Отображать подробные детали Великого Хранилища."
lockit["ui-settings-dashboard-overview"] =
"Интерфейс вылазок: Отображать раздел обзора (Позолоченный тайник, Многообещающая Вылазка)."
lockit["ui-settings-keys-cap"] = "Отображать еженедельный лимит ключей в подсказках."
lockit["ui-settings-ach-widgets"] = "Список вылазок: Отображать прогресс достижений (истории и сундуки)."
lockit["ui-settings-translation-title"] = "Особая благодарность за помощь с переводом:"

-- Отладка
lockit["debug-unexpected-enum-element"] = "Перечисление `%s` не содержит элемент: %s."
