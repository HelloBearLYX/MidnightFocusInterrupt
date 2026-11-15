# MidnightFocusInterrupt — Architecture & API Reference

This file is a fast-loading reference for AI assistants and developers extending this addon.
It documents the module lifecycle, the public APIs (`addon.core`, `addon.Utility`, `addon.GUI`),
and the exact steps to add a new module + config panel.

`addon` = the addon-private table (second vararg of `local ADDON_NAME, addon = ...`), shared by every file via the `.toc` load order.

This addon shares its exact architecture with its sibling `HBLyx_Tools` (same author) — see that addon's `HB_Addon.md` for
the fuller rationale. `MidnightFocusInterrupt` is a focused subset: it ships a single module (`FocusInterrupt`), fewer
libraries/locales, and a smaller set of derived "addon states" (no `inCombat`/`encounterInfo`/`instanceInfo`).

## File Layout

```
MidnightFocusInterrupt.toc -- load order: embeds.xml -> Locales -> Core\core.xml -> GUI\gui.xml
                           -- -> Modules\FocusInterrupt.lua -> Configs\GUIUtility.lua -> Configs\General.lua
                           -- -> Configs\FocusInterrupt.lua -> Configs\Profile.lua -> developer.lua
embeds.xml                 -- third-party libraries (LibStub, CallbackHandler, LibDataBroker, AceLocale, LibSharedMedia, AceSerializer, LibDeflate, LibDBIcon)
Core/core.xml               -- loads, in order: Utility.lua -> Initialize.lua -> DBHandler.lua -> EventsHandler.lua -> ModuleHandler.lua
Core/Utility.lua             -- addon.Utility: helpers, drag-to-move editFrame, popups, string/color/sound utils, enums
Core/Initialize.lua          -- addon.core: the Core "facade" — LDB/slash-command setup ("/mfi", "/midnightfocusinterrupt"),
                           -- Core:Initialize()/Configure(), and forwards addon.core:<method>(...) calls to whichever sub-handler implements them
Core/DBHandler.lua           -- addon.core.DBHandler: per-module default registration + addon.db validation/reset (saved variable: MidnightFocusInterrupt_DB)
Core/EventsHandler.lua       -- addon.core.EventsHandler: WoW event registry + the derived "addon state" system
Core/ModuleHandler.lua       -- addon.core.ModuleHandler: module registry, load/unload, test mode
Configs/GUIUtility.lua       -- addon.GUI table + its Create* widget factories (Slider, Dropdown, ToggleBox panel wrappers, etc.)
Configs/General.lua          -- the config window architecture itself: root frame/toolbar/tab-group, TABS table, General tab,
                           -- Render/OpenGUI/CloseGUI/SelectTab/RegisterModule — loaded right after GUIUtility.lua, before any Configs/<Name>.lua
TemplateModule.lua          -- copy-paste starting point for a new module (NOT loaded by the .toc)
Modules/FocusInterrupt.lua  -- the sole module's logic/behavior
Configs/FocusInterrupt.lua  -- FocusInterrupt's config panel (RenderPanel) + default settings (addon.core:RegisterDBDefaults)
Configs/Profile.lua         -- export/import of the FocusInterrupt module's saved profile only (single-module addon, no full-db export)
Locales/*.lua               -- AceLocale-3.0 string tables (enUS.lua is canonical, others are translations)
GUI/*.lua                   -- low level widget implementations (Slider, Dropdown, ToggleBox, etc.) built via addon.UICore, loaded via GUI/gui.xml
```

Modules and Configs are **paired by module key** (here just `"FocusInterrupt"`), which is used as:
- `addon.db[modKey]` — the saved-variable table for that module's settings
- the defaults table passed to `addon.core:RegisterDBDefaults(modKey, defaults)` — merged into `addon.db[modKey]` on load/reset
- the key in `addon.core.ModuleHandler.registeredMods` / `addon.core.ModuleHandler.modules`
- the key in `addon.GUI.tabPanels`
- the `module` field of a `TABS` entry in `Configs/General.lua`

## Module Lifecycle

1. `Modules/<Name>.lua` defines a table `local X = { modName = "X", ... }` with methods:
   - `X:Initialize()` → returns `self` (or `nil` to abort, e.g. wrong class). Called lazily, only once, when the module becomes enabled.
   - `X:RegisterEvents()` → optional. Called right after a successful `Initialize()`. Register WoW events / state monitors here.
   - `X:UpdateStyle()` → optional. Called whenever settings change (via `GetSafeUpdate`) and on `PLAYER_ENTERING_WORLD`.
   - `X:Test(on)` → optional. Toggle a visual preview; called by `addon.core:TestMode()` / `addon.core:TestModule()`.
   - Ends with: `addon.core:RegisterModule(X.modName, L["XSettings"], function() return X:Initialize() end)`
