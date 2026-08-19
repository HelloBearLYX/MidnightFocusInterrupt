local addon = select(2, ...)

---@class ColorPicker
---@field type string widget type
---@field frame Frame the container frame of the color picker
---@field label FontString the label above the swatch
---@field button Button the swatch button which opens the game color picker
local ColorPicker = {
    type = "ColorPicker",
    frame = nil,
    label = nil,
    button = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 38
local LABEL_HEIGHT = 14
local CONTROL_HEIGHT = 20
local SWATCH_INSET = 3
local PADDING = 4
local DISABLED_COLOR = { 0.5, 0.5, 0.5, 1 }
local ENABLED_COLOR = { 1, 1, 1, 1 }

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

-- MARK: Helpers

local function FireChanged(widget)
    if widget.onColorChanged then
        widget.onColorChanged(widget, widget.r, widget.g, widget.b, widget.a)
    end
end

local function OpenPicker(widget)
    local r, g, b, a = widget.r, widget.g, widget.b, widget.a

    local function Apply()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        local newA = widget.hasAlpha and ColorPickerFrame:GetColorAlpha() or 1
        widget:SetColor(newR, newG, newB, newA)
        FireChanged(widget)
    end

    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b,
        opacity = a,
        hasOpacity = widget.hasAlpha,
        swatchFunc = Apply,
        opacityFunc = Apply,
        cancelFunc = function()
            widget:SetColor(r, g, b, a)
            FireChanged(widget)
        end,
    })
end

-- MARK: Script handlers
local function Button_OnClick(frame)
    PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
    OpenPicker(frame.obj)
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
function ColorPicker:SetParent(parent)
    self.frame:SetParent(parent)
end

function ColorPicker:SetLabel(text)
    self.label:SetText(text or "")
end

function ColorPicker:SetFontSize(size)
    self.label:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
end

function ColorPicker:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function ColorPicker:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    self.frame:SetSize(width, height)
    self.label:SetSize(width, LABEL_HEIGHT)
    self.button:SetSize(width, height - LABEL_HEIGHT - PADDING)
end

function ColorPicker:GetWidth()
    return self.frame:GetWidth()
end

function ColorPicker:GetHeight()
    return self.frame:GetHeight()
end

function ColorPicker:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function ColorPicker:Show()
    self.frame:Show()
end

function ColorPicker:Hide()
    self.frame:Hide()
end

function ColorPicker:SetHasAlpha(hasAlpha)
    self.hasAlpha = hasAlpha and true or false
end

function ColorPicker:SetColor(r, g, b, a)
    self.r, self.g, self.b = r or 1, g or 1, b or 1
    self.a = a or 1
    self.swatch:SetColorTexture(self.r, self.g, self.b, self.a)
end

function ColorPicker:GetColor()
    return self.r, self.g, self.b, self.a
end

---@param hex string a hex color as stored in the database
function ColorPicker:SetHexColor(hex)
    self:SetColor(addon.Utilities:HexToRGB(hex))
end

function ColorPicker:GetHexColor()
    return addon.Utilities:RGBToHex(self.r, self.g, self.b, self.a)
end

function ColorPicker:SetDisabled(disabled)
    self.disabled = disabled and true or false
    self.label:SetTextColor(unpack(self.disabled and DISABLED_COLOR or ENABLED_COLOR))

    if self.disabled then
        self.button:Disable()
    else
        self.button:Enable()
    end
end

function ColorPicker:SetOnColorChanged(callback)
    self.onColorChanged = callback
end

function ColorPicker:SetOnEnter(callback)
    self.onEnter = callback
end

function ColorPicker:SetOnLeave(callback)
    self.onLeave = callback
end

function ColorPicker:Release()
    self.onColorChanged = nil
    self.onEnter = nil
    self.onLeave = nil
    self:SetDisabled(false)
    self:SetHasAlpha(false)
    self:SetColor(1, 1, 1, 1)
    self:SetSize()
    self:SetLabel("")
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function ColorPicker:Create(parent, width, height, labelText, r, g, b, a)
    local widget = setmetatable({}, { __index = ColorPicker })

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
    button:SetScript("OnClick", Button_OnClick)
    button:SetScript("OnEnter", Control_OnEnter)
    button:SetScript("OnLeave", Control_OnLeave)
    button.obj = widget

    addon.UICore:BuildHover(button)

    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", button, "TOPLEFT", SWATCH_INSET, -SWATCH_INSET)
    swatch:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -SWATCH_INSET, SWATCH_INSET)

    widget.frame = frame
    widget.label = label
    widget.button = button
    widget.swatch = swatch
    widget.type = ColorPicker.type

    widget:SetColor(r, g, b, a)

    return widget
end

function ColorPicker:Reuse(parent, width, height, labelText, r, g, b, a)
    self.frame:SetParent(parent)
    self:SetLabel(labelText or "")
    self:SetSize(width, height)
    self:SetColor(r, g, b, a)
    return self
end

addon.UICore:RegisterWidget(ColorPicker)
