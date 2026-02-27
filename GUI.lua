local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local AceGUI = LibStub("AceGUI-3.0")

---@class HB_GUI
---@field frame GUI? GUI to dispaly
---@field isOpened boolean is GUI opened, release the GUI if not opened to save memory
addon.GUI = {
    frame = nil,
    isOpened = false,
}

-- MARK: TABS
local TABS = {
    {text = L["General"], value = "General"},
    {text = L["FocusInterruptSettings"], value = "FocusInterrupt"},
    {text = L["Profile"], value = "Profile"},
}

-- MARK: General Panel

local function CreateGeneralPanel(container)
    local panel = addon.GUI:CreateScrollFrame(container)
    panel:SetFullWidth(true)
    addon.GUI:CreateInformationTag(panel, L["WelecomeInfo"], "CENTER")
    -- notification
    local notificationsGroup = addon.GUI:CreateInlineGroup(panel, L["Notifications"])
    addon.GUI:CreateInformationTag(notificationsGroup, L["NotificationContent"], "LEFT")
    -- notification-release
    local releaseGroup = addon.GUI:CreateInlineGroup(notificationsGroup, L["Downloads/Update"])
    addon.GUI:CreateInformationTag(releaseGroup, L["Release_Info"], "LEFT")
    local curseForgeRelease = AceGUI:Create("InteractiveLabel")
    curseForgeRelease:SetText("|TInterface\\AddOns\\HBLyx_tools\\Media\\CurseForge.png:20:20|t |cFF8080FFCurseForge|r")
    curseForgeRelease:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    curseForgeRelease:SetJustifyV("MIDDLE")
    curseForgeRelease:SetRelativeWidth(0.25)
    curseForgeRelease:SetCallback("OnClick", function() addon.Utilities:OpenURL("CurseForge", "https://www.curseforge.com/wow/addons/hblyx-tools") end)
    curseForgeRelease:SetCallback("OnEnter", function() curseForgeRelease:SetText("|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\CurseForge.png:20:20|t |cFFFFFFFFCurseForge|r") end)
    curseForgeRelease:SetCallback("OnLeave", function() curseForgeRelease:SetText("|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\CurseForge.png:20:20|t |cFF8080FFCurseForge|r") end)
    releaseGroup:AddChild(curseForgeRelease)
    -- change log
    local changeLogGroup = addon.GUI:CreateInlineGroup(panel, L["ChangeLog"])
    addon.GUI:CreateInformationTag(changeLogGroup, L["ChangeLogContent"], "LEFT")
    -- issues
    local issueGroup = addon.GUI:CreateInlineGroup(panel, L["Issues"])
    addon.GUI:CreateInformationTag(issueGroup, L["IssuesContent"], "LEFT")
    -- contact
    local contactGroup = addon.GUI:CreateInlineGroup(panel, L["Contact"])
    local gitHubInteractive = AceGUI:Create("InteractiveLabel")
    gitHubInteractive:SetText("|TInterface\\AddOns\\HBLyx_tools\\Media\\Github.png:21:21|t |cFF8080FFGitHub|r")
    gitHubInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    gitHubInteractive:SetJustifyV("MIDDLE")
    gitHubInteractive:SetRelativeWidth(0.25)
    gitHubInteractive:SetCallback("OnClick", function() addon.Utilities:OpenURL(L["GitHub"], "https://github.com/HelloBearLYX/HBLyx_Tools/issues") end)
    gitHubInteractive:SetCallback("OnEnter", function() gitHubInteractive:SetText("|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\Github.png:21:21|t |cFFFFFFFFGitHub|r") end)
    gitHubInteractive:SetCallback("OnLeave", function() gitHubInteractive:SetText("|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\Github.png:21:21|t |cFF8080FFGitHub|r") end)
    contactGroup:AddChild(gitHubInteractive)
    local curseForgeInteractive = AceGUI:Create("InteractiveLabel")
    curseForgeInteractive:SetText("|TInterface\\AddOns\\HBLyx_tools\\Media\\CurseForge.png:21:21|t |cFF8080FFCurseForge|r")
    curseForgeInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    curseForgeInteractive:SetJustifyV("MIDDLE")
    curseForgeInteractive:SetRelativeWidth(0.25)
    curseForgeInteractive:SetCallback("OnClick", function() addon.Utilities:OpenURL(L["CurseForge"], "https://www.curseforge.com/wow/addons/midnightfocusinterrupt/comments") end)
    curseForgeInteractive:SetCallback("OnEnter", function() curseForgeInteractive:SetText("|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\CurseForge.png:21:21|t |cFFFFFFFFCurseForge|r") end)
    curseForgeInteractive:SetCallback("OnLeave", function() curseForgeInteractive:SetText("|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\CurseForge.png:21:21|t |cFF8080FFCurseForge|r") end)
    contactGroup:AddChild(curseForgeInteractive)

    return panel
