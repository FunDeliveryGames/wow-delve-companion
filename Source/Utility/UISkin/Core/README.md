# UISkin core

Restyles an addon's frames to match a supported UI suite: **ElvUI** or **EllesmereUI**. It does nothing when no suite is loaded.

This folder is copied as-is into every addon that uses it. It is not a library: there is no LibStub and no globals. Each addon gets its own private copy through its addon table (`AddonTbl.UISkin`).

## Rules for copies

- Never reference the host addon from here: no namespace, saved variables, logger or config. Anything addon-specific is injected through `Init` or registered as recipes.
- Keep the copies identical. Make a change in one, then copy the folder to the others.

## Integration

1. In the TOC, add the suites as optional dependencies so they load first:

    ```
    ## OptionalDeps: ElvUI, EllesmereUI
    ```

2. Include the core, then the addon's recipes:

    ```xml
    <Include file="Core\Include.xml" />
    <Script file="Recipes.lua" />
    ```

3. Register recipes, one per kind of addon frame. Write them against the adapter contract (`UISkinAdapter` in `UISkin.lua`), so one function serves every suite:

    ```lua
    local _, AddonTbl = ...
    local UISkin = AddonTbl.UISkin

    UISkin:RegisterRecipe("MainWindow", UISkin.Host.standalone, function(skin, frame)
        skin:Window(frame)
        skin:CloseButton(frame.CloseButton)
        skin:TextColor(frame.Title)
    end)
    ```

    Only where suites genuinely need different treatment, register per-suite variants keyed by `UISkin.Suite`. `default` serves the other suites; a suite with neither doesn't get the recipe. Put the shared steps in a local helper:

    ```lua
    local function SkinRowBackdrop(skin, row)
        skin:Panel(UISkin.Ops.CreateHolder(row, row.Art, 1))
    end

    UISkin:RegisterRecipe("Row", UISkin.Host.journal, {
        default = SkinRowBackdrop,
        [UISkin.Suite.ElvUI] = function(skin, row)
            UISkin.Ops.HideRegions(row:GetNormalTexture())
            SkinRowBackdrop(skin, row)
        end
    })
    ```

4. On `ADDON_LOADED`, once the saved variables are ready, call `Init` once:

    ```lua
    UISkin:Init({
        savedVariables = MyAddonAccountData, -- Table holding the on/off toggle. Read once, here.
        saveKey = "uiSkinEnabled",           -- Key of the toggle. Changes apply on reload.
        defaultEnabled = true,               -- Used when the toggle is unset.
        log = function(message) print(message) end -- Optional debug output.
    })
    ```

    All options are optional. Without `savedVariables` or `saveKey`, skinning follows `defaultEnabled`. `Init` also starts the ready timeout: a suite that hasn't reported ready 5 s after `PLAYER_LOGIN` is given up.

5. Apply a recipe where each frame is created. It is safe to call repeatedly: a recipe runs once per frame. Requests made before the suite is ready are queued.

    ```lua
    UISkin:Apply("MainWindow", frame)
    ```

## Public interface

| Member | Purpose |
|---|---|
| `Host` | Blizzard windows recipes can live in (`journal`, `picker`, `settings`, `standalone`). Adapters follow the suite's own toggle for each window. |
| `Suite` | Ids of the supported suites (`ElvUI`, `EllesmereUI`), the keys of per-suite recipe variants. |
| `Ops` | Suite-agnostic helpers for recipes: `HideRegions`, `CreateHolder`, `FlatHighlight`. |
| `RegisterAdapter(adapter)` | Add a suite adapter. The first available one is used. |
| `RegisterRecipe(name, host, recipe)` | `recipe(skin, frame)` restyles one kind of frame, or `recipe` is a table of per-suite variants. `host = nil`: only the suite's global toggle counts. |
| `Init(options)` | Select an adapter and hook into its suite. |
| `Apply(name, frame)` | Run a recipe on a frame. |
| `PaintAccent(texture, alpha)` | Paint a texture with the suite's accent color, and keep it in sync with live theme changes. |
| `IsActive()` / `IsHostActive(host)` | Whether a suite skin is in use (for a window). |
| `GetTabLayout(host, tab)` | The suite's tab chain for a window, or `nil` (use your own). |
| `SetTabSelected(host, tab, selected)` | Force the selected look of a tab the addon switches itself. |
| `GetState()` / `GetAdapterName()` / `GetFailure(name)` | Debugging. Recipes run in `xpcall`: a failure is logged and kept here. |

## Primitives

Recipes call the adapter (`skin`) only through the `UISkinAdapter` contract: containers (`Window`, `Panel`, `StripPanel`, `Inset`), widgets (`Button`, `Tab`, `CloseButton`, `Checkbox`, `ScrollBar`), icons (`Icon`, then `IconQualityBorder` for a quality ring), `StatusBar`, and text (`Font` for the suite's UI font, `TextColor` for its text color). A suite without an equivalent implements a primitive as a no-op, e.g. ElvUI's `Font` and `TextColor`.

## Extending

- **New primitive:** add it to the `UISkinAdapter` contract in `UISkin.lua`, then implement it in every adapter.
- **New window:** add it to `UISkin.Host`, then map it in the adapters with per-window toggles (ElvUI `HOST_TOGGLES`).
- **New suite:** add its id to `UISkin.Suite` (and the `UISkinSuite` alias), add `Adapters/<Suite>.lua` implementing the contract with that `id`, and list it in `Include.xml` in priority order.
