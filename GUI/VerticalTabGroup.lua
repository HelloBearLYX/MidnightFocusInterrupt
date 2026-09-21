local addon = select(2, ...)

---@class VerticalTabGroup
---@field type string widget type
---@field frame Frame the frame which bounds both the sidebar and the content area
---@field sidebar table the ScrollFrame widget which lists the tab buttons and section titles
---@field contentHolder Frame the frame the per-tab content panels are anchored into
---@field tabs table the ordered list of {info, row, container} built by SetTabs
---@field selectedIndex number? the index into tabs which is currently shown
local VerticalTabGroup = {
    type = "VerticalTabGroup",
    frame = nil,
    sidebar = nil,
    contentHolder = nil,
    tabs = nil,
    selectedIndex = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 400
local DEFAULT_HEIGHT = 300
local DEFAULT_SIDEBAR_WIDTH = 155
local TAB_ROW_HEIGHT = 22
local ROW_SPACING = 2
local INDICATOR_WIDTH = 3
local INDICATOR_TEXT_PADDING = 6
local SECTION_TOP_SPACING = 8
local SECTION_TITLE_HEIGHT = 16
local SEPARATOR_HEIGHT = 1
local DIVIDER_COLOR = { 1, 1, 1, 0.5 }

local HIGHLIGHT_TEXT_COLOR = "|c" .. addon.Utilities:RGBToHex(unpack(addon.UICore:GetHighlightColor()))

-- MARK: Helpers

---Build a plain-text, clickable tab row with a left indicator bar shown only while selected
local function CreateTabButtonRow(widget, container, y, info, index)
    local button = CreateFrame("Button", nil, container)
    button:SetHeight(TAB_ROW_HEIGHT)
    button:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -y)
    button:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -y)

    addon.UICore:BuildHover(button)

    local indicator = button:CreateTexture(nil, "ARTWORK")
    indicator:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    indicator:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    indicator:SetWidth(INDICATOR_WIDTH)
    indicator:SetColorTexture(unpack(addon.UICore:GetHighlightColor()))
    indicator:Hide()

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(addon.UICore:GetDefaultFont(), 12, "OUTLINE")
    text:SetPoint("LEFT", indicator, "RIGHT", INDICATOR_TEXT_PADDING, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(unpack(addon.UICore:GetNormalTextColor()))
    text:SetText(info.text)

    button:SetScript("OnClick", function()
        PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
        widget:SelectTab(index)
    end)

    if info.tooltip then
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetText(info.tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return { button = button, text = text, indicator = indicator, height = TAB_ROW_HEIGHT }
end

---Build a non-clickable section title row, used to group tab buttons
local function CreateSectionRow(container, y, info)
    local separator = container:CreateTexture(nil, "BORDER")
    separator:SetColorTexture(unpack(DIVIDER_COLOR))
    separator:SetHeight(SEPARATOR_HEIGHT)
    separator:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -y)
    separator:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -y)

    local title = container:CreateFontString(nil, "OVERLAY")
    title:SetFont(addon.UICore:GetDefaultFont(), 12, "OUTLINE")
    title:SetJustifyH("CENTER")
    title:SetHeight(SECTION_TITLE_HEIGHT)
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -(y + SEPARATOR_HEIGHT + SECTION_TOP_SPACING))
    title:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -(y + SEPARATOR_HEIGHT + SECTION_TOP_SPACING))
    title:SetText(HIGHLIGHT_TEXT_COLOR .. info.text .. "|r")

    return { separator = separator, title = title, height = SEPARATOR_HEIGHT + SECTION_TOP_SPACING + SECTION_TITLE_HEIGHT }
end

---Build the content panel of a tab the first time it is selected, then just show it again
---so that its scroll position and widget values survive switching to another tab and back
local function ShowTabContent(widget, tab)
    if not tab.container then
        local container = addon.UICore:Build("ScrollFrame")
        container:SetParent(widget.contentHolder)
        container:SetPoint("TOPLEFT", widget.contentHolder, "TOPLEFT", 0, 0)
        container:SetSize(widget.contentHolder:GetWidth(), widget.contentHolder:GetHeight())
        container:SetRenderer(function(built)
            tab.info.panelFunction(built)
            built:DoLayout()
        end)
        container:Rerender()
        tab.container = container
    end

    tab.container:Show()
end

---Highlight the text and indicator bar of the selected tab and reset every other one
local function RefreshTabAppearance(widget)
    for i, tab in ipairs(widget.tabs) do
        if tab.row and tab.row.text then
            if i == widget.selectedIndex then
                tab.row.text:SetTextColor(unpack(addon.UICore:GetHighlightColor()))
                tab.row.indicator:Show()
            else
                tab.row.text:SetTextColor(unpack(addon.UICore:GetNormalTextColor()))
                tab.row.indicator:Hide()
            end
        end
    end
end

-- MARK: API
function VerticalTabGroup:SetParent(parent)
    self.frame:SetParent(parent)
end

function VerticalTabGroup:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    self.frame:ClearAllPoints()
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function VerticalTabGroup:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function VerticalTabGroup:Show()
    self.frame:Show()
