# Delve Companion — agent context summary

## Purpose

Delve Companion is a World of Warcraft addon focused on Delves. It enhances the built-in Delves experience by adding a dedicated Delves tab to the Adventure Guide/Encounter Journal, extending the Delve Encounter UI, improving the Delves gossip flow, and tracking progress while a Delve is active.

The addon is intentionally lightweight and built directly on WoW APIs and Blizzard frame XML. It uses a small set of common community libraries only where necessary (LibStub, CallbackHandler, LibDataBroker, LibDBIcon).

---

## High-level architecture

The addon is organized around a central master table, `AddonTbl.DelveCompanion`, which exposes the main subsystems:

- `Logger` – lightweight logging helper.
- `Config` – static config, game IDs, Delve definitions, and saved-data defaults.
- `Variables` – runtime flags such as optional dependency availability, and frame references.
- `Definitions` – enums, event names, and shared constants.
- `DelvesData` – service that owns all Delves runtime data (see "Data model notes").
- `AddonSettings` – account/character settings handling.
- `EJExtension` – integration with the Encounter Journal / Adventure Guide UI.
- `ProgressTracker` – scenario-based Delve lifecycle tracking.
- `InDelveWidget` – temporary frame shown during Delves.
- `GossipExtension` – auto-enter and Delves gossip enhancements.
- `MinimapIcon` – optional minimap access point.
- `UISkin` – restyles addon frames to match a supported UI suite (ElvUI, EllesmereUI).

Bootstrapping happens in two phases via `Source/Bootstrap.lua`:

1. `ADDON_LOADED` – initialize saved variables, optional dependencies, `UISkin`, and preload UI frames.
2. `PLAYER_LOGIN` – initialize settings, minimap icon, progress tracker, in-delve widget, gossip extension, `DelvesData`, and tooltips. `EJExtension` initializes once `Blizzard_EncounterJournal` is loaded (deferred at the end of this phase).

Layering rule: `Libs` → `Data` → `Services` → `Utility`/`Settings` → `Modules`. Services never reference modules or frames.

---

## Repository navigation

### Root
- [README.md](README.md) – short project description.
- [DelveCompanion_Mainline.toc](DelveCompanion_Mainline.toc) – addon manifest and load order.
- [.github/AGENTS.md](.github/AGENTS.md) – this file, agent-oriented repository summary.

### Data and configuration
- [Data/Config.lua](Data/Config.lua) – game IDs, currency IDs, Delve definitions, saved-data schema, and expansion-specific content.
- [Data/Definitions.lua](Data/Definitions.lua) – shared enums, dependency addon names, event identifiers, and layout constants.
- [Data/Variables.lua](Data/Variables.lua) – runtime state and feature flags.

### Core bootstrap and shared infrastructure
- [Source/Bootstrap.lua](Source/Bootstrap.lua) – addon startup, dependency detection, and initialization sequence.
- [Source/Core/Core.lua](Source/Core/Core.lua) – the `DelveCompanion` master table and small shared helpers (continent lookup, Loot Info frame, max tier).
- [Source/Core/Logger.lua](Source/Core/Logger.lua) – logging utility.

### Services
- [Source/Services/DelvesData](Source/Services/DelvesData) – owner of all Delves runtime data: records, indexes, providers, refresh scheduling, `UPDATED` event.
- [Libs/LibResetTracker-1.0](Libs/LibResetTracker-1.0) – first-party, addon-independent library that fires daily/weekly reset callbacks (see its README).

### Tests
- [Tests](Tests) – offline Lua tests with WoW API stubs. Run `lua Tests/run.lua` (Lua 5.2+, or the VS Code "Run Tests" task). Not packaged.

### UI modules
- [Source/Modules/EJExtension](Source/Modules/EJExtension) – Encounter Journal integration.
  - Adds a custom Delves tab to the Adventure Guide / Encounter Journal.
  - Injects a dedicated Delves list frame and its expansion dropdown logic.
- [Source/Modules/EJExtension/DelveEncounter](Source/Modules/EJExtension/DelveEncounter) – enhancements for the built-in Delve Encounter window.
  - Exp bar, companion config panel, bountiful/consumables/gilded stash frame hooks, and loot-info controls.
- [Source/Modules/GossipExtension](Source/Modules/GossipExtension) – Delves gossip integration.
  - Detects Delves difficulty picker / tiered entrance UI, displays story status, and offers auto-enter automation.