end

-- MARK: Initialize GUI

---Initialize/Constructor for GUI
function addon.GUI:Render()
    if self.isOpened or InCombatLockdown() then return end

    -- create main frame
    self.isOpened = true
    self.frame = AceGUI:Create("Frame")
    self.frame:SetTitle("|TInterface\\AddOns\\MidnightFocusInterrupt\\Media\\HBLyx.png:20:20|t " .. L["GUITitle"])
    self.frame:SetLayout("Flow")
    self.frame:SetWidth(900)
    self.frame:SetHeight(600)
    self.frame:EnableResize(false)
    self.frame:SetStatusText("|cff8788ee"..  ADDON_NAME .. "|r v" .. addon:GetVersion() .. " " .. L["AnyIssues"])
    self.frame:SetCallback("OnClose", function(widgets)
        if widgets then
            AceGUI:Release(widgets)
        end

        self.isOpened = false
        addon.core:TestMode(false) -- turn off test mode when closing GUI
    end)

    -- MARK: Test button
    self.TestButton = AceGUI:Create("Button")
    self.TestButton:SetText(L["Test"])
    self.TestButton:SetWidth(200)
    self.TestButton:SetCallback("OnClick", function()
        addon.core:TestMode() -- toggle test mode on/off when click the button
    end)
    self.frame:AddChild(self.TestButton)

    addon.GUI:CreateToggleCheckBox(self.frame, L["HideMinimapIcon"], addon.db.MinimapIcon.hide, function(value)
        addon.db.MinimapIcon.hide = value
        if not addon.db.MinimapIcon.hide then
            LibStub("LibDBIcon-1.0"):Show(ADDON_NAME)
        else
            LibStub("LibDBIcon-1.0"):Hide(ADDON_NAME)
        end
    end)

    -- create tabs
    local tabs = AceGUI:Create("TabGroup")
    tabs:SetLayout("Flow")
    tabs:SetFullWidth(true)
    tabs:SetFullHeight(true)
    tabs:SetTabs(TABS)
    self.frame:AddChild(tabs)
    
    -- MARK: Tab Callback
    tabs:SetCallback("OnGroupSelected", function(container, _, tab)
        container:ReleaseChildren()

        -- General Panel
        if tab == "General" then
            local panel = CreateGeneralPanel(container)
            panel:DoLayout()
        elseif tab == "FocusInterrupt" then
            local panel = addon.GUI.TagPanels.FocusInterrupt:CreateTabPanel(container)
            panel:DoLayout()
        elseif tab == "Profile" then
            local panel = addon.GUI.TagPanels.Profile:CreateTabPanel(container)
            panel:DoLayout()
        end
    end)

    tabs:SelectTab("General")
end

-- MARK: Open/Close GUI

---Open GUI
function addon.GUI:OpenGUI()
    addon.GUI:Render()
end

---Close GUI
function addon.GUI:CloseGUI()
    if self.isOpened and self.frame then
        self.frame:Hide()
        self.isOpened = false
    end
end

-- MARK: Inline Group

---Create an inline group to its parent
---@param parent AceGUIWidget the parent container
---@param title string title
---@return AceGUIWidget
function addon.GUI:CreateInlineGroup(parent, title)
    local inlineGroup = AceGUI:Create("InlineGroup")
    inlineGroup:SetTitle("|cFFFFFFFF" .. title .. "|r")
    inlineGroup:SetFullWidth(true)
    inlineGroup:SetLayout("Flow")

    if parent then
        parent:AddChild(inlineGroup)
    end

    return inlineGroup
