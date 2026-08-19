local addon = select(2, ...)

---@class TextButton
---@field type string widget type
---@field frame Frame the container frame, sized like every other widget
---@field button Button|BackdropTemplate the clickable row, vertically centered inside the container
---@field text FontString the text of the button
local TextButton = {
    type = "TextButton",
    frame = nil,
    button = nil,
    text = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 38
local ROW_HEIGHT = 20

-- MARK: Script handlers
local function  Button_OnClick(frame, ...)
    PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
    local widget = frame.obj
    if widget.onClick then
        widget.onClick(widget, ...)
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

function TextButton:SetParent(parent)
    self.frame:SetParent(parent)
end

function TextButton:SetText(text)
    self.text:SetText(text)
end

function TextButton:SetFontSize(size)
    self.text:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
end

function TextButton:SetColor(r, g, b, a)
    self.button:SetBackdropColor(r or 0, g or 0, b or 0, a or 0.5)
end

function TextButton:SetDisabled(disabled)
    self.disabled = disabled and true or false

    if self.disabled then
        self.button:Disable()
        self.text:SetTextColor(0.5, 0.5, 0.5, 1)
    else
        self.button:Enable()
        self.text:SetTextColor(1, 1, 1, 1)
    end
end

function TextButton:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function TextButton:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    self.frame:SetSize(width, height)
    self.button:SetSize(width, ROW_HEIGHT)
    self.text:SetSize(width, ROW_HEIGHT)
end

function TextButton:GetWidth()
    return self.frame:GetWidth()
end

function TextButton:GetHeight()
    return self.frame:GetHeight()
end

function TextButton:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function TextButton:Show()
    self.frame:Show()
end

function TextButton:Hide()
    self.frame:Hide()
end

function TextButton:SetOnClick(callback)
    self.onClick = callback
end

function TextButton:SetOnEnter(callback)
    self.onEnter = callback
end

function TextButton:SetOnLeave(callback)
    self.onLeave = callback
end

function TextButton:Release()
    self.onClick = nil
    self.onEnter = nil
    self.onLeave = nil
    self:SetDisabled(false)
    self:SetColor() -- reset to the default backdrop
    self:SetSize() -- reset to default size
    self:SetText("") -- reset text
    self:SetPosition() -- reset position
    self.frame:SetParent(nil) -- remove parent
    self.frame:Hide() -- hide the frame
end

-- MARK: Build
function TextButton:Create(parent, width, height, buttonText)
    local widget = setmetatable({}, { __index = TextButton })

    local frame = CreateFrame("Frame", nil, parent)
    frame:Hide()
    frame.obj = widget
    frame:SetSize(width or DEFAULT_WIDTH, height or DEFAULT_HEIGHT)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)

    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button.obj = widget

    -- background and border
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, tileSize = 1, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    button:SetBackdropColor(0, 0, 0, 0.5)
    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    -- behavior
    button:EnableMouse(true)
    button:SetScript("OnClick", Button_OnClick)
    button:SetScript("OnEnter", Control_OnEnter)
    button:SetScript("OnLeave", Control_OnLeave)
    -- size and position
    button:SetSize(width or DEFAULT_WIDTH, ROW_HEIGHT)
    button:SetPoint("CENTER", frame, "CENTER", 0, 0)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetText(buttonText or "")
    text:SetPoint("CENTER", button, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetSize(width or DEFAULT_WIDTH, ROW_HEIGHT)

    widget.frame = frame
    widget.button = button
    widget.text = text
    widget.type = TextButton.type

    return widget
end

function TextButton:Reuse(parent, width, height, buttonText, fontSize)
    self.frame:SetParent(parent)
    self:SetText(buttonText or "")
    self:SetFontSize(fontSize or 12)
    self:SetSize(width or DEFAULT_WIDTH, height or DEFAULT_HEIGHT)
    return self
end

addon.UICore:RegisterWidget(TextButton)