local addon = select(2, ...)

---@class InfoContainer
---@field type string widget type
---@field frame Frame the container frame
---@field label FontString the first line, read-only
---@field content FontString the second line, read-only
local InfoContainer = {
    type = "InfoContainer",
    frame = nil,
    label = nil,
    content = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_FONT_SIZE = 12
local LINE_SPACING = 2
local PADDING = 4
local INSET = 6

-- MARK: Helpers

---Two fixed lines: the height only depends on the font size
local function UpdateLayout(widget)
    local frame = widget.frame
    local textWidth = math.max((frame:GetWidth() or 0) - 2 * INSET, 1)
    widget.label:SetWidth(textWidth)
    widget.content:SetWidth(textWidth)

    local lineHeight = widget.fontSize + LINE_SPACING
    widget.label:SetHeight(lineHeight)
    widget.content:SetHeight(lineHeight)
    frame:SetHeight(2 * INSET + 2 * lineHeight + PADDING)
end

---Run the callback and show what it returns
local function Refresh(widget)
    if not widget.callback then return end
    local label, content, tooltip = widget.callback(widget)
    if label ~= nil then widget:SetLabel(label) end
    if content ~= nil then widget:SetContent(content) end
    if tooltip ~= nil then widget:SetTooltip(tooltip) end
end

-- MARK: Script handlers
local function Frame_OnEnter(frame)
    local tooltip = frame.obj.tooltip
    if not tooltip or tooltip == "" then return end
    GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
    GameTooltip:Show()
end

local function Frame_OnLeave()
    GameTooltip:Hide()
end

-- MARK: API
function InfoContainer:SetParent(parent)
    self.frame:SetParent(parent)
end

function InfoContainer:SetLabel(text)
    self.label:SetText(text or "")
end

function InfoContainer:SetContent(text)
    self.content:SetText(text or "")
end

function InfoContainer:GetContent()
    return self.content:GetText()
end

---Set the text shown in a tooltip while hovering the widget, empty or nil disables it
function InfoContainer:SetTooltip(text)
    self.tooltip = text
    self.frame:EnableMouse(text ~= nil and text ~= "")
end

---Set the callback which provides the information, it is called right away and returns label, content, tooltip.
---Any return value may be nil to keep the current text.
---@param callback fun(widget: InfoContainer): string?, string?, string?
function InfoContainer:SetCallback(callback)
    self.callback = callback
    Refresh(self)
end

function InfoContainer:Refresh()
    Refresh(self)
end

---Also adjusts the height, which is fixed by the two lines
function InfoContainer:SetFontSize(size)
    self.fontSize = size or DEFAULT_FONT_SIZE
    self.label:SetFont(addon.UICore:GetDefaultFont(), self.fontSize, "OUTLINE")
    self.content:SetFont(addon.UICore:GetDefaultFont(), self.fontSize, "OUTLINE")
    UpdateLayout(self)
end

function InfoContainer:SetWidth(width)
    self.frame:SetWidth(width or DEFAULT_WIDTH)
    UpdateLayout(self)
end

function InfoContainer:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function InfoContainer:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function InfoContainer:GetWidth()
    return self.frame:GetWidth()
end

function InfoContainer:GetHeight()
    return self.frame:GetHeight()
end

function InfoContainer:Show()
    self.frame:Show()
end

function InfoContainer:Hide()
    self.frame:Hide()
end

function InfoContainer:Release()
    self.callback = nil
    self:SetFontSize()
    self:SetLabel("")
    self:SetContent("")
    self:SetTooltip(nil)
    self:SetWidth()
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function InfoContainer:Create(parent, width, labelText, contentText)
    local widget = setmetatable({}, { __index = InfoContainer })
    widget.fontSize = DEFAULT_FONT_SIZE

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:Hide()
    frame:SetBackdrop(addon.UICore:GetDefaultBackdrop())
    addon.UICore:SetBackdropColor(frame)
    addon.UICore:SetBorderColor(frame)
    frame:SetWidth(width or DEFAULT_WIDTH)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)
    frame.obj = widget

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(addon.UICore:GetDefaultFont(), DEFAULT_FONT_SIZE, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", INSET, -INSET)
    label:SetText(labelText or "")

    local content = frame:CreateFontString(nil, "OVERLAY")
    content:SetFont(addon.UICore:GetDefaultFont(), DEFAULT_FONT_SIZE, "OUTLINE")
    content:SetTextColor(unpack(addon.UICore:GetHighlightColor()))
    content:SetJustifyH("LEFT")
    content:SetWordWrap(false)
    content:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -PADDING)
    content:SetText(contentText or "")

    frame:SetScript("OnEnter", Frame_OnEnter)
    frame:SetScript("OnLeave", Frame_OnLeave)
    frame:EnableMouse(false)

    widget.frame = frame
    widget.label = label
    widget.content = content
    widget.type = InfoContainer.type

    UpdateLayout(widget)

    return widget
end

function InfoContainer:Reuse(parent, width, labelText, contentText)
    self:SetParent(parent)
    self:SetWidth(width)
    self:SetLabel(labelText or "")
    self:SetContent(contentText or "")
    return self
end

addon.UICore:RegisterWidget(InfoContainer)
