local ADDON_NAME, addon = ...

---@class Core
---@field eventFrame Frame the frame used to register events
---@field eventMap table<string, {mods: table<string>, units: table<string, boolean>}> map of events to the modules and units registered for it, just record for developers
---@field modules table<string, table> map of module key to module instance, used to store
---@field registeredMods table<string, table> map of module key to module initialize and event register function, used to store the registered modules before they are loaded
---@field totalMods number total number of registered modules, used to check if all modules are loaded
---@field loadedMods number total number of loaded modules, used to check if all modules are loaded
---@field testMode boolean if the addon is in test mode
---@field statesUpdate table<string, table<string, function>> map of event to map of addon state to update function
---@field statesMonitor table<string, table<string, function>> map of addon state to map of module to monitor function
local Core = {}

-- MARK: Initialize

---Initialize/Constructor
---@return Core
function Core:Initialize()
    self.eventFrame = CreateFrame("Frame")
    self.eventMap = {}
    self.modules = {}
    self.registeredMods = {}
    self.totalMods = 0
    self.loadedMods = 0
    self.testMode = false
    self.registeredStates = {}
    self.statesUpdate = {}
    self.statesMonitor = {}

    self.eventFrame:RegisterEvent("ADDON_LOADED") -- "ADDON_LOADED" is automatically registered
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- "PLAYER_ENTERING_WORLD" is automatically registered

    return self
end

-- private methods

-- MARK: Event Handler

