# HBLyx GUI

A small, self contained widget library used to build the configuration UI of **HBLyx_Tools**.
It replaces AceGUI-3.0 for the addon's own panels while keeping a similar mental model: build widgets, put them into a container, release them back when the panel closes.

> This is not a general purpose WoW GUI library. It is intentionally opinionated: a fixed dark backdrop with a white border, a row based layout, and a per widget type frame pool.

## Files

| File | Purpose |
| --- | --- |
| `gui.xml` | Load order for the library, referenced by the `.toc` |
| `UICore.lua` | Widget registry, frame pools, shared backdrop/color helpers, hover helper, color cycle, row layout math |
| `ScrollFrame.lua` | Scrollable container |
| `Window.lua` | Plain (non scrolling) container with a title |
| `VerticalTabGroup.lua` | Sidebar of tab buttons next to a content area, with an optional title window above the sidebar |
| `TextButton.lua` | Clickable button with a centered label |
| `ToggleBox.lua` | Check box with a label on the right |
| `Slider.lua` | Labelled slider with a value edit box |
| `EditBox.lua` | Labelled text input with an accept button |
| `MultiLineEditBox.lua` | Labelled, scrollable multi line input with an accept button |
| `ColorPickerPopup.lua` | The single shared color picker panel (saturation/value pad, hue and alpha bars, hex and opacity inputs), created once and reached through `UICore:GetColorPicker()` |
| `ColorPicker.lua` | Labelled color swatch which opens the color picker popup |
| `Dropdown.lua` | Labelled selection button with a pullout list |
| `MultiDropdown.lua` | Dropdown variant with a set of selected keys |
| `MediaDropdown.lua` | LibSharedMedia dropdowns: font, status bar texture and sound |
| `TextRegion.lua` | Full width, auto height wrapped text |
| `InfoContainer.lua` | Read-only bordered label and content lines loaded by a callback, with a tooltip |
| `LineSeperator.lua` | Full width horizontal line which separates groups |


## Core concepts

### Widget contract

Every widget is a Lua table (not a frame) that owns a `frame`. A widget class implements:

| Method | Meaning |
| --- | --- |
| `Create(parent, ...)` | Builds and returns a **new** instance (`setmetatable({}, { __index = Class })`) |
| `Reuse(parent, ...)` | Resets an instance taken from the pool |
| `Release()` | Resets the instance to its default state before it goes back to the pool |
| `SetParent`, `SetPoint`, `SetPosition`, `SetSize`, `GetWidth`, `GetHeight`, `Show`, `Hide` | Layout surface used by the containers |

Frames keep a back reference in `frame.obj`, so shared script handlers can reach the widget.

### Frame pools

`UICore` keeps one pool per widget type. Releasing a widget resets it and pushes it onto the pool of its own type, building fetches from that pool first.

```lua
addon.UICore:RegisterWidget(MyWidget)   -- called at the bottom of every widget file
local widget = addon.UICore:Build("Slider")
addon.UICore:ReleaseToPool(widget)
```

There is deliberately no single global pool: widgets nest several frames with different invariants, so a shared pool would need to unwind all of them.

### Row based layout

Containers place widgets left to right and wrap to a new row when the next widget does not fit.
`UICore:ComputeContentPosition(container, widget)` returns the position for a widget and advances the container cursor (`contentX`, `contentY`, `rowMaxHeight`) with an 8px spacing.

Containers expose:

- `AddWidget(widget)` — parent, position, show and track the widget
- `NewRow()` — force a line break even when the current row still has room
- `GetContentPosition()` — the cursor, used by `UICore`
- `GetWidth()` — the **usable** width for children (insets and scroll bar excluded)

### Re-render

Containers can remember how their content is built, which makes tab-like panels cheap:

```lua
scrollFrame:SetRenderer(function(container)
    local button = addon.UICore:Build("TextButton")
    button:SetText("Hello")
    container:AddWidget(button)
end)

scrollFrame:Rerender()   -- recycles the current content, then replays the renderer
```

| Method | Effect |
| --- | --- |
| `SetRenderer(fn)` | Stores the function that fills the container |
| `ReleaseChildren()` | Sends every child back to its pool and resets the layout cursor |
| `Rerender()` | `ReleaseChildren()` followed by the renderer |
| `Release()` | `ReleaseChildren()`, drops the renderer and hides the container |

