local addon = select(2, ...)

---@class ToggleBox
---@field type string widget type
---@field frame Frame the container frame, sized like every other widget
---@field button Button the clickable row, vertically centered inside the container
---@field box Frame the square check box on the left
---@field toggleOverlay Texture the fill shown while the value is true
---@field text FontString the text of the toggle box
local ToggleBox = {
    type = "ToggleBox",
    frame = nil,
    button = nil,
    box = nil,
    toggleOverlay = nil,
    text = nil,
    value = false,
}

-- MARK: Default values
local BUTTON_SIZE = 16
local PADDING = 4
local OVERLAY_MARGIN = 4
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 38
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
    -- the check box is a fixed square on the left, the text takes the rest of the row
    return width - BUTTON_SIZE - PADDING, ROW_HEIGHT
end

function ToggleBox:SetParent(parent)
    self.frame:SetParent(parent)
end

function ToggleBox:SetText(text)
    self.text:SetText(text)
end

function ToggleBox:SetFontSize(size)
    self.text:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
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
    if self.value then
        self.toggleOverlay:Show()
    else
        self.toggleOverlay:Hide()
    end
end

function ToggleBox:GetValue()
    return self.value
end

function ToggleBox:SetDisabled(disabled)
    self.disabled = disabled and true or false

    if self.disabled then
        self.button:Disable()
        self.text:SetTextColor(0.5, 0.5, 0.5, 1)
        self.toggleOverlay:SetVertexColor(0.5, 0.5, 0.5, 1)
    else
        self.button:Enable()
        self.text:SetTextColor(1, 1, 1, 1)
        self.toggleOverlay:SetVertexColor(1, 1, 1, 1)
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

    -- the check box itself is a fixed square, centered on the row
    local box = CreateFrame("Frame", nil, button, "BackdropTemplate")
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, tileSize = 1, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    box:SetBackdropColor(0, 0, 0, 0.5)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    box:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    box:SetPoint("LEFT", button, "LEFT", 0, 0)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetText(buttonText or "")
    text:SetPoint("LEFT", box, "RIGHT", PADDING, 0)
    text:SetJustifyH("LEFT")
    text:SetSize(GetTextSize(width or DEFAULT_WIDTH))

    local toggleOverlay = box:CreateTexture(nil, "OVERLAY")
    toggleOverlay:SetSize(BUTTON_SIZE - OVERLAY_MARGIN, BUTTON_SIZE - OVERLAY_MARGIN)
    toggleOverlay:SetPoint("CENTER", box, "CENTER", 0, 0)
    toggleOverlay:SetColorTexture(1, 1, 1, 1) -- white overlay

    widget.frame = frame
    widget.button = button
    widget.box = box
    widget.text = text
    widget.toggleOverlay = toggleOverlay
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