end

function VerticalTabGroup:Hide()
    self.frame:Hide()
end

---The sidebar spans the full height, the content area is inset from the top (e.g. for a toolbar above it)
function VerticalTabGroup:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    self.frame:SetSize(width, height)
    self.sidebar:SetSize(self.sidebarWidth, height)

    local contentWidth = width - self.sidebarWidth
    local contentHeight = height - self.contentTopInset
    self.contentHolder:SetSize(contentWidth, contentHeight)

    for _, tab in ipairs(self.tabs) do
        if tab.container then
            tab.container:SetSize(contentWidth, contentHeight)
        end
    end
end

function VerticalTabGroup:GetWidth()
    return self.frame:GetWidth()
end

function VerticalTabGroup:GetHeight()
    return self.frame:GetHeight()
end

---Reserve space on the left for the tab buttons, defaults to 155
function VerticalTabGroup:SetSidebarWidth(width)
    self.sidebarWidth = width or DEFAULT_SIDEBAR_WIDTH
    self:SetSize(self.frame:GetWidth(), self.frame:GetHeight())
end

---Reserve space above the content area, e.g. for a toolbar drawn on top of it
function VerticalTabGroup:SetContentTopInset(inset)
    self.contentTopInset = inset or 0
    self:SetSize(self.frame:GetWidth(), self.frame:GetHeight())
end

---Show the content panel of the given tab and highlight its button
---@param index number the index into the list passed to SetTabs
function VerticalTabGroup:SelectTab(index)
    local tab = self.tabs[index]
    if not tab or not tab.info.panelFunction then return end

    local previous = self.selectedIndex and self.tabs[self.selectedIndex]
    if previous and previous.container then
        previous.container:Hide()
    end

    self.selectedIndex = index
    ShowTabContent(self, tab)
    RefreshTabAppearance(self)

    if self.onTabSelected then
        self.onTabSelected(tab.info, index)
    end
end

function VerticalTabGroup:GetSelectedIndex()
    return self.selectedIndex
end

function VerticalTabGroup:SetOnTabSelected(callback)
    self.onTabSelected = callback
end

---Recycle every per-tab content panel that was built, and hide the sidebar rows
function VerticalTabGroup:ClearTabs()
    for _, tab in ipairs(self.tabs) do
        if tab.container then
            addon.UICore:ReleaseToPool(tab.container)
        end
        if tab.row then
            if tab.row.button then
                tab.row.button:Hide()
            else
                tab.row.separator:Hide()
                tab.row.title:Hide()
            end
        end
    end

    self.tabs = {}
    self.selectedIndex = nil
end

---Fill the sidebar with tab buttons and section titles, and select the first selectable tab
---@param tabList table an ordered list of {text, type = "Button"|"Text", tooltip, panelFunction}
---@param defaultIndex number? the tab to select once built, defaults to the first selectable tab
function VerticalTabGroup:SetTabs(tabList, defaultIndex)
    self:ClearTabs()

    local container = self.sidebar.container
    local y = 0
    local firstSelectable = nil

    for i, info in ipairs(tabList) do
        local tab = { info = info }

        if info.type == "Button" then
            tab.row = CreateTabButtonRow(self, container, y, info, i)
            firstSelectable = firstSelectable or i
        else
            tab.row = CreateSectionRow(container, y, info)
        end

        y = y + tab.row.height + ROW_SPACING
        self.tabs[i] = tab
    end

    -- the sidebar rows are stacked manually instead of through AddWidget, so the scroll range is refreshed by hand
    container:SetHeight(math.max(1, y))
    self.sidebar:SetSize(self.sidebar.frame:GetWidth(), self.sidebar.frame:GetHeight())

    self:SelectTab(defaultIndex or firstSelectable)
end

function VerticalTabGroup:Release()
    self.onTabSelected = nil
    self:ClearTabs()
    self:SetSidebarWidth()
    self:SetContentTopInset()
    self:SetSize()
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function VerticalTabGroup:Create(parent, width, height)
    local widget = setmetatable({}, { __index = VerticalTabGroup })

    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    local frame = CreateFrame("Frame", nil, parent)
    frame:Hide()
    frame.obj = widget
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)

    local sidebar = addon.UICore:Build("ScrollFrame")
    sidebar:SetParent(frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    sidebar:Show()

    -- a plain frame, not a pooled widget: it only anchors the per-tab ScrollFrames built on demand
    local contentHolder = CreateFrame("Frame", nil, frame)
    contentHolder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    widget.frame = frame
    widget.sidebar = sidebar
    widget.contentHolder = contentHolder
    widget.tabs = {}
    widget.selectedIndex = nil
    widget.sidebarWidth = DEFAULT_SIDEBAR_WIDTH
    widget.contentTopInset = 0
    widget.type = VerticalTabGroup.type

    widget:SetSize(width, height)

    return widget
end

function VerticalTabGroup:Reuse(parent, width, height)
    self.frame:SetParent(parent)
    self:SetSize(width, height)
    return self
end

addon.UICore:RegisterWidget(VerticalTabGroup)