Because a re-render recycles the widget that may be running its own click handler, trigger it from a deferred point (the demo raises a flag and handles it in `OnUpdate`).

## Containers

### ScrollFrame

Scrollable container with a scroll bar styled like the `Slider` widget. The bar hides itself when the content fits and the mouse wheel scrolls the content.

```lua
local scrollFrame = addon.UICore:Build("ScrollFrame")
scrollFrame:SetParent(panel)
scrollFrame:SetSize(400, 300)
scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -40)
scrollFrame:SetRenderer(Populate)
scrollFrame:Rerender()
scrollFrame:Show()
```

`SetTitle`, `SetSize(width, height)`, `AddWidget`, `NewRow`, `SetRenderer`, `Rerender`, `ReleaseChildren`, `Release`.

### Window

Same layout logic without scrolling: backdrop, border and a content container. No title, no close button.

```lua
local window = addon.UICore:Build("Window")
window:SetParent(UIParent)
window:SetSize(180, 190)
window:SetPoint("TOPRIGHT", scrollFrame.frame, "TOPLEFT", -16, 0)
window:SetRenderer(PopulateTabs)
window:Rerender()
window:Show()
```

Note that `SetPoint` takes a **frame** as `relativeTo`, so pass `otherWidget.frame`.

### VerticalTabGroup

A scrolling sidebar of tab buttons and section titles on the left, and the panel of the selected tab on the right. The panel is rendered on demand each time a tab is selected: `SelectTab` recycles the previous panel (its `ScrollFrame` and all the widgets in it go back to their pools) and builds the new one, so callback driven widgets such as `InfoContainer` always load fresh information. Scroll position and uncommitted widget state are not kept across tab switches.

```lua
local tabGroup = addon.UICore:Build("VerticalTabGroup")
tabGroup:SetParent(root)
tabGroup:SetSidebarWidth(200)
tabGroup:SetTitle({ icon = "Interface\\AddOns\\MyAddon\\icon.png", title = "MyAddon", subtitle = "v1.0", height = 30 })
tabGroup:SetContentTopInset(30)   -- e.g. a toolbar drawn above the content area
tabGroup:SetSize(1055, 630)
tabGroup:SetTabs({
    { text = "Section", type = "Text" },
    { text = "General", type = "Button", panelFunction = function(container) end },
})
tabGroup:Show()
```

| Method | Effect |
| --- | --- |
| `SetSidebarWidth(width)` | Width of the sidebar, defaults to 155 |
| `SetContentTopInset(inset)` | Space reserved above the content area |
| `SetTitle(info)` | Builds or updates the title window above the sidebar, `nil` removes it |
| `SetTabs(list, defaultIndex)` | Fills the sidebar, `Button` rows are selectable and `Text` rows are section titles |
| `SelectTab(index)` | Recycles the previous panel and renders the panel of a tab |
| `SetOnTabSelected(fn)` | Callback `fn(info, index)` after a tab was selected |
| `ClearTabs()` | Recycles the current panel and hides the sidebar rows |

#### Title window

`SetTitle` takes `{ icon, title, subtitle, height }`. It builds a `Window` right above the sidebar once, only when a title is needed, holding an icon of full height and two game `FontString`s on its right: the first line is the title, the second is the subtitle. Calling it again only updates the icon and the texts. `SetTitle()` (or `Release`) removes the window.

The sidebar is shortened by the title height, so the title window plus the sidebar always add up to the height of the group. This lines up with the content area, which is shortened by `SetContentTopInset`. The window is exposed as `tabGroup.titleWindow`, for example to add a drag handle.

## Widgets

### TextButton

```lua
local button = addon.UICore:Build("TextButton")
button:SetSize(120, 22)
button:SetText("Rebuild")
button:SetOnClick(function(widget) end)
```

`SetText`, `SetFontSize`, `SetColor`, `SetOnClick`, `SetOnEnter`, `SetOnLeave`. The button highlights on hover, like every other clickable control.

### ToggleBox

A square check box with the label on its right. `GetWidth()` covers box plus label.

