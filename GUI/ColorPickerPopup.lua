local addon = select(2, ...)

---@class ColorPickerPopup
---@field frame Frame the popup frame, built once when the GUI loads
local ColorPickerPopup = {
    frame = nil,
}

-- MARK: Default values
local PAD = 16
local TITLE_HEIGHT = 24
local TOP_PAD = 4
local SV_SIZE = 200
local BAR_WIDTH = 18
local GAP = 10
local RIGHT_WIDTH = 72
local PREVIEW_HEIGHT = 18
local INPUT_HEIGHT = 22
local BUTTON_HEIGHT = 20
local SWATCH_INSET = 1
local PRESET_SIZE = 18
local PRESET_GAP = 4
local PRESET_TOP_GAP = 10
local BOTTOM_PAD = 12
local POPUP_HEIGHT = TITLE_HEIGHT + TOP_PAD + SV_SIZE + PRESET_TOP_GAP + PRESET_SIZE + BOTTOM_PAD
local WIDTH_WITH_ALPHA = PAD + SV_SIZE + GAP + BAR_WIDTH + GAP + BAR_WIDTH + GAP + RIGHT_WIDTH + PAD
local WIDTH_NO_ALPHA = WIDTH_WITH_ALPHA - BAR_WIDTH - GAP
-- preset colors shown as one row of buttons at the bottom of the picker, {r, g, b} in 0-1
-- class colors come from https://warcraft.wiki.gg/wiki/Class_colors
local PRESET_COLORS = {
    { 0, 0, 0 },            -- Black
    { 1.00, 1.00, 1.00 },   -- Priest (white)
    { 0.77, 0.12, 0.23 },   -- Death Knight
    { 0.64, 0.19, 0.79 },   -- Demon Hunter
    { 1.00, 0.49, 0.04 },   -- Druid
    { 0.20, 0.58, 0.50 },   -- Evoker
    { 0.67, 0.83, 0.45 },   -- Hunter
    { 0.25, 0.78, 0.92 },   -- Mage
    { 0.00, 1.00, 0.60 },   -- Monk
    { 0.96, 0.55, 0.73 },   -- Paladin
    { 1.00, 0.96, 0.41 },   -- Rogue
    { 0.00, 0.44, 0.87 },   -- Shaman
    { 0.53, 0.53, 0.93 },   -- Warlock
    { 0.78, 0.61, 0.43 },   -- Warrior
}
local HUE_COLORS = {
    { 1, 0, 0 }, { 1, 1, 0 }, { 0, 1, 0 }, { 0, 1, 1 }, { 0, 0, 1 }, { 1, 0, 1 }, { 1, 0, 0 },
}
local CHECKER_CELL = 9

-- MARK: Color math
---@param h number 0-360
---@param s number 0-1
---@param v number 0-1
local function HSVtoRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x
    end
    return r + m, g + m, b + m
end

local function RGBtoHSV(r, g, b)
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local d = mx - mn
    local h
    if d == 0 then
        h = 0
    elseif mx == r then
        h = 60 * (((g - b) / d) % 6)
    elseif mx == g then
        h = 60 * (((b - r) / d) + 2)
    else
        h = 60 * (((r - g) / d) + 4)
    end
    return h, mx == 0 and 0 or d / mx, mx
end

local function Clamp01(value)
    return math.max(0, math.min(1, value))
end

-- MARK: Builders
local function BuildBox(parent)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop(addon.UICore:GetDefaultBackdrop())
    addon.UICore:SetBackdropColor(box)
    addon.UICore:SetBorderColor(box)
    return box
end

