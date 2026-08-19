local addon = select(2, ...)

---@class Dropdown
---@field type string widget type
---@field frame Frame the container frame of the dropdown
---@field label FontString the label above the dropdown button
---@field button Button the button which displays the current selection
---@field pullout Frame the pullout frame which holds the selectable items
local Dropdown = {
    type = "Dropdown",
    frame = nil,
    label = nil,
    button = nil,
    pullout = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 38
local LABEL_HEIGHT = 14
local CONTROL_HEIGHT = 20
local ITEM_HEIGHT = 18
local PULLOUT_INSET = 2
local MAX_VISIBLE_ITEMS = 12
local SEARCH_HEIGHT = 20
local PADDING = 4
local TEXT_INSET = 6
local ARROW_SIZE = 12

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}
-- get the arrow texture from the addon assets folder, so that it works even if the default arrow texture is missing
local ARROW_FILE = addon.UICore:GetAssetDirectory() .. "Dropdown_Arrow.png"

local SELECTED_COLOR = { 1, 0.82, 0, 1 }
local NORMAL_COLOR = { 1, 1, 1, 1 }

-- MARK: Helpers

local function GetItemButton(widget, index)
    local item = widget.itemButtons[index]
    if item then return item end

    item = CreateFrame("Button", nil, widget.pullout)
    item:SetHeight(ITEM_HEIGHT)
    item:SetPoint("LEFT", widget.pullout, "LEFT", PULLOUT_INSET, 0)
    item:SetPoint("RIGHT", widget.pullout, "RIGHT", -PULLOUT_INSET, 0)

    local text = item:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetJustifyH("LEFT")
    text:SetPoint("LEFT", item, "LEFT", TEXT_INSET, 0)
    text:SetPoint("RIGHT", item, "RIGHT", -TEXT_INSET, 0)
    item.text = text

    addon.UICore:BuildHover(item)

    item:SetScript("OnClick", function(self)
        PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
        widget:OnItemClick(self.key)
    end)

    widget.itemButtons[index] = item
    widget:OnItemCreated(item)

    return item
end

local function GetSearchBox(widget)
    if widget.searchBox then return widget.searchBox end

    local searchBox = CreateFrame("EditBox", nil, widget.pullout, "BackdropTemplate")
    searchBox:SetBackdrop(BACKDROP)
    searchBox:SetBackdropColor(0, 0, 0, 0.5)
    searchBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    searchBox:SetTextInsets(TEXT_INSET, TEXT_INSET, 0, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetHeight(SEARCH_HEIGHT)
    searchBox:SetPoint("TOPLEFT", widget.pullout, "TOPLEFT", PULLOUT_INSET, -PULLOUT_INSET)
    searchBox:SetPoint("TOPRIGHT", widget.pullout, "TOPRIGHT", -PULLOUT_INSET, -PULLOUT_INSET)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function(self)
        widget.searchText = string.lower(self:GetText() or "")
        widget.offset = 0
        widget:Refresh()
    end)

    widget.searchBox = searchBox
    return searchBox
end

---Redraw the visible slice of the item list into the pullout
local function RefreshPullout(widget)
    local order = widget:GetVisibleOrder()
    local count = #order
    local visibleCount = math.min(count, MAX_VISIBLE_ITEMS)
    local maxOffset = math.max(0, count - visibleCount)
    local topInset = PULLOUT_INSET

    if widget.searchEnabled then
        GetSearchBox(widget):Show()
        topInset = topInset + SEARCH_HEIGHT + PULLOUT_INSET
    elseif widget.searchBox then
        widget.searchBox:Hide()
    end

    widget.offset = math.max(0, math.min(widget.offset, maxOffset))

    for i = 1, visibleCount do
        local key = order[i + widget.offset]
        local item = GetItemButton(widget, i)
        item.key = key
        item:SetPoint("TOP", widget.pullout, "TOP", 0, -(topInset + (i - 1) * ITEM_HEIGHT))
        item:Show()
        widget:FormatItem(item, key)
    end

    for i = visibleCount + 1, #widget.itemButtons do
        widget.itemButtons[i]:Hide()
    end

    widget.pullout:SetHeight(visibleCount * ITEM_HEIGHT + topInset + PULLOUT_INSET)
    widget.pullout:SetWidth(widget.button:GetWidth())
