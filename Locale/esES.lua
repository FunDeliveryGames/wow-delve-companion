if GetLocale() ~= "esES" then return end -- Spanish

local _, AddonTbl = ...

---@type DelveCompanion
local DelveCompanion = AddonTbl.DelveCompanion

---@type Logger
local Logger = DelveCompanion.Logger
---@type Lockit
local Lockit = DelveCompanion.Lockit
-- ====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================

-- Common

Lockit.UI_COMMON_BOUNTIFUL_DELVE_TITLE = "Profundidades pródigas:"
Lockit.UI_COMMON_MISSING_ADDON_TITLE = "Falta el complemento necesario: %s" -- `%s`: name of the missing AddOn, e.g. DelveCompanion

-- Delves List

Lockit.UI_DELVES_LIST_MODIFIERS_TEXT = _G["MODIFIERS_COLON"]

Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLICK_INSTRUCTION = "<Shift click para establecer puntos de referencia en la profundidad>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CURRENT_TEXT = "Punto de referencia establecido."
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLEAR_INSTRUCTION = "<Shift click para borrar el punto de referencia>"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_CLEAR_MPE = "Por favor utiliza MapPinEnhanced Tracker para eliminar el punto de referencia."

-- !!! Formatting note: Symbol "~" in the following text is used to split the string into 2 separate parts in the code. It's not shown in the actual locale. No spaces around.
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_NEMESIS_TWW_S1 = "Nemesis: |cnHIGHLIGHT_FONT_COLOR:Zekvir|r~The War Within Season 1"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_NEMESIS_TWW_S2 = "Nemesis: |cnHIGHLIGHT_FONT_COLOR:The Underpin|r~The War Within Season 2"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_NEMESIS_TWW_S3 = "Nemesis: |cnHIGHLIGHT_FONT_COLOR:Ky'Veza|r~The War Within Season 3"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_NEMESIS_MIDNIGHT_S1 = "Nemesis: |cnHIGHLIGHT_FONT_COLOR:Nullaeus|r~Midnight Season 1"
Lockit.UI_DELVE_INSTANCE_BUTTON_TOOLTIP_NEMESIS_MIDNIGHT_S2 = "Nemesis: |cnHIGHLIGHT_FONT_COLOR:Azta'rec|r~Midnight Season 2"
-----

-- Delves UI

Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA_TWW = "Visita las zonas de The War Within para ver el progreso"
Lockit.UI_GILDED_STASH_CANNOT_RETRIEVE_DATA_MIDNIGHT = "Visita las zonas de Midnight para ver el progreso"
Lockit.UI_GILDED_STASH_BOUNTIFUL_NOTE = "Aparece sólo en el |cnNORMAL_FONT_COLOR:Nivel 11|r de las profundidades pródigas|A:delves-bountiful:16:16|a."
Lockit.UI_GILDED_STASH_CRESTS_NOTE = "Cada alijo contiene %d |cnIQ4:Blasones mito|r (|cnNORMAL_FONT_COLOR:%d por semana|r en total)."
Lockit.UI_JOURNEY_LEVEL_REQUIRED = "Requiere nivel %d del diario de viaje de explorador"
Lockit.UI_NO_ACTIVE_BOUNTIFUL = "No hay profundidades pródigas activas"
Lockit.UI_LOOT_INFO_BUTTON_TOOLTIP_INSTRUCTION = "<Click para mostrar información sobre el botín de las profundidades.>"

-- Loot Info

Lockit.UI_LOOT_INFO_DESCRIPTION = "Tabla de botín de las profundidades:"
Lockit.UI_LOOT_INFO_TIPS = "|A:delves-treasure-upgrade:16:16|a |cnNORMAL_FONT_COLOR:%s|r: Los grupos de enemigos deben ser eliminados antes del jefe final. Eliminarlos después no añade más recompensas al cofre. Se añaden blasones al matar a 3 o más grupos en los niveles especificados.\n\n|T%s:16|t |cnNORMAL_FONT_COLOR:%s|r: Se desbloquea en el nivel 4 del diario de explorador de profundidades. El alijo se puede saquear 4 veces por semana."