end

-- MARK: Dropdown Group

---Create a dropdown group to its parent
---@param parent AceGUIWidget the parent container
---@param title string title
---@param list table the list of items for the dropdown
---@param order table the order of items in the dropdown
---@param get any initial value for the dropdown
---@param callback fun(key) callback function when an item is selected
---@return AceGUIWidget
function addon.GUI:CreateDropdownGroup(parent, title, list, order, get, callback)
    local dropdownGroup = AceGUI:Create("DropdownGroup")
    dropdownGroup:SetTitle("|cFFFFFFFF" .. title .. "|r")
    dropdownGroup:SetFullWidth(true)
    dropdownGroup:SetLayout("Flow")
    dropdownGroup:SetGroupList(list, order)
    dropdownGroup:SetGroup(get)
    dropdownGroup:SetCallback("OnGroupSelected", function(_, _, group)
        if callback then
            callback(group)
        end
    end)

    if parent then
        parent:AddChild(dropdownGroup)
    end
    
    return dropdownGroup
end

-- MARK: Scroll Frame

---Create a scroll frame to its parent
---@param parent AceGUIWidget the parent container
---@return AceGUIWidget
function addon.GUI:CreateScrollFrame(parent)
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    
    if parent then
        parent:AddChild(scrollFrame)
    end

    return scrollFrame
end

-- MARK: Toggle CheckBox

---Create a Toggle Check Box
---@param parent AceGUIWidget the parent container
---@param label string label
---@param get boolean the value to set
---@param callback fun(newValue: boolean) callback function when value changed
---@return AceGUIWidget
function addon.GUI:CreateToggleCheckBox(parent, label, get, callback)
    local toggle = AceGUI:Create("CheckBox")
    toggle:SetLabel(label)
    toggle:SetValue(get)
    toggle:SetCallback("OnValueChanged", function(_, _, newValue)
        if callback then
            callback(newValue)
        end
    end)
    if parent then
        parent:AddChild(toggle)
    end
    return toggle
end

-- MARK: Button

---Create a button
---@param parent AceGUIWidget the parent container
---@param label string label
---@param callback fun() callback function when button clicked
---@return AceGUIWidget
function addon.GUI:CreateButton(parent, label, callback)
    local button = AceGUI:Create("Button")
    button:SetText(label)
    button:SetCallback("OnClick", function()
        if callback then
            callback()
        end
    end)
    if parent then
        parent:AddChild(button)
    end
    return button
end

-- MARK: Slider

---Create a slider
---@param parent AceGUIWidget the parent container
---@param label string label
---@param min number minimum of the slider
---@param max number maximum of the slider
---@param step number step size of the slider
---@param get number the value to set
---@param callback fun(newValue) callback function when value change
---@return AceGUIWidget
function addon.GUI:CreateSlider(parent, label, min, max, step, get, callback)
    local slider = AceGUI:Create("Slider")
    slider:SetLabel(label)
    slider:SetSliderValues(min, max, step)
    slider:SetValue(get)
    slider:SetCallback("OnValueChanged", function(_, _, newValue)
        if callback then
            callback(newValue)
        end
    end)
    if parent then
        parent:AddChild(slider)
    end
    return slider
end

-- MARK: Create Header

---Create a header
---@param parent AceGUIWidget the parent container
---@param title string title
---@return AceGUIWidget
function addon.GUI:CreateHeader(parent, title)
    local headingText = AceGUI:Create("Heading")
    headingText:SetText("|cFFFFCC00" .. title .. "|r")
    headingText:SetFullWidth(true)
    if parent then
        parent:AddChild(headingText)
    end
    return headingText
end

-- MARK: Information Tag

---Create an information tag/lines
---@param parent AceGUIWidget the parent container
---@param description string the description to display
---@param textJustification string the text justification ("LEFT", "CENTER", "RIGHT")
---@return AceGUIWidget
function addon.GUI:CreateInformationTag(parent, description, textJustification)
    local informationLabel = AceGUI:Create("Label")
    informationLabel:SetText(description)
    informationLabel:SetFullWidth(true)
    informationLabel:SetJustifyH(textJustification or "CENTER")
    informationLabel:SetHeight(24)
    informationLabel:SetJustifyV("MIDDLE")
    if parent then
        parent:AddChild(informationLabel)
    end
    return informationLabel
