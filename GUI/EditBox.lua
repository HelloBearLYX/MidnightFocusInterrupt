local addon = select(2, ...)

---@class EditBox
---@field type string widget type
---@field frame Frame the container frame of the edit box
---@field label FontString the label above the input field
---@field editBox EditBox the input field
---@field button Button the accept button which commits the text
local EditBox = {
    type = "EditBox",
    frame = nil,
    label = nil,
    editBox = nil,
    button = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 38
local LABEL_HEIGHT = 14
local CONTROL_HEIGHT = 20
local BUTTON_WIDTH = 40
local PADDING = 4
local TEXT_INSET = 6

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

-- MARK: Helpers

---Show or hide the accept button depending on whether the text is dirty
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

local function EditBox_OnEnterPressed(frame)
    Commit(frame.obj)
end

local function EditBox_OnEscapePressed(frame)
    local widget = frame.obj
    frame:ClearFocus()
    frame:SetText(widget.text or "")
    SetDirty(widget, false)
end

local function EditBox_OnEditFocusGained(frame)
    frame:HighlightText()
end

local function EditBox_OnEditFocusLost(frame)
    frame:HighlightText(0, 0)
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
function EditBox:SetParent(parent)
    self.frame:SetParent(parent)
end

function EditBox:SetLabel(text)
    self.label:SetText(text or "")
end

function EditBox:SetFontSize(size)
    self.label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    self.editBox:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    self.button.text:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
end

function EditBox:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function EditBox:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    self.frame:SetSize(width, height)
    self.label:SetSize(width, LABEL_HEIGHT)
    self.editBox:SetSize(width - BUTTON_WIDTH - PADDING, height - LABEL_HEIGHT - PADDING)
    self.button:SetSize(BUTTON_WIDTH, CONTROL_HEIGHT)
end

function EditBox:GetWidth()
    return self.frame:GetWidth()
end

function EditBox:GetHeight()
    return self.frame:GetHeight()
end

function EditBox:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function EditBox:Show()
    self.frame:Show()
end

function EditBox:Hide()
    self.frame:Hide()
end

function EditBox:SetText(text)
    self.text = text or ""
    self.editBox:SetText(self.text)
    self.editBox:SetCursorPosition(0)
    SetDirty(self, false)
end

function EditBox:GetText()
    return self.editBox:GetText()
end

function EditBox:SetMaxLetters(count)
    self.editBox:SetMaxLetters(count or 0)
end

function EditBox:SetDisabled(disabled)
    self.disabled = disabled
    if disabled then
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

function EditBox:SetOnEnterPressed(callback)
    self.onEnterPressed = callback
end

function EditBox:SetOnTextChanged(callback)
    self.onTextChanged = callback
end

function EditBox:SetOnEnter(callback)
    self.onEnter = callback
end

function EditBox:SetOnLeave(callback)
    self.onLeave = callback
end

function EditBox:Release()
    self.onEnterPressed = nil
    self.onTextChanged = nil
    self.onEnter = nil
    self.onLeave = nil
    self.editBox:ClearFocus()
    self:SetDisabled(false)
    self:SetMaxLetters(0)
    self:SetText("")
    self:SetSize()
    self:SetLabel("")
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function EditBox:Create(parent, width, height, labelText, text)
    local widget = setmetatable({}, { __index = EditBox })

    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    local frame = CreateFrame("Frame", nil, parent)
    frame:Hide()
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    frame.obj = widget

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(labelText or "")
    label:SetJustifyH("LEFT")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetSize(width, LABEL_HEIGHT)

    local editBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    editBox:SetBackdrop(BACKDROP)
    editBox:SetBackdropColor(0, 0, 0, 0.5)
    editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetTextInsets(TEXT_INSET, TEXT_INSET, 0, 0)
    editBox:SetJustifyH("LEFT")
    editBox:SetAutoFocus(false)
    editBox:SetSize(width - BUTTON_WIDTH - PADDING, height - LABEL_HEIGHT - PADDING)
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -PADDING)
    editBox.obj = widget

    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button:SetBackdrop(BACKDROP)
    button:SetBackdropColor(0, 0, 0, 0.5)
    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    button:SetSize(BUTTON_WIDTH, CONTROL_HEIGHT)
    button:SetPoint("LEFT", editBox, "RIGHT", PADDING, 0)
    button:Hide()
    button.obj = widget

    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    buttonText:SetTextColor(1, 1, 1, 1)
    buttonText:SetText(OKAY or "OK")
    buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text = buttonText

    addon.UICore:BuildHover(button)

    editBox:SetScript("OnTextChanged", EditBox_OnTextChanged)
    editBox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
    editBox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
    editBox:SetScript("OnEditFocusGained", EditBox_OnEditFocusGained)
    editBox:SetScript("OnEditFocusLost", EditBox_OnEditFocusLost)
    editBox:SetScript("OnEnter", Control_OnEnter)
    editBox:SetScript("OnLeave", Control_OnLeave)
    button:SetScript("OnClick", Button_OnClick)

    widget.frame = frame
    widget.label = label
    widget.editBox = editBox
    widget.button = button
    widget.type = EditBox.type

    widget:SetText(text or "")

    return widget
end

function EditBox:Reuse(parent, width, height, labelText, text)
    self.frame:SetParent(parent)
    self:SetLabel(labelText or "")
    self:SetSize(width, height)
    self:SetText(text or "")
    return self
end

addon.UICore:RegisterWidget(EditBox)
