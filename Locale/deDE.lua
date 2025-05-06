if GetLocale() ~= "deDE" then return end

local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit
-- ====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================

-- Common

Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE = "Großzügige Tiefe"
Lockit.UI_COMMON_MISSING_ADDON_TITLE = "Erforderliches AddOn fehlt: %s" -- %s: name of the missing AddOn, e.g. DelveCompanion

-- Delves List

Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION = "<Shift + Linksklick, um einen Wegpunkt zur Tiefe zu setzen>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT = "Wegpunkt gesetzt."
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_INSTRUCTION = "<Shift + Linksklick, um den Wegpunkt zu entfernen>"

-- Delves UI

Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA = "Besuche die Gebiete von Khaz Algar, um den Fortschritt zu sehen."
Lockit.UI_GILDED_STASH_BOUNTIFUL_NOTE = "Erscheint nur in großzügigen Tiefen der |cnNORM...NT_COLOR:Stufe 11|r |A:delves-bountiful:16:16|a."
Lockit.UI_NO_ACTIVE_BOUNTIFUL = "Keine aktiven Tiefen."
Lockit.UI_LOOT_INFO_BUTTON_TOOLTIP_INSTRUCTION = "<Klicken, um Beute Informationen der Tiefen anzuzeigen>"

-- Loot Info

Lockit.UI_LOOT_INFO_DESCRIPTION = "Schließe eine Tiefe ab um folgendes zu erhalten:"

-- Keys Info

Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX = "Schlüssel aus Truhen"

-- Compartment (these are shown hovering over the addon in the corresponding dropdown menu)

Lockit.UI_COMPARTMENT_DESCRIPTION_LEFT_CLICK = "|cnGREEN_FONT_COLOR:Linksklick|r, um das Informationsfenster anzuzeigen."
Lockit.UI_COMPARTMENT_DESCRIPTION_RIGHT_CLICK = "|cnGREEN_FONT_COLOR:Rechtsklick|r, um auf die Addon-Optionen zuzugreifen."

-- Settings

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "Account-weite Einstellungen"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_NAME = "Tiefen Fortschrittsinformation"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_TOOLTIP = "Tiefen-Liste: Zeige den Fortschritt von Erfolgen für jede Tiefe (Geschichten und Truhen) an."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_NAME = "Art der Wegpunktverfolgung"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_START = "Wähle aus, welche Art von Wegpunkten für die Navigation verwendet werden soll.\n\nMögliche Optionen:"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_BLIZZARD = "- Blizzards-Kartenpin (die Standard-Navigation im Spiel)"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_TOMTOM = "- TomTom-Wegpunkte"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_TOMTOM_UNAVAILABLE_FORMAT = "%s (%s)."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_FORMAT = "%s\n%s\n%s"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_BLIZZARD_NAME = "Blizzard"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_BLIZZARD_DESCRIPTION = "verwende Blizzards-Kartenpin"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_TOMTOM_NAME = "TomTom"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_TOMTOM_DESCRIPTION = "verwende TomTom-Wegpunkte"

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "Charakter-spezifische Einstellungen"
Lockit.UI_SETTING_TOOLTIP_EXTENSION_NAME = "zusätzliche Informationen in Tooltips"
Lockit.UI_SETTING_TOOLTIP_EXTENSION_TOOLTIP = "Zeigt zusätzliche Informationen in den Tooltips an (z.B. die Anzahl der |cnITEM_EPIC_COLOR:restaurierten Kastenschlüssel|r, die diese Woche erhalten wurden).“
Lockit.UI_SETTING_COMPANION_CONFIG_NAME = "Begleiter-Konfigurations-Widget"
Lockit.UI_SETTING_COMPANION_CONFIG_TOOLTIP = "Tiefen UI: Aktiviert ein Widget, das die aktuelle Spezialisierung und die Fähigkeiten des Begleiters anzeigt. Es kann verwendet werden, um die Konfiguration direkt von der Tiefen UI aus zu ändern.\nHinweis: Der Layout-Typ hat keinen Einfluss auf die Funktionalität, nur auf die visuelle Anordnung."
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_HORIZONTAL_NAME = "Horizontales Layout"
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_HORIZONTAL_DESCRIPTION = "Die Schaltflächen werden horizontal angeordnet. Das Begleiter-Modell wird angezeigt."
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_VERTICAL_NAME = "Vertikales Layout"
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_VERTICAL_DESCRIPTION = "Die Schaltflächen werden vertikal angeordnet. Das Begleiter-Modell ist verborgen."
Lockit.UI_SETTING_GV_DETAILS_NAME = "angepasste große Schatzkammer"
Lockit.UI_SETTING_GV_DETAILS_TOOLTIP = "Tiefen UI: Zeigt große Schatzkammer Belohnungen und den dazugehörigen Fortschritt für die Tiefen direkt in der Tiefen UI an."
Lockit.UI_SETTING_DASHBOARD_OVERVIEW_NAME = "Übersichtsbereich der Tiefen"
Lockit.UI_SETTING_DASHBOARD_OVERVIEW_TOOLTIP = "Tiefen UI: Zeigt einen zusätzlichen Übersichtsbereich an. Er enthält Informationen über vergoldete Schätze, verfügbare großzügige Tiefen und Tiefen-bezogene Verbrauchsgüter."

Lockit.UI_SETTINGS_TRANSLATION_TITLE = "Besonderen Dank für den Beitrag zur Übersetzung:"
