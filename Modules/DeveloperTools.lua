local ADDON_NAME, addon = ...
local AceGUI = LibStub("AceGUI-3.0")
local GUI = addon.GUI

---@class DeveloperTools
---@field displayFrame frame|nil a frame to display developer tool's outputs
addon.DeveloperTools = {
    displayFrame = nil,
    isOpened = false,
}

-- MARK: Constants
local TABS = {
    {text = "Copy Info", value = "CopyInfo"},
    {text = "Modules Info", value = "ModulesInfo"},
    {text = "States Info", value = "StatesInfo"},
}

-- private methods

local function RenderDisplayFrame(self, info)
    self.isOpened = true
    self.displayFrame = AceGUI:Create("Frame")
    self.displayFrame:SetTitle("|cFF8788EEHBLyx Tools|r - Developer Tools")
    self.displayFrame:SetLayout("Flow")
    self.displayFrame:SetWidth(900)
    self.displayFrame:SetHeight(600)
    self.displayFrame:SetStatusText("|cff8788ee"..  ADDON_NAME .. "|r v" .. addon:GetVersion() .. " " .. "Developer Tools")
    self.displayFrame:SetCallback("OnClose", function(widget)
        if widget then
            widget:Release()
        end

        self.isOpened = false
    end)

    local tabs = AceGUI:Create("TabGroup")
    tabs:SetLayout("Flow")
    tabs:SetFullWidth(true)
    tabs:SetFullHeight(true)
    tabs:SetTabs(TABS)
    self.displayFrame:AddChild(tabs)
    tabs:SetCallback("OnGroupSelected", function (container, _, tab)
        container:ReleaseChildren()

        if tab == "CopyInfo" then
            local panel = GUI:CreateScrollFrame(container)
            
            local addonInfo = ""
            for _, value in pairs(info) do
                addonInfo = addonInfo .. value .. "\n------\n\n"
            end

            GUI:CreateMultiLineEditBox(panel, "Copy the addon info below:", addonInfo)
            panel:DoLayout()
        elseif tab == "ModulesInfo" then
            local panel = GUI:CreateScrollFrame(container)
            GUI:CreateInformationTag(panel, info["ModulesInfo"], "LEFT")
            panel:DoLayout()
        elseif tab == "StatesInfo" then
            local panel = GUI:CreateScrollFrame(container)
            GUI:CreateInformationTag(panel, info["StatesInfo"], "LEFT")
            panel:DoLayout()
        end
    end)
    
    tabs:SelectTab("CopyInfo")
end

local function GetEventsInfo()
    local events = {}
    for event, _ in pairs(addon.core.eventMap) do
        table.insert(events, event)
    end
    table.sort(events, function (a, b)
        if #addon.core.eventMap[a] == #addon.core.eventMap[b] then
            return a < b
        end

        return #addon.core.eventMap[a] > #addon.core.eventMap[b]
    end)

    local output = "|cff8788EEEvents Info|r:\n"
    local total = 0
    
    for _, event in ipairs(events) do
        output = output .. "|cff00ff00" .. event .. "|r|cffC41E3A(" .. tostring(#addon.core.eventMap[event]) .. ")|r: "
        total = total + #addon.core.eventMap[event]
        for _, mod in ipairs(addon.core.eventMap[event]) do
            output = output .. mod .. ", "
        end
        output = output .. "\n"
    end

    output = output .. string.format("*|cff00ff00Total Events: %d|r *|cffC41E3ATotal Registers: %d|r\n", #events, total)

    return output
end

local function GetStatesInfo()
    local vars = {}
    for var, _ in pairs(addon.states) do
        table.insert(vars, var)
    end
    table.sort(vars)

    local output = "|cff8788EEStates Info|r:\n"
    
    for _, var in ipairs(vars) do
        output = output .. string.format("|cff0070DD%s|r|cffC41E3A(%s)|r: %s, ", var, type(addon.states[var]), tostring(addon.states[var]))
    end
    output = output .. "\n"

    for event, states in pairs(addon.core.statesUpdate) do
        output = output .. string.format("|cff00ff00%s|r: ", event)
        for state, _ in pairs(states) do
            output = output .. string.format("%s, ", state)
        end
        output = output .. "\n"
    end

    return output
end

local function GetModulesInfo()
    local output = "|cff8788EEModules Info|r:\n"

    output = output .. string.format("|cffFF7C0ARegistered Modules|r|cffC41E3A(%d)|r: ", addon.core.totalMods)
    for mod, _ in pairs(addon.core.registeredMods) do
        output = output .. mod .. ", "
    end
    output = output .. "\n"

    output = output .. string.format("|cff00ff00Loaded Modules|r|cffC41E3A(%d)|r: ", addon.core.loadedMods)
    for mod, _ in pairs(addon.core.modules) do
        output = output .. mod .. ", "
    end
    output = output .. "\n"

    return output
end

local function GetStateMonitorsInfo()
    local output = "|cff8788EEState Monitors Info|r:\n"

    local states = {}
    local statesCount = {}
    for state, monitors in pairs(addon.core.statesMonitor) do
        table.insert(states, state)
        statesCount[state] = 0
        for _, _ in pairs(monitors) do
            statesCount[state] = statesCount[state] + 1
        end
    end

    table.sort(states, function (a, b)
        if statesCount[a] == statesCount[b] then
            return a < b
        end

        return statesCount[a] > statesCount[b]
    end)

    for _, state in ipairs(states) do
        local str = ""
        for monitor, _ in pairs(addon.core.statesMonitor[state]) do
            str = str .. monitor .. ", "
        end
        output = output .. string.format("|cff00ff00%s|r|cffC41E3A(%d)|r: %s\n", state, statesCount[state], str)
    end

    return output
end

function addon.DeveloperTools:DisplayAddonInfo()
    local output = {}
    output["ModulesInfo"] = GetModulesInfo() .. "\n" .. GetEventsInfo()
    output["StatesInfo"] = GetStatesInfo() .. "\n" .. GetStateMonitorsInfo()

    if self.isOpened and self.displayFrame then
        self.displayFrame:Hide()
        self.displayFrame:Release()
        self.isOpened = false
    else
        RenderDisplayFrame(self, output)
    end
end