---Handle events
---@param event string event name
---@param ... unknown other args passed to the handler
local function Handle(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            addon:Initialize()
        end
    end
    -- move all UpdateStyle after "PLAYER_ENTERING_WORLD" to make sure all addon has loaded medias
    -- prevent cannot load the medias which is loaded by other addons loaded later than this addon
    if event == "PLAYER_ENTERING_WORLD" then
        for mod, _ in pairs(self.modules) do
            self:GetSafeUpdate(mod)()
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

-- public methods
-- MARK: Register Event

---Call to let Manager register this event with the function
---@param event string event name
---@param frame frame the frame used to hook the event
---@param mod string module name/key
---@param unit nil|string|table<string>? if this is a unit event, the unit name or units list
function Core:RegisterEvent(event, frame, mod, unit)
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

-- MARK: Register State

---Register addon state to the core
---@param event string event name
---@param unit nil|string|table<string>? if this is a unit event, the unit name or units list
---@param name string name of the addon state
---@param updateFunc function function used to update the addon state when the event is triggered
function Core:RegisterState(event, unit, name, updateFunc)
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
end

-- MARK: Register State Monitor

---Register a module to an addon state, call the monitor function when the state is updated
---@param stateName string name(key) of the addon state
---@param moduleName string name(key) of the module
---@param monitorFunc function function used to monitor the addon state, it will be called with the delta of the state value when the state is updated
function Core:RegisterStateMonitor(stateName, moduleName, monitorFunc)
    if not self.statesMonitor[stateName] then
        self.statesMonitor[stateName] = {}
    end

    self.statesMonitor[stateName][moduleName] = monitorFunc
end

-- MARK: Register Module

---Register module to the manager(not initialized so far)
---@param mod string module key
---@param name string localized display name of the module
---@param initializeFunc function function used to initialize module
function Core:RegisterModule(mod, name, initializeFunc)
    self.registeredMods[mod] = {name = name, initialize = initializeFunc}
    self.totalMods = self.totalMods + 1
end

-- MARK: Check Module Loaded

---Check if the module has been loaded
---@param mod string module key
---@return boolean if the module is loaded
function Core:HasModuleLoaded(mod)
    return self.modules[mod] ~= nil
end

-- MARK: Load module

---Load(initialize and register events) the module
---@param mod string module key
---@return boolean if the module is loaded after this call
function Core:LoadModule(mod)
    local loadedAlready = self:HasModuleLoaded(mod)

    if not loadedAlready and self.registeredMods[mod] and addon.db[mod]["Enabled"] then
        local success, result = pcall(self.registeredMods[mod].initialize)
        self.modules[mod] = success and result or nil
        if not success then -- otherwise the module silently stays unloaded
            addon.Utilities:print(string.format("|cffff0000%s failed to load|r: %s", mod, tostring(result)))
            return false
        end
        if self.modules[mod] and self.modules[mod].RegisterEvents then
            self.modules[mod]:RegisterEvents()
            self.loadedMods = self.loadedMods + 1
        end
        return true
    elseif loadedAlready then -- if the module is already loaded, it has been loaded
        return true
    end

    return false
end

---Load all registered modules
function Core:LoadAllModules()
    for mod, _ in pairs(self.registeredMods) do
        self:LoadModule(mod)
    end
end

---Get a module instance
---@param mod string module key
---@return table|nil module module instance or nil if not loaded
function Core:GetModule(mod)
    if self:HasModuleLoaded(mod) then
        return self.modules[mod]
    else
        return nil
    end
end

---Get the display name of a module
---@param mod string module key
---@return string|nil name the display name of the module or nil if not loaded
function Core:GetModuleName(mod)
    if self.registeredMods[mod] then
        return self.registeredMods[mod].name
    else
        return nil
    end
end

---Get the list of loaded modules
---@param useKey boolean|nil if true, return the module keys instead of names
---@return table, number output list of loaded modules, count of loaded modules
function Core:GetLoadedModulesList(useKey)
    local output = {}
    for mod, _ in pairs(self.modules) do
        if useKey then
            table.insert(output, mod)
        else
            table.insert(output, self.registeredMods[mod].name)
        end
    end

    return output, #output
end

---Get the list of unloaded modules
---@param useKey boolean|nil if true, return the module keys instead of names
---@return table, number list of unloaded modules, count of unloaded modules
function Core:GetUnloadedModulesList(useKey)
    local output = {}
    for mod, _ in pairs(self.registeredMods) do
        if not self:HasModuleLoaded(mod) then
            if useKey then
                table.insert(output, mod)
            else
                table.insert(output, self.registeredMods[mod].name)
            end
        end
    end

    return output, #output
end

function Core:GetStatesInfo()
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

function Core:GetStatesMonitorInfo()
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

---Get "event(count): state1, state2" for every registered state update event
---@return table<string> output
function Core:GetStateEventInfo()
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

---Get "event(unit1, unit2)(count): module1, module2" for every registered event, the unit part is omitted when the event has no unit
---@return table<string> output
function Core:GetEventInfo()
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

-- MARK: Get UpdateStyle

---Get the safe update function for module
---@param mod string module key
---@return function update update function for the update module style
function Core:GetSafeUpdate(mod)
    if self:HasModuleLoaded(mod) and self.modules[mod].UpdateStyle then
        return function() self.modules[mod]:UpdateStyle() end
    else
        return function() end
    end
end

-- MARK: TestMode

---Turn on/off TestMode for all loaded modules
---@param on boolean|nil turn on or off the test mode, nil to toggle the test mode
function Core:TestMode(on)
    if on == nil then
        self.testMode = not self.testMode -- toggle test mode if on is nil
    else
        self.testMode = on -- set test mode to on if on is not nil
    end

    for _, module in pairs(self.modules) do -- for all loaded modules, call the Test function if it exists
        if module.Test then
            pcall(module.Test, module, self.testMode)
        end
    end
end

-- MARK: Module Test Mode

---Attempt to turn the test mod for the module
---@param module string module key
---@return boolean success if the test mode is turned on after this call
function Core:TestModule(module)
    if self.modules[module] and self.modules[module].Test then
        self.modules[module]:Test(self.testMode)
        return self.testMode
    end

    return false
end

-- MARK: Is Test On

---Check whether the test mode is on
---@return boolean on if the test mode is on
function Core:IsTestOn()
    return self.testMode
end

-- MARK: Get Module List

---Get All Modules List(include not-loaded)
---@return table<string> list of all registered module keys
function Core:GetModuleList()
    local output = {}
    for mod, _ in pairs(self.registeredMods) do
        table.insert(output, mod)
    end

    return output
end

-- MARK: Core Start
---Start the core, let the eventFrame hook to events
function Core:Start()
    self.eventFrame:SetScript("OnEvent", function (_, event, ...)
        Handle(self, event, ...)
    end)
end

-- MARK: Main-Initialize Core
addon.core = Core:Initialize()