```lua
local toggle = addon.UICore:Build("ToggleBox")
toggle:SetSize(160, 20)
toggle:SetText("Enable feature")
toggle:SetValue(true)
toggle:SetOnClick(function(widget, value) end)
```

`SetText`, `SetValue`, `GetValue`, `SetFontSize`, `SetOnClick`, `SetOnEnter`, `SetOnLeave`.

### Slider

Label on top, bar below, value edit box on the right, min and max captions under the bar. Values are snapped to the step, the mouse wheel steps the bar and the edit box commits on enter.

```lua
local slider = addon.UICore:Build("Slider")
slider:SetSize(200, 40)
slider:SetLabel("Scale")
slider:SetMinMaxValues(0.5, 2, 0.05)
slider:SetValue(1)
slider:SetOnValueChanged(function(widget, value) end)
```

`SetLabel`, `SetMinMaxValues(min, max, step)`, `SetValue`, `GetValue`, `SetOnValueChanged`, `SetOnEnter`, `SetOnLeave`.

### EditBox

Label on top, input below. The accept button only appears while the text differs from the committed value; enter commits, escape reverts.

```lua
local editBox = addon.UICore:Build("EditBox")
editBox:SetSize(200, 38)
editBox:SetLabel("Player name")
editBox:SetMaxLetters(24)
editBox:SetText("HBLyx")
editBox:SetOnEnterPressed(function(widget, text) end)
```

`SetLabel`, `SetText`, `GetText`, `SetMaxLetters`, `SetDisabled`, `SetOnEnterPressed`, `SetOnTextChanged`, `SetOnEnter`, `SetOnLeave`.

### MultiLineEditBox

Label on top, a scrollable multi line input below and an accept button under it, which only shows up while the text is dirty. Used for the profile export and import boxes.

```lua
local box = addon.UICore:Build("MultiLineEditBox")
box:SetSize(400, 120)
box:SetLabel("Export / import")
box:SetText(addon:ExportProfile())
box:SetOnEnterPressed(function(widget, text) addon:ImportProfile(text) end)
```

`SetLabel`, `SetText`, `GetText`, `HighlightText`, `SetDisabled`, `SetOnEnterPressed`, `SetOnTextChanged`, `SetOnEnter`, `SetOnLeave`.

### ColorPicker

A small bordered color swatch on the left with the label beside it, matching the layout of `ToggleBox`. Clicking the swatch borrows the shared panel from `UICore:GetColorPicker()` (see below), with alpha when `SetHasAlpha(true)` is set. The panel calls back on every change, restores the starting color on cancel, close, Escape or a click outside, and keeps no recent or favorite colors.

Any widget can use the shared panel directly. Opening it for another caller closes the previous session without reverting it:

```lua
addon.UICore:GetColorPicker():Open({
    r = 1, g = 0, b = 0, a = 1,
    hasAlpha = true,
    onChange = function(r, g, b, a) end,   -- every change, and the starting color on cancel
    onClose = function() end,              -- optional, once the panel is hidden
}, anchorFrame)
```

The hex helpers match how colors are stored in the database.

```lua
local color = addon.UICore:Build("ColorPicker")
color:SetLabel("In combat color")
color:SetHasAlpha(true)
color:SetHexColor(addon.db.CombatIndicator.InCombatColor)
color:SetOnColorChanged(function(widget)
    addon.db.CombatIndicator.InCombatColor = widget:GetHexColor()
end)
```

`SetLabel`, `SetColor(r, g, b, a)`, `GetColor`, `SetHexColor`, `GetHexColor`, `SetHasAlpha`, `SetDisabled`, `SetOnColorChanged`, `SetOnEnter`, `SetOnLeave`.

#### Shared color picker panel

The panel is not a pooled widget: `ColorPickerPopup.lua` builds one fixed panel when the GUI loads and `UICore:GetColorPicker()` returns it. `Open` loads the caller's color and callbacks, anchors the panel next to the given frame and shows it.

