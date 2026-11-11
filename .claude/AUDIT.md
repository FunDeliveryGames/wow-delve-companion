# Delve Companion — Repository Audit

- **Date:** 2026-11-09
- **Baseline:** commit `c7d67e6` plus the uncommitted working tree (`.pkgmeta`, TOC, `Source/Bootstrap.lua`, `Source/Modules/EJExtension/EJExtension.lua`, `Data/Variables.lua`)
- **Report location:** `.claude/AUDIT.md`. Links are relative to this file.

---

## 0. Scope, method, confidence

**Read:** every Lua and XML file the TOC loads, the packaging scripts, `.pkgmeta`, `.vscode/tasks.json` and `CHANGELOG.md`. `DelvesList/InfoFrame` is unfinished (per AGENTS.md), so I only checked how it gets loaded and shipped. I didn't review `Libs/`.

**Checked without a game client:**
- I compiled every source file with `luac 5.2 -l` and listed its global reads and writes. This found two unintended global reads.
- I ran the suspicious Lua patterns in a throwaway script.
- I listed the contents of `Releases/DelveCompanion_v2026.09.1.zip`.

**Not checked:** anything that depends on how Blizzard's FrameXML behaves at runtime, such as taint spread, the `GetEJTierData` fallback, or when the picker frame loads. Those findings are tagged **Risk**, not **Bug**.

**Tags:**

| Tag | Meaning |
|---|---|
| **Bug** | Defect visible in the code; reproduced where marked *(verified)* |
| **Risk** | Latent defect, or one that depends on game runtime behavior |
| **Design** | Structure / maintainability problem |
| **Dead** | Unused code or data |

### Where AGENTS.md is inaccurate or incomplete
- *"Modules use `:Init()`, `:Refresh()`, `:ProcessEvent()`"*: this is only partly true.
  - TooltipExtension is a global function (`DelveCompanion_TooltipExtension_Init`).
  - LootInfo is a lazily created singleton stored in `Variables`.
  - WaypointTracker is created once per button.
  - DelvesList and DelveEncounter are sub-tables that EJExtension initializes.
- *"`Variables.delvesData` is the central source of truth"*: it is, but nothing keeps it fresh. See **A1**.
- *"Bootstrapping happens in two phases"*: with the uncommitted change, EJExtension now starts in a third, deferred step at the end of `OnPlayerLogin`.
- Not mentioned:
  - Auto-exit, which is split across ProgressTracker, GossipExtension and Settings.
  - The Labyrinth special cases.
  - The Midnight secret-value guards in TooltipExtension.

---

## 1. Major architecture flaws

### A1. Delve runtime data has no owner and no refresh policy

> **Status (2026-11-09): addressed.** Replaced by the `DelvesData` service ([Source/Services/DelvesData](../Source/Services/DelvesData)) and `LibResetTracker-1.0` ([Libs/LibResetTracker-1.0](../Libs/LibResetTracker-1.0)), with offline tests in [Tests](../Tests). The findings below describe the code before that change; line links point to the old code.
>
> Note: not refreshing on daily reset was originally a deliberate early-stage decision (minor impact compared to the structural changes needed), not an oversight. It is now handled by the reset library, which also covers weekly resets for future features.