2. `Configs/<Name>.lua` defines:
   - `addon.core:RegisterDBDefaults(MOD_KEY, { Enabled = true, ... })` (defaults)
   - `local function RenderPanel(parent) ... return frame end` — builds the config UI using `GUI:Create*` widget factories
   - Ends with: `GUI:RegisterModule(MOD_KEY, RenderPanel)`
3. `Configs/General.lua`'s `TABS` table adds one entry per module:
   ```lua
   {text = addon.core:GetModuleName("X"), type = "Button", module = "X", tooltip = L["XSettingsDesc"],
    panelFunction = function(container) return addon.GUI.tabPanels.X(container) end},
   ```
   The `function(container) return addon.GUI.tabPanels.X(container) end` wrapper is required (not a direct reference) because
   `Configs/General.lua` loads **before** the other `Configs/*.lua` files, so `addon.GUI.tabPanels.X` doesn't exist yet at TABS-table construction time — the wrapper defers the lookup until the tab is actually clicked.

A module is only initialized when `addon.db[modKey]["Enabled"] == true`. Toggling the checkbox in the config panel calls
`addon.core:LoadModule(modKey)` (if not loaded yet) or shows the "Reload needed" dialog (if disabling an already-loaded module).

## `addon.core` (Core/Initialize.lua + sub-handlers) — Module/Event/DB Facade

`addon.core` is a thin facade: `Core/Initialize.lua` owns `Core:Initialize()`/`Core:Configure()` (the addon bootstrap) and
forwards every other `addon.core:<method>(...)` call to whichever sub-handler actually implements it
(`addon.core.ModuleHandler`, `addon.core.EventsHandler`, or `addon.core.DBHandler`), so callers never need to know which
handler owns a given method — `addon.core:RegisterModule(...)`, `addon.core:RegisterEvent(...)`,
`addon.core:RegisterDBDefaults(...)` etc. all work directly off `addon.core`.

| Method | Owner | Purpose |
|---|---|---|
| `RegisterModule(mod, name, initializeFunc)` | ModuleHandler | Register a module (not yet initialized). `name` is the localized display name, retrievable via `GetModuleName`. |
| `LoadModule(mod)` | ModuleHandler | Initialize + `RegisterEvents()` a module if `Enabled`. Safe to call multiple times (no-op if already loaded). |
| `LoadAllModules()` | ModuleHandler | Calls `LoadModule` for every registered module (used at startup). |
| `HasModuleLoaded(mod)` | ModuleHandler | `boolean` |
| `GetModule(mod)` | ModuleHandler | Returns the live module instance table, or `nil`. |
| `GetModuleName(mod)` | ModuleHandler | Returns the localized display name passed to `RegisterModule`. |
| `GetModuleList()` | ModuleHandler | Returns an array of all registered module keys (loaded or not). |
| `GetLoadedModulesList(useKey?)` / `GetUnloadedModulesList(useKey?)` | ModuleHandler | Returns `(list, count)` of loaded/unloaded modules. |
| `ToggleModule(mod, on)` | ModuleHandler | Loads or unloads a module and handles test-mode/reload-popup side effects. |
| `TestMode(on?)` | ModuleHandler | Toggle/set global test mode (`addon.testMode`); calls `:Test(on)` on every loaded module. |
| `TestModule(mod)` | ModuleHandler | Toggle test mode for a single module only. |
| `IsTestOn()` | ModuleHandler | `boolean` |
| `GetSafeUpdate(mod)` | ModuleHandler | Returns a no-throw `function()` that calls `module:UpdateStyle()` if the module is loaded and implements it — use this from config panel callbacks. |
| `RegisterEvent(event, frame, mod, unit?)` | EventsHandler | Registers a WoW event on `frame` (supports unit events via `unit`). |
| `UnregisterEvent(event, frame, mod)` | EventsHandler | Unregisters a previously-registered event. |
| `RegisterState(event, unit, name, initialValue, updateFunc)` | EventsHandler | Declare a derived "addon state" (`addon.states[name]`), recomputed from `updateFunc(...)` whenever `event` fires. |
| `RegisterStateMonitor(stateName, moduleName, monitorFunc)` / `UnregisterStateMonitor(stateName, moduleName)` | EventsHandler | Get notified (with the delta) whenever a registered state changes. |
| `RegisterDBDefaults(mod, defaults)` | DBHandler | Register default values for a module's `addon.db[mod]`; call once from `Configs/<Name>.lua`. |
| `ValidateModuleDatabase(mod, resetValues?)` | DBHandler | Validates (or, if `resetValues`, force-resets) `addon.db[mod]` against its registered defaults — this is what `GUI:CreateResetModButton` calls to reset a module. |
| `ValidateDatabase()` | DBHandler | Validates the whole saved-variable DB and all registered modules' defaults; called once from `Core:Initialize()`. |
| `ShowReloadPopup()` | Utility (forwarded) | Shows the "reload needed" popup. |