- Controls: saturation/value pad with a crosshair cursor, hue bar, alpha bar and Opacity input (only with `hasAlpha`), Hex# input, New and Prev previews (clicking Prev restores the starting color), OK and Cancel.
- The right column always reserves the Opacity space, so the layout does not shift between alpha and non alpha pickers.
- The row of preset color buttons at the bottom is driven by `PRESET_COLORS` in `ColorPickerPopup.lua` (`{r, g, b}`, 0 to 1): black, Priest white and the other class colors. The buttons are squares sized to the popup width.
- It closes through OK, Cancel, the close button, Escape inside an input, or a click outside it. Everything except OK restores the starting color.

### Dropdown

Label on top, selection button below. The pullout is parented to `UIParent` at `FULLSCREEN_DIALOG` strata, scrolls with the mouse wheel past 12 entries and closes when clicking outside.

```lua
local dropdown = addon.UICore:Build("Dropdown")
dropdown:SetSize(200, 38)
dropdown:SetLabel("Role")
dropdown:SetPlaceholder("Select a role")
dropdown:SetList({ tank = "Tank", healer = "Healer" }, { "tank", "healer" })
dropdown:SetValue("healer")
dropdown:SetOnValueChanged(function(widget, key) end)
```

`SetLabel`, `SetList(list, order)`, `SetValue`, `GetValue`, `SetPlaceholder`, `Open`, `Close`, `SetOnValueChanged`, `SetOnEnter`, `SetOnLeave`.

The `order` table is optional, the keys are sorted when it is omitted.

`Dropdown` is the base of the dropdown variants below. A variant overrides the hooks `OnItemCreated`, `FormatItem`, `IsSelected`, `GetDisplayText`, `OnItemClick` and `GetVisibleOrder`, and calls `Refresh()` when its selection changes. `SetSearchEnabled(true)` adds a filter box on top of the pullout.

### MultiDropdown

A dropdown which holds a set of keys. Items show a check box, the pullout stays open while toggling, and the button lists the selected entries.

```lua
local roles = addon.UICore:Build("MultiDropdown")
roles:SetList(list, order)
roles:SetSelectedKeys({ tank = true })
roles:SetOnValueChanged(function(widget, key, checked) end)

local selected = roles:GetSelectedKeys() -- a set, or nil when nothing is selected
```

Adds `GetSelectedKeys`, `SetSelectedKeys(keys)`, `ClearSelections`. `SetValue` accepts a single key or a set.

### FontDropdown, TextureDropdown, SoundDropdown

LibSharedMedia backed dropdowns, all three fill their own list and enable the search box.

| Widget | Media type | Preview |
| --- | --- | --- |
| `FontDropdown` | `font` | each entry is rendered with its own font |
| `TextureDropdown` | `statusbar` | each entry shows the status bar texture |
| `SoundDropdown` | `sound` | a speaker on every entry, and on the button, plays it |

```lua
local font = addon.UICore:Build("FontDropdown")
font:SetLabel("Font")
font:SetValue(addon.db.font)
font:SetOnValueChanged(function(widget, key) addon.db.font = key end)
```

The list is refreshed on build and on re-use, so media registered by other addons after login is picked up.

### TextRegion

Takes the full width of its container and grows as tall as the wrapped text needs, so it always occupies its own row. Icons are not a widget feature, use the game's inline texture escape inside the text. Giving it an `SetOnClick` callback turns it into an interactive label.

```lua
local text = addon.UICore:Build("TextRegion")
text:SetFontSize(14)
text:SetText("|TInterface\\Icons\\INV_Misc_QuestionMark:16:16|t A long description that wraps over several lines.")

local link = addon.UICore:Build("TextRegion")
link:SetText("|cff8080FFCurseForge|r")
link:SetOnClick(function() addon.Utilities:OpenURL("CurseForge", url) end)
```

`SetText`, `GetText`, `SetFontSize`, `SetColor`, `SetJustifyH`, `SetJustifyV`, `SetWidth`, `SetOnClick`, `SetOnEnter`, `SetOnLeave`.

### LineSeperator

A horizontal line used to separate groups of settings. The frame height is the room around the line, the line keeps its own thickness.

```lua
local line = addon.UICore:Build("LineSeperator")
line:SetFullWidth(true)
container:AddWidget(line)
```

`SetColor`, `SetThickness`, `SetSize`.

### InfoContainer

