local addon = select(2, ...)

---@class ToggleBox
---@field type string widget type
---@field frame Frame the container frame, sized like every other widget
---@field button Button the clickable row, vertically centered inside the container
---@field track Frame the rectangular switch track on the left
---@field accentFill Texture the fill shown across the track while the value is true
---@field knob Frame the handle that slides to either side of the track
---@field knobTex Texture the texture colored to reflect the enabled state
---@field text FontString the text of the toggle box
local ToggleBox = {
    type = "ToggleBox",
    frame = nil,
    button = nil,
    track = nil,
    accentFill = nil,
    knob = nil,
    knobTex = nil,
    text = nil,
    value = false,
}

-- MARK: Default values
local TRACK_WIDTH = 32
local TRACK_HEIGHT = 16
local KNOB_INSET = 2
local PADDING = 4
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 40
local ROW_HEIGHT = 20

-- MARK: Script handlers
local function Button_OnClick(frame, ...)
    PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
    local widget = frame.obj
    widget:SetValue(not widget.value)

    if widget.onClick then
        widget.onClick(widget, widget.value, ...)
    end
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

local function GetTextSize(width)
    -- the switch track is a fixed size on the left, the text takes the rest of the row
    return width - TRACK_WIDTH - PADDING, ROW_HEIGHT
end

---Slide the knob to match the current value and show/hide the accent fill
local function UpdateVisual(widget)
    widget.knob:ClearAllPoints()
    if widget.value then
        widget.knob:SetPoint("RIGHT", widget.track, "RIGHT", -KNOB_INSET, 0)
        widget.accentFill:Show()
    else
        widget.knob:SetPoint("LEFT", widget.track, "LEFT", KNOB_INSET, 0)
        widget.accentFill:Hide()
    end
end

function ToggleBox:SetParent(parent)
    self.frame:SetParent(parent)
end

function ToggleBox:SetText(text)
    self.text:SetText(text)
end

function ToggleBox:SetFontSize(size)
    self.text:SetFont(addon.UICore:GetDefaultFont(), size or 12, "OUTLINE")
end

function ToggleBox:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function ToggleBox:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    self.frame:SetSize(width, height)
    self.button:SetSize(width, ROW_HEIGHT)
    self.text:SetSize(GetTextSize(width))
end

function ToggleBox:GetWidth()
    return self.frame:GetWidth()
end

function ToggleBox:GetHeight()
    return self.frame:GetHeight()
end

function ToggleBox:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function ToggleBox:SetValue(value)
    self.value = value and true or false
    UpdateVisual(self)
end

function ToggleBox:GetValue()
    return self.value
end

function ToggleBox:SetDisabled(disabled)
    self.disabled = disabled and true or false

    if self.disabled then
        self.button:Disable()
        self.text:SetTextColor(unpack(addon.UICore:GetDisabledTextColor()))
        self.knobTex:SetVertexColor(unpack(addon.UICore:GetDisabledTextColor()))
        self.accentFill:SetVertexColor(unpack(addon.UICore:GetDisabledTextColor()))
    else
        self.button:Enable()
        self.text:SetTextColor(unpack(addon.UICore:GetNormalTextColor()))
        self.knobTex:SetVertexColor(unpack(addon.UICore:GetNormalTextColor()))
        self.accentFill:SetVertexColor(unpack(addon.UICore:GetHighlightColor()))
    end
end

function ToggleBox:Show()
    self.frame:Show()
end

function ToggleBox:Hide()
    self.frame:Hide()
end

function ToggleBox:SetOnClick(callback)
    self.onClick = callback
end

function ToggleBox:SetOnEnter(callback)
    self.onEnter = callback
end

function ToggleBox:SetOnLeave(callback)
    self.onLeave = callback
end

function ToggleBox:Release()
    self.onClick = nil
    self.onEnter = nil
    self.onLeave = nil
    self:SetDisabled(false)
    self:SetValue(false)
    self:SetSize() -- reset to default size
    self:SetText("") -- reset text
    self:SetPosition() -- reset position
    self.frame:SetParent(nil) -- remove parent
    self.frame:Hide() -- hide the frame
end

-- MARK: Build
function ToggleBox:Create(parent, width, height, buttonText, value)
    local widget = setmetatable({}, { __index = ToggleBox })

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:Hide()
    frame.obj = widget
    frame:SetSize(width or DEFAULT_WIDTH, height or DEFAULT_HEIGHT)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)

    local button = CreateFrame("Button", nil, frame)
    button.obj = widget

    -- behavior
    button:EnableMouse(true)
    button:SetScript("OnClick", Button_OnClick)
    button:SetScript("OnEnter", Control_OnEnter)
    button:SetScript("OnLeave", Control_OnLeave)
    -- size and position
    button:SetSize(width or DEFAULT_WIDTH, ROW_HEIGHT)
    button:SetPoint("LEFT", frame, "LEFT", 0, 0)

    -- the track is a fixed rectangular switch region, centered on the row
    local track = CreateFrame("Frame", nil, button, "BackdropTemplate")
    track:SetBackdrop(addon.UICore:GetDefaultBackdrop())
    addon.UICore:SetBackdropColor(track)
    addon.UICore:SetBorderColor(track)
    track:SetSize(TRACK_WIDTH, TRACK_HEIGHT)
    track:SetPoint("LEFT", button, "LEFT", 0, 0)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(addon.UICore:GetDefaultFont(), 12, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetText(buttonText or "")
    text:SetPoint("LEFT", track, "RIGHT", PADDING, 0)
    text:SetJustifyH("LEFT")
    text:SetSize(GetTextSize(width or DEFAULT_WIDTH))

    -- the accent fill covers the track inside the border and is only shown while the value is true
    -- base color is white so SetVertexColor (used to tint enabled/disabled) is not multiplied on top of an already-tinted texture
    local accentFill = track:CreateTexture(nil, "ARTWORK")
    accentFill:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -1)
    accentFill:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", -1, 1)
    accentFill:SetColorTexture(1, 1, 1, 1)
    accentFill:SetVertexColor(unpack(addon.UICore:GetHighlightColor()))
    accentFill:Hide()

    -- the knob slides between the left and right side of the track to indicate the value
    local knob = CreateFrame("Frame", nil, track)
    knob:SetSize(TRACK_HEIGHT - KNOB_INSET * 2, TRACK_HEIGHT - KNOB_INSET * 2)

    local knobTex = knob:CreateTexture(nil, "OVERLAY")
    knobTex:SetAllPoints()
    knobTex:SetColorTexture(1, 1, 1, 1)

    widget.frame = frame
    widget.button = button
    widget.track = track
    widget.accentFill = accentFill
    widget.knob = knob
    widget.knobTex = knobTex
    widget.text = text
    widget.type = ToggleBox.type

    widget:SetValue(value)

    return widget
end

function ToggleBox:Reuse(parent, width, height, buttonText, fontSize)
    self.frame:SetParent(parent)
    self:SetText(buttonText or "")
    self:SetFontSize(fontSize or 12)
    self:SetSize(width or DEFAULT_WIDTH, height or DEFAULT_HEIGHT)
    return self
end

addon.UICore:RegisterWidget(ToggleBox)