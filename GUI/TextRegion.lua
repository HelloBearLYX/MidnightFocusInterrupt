local addon = select(2, ...)

---@class TextRegion
---@field type string widget type
---@field frame Frame the container frame of the text region
---@field label FontString the wrapped text
local TextRegion = {
    type = "TextRegion",
    frame = nil,
    label = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_FONT_SIZE = 12

-- MARK: Helpers

---Shrink the frame to the height the wrapped text needs
local function UpdateLayout(widget)
    if widget.updating then return end

    local frame, label = widget.frame, widget.label

    label:SetWidth(frame:GetWidth() or 0)

    -- a zero height frame would be dropped by the layout, keep it usable as a spacer
    local height = label:GetStringHeight()
    if not height or height <= 0 then
        height = 1
    end

    widget.updating = true
    frame:SetHeight(height)
    widget.updating = nil
end

-- MARK: Script handlers
local function Frame_OnSizeChanged(frame)
    UpdateLayout(frame.obj)
end

local function Frame_OnMouseUp(frame)
    local widget = frame.obj
    if widget.onClick then
        PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
        widget.onClick(widget)
    end
end

local function Frame_OnEnter(frame)
    local widget = frame.obj
    if widget.onEnter then
        widget.onEnter(widget)
    end
end

local function Frame_OnLeave(frame)
    local widget = frame.obj
    if widget.onLeave then
        widget.onLeave(widget)
    end
end

-- MARK: API

---Takes the full width of the parent, the height follows the text
function TextRegion:SetParent(parent)
    self.frame:SetParent(parent)
    if parent and parent.GetWidth then
        self:SetWidth(parent:GetWidth())
    end
end

function TextRegion:SetText(text)
    self.label:SetText(text or "")
    UpdateLayout(self)
end

function TextRegion:GetText()
    return self.label:GetText()
end

function TextRegion:SetFontSize(size)
    self.label:SetFont("Fonts\\FRIZQT__.TTF", size or DEFAULT_FONT_SIZE, "OUTLINE")
    UpdateLayout(self)
end

function TextRegion:SetColor(r, g, b, a)
    self.label:SetTextColor(r or 1, g or 1, b or 1, a or 1)
end

function TextRegion:SetJustifyH(justifyH)
    self.label:SetJustifyH(justifyH or "LEFT")
end

function TextRegion:SetJustifyV(justifyV)
    self.label:SetJustifyV(justifyV or "TOP")
end

function TextRegion:SetWidth(width)
    self.frame:SetWidth(width or DEFAULT_WIDTH)
    UpdateLayout(self)
end

---The height is driven by the text, so it is ignored
function TextRegion:SetSize(width, _)
    self:SetWidth(width)
end

function TextRegion:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function TextRegion:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function TextRegion:GetWidth()
    return self.frame:GetWidth()
end

function TextRegion:GetHeight()
    return self.frame:GetHeight()
end

function TextRegion:Show()
    self.frame:Show()
end

function TextRegion:Hide()
    self.frame:Hide()
end

---Makes the region behave like a link, the callback runs on click
function TextRegion:SetOnClick(callback)
    self.onClick = callback
    self.frame:EnableMouse(callback and true or false)
end

function TextRegion:SetOnEnter(callback)
    self.onEnter = callback
    if callback then
        self.frame:EnableMouse(true)
    end
end

function TextRegion:SetOnLeave(callback)
    self.onLeave = callback
end

function TextRegion:Release()
    self:SetOnClick(nil)
    self.onEnter = nil
    self.onLeave = nil
    self:SetFontSize()
    self:SetColor()
    self:SetJustifyH()
    self:SetJustifyV()
    self:SetText("")
    self:SetWidth()
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function TextRegion:Create(parent, width, text)
    local widget = setmetatable({}, { __index = TextRegion })

    local frame = CreateFrame("Frame", nil, parent)
    frame:Hide()
    frame:SetWidth(width or (parent and parent.GetWidth and parent:GetWidth()) or DEFAULT_WIDTH)
    frame:SetHeight(1)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)
    frame.obj = widget

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", DEFAULT_FONT_SIZE, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(true)
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetText(text or "")

    frame:SetScript("OnSizeChanged", Frame_OnSizeChanged)
    frame:SetScript("OnMouseUp", Frame_OnMouseUp)
    frame:SetScript("OnEnter", Frame_OnEnter)
    frame:SetScript("OnLeave", Frame_OnLeave)
    frame:EnableMouse(false)

    widget.frame = frame
    widget.label = label
    widget.type = TextRegion.type
    widget.fullWidth = true -- the text always takes its own row

    UpdateLayout(widget)

    return widget
end

function TextRegion:Reuse(parent, width, text)
    self:SetParent(parent)
    self:SetWidth(width)
    self:SetText(text or "")
    self.fullWidth = true
    return self
end

addon.UICore:RegisterWidget(TextRegion)