-- Delves Gossip
Lockit.UI_DELVE_AUTO_ENTER_SELECTED_TIER = "Entrada automática (Nivel %d)" -- %d is a Tier number (1-11).
Lockit.UI_DELVE_AUTO_ENTER_INFO = "El nivel seleccionado se puede cambiar en las opciones del addon."
Lockit.UI_DELVE_AUTO_ENTER_CANCEL_TOOLTIP_INSTRUCTION = "<Click para cancelar la entrada automática>"

-- Tooltips Extension

Lockit.UI_BOUNTIFUL_KEYS_COUNT_CACHES_PREFIX = "Llaves de cofres"

-- Compartment (these are shown hovering over the addon in the corresponding dropdown menu)

Lockit.UI_COMPARTMENT_DESCRIPTION_LEFT_CLICK = "|cnGREEN_FONT_COLOR:Click|r para abrir el panel de temporada."
Lockit.UI_COMPARTMENT_DESCRIPTION_RIGHT_CLICK = "|cnGREEN_FONT_COLOR:Click derecho|r para acceder a las opciones del complemento."

-- Settings

Lockit.UI_SETTINGS_SECTION_TITLE_ACCOUNT = "A nivel de cuenta"
Lockit.UI_SETTING_DELVE_PROGRESS_WIDGETS_NAME = "Información sobre el progreso de profundidades"
Lockit.UI_SETTING_DELVES_LIST_INFO_WIDGETS_TOOLTIP = "Lista de profundidades: Mostrar el progreso de los logros para cada profundidad (Historias y Cofres)."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_NAME = "Tipo de seguimiento de puntos de referencia"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_START = "Selecciona qué tipo de puntos de referencia se utilizan para la navegación.\n\nPosibles opciones:"
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_BLIZZARD = "- Marca de mapa de Blizzard (La navegación predeterminada dentro del juego)."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_TOMTOM = "- TomTom Waypoints."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_MPE = "- MapPinEnhanced Waypoints."
Lockit.UI_SETTING_WAYPOINT_TRACKING_TYPE_TOOLTIP_TOMTOM_UNAVAILABLE_FORMAT = "%s (%s)."
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_BLIZZARD_NAME = "Blizzard"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_BLIZZARD_DESCRIPTION = "Utilizar marca de mapa de Blizzard."
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_TOMTOM_NAME = "TomTom"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_TOMTOM_DESCRIPTION = "Utilizar puntos de referencia de TomTom."
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_MPE_NAME = "MapPinEnhanced"
Lockit.UI_SETTING_WAYPOINT_TRACKING_OPTION_MPE_DESCRIPTION = "Utilizar puntos de referencia de MapPinEnhanced."
Lockit.UI_SETTING_IN_DELVE_WIDGET_CONTROL_NAME = "Miniaplicación en profundidades"
Lockit.UI_SETTING_IN_DELVE_WIDGET_CONTROL_TOOLTIP = "Activa una miniaplicación que se muestra dentro de una profundidad. Sirve como recordatorio y menú de acceso rápido para el mapa de recompensas, el señuelo Némesis y mucho más."
Lockit.UI_SETTING_IN_DELVE_WIDGET_DISPLAY_RULE_NAME = "Miniaplicación en profundidades"
Lockit.UI_SETTING_IN_DELVE_WIDGET_DISPLAY_RULE_TOOLTIP = "Activa una miniaplicación que se muestra dentro de una profundidad. Sirve como recordatorio y menú de acceso rápido para el mapa de recompensas, el señuelo Némesis y mucho más."
Lockit.UI_SETTING_IN_DELVE_WIDGET_DISPLAY_RULE_OPTION_LEFT_NAME = "Lado izquierdo"
Lockit.UI_SETTING_IN_DELVE_WIDGET_DISPLAY_RULE_OPTION_LEFT_DESCRIPTION = "La miniaplicación se muestra en el lado izquierdo de Objective Tracker."
Lockit.UI_SETTING_IN_DELVE_WIDGET_DISPLAY_RULE_OPTION_RIGHT_NAME = "Lado derecho"
Lockit.UI_SETTING_IN_DELVE_WIDGET_DISPLAY_RULE_OPTION_RIGHT_DESCRIPTION = "La miniaplicación se muestra en el lado derecho de Objective Tracker."
Lockit.UI_SETTING_IN_DELVE_WIDGET_DISPLAY_RULE_OPTION_CUSTOM_NAME = "Personalizado"
Lockit.UI_SETTING_IN_DELVE_WIDGET_DISPLAY_RULE_OPTION_CUSTOM_DESCRIPTION = "La miniaplicación se puede mover libremente por la pantalla. |cnGREEN_FONT_COLOR:Click derecho|r y arrastra la miniaplicación para moverla."
Lockit.UI_SETTING_IN_DELVE_WIDGET_LAYOUT_NAME = "Disposición de los botones"
Lockit.UI_SETTING_IN_DELVE_WIDGET_LAYOUT_TOOLTIP = "Cómo están dispuestos los botones de la miniaplicación."
Lockit.UI_SETTING_IN_DELVE_WIDGET_LAYOUT_OPTION_VERTICAL_NAME = "Vertical"
Lockit.UI_SETTING_IN_DELVE_WIDGET_LAYOUT_OPTION_VERTICAL_DESCRIPTION = "Los botones están dispuestos verticalmente."
Lockit.UI_SETTING_IN_DELVE_WIDGET_LAYOUT_OPTION_HORIZONTAL_NAME = "Horizontal"
Lockit.UI_SETTING_IN_DELVE_WIDGET_LAYOUT_OPTION_HORIZONTAL_DESCRIPTION = "Los botones están dispuestos horizontalmente."
Lockit.UI_SETTING_STORY_STATUS_IN_GOSSIP_NAME = "Estado de la variante de historia"
Lockit.UI_SETTING_STORY_STATUS_IN_GOSSIP_TOOLTIP = "Resalta si la variante de historia activa se ha completado o no (necesario para los logros) en la ventana que se muestra al entrar en una profundidad."
Lockit.UI_SETTING_MINIMAP_ICON_NAME = "Mostrar icono en el minimapa"
Lockit.UI_SETTING_MINIMAP_ICON_TOOLTIP = "Muestra un icono en el minimapa. Se puede hacer click en él para abrir el panel de la temporada actual de profundidades."
Lockit.UI_SETTING_DELVE_AUTO_ENTER_CONTROL_NAME = "Entrada automática a las profundidades"
Lockit.UI_SETTING_DELVE_AUTO_ENTER_CONTROL_TOOLTIP = "Ingresas a una profundidad automáticamente al llegar a su entrada.\n\nNo se podrá ingresar en la profundidad si:\n   • El nivel aún no se ha desbloqueado.\n   • Es una profundidad de Némesis.\n   • Es una profundidad pródiga pero no tienes una |cnIQ4:Llave de arca restaurada|r o no tienes suficientes |cnIQ3: Fragmentos de llave de arca|r para formar una llave."
Lockit.UI_SETTING_DELVE_AUTO_ENTER_TIER_TOOLTIP = "Nivel de profundidad para entrar."
Lockit.UI_SETTING_DELVE_AUTO_ENTER_DELAY_NAME = "Introducir retraso"
Lockit.UI_SETTING_DELVE_AUTO_ENTER_DELAY_TOOLTIP = "Ingresarás en una profundidad con un retraso (en segundos).\n\nEn la ventana que se muestra hay un botón para entrar en una profundidad. Se puede hacer click para cancelar la entrada automática antes de que finalice la cuenta regresiva."

