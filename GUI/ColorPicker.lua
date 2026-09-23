local addon = select(2, ...)

---@class ColorPicker
---@field type string widget type
---@field frame Frame the container frame, sized like every other widget
---@field button Button the clickable row, vertically centered inside the container
---@field swatchBox Frame the bordered box on the left which previews the color and opens the picker
---@field swatch Texture the color preview inside the swatch box
---@field label FontString the label to the right of the swatch box
local ColorPicker = {
    type = "ColorPicker",
    frame = nil,
    button = nil,
    swatchBox = nil,
    swatch = nil,
    label = nil,
}

-- MARK: Default values
local SWATCH_WIDTH = 32
local SWATCH_HEIGHT = 16
local SWATCH_INSET = 1
local PADDING = 4
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 40
local ROW_HEIGHT = 20

local function GetLabelSize(width)
    -- the swatch box is a fixed size on the left, the label takes the rest of the row
    return width - SWATCH_WIDTH - PADDING, ROW_HEIGHT
end

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
    if frame.obj.disabled then return end
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
    self.label:SetFont(addon.UICore:GetDefaultFont(), size or 12, "OUTLINE")
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
    self.button:SetSize(width, ROW_HEIGHT)
    self.label:SetSize(GetLabelSize(width))
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
    self.swatch:SetColorTexture(self.r, self.g, self.b, self.hasAlpha and self.a or 1)
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
    self.label:SetTextColor(unpack(self.disabled and addon.UICore:GetDisabledTextColor() or addon.UICore:GetNormalTextColor()))
    self.swatch:SetAlpha(self.disabled and 0.45 or 1)
    addon.UICore:SetBorderColor(self.swatchBox, self.disabled and addon.UICore:GetDisabledTextColor() or nil)

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

    local button = CreateFrame("Button", nil, frame)
    button.obj = widget

    -- behavior
    button:EnableMouse(true)
    button:SetScript("OnClick", Button_OnClick)
    button:SetScript("OnEnter", Control_OnEnter)
    button:SetScript("OnLeave", Control_OnLeave)
    -- size and position
    button:SetSize(width, ROW_HEIGHT)
    button:SetPoint("LEFT", frame, "LEFT", 0, 0)

    -- the swatch box is the fixed color preview button, centered on the row
    local swatchBox = CreateFrame("Frame", nil, button, "BackdropTemplate")
    swatchBox:SetBackdrop(addon.UICore:GetDefaultBackdrop())
    addon.UICore:SetBackdropColor(swatchBox)
    addon.UICore:SetBorderColor(swatchBox)
    swatchBox:SetSize(SWATCH_WIDTH, SWATCH_HEIGHT)
    swatchBox:SetPoint("LEFT", button, "LEFT", 0, 0)

    addon.UICore:BuildHover(swatchBox)

    local swatch = swatchBox:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", swatchBox, "TOPLEFT", SWATCH_INSET, -SWATCH_INSET)
    swatch:SetPoint("BOTTOMRIGHT", swatchBox, "BOTTOMRIGHT", -SWATCH_INSET, SWATCH_INSET)

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(addon.UICore:GetDefaultFont(), 12, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(labelText or "")
    label:SetPoint("LEFT", swatchBox, "RIGHT", PADDING, 0)
    label:SetJustifyH("LEFT")
    label:SetSize(GetLabelSize(width))

    widget.frame = frame
    widget.button = button
    widget.swatchBox = swatchBox
    widget.swatch = swatch
    widget.label = label
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