end

local function UpdateButtonText(widget)
    widget.buttonText:SetText(widget:GetDisplayText() or "")
end

-- MARK: Script handlers
local function Button_OnClick(frame)
    PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
    local widget = frame.obj
    if widget.pullout:IsShown() then
        widget:Close()
    else
        widget:Open()
    end
end

local function Pullout_OnMouseWheel(frame, delta)
    local widget = frame.obj
    widget.offset = widget.offset - delta
    RefreshPullout(widget)
end

local function Control_OnEnter(frame)
    local widget = frame.obj
    if widget.onEnter then
        widget.onEnter(widget)
    end
end

local function Control_OnLeave(frame)
    local widget = frame.obj
    if widget.onLeave then
        widget.onLeave(widget)
    end
end

-- MARK: API
function Dropdown:SetParent(parent)
    self.frame:SetParent(parent)
end

function Dropdown:SetLabel(text)
    self.label:SetText(text or "")
end

function Dropdown:SetFontSize(size)
    self.label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    self.buttonText:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
end

function Dropdown:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function Dropdown:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    self.frame:SetSize(width, height)
    self.label:SetSize(width, LABEL_HEIGHT)
    self.button:SetSize(width, height - LABEL_HEIGHT - PADDING)
end

function Dropdown:GetWidth()
    return self.frame:GetWidth()
end

function Dropdown:GetHeight()
    return self.frame:GetHeight()
end

function Dropdown:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function Dropdown:Show()
    self.frame:Show()
end

function Dropdown:Hide()
    self:Close()
    self.frame:Hide()
end

---@param list table<any, string> a map of value key to display text
---@param order table|nil the keys in display order, defaults to the sorted keys of the list
function Dropdown:SetList(list, order)
    self.list = list or {}

    if order then
        self.order = order
    else
        self.order = {}
        for key in pairs(self.list) do
            table.insert(self.order, key)
        end
        table.sort(self.order, function(a, b) return tostring(a) < tostring(b) end)
    end

    self.offset = 0
    UpdateButtonText(self)
end

function Dropdown:SetValue(value)
    self.value = value
    UpdateButtonText(self)
end

function Dropdown:GetValue()
    return self.value
end

-- MARK: Overridable behavior
-- the variants of the dropdown (multi select, shared media, ...) plug into these

---Called once for every item button that gets created
function Dropdown:OnItemCreated(_) end

function Dropdown:IsSelected(key)
    return self.value == key
end

function Dropdown:GetDisplayText()
    return (self.value ~= nil and self.list[self.value]) or self.placeholder or ""
end

function Dropdown:FormatItem(item, key)
    item.text:SetText(self.list[key] or tostring(key))
    item.text:SetTextColor(unpack(self:IsSelected(key) and SELECTED_COLOR or NORMAL_COLOR))
end

function Dropdown:OnItemClick(key)
    self:SetValue(key)
    self:Close()

    if self.onValueChanged then
        self.onValueChanged(self, key)
    end
end

---The keys to display, filtered by the search text when the search box is enabled
function Dropdown:GetVisibleOrder()
    if not self.searchEnabled or not self.searchText or self.searchText == "" then
        return self.order
    end

    local filtered = {}
    for _, key in ipairs(self.order) do
        local display = string.lower(tostring(self.list[key] or key))
        if display:find(self.searchText, 1, true) then
            table.insert(filtered, key)
        end
    end

    return filtered
end

---Show a search box on the top of the pullout
function Dropdown:SetSearchEnabled(enabled)
    self.searchEnabled = enabled and true or false
end

---Redraw the button text and, when it is open, the pullout
function Dropdown:Refresh()
    UpdateButtonText(self)
    if self.pullout:IsShown() then
        RefreshPullout(self)
    end
end

function Dropdown:SetPlaceholder(text)
    self.placeholder = text
    UpdateButtonText(self)
end

function Dropdown:SetDisabled(disabled)
    self.disabled = disabled and true or false

    if self.disabled then
        self:Close()
        self.button:Disable()
        self.label:SetTextColor(0.5, 0.5, 0.5, 1)
        self.buttonText:SetTextColor(0.5, 0.5, 0.5, 1)
    else
        self.button:Enable()
        self.label:SetTextColor(1, 1, 1, 1)
        self.buttonText:SetTextColor(1, 1, 1, 1)
    end
