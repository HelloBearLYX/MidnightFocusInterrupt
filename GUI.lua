local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

---@class HB_GUI
---@field frame Frame? the movable root frame which holds every part of the configuration UI
---@field panel Frame? the main panel which holds the title and the content
---@field content table? the scroll frame which holds the panel of the selected tab
---@field sidebar table? the window which holds the tab buttons
---@field selectedTab table? the entry of TABS which is currently shown
---@field isOpened boolean is the GUI opened
addon.GUI = {
    frame = nil,
    content = nil,
    sidebar = nil,
    isOpened = false,
}

-- MARK: Default values
local PANEL_WIDTH = 1000
local PANEL_HEIGHT = 600
local SIDEBAR_WIDTH = 155
local PADDING = 16
local TITLE_HEIGHT = 26
local TOOLBAR_HEIGHT = 20
local TOOLBAR_BUTTON_WIDTH = 155
-- the toolbar window and the close button share this height, so they line up
local TOOLBAR_FRAME_HEIGHT = TOOLBAR_HEIGHT + 10
-- the config widgets share one grid: a plain control row, and a labelled one
local WIDGET_HEIGHT = 38
local LABELLED_HEIGHT = 38
local WIDGET_WIDTH = 220
local CLOSE_BUTTON_SIZE = TOOLBAR_FRAME_HEIGHT

local HEADER_COLOR = "|cFFFFFFFF"
local SECTION_COLOR = "|cff8788ee"

local CLOSE_BUTTON_TEXTURE = "Interface\\AddOns\\MidnightFocusInterrupt\\GUI\\Assets\\Close_Button.png"

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

