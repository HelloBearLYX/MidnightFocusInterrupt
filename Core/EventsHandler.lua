local ADDON_NAME, addon = ...

---@class EventsHandler
---@field eventFrame frame the frame used to register events
---@field eventMap table<string, {mods: string[], units: table<string, boolean>}> map of events to the modules and units registered for it
---@field statesUpdate table<string, table<string, function>> map of events to state update functions
---@field statesMonitor table<string, table<string, function>> map of states to monitor functions
---@field registeredStates table<string, boolean> map of registered states
local EventsHandler = {}
--[[
    Handles the registration and management of events and addon states for the addon.
    The two types of handlers are event handlers and state handlers.
    Event handlers respond to game events, while state handlers manage addon-specific states.
    State handler is basically based on game events or other data source, and updates the addon state accordingly.
    Both handlers works collectively to manage the addon's behavior and state based on game events and other data sources.
    
    NOTE:
        - "ADDON_LOADED" event is used to initialize the addon when it is loaded, so it has been registered by default.
        - Since the event is actually baed on frame, and unit events require specifying the unit. 
            - Nevertheless, some module may need a frame to take multiple unit for a same unit event, so the frame-based registration is still necessary.
            - In other words, the event handler does not really register the events with the core's event frame directly, but use the frame provided by the module to register the events to avoid multiple units for the same event
            - Thus, the event handler actually merely record the events registered and unregister them when necessary.

    Public Methods:
        - Initialize: Initializes the event handler and sets up default events.
        - RegisterEvent: Registers an event with the event handler.
        - UnregisterEvent: Unregisters an event from the event handler.
        - RegisterState: Registers a state with the event handler.
        - RegisterStateMonitor: Registers a callback function for a specific state.
        - UnregisterStateMonitor: Unregisters a callback function for a specific state.
        
        - GetEventInfo: Retrieves information about the currently registered events.
        - GetStateEventInfo: Retrieves information about the event associated with a specific state.
        - GetStatesInfo: Retrieves information about the current states.
        - GetStatesMonitorInfo: Retrieves information about the current state monitors.
]]--

-- MARK: Private Methods

---Handle events
---@param event string event name
---@param ... unknown other args passed to the handler
local function Handle(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            addon.core:Initialize()
        end
    end

    -- let state update first
    for name, func in pairs(self.statesUpdate[event] or {}) do
        local delta = func(...)
        for _, monitorFunc in pairs(self.statesMonitor[name] or {}) do
            monitorFunc(delta)
        end
    end
end

-- MARK: Public Methods

function EventsHandler:Initialize()
    self.eventFrame = CreateFrame("Frame") -- the frame used to register events
    self.eventMap = {} -- map of events to the modules and units registered for it, just record for developers
    self.statesUpdate = {} -- map of events to state update functions
    self.statesMonitor = {} -- map of states to monitor functions
    self.registeredStates = {} -- map of registered states

    -- defaultly register "ADDON_LOADED" and "PLAYER_ENTERING_WORLD"
    self.eventFrame:RegisterEvent("ADDON_LOADED")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        Handle(self, event, ...)
    end)

    -- initialize the event handler for the core
    addon.core.EventsHandler = self
end

-- MARK: Initialize States

---Initialize addon states
---@param self table the event handler instance
function EventsHandler:InitializeStates()
    addon.states = addon.states or {}

    -- interface number
    -- GetBuildInfo is available at ADDON_LOADED, before modules initialize.
    local interfaceNumber = select(4, GetBuildInfo())
    self:RegisterState("ADDON_LOADED", nil, "interfaceNumber", interfaceNumber, function() end)

	-- player class (this addon only needs to refresh it after "PLAYER_ENTERING_WORLD", unlike HBLyx_Tools)
	local playerClass = select(2, UnitClass("player"))
	self:RegisterState("PLAYER_ENTERING_WORLD", nil, "playerClass", playerClass, function()
		addon.states["playerClass"] = select(2, UnitClass("player"))
	end)

	-- player spec state
	local GetSpec = function ()
		addon.states["playerSpec"] = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
	end
	local playerSpec = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
	self:RegisterState("PLAYER_ENTERING_WORLD", nil, "playerSpec", playerSpec, GetSpec) -- the spec cannot be initialized when "ADDON_LOADED", it must be initialized after "PLAYER_ENTERING_WORLD"
	self:RegisterState("PLAYER_SPECIALIZATION_CHANGED", nil, "playerSpec", playerSpec, GetSpec)
end

-- MARK: Register Event

---Call to let Manager register this event with the function
---@param event string event name
---@param frame frame the frame used to hook the event
---@param mod string module name/key
---@param unit nil|string|table<string>? if this is a unit event, the unit name or units list
function EventsHandler:RegisterEvent(event, frame, mod, unit)
    if not self.eventMap[event] then
        self.eventMap[event] = { mods = {}, units = {} }
    end

    table.insert(self.eventMap[event].mods, mod)

    if unit then
        if type(unit) == "table" then
            for _, u in ipairs(unit) do
                self.eventMap[event].units[u] = true
            end
            frame:RegisterUnitEvent(event, unpack(unit))
        else
            self.eventMap[event].units[unit] = true
            frame:RegisterUnitEvent(event, unit)
        end
    else
        frame:RegisterEvent(event)
    end