A read-only, bordered two line widget: the first line is the label, the second is the content. It has the standard width (200) and a fixed height, so there is `SetWidth` but no `SetHeight`/`SetSize`. The height follows the font size, change both with `SetFontSize`. Text is single line and cut off at the width.

The text comes from a callback which returns `label, content, tooltip` (any of them may be `nil` to keep the current value). The callback runs when the widget is built or re-used from the pool, and the tooltip is shown on hover, anchored to the cursor.

```lua
GUI:CreateInfoContainer(container, function()
    local modules, count = addon.core:GetLoadedModulesList()
    return L["LoadedModules"], tostring(count), table.concat(modules, ", ")
end)
```

`SetCallback` (stores and runs it), `Refresh`, `SetLabel`, `SetContent`, `GetContent`, `SetTooltip`, `SetFontSize`, `SetWidth`.

## Shared behavior

`SetDisabled(true)` greys out and blocks the control. It is available on `TextButton`, `ToggleBox`, `Slider`, `EditBox`, `MultiLineEditBox`, `ColorPicker` and every dropdown, which is what the config panels use to follow an enable toggle.

`UICore:SetTooltip(widget, text, anchor)` wires the hover callbacks of any widget to a `GameTooltip`.

Backdrop and text colors are centralized in `UICore` instead of being duplicated per widget file:

| Method | Returns |
| --- | --- |
| `GetDefaultBackdrop()` | the shared backdrop shape (background + border texture) |
| `SetBackdropColor(frame, color?)` | applies `color` or the shared background color to a backdrop frame |
| `SetBorderColor(frame, color?)` | applies `color` or the shared border color to a backdrop frame |
| `GetHighlightColor()` | the shared selection/highlight color |
| `GetNormalTextColor()` | the shared enabled text color |
| `GetDisabledTextColor()` | the shared disabled text color |

```lua
frame:SetBackdrop(addon.UICore:GetDefaultBackdrop())
addon.UICore:SetBackdropColor(frame)   -- or SetBackdropColor(frame, {0, 0, 0, 0.9}) to override
addon.UICore:SetBorderColor(frame)
```

## Adding a new widget
1. Create `GUI/MyWidget.lua` with a class table that has a `type` field.
2. Implement `Create`, `Reuse`, `Release` and the layout surface listed above.
3. Return a fresh instance from `Create`, and set `frame.obj = widget` so the shared handlers can find it.
4. Call `addon.UICore:RegisterWidget(MyWidget)` at the bottom of the file.
5. Add the file to `gui.xml`.

Store callbacks on the widget (`self.onClick`, `self.onValueChanged`, ...) instead of replacing the frame scripts, so the internal behavior of the widget is not lost, and clear them in `Release`.

## Styling

| Element | Value |
| --- | --- |
| Background | `Interface\Buttons\WHITE8x8`, black at 50% (containers 80%) |
| Border | `UICore:GetDefaultBackdrop()`/`SetBorderColor`, 1px |
| Font | `Fonts\FRIZQT__.TTF`, 12 outline (titles 16 to 20) |
| Hover | `UICore:BuildHover(frame)`, additive white at 25% |
| Spacing | 8px between widgets and rows, 6px container inset |

`UICore:GetNextColorCycle()` and `UICore:ResetColorCycle()` provide a fixed, readable color cycle for content that needs to be visually grouped.

## Changelog

### 2026-10-27
- Replaced the Blizzard `ColorPickerFrame` with a custom color picker: new `ColorPickerPopup.lua`, loaded before `ColorPicker.lua` in `gui.xml`.
- The picker is one fixed panel created once with the GUI and shared through `UICore:GetColorPicker()`. Widgets call `Open(info, anchor)` to borrow it. It is not part of the frame pools.
- `ColorPicker` now opens the shared panel; its public API is unchanged.
- Layout: saturation/value pad, hue bar, optional alpha bar, New/Prev previews, Hex# and Opacity inputs, OK and Cancel. The Opacity space is always reserved on the right and the controls sit closer to the title bar.
- Added a bottom row of preset color buttons (`PRESET_COLORS`: black, Priest white and the other class colors).
- The pad cursor is a four line crosshair, as in EllesmereUI.
- Clicking outside the picker cancels it, as in EllesmereUI. It keeps no recent or favorite colors.
