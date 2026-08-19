local addon = select(2, ...)

---@class ScrollFrame
---@field type string widget type
---@field frame Frame the main frame of the scroll frame
---@field scrollHandler ScrollFrame the scroll handler frame
---@field container Frame the scroll container frame that holds the content
---@field titleBar FontString the title bar of the scroll frame
---@field content table the content of the scroll frame
---@field contentX number the x position of the current content
---@field contentY number the y position of the current content
local ScrollFrame = {
    type = "ScrollFrame",
    frame = nil,
    scrollHandler = nil,
    container = nil,
    titleBar = nil,
    content = nil,
    contentX = 0,
    contentY = 0,
    rowMaxHeight = 0,
}

-- MARK: Default values
local DEFAULT_WIDTH = 400
local DEFAULT_HEIGHT = 300
local CONTENT_INSET = 6
local SCROLLBAR_WIDTH = 24
local ROW_SPACING = 8
local TITLE_FONT_SIZE = 20
local SCROLLBAR_THICKNESS = 10
local SCROLLBAR_THUMB_HEIGHT = 24
local SCROLL_STEP = 24

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

-- MARK: Helpers

---Match the scroll bar range to the content that overflows the visible area
local function UpdateScrollRange(widget)
    -- derived from the frame instead of the scroll handler, whose anchored size can still be stale here
    local visibleHeight = widget.frame:GetHeight() - CONTENT_INSET * 2
    local range = math.max(0, widget.container:GetHeight() - visibleHeight)

    widget.scrollBar:SetMinMaxValues(0, range)
    if range > 0 then
        widget.scrollBar:Show()
        widget.scrollBar:SetValue(math.min(widget.scrollBar:GetValue(), range))
    else
        widget.scrollBar:SetValue(0)
        widget.scrollBar:Hide()
    end
end

-- MARK: Script handlers
local function ScrollBar_OnValueChanged(scrollBar, value)
    scrollBar.obj.scrollHandler:SetVerticalScroll(value)
end

local function ScrollHandler_OnMouseWheel(scrollHandler, delta)
    local scrollBar = scrollHandler.obj.scrollBar
    scrollBar:SetValue(scrollBar:GetValue() - delta * SCROLL_STEP)
end

---Recycle every widget currently held by the scroll frame and reset the layout cursor
function ScrollFrame:ReleaseChildren()
    for _, widget in ipairs(self.content) do
        if widget ~= addon.UICore.ROW_BREAK then
            addon.UICore:ReleaseToPool(widget)
        end
    end
    self.contentX = 0
    self.contentY = 0
    self.rowMaxHeight = 0
    self.content = {}
    self.container:SetHeight(1)
    UpdateScrollRange(self)
end

---The renderer fills the scroll frame and is replayed on every re-render
---@param renderer fun(scrollFrame: table)
function ScrollFrame:SetRenderer(renderer)
    self.renderer = renderer
end

---Recycle the current content and build it again with the renderer
function ScrollFrame:Rerender()
    self:ReleaseChildren()

    if self.renderer then
        self.renderer(self)
    end
end

function ScrollFrame:Release()
    self:ReleaseChildren()
    self.renderer = nil
    self.frame:Hide()
end

