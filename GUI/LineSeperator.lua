local addon = select(2, ...)

---@class LineSeperator
---@field type string widget type
---@field frame Frame the container frame of the line
---@field line Texture the line itself
local LineSeperator = {
    type = "LineSeperator",
    frame = nil,
    line = nil,
}

-- MARK: Default values
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 9
local DEFAULT_THICKNESS = 1
local DEFAULT_COLOR = { 1, 1, 1, 0.4 }

-- MARK: API
function LineSeperator:SetParent(parent)
    self.frame:SetParent(parent)
end

function LineSeperator:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function LineSeperator:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

---The height is the room around the line, the line itself keeps its thickness
function LineSeperator:SetSize(width, height)
    self.frame:SetSize(width or DEFAULT_WIDTH, height or DEFAULT_HEIGHT)
end

function LineSeperator:GetWidth()
    return self.frame:GetWidth()
end

function LineSeperator:GetHeight()
    return self.frame:GetHeight()
end

function LineSeperator:SetColor(r, g, b, a)
    self.line:SetColorTexture(r or DEFAULT_COLOR[1], g or DEFAULT_COLOR[2], b or DEFAULT_COLOR[3], a or DEFAULT_COLOR[4])
end

function LineSeperator:SetThickness(thickness)
    self.line:SetHeight(thickness or DEFAULT_THICKNESS)
end

function LineSeperator:Show()
    self.frame:Show()
end

function LineSeperator:Hide()
    self.frame:Hide()
end

function LineSeperator:Release()
    self:SetColor()
    self:SetThickness()
    self:SetSize()
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function LineSeperator:Create(parent, width, height)
    local widget = setmetatable({}, { __index = LineSeperator })

    local frame = CreateFrame("Frame", nil, parent)
    frame:Hide()
    frame:SetSize(width or DEFAULT_WIDTH, height or DEFAULT_HEIGHT)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)
    frame.obj = widget

    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetHeight(DEFAULT_THICKNESS)
    line:SetPoint("LEFT", frame, "LEFT", 0, 0)
    line:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    line:SetColorTexture(unpack(DEFAULT_COLOR))

    widget.frame = frame
    widget.line = line
    widget.type = LineSeperator.type
    widget.fullWidth = true -- a separator always spans its row

    return widget
end

function LineSeperator:Reuse(parent, width, height)
    self.frame:SetParent(parent)
    self:SetSize(width, height)
    self.fullWidth = true
    return self
end

addon.UICore:RegisterWidget(LineSeperator)
