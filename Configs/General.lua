local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

-- MARK: Default values
local PANEL_WIDTH = 855
local PANEL_HEIGHT = 600
local SIDEBAR_WIDTH = 200
local TOOLBAR_HEIGHT = 20
local TOOLBAR_BUTTON_WIDTH = 155
-- the toolbar window and the close button share this height, so they line up
local TOOLBAR_FRAME_HEIGHT = TOOLBAR_HEIGHT + 10
-- the config widgets share one grid: a plain control row, and a labelled one
-- local WIDGET_HEIGHT = 38
-- local LABELLED_HEIGHT = 38
local WIDGET_WIDTH = 220
local CLOSE_BUTTON_SIZE = TOOLBAR_FRAME_HEIGHT
local HIGHLIGHT_TEXT_COLOR = "|c" .. addon.Utility:RGBToHex(unpack(addon.UICore:GetHighlightColor()))
local CLOSE_BUTTON_TEXTURE = "Interface\\AddOns\\MidnightFocusInterrupt\\GUI\\Assets\\Close_Button.png"
local TITLE_ICON_TEXTURE = "Interface\\AddOns\\MidnightFocusInterrupt\\Media\\HBLyx.png"

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

---Create a labelled, read-only edit box so the URL can be selected and copied
local function CreateLink(container, info)
    return addon.GUI:CreateEditBox(container, info.text, info.url, function() end):SetRelativeWidth(0.3)
end

local function CreateGeneralPanel(container)
    addon.GUI:CreateInformationTag(container, L["WelecomeInfo"], "CENTER")

    addon.GUI:CreateInlineGroup(container, L["ModulesOverview"])
    addon.GUI:CreateInfoContainer(container, function()
        local modules, count = addon.core:GetLoadedModulesList()
        return L["LoadedModules"], tostring(count), table.concat(modules, ", ")
    end)
    addon.GUI:CreateInfoContainer(container, function()
        local modules, count = addon.core:GetUnloadedModulesList()
        return L["UnloadedModules"], tostring(count), table.concat(modules, ", ")
    end)
    container:NewRow()

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
    addon.GUI:CreateEditBox(container, "", L["ChangeLogLink"], function() end):SetRelativeWidth(0.3)
    container:NewRow()

    addon.GUI:CreateInlineGroup(container, L["Contact"])
    for _, info in ipairs(CONTACTS) do
        CreateLink(container, info)
    end
    container:NewRow()

    return container
end

-- MARK: TABS
local TABS = {
    {text = L["General"], type = "Button", module = "General", panelFunction = function(container) return CreateGeneralPanel(container) end},
    {text = addon.core:GetModuleName("FocusInterrupt"), type = "Button", module = "FocusInterrupt", tooltip = L["FocusInterruptSettingsDesc"], panelFunction = function(container) return addon.GUI.tabPanels.FocusInterrupt(container) end},
    {text = L["Profile"], type = "Button", module = "Profile", panelFunction = function(container) return addon.GUI.tabPanels.Profile(container) end},
}

-- auto assign index to each tabInfo for quick lookup
local MOD_INDEX = {}
for i, tabInfo in ipairs(TABS) do
    if tabInfo.module then
        MOD_INDEX[tabInfo.module] = i
    end
end

-- MARK: Tabs

---Show the panel of a tab in the content area
---@param module string the module key of the tab to select
function addon.GUI:SelectTab(module)
    local index = MOD_INDEX[module]
    if index then
        self.tabGroup:SelectTab(index)
    end
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

