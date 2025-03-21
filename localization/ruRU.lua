local _, addon = ...

--[[
Правила:
- Префиксы для разных частей:
--- ui
--- debug
--- data
--- config
-
]]
addon.lockit = setmetatable(
    {
        -- Общие
        ["ui-common-bountiful-delve"] = "Многообещающая Вылазка",
        ["ui-addon-name"] = "Delve Companion",
        -- Список вылазок
        ["ui-delve-instance-button-tooltip-click-text"] = "Shift + ЛКМ, чтобы установить точку маршрута к вылазке.",
        ["ui-delve-instance-button-tooltip-current-text"] = "Точка маршрута установлена.\nShift + ЛКМ, чтобы сбросить точку маршрута.",

        -- Обзор панели
        ["ui-gilded-stash-bountiful-note"] =
        "Появляется только на |cnNORMAL_FONT_COLOR:Уровне 11|r Многообещающих Вылазок|A:delves-bountiful:16:16|a.",
        ["ui-no-active-bountiful"] = "Нет активных вылазок",
        -- Информация о добыче
        ["ui-loot-info-description"] = "Завершите вылазку, чтобы получить:",
        ["ui-loot-info-bountilful-gear-title"] = "Многообещающая", -- Заменить на https://www.wowhead.com/item=228942/bountiful-coffer

        -- Информация о ключах
        ["ui-bountiful-keys-count-owned-format"] = "%s %s: %d",

        -- Настройки
        ["ui-settings-apply-button"] = "%s (%s)",
        ["ui-settings-gv-details"] = "Интерфейс вылазок: Включить информативные детали Великого Хранилища.",
        ["ui-settings-dashboard-overview"] = "Интерфейс вылазок: Включить раздел обзора (Позолоченный тайник, Многообещающая Вылазка).",
        ["ui-settings-keys-cap"] = "Отображать еженедельный лимит ключей в подсказках.",

        -- Отладка
        ["debug-unexpected-enum-element"] = "Перечисление %s не содержит предмет: %s.",
    },
    {
        __index = function(_, ...)
            addon.log("Ключ не найден в lockit: %s!", ...);
        end
    }
)