Lockit.UI_SETTINGS_SECTION_TITLE_CHARACTER = "A nivel de personaje"
Lockit.UI_SETTING_TOOLTIP_EXTENSION_NAME = "Información adicional en las descripciones emergentes"
Lockit.UI_SETTING_TOOLTIP_EXTENSION_TOOLTIP = "Muestra información adicional en las descripciones emergentes (ej:, el número de |cnITEM_EPIC_COLOR:Llaves de arcas restauradas|r recibidas esta semana)."
Lockit.UI_SETTING_COMPANION_CONFIG_NAME = "Widget de configuración del compañero"
Lockit.UI_SETTING_COMPANION_CONFIG_TOOLTIP = "Profundidades UI: Activa un widget que muestra la especialización y habilidades actuales del compañero.\nSe puede utilizar para modificar la configuración directamente desde Profundidades UI.\nNota: el tipo de diseño no afecta a la funcionalidad, solo a la disposición visual."
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_HORIZONTAL_NAME = "Disposición horizontal"
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_HORIZONTAL_DESCRIPTION = "Un diseño compacto con los botones dispuestos horizontalmente. Se muestra el modelo Companion."
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_VERTICAL_NAME = "Disposición vertical"
Lockit.UI_SETTING_COMPANION_CONFIG_OPTION_VERTICAL_DESCRIPTION = "Un diseño más detallado con los botones dispuestos verticalmente. El modelo Companion está oculto."
Lockit.UI_SETTING_GV_DETAILS_NAME = "Gran cámara personalizada"
Lockit.UI_SETTING_GV_DETAILS_TOOLTIP = "Profundidades UI: Muestra las recompensas y el progreso de la Gran cámara (relevante para profundidades) directamente en la Profundidades UI."
Lockit.UI_SETTING_DASHBOARD_OVERVIEW_NAME = "Sección de descripción general de Profundidades"
Lockit.UI_SETTING_DASHBOARD_OVERVIEW_TOOLTIP = "Profundidades UI: Muestra una sección de descripción general adicional. Contiene información sobre Alijo dorados, Profundidades pródigas disponibles y consumibles relacionados con las profundidades."