---Fill the toolbar window with the settings which are not owned by a module
local function RenderToolbar(toolbar)
    local testButton = addon.UICore:Build("TextButton")
    testButton:SetSize(TOOLBAR_BUTTON_WIDTH, TOOLBAR_HEIGHT)
    testButton:SetText(L["EditMode"])
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
    addon.UICore:SetBackdropColor(close)
    addon.UICore:SetBorderColor(close)
    close:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE)
    close:SetPoint("TOPRIGHT", toolbar.frame, "TOPRIGHT", 0, 0)
    close:SetNormalTexture(CLOSE_BUTTON_TEXTURE)
    close:SetPushedTexture(CLOSE_BUTTON_TEXTURE)
    close:SetHighlightTexture(CLOSE_BUTTON_TEXTURE)
    close:GetHighlightTexture():SetAlpha(0.75)
    close:SetScript("OnClick", function() addon.GUI:CloseGUI() end)
    addon.UICore:BuildHover(close)
    self.closeButton = close

    -- placeholder texture, to be replaced later
    local developerButton = CreateFrame("Button", nil, toolbar.frame, "BackdropTemplate")
    developerButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, tileSize = 1, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    addon.UICore:SetBackdropColor(developerButton)
    addon.UICore:SetBorderColor(developerButton)
    developerButton:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE)
    developerButton:SetPoint("TOPRIGHT", close, "TOPLEFT", 0, 0)
    developerButton:SetNormalTexture("Interface\\AddOns\\".. ADDON_NAME .. "\\Media\\Developer_Button.png")
    developerButton:SetPushedTexture("Interface\\AddOns\\".. ADDON_NAME .. "\\Media\\Developer_Button_Pushed.png")
    developerButton:SetHighlightTexture("Interface\\AddOns\\".. ADDON_NAME .. "\\Media\\Developer_Button_Highlight.png")
    developerButton:GetHighlightTexture():SetAlpha(0.75)
    developerButton:SetScript("OnClick", function() addon.Developer:DisplayAddonInfo() end)
    addon.UICore:BuildHover(developerButton)
    self.developerButton = developerButton

    -- the title window sits above the sidebar, the toolbar above the content area
    local tabGroup = addon.UICore:Build("VerticalTabGroup")
    tabGroup:SetParent(root)
    tabGroup:SetSidebarWidth(SIDEBAR_WIDTH)
    tabGroup:SetTitle({
        icon = TITLE_ICON_TEXTURE,
        title = string.format(L["GUITitle"], HIGHLIGHT_TEXT_COLOR),
        subtitle = string.format(L["GUIVersion"], addon:GetVersion()),
        height = TOOLBAR_FRAME_HEIGHT,
    })
    tabGroup:SetContentTopInset(TOOLBAR_FRAME_HEIGHT)
    tabGroup:SetSize(SIDEBAR_WIDTH + PANEL_WIDTH, PANEL_HEIGHT + TOOLBAR_FRAME_HEIGHT)
    tabGroup:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
    tabGroup:SetTabs(TABS)
    tabGroup:Show()
    AddDragHandle(tabGroup.sidebar.frame, root)
    AddDragHandle(tabGroup.titleWindow.frame, root)
    self.tabGroup = tabGroup
end

---Initialize/Constructor for GUI
function addon.GUI:Render()
    if self.isOpened or addon.states["inCombat"] then
        if addon.states["inCombat"] then
            addon.Utility:print(L["CombatLock"])
        end

        return
    end

    if not self.frame then
        BuildGUI(self)
    end

    self.isOpened = true
    self.frame:Show()
end

-- MARK: Open/Close GUI

---Open GUI
function addon.GUI:OpenGUI()
    addon.GUI:Render()
end

---Open GUI with a specific module tab selected
---@param module string the module key of the tab to select
function addon.GUI:OpenModuleGUI(module)
    addon.GUI:Render()
    if module then
        addon.GUI:SelectTab(module)
    end
end

---Close GUI
function addon.GUI:CloseGUI()
    if not self.frame then return end

    self.isOpened = false
    self.frame:Hide()
    addon.core:TestMode(false) -- turn off test mode when closing GUI
end

-- MARK: GUI Register Module
function addon.GUI:RegisterModule(modKey, renderFunction)
    if not self.tabPanels then
        self.tabPanels = {}
    end
    self.tabPanels[modKey] = renderFunction
end