local function BuildLabel(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(addon.UICore:GetDefaultFont(), 10, "OUTLINE")
    label:SetTextColor(unpack(addon.UICore:GetNormalTextColor()))
    label:SetText(text)
    return label
end

local function BuildButton(parent, text, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetBackdrop(addon.UICore:GetDefaultBackdrop())
    addon.UICore:SetBackdropColor(button)
    addon.UICore:SetBorderColor(button)
    button:SetSize(width, height)
    addon.UICore:BuildHover(button)
    button:SetScript("OnClick", onClick)

    local label = BuildLabel(button, text)
    label:SetPoint("CENTER")
    return button
end

local function BuildInput(parent, maxLetters, numeric)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetBackdrop(addon.UICore:GetDefaultBackdrop())
    addon.UICore:SetBackdropColor(box)
    addon.UICore:SetBorderColor(box)
    box:SetSize(RIGHT_WIDTH, INPUT_HEIGHT)
    box:SetFont(addon.UICore:GetDefaultFont(), 11, "OUTLINE")
    box:SetTextColor(unpack(addon.UICore:GetNormalTextColor()))
    box:SetJustifyH("CENTER")
    box:SetMaxLetters(maxLetters)
    box:SetNumeric(numeric)
    box:SetAutoFocus(false)
    return box
end

---A bar or pad which reports the cursor position, normalized to 0-1, while the left button is held
local function MakeDraggable(frame, onChange)
    local function Update()
        local scale = frame:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale
        local x = Clamp01((cx - frame:GetLeft()) / frame:GetWidth())
        local y = Clamp01((cy - frame:GetBottom()) / frame:GetHeight())
        onChange(x, y)
    end

    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        Update()
        self:SetScript("OnUpdate", function(f)
            if not IsMouseButtonDown("LeftButton") then
                f:SetScript("OnUpdate", nil)
                return
            end
            Update()
        end)
    end)
    frame:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)
end