`Variables.delvesData` is a global table that anything can change. `UpdateDelvesData()` runs once at login. After that it runs only as a side effect of a view opening:
- [DelvesListFrame.lua:39](../Source/Modules/EJExtension/DelvesList/DelvesListFrame.lua#L39)
- [BountifulFrame.lua:39](../Source/Modules/EJExtension/DelveEncounter/Bountiful/BountifulFrame.lua#L39)

The modules that most need fresh data never refresh it. GossipExtension uses it for story status and for the auto-enter key check, and the waypoint tooltips read it too.

What goes wrong:
- **Bug.** Bountiful rotation and story variants change at the daily reset. Take a player who stays logged in past reset and walks to an entrance without opening the Adventure Guide. They see yesterday's `isBountiful` and `isStoryCompleted`. Auto-enter's "no Bountiful without a key" guard ([GossipExtension.lua:243](../Source/Modules/GossipExtension/GossipExtension.lua#L243)) is computed from that stale flag.
- **Bug.** `UpdateDelvesData` doesn't reset `storyVariant` or `isStoryCompleted` before recomputing ([Core.lua:68](../Source/Core/Core.lua#L68)). If the tooltip widget is missing on a refresh, the old values quietly stay.
- **Risk.** At `PLAYER_LOGIN`, POI and widget data for continents other than the player's current one may not be loaded yet, so the first snapshot may be incomplete.
- **Design.** Every Adventure Guide open and every expansion switch recomputes all expansions, including the achievement-criteria loops, with no throttling.

**Direction:** add a `DelvesData` service that owns refreshing. It would refresh at login, on `AREA_POIS_UPDATED`, on a daily-reset timer and on achievement/criteria events, with throttling, and broadcast a `DATA_UPDATED` event. Views only read from it.

### A2. Any file can read or write the saved settings, through two write paths
`DelveCompanionAccountData` and `DelveCompanionCharacterData` are referenced on about 60 lines across 11 files. There are two ways to write them:
- Through the Settings API, which broadcasts `SETTING_CHANGE` ([SettingsMain.lua:164](../Source/Settings/SettingsMain.lua#L164)).
- By assigning the field directly:
  - [GossipExtension.lua:386](../Source/Modules/GossipExtension/GossipExtension.lua#L386)
  - [GossipExtension.lua:419](../Source/Modules/GossipExtension/GossipExtension.lua#L419)
  - [InDelveWidgetFrame.lua:360](../Source/Modules/ProgressTracker/InDelveWidget/InDelveWidgetFrame.lua#L360)
  - [SettingsMain.lua:307](../Source/Settings/SettingsMain.lua#L307)

Direct writes never broadcast `SETTING_CHANGE`. Other problems in the same layer:
- **Risk.** `AddNewKeysToSave` copies default values by reference ([SettingsMain.lua:104](../Source/Settings/SettingsMain.lua#L104)). For table defaults (`inDelveWidgetPoint`, `ldbIconData`), the save and `Config.DEFAULT_*` end up as the same table object. LibDBIcon then writes `minimapPos` straight into `Config.DEFAULT_CHARACTER_DATA.ldbIconData` for an upgraded character save. The reset button does the same aliasing on purpose ([SettingsMain.lua:306](../Source/Settings/SettingsMain.lua#L306)). It's harmless only because `SavePosition` replaces the table instead of editing it.
- **Bug.** `RegisterSetting` returns `nil` when a key is missing, but no caller checks for that, so the next `Settings.Create*` call would throw. Its log line also passes a table to `%s` ([SettingsMain.lua:184](../Source/Settings/SettingsMain.lua#L184)), which raises an error in Lua 5.1.
- **Design.** `SETTING_CHANGE` carries only the bare key name, so account and character keys share one namespace.
- **Design.** The two modules depend on each other's internals:
  - Settings calls `DelveCompanion.InDelveWidget:Refresh(true)` directly from its reset button.
  - InDelveWidget reads `AddonSettings.optionsCategory`.

**Direction:** a small facade, `Settings:Get(key)` / `Settings:Set(key, value)`, that writes through `Settings.GetSetting(id):SetValue()` so every write notifies listeners. Deep-copy table defaults and namespace the event keys.

### A3. "Current season" is inferred from `LE_EXPANSION_LEVEL_CURRENT`
There are 16 references to `LE_EXPANSION_LEVEL_CURRENT`, and they treat the client's latest expansion as "the current Delves season". The configs are keyed inconsistently:
- By that constant: `NEMESIS_LURE`, `BOUNTY_MAPS`, `BOUNTY_ACTIVATED_SPELL` and `AFFIXES.Nemesis` ([Config.lua:99](../Data/Config.lua#L99)).
- By a named expansion: `DELVE_SEASON_FACTION_IDS` and `DELVES_CONFIG`.

Seasonal facts are hand-edited constants spread through the same file: `nemesisInfo.isCurrentSeason`, `labyrinthInfo.isAvailable`, the loot tables and `BOUNTY_MAP_QUEST`.

**Risk.** `LE_EXPANSION_LEVEL_CURRENT` will point at an expansion with no data in two situations: on the next expansion's beta/PTR (which `update_addon.ps1` deploys to: `_beta_`, `_ptr_`, `_xptr_`), and on live from the next pre-patch. Then:
- The minimap icon, the addon compartment and `/delves` all go through `Config.DELVE_SEASON_FACTION_IDS[LE_EXPANSION_LEVEL_CURRENT][season]` ([SettingsMain.lua:53](../Source/Settings/SettingsMain.lua#L53)). That raises "attempt to index a nil value".
- The LootInfo header is built from `nil` item and spell IDs ([LootInfoFrame.lua:49](../Source/Utility/LootInfo/LootInfoFrame.lua#L49)).
- Gilded Stash, the Loot button, the modifiers row and the Lure/Map buttons silently disappear, because they're all gated on `== LE_EXPANSION_LEVEL_CURRENT`.

**Direction:** one `Season` context resolved once at login, with explicit fallbacks. It would hold the expansion, season number, faction ID and the lure/map/affix IDs, and all code reads from it. Move seasonal balance data into its own file per season.

### A4. Views refresh in `OnShow`, while parents "refresh" them by calling `Show()`
These panels compute their content in `OnShow`: ExpBar, BountifulFrame, ConsumablesFrame, GildedStashFrame and CompanionConfigPanel. `DelveEncounter:Refresh()` tries to refresh them by calling `:Show()` ([DelveEncounter.lua:207-224](../Source/Modules/EJExtension/DelveEncounter/DelveEncounter.lua#L207-L224)). Calling `Show()` on a frame that's already visible does not fire `OnShow`.

- **Risk.** Suppose Blizzard's `EncounterRewardProgressFrame` stays visible while the displayed journey changes. The code's own comment notes that this frame shows and hides oddly ([DelveEncounter.lua:119](../Source/Modules/EJExtension/DelveEncounter/DelveEncounter.lua#L119)). The panels then keep showing the previous companion's or expansion's data.
- **Bug.** `ConfigPanel` isn't hidden on refresh when the companion has no trait config, so it keeps showing the previous companion.
- **Design.** The sub-panels fetch their input by reaching up into the parent singleton:
  - [BountifulFrame.lua:42](../Source/Modules/EJExtension/DelveEncounter/Bountiful/BountifulFrame.lua#L42)
  - [ConsumablesFrame.lua:27](../Source/Modules/EJExtension/DelveEncounter/Consumables/ConsumablesFrame.lua#L27)
  - GildedStash

  They call `DelveCompanion.EJExtension.DelveEncounter:GetFactionData()`, so the dependency points the wrong way.

**Direction:** the parent calls an explicit `panel:Refresh(context)` and passes the faction data down. `OnShow`/`OnHide` only register and unregister events.

### A5. Timing is handled with one-off `C_Timer.After` calls that can't be cancelled
Eight call sites delay work by 0.15–10 s to work around Blizzard timing:
- [GossipExtension.lua:58](../Source/Modules/GossipExtension/GossipExtension.lua#L58)
- [GossipExtension.lua:268](../Source/Modules/GossipExtension/GossipExtension.lua#L268)
- [GossipExtension.lua:295](../Source/Modules/GossipExtension/GossipExtension.lua#L295)
- [ProgressTracker.lua:56](../Source/Modules/ProgressTracker/ProgressTracker.lua#L56)
- [InDelveWidget.lua:135](../Source/Modules/ProgressTracker/InDelveWidget/InDelveWidget.lua#L135)
- [InDelveWidgetFrame.lua:161](../Source/Modules/ProgressTracker/InDelveWidget/InDelveWidgetFrame.lua#L161)
- [ConsumablesFrame.lua:128](../Source/Modules/EJExtension/DelveEncounter/Consumables/ConsumablesFrame.lua#L128)
- [GildedStashFrame.lua:52](../Source/Modules/EJExtension/DelveEncounter/GildedStash/GildedStashFrame.lua#L52)

Only the two InDelveWidget files use a token to drop stale callbacks.

- **Bug.** The auto-enter countdown has a race. Details are in the GossipExtension section below.
- **Bug.** Both event dispatchers wrap their handler in `function(...)`. The inner `...` (the timer callback's own arguments) hides the outer one, so every event argument after `arg1` is lost. See [GossipExtension.lua:58](../Source/Modules/GossipExtension/GossipExtension.lua#L58) and [ProgressTracker.lua:56](../Source/Modules/ProgressTracker/ProgressTracker.lua#L56).
- **Design.** ProgressTracker creates a new closure and a 1 s timer for every `SCENARIO_CRITERIA_UPDATE`, which fires often inside a Delve, and never merges them. ConsumablesFrame schedules one 0.5 s update per `BAG_UPDATE` (which fires once per bag, in bursts), and those updates still run after the frame has hidden.

**Direction:** one small debounce/ticker utility, reused everywhere, with `IsShown()` and token guards. This generalizes the token pattern InDelveWidget already uses.

### A6. Blizzard UI is modified directly from many places (taint surface)
All of the following runs from insecure addon code:
- **Writes into Blizzard frames and tables:**
  - `DelvesCompanionConfigurationFrame.playerCompanionID` ([DelveEncounter.lua:213](../Source/Modules/EJExtension/DelveEncounter/DelveEncounter.lua#L213))
  - `EncounterJournal.JourneysFrame.expansionFilter` ([EJExtension.lua:108-110](../Source/Modules/EJExtension/EJExtension.lua#L108-L110))
  - A new function added to Blizzard's global `ScrollUtil` table ([ScrollUtilHelper.lua:5](../Source/Utility/ScrollUtilHelper.lua#L5))
- **Encounter Journal changes:**
  - A tab injected into the EncounterJournal tab system with a hard-coded ID of `8` ([DelvesList.lua:17](../Source/Modules/EJExtension/DelvesList/DelvesList.lua#L17)).
  - Blizzard's tabs re-anchored on every `OnShow` ([EJExtension.lua:80](../Source/Modules/EJExtension/EJExtension.lua#L80)).
  - Direct calls into EJ internals: `EJ_HideNonInstancePanels`, `EncounterJournal_ShowGreatVaultButton`, `EncounterJournal_EnableExpansionDropdown`, `ExpansionEnumToEJTierDataTableId`, `GetEJTierData`.
- **Other Blizzard UI:**
  - Rewrites the text of `DelvesDifficultyPickerFrame.Description` and `EnterDelveButton`.
  - Adds a global `hooksecurefunc("StaticPopup_Show")`.
  - Edits GameTooltip FontStrings inside tooltip post-calls ([TooltipExtension.lua:143](../Source/Modules/TooltipExtension/TooltipExtension.lua#L143)).
- **Another addon's private data:** reads MapPinEnhanced's internal saved data, `MapPinEnhancedDB.storedPins` ([WaypointTracker.lua:117](../Source/Utility/WaypointTracker.lua#L117)).

The changelog shows what this has cost: "MoneyFrame taint" (2026.04.2), "secret values" (2026.03.3, 2026.06.1), "errors switching tabs" (2026.07.1), and issue #75. These touch points are spread over about 9 files with no guards or feature checks, so every Blizzard patch means re-checking file by file.

**Direction:** one `BlizzardBridge` module that owns every hook, write and internal call. It would check that each Blizzard function or frame field exists before using it, and it's the one place to update after a patch. Prefer addon-owned frames anchored to Blizzard frames over writing Blizzard fields.

### A7. Module boundaries and communication are inconsistent
Four communication mechanisms are mixed, with no rule for which to use when:
1. **EventRegistry custom events:** `SETTING_CHANGE`, `PROGRESS_TRACKER.*`.
2. **Direct reads of another module's state:**
   - GossipExtension and InDelveWidget read `ProgressTracker.isDelveInProgress` ([GossipExtension.lua:119](../Source/Modules/GossipExtension/GossipExtension.lua#L119)).
   - InDelveWidget reads `AddonSettings.optionsCategory`.
3. **Global functions used as an internal API:**
   - MinimapIcon and SlashCmd both call `DelveCompanion_CompartmentOnClick`. SlashCmd passes a fake `"LeftButton"` ([SlashCmd.lua:21](../Source/Utility/SlashCmd.lua#L21)).
   - `DelveCompanion_TooltipExtension_Init`.
4. **Global SavedVariables tables** (see A2).

One feature can also be split across several modules. Auto-exit has its setting in Settings, its checkbox and 10-second "just exited" flag in GossipExtension, and the actual `StaticPopup_Show` hook in ProgressTracker ([ProgressTracker.lua:74](../Source/Modules/ProgressTracker/ProgressTracker.lua#L74)).

**Direction:** a module contract (`Init`, plus public getters where needed). Events notify other modules of changes; getters answer state queries. Each feature lives in one module.

### A8. The build ships dev-only content and has no static checks
- **Bug *(verified)*.** The v2026.09.1 release zip contains `.github/AGENTS.md`. Releases are zipped from the local AddOns copy that `update_addon.ps1` makes, and that script excludes only what `.pkgmeta` lists. `.github` isn't listed. **A new `.claude/` folder, including this report, will ship the same way unless it's added to `.pkgmeta`.**
- **Design.** The unfinished `InfoFrame` (769 lines of XML plus Lua) is in the TOC load path ([DelvesList/Include.xml:16-17](../Source/Modules/EJExtension/DelvesList/Include.xml#L16-L17)). Every client parses it, and it registers a generic global template name, `TempEncounterInfoTemplate`, that could collide with other addons.
- **Risk.** `.pkgmeta` lists `SharedAnnotations.lua` as a bare file name. Robocopy `/XF` matches it, but the BigWigs packager treats ignore entries as paths from the repo root, and the file is in `Source/`. This only matters if CurseForge or Wago packaging is ever used.
- **Design.** There is no linting or CI, even though the EmmyLua annotations are good. The two global-read bugs below are exactly what `luacheck` or LuaLS diagnostics report.

---

## 2. Module-level issues

### Bootstrap / Core / Logger
- The uncommitted move of `EJExtension:Init()` into `OnPlayerLogin` is correct. Before it, another addon could force-load `Blizzard_EncounterJournal` during its own `ADDON_LOADED`, and EJExtension would then initialize before settings and `delvesData` existed. Worth committing.
- **Risk.** `UpdateDelvesData` calls `GetAchievementNumCriteria(achID)` with `achID = config.achievements.story` ([Core.lua:105](../Source/Core/Core.lua#L105)). That value is `nil` for Nemesis delves and the Labyrinth. It's safe only while their POI tooltips never contain a `TextWithState` widget with `orderIndex == 0`.
- **Bug.** Story matching calls `string.find(variant, criteria)` without `plain = true` ([Core.lua:108](../Source/Core/Core.lua#L108)), so the achievement criteria strings act as Lua patterns. See P0-1.
- **Design.** `table.insert(delvesData, expansion, expansionDelves)` ([Core.lua:60](../Source/Core/Core.lua#L60)) only works because Lua 5.1's `tinsert` tolerates out-of-range positions; Lua 5.3+ would throw. The intent is `delvesData[expansion] = expansionDelves`.
- **Design / Dead.**
  - `levelRequired` defaults to the Dragonflight max level ([Core.lua:54](../Source/Core/Core.lua#L54)) but only means something for Nemesis delves.
  - `Variables.maxLevelReached` and `Variables.isPTR` are written and never read.
- **Design.** `GetLootInfoFrame` keeps a frame in `Variables`, which is the runtime-state table ([Core.lua:170](../Source/Core/Core.lua#L170)). That one frame is shared by the Adventure Guide and the gossip window; each re-anchors it and sets `frameOverlap` on it.
- **Bug (minor).** Logger init uses the `a and b or c` idiom ([Logger.lua:56](../Source/Core/Logger.lua#L56)), so a saved `false` falls through to the default. That's correct only while the default is `false`.
- **Risk.** Lockit's `__index` logs missing keys through Logger ([LockitMain.lua:13](../Locale/LockitMain.lua#L13)). But Config reads Lockit while files are still loading, before `Logger:Init` runs, so keys missing there just become `nil` with no log.

### Data (Config / Definitions / Variables / Locale)
- **Design.** `Config.lua` mixes four kinds of data that change at different rates:
  - Stable game IDs.
  - Per-season balance tables (`DELVES_LOOT_INFO_DATA`, crests, item levels).
  - Flags that change during a season (`isCurrentSeason`, `labyrinthInfo.isAvailable`).
  - Localized UI strings: `nemesisInfo.delveTooltipLine` holds Lockit values ([Config.lua:451](../Data/Config.lua#L451)).

  So Data depends on the Locale load order, and every new season edits the same 1,000-line file.
- **Design.** Nemesis tooltip text is stored as `"<left>~<right>"` inside translatable strings and split at runtime. That's a formatting rule translators can't see; use two keys instead.
- **Bug (minor).** `LOOT_RARITY` is documented as inclusive at both ends, with overlapping bounds ([Config.lua:743](../Data/Config.lua#L743)), but `GetLootRarity` uses an exclusive upper bound ([LootInfoFrame.lua:102](../Source/Utility/LootInfo/LootInfoFrame.lua#L102)). It works by accident; pick one rule.
- **Dead.**
  - Definitions: `Definitions.CompanionWidgetLayout`, `DependencyAddonName.rio`, `Events.DELVE_INSTANCE_BUTTON_CLICK`.
  - Lockit keys: `UI_SETTING_COMPANION_CONFIG_*`, `UI_SETTING_GV_DETAILS_*`, `UI_SETTING_DASHBOARD_OVERVIEW_*`, `UI_GILDED_STASH_CANNOT_RETRIEVE_DATA_TWW`. All of these are still being translated in 5 locale files.
- **Design.** All 10 regular Midnight delves share `gildedStashUiWidgetID = 7591` ([Config.lua:501](../Data/Config.lua#L501)), so GildedStash's per-delve lookup loop is redundant; one ID per expansion would be clearer.
- **Note.** The TOC declares `Category-esMX`, but `esES.lua` returns early for every locale except `esES`, so `esMX` clients get English.

### Settings (SettingsMain / SettingsFrame)
- See A2: two write paths, defaults copied by reference, an unchecked `nil` from `RegisterSetting`, and a table passed to `%s`.
- **Bug *(verified via bytecode)*.** `StaticPopup_Show(ID, data.name, _, data.url)` ([SettingsFrame.lua:30](../Source/Settings/SettingsFrame.lua#L30)) passes the global `_`, which other addons often leak a value into. Pass `nil`.
- **Risk.** `DelveCompanion_CompartmentOpenDelvesInfo` ([SettingsMain.lua:53](../Source/Settings/SettingsMain.lua#L53)) doesn't handle `GetCurrentDelvesSeasonNumber()` returning 0 or `nil` (off-season), or a missing expansion row.
- **Design.** `DelveCompanion_CompartmentSetTooltipContent` and `DelveCompanion_CompartmentOpenDelvesInfo` are globals, although only the functions the TOC references need to be.

### EJExtension (+ DelvesList and list elements)
- **Bug *(verified via bytecode)*.** `EJ_OnShowHook` passes `ExpansionDropdown_Select` at [EJExtension.lua:90](../Source/Modules/EJExtension/EJExtension.lua#L90), but the local of that name is declared later, at [EJExtension.lua:121](../Source/Modules/EJExtension/EJExtension.lua#L121). So line 90 compiles to a global lookup (`GETTABUP _ENV "ExpansionDropdown_Select"`). When the Adventure Guide reopens on the Delves tab, the dropdown is rebuilt with the wrong callback. That's either `nil`, or a Blizzard global of the same name if one exists. Either way, picking an expansion from it skips the addon's handler, so `JourneysFrame.expansionFilter` isn't synced and the list doesn't refresh. **Fix:** declare the local above `EJ_OnShowHook`, or make it a method.
- **Risk.** The tab ID is hard-coded to `8` ([DelvesList.lua:17](../Source/Modules/EJExtension/DelvesList/DelvesList.lua#L17)), and `EJ_TABS_COUNT` ([EJExtension.lua:14](../Source/Modules/EJExtension/EJExtension.lua#L14)) is unused because its `PanelTemplates_SetNumTabs` call is commented out (issue #75). If Blizzard adds an 8th tab, both tabs will respond to `EJ_ContentTab_Select(8)`.
- **Design.** The code maps between EJ tiers and expansions in two different ways: `GetEJTierDataTableID(...)` for the minimum tier, and `GetServerExpansionLevel() + 1` for the fallback ([EJExtension.lua:143](../Source/Modules/EJExtension/EJExtension.lua#L143)).
- **Risk.** `DelvesListFrame:Refresh` calls `GetEJTierData(EJ_GetCurrentTier())` ([DelvesListFrame.lua:42](../Source/Modules/EJExtension/DelvesList/DelvesListFrame.lua#L42)), then indexes `Config.DELVE_MAPS[...]` and `delvesData[...]` with no nil checks ([:67](../Source/Modules/EJExtension/DelvesList/DelvesListFrame.lua#L67), [:71](../Source/Modules/EJExtension/DelvesList/DelvesListFrame.lua#L71)). The dropdown lists every tier up to `EJ_GetNumTiers()`, which can include a "Current Season" tier. `OnExpansionDropdownSelected` handles that tier as a special case; `Refresh` doesn't.
- **Design.** `DELVE_MAPS` is an ordered array (its comment says it "controls display order"), but it's iterated with `pairs` ([DelvesListFrame.lua:67](../Source/Modules/EJExtension/DelvesList/DelvesListFrame.lua#L67)). Use `ipairs`.
- **Design.** The list doesn't listen for `SETTING_CHANGE` on `delvesListInfoWidgetsEnabled`, so a change only applies on the next refresh. The element size calculator reads SavedVariables once per element.
- **Dead.** `OnDelveButtonClicked` dereferences `DelvesList.InfoFrame`, which is never created ([DelvesList.lua:52](../Source/Modules/EJExtension/DelvesList/DelvesList.lua#L52)).
- **List elements:**
  - **Design.** `DelveInstanceButton:Init` builds a new WaypointTracker, with fresh closures, every time the ScrollBox rebinds the frame ([DelveInstanceButton.lua:33](../Source/Modules/EJExtension/DelvesList/ListElements/DelveInstanceButton.lua#L33)). BountifulButton does the same ([BountifulButton.lua:44](../Source/Modules/EJExtension/DelveEncounter/Bountiful/BountifulButton.lua#L44)).
  - **Bug (minor).** The waypoint icon only refreshes on `SUPER_TRACKING_CHANGED`, which TomTom and MapPinEnhanced (MPE) waypoints don't fire. The icon goes stale in those modes.
  - **Design.** `DLDelveInfoWidget:Init` hides unused widgets but leaves their `frameCode` set ([DLDelveInfoWidget.lua:52](../Source/Modules/EJExtension/DelvesList/ListElements/DLDelveInfoWidget.lua#L52)). Recycled frames keep querying achievements for those hidden widgets in `Refresh`.
  - **Risk.** `bit.band(flags, …)` throws if `flags` is `nil`, which happens for an unknown achievement ID ([DelveListElement.lua:34](../Source/Modules/EJExtension/DelvesList/ListElements/DelveListElement.lua#L34)).
  - **Design.** The XML uses `relativeKey="$parentBackground"` 7 times (DelveInstanceButton.xml, DelveMapHeader.xml) and `$parentArtBg` once (BountifulButton.xml). That's not valid `relativeKey` syntax (it should be `$parent.Key`), and those keys don't exist anyway. The anchors fall back without any warning, so the layout works by accident.

### DelveEncounter (+ Bountiful, Consumables, GildedStash, Companion)
- See A4: `Show()` used as a refresh, a stale ConfigPanel, and children reaching into the parent singleton.
- See A6 for the write into `DelvesCompanionConfigurationFrame`. It's there because the addon reuses Blizzard's `CompanionConfigSlotTemplate`, whose mixin reads that global frame.
- **Bug *(verified)*.** GildedStash parses the localized spell tooltip with `strmatch(desc, GENERIC_FRACTION_STRING)` and then reads fixed character offsets ([GildedStashFrame.lua:131](../Source/Modules/EJExtension/DelveEncounter/GildedStash/GildedStashFrame.lua#L131)). `GENERIC_FRACTION_STRING` is a format string. Used as a pattern, `"%d/%d"` only matches single digits:
  - In my test, `"10/12"` came back as `"0/1"`.
  - In any locale that puts spaces around `/` or formats the fraction differently, the match returns `nil`. The following `strsub(nil)` then errors in both `Refresh` and the tooltip hook.

  Use `(%d+)%s*/%s*(%d+)` and check the result.
- **Risk.** GildedStash shows its widgets from a 0.15 s timer even if the panel was hidden in the meantime ([:52](../Source/Modules/EJExtension/DelveEncounter/GildedStash/GildedStashFrame.lua#L52)). `ErrorLabel` is hard-wired to the Midnight message ([:33](../Source/Modules/EJExtension/DelveEncounter/GildedStash/GildedStashFrame.lua#L33)).
- **ConsumablesFrame:**
  - **Bug (minor).** It starts a new 0.5 s timer on every event, without merging them or checking visibility ([ConsumablesFrame.lua:128](../Source/Modules/EJExtension/DelveEncounter/Consumables/ConsumablesFrame.lua#L128)).
  - **Dead.** The `self.Shards.frameType == Item` branch can never be true; `frameType` is set to Currency two lines above ([:60](../Source/Modules/EJExtension/DelveEncounter/Consumables/ConsumablesFrame.lua#L60)).
  - **Risk.** `GetCurrencyInfo(...).quantity` is used 4 times with no nil check.
  - **Design.** `SetInsecureAction` is re-applied on every update.
- **Risk.** ExpBar computes `current / needed`, which gives `inf` or `nan` when `needed == 0` ([ExpBar.lua:57](../Source/Modules/EJExtension/DelveEncounter/Companion/ExpBar.lua#L57)). `rankInfo` is `nil` if `GetFactionForCompanion` returns `nil`.
- **Design.** `FlavorSlot` visibility is hard-coded to `LE_EXPANSION_MIDNIGHT` ([DelveEncounter.lua:214](../Source/Modules/EJExtension/DelveEncounter/DelveEncounter.lua#L214)).
- **Design.** BountifulFrame calls `UpdateDelvesData()` from `OnShow` ([BountifulFrame.lua:39](../Source/Modules/EJExtension/DelveEncounter/Bountiful/BountifulFrame.lua#L39)); see A1.

### GossipExtension
- **Bug *(verified)*.** The delve at the entrance is identified with `strmatch(delveName, data.delveName)` ([GossipExtension.lua:174](../Source/Modules/GossipExtension/GossipExtension.lua#L174)), so each localized delve name is treated as a Lua pattern. `"Tak-Rethan Abyss"` doesn't even match itself, because `-` is a pattern quantifier. For that delve, and any localized name containing one of `-().%+*?[^$`, `GetDelveInfo` returns `false` for everything. As a result:
  - The story status always says "Not completed", whatever the actual progress.
  - `isBountiful` is `false`, so auto-enter skips the "no key" check and enters a Bountiful delve without a key. The setting's own tooltip promises it won't.

  Delves that aren't recognized at all also default to "not completed" ([:170](../Source/Modules/GossipExtension/GossipExtension.lua#L170)) instead of showing no status. **Fix:** use exact equality, or `string.find(header, name, 1, true)`. Ideally, identify the delve by map or POI ID.
- **Bug.** The auto-enter countdown is a recursive chain of `C_Timer.After` calls with no handle ([:268](../Source/Modules/GossipExtension/GossipExtension.lua#L268)), and `OnHide` resets `autoEnterCancelled = false` ([:150](../Source/Modules/GossipExtension/GossipExtension.lua#L150)). If the player closes and reopens the picker during the countdown:
  - A second chain starts.
  - The first chain keeps ticking, because its guard `IsEnteringPossible()` is true again.
  - The two chains overwrite each other's button text.
  - The first chain enters about one tick after the reopen instead of after the full configured delay.

  **Fix:** use one cancellable ticker and cancel it on hide, on cancel and on enter.
- **Bug (minor).** The exit cooldown (`exitTimer`) is a 10 s timer that can't be cancelled ([:295](../Source/Modules/GossipExtension/GossipExtension.lua#L295)). If the player exits twice within 10 s, the first timer clears the flag early.
- **Risk.** `ProcessEvent` runs 0.25 s after `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` ([:58](../Source/Modules/GossipExtension/GossipExtension.lua#L58)). It assumes `DelvesDifficultyPickerFrame` exists and is filled in by then, and doesn't check before calling `SetupDiffPicker`.
- **Risk.** `DisplayStoryStatus` sets the `Description` height to `GetHeight() + 500` on every show ([:440](../Source/Modules/GossipExtension/GossipExtension.lua#L440)). Once an explicit height is set, the next `GetHeight()` returns it, so the height can grow by 500 each time the picker opens.
- **Design.** The checkboxes write SavedVariables directly ([:386](../Source/Modules/GossipExtension/GossipExtension.lua#L386), [:419](../Source/Modules/GossipExtension/GossipExtension.lua#L419)); see A2. The module reads `ProgressTracker.isDelveInProgress` directly ([:119](../Source/Modules/GossipExtension/GossipExtension.lua#L119)); see A7.
- **Design.** Frame names look like `"$DelveCompanion.X"` ([:332](../Source/Modules/GossipExtension/GossipExtension.lua#L332)). Only `$parent` gets substituted, so these create globals literally named `$DelveCompanion.LootInfoButton` and so on. Pass `nil` as the name; the parentKey is enough.

### ProgressTracker
- **Bug (minor, harmless today).** After a reload inside a Delve, `Init` registers `baseEvents` but never sets `isSubscribed = true` ([ProgressTracker.lua:68](../Source/Modules/ProgressTracker/ProgressTracker.lua#L68)). The next `SCENARIO_UPDATE` registers them again and fires a second `DELVE_IN_PROGRESS`.
- **Bug.** The event payload is lost through the hidden `...` ([:56](../Source/Modules/ProgressTracker/ProgressTracker.lua#L56)); see A5. Every event, including the frequent `SCENARIO_CRITERIA_UPDATE`, is delayed 1 s with a new closure.
- **Risk.** Auto-exit hooks the global `StaticPopup_Show` and teleports out whenever the 4th argument equals the magic number `424700`, without checking `which` ([:74](../Source/Modules/ProgressTracker/ProgressTracker.lua#L74)). Any popup that passes that `data` value triggers `C_PartyInfo.DelveTeleportOut()`.
- **Design.** Respawn detection uses `string.match(arg1, 433110)` ([:124](../Source/Modules/ProgressTracker/ProgressTracker.lua#L124)). The number is converted to a pattern, so it matches anywhere as a substring. `lastSeenScenario` is annotated as `string` but holds a number, and it's never reset after exit.

### InDelveWidget (+ Frame, Item)
- **Bug.** Preview mode is inconsistent between two functions:
  - `PrepareWidget` uses `LE_EXPANSION_LEVEL_CURRENT` in preview ([InDelveWidgetFrame.lua:187](../Source/Modules/ProgressTracker/InDelveWidget/InDelveWidgetFrame.lua#L187)).
  - `Refresh` decides whether to show the Lure and Map buttons from `self.delveExpansion` alone ([:262](../Source/Modules/ProgressTracker/InDelveWidget/InDelveWidgetFrame.lua#L262)), and that comes from the player's current continent.

  Opening the options outside a Midnight zone previews only the Radar button.
- **Risk.** `delveExpansion` is `nil` for any Delve whose map isn't under a continent listed in `DELVE_CONTINENTS` ([InDelveWidget.lua:152](../Source/Modules/ProgressTracker/InDelveWidget/InDelveWidget.lua#L152)). In that case the Lure and Map buttons are hidden with no message. Worth checking for the Labyrinth (uiMapID 2647).
- **Design.** The widget position is persisted in two ways:
  - The named, movable frame is created before `PLAYER_LOGIN` "so WoW saves its position" ([InDelveWidget.lua:28](../Source/Modules/ProgressTracker/InDelveWidget/InDelveWidget.lua#L28)). That's the game's layout cache.
  - `Refresh` always re-anchors from `inDelveWidgetPoint` in SavedVariables.

  One mechanism is redundant, and the comment no longer describes what the code depends on.
- **Design.** `Refresh` repeats anchoring, scaling, item state, insecure-action attributes and layout on every `BAG_UPDATE`. Switching layout mixes `VerticalLayoutMixin` or `HorizontalLayoutMixin` into the same frame at runtime ([:331-333](../Source/Modules/ProgressTracker/InDelveWidget/InDelveWidgetFrame.lua#L331-L333)).
- **Positive.** The setup/refresh token pattern here is the right one to reuse elsewhere (see A5).

### TooltipExtension
- **Bug.** `FindLineInTooltip` loops over `tooltip:NumLines()` for whichever tooltip fired the post-call, but it reads the lines from `_G["GameTooltipTextLeft"..i]` ([TooltipExtension.lua:57](../Source/Modules/TooltipExtension/TooltipExtension.lua#L57)). `TooltipDataProcessor` post-calls also fire for ItemRefTooltip, the shopping tooltips and embedded tooltips. For those, the code searches the wrong tooltip and may edit it. Use `tooltip:GetName().."TextLeft"..i`, or better, append with `tooltip:AddLine(...)` instead of rewriting a line.
- **Risk.** The 2026.04.2 changelog says tooltip modifications were disabled to stop the `MoneyFrame` taint, but this code path still rewrites GameTooltip FontStrings ([:143](../Source/Modules/TooltipExtension/TooltipExtension.lua#L143)). If the post-call runs twice on the same lines, the text gets appended twice.
- **Design.** `ITEM_UNIQUE` is used as a pattern ([:69](../Source/Modules/TooltipExtension/TooltipExtension.lua#L69)). The currency post-call is dead code. The module is a global function rather than `DelveCompanion.TooltipExtension`.

### Utility
- **CustomActionWidget**
  - **Bug (latent).** `UpdateCooldown` always calls `C_Item.GetItemCooldown(frameCode)` ([CustomActionWidget.lua:260](../Source/Utility/CustomActionWidget.lua#L260)). For Spell, Currency and Achievement widgets, the ID gets looked up as an item ID. ID ranges in different namespaces overlap (for example, achievement IDs in the 40xxx range overlap WotLK item IDs), so the widget can show an unrelated item's cooldown swipe. The `enable` handling also differs from Blizzard's `CooldownFrame_Set`: it hides the cooldown when enabled. Limit this to Item and Toy widgets and use `CooldownFrame_Set`.
  - **Dead.** The `useMask` code path is commented out ("DOESN'T WORK IN MIDNIGHT"), yet `useMask` still changes what elements anchor to, and no template sets it.
  - **Risk.** `GetCurrencyInfo(code).iconFileID` has no nil check ([:220](../Source/Utility/CustomActionWidget.lua#L220)). The async toy-icon callback doesn't check that `frameCode` is still the same item.
- **WaypointTracker**
  - **Bug.** For delves with configured coordinates, MapPinEnhanced pins get 0–100 values ([WaypointTracker.lua:146](../Source/Utility/WaypointTracker.lua#L146)), while the same file documents `pinData.x/y` as 0–1. TomTom divides by 100 ([:56](../Source/Utility/WaypointTracker.lua#L56)). Every Nemesis delve uses the coordinates path, so their MPE pins land in the wrong place, probably clamped to a map edge. The two trackers also pick sources in opposite order: TomTom tries the POI first and then coordinates, MPE does the reverse.
  - **Bug.** Nothing handles the case where both the POI info and the coordinates are missing ([:53](../Source/Utility/WaypointTracker.lua#L53), [:150](../Source/Utility/WaypointTracker.lua#L150)). The Labyrinth hits this whenever its POI isn't active, since its coordinates are commented out in Config. Shift-clicking it with TomTom or MPE then throws a nil-index error.
  - **Design.** `Prepare()` builds closures for each instance that check `trackingType` on every call ([:181](../Source/Utility/WaypointTracker.lua#L181)). The `isActive` state is kept per button, even though SuperTrack is global. A single tracker service with a strategy table would remove the duplication and the allocations on every `Init`.
  - **Risk.** It reads MapPinEnhanced's private saved data, `MapPinEnhancedDB.storedPins` ([:117](../Source/Utility/WaypointTracker.lua#L117)), and identifies pins by title plus texture.
- **LootInfoFrame:**
  - It rebuilds static rows on every `OnShow` ([:178](../Source/Utility/LootInfo/LootInfoFrame.lua#L178)).
  - Callers must set `frameOverlap` before calling `Show`, an unstated contract.
  - Currency info has no nil checks.
- **ScrollUtilHelper.** It adds a function to Blizzard's global `ScrollUtil` table ([ScrollUtilHelper.lua:5](../Source/Utility/ScrollUtilHelper.lua#L5)). Use a helper local to the addon instead (see A6).
- **MinimapIcon.** The enabled flag is account-wide but the position is per character. `db.hide` is overwritten from the account flag at every login ([MinimapIcon.lua:55](../Source/Utility/MinimapIcon.lua#L55)), so the per-character `hide` field has no effect.
- **SlashCmd.** It forwards to `DelveCompanion_CompartmentOnClick` with a fake `"LeftButton"`, and silently does nothing in combat.

---

## 3. Crucial improvements (prioritized)

These are only the changes with a large payoff, either because they remove a whole class of bugs or because they fix a subtle, user-visible one. Everything else is in section 2.

### P0: small, contained fixes for real bugs
1. **Stop treating game and localized strings as Lua patterns.** Four places need it:
   - The gossip delve lookup: exact match or plain `find`, ideally keyed by map or POI ID.
   - Story criteria matching: `string.find(..., 1, true)`.
   - The Gilded Stash count: `(%d+)%s*/%s*(%d+)`.
   - The tooltip line search.

   This fixes the Tak-Rethan story and auto-enter bug, the two-digit and locale parsing bug, and the same latent bugs for every locale.
2. **Fix the forward reference in EJExtension** (a local used before it's declared). That restores the expansion dropdown's callback after the Adventure Guide is reopened. Bytecode confirms it.
3. **Make the auto-enter countdown one cancellable ticker** that's cancelled when the picker hides, when the player cancels, and when the delve is entered. Also pass event arguments through correctly in both deferred dispatchers.
4. **WaypointTracker:** convert MPE coordinates to 0–1, use the same source order (POI or coordinates first) for TomTom and MPE, and handle a missing POI plus missing coordinates gracefully.
5. **TooltipExtension:** work on the tooltip that fired, preferably with `AddLine`, and don't append twice. This also removes a remaining way the addon modifies GameTooltip text, which the changelog links to taint.
6. **Packaging:**
   - Add the `.github` and `.claude` folders to `.pkgmeta`.
   - Take `InfoFrame` out of the TOC until it's finished.
   - Rename `TempEncounterInfoTemplate` with the addon prefix.

### P1: structural changes
7. **DelvesData service (A1).** One owner for refreshing: event-driven, plus a daily-reset refresh, with throttling and a `DATA_UPDATED` event. GossipExtension reads fresh data. Fields that are recomputed on each refresh get reset first.
   - **Done (2026-11-09).**
     - `DelvesData` service with records, indexes, providers (Poi, Story), coalesced refreshes, combat deferral and a `DELVES_DATA.UPDATED` event.
     - `LibResetTracker-1.0` for daily and weekly resets.
     - All consumers migrated.
     - 34 offline tests (`lua Tests/run.lua`).
     - This also fixed the gossip delve lookup and the story-criteria matching from P0-1 (both now use plain text), and the missing `.github`/`.claude` entries from P0-6.
8. **Season context (A3).**
   - One object, resolved once at login, replaces every use of `LE_EXPANSION_LEVEL_CURRENT` and every table keyed by it.
   - When the client's season has no data, hide the feature and log it instead of throwing.
   - Move seasonal balance data into a file per season (for example `Data/Seasons/Midnight_S2.lua`).
9. **Settings facade (A2).** `Get`/`Set` go through the Settings API so every write broadcasts `SETTING_CHANGE`. Deep-copy defaults. No module reads the SavedVariables globals directly.
10. **Explicit view refresh (A4).** The parent calls `Refresh(context)` and passes the data down. `OnShow` only registers and unregisters events. This fixes the stale panels in the Delves encounter window.
11. **Shared debounce/ticker utility (A5).** Use tokens to drop stale callbacks, and replace the 8 one-off timers.
12. **BlizzardBridge (A6).**
    - One module owns every hook, write and internal call, and checks that each Blizzard function or frame field exists before using it.
    - Remove writes into Blizzard tables (`ScrollUtil`, `DelvesCompanionConfigurationFrame`, `JourneysFrame.expansionFilter`) wherever an addon-owned alternative exists.
    - Document why each remaining one is needed.

    This turns "re-audit 9 files after every patch" into "re-check one file".
13. **Tooling.** Add a `.luacheckrc` (WoW API globals plus a whitelist of the addon's intentional globals) and a GitHub Actions job that runs luacheck or LuaLS on pull requests. Two of the confirmed bugs here (`ExpansionDropdown_Select` and the global `_`) are exactly what it reports.

---

## 4. What is already solid (keep it)
- **Consistent EmmyLua annotations** for XML templates and data shapes. They make the code easy to navigate and would make a type-checking job (P1-13) cheap to add.
- **Disciplined localization:** a key-naming convention, an enUS default with overrides per locale, and in-game terms reused through `_G` strings.
- **Secret-value guards** (`issecretvalue`/`issecrettable`) in TooltipExtension. Combat checks guard the gossip and EJ loot buttons, the compartment and tooltip processing.
- **InDelveWidget's token-based staleness guard**, which is the pattern to reuse across the codebase.
- **The uncommitted change** that moves EJExtension init to `OnPlayerLogin`, after settings and data exist.