local BORDER_BACKDROP = {
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

---Background and border as their own regions, a moved frame keeps them
local function StyleFrame(frame, alpha)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(0, 0, 0, alpha or 0.8)

    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints(frame)
    border:SetBackdrop(BORDER_BACKDROP)
    border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    frame.background = background
    frame.border = border
end

-- MARK: General Panel

local LINKS = {
    { text = "|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\CurseForge.png:0|t CurseForge", name = "CurseForge", url = "https://www.curseforge.com/wow/addons/midnightfocusinterrupt" },
    { text = "新手盒子", name = "新手盒子", url = "https://www.wclbox.com/games/1/PluginItem/17822?version=2" },
}

local CONTACTS = {
    { text = "|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\Discord.png:0|t Discord", name = "Discord", url = "https://discord.gg/EVFmd6uVYg" },
    { text = "|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\Github.png:0|t GitHub", name = "GitHub", url = "https://github.com/HelloBearLYX/MidnightFocusInterrupt/issues" },
    { text = "|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\CurseForge.png:0|t CurseForge", name = "CurseForge", url = "https://www.curseforge.com/wow/addons/midnightfocusinterrupt/comments" },
}

---Create a clickable link which opens the copy URL popup
local function CreateLink(container, info)
    local link = addon.UICore:Build("TextRegion")
    link:SetText("|cFF8080FF" .. info.text .. "|r")
    link:SetRelativeWidth(0.3)
    link:SetOnClick(function() addon.Utilities:OpenURL(info.name, info.url) end)
    container:AddWidget(link)
    return link
end

local function CreateGeneralPanel(container)
    addon.GUI:CreateInformationTag(container, L["WelecomeInfo"], "CENTER")

    addon.GUI:CreateInlineGroup(container, L["Downloads/Update"])
    addon.GUI:CreateInformationTag(container, L["Release_Info"], "LEFT")
    for _, info in ipairs(LINKS) do
        CreateLink(container, info)
    end
    container:NewRow()

    addon.GUI:CreateInlineGroup(container, L["Notifications"])
    addon.GUI:CreateInformationTag(container, L["NotificationContent"], "LEFT")

    addon.GUI:CreateInlineGroup(container, L["ChangeLog"])
    addon.GUI:CreateInformationTag(container, L["ChangeLogContent"], "LEFT")
    addon.GUI:CreateEditBox(container, "", L["ChangeLogLink"], function() end):SetFullWidth(true)

    addon.GUI:CreateInlineGroup(container, L["Contact"])
    for _, info in ipairs(CONTACTS) do
        CreateLink(container, info)
    end
    container:NewRow()

    return container
end

-- MARK: TABS
local TABS = {
    {text = L["General"], type = "Button", panelFunction = function(container) return CreateGeneralPanel(container) end},
    {text = L["FocusInterruptSettings"], type = "Button", tooltip = L["FocusInterruptSettingsDesc"], panelFunction = function(container) return addon.GUI.TagPanels.FocusInterrupt:CreateTabPanel(container) end},
    {text = L["Profile"], type = "Button", panelFunction = function(container) return addon.GUI.TagPanels.Profile:CreateTabPanel(container) end},
}

-- MARK: Tabs

---Fill the sidebar with the tab buttons and the section titles
local function RenderTabs(sidebar)
    for _, tabInfo in ipairs(TABS) do
        if tabInfo.type == "Button" then
            local tabButton = addon.UICore:Build("TextButton")
            tabButton:SetSize(sidebar:GetWidth(), 22)
            tabButton:SetText(tabInfo.text)
            tabButton:SetOnClick(function() addon.GUI:SelectTab(tabInfo) end)
            if tabInfo.tooltip then
                addon.UICore:SetTooltip(tabButton, tabInfo.tooltip)
            end
            sidebar:AddWidget(tabButton)
        else
            local separator = addon.UICore:Build("LineSeperator")
            separator:SetFullWidth(true)
            sidebar:AddWidget(separator)
            sidebar:NewRow()

            local title = addon.UICore:Build("TextRegion")
            title:SetText(HEADER_COLOR .. tabInfo.text .. "|r")
            title:SetJustifyH("CENTER")
            title:SetFullWidth(true)
            sidebar:AddWidget(title)
        end

        sidebar:NewRow()
    end
end

---Show the panel of a tab in the content scroll frame
---@param tabInfo table an entry of TABS
function addon.GUI:SelectTab(tabInfo)
    if not tabInfo.panelFunction then return end

    self.selectedTab = tabInfo
    self.content:SetRenderer(function(container)
        tabInfo.panelFunction(container)
        container:DoLayout()
    end)
    self.content:Rerender()
end

-- MARK: Initialize GUI

---The root frame carries the drag, every other frame is anchored inside of it
local function CreateRootFrame()
    local root = CreateFrame("Frame", "MidnightFocusInterruptConfigFrame", UIParent)
    root:SetSize(SIDEBAR_WIDTH + PANEL_WIDTH, TOOLBAR_FRAME_HEIGHT + PANEL_HEIGHT)
    root:SetPoint("CENTER")
    root:SetFrameStrata("HIGH")
    root:SetMovable(true)
    root:EnableMouse(true)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", root.StartMoving)
    root:SetScript("OnDragStop", root.StopMovingOrSizing)
    root:SetClampedToScreen(true)
    root:Hide()

    return root
end

---A mouse enabled child swallows the drag, so it has to move the root itself
local function AddDragHandle(frame, root)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() root:StartMoving() end)
    frame:SetScript("OnDragStop", function() root:StopMovingOrSizing() end)
end

local function CreatePanelFrame(root)
    local frame = CreateFrame("Frame", nil, root)
    frame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    frame:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)

    StyleFrame(frame, 0.8)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    title:SetTextColor(1, 1, 1, 1)
    title:SetText("|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\HBLyx.png:0|t " .. string.format(L["GUITitle"], addon:GetVersion()))
    title:SetJustifyH("CENTER")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -PADDING)
    frame.title = title

    return frame
end

---Fill the toolbar window with the settings which are not owned by a module
local function RenderToolbar(toolbar)
    local testButton = addon.UICore:Build("TextButton")
    testButton:SetSize(TOOLBAR_BUTTON_WIDTH, TOOLBAR_HEIGHT)
    testButton:SetText(L["Test"])
    testButton:SetOnClick(function() addon.core:TestMode() end)
    toolbar:AddWidget(testButton)

    local minimapToggle = addon.UICore:Build("ToggleBox")
    minimapToggle:SetSize(TOOLBAR_BUTTON_WIDTH, TOOLBAR_HEIGHT)
    minimapToggle:SetText(L["HideMinimapIcon"])
    minimapToggle:SetValue(addon.db.MinimapIcon.hide)
    minimapToggle:SetOnClick(function(_, value)
        addon.db.MinimapIcon.hide = value
        if value then
            LibStub("LibDBIcon-1.0"):Hide(ADDON_NAME)
        else
            LibStub("LibDBIcon-1.0"):Show(ADDON_NAME)
        end
    end)
    toolbar:AddWidget(minimapToggle)
