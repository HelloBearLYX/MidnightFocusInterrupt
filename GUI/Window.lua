local addon = select(2, ...)

---@class Window
---@field type string widget type
---@field frame Frame the main frame of the window
---@field container Frame the content container which holds the widgets
---@field content table the widgets currently held by the window
---@field contentX number the x position of the current content
---@field contentY number the y position of the current content
local Window = {
    type = "Window",
    frame = nil,
    container = nil,
    content = nil,
    contentX = 0,
    contentY = 0,
    rowMaxHeight = 0,
}

-- MARK: Default values
local DEFAULT_WIDTH = 400
local DEFAULT_HEIGHT = 300
local CONTENT_INSET = 6
local ROW_SPACING = 8

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

---Recycle every widget currently held by the window and reset the layout cursor
function Window:ReleaseChildren()
    for _, widget in ipairs(self.content) do
        if widget ~= addon.UICore.ROW_BREAK then
            addon.UICore:ReleaseToPool(widget)
        end
    end
    self.contentX = 0
    self.contentY = 0
    self.rowMaxHeight = 0
    self.content = {}
end

---The renderer fills the window and is replayed on every re-render
---@param renderer fun(window: table)
function Window:SetRenderer(renderer)
    self.renderer = renderer
end

---Recycle the current content and build it again with the renderer
function Window:Rerender()
    self:ReleaseChildren()

    if self.renderer then
        self.renderer(self)
    end
end

function Window:Release()
    self:ReleaseChildren()
    self.renderer = nil
    self:SetSize()
    self:SetPosition()
    self.frame:SetParent(nil)
    self.frame:Hide()
end

-- MARK: Build
function Window:Create(parent, width, height)
    local widget = setmetatable({}, { __index = Window })

    width = width or DEFAULT_WIDTH
    height = height or DEFAULT_HEIGHT

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:Hide()
    frame.obj = widget

    -- background and border
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(0, 0, 0, 0.5)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    -- size and position
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)

    -- the container tracks the widgets so that they can be released back to the pool with the window
    local container = CreateFrame("Frame", nil, frame)
    container:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_INSET, -CONTENT_INSET)
    container:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET)

    widget.frame = frame
    widget.container = container
    widget.content = {}
    widget.contentX = 0
    widget.contentY = 0
    widget.rowMaxHeight = 0
    widget.type = Window.type

    return widget
end

-- MARK: API
function Window:SetParent(parent)
    self.frame:SetParent(parent)
end

function Window:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    self.frame:ClearAllPoints()
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function Window:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function Window:Show()
    self.frame:Show()
end

function Window:Hide()
    self.frame:Hide()
end

function Window:SetSize(width, height)
    self.frame:SetSize(width or DEFAULT_WIDTH, height or DEFAULT_HEIGHT)
end

---The usable width for the child widgets, the insets are excluded
function Window:GetWidth()
    return self.frame:GetWidth() - CONTENT_INSET * 2
end

function Window:GetHeight()
    return self.frame:GetHeight()
end

function Window:GetContentPosition()
    return self.contentX, self.contentY, self.rowMaxHeight
end

function Window:AddWidget(widget)
    -- parented first so that a widget which sizes itself from its parent is measured correctly
    widget:SetParent(self.container)
    table.insert(self.content, widget)
    self:Layout()
end

Window.AddChild = Window.AddWidget

---Start a new row no matter how much room is left in the current one
function Window:NewRow()
    table.insert(self.content, addon.UICore.ROW_BREAK)
    self:Layout()
end

---Place every widget again, honouring the row breaks and the relative widths
function Window:Layout()
    self.contentX, self.contentY, self.rowMaxHeight = 0, 0, 0

    for _, widget in ipairs(self.content) do
        if widget == addon.UICore.ROW_BREAK then
            self.contentX = 0
            self.contentY = self.contentY + self.rowMaxHeight + ROW_SPACING
            self.rowMaxHeight = 0
        else
            addon.UICore:ApplyLayoutWidth(self, widget)

            local currentX, currentY = addon.UICore:ComputeContentPosition(self, widget)
            widget:SetPoint("TOPLEFT", self.container, "TOPLEFT", currentX, -currentY)
            widget:Show()
        end
    end
end

Window.DoLayout = Window.Layout

function Window:Reuse(parent, width, height)
    self.frame:SetParent(parent)
    self:SetSize(width, height)
    return self
end

addon.UICore:RegisterWidget(Window)