Existing addon states (see `Modules/FocusInterrupt.lua` for `RegisterStateMonitor` calls): `interfaceNumber`, `playerClass`, `playerSpec`.
These are set up once in `EventsHandler:InitializeStates()`, called from `Core:Initialize()`. Unlike `HBLyx_Tools`, there is no
`inCombat`/`encounterInfo`/`instanceInfo` state here since no module needs them.

## `addon.Utility` (Core/Utility.lua) — Shared Helpers

- `ShowEditFrame(frame, dbTable, xKey, yKey, anchorFrom, label, modKey, updateFunc)` / `HideEditFrame(frame)`
  Drag-to-reposition overlay used during test mode. Persists position into `dbTable[xKey]`/`dbTable[yKey]`.
  **Left-click+drag** moves the frame; **right-click** opens the GUI directly to `modKey`'s tab (`addon.GUI:OpenModuleGUI(modKey)`).
- `SetPopupDialog(dialogName, text, show?, extraFields?)` — registers/shows a `StaticPopupDialogs` entry.
- `print(msg)` / `addon:debug(msg, callback?)` — addon-prefixed chat output.
- To reset a module's saved settings back to defaults, use `addon.core:ValidateModuleDatabase(mod, true)` (owned by `DBHandler`, not `Utility`).
- `GetGrowAnchors(direction)`, anchor/color/hex conversion helpers, `SoundChannels`, `FrameStrata`, `Anchors`, `Grows` enums.
- `RaidMarkers[1..8]` — `{rt%d}` icon markup.

## `addon.GUI` (Configs/GUIUtility.lua + Configs/General.lua) — Config Window

`addon.GUI` is also split: `Configs/GUIUtility.lua` declares the `addon.GUI` table and its `Create*` widget factories;
`Configs/General.lua` (loaded right after) adds the config-window architecture below. Both load before every other
`Configs/<Name>.lua` panel, per the `.toc`'s script order.

- `OpenGUI()` / `CloseGUI()` / `Render()` — show/hide/build the config window.
- `OpenModuleGUI(module)` — open the GUI and jump straight to a module's tab (used by right-click on an editFrame).
- `SelectTab(module)` — select a tab by module key (looked up via `MOD_INDEX`, built from `TABS[i].module`).
- `RegisterModule(modKey, renderFunction)` — called from each `Configs/<Name>.lua` to register its `RenderPanel` under `addon.GUI.tabPanels[modKey]`.
- Widget factories (all take a `parent` container first, return the widget so it can be reused/disabled later):
  `CreateInlineGroup`, `CreateHeader`, `CreateSeperator`, `CreateLinebreaker`, `CreateInformationTag`,
  `CreateToggleCheckBox`, `CreateButton`, `CreateResetModButton`, `CreateSlider`, `CreateEditBox`, `CreateMultiLineEditBox`,
  `CreateDropdown`, `CreateColorPicker`, `CreateFontSelect`, `CreateTextureSelect`, `CreateSoundSelect`,
  `CreateFrameStrataDropdown`, `CreateMultiDropdown`, `CreateSpecSelectDropdown`, `CreateScrollFrame` (no-op, panels are already scrollable).

### `TABS` entry shape (Configs/General.lua)
```lua
{text = string, type = "Button"|"Text", module = string?, tooltip = string?, panelFunction = function(container) -> frame}
```
`type = "Text"` entries are section headers (no panel). `module` is optional — only set it if the tab maps to a real
`addon.core` module key (used by `SelectTab`/`OpenModuleGUI`/right-click-to-open).

## Adding a New Module — Checklist

1. Copy `TemplateModule.lua` → `Modules/<Name>.lua`, set `modName`, implement `Initialize`/`RegisterEvents`/`UpdateStyle`/`Test`.
2. Add locale strings to `Locales/enUS.lua` (at least `<Name>Settings`, and `<Name>SettingsDesc` for the tab tooltip).
3. Create `Configs/<Name>.lua`: call `addon.core:RegisterDBDefaults(MOD_KEY, { Enabled = true, ... })`, write `RenderPanel(parent)`, call `GUI:RegisterModule(MOD_KEY, RenderPanel)`.
4. Add the module file path to `MidnightFocusInterrupt.toc` under `# modules`, and the config file path under `# handle configuration and options`.
5. Add a `TABS` entry in `Configs/General.lua` with `module = "<Name>"`.
6. If the module has a draggable on-screen frame, call `addon.Utility:ShowEditFrame(...)` / `HideEditFrame(...)` from `Test(on)`.

## Sibling Addons (same author, same architecture)

`HBLyx_Tools` and `HBLyx_Encounter_Sound` share this exact same `Core/` + `GUIUtility.lua`/`General.lua` design
(module registry, `RenderPanel` + `GUI:RegisterModule` config panels, `TABS` with `module` keys). `HBLyx_Encounter_Sound`
may still use the older, pre-refactor single-file `core.lua`/`utilities.lua`/`GUI.lua` layout — check before assuming parity.
When changing this architecture, mirror the change in those addons too for consistency.
