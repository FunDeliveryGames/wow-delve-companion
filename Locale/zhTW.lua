if GetLocale() ~= "zhTW" then
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

Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE = "豐碩探究"

-- Delves List

Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION = "<Shift + 左鍵：設置地下堡的路徑點>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT = "路徑點設置"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION = "<Shift + 左鍵：清空路徑點>"

-- Delves UI

Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA = "在卡茲阿爾加地區時可獲取鍍金儲物箱進度"
Lockit.UI_GILDED_STASH_BOUNTIFUL_NOTE = "僅出現在 |cnNORMAL_FONT_COLOR:難度 11|r 豐碩探究|A:delves-bountiful:16:16|a。"
Lockit.UI_NO_ACTIVE_BOUNTIFUL = "任意難度11豐碩探究可啟動進度"
Lockit.UI_LOOT_INFO_BUTTON_TOOLTIP_INSTRUCTION = "<點擊來顯示探究的拾取資訊>"

-- Loot Info

Lockit.UI_LOOT_INFO_DESCRIPTION = "完成探究可獲得戰利品："

-- Keys Info

Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX = "寶箱裡獲取的鑰匙數量"

-- Settings

Lockit.UI_SETTINGS_MISSING_ADDON_TITLE = "缺少必需的插件：%s" -- %s: name of the missing AddOn, e.g. DelveCompanion

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "帳號設置"
Lockit.UI_SETTINGS_ACH_WIDGETS = "冒險指南-探究：顯示探究成就進度（劇情和探索）。"
Lockit.UI_SETTINGS_TOMTOM_DESCRIPTION = "路徑點風格：使用 TomTom 路徑點替代暴雪導航點。"

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "角色設置"
Lockit.UI_SETTINGS_GV_DETAILS = "探究：顯示詳細的寶庫獎勵。"
Lockit.UI_SETTINGS_DASHBOARD_OVERVIEW = "探究：顯示探究的其他概要（鍍金儲物箱，豐碩探究）。"
Lockit.UI_SETTINGS_KEYS_CAP = "鼠標提示：顯示每週寶箱獲取的鑰匙數量。"
Lockit.UI_SETTINGS_TRANSLATION_TITLE = "特別鳴謝翻譯者："
