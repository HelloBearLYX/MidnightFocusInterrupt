local addon = select(2, ...)

---@class MultiLineEditBox
---@field type string widget type
---@field frame Frame the container frame
---@field label FontString the label above the input
---@field editBox EditBox the multi line input
---@field button Button the accept button which commits the text
local MultiLineEditBox = {
    type = "MultiLineEditBox",
    frame = nil,
    label = nil,
    editBox = nil,
    button = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 140
local LABEL_HEIGHT = 14
local BUTTON_WIDTH = 60
local BUTTON_HEIGHT = 20
local PADDING = 4
local TEXT_INSET = 6
local SCROLL_STEP = 20

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

-- MARK: Helpers

local function SetDirty(widget, dirty)
    widget.dirty = dirty
    if dirty then
        widget.button:Show()
    else
        widget.button:Hide()
    end
end

local function Commit(widget)
    local text = widget.editBox:GetText()
    widget.text = text
    SetDirty(widget, false)
    widget.editBox:ClearFocus()

    if widget.onEnterPressed then
        widget.onEnterPressed(widget, text)
    end
end

-- MARK: Script handlers
local function EditBox_OnTextChanged(frame, userInput)
    local widget = frame.obj
    if not userInput then return end

    SetDirty(widget, frame:GetText() ~= widget.text)

    if widget.onTextChanged then
        widget.onTextChanged(widget, frame:GetText())
    end
end

local function EditBox_OnEscapePressed(frame)
    local widget = frame.obj
    frame:ClearFocus()
    frame:SetText(widget.text or "")
    SetDirty(widget, false)
end

local function Scroll_OnMouseWheel(frame, delta)
    local current = frame:GetVerticalScroll()
    local range = frame:GetVerticalScrollRange()
    frame:SetVerticalScroll(math.max(0, math.min(range, current - delta * SCROLL_STEP)))
end

local function Scroll_OnMouseDown(frame)
    frame.obj.editBox:SetFocus()
end

local function Button_OnClick(frame)
    PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
    Commit(frame.obj)
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
function MultiLineEditBox:SetParent(parent)
    self.frame:SetParent(parent)
end

function MultiLineEditBox:SetLabel(text)
    self.label:SetText(text or "")
end

function MultiLineEditBox:SetFontSize(size)
    self.label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    self.editBox:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "")
end

function MultiLineEditBox:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function MultiLineEditBox:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    self.frame:SetSize(width, height)
    self.label:SetSize(width, LABEL_HEIGHT)
    self.scroll:SetSize(width, height - LABEL_HEIGHT - BUTTON_HEIGHT - PADDING * 3)
    self.editBox:SetWidth(width - TEXT_INSET * 2)
end

function MultiLineEditBox:GetWidth()
    return self.frame:GetWidth()
end

function MultiLineEditBox:GetHeight()
    return self.frame:GetHeight()
end

function MultiLineEditBox:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function MultiLineEditBox:Show()
    self.frame:Show()
end

function MultiLineEditBox:Hide()
    self.frame:Hide()
end

function MultiLineEditBox:SetText(text)
    self.text = text or ""
    self.editBox:SetText(self.text)
    self.editBox:SetCursorPosition(0)
    self.scroll:SetVerticalScroll(0)
    SetDirty(self, false)
end

function MultiLineEditBox:GetText()
    return self.editBox:GetText()
end

function MultiLineEditBox:HighlightText()
    self.editBox:SetFocus()
    self.editBox:HighlightText()
end

function MultiLineEditBox:SetDisabled(disabled)
    self.disabled = disabled and true or false

    if self.disabled then
        self.editBox:EnableMouse(false)
        self.editBox:ClearFocus()
        self.editBox:SetTextColor(0.5, 0.5, 0.5, 1)
        self.label:SetTextColor(0.5, 0.5, 0.5, 1)
    else
        self.editBox:EnableMouse(true)
        self.editBox:SetTextColor(1, 1, 1, 1)
        self.label:SetTextColor(1, 1, 1, 1)
    end
end

function MultiLineEditBox:SetOnEnterPressed(callback)
    self.onEnterPressed = callback
end

function MultiLineEditBox:SetOnTextChanged(callback)
    self.onTextChanged = callback
end

function MultiLineEditBox:SetOnEnter(callback)
    self.onEnter = callback
end

function MultiLineEditBox:SetOnLeave(callback)
    self.onLeave = callback
end

function MultiLineEditBox:Release()
    self.onEnterPressed = nil
    self.onTextChanged = nil
    self.onEnter = nil
    self.onLeave = nil
    self.editBox:ClearFocus()
    self:SetDisabled(false)
    self:SetText("")
    self:SetSize()
    self:SetLabel("")
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function MultiLineEditBox:Create(parent, width, height, labelText, text)
    local widget = setmetatable({}, { __index = MultiLineEditBox })

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

    local scroll = CreateFrame("ScrollFrame", nil, frame, "BackdropTemplate")
    scroll:SetBackdrop(BACKDROP)
    scroll:SetBackdropColor(0, 0, 0, 0.5)
    scroll:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    scroll:SetSize(width, height - LABEL_HEIGHT - BUTTON_HEIGHT - PADDING * 3)
    scroll:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -PADDING)
    scroll:EnableMouse(true)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", Scroll_OnMouseWheel)
    scroll:SetScript("OnMouseDown", Scroll_OnMouseDown)
    scroll.obj = widget

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetJustifyH("LEFT")
    editBox:SetWidth(width - TEXT_INSET * 2)
    editBox:SetTextInsets(TEXT_INSET, TEXT_INSET, TEXT_INSET, TEXT_INSET)
    editBox:SetScript("OnTextChanged", EditBox_OnTextChanged)
    editBox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
    editBox:SetScript("OnEnter", Control_OnEnter)
    editBox:SetScript("OnLeave", Control_OnLeave)
    editBox.obj = widget
    scroll:SetScrollChild(editBox)

    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button:SetBackdrop(BACKDROP)
    button:SetBackdropColor(0, 0, 0, 0.5)
    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    button:SetPoint("TOPRIGHT", scroll, "BOTTOMRIGHT", 0, -PADDING)
    button:SetScript("OnClick", Button_OnClick)
    button:Hide()
    button.obj = widget

    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    buttonText:SetTextColor(1, 1, 1, 1)
    buttonText:SetText(ACCEPT or "Accept")
    buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text = buttonText

    addon.UICore:BuildHover(button)

    widget.frame = frame
    widget.label = label
    widget.scroll = scroll
    widget.editBox = editBox
    widget.button = button
    widget.type = MultiLineEditBox.type

    widget:SetText(text or "")

    return widget
end

function MultiLineEditBox:Reuse(parent, width, height, labelText, text)
    self.frame:SetParent(parent)
    self:SetLabel(labelText or "")
    self:SetSize(width, height)
    self:SetText(text or "")
    return self
end

addon.UICore:RegisterWidget(MultiLineEditBox)