end

function Dropdown:Open()
    RefreshPullout(self)
    self.clicker:Show()
    self.pullout:ClearAllPoints()
    self.pullout:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, -PULLOUT_INSET)
    self.pullout:Show()
end

function Dropdown:Close()
    if self.searchBox then
        self.searchBox:SetText("")
        self.searchBox:ClearFocus()
    end
    self.searchText = nil
    self.pullout:Hide()
    self.clicker:Hide()
end

function Dropdown:SetOnValueChanged(callback)
    self.onValueChanged = callback
end

function Dropdown:SetOnEnter(callback)
    self.onEnter = callback
end

function Dropdown:SetOnLeave(callback)
    self.onLeave = callback
end

function Dropdown:Release()
    self.onValueChanged = nil
    self.onEnter = nil
    self.onLeave = nil
    self:Close()
    self:SetDisabled(false)
    self:SetSearchEnabled(false)
    self.value = nil
    self.placeholder = nil
    self:SetList({})
    self:SetSize()
    self:SetLabel("")
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function Dropdown:Create(parent, width, height, labelText, list, order, value)
    -- self is the class, so the variants of the dropdown inherit this constructor
    local widget = setmetatable({}, { __index = self })

    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    local frame = CreateFrame("Frame", nil, parent)
    frame:Hide()
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)
    frame.obj = widget

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(labelText or "")
    label:SetJustifyH("LEFT")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetSize(width, LABEL_HEIGHT)

    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button:SetBackdrop(BACKDROP)
    button:SetBackdropColor(0, 0, 0, 0.5)
    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    button:SetSize(width, height - LABEL_HEIGHT - PADDING)
    button:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -PADDING)
    button.obj = widget

    addon.UICore:BuildHover(button)

    local arrow = button:CreateTexture(nil, "OVERLAY")
    -- instead of using the default arrow texture, we use a backdrop with a V text on it
    arrow:SetTexture(ARROW_FILE) -- "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up"
    arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow:SetPoint("RIGHT", button, "RIGHT", -PADDING, 0)

    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    buttonText:SetTextColor(1, 1, 1, 1)
    buttonText:SetJustifyH("LEFT")
    buttonText:SetPoint("LEFT", button, "LEFT", TEXT_INSET, 0)
    buttonText:SetPoint("RIGHT", arrow, "LEFT", -PADDING, 0)

    -- the clicker catches the clicks outside of the pullout so that the pullout can be dismissed
    local clicker = CreateFrame("Frame", nil, UIParent)
    clicker:SetAllPoints(UIParent)
    clicker:SetFrameStrata("FULLSCREEN_DIALOG")
    clicker:EnableMouse(true)
    clicker:Hide()
    clicker:SetScript("OnMouseDown", function() widget:Close() end)

    local pullout = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    pullout:SetBackdrop(BACKDROP)
    pullout:SetBackdropColor(0, 0, 0, 0.9)
    pullout:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    pullout:SetFrameStrata("FULLSCREEN_DIALOG")
    pullout:SetFrameLevel(clicker:GetFrameLevel() + 10)
    pullout:SetClampedToScreen(true)
    pullout:EnableMouse(true)
    pullout:EnableMouseWheel(true)
    pullout:Hide()
    pullout.obj = widget

    button:SetScript("OnClick", Button_OnClick)
    button:SetScript("OnEnter", Control_OnEnter)
    button:SetScript("OnLeave", Control_OnLeave)
    pullout:SetScript("OnMouseWheel", Pullout_OnMouseWheel)

    widget.frame = frame
    widget.label = label
    widget.button = button
    widget.buttonText = buttonText
    widget.arrow = arrow
    widget.pullout = pullout
    widget.clicker = clicker
    widget.itemButtons = {}
    widget.offset = 0
    widget.type = self.type

    widget:SetList(list or {}, order)
    widget:SetValue(value)

    return widget
end

function Dropdown:Reuse(parent, width, height, labelText, list, order, value)
    self.frame:SetParent(parent)
    self:SetLabel(labelText or "")
    self:SetSize(width, height)
    self:SetList(list or {}, order)
    self:SetValue(value)
    return self
end

addon.UICore:RegisterWidget(Dropdown)