- [Source/Modules/ProgressTracker](Source/Modules/ProgressTracker) – lifecycle tracking for active Delves.
  - Monitors scenario state, completion events, respawn events, and exit transitions.
  - Drives the In-Delve widget.
- [Source/Modules/TooltipExtension](Source/Modules/TooltipExtension) – tooltip post-processing for game items and currencies.

### Utility components
- [Source/Utility/CustomActionWidget.lua](Source/Utility/CustomActionWidget.lua) – generic widget used to render icons, item/currency/spell/achievement/toy data, and optional click behavior.
- [Source/Utility/WaypointTracker.lua](Source/Utility/WaypointTracker.lua) – waypoint setting support for SuperTrack, TomTom, and MapPinEnhanced.
- [Source/Utility/MinimapIcon.lua](Source/Utility/MinimapIcon.lua) – optional minimap entry point.
- [Source/Utility/SlashCmd.lua](Source/Utility/SlashCmd.lua) – slash command handling.
- [Source/Utility/LootInfo](Source/Utility/LootInfo) – reusable loot info frame shown from multiple UI surfaces.
- [Source/Utility/DelveOBotWidget.lua](Source/Utility/DelveOBotWidget.lua) – separate helper/widget component.
- [Source/Utility/ScrollUtilHelper.lua](Source/Utility/ScrollUtilHelper.lua) – scroll helper used by some UI frames.

### Settings and localization
- [Source/Settings](Source/Settings) – settings UI and saved-variable synchronization.
- [Locale](Locale) – localization files and XML registration.
- [Release Notes](Release Notes) – release notes and packaging helpers.

---

## Module breakdown

### 1) Delves List
Location: [Source/Modules/EJExtension/DelvesList](Source/Modules/EJExtension/DelvesList)

This is the addon’s core feature. It injects a custom Delves tab into the Encounter Journal / Adventure Guide and builds a dedicated Delves list UI. The module is responsible for:

- creating the custom tab button inside the Encounter Journal;
- populating the Delves list by expansion and map;
- wiring the expansion dropdown so the Delves list behaves like a first-class tab;
- preparing list elements for individual Delves.

Note: the info-frame implementation under [Source/Modules/EJExtension/DelvesList/InfoFrame](Source/Modules/EJExtension/DelvesList/InfoFrame) is currently unfinished and should be ignored for now.

Agent note: this is the primary integration point for Adventure Guide UI changes.

### 2) Delve Encounter
Location: [Source/Modules/EJExtension/DelveEncounter](Source/Modules/EJExtension/DelveEncounter)

This module hooks into the existing Delve Encounter window that Blizzard already provides and enriches it with addon-driven panels. It includes:

- an experience bar for the companion progression flow;
- a companion configuration panel for Delve companion-related details;
- UI panels for Bountiful reward info, consumables, and Gilded Stash data;
- a loot info button that opens a dedicated loot information frame.

Agent note: this is the place to look for UI extensions tied to the built-in Delve encounter view.

### 3) Gossip extension
Location: [Source/Modules/GossipExtension/GossipExtension.lua](Source/Modules/GossipExtension/GossipExtension.lua)

This module watches Delves-related gossip UI (`PLAYER_INTERACTION_MANAGER_FRAME_SHOW`) and enhances the Delves difficulty picker window. Its responsibilities include:

- identifying whether the current interaction is a Delve entrance;
- showing story status in the gossip flow when enabled;
- adding a loot-info button and auto-enter controls to the Delves UI;
- allowing the player to enable/disable delayed auto-enter and cancel it while the countdown runs.

Agent note: this module is tightly coupled with Blizzard’s Delves difficulty picker frame.

### 4) Progress Tracker
Location: [Source/Modules/ProgressTracker/ProgressTracker.lua](Source/Modules/ProgressTracker/ProgressTracker.lua)

This module tracks the lifecycle of a Delve session by reacting to scenario and zone events. It determines when:

- a Delve starts;
- the Delve is completed;
- a Delve is exited;
- a respawn is activated.

The tracked state is broadcast through `Definitions.Events.PROGRESS_TRACKER` so other components can react.

Agent note: if you need to add or change behavior tied to “in Delve” state, start here.

### 5) In-Delve Widget
Location: [Source/Modules/ProgressTracker/InDelveWidget](Source/Modules/ProgressTracker/InDelveWidget)

The In-Delve Widget is a separate UI frame shown while the player is inside a Delve. It is driven by the Progress Tracker and can be configured to appear on the left, right, or in a custom position. Its purpose is to present extra information or quick actions during the Delve session.

