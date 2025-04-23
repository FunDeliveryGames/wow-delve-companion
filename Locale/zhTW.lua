if GetLocale() ~= "zhTW" then
    return
end

local _, Addon = ...
---@type Logger
local Logger = Addon.Logger
local lockit = Addon.lockit
--====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================

-- Common

lockit["ui-common-bountiful-delve"] = "豐碩探究"

-- Delves List

lockit["ui-delve-instance-button-tooltip-click-instruction"] = "<Shift + 左鍵：設置地下堡的路徑點>"
lockit["ui-delve-instance-button-tooltip-current-text"] = "路徑點設置"
lockit["ui-delve-instance-button-tooltip-current-instruction"] = "<Shift + 左鍵：清空路徑點>"

-- Delves UI

lockit["ui-gilded-stash-cannot-retrieve-data"] = "在卡茲阿爾加地區時可獲取鍍金儲物箱進度"
lockit["ui-gilded-stash-bountiful-note"] = "僅出現在 |cnNORMAL_FONT_COLOR:難度 11|r 豐碩探究|A:delves-bountiful:16:16|a。"
lockit["ui-no-active-bountiful"] = "任意難度11豐碩探究可啟動進度"
lockit["ui-loot-info-button-tooltip-instruction"] = "<點擊來顯示探究的拾取資訊>"

-- Loot Info

lockit["ui-loot-info-description"] = "完成探究可獲得戰利品："

-- Keys Info

lockit["ui-bountiful-keys-count-caches-prefix"] = "寶箱裡獲取的鑰匙數量"

-- Settings

lockit["ui-settings-missing-addon-title"] = "缺少必需的插件：%s" -- %s: name of the missing AddOn, e.g. DelveCompanion

lockit["ui-settings-section-title-account"] = "帳號設置"
lockit["ui-settings-ach-widgets"] = "冒險指南-探究：顯示探究成就進度（劇情和探索）。"
lockit["ui-settings-tomtom-description"] = "路徑點風格：使用 TomTom 路徑點替代暴雪導航點。"

lockit["ui-settings-section-title-character"] = "角色設置"
lockit["ui-settings-gv-details"] = "探究：顯示詳細的寶庫獎勵。"
lockit["ui-settings-dashboard-overview"] = "探究：顯示探究的其他概要（鍍金儲物箱，豐碩探究）。"
lockit["ui-settings-keys-cap"] = "鼠標提示：顯示每週寶箱獲取的鑰匙數量。"
lockit["ui-settings-translation-title"] = "特別鳴謝翻譯者："
