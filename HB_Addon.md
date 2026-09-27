# HBLyx_Tools — Architecture & API Reference

This file is a fast-loading reference for AI assistants and developers extending this addon.
It documents the module lifecycle, the public APIs (`addon.core`, `addon.Utilities`, `addon.GUI`),
and the exact steps to add a new module + config panel.

`addon` = the addon-private table (second vararg of `local ADDON_NAME, addon = ...`), shared by every file via `embeds.xml`/`.toc` load order.

## File Layout

```
HBLyx_Tools.toc      -- load order: Locales -> utilities -> configure -> core -> data -> GUI\gui.xml
                      -- -> Modules\*.lua -> GUI.lua -> Configs\*.lua -> main.lua
main.lua              -- AceAddon bootstrap, profile/db init (ProfileHandler), minimap icon (LDB)
configure.lua         -- addon.configurationList / addon.optionsList setup, LSM registration, locale font defaults
core.lua              -- addon.core: module registry, event registry, state system, test mode
utilities.lua         -- addon.Utilities: helpers, drag-to-move editFrame, popups, string/color/sound utils
data.lua              -- static data tables (spell/instance lookups etc., addon-specific)
GUI.lua               -- addon.GUI: config window, tab system, widget factories
TemplateModule.lua    -- copy-paste starting point for a new module (NOT loaded by the .toc)
Modules/<Name>.lua    -- module logic/behavior (one file per feature)
Configs/<Name>.lua    -- module's config panel (RenderPanel) + default settings (addon.configurationList)
Locales/*.lua         -- AceLocale-3.0 string tables (enUS.lua is canonical, others are translations)
GUI/*.lua             -- low level widget implementations (Slider, Dropdown, ToggleBox, etc.) built via addon.UICore
```

Modules and Configs are **paired by module key** (a string, e.g. `"FocusInterrupt"`), which is used as:
- `addon.db[modKey]` — the saved-variable table for that module's settings
- `addon.configurationList[modKey]` — default values, merged into `addon.db[modKey]` on load/reset
- the key in `addon.core.registeredMods` / `addon.core.modules`
- the key in `addon.GUI.tabPanels`
- the `module` field of a `TABS` entry in `GUI.lua`

## Module Lifecycle

1. `Modules/<Name>.lua` defines a table `local X = { modName = "X", ... }` with methods:
   - `X:Initialize()` → returns `self` (or `nil` to abort, e.g. wrong class). Called lazily, only once, when the module becomes enabled.
   - `X:RegisterEvents()` → optional. Called right after a successful `Initialize()`. Register WoW events / state monitors here.
   - `X:UpdateStyle()` → optional. Called whenever settings change (via `GetSafeUpdate`) and on `PLAYER_ENTERING_WORLD`.
   - `X:Test(on)` → optional. Toggle a visual preview; called by `Core:TestMode()` / `Core:TestModule()`.
   - Ends with: `addon.core:RegisterModule(X.modName, L["XSettings"], function() return X:Initialize() end)`
2. `Configs/<Name>.lua` defines:
   - `addon.configurationList[MOD_KEY] = { Enabled = true, ... }` (defaults)
   - `local function RenderPanel(parent) ... return frame end` — builds the config UI using `GUI:Create*` widget factories
   - Ends with: `GUI:RegisterModule(MOD_KEY, RenderPanel)`
3. `GUI.lua`'s `TABS` table adds one entry per module:
   ```lua
   {text = addon.core:GetModuleName("X"), type = "Button", module = "X", tooltip = L["XSettingsDesc"],
    panelFunction = function(container) return addon.GUI.tabPanels.X(container) end},
   ```
   The `function(container) return addon.GUI.tabPanels.X(container) end` wrapper is required (not a direct reference) because
   `GUI.lua` loads **before** `Configs/*.lua`, so `addon.GUI.tabPanels.X` doesn't exist yet at TABS-table construction time — the wrapper defers the lookup until the tab is actually clicked.

A module is only initialized when `addon.db[modKey]["Enabled"] == true`. Toggling the checkbox in the config panel calls
`addon.core:LoadModule(modKey)` (if not loaded yet) or shows the "Reload needed" dialog (if disabling an already-loaded module).

## `addon.core` (core.lua) — Module/Event/State Manager

| Method | Purpose |
|---|---|
| `RegisterModule(mod, name, initializeFunc)` | Register a module (not yet initialized). `name` is the localized display name, retrievable via `GetModuleName`. |
| `LoadModule(mod)` | Initialize + `RegisterEvents()` a module if `Enabled`. Safe to call multiple times (no-op if already loaded). |
| `LoadAllModules()` | Calls `LoadModule` for every registered module (used at startup). |
| `HasModuleLoaded(mod)` | `boolean` |
| `GetModule(mod)` | Returns the live module instance table, or `nil`. |
| `GetModuleName(mod)` | Returns the localized display name passed to `RegisterModule`. |
| `GetModuleList()` | Returns an array of all registered module keys (loaded or not). |
| `RegisterEvent(event, frame, mod, unit?)` | Registers a WoW event on `frame` (supports unit events via `unit`). |
| `RegisterState(event, unit, name, updateFunc)` | Declare a derived "addon state" (`addon.states[name]`), recomputed from `updateFunc(...)` whenever `event` fires. |
| `RegisterStateMonitor(stateName, moduleName, monitorFunc)` | Get notified (with the delta) whenever a registered state changes. |
| `TestMode(on?)` | Toggle/set global test mode; calls `:Test(on)` on every loaded module. |
| `TestModule(mod)` | Toggle test mode for a single module only. |
| `IsTestOn()` | `boolean` |
| `GetSafeUpdate(mod)` | Returns a no-throw `function()` that calls `module:UpdateStyle()` if the module is loaded and implements it — use this from config panel callbacks. |