Agent note: this is mostly a presentation/UX module and depends strongly on the Progress Tracker state.

### 6) Utility components

#### CustomActionWidget
Location: [Source/Utility/CustomActionWidget.lua](Source/Utility/CustomActionWidget.lua)

A reusable UI widget that can display an icon for items, spells, currencies, achievements, or toys. It can optionally behave like a clickable button and can show a label, cooldown overlay, mask, or border.

#### WaypointTracker
Location: [Source/Utility/WaypointTracker.lua](Source/Utility/WaypointTracker.lua)

A small but important utility that sets waypoints to Delve entrances and POIs. It supports:

- Blizzard SuperTrack;
- TomTom; and
- MapPinEnhanced.

It uses `DelveRecord`s from `DelvesData` and the available POI information from the game API. TomTom waypoint handles are kept in the module, keyed by Delve uiMapID (never on the record).

#### UISkin
Location: [Source/Utility/UISkin](Source/Utility/UISkin)

Makes addon frames match a supported UI suite. It does nothing when none is loaded, or when `uiSkinEnabled` is off (applied on reload).

- `Core/` – the portable core, shared with other addons by copying the folder verbatim (see [Core/README.md](Source/Utility/UISkin/Core/README.md)). It never references Delve Companion: it exports itself as `AddonTbl.UISkin` and its state is file-private.
  - `UISkin.lua` – the public interface. `Init(options)` is called on `ADDON_LOADED` with the injected settings (`savedVariables`, `saveKey`, `defaultEnabled`, `log`). It selects the first available adapter and waits for it to report ready, queueing requests meanwhile. It gives up 5 s after `PLAYER_LOGIN` (its own timer), e.g. when EllesmereUI skinning is off for this addon.
  - `Ops.lua` – suite-agnostic helpers for recipes (`HideRegions`, `CreateHolder`, `FlatHighlight`).
  - `Adapters/ElvUI.lua`, `Adapters/EllesmereUI.lua` – one per suite, identified by `UISkin.Suite`. They implement the same primitives (`Window`, `Panel`, `StripPanel`, `Inset`, `Button`, `Tab`, `CloseButton`, `Checkbox`, `ScrollBar`, `Icon`, `IconQualityBorder`, `StatusBar`, `Font`, `TextColor`, ...) on top of the suite's public skinning API. Each follows the suite's own toggle for the Blizzard window our frames live in (the recipe's `host`).
- `Recipes.lua` – Delve Companion's recipes, one per kind of addon frame, written against the primitives only. It also exposes the core as `DelveCompanion.UISkin`. A recipe is one function for all suites. Where suites genuinely differ, register per-suite variants instead (`{ default = fn, [Suite.ElvUI] = fn }`, shared steps in a local helper). This is the only mechanism: adapters carry no style flags.

`Bootstrap` calls `UISkin:Init` with the `uiSkinEnabled` account key. Modules call `DelveCompanion.UISkin:Apply("<Recipe>", frame)` where they create a frame. Each recipe runs once per frame, so it is safe for pooled frames. Recipes run in `xpcall`: a failure is logged and never breaks a feature.

The Encounter Journal tab chain uses `UISkin:GetTabLayout(Host.journal, tab)`. It returns `nil` unless the suite keeps its own chain (ElvUI), and `EJExtension` then uses the stock layout. EllesmereUI keeps none: Blizzard re-anchors the stock tabs on every show.

Suite pitfalls:
- EllesmereUI's `Panel` fades every texture of the frame it gets, so never pass it a frame whose own textures are content (a StatusBar's fill, icons): put the backdrop on `Ops.CreateHolder` instead.
- EllesmereUI squares icons, so Blizzard's round `IconBorder` ring no longer fits: the adapter fades it and draws EllesmereUI's square quality border, which follows the ring's color and shown state.
- ElvUI's `HandleIconBorder` copies a hidden ring's color too (white when never colored): the adapter resets it to the default border.

#### TooltipExtension
Location: [Source/Modules/TooltipExtension/TooltipExtension.lua](Source/Modules/TooltipExtension/TooltipExtension.lua)

A lightweight tooltip enhancement module. At the moment it mainly appends extra information to item tooltips (for example, Bounty Map-related data) via tooltip post-calls.

---

## Data model notes

All Delves runtime data is owned by the `DelvesData` service ([Source/Services/DelvesData](Source/Services/DelvesData)). It is the single source of truth for the Delves list, the Bountiful panel, gossip decisions, and waypoints.

