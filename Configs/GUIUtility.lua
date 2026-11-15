local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

---@class HB_GUI
---@field frame Frame? the movable root frame which holds every part of the configuration UI
---@field tabGroup table? the sidebar and content area which show the selected tab's panel
---@field isOpened boolean is the GUI opened
addon.GUI = {
    frame = nil,
    tabPanels = {},
    tabGroup = nil,
    isOpened = false,
}

local HIGHLIGHT_TEXT_COLOR = "|c" .. addon.Utility:RGBToHex(unpack(addon.UICore:GetHighlightColor()))

-- MARK: Widget factories
-- every factory adds the widget to the container when one is given, and returns the widget,
-- so the config panels can keep a reference and disable, resize or re-fill it later

local function Attach(container, widget)
    if container then
        container:AddWidget(widget)
    end
    return widget
end

---The config panels are laid out by the container itself, so a group is only a title
---@param parent table the container
---@param title string title
---@return table container the very same container
function addon.GUI:CreateInlineGroup(parent, title)
    if parent and title and title ~= "" then
        parent:NewRow()
        self:CreateHeader(parent, title)
    end

    return parent
end

---@param parent table the container
function addon.GUI:CreateLinebreaker(parent)
    if parent then parent:NewRow() end
end

---@param parent table the container
---@param mod string the module key, passed to ResetModule and the reload prompt
---@param modLocale string the localized module title shown in the confirmation dialog
---@return table widget
function addon.GUI:CreateResetModButton(parent, mod, modLocale)
    return self:CreateButton(parent, L["ResetMod"], function()
        addon.Utility:SetPopupDialog(
            ADDON_NAME .. "ResetMod",
            "|cffC41E3A" .. modLocale .. "|r: " .. L["ComfirmResetMod"],
            true,
            {button1 = YES, button2 = NO, OnButton1 = function()
                addon.core:ValidateModuleDatabase(mod, true)
                ReloadUI()
            end}
        )
    end)
end

---@param parent table the container
---@return table? widget
function addon.GUI:CreateSeperator(parent)
    if not parent then return end

    local line = addon.UICore:Build("LineSeperator")
    line:SetFullWidth(true)

    parent:AddWidget(line)
    parent:NewRow()

    return line
end

---@param parent table the container
---@return table container the container itself, the panels are already scrollable
function addon.GUI:CreateScrollFrame(parent)
    return parent
end

---@param parent table the container
---@param title string title
---@return table widget
function addon.GUI:CreateHeader(parent, title)
    -- a header always opens a new section, so it carries the separator
    self:CreateSeperator(parent)

    local header = addon.UICore:Build("TextRegion")
    header:SetFontSize(14)
    header:SetText(HIGHLIGHT_TEXT_COLOR .. (title or "") .. "|r")
    header:SetFullWidth(true)

    Attach(parent, header)
    if parent then parent:NewRow() end

    return header
end

---@param parent table the container
---@param description string the description to display
---@param textJustification string? "LEFT", "CENTER" or "RIGHT"
---@return table widget
function addon.GUI:CreateInformationTag(parent, description, textJustification)
    local text = addon.UICore:Build("TextRegion")
    text:SetText(description or "")
    text:SetJustifyH(textJustification or "CENTER")
    text:SetFullWidth(true)

    Attach(parent, text)
    if parent then parent:NewRow() end

    return text
end

---Create a read-only two line widget (label, content) whose text comes from a callback.
---The callback runs every time the widget is built or reused from the pool.
---@param parent table the container
---@param callback fun(widget: table): string?, string?, string? returns label, content and tooltip
---@return table widget
function addon.GUI:CreateInfoContainer(parent, callback)
    local info = addon.UICore:Build("InfoContainer")
    info:SetCallback(callback)

    return Attach(parent, info)
end

