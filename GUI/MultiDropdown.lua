local addon = select(2, ...)

local Dropdown = addon.UICore:GetWidgetClass("Dropdown")

---@class MultiDropdown : Dropdown
---A dropdown which keeps a set of selected keys instead of a single value.
---The pullout stays open while selecting so several entries can be toggled in a row.
local MultiDropdown = setmetatable({ type = "MultiDropdown" }, { __index = Dropdown })

-- MARK: Default values
local CHECKED_ICON = "|TInterface\\Buttons\\UI-CheckBox-Check:14:14|t "
local UNCHECKED_ICON = "|TInterface\\Buttons\\UI-CheckBox-Up:14:14|t "
local SELECTED_COLOR = { 1, 0.82, 0, 1 }
local NORMAL_COLOR = { 1, 1, 1, 1 }
local SEPARATOR = ", "

local function GetSelected(widget)
    widget.selected = widget.selected or {}
    return widget.selected
end

-- MARK: API
function MultiDropdown:IsSelected(key)
    return GetSelected(self)[key] and true or false
end

function MultiDropdown:FormatItem(item, key)
    local checked = self:IsSelected(key)
    item.text:SetText((checked and CHECKED_ICON or UNCHECKED_ICON) .. tostring(self.list[key] or key))
    item.text:SetTextColor(unpack(checked and SELECTED_COLOR or NORMAL_COLOR))
end

function MultiDropdown:GetDisplayText()
    local selected = GetSelected(self)
    local names = {}

    for _, key in ipairs(self.order or {}) do
        if selected[key] then
            table.insert(names, tostring(self.list[key] or key))
        end
    end

    if #names == 0 then
        return self.placeholder or ""
    end

    return table.concat(names, SEPARATOR)
end

function MultiDropdown:OnItemClick(key)
    local selected = GetSelected(self)
    selected[key] = not selected[key] or nil

    self:Refresh()

    if self.onValueChanged then
        self.onValueChanged(self, key, selected[key] and true or false)
    end
end

---@param value any|table a single key or a set of keys to select
function MultiDropdown:SetValue(value)
    if type(value) == "table" then
        self:SetSelectedKeys(value)
        return
    end

    local selected = GetSelected(self)
    wipe(selected)
    if value ~= nil then
        selected[value] = true
    end

    self:Refresh()
end

---@return table|nil selected the set of selected keys, nil when nothing is selected
function MultiDropdown:GetValue()
    local selected = GetSelected(self)
    return next(selected) and selected or nil
end

MultiDropdown.GetSelectedKeys = MultiDropdown.GetValue

---@param keys table a set of keys to select
function MultiDropdown:SetSelectedKeys(keys)
    local selected = GetSelected(self)
    wipe(selected)

    for key in pairs(keys or {}) do
        selected[key] = true
    end

    self:Refresh()
end

function MultiDropdown:ClearSelections()
    wipe(GetSelected(self))
    self:Refresh()
end

function MultiDropdown:Release()
    wipe(GetSelected(self))
    Dropdown.Release(self)
end

addon.UICore:RegisterWidget(MultiDropdown)