**Records.** One `DelveRecord` per Delve in `Config.DELVES_CONFIG`, keyed by uiMapID, built once at `PLAYER_LOGIN` and never replaced. Records are **read-only** for consumers.
- Static fields: `id`, `expansion`, `kind` (`Definitions.DelveKind`: Regular / Nemesis / Labyrinth), `config`, `delveName`, `parentMapID`, `parentMapName`, `levelRequired` (Nemesis only).
- Provider fields: `poiID`, `isBountiful` (PoiProvider); `storyVariant`, `storyStatus` (StoryProvider, `Definitions.DelveStoryStatus`: Unknown / NotCompleted / Completed / NotTracked).

**Reading.** Use the accessors, never index internals: `Get(mapID)`, `GetByPoi`, `GetByStoryAchievement`, `FindByEntranceName(text)` (plain text, no Lua patterns), `GetExpansions`, `GetDelves(exp)`, `GetZones(exp)`, `GetBountiful(exp)`, `IterateAll`. Returned lists are read-only.

**Freshness.** Providers refresh on game events (`AREA_POIS_UPDATED`, `PLAYER_ENTERING_WORLD`, `CRITERIA_EARNED`/`ACHIEVEMENT_EARNED` for story achievements) and on daily resets (LibResetTracker, +5 s and +60 s after the reset). Requests are merged within 0.5 s and wait until combat ends. Views that open rarely call `EnsureFresh(maxAgeSec)`; the gossip window calls `RefreshNow` for the entrance Delve.

**Change notifications.** `Definitions.Events.DELVES_DATA.UPDATED` (EventRegistry) fires only when a field changed. Payload: `{ reason, delves = {[uiMapID]=true}, fields = {[name]=true} }`. Views subscribe while shown.

**Adding data.** Register a provider with `DelvesData:RegisterProvider({ name, fields, events?, resets?, InitRecord?, FilterEvent?, Refresh })`. Each field has exactly one owning provider; providers write only through `ctx:Set(record, field, value)`, which tracks changes. Providers run in registration order and may read fields of earlier providers.

**Debugging.** `/delvecomp data` prints all records; `/delvecomp data reset` simulates a daily reset.

---

## Important implementation conventions for agents

- The addon is frame-based and XML-driven. Many UI components are created dynamically from XML templates and mixins.
- The central object is `DelveCompanion`, not a classic OOP hierarchy. Modules attach themselves to this table and use methods like `:Init()`, `:Refresh()`, and `:ProcessEvent()`.
- A lot of behavior is tied to events from Blizzard’s Delves UI rather than to custom event buses. Expect hooks around `EncounterJournal`, `DelvesDifficultyPickerFrame`, `JourneysFrame`, and scenario events.
- Settings are persisted via WoW SavedVariables and synced through `AddonSettings`.
- Optional dependency support is explicit: TomTom, MapPinEnhanced, ElvUI and EllesmereUI are detected at startup and used conditionally.
- New frames that use Blizzard art or templates should get a `UISkin` recipe. Add it to `Recipes.lua` and call `UISkin:Apply` where the frame is created.
- Delves data comes from `DelvesData` only. Don't cache Delve state in modules or write fields on `DelveRecord`s; add a provider instead.
- `Libs/LibResetTracker-1.0` must stay independent from the addon (no `DelveCompanion` references), so it can be reused in other addons.
- `Source/Utility/UISkin/Core` must stay independent from the addon too (a test enforces it). Inject addon-specific values through `UISkin:Init`; put addon frames' styling in `Recipes.lua`.
- Run `lua Tests/run.lua` after changing services, the library or the UISkin core.

---

## Suggested starting points

If you are trying to understand or change behavior, the best entry points are:

1. [Source/Bootstrap.lua](Source/Bootstrap.lua) – startup and initialization order.
2. [Source/Modules/EJExtension/EJExtension.lua](Source/Modules/EJExtension/EJExtension.lua) – how the addon integrates with the Encounter Journal.
3. [Source/Modules/GossipExtension/GossipExtension.lua](Source/Modules/GossipExtension/GossipExtension.lua) – Delves gossip and auto-entry behavior.
4. [Source/Modules/ProgressTracker/ProgressTracker.lua](Source/Modules/ProgressTracker/ProgressTracker.lua) – state changes during a Delve run.
5. [Data/Config.lua](Data/Config.lua) – canonical Delve definitions and feature flags.