---@param parent table the container
---@param label string label
---@param get boolean the value to set
---@param callback fun(newValue: boolean) called when the value changed
---@return table widget
function addon.GUI:CreateToggleCheckBox(parent, label, get, callback)
    local toggle = addon.UICore:Build("ToggleBox")
    -- toggle:SetSize(WIDGET_WIDTH, WIDGET_HEIGHT)
    toggle:SetText(label or "")
    toggle:SetValue(get)
    toggle:SetOnClick(function(_, value)
        if callback then callback(value) end
    end)

    return Attach(parent, toggle)
end

---@param parent table the container
---@param label string label
---@param callback fun() called when the button is clicked
---@return table widget
function addon.GUI:CreateButton(parent, label, callback)
    local button = addon.UICore:Build("TextButton")
    -- button:SetSize(WIDGET_WIDTH, WIDGET_HEIGHT)
    button:SetText(label or "")
    button:SetOnClick(function()
        if callback then callback() end
    end)

    return Attach(parent, button)
end

---@param parent table the container
---@param label string label
---@param min number minimum of the slider
---@param max number maximum of the slider
---@param step number step size of the slider
---@param get number the value to set
---@param callback fun(newValue: number) called when the value changed
---@return table widget
function addon.GUI:CreateSlider(parent, label, min, max, step, get, callback)
    local slider = addon.UICore:Build("Slider")
    -- slider:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT + 2)
    slider:SetLabel(label or "")
    slider:SetMinMaxValues(min, max, step)
    slider:SetValue(get)
    slider:SetOnValueChanged(function(_, value)
        if callback then callback(value) end
    end)

    return Attach(parent, slider)
end

---@param parent table the container
---@param label string label
---@param get string the value to set
---@param callback fun(newValue: string) called when the text is committed
---@return table widget
function addon.GUI:CreateEditBox(parent, label, get, callback)
    local editBox = addon.UICore:Build("EditBox")
    -- editBox:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
    editBox:SetLabel(label or "")
    editBox:SetText(get or "")
    editBox:SetOnEnterPressed(function(_, text)
        if callback then callback(text) end
    end)

    return Attach(parent, editBox)
end

---@param parent table the container
---@param label string label
---@param get string the value to set
---@param callback fun(newValue: string) called when the text is committed
---@return table widget
function addon.GUI:CreateMultiLineEditBox(parent, label, get, callback)
    local editBox = addon.UICore:Build("MultiLineEditBox")
    -- editBox:SetSize(400, 140)
    editBox:SetLabel(label or "")
    editBox:SetText(get or "")
    editBox:SetFullWidth(true)
    editBox:SetOnEnterPressed(function(_, text)
        if callback then callback(text) end
    end)

    Attach(parent, editBox)
    if parent then parent:NewRow() end

    return editBox
end

---@param parent table the container
---@param label string label
---@param list table the value to display map
---@param order table? optional display order
---@param get any the value to set
---@param callback fun(key: any) called when the value changed
---@return table widget
function addon.GUI:CreateDropdown(parent, label, list, order, get, callback)
    local dropdown = addon.UICore:Build("Dropdown")
    -- dropdown:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
    dropdown:SetLabel(label or "")
    dropdown:SetList(list or {}, order)
    dropdown:SetValue(get)
    dropdown:SetOnValueChanged(function(_, key)
        if callback then callback(key) end
    end)

    return Attach(parent, dropdown)
end

---@param parent table the container
---@param label string label
---@param hasAlpha boolean whether the alpha channel can be edited
---@param get string the hex color to set
---@param callback fun(hexColor: string) called with the new hex color
---@return table widget
function addon.GUI:CreateColorPicker(parent, label, hasAlpha, get, callback)
    local colorPicker = addon.UICore:Build("ColorPicker")
    -- colorPicker:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
    colorPicker:SetLabel(label or "")
    colorPicker:SetHasAlpha(hasAlpha)
    colorPicker:SetHexColor(get)
    colorPicker:SetOnColorChanged(function(widget)
        if callback then callback(widget:GetHexColor()) end
    end)

    return Attach(parent, colorPicker)
end