Common existing addon states (see `Modules/*.lua` for `RegisterState` calls): `inCombat`, `instanceInfo`, `encounterInfo`, `playerSpec`, `playerClass`.

## `addon.Utilities` (utilities.lua) — Shared Helpers

- `ShowEditFrame(frame, dbTable, xKey, yKey, anchorFrom, label, modKey, updateFunc)` / `HideEditFrame(frame)`
  Drag-to-reposition overlay used during test mode. Persists position into `dbTable[xKey]`/`dbTable[yKey]`.
  **Left-click+drag** moves the frame; **right-click** opens the GUI directly to `modKey`'s tab (`addon.GUI:OpenModuleGUI(modKey)`).
- `SetPopupDialog(dialogName, text, show?, extraFields?)` — registers/shows a `StaticPopupDialogs` entry.
- `print(msg)` / `debug(msg, callback?)` — addon-prefixed chat output.
- `ResetModule(mod)` — resets `addon.db[mod]` back to `addon.configurationList[mod]` defaults.
- `GetGrowAnchors(direction)`, anchor/color/hex conversion helpers, `SoundChannels`, `FrameStrata`, `Anchors`, `Grows` enums.
- `RaidMarkers[1..8]` — `{rt%d}` icon markup.

## `addon.GUI` (GUI.lua) — Config Window

- `OpenGUI()` / `CloseGUI()` / `Render()` — show/hide/build the config window.
- `OpenModuleGUI(module)` — open the GUI and jump straight to a module's tab (used by right-click on an editFrame).
- `SelectTab(module)` — select a tab by module key (looked up via `MOD_INDEX`, built from `TABS[i].module`).
- `RegisterModule(modKey, renderFunction)` — called from each `Configs/<Name>.lua` to register its `RenderPanel` under `addon.GUI.tabPanels[modKey]`.
- Widget factories (all take a `parent` container first, return the widget so it can be reused/disabled later):
  `CreateInlineGroup`, `CreateHeader`, `CreateSeperator`, `CreateLinebreaker`, `CreateInformationTag`,
  `CreateToggleCheckBox`, `CreateButton`, `CreateResetModButton`, `CreateSlider`, `CreateEditBox`, `CreateMultiLineEditBox`,
  `CreateDropdown`, `CreateColorPicker`, `CreateFontSelect`, `CreateTextureSelect`, `CreateSoundSelect`,
  `CreateFrameStrataDropdown`, `CreateMultiDropdown`, `CreateSpecSelectDropdown`, `CreateScrollFrame` (no-op, panels are already scrollable).

### `TABS` entry shape (GUI.lua)
```lua
{text = string, type = "Button"|"Text", module = string?, tooltip = string?, panelFunction = function(container) -> frame}
```
`type = "Text"` entries are section headers (no panel). `module` is optional — only set it if the tab maps to a real
`addon.core` module key (used by `SelectTab`/`OpenModuleGUI`/right-click-to-open).

## Adding a New Module — Checklist

1. Copy `TemplateModule.lua` → `Modules/<Name>.lua`, set `modName`, implement `Initialize`/`RegisterEvents`/`UpdateStyle`/`Test`.
2. Add locale strings to `Locales/enUS.lua` (at least `<Name>Settings`, and `<Name>SettingsDesc` for the tab tooltip).
3. Create `Configs/<Name>.lua`: set `addon.configurationList[MOD_KEY]`, write `RenderPanel(parent)`, call `GUI:RegisterModule(MOD_KEY, RenderPanel)`.
4. Add the module file path to `HBLyx_Tools.toc` under `# modules` (before `GUI.lua`) and the config file path under `# handle configuration and options` (after `GUI.lua`).
5. Add a `TABS` entry in `GUI.lua` with `module = "<Name>"`.
6. If the module has a draggable on-screen frame, call `addon.Utilities:ShowEditFrame(...)` / `HideEditFrame(...)` from `Test(on)`.

## Sibling Addons (same author, same architecture)

`MidnightFocusInterrupt` and `HBLyx_Encounter_Sound` share this exact same `core.lua` / `utilities.lua` / `GUI.lua` design
(module registry, `RenderPanel` + `GUI:RegisterModule` config panels, `TABS` with `module` keys). When changing this
architecture, mirror the change in those addons too for consistency.