end

-- MARK: Unregister Event

---Call to let Manager unregister this event for the module
---@param event string event name
---@param frame frame the frame used to hook the event
---@param mod string module name/key
function EventsHandler:UnregisterEvent(event, frame, mod)
    frame:UnregisterEvent(event)

    local info = self.eventMap[event]
    if not info then
        return
    end

    for i = #info.mods, 1, -1 do
        if info.mods[i] == mod then
            table.remove(info.mods, i)
        end
    end

    if #info.mods == 0 then
        self.eventMap[event] = nil
    end
end

-- MARK: Register State

---Register addon state to the core
---@param event string event name
---@param unit nil|string|table<string>? if this is a unit event, the unit name or units list
---@param name string name of the addon state
---@param updateFunc function function used to update the addon state when the event is triggered
function EventsHandler:RegisterState(event, unit, name, initializeValue, updateFunc)
    if not self.statesUpdate[event] then
        self.statesUpdate[event] = {}
    end

    self.statesUpdate[event][name] = updateFunc

    if unit then
        if type(unit) == "table" then
            self.eventFrame:RegisterUnitEvent(event, unpack(unit))
        else
            self.eventFrame:RegisterUnitEvent(event, unit)
        end
    else
        self.eventFrame:RegisterEvent(event)
    end

    if not self.registeredStates[name] then
        self.registeredStates[name] = true
    end

    if not addon.states then
        addon.states = {}
    end

    addon.states[name] = initializeValue
end

-- MARK: State Monitor

---Register a module to an addon state, call the monitor function when the state is updated
---@param stateName string name(key) of the addon state
---@param moduleName string name(key) of the module
---@param monitorFunc function function used to monitor the addon state, it will be called with the delta of the state value when the state is updated
function EventsHandler:RegisterStateMonitor(stateName, moduleName, monitorFunc)
    if not self.statesMonitor[stateName] then
        self.statesMonitor[stateName] = {}
    end

    self.statesMonitor[stateName][moduleName] = monitorFunc
end

---Unregister a module from an addon state
---@param stateName string name(key) of the addon state
---@param moduleName string name(key) of the module
function EventsHandler:UnregisterStateMonitor(stateName, moduleName)
    if self.statesMonitor[stateName] then
        self.statesMonitor[stateName][moduleName] = nil
    end
end

-- MARK: Info Fetch APIs

---Get "event(unit1, unit2)(count): module1, module2" for every registered event, the unit part is omitted when the event has no unit
---@return table<string> output list of formatted strings representing the events
function EventsHandler:GetEventInfo()
    local output = {}
    for event, info in pairs(self.eventMap) do
        local entry = "|cff8788ee" .. event .. "|r"

        local unitNames = {}
        for unit, _ in pairs(info.units) do
            table.insert(unitNames, unit)
        end
        if #unitNames > 0 then
            entry = entry .. "(" .. table.concat(unitNames, ", ") .. ")"
        end

        entry = entry .. "(" .. #info.mods .. "): " .. table.concat(info.mods, ", ")
        table.insert(output, entry)
    end

    return output
end

---Get "event(count): state1, state2" for every registered state update event
---@return table<string> output list of formatted strings representing the state update events
function EventsHandler:GetStateEventInfo()
    local output = {}
    for event, states in pairs(self.statesUpdate) do
        local stateNames = {}
        for state, _ in pairs(states) do
            table.insert(stateNames, state)
        end
        table.sort(stateNames)

        local entry = "|cff8788ee" .. event .. "|r(" .. #stateNames .. "): " .. table.concat(stateNames, ", ")
        table.insert(output, entry)
    end
    table.sort(output)

    return output
end

---Get information about all registered addon states
---@return table<string> output list of formatted strings representing the states
function EventsHandler:GetStatesInfo()
    local output = {}
    for state, _ in pairs(self.registeredStates) do
        -- if the states is a table, include all values in it
        if type(addon.states[state]) == "table" then
            for k, v in pairs(addon.states[state]) do
                table.insert(output, string.format("|cff8788ee%s|r.|cff0070DD%s|r: %s|cffFF7C0A %s|r", state, k, tostring(v), type(v)))
            end
        else
            local entry = "|cff8788ee" .. state .. "|r: "
            entry = entry .. tostring(addon.states[state])
            entry = entry .. string.format("|cffFF7C0A %s|r", type(addon.states[state]))
            table.insert(output, entry)
        end
    end

    return output
end

---Get information about all registered state monitors
---@return table<string> output list of formatted strings representing the state monitors
function EventsHandler:GetStatesMonitorInfo()
    local output = {}
    for state, mods in pairs(self.statesMonitor) do
        -- mods maps module name to monitor function, so it must be collected with pairs, not ipairs/#
        local modNames = {}
        for mod, _ in pairs(mods) do
            table.insert(modNames, mod)
        end

        local entry = "|cff8788ee" .. state .. "|r(" .. #modNames .. "): " .. table.concat(modNames, ", ")
        table.insert(output, entry)
    end

    return output
end

-- MARK: Initialize EventsHandler
EventsHandler:Initialize()