end

---Build the main frame, the sidebar and the content area once
local function BuildGUI(self)
    local root = CreateRootFrame()
    self.frame = root

    local frame = CreatePanelFrame(root)
    self.panel = frame

    -- the toolbar sits above the main frame, like the tab window sits next to it
    local toolbar = addon.UICore:Build("Window")
    toolbar:SetParent(root)
    toolbar:SetSize(PANEL_WIDTH, TOOLBAR_FRAME_HEIGHT)
    toolbar:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    toolbar:SetRenderer(RenderToolbar)
    toolbar:Rerender()
    toolbar:Show()
    AddDragHandle(toolbar.frame, root)
    self.toolbar = toolbar

    local close = CreateFrame("Button", nil, toolbar.frame, "BackdropTemplate")
    close:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, tileSize = 1, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    close:SetBackdropColor(0, 0, 0, 0.5)
    close:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    close:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE)
    close:SetPoint("TOPRIGHT", toolbar.frame, "TOPRIGHT", 0, 0)
    close:SetNormalTexture(CLOSE_BUTTON_TEXTURE)
    close:SetPushedTexture(CLOSE_BUTTON_TEXTURE)
    close:SetHighlightTexture(CLOSE_BUTTON_TEXTURE)
    close:GetHighlightTexture():SetAlpha(0.75)
    close:SetScript("OnClick", function() addon.GUI:CloseGUI() end)
    addon.UICore:BuildHover(close)
    self.closeButton = close

    local content = addon.UICore:Build("ScrollFrame")
    content:SetParent(frame)
    content:SetSize(PANEL_WIDTH - PADDING * 2, PANEL_HEIGHT - PADDING * 2 - TITLE_HEIGHT)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -(PADDING + TITLE_HEIGHT))
    content:Show()
    self.content = content

    local sidebar = addon.UICore:Build("Window")
    sidebar:SetParent(root)
    sidebar:SetSize(SIDEBAR_WIDTH, PANEL_HEIGHT + TOOLBAR_FRAME_HEIGHT)
    sidebar:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
    sidebar:SetRenderer(RenderTabs)
    sidebar:Rerender()
    sidebar:Show()
    AddDragHandle(sidebar.frame, root)
    self.sidebar = sidebar
end

---Initialize/Constructor for GUI
function addon.GUI:Render()
    if self.isOpened or addon.states["inCombat"] then
        if addon.states["inCombat"] then
            addon.Utilities:print(L["CombatLock"])
        end

        return
    end

    if not self.frame then
        BuildGUI(self)
    end

    self.isOpened = true
    self.frame:Show()
    self:SelectTab(self.selectedTab or TABS[1])
end

-- MARK: Open/Close GUI

---Open GUI
function addon.GUI:OpenGUI()
    addon.GUI:Render()
end

---Close GUI
function addon.GUI:CloseGUI()
    if not self.frame then return end

    self.isOpened = false
    self.frame:Hide()
    addon.core:TestMode(false) -- turn off test mode when closing GUI
end

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
    header:SetText(SECTION_COLOR .. (title or "") .. "|r")
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

---@param parent table the container
---@param label string label
---@param get boolean the value to set
---@param callback fun(newValue: boolean) called when the value changed
---@return table widget
function addon.GUI:CreateToggleCheckBox(parent, label, get, callback)
    local toggle = addon.UICore:Build("ToggleBox")
    toggle:SetSize(WIDGET_WIDTH, WIDGET_HEIGHT)
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
    button:SetSize(WIDGET_WIDTH, WIDGET_HEIGHT)
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
    slider:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT + 2)
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
    editBox:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
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
    editBox:SetSize(400, 140)
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
    dropdown:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
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
    colorPicker:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
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
    fontSelect:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
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
    textureSelect:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
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
    soundSelect:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
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
    return addon.GUI:CreateDropdown(parent, L["FrameStrata"], addon.Utilities.FrameStrata, order, get, function(key)
        if callback then
            callback(addon.Utilities.FrameStrata[key])
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
    dropdown:SetSize(WIDGET_WIDTH, LABELLED_HEIGHT)
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
    local specClassList = addon.Utilities:GetAllSpecIconList(true)
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

-- Initialize Tag Panels
addon.GUI.TagPanels = {}
