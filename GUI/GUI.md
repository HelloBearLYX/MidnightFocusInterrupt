# HBLyx GUI

A small, self contained widget library used to build the configuration UI of **HBLyx_Tools**.
It replaces AceGUI-3.0 for the addon's own panels while keeping a similar mental model: build widgets, put them into a container, release them back when the panel closes.

> This is not a general purpose WoW GUI library. It is intentionally opinionated: a fixed dark backdrop with a white border, a row based layout, and a per widget type frame pool.

## Files

| File | Purpose |
| --- | --- |
| `gui.xml` | Load order for the library, referenced by the `.toc` |
| `UICore.lua` | Widget registry, frame pools, hover helper, color cycle, row layout math |
| `ScrollFrame.lua` | Scrollable container |
| `Window.lua` | Plain (non scrolling) container with a title |
| `TextButton.lua` | Clickable button with a centered label |
| `ToggleBox.lua` | Check box with a label on the right |
| `Slider.lua` | Labelled slider with a value edit box |
| `EditBox.lua` | Labelled text input with an accept button |
| `MultiLineEditBox.lua` | Labelled, scrollable multi line input with an accept button |
| `ColorPicker.lua` | Labelled color swatch which opens the game color picker |
| `Dropdown.lua` | Labelled selection button with a pullout list |
| `MultiDropdown.lua` | Dropdown variant with a set of selected keys |
| `MediaDropdown.lua` | LibSharedMedia dropdowns: font, status bar texture and sound |
| `TextRegion.lua` | Full width, auto height wrapped text |
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

Scrollable container with a title above the frame and a scroll bar styled like the `Slider` widget. The bar hides itself when the content fits and the mouse wheel scrolls the content.

```lua
local scrollFrame = addon.UICore:Build("ScrollFrame")
scrollFrame:SetParent(panel)
scrollFrame:SetSize(400, 300)
scrollFrame:SetTitle("Settings")
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

## Widgets

### TextButton

```lua
local button = addon.UICore:Build("TextButton")
button:SetSize(120, 22)
button:SetText("Rebuild")
button:SetOnClick(function(widget) end)
```

`SetText`, `SetFontSize`, `SetColor`, `SetOnClick`, `SetOnEnter`, `SetOnLeave`.

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

Label on top, a color swatch below. Clicking the swatch opens the game color picker, with alpha when `SetHasAlpha(true)` is set. The hex helpers match how colors are stored in the database.

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

## Shared behavior

`SetDisabled(true)` greys out and blocks the control. It is available on `TextButton`, `ToggleBox`, `Slider`, `EditBox`, `MultiLineEditBox`, `ColorPicker` and every dropdown, which is what the config panels use to follow an enable toggle.

`UICore:SetTooltip(widget, text, anchor)` wires the hover callbacks of any widget to a `GameTooltip`.

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
| Border | 1px gray, `0.4, 0.4, 0.4` |
| Font | `Fonts\FRIZQT__.TTF`, 12 outline (titles 16 to 20) |
| Hover | `UICore:BuildHover(frame)`, additive white at 25% |
| Spacing | 8px between widgets and rows, 6px container inset |

`UICore:GetNextColorCycle()` and `UICore:ResetColorCycle()` provide a fixed, readable color cycle for content that needs to be visually grouped.
