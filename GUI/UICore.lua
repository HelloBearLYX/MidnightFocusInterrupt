local ADDON_NAME, addon = ...

--- HBLyx GUI Core
--- @author HBLyx
--- @github https://github.com/HelloBearLYX/HBLyx_Tools
--- @version 0.1.0
--- @introduction This is the GUI library of HBLyx which provides frame pools and other utilities for building GUI widgets. 
--[[
Although this module has some extendability and general utility, it is not totally designed as a general World of Warcraft GUI library.
Therefore, there are many arbitrary design in this module.
Such as the GUI layout is designed as row-based layout and color cycle is a fixed color cycle although it can easily be extended.
If you want to build your version of GUI with this library, you can fork this repo and modify it to the demands.
Nevertheless, keep in mind, make sure you have correct and suitable references and citations.
]]
--[[Description:
This library designed to provide a convinient way to build GUI, the configuration GUI. The GUI is not designed to be used to create in-game features.
This GUI library contains a frame pool system but not a general frame pool system which re-use all frames created through this library.
The detailed design of the frame pool system are also described below in comments.
]]

---@class UICore
local UICore = {
    colorCycleIndex = 1,
    registeredWidgets = {},
    framePools = {},
}

-- constants
local COLOR_CYCLE = {
    {0.33, 0.55, 0.82, 1},
    {0.42, 0.70, 0.48, 1},
    {0.89, 0.62, 0.34, 1},
    {0.73, 0.47, 0.76, 1},
    {0.86, 0.42, 0.46, 1},
    {0.45, 0.73, 0.72, 1},
    {0.78, 0.68, 0.35, 1},
}
local ERROR_MSG ={
    ["InvalidType"] = "Invalid widget type: %s",
}

-- MARK: frame pool
-- since the frame are created with some invariants, a global general frame pool is also not a good idea, even if each frame got released totally before added into framePools.
-- As there are many nested frame within a frame, the global general frame pool must release these nested frames also which mean tremendous complicated logic
-- so keep the frame pool for each frame type, and each frame type should have its own release logic, which is much easier to maintain and develop.


---Attempt to fetch a widget from pool
---@param widgetType string the widget type
---@return table|nil widget the widget to be re-used, nil if the pool is empty
local function FetchWidgetFromPool(self, widgetType)
    if not self.framePools[widgetType] then
        error(string.format(ERROR_MSG["InvalidType"], tostring(widgetType)))
    end

    -- the table.remove pop the last element with O(1)
    -- if it return nil, it means the pool is empty, then we need to build a new widget
    local widget = table.remove(self.framePools[widgetType])

    return widget
end

---Register a widget constructor for a given type
---@param widgetClass table the widget class to be registered
function UICore:RegisterWidget(widgetClass)
    self.registeredWidgets[widgetClass.type] = widgetClass

    -- every widget takes part in the container layout, so the sizing hints are shared
    widgetClass.SetRelativeWidth = widgetClass.SetRelativeWidth or function(widget, fraction)
        widget.relativeWidth = fraction
        widget.fullWidth = nil
        return widget
    end

    widgetClass.SetFullWidth = widgetClass.SetFullWidth or function(widget, isFull)
        widget.fullWidth = isFull ~= false
        widget.relativeWidth = nil
        return widget
    end

    -- also allocate a frame pool for this widget type if it doesn't exist yet
    if not self.framePools[widgetClass.type] then
        self.framePools[widgetClass.type] = {}
    end
end

---The registered class of a widget type, used by the widgets which extend another widget
---@param widgetType string the widget type
---@return table widgetClass
function UICore:GetWidgetClass(widgetType)
    local widgetClass = self.registeredWidgets[widgetType]
    if not widgetClass then
        error(string.format(ERROR_MSG["InvalidType"], tostring(widgetType)))
    end

    return widgetClass
end