end

-- MARK: Create Font

---Create a font select dropdown
---@param parent AceGUIWidget the parent container
---@param label string label
---@param get string the value to set
---@param callback fun(key: string) callback function when value changed
---@return AceGUIWidget
function addon.GUI:CreateFontSelect(parent, label, get, callback)
    local fontSelect = AceGUI:Create("LSM30_Font")
    fontSelect:SetLabel(label)
    fontSelect:SetList(addon.LSM:HashTable("font"))
    fontSelect:SetValue(get)
    fontSelect:SetCallback("OnValueChanged", function(self, _, key)
        self:SetValue(key)
        if callback then
            callback(key)
        end
    end)
    if parent then
        parent:AddChild(fontSelect)
    end
    return fontSelect
end

-- MARK: Create Sound

---Create a sound select dropdown
---@param parent AceGUIWidget the parent container
---@param label string label
---@param get string the value to set
---@param callback fun(key: string) callback function when value changed
---@return AceGUIWidget
function addon.GUI:CreateSoundSelect(parent, label, get, callback)
    local soundSelect = AceGUI:Create("LSM30_Sound")
    soundSelect:SetLabel(label)
    soundSelect:SetList(addon.LSM:HashTable("sound"))
    soundSelect:SetValue(get)
    soundSelect:SetCallback("OnValueChanged", function(self, _, key)
        self:SetValue(key)
        if callback then
            callback(key)
        end
    end)
    if parent then
        parent:AddChild(soundSelect)
    end
    return soundSelect
end

-- MARK: Create Texture

---Create a texture select dropdown
---@param parent AceGUIWidget the parent container
---@param label string label
---@param get string the value to set
---@param callback fun(key: string) callback function when value changed
---@return AceGUIWidget
function addon.GUI:CreateTextureSelect(parent, label, get, callback)
    local textureSelect = AceGUI:Create("LSM30_Statusbar")
    textureSelect:SetLabel(label)
    textureSelect:SetList(addon.LSM:HashTable("statusbar"))
    textureSelect:SetValue(get)
    textureSelect:SetCallback("OnValueChanged", function(self, _, key)
        self:SetValue(key)
        if callback then
            callback(key)
        end
    end)
    if parent then
        parent:AddChild(textureSelect)
    end
    return textureSelect
end

-- MARK: Create Color Picker

---Create a color picker
---@param parent AceGUIWidget the parent container
---@param label string label
---@param hasAlpha boolean whether the color picker has alpha channel
---@param get string the value to set (hex color)
---@param callback fun(hexColor: string) callback function when value changed, the color will be converted to hex format before passing to the callback
---@return AceGUIWidget
function addon.GUI:CreateColorPicker(parent, label, hasAlpha, get, callback)
    local colorPicker = AceGUI:Create("ColorPicker")
    colorPicker:SetLabel(label)
    colorPicker:SetHasAlpha(hasAlpha)
    colorPicker:SetColor(addon.Utilities:HexToRGB(get))
    colorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
        if callback then
            callback(addon.Utilities:RGBToHex(r, g, b, a))
        end
    end)
    if parent then
        parent:AddChild(colorPicker)
    end
    return colorPicker
end

-- MARK: Create EditBox

---Create an edit box
---@param parent AceGUIWidget the parent container
---@param label string label
---@param get string the value to set
---@param callback fun(newValue: string) callback function when value changed
---@return AceGUIWidget
function addon.GUI:CreateEditBox(parent, label, get, callback)
    local editBox = AceGUI:Create("EditBox")
    editBox:SetLabel(label)
    editBox:SetText(get)
    editBox:SetCallback("OnEnterPressed", function(self)
        if callback then
            callback(self:GetText())
        end
    end)
    if parent then
        parent:AddChild(editBox)
    end
    return editBox
end

-- MARK: Create Dropdown