local function Build()
    local UICore = addon.UICore

    -- the current state, stored as HSV so that hue and saturation survive a black or gray pick
    local state = { h = 0, s = 1, v = 1, a = 1 }
    local previous = { r = 1, g = 1, b = 1, a = 1 }
    local info = nil
    local closedCallback = nil

    local popup = BuildBox(UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(400)
    popup:SetClampedToScreen(true)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:SetPoint("CENTER")
    popup:SetSize(WIDTH_WITH_ALPHA, POPUP_HEIGHT)
    popup:Hide()

    -- MARK: title bar
    local titleBar = CreateFrame("Frame", nil, popup)
    titleBar:SetHeight(TITLE_HEIGHT)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() popup:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() popup:StopMovingOrSizing() end)

    local title = BuildLabel(titleBar, "HBLyx Color Picker")
    title:SetFont(UICore:GetDefaultFont(), 12, "OUTLINE")
    title:SetPoint("CENTER")

    local closeButton = CreateFrame("Button", nil, popup)
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -6, -6)
    closeButton:SetFrameLevel(popup:GetFrameLevel() + 5)
    local closeIcon = closeButton:CreateTexture(nil, "ARTWORK")
    closeIcon:SetAllPoints()
    closeIcon:SetTexture(UICore:GetAssetDirectory() .. "Close_Button.png")
    UICore:BuildHover(closeButton)

    -- forward declarations, defined once the controls exist
    local Refresh, Fire, Cancel, Confirm

    -- MARK: saturation / value pad
    local svPad = BuildBox(popup)
    svPad:SetSize(SV_SIZE, SV_SIZE)
    svPad:SetPoint("TOPLEFT", popup, "TOPLEFT", PAD, -(TITLE_HEIGHT + TOP_PAD))

    local svHue = svPad:CreateTexture(nil, "BACKGROUND")
    svHue:SetPoint("TOPLEFT", SWATCH_INSET, -SWATCH_INSET)
    svHue:SetPoint("BOTTOMRIGHT", -SWATCH_INSET, SWATCH_INSET)
    svHue:SetColorTexture(1, 0, 0, 1)

    local svWhite = svPad:CreateTexture(nil, "BORDER")
    svWhite:SetAllPoints(svHue)
    svWhite:SetColorTexture(1, 1, 1, 1)
    svWhite:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 1), CreateColor(1, 1, 1, 0))

    local svBlack = svPad:CreateTexture(nil, "ARTWORK")
    svBlack:SetAllPoints(svHue)
    svBlack:SetColorTexture(0, 0, 0, 1)
    svBlack:SetGradient("VERTICAL", CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 0))

    -- four short lines around the picked point, leaving the point itself visible
    local CROSSHAIR_ARM = 6
    local CROSSHAIR_GAP = 2
    local crosshairTop = svPad:CreateTexture(nil, "OVERLAY", nil, 7)
    crosshairTop:SetSize(1, CROSSHAIR_ARM)
    local crosshairBottom = svPad:CreateTexture(nil, "OVERLAY", nil, 7)
    crosshairBottom:SetSize(1, CROSSHAIR_ARM)
    local crosshairLeft = svPad:CreateTexture(nil, "OVERLAY", nil, 7)
    crosshairLeft:SetSize(CROSSHAIR_ARM, 1)
    local crosshairRight = svPad:CreateTexture(nil, "OVERLAY", nil, 7)
    crosshairRight:SetSize(CROSSHAIR_ARM, 1)
    for _, line in ipairs({ crosshairTop, crosshairBottom, crosshairLeft, crosshairRight }) do
        line:SetColorTexture(1, 1, 1, 0.9)
    end

    MakeDraggable(svPad, function(x, y)
        state.s, state.v = x, y
        Refresh()
        Fire()
    end)

    -- MARK: hue bar
    local hueBar = BuildBox(popup)
    hueBar:SetSize(BAR_WIDTH, SV_SIZE)
    hueBar:SetPoint("TOPLEFT", svPad, "TOPRIGHT", GAP, 0)

    local segmentHeight = (SV_SIZE - 2 * SWATCH_INSET) / 6
    for i = 1, 6 do
        local segment = hueBar:CreateTexture(nil, "ARTWORK")
        segment:SetPoint("TOPLEFT", hueBar, "TOPLEFT", SWATCH_INSET, -SWATCH_INSET - (i - 1) * segmentHeight)
        segment:SetPoint("BOTTOMRIGHT", hueBar, "TOPRIGHT", -SWATCH_INSET, -SWATCH_INSET - i * segmentHeight)
        segment:SetColorTexture(1, 1, 1, 1)
        local top, bottom = HUE_COLORS[i], HUE_COLORS[i + 1]
        segment:SetGradient("VERTICAL", CreateColor(bottom[1], bottom[2], bottom[3], 1), CreateColor(top[1], top[2], top[3], 1))
    end

    local hueMarker = hueBar:CreateTexture(nil, "OVERLAY")
    hueMarker:SetSize(BAR_WIDTH + 4, 2)
    hueMarker:SetColorTexture(1, 1, 1, 1)

    MakeDraggable(hueBar, function(_, y)
        state.h = (1 - y) * 360
        Refresh()
        Fire()
    end)

    -- MARK: alpha bar
    local alphaBar = BuildBox(popup)
    alphaBar:SetSize(BAR_WIDTH, SV_SIZE)
    alphaBar:SetPoint("TOPLEFT", hueBar, "TOPRIGHT", GAP, 0)

    local innerHeight = SV_SIZE - 2 * SWATCH_INSET
    for row = 0, math.ceil(innerHeight / CHECKER_CELL) - 1 do
        for col = 0, math.ceil((BAR_WIDTH - 2 * SWATCH_INSET) / CHECKER_CELL) - 1 do
            local shade = ((row + col) % 2 == 0) and 0.3 or 0.15
            local cell = alphaBar:CreateTexture(nil, "BACKGROUND")
            cell:SetSize(CHECKER_CELL, CHECKER_CELL)
            cell:SetPoint("TOPLEFT", alphaBar, "TOPLEFT", SWATCH_INSET + col * CHECKER_CELL, -SWATCH_INSET - row * CHECKER_CELL)
            cell:SetColorTexture(shade, shade, shade, 1)
        end
    end
    -- the last checker row and column overflow the bar, so clip them
    alphaBar:SetClipsChildren(true)

    local alphaGradient = alphaBar:CreateTexture(nil, "ARTWORK")
    alphaGradient:SetPoint("TOPLEFT", SWATCH_INSET, -SWATCH_INSET)
    alphaGradient:SetPoint("BOTTOMRIGHT", -SWATCH_INSET, SWATCH_INSET)
    alphaGradient:SetColorTexture(1, 1, 1, 1)

    local alphaMarker = alphaBar:CreateTexture(nil, "OVERLAY")
    alphaMarker:SetSize(BAR_WIDTH + 4, 2)
    alphaMarker:SetColorTexture(1, 1, 1, 1)

    -- reused to avoid allocating a color object on every drag step
    local alphaLow, alphaHigh = CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 1)

    MakeDraggable(alphaBar, function(_, y)
        state.a = y
        Refresh()
        Fire()
    end)

    -- MARK: right column
    local rightColumn = CreateFrame("Frame", nil, popup)
    rightColumn:SetSize(RIGHT_WIDTH, SV_SIZE)
    rightColumn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -PAD, -(TITLE_HEIGHT + TOP_PAD))

    local newLabel = BuildLabel(rightColumn, "New")
    newLabel:SetPoint("TOPLEFT")
    local newBox = BuildBox(rightColumn)
    newBox:SetSize(RIGHT_WIDTH, PREVIEW_HEIGHT)
    newBox:SetPoint("TOPLEFT", newLabel, "BOTTOMLEFT", 0, -2)
    local newPreview = newBox:CreateTexture(nil, "ARTWORK")
    newPreview:SetPoint("TOPLEFT", SWATCH_INSET, -SWATCH_INSET)
    newPreview:SetPoint("BOTTOMRIGHT", -SWATCH_INSET, SWATCH_INSET)

    local prevLabel = BuildLabel(rightColumn, "Prev")
    prevLabel:SetPoint("TOPLEFT", newBox, "BOTTOMLEFT", 0, -4)
    local prevBox = BuildBox(rightColumn)
    prevBox:SetSize(RIGHT_WIDTH, PREVIEW_HEIGHT)
    prevBox:SetPoint("TOPLEFT", prevLabel, "BOTTOMLEFT", 0, -2)
    local prevPreview = prevBox:CreateTexture(nil, "ARTWORK")
    prevPreview:SetPoint("TOPLEFT", SWATCH_INSET, -SWATCH_INSET)
    prevPreview:SetPoint("BOTTOMRIGHT", -SWATCH_INSET, SWATCH_INSET)
    UICore:BuildHover(prevBox)
    prevBox:EnableMouse(true)

    local hexLabel = BuildLabel(rightColumn, "Hex#")
    hexLabel:SetPoint("TOPLEFT", prevBox, "BOTTOMLEFT", 0, -6)
    local hexInput = BuildInput(rightColumn, 6, false)
    hexInput:SetPoint("TOPLEFT", hexLabel, "BOTTOMLEFT", 0, -2)

    local opacityLabel = BuildLabel(rightColumn, "Opacity")
    opacityLabel:SetPoint("TOPLEFT", hexInput, "BOTTOMLEFT", 0, -6)
    local opacityInput = BuildInput(rightColumn, 3, true)
    opacityInput:SetPoint("TOPLEFT", opacityLabel, "BOTTOMLEFT", 0, -2)

    local okButton = BuildButton(rightColumn, "OK", RIGHT_WIDTH, BUTTON_HEIGHT, function() Confirm() end)
    okButton:SetPoint("BOTTOMLEFT")
    local cancelButton = BuildButton(rightColumn, "Cancel", RIGHT_WIDTH, BUTTON_HEIGHT, function() Cancel() end)
    cancelButton:SetPoint("BOTTOM", okButton, "TOP", 0, 4)

    -- MARK: preset colors
    -- the row spans the bottom of the popup and a click applies the preset like a typed hex value
    local presetButtons = {}
    for index, preset in ipairs(PRESET_COLORS) do
        local button = BuildBox(popup)
        local fill = button:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", SWATCH_INSET, -SWATCH_INSET)
        fill:SetPoint("BOTTOMRIGHT", -SWATCH_INSET, SWATCH_INSET)
        fill:SetColorTexture(preset[1], preset[2], preset[3], 1)
        UICore:BuildHover(button)
        button:EnableMouse(true)
        button:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton ~= "LeftButton" then return end
            state.h, state.s, state.v = RGBtoHSV(preset[1], preset[2], preset[3])
            Refresh()
            Fire()
        end)
        presetButtons[index] = button
    end

    -- the buttons are squares which share the inner width, so a popup without the alpha bar gets smaller ones
    local function LayoutPresets(popupWidth)
        local count = #presetButtons
        local size = math.min(PRESET_SIZE, math.floor((popupWidth - 2 * PAD - (count - 1) * PRESET_GAP) / count))
        for index, button in ipairs(presetButtons) do
            button:SetSize(size, size)
            button:ClearAllPoints()
            button:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", PAD + (index - 1) * (size + PRESET_GAP), BOTTOM_PAD)
        end
    end
    LayoutPresets(WIDTH_WITH_ALPHA)

    -- MARK: behavior
    Refresh = function()
        local r, g, b = HSVtoRGB(state.h, state.s, state.v)

        local hr, hg, hb = HSVtoRGB(state.h, 1, 1)
        svHue:SetColorTexture(hr, hg, hb, 1)
        local x, y = state.s * SV_SIZE, state.v * SV_SIZE
        crosshairTop:ClearAllPoints()
        crosshairTop:SetPoint("BOTTOM", svPad, "BOTTOMLEFT", x, y + CROSSHAIR_GAP)
        crosshairBottom:ClearAllPoints()
        crosshairBottom:SetPoint("TOP", svPad, "BOTTOMLEFT", x, y - CROSSHAIR_GAP)
        crosshairLeft:ClearAllPoints()
        crosshairLeft:SetPoint("RIGHT", svPad, "BOTTOMLEFT", x - CROSSHAIR_GAP, y)
        crosshairRight:ClearAllPoints()
        crosshairRight:SetPoint("LEFT", svPad, "BOTTOMLEFT", x + CROSSHAIR_GAP, y)

        hueMarker:ClearAllPoints()
        hueMarker:SetPoint("CENTER", hueBar, "TOPLEFT", BAR_WIDTH / 2, -(state.h / 360) * SV_SIZE)

        alphaLow.r, alphaLow.g, alphaLow.b = r, g, b
        alphaHigh.r, alphaHigh.g, alphaHigh.b = r, g, b
        alphaGradient:SetGradient("VERTICAL", alphaLow, alphaHigh)
        alphaMarker:ClearAllPoints()
        alphaMarker:SetPoint("CENTER", alphaBar, "TOPLEFT", BAR_WIDTH / 2, -(1 - state.a) * SV_SIZE)

        local alpha = info and info.hasAlpha and state.a or 1
        newPreview:SetColorTexture(r, g, b, alpha)

        if not hexInput:HasFocus() then
            hexInput:SetText(string.format("%02X%02X%02X", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)))
        end
        if not opacityInput:HasFocus() then
            opacityInput:SetText(tostring(math.floor(state.a * 100 + 0.5)))
        end
    end

    Fire = function()
        if info and info.onChange then
            local r, g, b = HSVtoRGB(state.h, state.s, state.v)
            info.onChange(r, g, b, info.hasAlpha and state.a or 1)
        end
    end

    -- Cancel restores the color the picker was opened with
    Cancel = function()
        if info and info.onChange then
            info.onChange(previous.r, previous.g, previous.b, previous.a)
        end
        info = nil
        popup:Hide()
    end

    Confirm = function()
        Fire()
        info = nil
        popup:Hide()
    end

    closeButton:SetScript("OnClick", function() Cancel() end)

    prevBox:SetScript("OnMouseDown", function()
        state.h, state.s, state.v = RGBtoHSV(previous.r, previous.g, previous.b)
        state.a = previous.a
        Refresh()
        Fire()
    end)

    hexInput:SetScript("OnTextChanged", function(self)
        if not self:HasFocus() then return end
        local text = self:GetText():upper():gsub("[^%dA-F]", "")
        if #text == 6 then
            local r, g, b = tonumber(text:sub(1, 2), 16) / 255, tonumber(text:sub(3, 4), 16) / 255, tonumber(text:sub(5, 6), 16) / 255
            state.h, state.s, state.v = RGBtoHSV(r, g, b)
            Refresh()
            Fire()
        end
    end)
    hexInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    hexInput:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    -- restore a canonical value if the typed text was incomplete
    hexInput:SetScript("OnEditFocusLost", function() Refresh() end)

    opacityInput:SetScript("OnTextChanged", function(self)
        if not self:HasFocus() then return end
        local value = tonumber(self:GetText())
        if value then
            state.a = Clamp01(value / 100)
            Refresh()
            Fire()
        end
    end)
    opacityInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    opacityInput:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    opacityInput:SetScript("OnEditFocusLost", function() Refresh() end)

    -- Escape inside an input cancels the whole picker, like the close button
    hexInput:SetScript("OnEscapePressed", function(self) self:ClearFocus(); Cancel() end)
    opacityInput:SetScript("OnEscapePressed", function(self) self:ClearFocus(); Cancel() end)

    -- click outside cancels; registered one frame late so the click which opened the popup does not close it
    local clickOff = CreateFrame("Frame")
    clickOff:SetScript("OnEvent", function()
        if popup:IsShown() and not popup:IsMouseOver() then
            Cancel()
        end
    end)
    popup:HookScript("OnShow", function()
        C_Timer.After(0, function()
            if popup:IsShown() then
                clickOff:RegisterEvent("GLOBAL_MOUSE_DOWN")
            end
        end)
    end)
    popup:HookScript("OnHide", function()
        clickOff:UnregisterEvent("GLOBAL_MOUSE_DOWN")
        -- every way of closing ends here, so the owner learns the session is over
        local onClose = closedCallback
        closedCallback = nil
        info = nil
        if onClose then onClose() end
    end)

    -- MARK: popup API
    ---@param openInfo table see ColorPickerPopup:Open
    function popup:Setup(openInfo)
        info = openInfo
        closedCallback = openInfo.onClose
        previous.r, previous.g, previous.b = openInfo.r or 1, openInfo.g or 1, openInfo.b or 1
        previous.a = openInfo.a or 1
        state.h, state.s, state.v = RGBtoHSV(previous.r, previous.g, previous.b)
        state.a = previous.a

        local hasAlpha = openInfo.hasAlpha and true or false
        alphaBar:SetShown(hasAlpha)
        opacityLabel:SetShown(hasAlpha)
        opacityInput:SetShown(hasAlpha)
        popup:SetWidth(hasAlpha and WIDTH_WITH_ALPHA or WIDTH_NO_ALPHA)
        LayoutPresets(popup:GetWidth())
        prevPreview:SetColorTexture(previous.r, previous.g, previous.b, hasAlpha and previous.a or 1)
        Refresh()
    end

    return popup
end

-- MARK: API
---Open the color picker for a caller. A session which is still open is closed first, without reverting it.
---@param info table
--- `r`, `g`, `b`, `a`: the starting color, `hasAlpha`: show the opacity controls,
--- `onChange(r, g, b, a)`: called on every change, and with the starting color on cancel,
--- `onClose()`: called once the popup is hidden, however it was closed
---@param anchor Frame? the frame to place the picker next to, defaults to the screen center
function ColorPickerPopup:Open(info, anchor)
    local popup = self.frame

    popup:Hide()
    popup:Setup(info)
    popup:ClearAllPoints()
    if anchor then
        popup:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
    else
        popup:SetPoint("CENTER")
    end
    popup:Show()
end

function ColorPickerPopup:Close()
    self.frame:Hide()
end

function ColorPickerPopup:IsShown()
    return self.frame:IsShown()
end

-- MARK: Singleton
-- the picker is a fixed panel created once together with UICore, widgets borrow it through UICore:GetColorPicker
ColorPickerPopup.frame = Build()
ColorPickerPopup.frame.obj = ColorPickerPopup

---Get the shared color picker panel
---@return ColorPickerPopup colorPicker
function addon.UICore:GetColorPicker()
    return ColorPickerPopup
end
