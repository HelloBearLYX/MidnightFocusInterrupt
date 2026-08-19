local addon = select(2, ...)

---@class Slider
---@field type string widget type
---@field frame Frame the container frame of the slider
---@field label FontString the label above the slider bar
---@field slider Slider the slider bar
---@field editBox EditBox the value box on the right of the slider bar
local Slider = {
    type = "Slider",
    frame = nil,
    label = nil,
    slider = nil,
    editBox = nil,
    value = 0,
    min = 0,
    max = 100,
    step = 1,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 40
local LABEL_HEIGHT = 14
local CONTROL_HEIGHT = 20
local EDITBOX_WIDTH = 50
local PADDING = 4

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

-- MARK: Helpers

---Round the value to the closest valid step within [min, max]
local function SnapValue(widget, value)
    value = tonumber(value) or widget.min
    if widget.step and widget.step > 0 then
        value = widget.min + math.floor((value - widget.min) / widget.step + 0.5) * widget.step
    end
    return math.max(widget.min, math.min(widget.max, value))
end

local function FormatValue(widget, value)
    if widget.step and widget.step < 1 then
        return string.format("%.2f", value)
    end
    return string.format("%d", value)
end

---Push the value into the widgets without firing the callback again
local function RefreshDisplay(widget)
    widget.settingValue = true
    widget.slider:SetValue(widget.value)
    widget.editBox:SetText(FormatValue(widget, widget.value))
    widget.editBox:SetCursorPosition(0)
    widget.settingValue = false
end

-- MARK: Script handlers
local function Slider_OnValueChanged(frame, value)
    local widget = frame.obj
    if widget.settingValue then return end

    local snapped = SnapValue(widget, value)
    widget.value = snapped
    RefreshDisplay(widget)

    if widget.onValueChanged then
        widget.onValueChanged(widget, snapped)
    end
end

local function Slider_OnMouseWheel(frame, delta)
    local widget = frame.obj
    widget:SetValue(widget.value + delta * (widget.step or 1))
    if widget.onValueChanged then
        widget.onValueChanged(widget, widget.value)
    end
end

local function EditBox_OnEnterPressed(frame)
    local widget = frame.obj
    widget:SetValue(frame:GetText())
    frame:ClearFocus()

    if widget.onValueChanged then
        widget.onValueChanged(widget, widget.value)
    end
end

local function EditBox_OnEscapePressed(frame)
    frame:ClearFocus()
    RefreshDisplay(frame.obj)
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
function Slider:SetParent(parent)
    self.frame:SetParent(parent)
end

function Slider:SetLabel(text)
    self.label:SetText(text or "")
end

function Slider:SetFontSize(size)
    self.label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    self.editBox:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
end

function Slider:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function Slider:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    self.frame:SetSize(width, height)
    self.label:SetSize(width, LABEL_HEIGHT)
    self.slider:SetSize(width - EDITBOX_WIDTH - PADDING, height - LABEL_HEIGHT - PADDING)
    self.editBox:SetSize(EDITBOX_WIDTH, CONTROL_HEIGHT)
end

function Slider:GetWidth()
    return self.frame:GetWidth()
end

function Slider:GetHeight()
    return self.frame:GetHeight()
end

function Slider:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function Slider:Show()
    self.frame:Show()
end

function Slider:Hide()
    self.frame:Hide()
end

---@param min number the lower bound
---@param max number the upper bound
---@param step number the granularity of the slider
function Slider:SetMinMaxValues(min, max, step)
    self.min = min or 0
    self.max = max or 100
    self.step = step or 1

    self.slider:SetMinMaxValues(self.min, self.max)
    self.slider:SetValueStep(self.step)
    self.slider:SetObeyStepOnDrag(true)
    self.lowText:SetText(FormatValue(self, self.min))
    self.highText:SetText(FormatValue(self, self.max))

    self:SetValue(self.value)
end

function Slider:SetValue(value)
    self.value = SnapValue(self, value)
    RefreshDisplay(self)
end

function Slider:GetValue()
    return self.value
end

function Slider:SetDisabled(disabled)
    self.disabled = disabled and true or false

    if self.disabled then
        self.slider:Disable()
        self.editBox:EnableMouse(false)
        self.editBox:ClearFocus()
        self.label:SetTextColor(0.5, 0.5, 0.5, 1)
        self.thumb:SetVertexColor(0.5, 0.5, 0.5, 1)
    else
        self.slider:Enable()
        self.editBox:EnableMouse(true)
        self.label:SetTextColor(1, 1, 1, 1)
        self.thumb:SetVertexColor(1, 1, 1, 1)
    end
end

function Slider:SetOnValueChanged(callback)
    self.onValueChanged = callback
end

function Slider:SetOnEnter(callback)
    self.onEnter = callback
end

function Slider:SetOnLeave(callback)
    self.onLeave = callback
end

function Slider:Release()
    self.onValueChanged = nil
    self.onEnter = nil
    self.onLeave = nil
    self:SetDisabled(false)
    self.editBox:ClearFocus()
    self:SetMinMaxValues()
    self:SetSize()
    self:SetLabel("")
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function Slider:Create(parent, width, height, labelText, min, max, step, value)
    local widget = setmetatable({}, { __index = Slider })

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

    local slider = CreateFrame("Slider", nil, frame, "BackdropTemplate")
    slider:SetBackdrop(BACKDROP)
    slider:SetBackdropColor(0, 0, 0, 0.5)
    slider:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    slider:SetOrientation("HORIZONTAL")
    slider:SetHitRectInsets(0, 0, -4, -4)
    slider:SetSize(width - EDITBOX_WIDTH - PADDING, height - LABEL_HEIGHT - PADDING)
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -PADDING)
    slider:EnableMouseWheel(true)
    slider.obj = widget

    -- the thumb is the draggable handle of the slider bar
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(1, 1, 1, 1)
    thumb:SetSize(8, CONTROL_HEIGHT - 4)
    slider:SetThumbTexture(thumb)

    local lowText = slider:CreateFontString(nil, "ARTWORK")
    lowText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    lowText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, 0)

    local highText = slider:CreateFontString(nil, "ARTWORK")
    highText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    highText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, 0)

    local editBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    editBox:SetBackdrop(BACKDROP)
    editBox:SetBackdropColor(0, 0, 0, 0.5)
    editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(false)
    editBox:SetMaxLetters(8)
    editBox:SetSize(EDITBOX_WIDTH, CONTROL_HEIGHT)
    editBox:SetPoint("LEFT", slider, "RIGHT", PADDING, 0)
    editBox.obj = widget

    slider:SetScript("OnValueChanged", Slider_OnValueChanged)
    slider:SetScript("OnMouseWheel", Slider_OnMouseWheel)
    slider:SetScript("OnEnter", Control_OnEnter)
    slider:SetScript("OnLeave", Control_OnLeave)
    editBox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
    editBox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)

    widget.frame = frame
    widget.label = label
    widget.slider = slider
    widget.thumb = thumb
    widget.lowText = lowText
    widget.highText = highText
    widget.editBox = editBox
    widget.type = Slider.type
    widget.value = value or min or 0

    widget:SetMinMaxValues(min, max, step)

    return widget
end

function Slider:Reuse(parent, width, height, labelText, min, max, step, value)
    self.frame:SetParent(parent)
    self:SetLabel(labelText or "")
    self:SetSize(width, height)
    self.value = value or min or 0
    self:SetMinMaxValues(min, max, step)
    return self
end

addon.UICore:RegisterWidget(Slider)