---Create a generic dropdown
---@param parent AceGUIWidget the parent container
---@param label string label
---@param list table the list of items to display in the dropdown
---@param order table? optional display order for list items
---@param get string the value to set
---@param callback fun(key: string, checked: boolean) callback function when value changed
---@return AceGUIWidget
function addon.GUI:CreateDropdown(parent, label, list, order, get, callback)
    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetLabel(label)
    dropdown:SetMultiselect(false)
    if list then
        if order then
            dropdown:SetList(list, order)
        else
            dropdown:SetList(list)
        end
    end
    dropdown:SetValue(get)
    dropdown:SetCallback("OnValueChanged", function(_, _, key, checked)
        if callback then
            callback(key, checked)
        end
    end)

    if parent then
        parent:AddChild(dropdown)
    end
    return dropdown
end

-- MARK: MultiLine EditBox

---Create a multi-line edit box
---@param parent AceGUIWidget the parent container
---@param label string label
---@param get string the value to set
---@param callback fun(newValue: string) callback function when value changed
---@return AceGUIWidget
function addon.GUI:CreateMultiLineEditBox(parent, label, get, callback)
    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel(label)
    editBox:SetText(get)
    editBox:SetRelativeWidth(1)
    editBox:SetCallback("OnEnterPressed", function(self)
        if callback then
            callback(self:GetText())
        end
    end)

    if parent then
        parent:AddChild(editBox)
    end
    return editBox
end

-- MARK: Multi Dropdown

---Create a multi-select dropdown
---@param parent AceGUIWidget the parent container
---@param label string label
---@param list table the list of items to display in the dropdown
---@param order table? optional display order for list items
---@param get table the values to set
function addon.GUI:CreateMultiDropdown(parent, label, list, order, get)
    local self = {} -- re-defined self for this component

    self.selectedKeys = {}

    self.widget = addon.GUI:CreateDropdown(parent, label, list, order, get, function(key, checked)
        if checked then
            self.selectedKeys[key] = true
        else
            self.selectedKeys[key] = nil
        end
    end)
    self.widget:SetMultiselect(true)
    
    function self:GetSelectedKeys()
        return next(self.selectedKeys) and self.selectedKeys or nil
    end

    function self:ClearSelections()
        for key, _ in pairs(self.selectedKeys) do
            self.selectedKeys[key] = nil
            self.widget:SetItemValue(key, false)
        end
    end

    function self:SetSelectedKeys(keys)
        self:ClearSelections()
        for key, _ in pairs(keys or {}) do
            self.selectedKeys[key] = true
            self.widget:SetItemValue(key, true)
        end
    end

    function self:GetWidget()
        return self.widget
    end

    return self
end

-- MARK: Specs Dropdown

---Create a specialization select dropdown
---@param parent AceGUIWidget the parent container
---@param label string label
---@return table component GUI component with GetSelectedSpecs, ClearSpecSelection and SetSelectedSpecs methods
function addon.GUI:CreateSpecSelectDropdown(parent, label)
    local self = {} -- re-defined self for this component
    local specClassList = addon.Utilities:GetAllSpecIconList(true)
    local specsList, specsOrder = {}, {}
    for _, specs in pairs(specClassList) do
        for specID, specStr in pairs(specs) do
            specsList[specID] = specStr
            table.insert(specsOrder, specID)
        end
    end

    self.dropdown = addon.GUI:CreateMultiDropdown(parent, label, specsList, specsOrder, nil)

    function self:GetSelectedSpecs()
        return self.dropdown:GetSelectedKeys()
    end

    function self:ClearSpecSelection()
        self.dropdown:ClearSelections()
    end

    function self:SetSelectedSpecs(loadingSpecs)
        self.dropdown:SetSelectedKeys(loadingSpecs)
    end

    function self:GetWidget()
        return self.dropdown:GetWidget()
    end

    return self
end

-- MARK: Create Frame Strata

---Create a frame strata select dropdown
---@param parent AceGUIWidget the parent container
---@param get string the value to set
---@param callback fun(key: string) callback function when value changed
---@return AceGUIWidget
function addon.GUI:CreateFrameStrataDropdown(parent, get, callback)
    local frameStrataList = addon.Utilities.FrameStrata
    local order = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG"}
    return addon.GUI:CreateDropdown(parent, L["FrameStrata"], frameStrataList, order, get, function(key)
        if callback then
            callback(addon.Utilities.FrameStrata[key])
        end
    end)
end

-- Initialize Tag Panels
addon.GUI.TagPanels = {}