Lockit.UI_SETTING_LOGS_NAME = "Activar registros de depuración"
Lockit.UI_SETTING_LOGS_TOOLTIP = "Permite imprimir registros de depuración en el chat. Se utiliza para fines de desarrollo y pruebas."

Lockit.UI_SETTINGS_TRANSLATION_TITLE = "Agradecimiento especial por contribuir en la traducción para:"

-- The following strings are joined into a list using "\n" (a new line) as a delimiter.
Lockit.UI_SETTINGS_SLASH_CMD_TEXT = "Comandos de barra:"
Lockit.UI_SETTINGS_SLASH_CMD_SHOWDELVES = "   • |cnNORMAL_FONT_COLOR:/delvecompanion|r o |cnNORMAL_FONT_COLOR:/delvecomp|r o |cnNORMAL_FONT_COLOR:/delves|r: Abre el panel de la temporada actual de profundidades en la Guía de aventuras (el mismo comportamiento que al hacer click en el icono del minimapa)." -- The commands themselves should NOT be translated.
-----

Lockit.UI_SETTINGS_LINKS_TITLE = "Enlaces:"
Lockit.UI_SETTINGS_ADDON_LINK_TOOLTIP_CURSEFORGE = "Click para copiar la URL de la página del complemento en |cnNORMAL_FONT_COLOR:CurseForge|r."
Lockit.UI_SETTINGS_ADDON_LINK_TOOLTIP_WAGO = "Click para copiar la URL de la página del complemento en |cnNORMAL_FONT_COLOR:Wago.io|r."
Lockit.UI_SETTINGS_ADDON_LINK_TOOLTIP_WOWINT = "Click para copiar la URL de la página del complemento en |cnNORMAL_FONT_COLOR:WoW Interface|r."
Lockit.UI_SETTINGS_ADDON_LINK_TOOLTIP_GITHUB = "Click para copiar la URL de la página del complemento en |cnNORMAL_FONT_COLOR:GitHub|r.\n\nComparte tus comentarios, solicita nuevas funciones o informa de un error. ¡Esto ayuda a mejorar aún más el complemento!"
Lockit.UI_SETTINGS_ADDON_LINK_POPUP_TEXT = "|cnGREEN_FONT_COLOR:Ctrl + C|r para copiar |cnNORMAL_FONT_COLOR:%s|r URL." -- `%s`: website name, e.g. CurseForge.