---@param parent table the container
---@param label string label
---@param get string the value to set
---@param callback fun(key: string) called when the value changed
---@return table widget
function addon.GUI:CreateFontSelect(parent, label, get, callback)
    local fontSelect = addon.UICore:Build("FontDropdown")
    -- fontSelect:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
    fontSelect:SetLabel(label or "")
    fontSelect:SetValue(get)
    fontSelect:SetOnValueChanged(function(_, key)
        if callback then callback(key) end
    end)

    return Attach(parent, fontSelect)
end

---@param parent table the container
---@param label string label
---@param get string the value to set
---@param callback fun(key: string) called when the value changed
---@return table widget
function addon.GUI:CreateTextureSelect(parent, label, get, callback)
    local textureSelect = addon.UICore:Build("TextureDropdown")
    -- textureSelect:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
    textureSelect:SetLabel(label or "")
    textureSelect:SetValue(get)
    textureSelect:SetOnValueChanged(function(_, key)
        if callback then callback(key) end
    end)

    return Attach(parent, textureSelect)
end

---@param parent table the container
---@param label string label
---@param get string the value to set
---@param callback fun(key: string) called when the value changed
---@return table widget
function addon.GUI:CreateSoundSelect(parent, label, get, callback)
    local soundSelect = addon.UICore:Build("SoundDropdown")
    -- soundSelect:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
    soundSelect:SetLabel(label or "")
    soundSelect:SetValue(get)
    soundSelect:SetOnValueChanged(function(_, key)
        if callback then callback(key) end
    end)

    return Attach(parent, soundSelect)
end

---@param parent table the container
---@param get string the value to set
---@param callback fun(strata: string) called with the frame strata
---@return table widget
function addon.GUI:CreateFrameStrataDropdown(parent, get, callback)
    local order = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG"}
    return addon.GUI:CreateDropdown(parent, L["FrameStrata"], addon.Utility.FrameStrata, order, get, function(key)
        if callback then
            callback(addon.Utility.FrameStrata[key])
        end
    end)
end

-- MARK: Multi Dropdown

---Create a multi select dropdown
---@param parent table the container
---@param label string label
---@param list table the value to display map
---@param order table? optional display order
---@param get table? the keys to select
---@return table component with GetSelectedKeys, ClearSelections, SetSelectedKeys and GetWidget
function addon.GUI:CreateMultiDropdown(parent, label, list, order, get)
    local component = {}

    local dropdown = addon.UICore:Build("MultiDropdown")
    -- dropdown:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
    dropdown:SetLabel(label or "")
    dropdown:SetList(list or {}, order)
    dropdown:SetValue(get)
    Attach(parent, dropdown)

    component.widget = dropdown

    function component:GetSelectedKeys()
        return self.widget:GetSelectedKeys()
    end

    function component:ClearSelections()
        self.widget:ClearSelections()
    end

    function component:SetSelectedKeys(keys)
        self.widget:SetSelectedKeys(keys or {})
    end

    function component:GetWidget()
        return self.widget
    end

    return component
end

-- MARK: Specs Dropdown

---Create a specialization select dropdown
---@param parent table the container
---@param label string label
---@return table component with GetSelectedSpecs, ClearSpecSelection, SetSelectedSpecs and GetWidget
function addon.GUI:CreateSpecSelectDropdown(parent, label)
    local component = {}
    local specClassList = addon.Utility:GetAllSpecIconList(true)
    local specsList, specsOrder = {}, {}
    for _, specs in pairs(specClassList) do
        for specID, specStr in pairs(specs) do
            specsList[specID] = specStr
            table.insert(specsOrder, specID)
        end
    end

    component.dropdown = addon.GUI:CreateMultiDropdown(parent, label, specsList, specsOrder, nil)

    function component:GetSelectedSpecs()
        return self.dropdown:GetSelectedKeys()
    end

    function component:ClearSpecSelection()
        self.dropdown:ClearSelections()
    end

    function component:SetSelectedSpecs(loadingSpecs)
        self.dropdown:SetSelectedKeys(loadingSpecs)
    end

    function component:GetWidget()
        return self.dropdown:GetWidget()
    end

    return component
end