---Release the widget to the pool for later re-use
---@param widget table the widget to be released
function UICore:ReleaseToPool(widget)
    if not self.framePools[widget.type] then
        error(string.format(ERROR_MSG["InvalidType"], tostring(widget.type)))
    end

    -- release the widget to the pool for later re-use
    -- and reset the widget to its default state
    widget:Release()

    -- the sizing hints are owned by the container the widget was in, not by the widget
    widget.relativeWidth = nil
    widget.fullWidth = nil

    table.insert(self.framePools[widget.type], widget)
end

---Build a widget of the given type, either from the pool or by creating a new one
---@param widgetType string the widget type
---@return table widget the widget
function UICore:Build(widgetType)
    local widget = FetchWidgetFromPool(self, widgetType)

    -- if the widget is nil, it means the pool is empty, then we need to build a new widget
    if not widget then
        widget = self.registeredWidgets[widgetType]:Create()
    else
        widget:Reuse()
    end

    return widget
end

-- MARK: hover
local HOVER_COLOR = {1, 1, 1, 0.25}

---Build hover effect for an arbitrary frame
---@param frame frame an arbitrary frame
---@return Texture hover the hover frame
function UICore:BuildHover(frame)
    local hover = frame:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetBlendMode("ADD")
    hover:SetColorTexture(unpack(HOVER_COLOR))
    return hover
end

---Show a game tooltip while the widget is hovered
---@param widget table any widget which supports SetOnEnter and SetOnLeave
---@param text string the tooltip text
---@param anchor string? the tooltip anchor, defaults to ANCHOR_BOTTOMRIGHT
function UICore:SetTooltip(widget, text, anchor)
    widget:SetOnEnter(function()
        GameTooltip:SetOwner(widget.frame, anchor or "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetOnLeave(function()
        GameTooltip:Hide()
    end)
end

-- MARK: color
function UICore:ResetColorCycle()
    self.colorCycleIndex = 1
end
function UICore:GetNextColorCycle()
    local color = COLOR_CYCLE[self.colorCycleIndex]
    self.colorCycleIndex = self.colorCycleIndex + 1
    if self.colorCycleIndex > #COLOR_CYCLE then
        self.colorCycleIndex = 1
    end

    return color
end

-- MARK: Container contents
local WIDGET_SPACING = 8

---Placed in the content of a container to force a line break
UICore.ROW_BREAK = { type = "RowBreak" }

---Resize a widget to the width it asked for, relative to its container
---@param container table the container widget
---@param widget table the widget to be sized
function UICore:ApplyLayoutWidth(container, widget)
    local width
    if widget.fullWidth then
        width = container:GetWidth()
    elseif widget.relativeWidth then
        width = container:GetWidth() * widget.relativeWidth
    end

    if width then
        widget:SetSize(math.max(1, width - WIDGET_SPACING), widget:GetHeight())
    end
end

---For container widgets, compute the current and next content X and Y
---@param container table the container widget
---@param widget table the widget to be added to the container
function UICore:ComputeContentPosition(container, widget)
    local currentX, currentY = container:GetContentPosition()
    local width, height = widget:GetWidth(), widget:GetHeight()
    local rowMaxHeight = math.max(container.rowMaxHeight or 0, height)
    -- firstly, compute if the current row can fit the widget
    if currentX > 0 and currentX + width > container:GetWidth() then -- if the current row is full, then move to the next row
        -- if not, move to the next row
        currentX = 0
        currentY = currentY + rowMaxHeight + WIDGET_SPACING
        rowMaxHeight = height -- the new row starts over with the height of this widget
    end

    -- update the container's content position for the next widget
    container.contentX = currentX + width + WIDGET_SPACING
    container.contentY = currentY
    container.rowMaxHeight = rowMaxHeight

    return currentX, currentY
end

---Get the directory of the UI
---@return string the directory of the UI
function UICore:GetUIDirectory()
    return "Interface\\AddOns\\" .. ADDON_NAME .. "\\GUI\\"
end

-- initialize UI Utility
addon.UICore = UICore