-- MARK: Build
function ScrollFrame:Create(parent, width, height, title)
    local widget = setmetatable({}, { __index = ScrollFrame })

    -- create an new instance
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:Hide()
    frame.obj = widget

    -- background and border
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, tileSize = 1, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.5)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    -- size and position
    frame:SetSize(width or DEFAULT_WIDTH, height or DEFAULT_HEIGHT)
    frame:SetPoint("TOPLEFT", parent or UIParent, "TOPLEFT", 0, 0)

    local scrollHandler = CreateFrame("ScrollFrame", nil, frame)
    scrollHandler:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_INSET, -CONTENT_INSET)
    scrollHandler:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -SCROLLBAR_WIDTH, CONTENT_INSET)
    scrollHandler:EnableMouseWheel(true)
    scrollHandler:SetScript("OnMouseWheel", ScrollHandler_OnMouseWheel)
    scrollHandler.obj = widget

    local container = CreateFrame("Frame", nil, scrollHandler)
    container:SetSize((width or DEFAULT_WIDTH) - CONTENT_INSET - SCROLLBAR_WIDTH, 1) -- height will auto-expand based on
    scrollHandler:SetScrollChild(container)

    -- the scroll bar shares the look of the Slider widget
    local scrollBar = CreateFrame("Slider", nil, frame, "BackdropTemplate")
    scrollBar:SetBackdrop(BACKDROP)
    scrollBar:SetBackdropColor(0, 0, 0, 0.5)
    scrollBar:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetWidth(SCROLLBAR_THICKNESS)
    scrollBar:SetPoint("TOPLEFT", scrollHandler, "TOPRIGHT", CONTENT_INSET, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollHandler, "BOTTOMRIGHT", CONTENT_INSET, 0)
    scrollBar:SetValueStep(1)
    scrollBar:SetObeyStepOnDrag(true)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValue(0)
    scrollBar:SetScript("OnValueChanged", ScrollBar_OnValueChanged)
    scrollBar:Hide()
    scrollBar.obj = widget

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(1, 1, 1, 1)
    thumb:SetSize(SCROLLBAR_THICKNESS - 4, SCROLLBAR_THUMB_HEIGHT)
    scrollBar:SetThumbTexture(thumb)

    -- title bar
    local titleBar = frame:CreateFontString(nil, "OVERLAY")
    titleBar:SetPoint("BOTTOM", frame, "TOP", 0, 0)
    titleBar:SetFont("Fonts\\FRIZQT__.TTF", TITLE_FONT_SIZE, "OUTLINE")
    titleBar:SetText(title or "")

    -- content
    -- once the content is added into the container, the content tracks the widgets in the scroll frame
    -- then, the widgets can be released to the pool when the scroll frame is released
    local content = {}

    widget.frame = frame
    widget.scrollHandler = scrollHandler
    widget.container = container
    widget.scrollBar = scrollBar
    widget.titleBar = titleBar
    widget.content = content
    widget.contentX = 0
    widget.contentY = 0
    widget.rowMaxHeight = 0
    widget.type = ScrollFrame.type

    return widget
end

function ScrollFrame:SetParent(parent)
    self.frame:SetParent(parent)
end

function ScrollFrame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    self.frame:ClearAllPoints()
    if not relativeTo or not anchorTo then
        self.frame:SetPoint(anchorFrom, x, y)
    else
        self.frame:SetPoint(anchorFrom, relativeTo, anchorTo, x, y)
    end
end

function ScrollFrame:SetPosition(x, y)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", x or 0, y or 0)
end

function ScrollFrame:Show()
    self.frame:Show()
end

function ScrollFrame:Hide()
    self.frame:Hide()
end

function ScrollFrame:SetTitle(title)
    self.titleBar:SetText(title or "")
end

function ScrollFrame:SetSize(width, height)
    width = width or DEFAULT_WIDTH
    self.frame:SetSize(width, height or DEFAULT_HEIGHT)
    self.container:SetWidth(width - CONTENT_INSET - SCROLLBAR_WIDTH)
    UpdateScrollRange(self)
end

---The usable width for the child widgets, the scroll bar is excluded
function ScrollFrame:GetWidth()
    return self.container:GetWidth()
end

function ScrollFrame:GetHeight()
    return self.frame:GetHeight()
end

function ScrollFrame:GetContentPosition()
    return self.contentX, self.contentY, self.rowMaxHeight
end

function ScrollFrame:AddWidget(widget)
    -- parented first so that a widget which sizes itself from its parent is measured correctly
    widget:SetParent(self.container)
    table.insert(self.content, widget)
    self:Layout()
end

ScrollFrame.AddChild = ScrollFrame.AddWidget

---Start a new row no matter how much room is left in the current one
function ScrollFrame:NewRow()
    table.insert(self.content, addon.UICore.ROW_BREAK)
    self:Layout()
end

---Place every widget again, honouring the row breaks and the relative widths
function ScrollFrame:Layout()
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

    -- the container grows with its content so that the scroll bar knows the scroll range
    self.container:SetHeight(math.max(1, self.contentY + self.rowMaxHeight))
    UpdateScrollRange(self)
end

ScrollFrame.DoLayout = ScrollFrame.Layout

function ScrollFrame:Reuse(parent, width, height, title)
    self.frame:SetParent(parent)
    self.titleBar:SetText(title or "")
    self:SetSize(width, height)
    return self
end

addon.UICore:RegisterWidget(ScrollFrame)