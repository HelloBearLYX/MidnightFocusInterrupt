local ADDON_NAME, addon = ...

---@class ModuleHandler
---@field modules table<string, table> map of module key to module instance, used to store(aka. loaded modules)
---@field registeredMods table<string, table> map of module key to module initialize and event register function, used to store the registered modules before they are loaded
---@field totalMods number total number of registered modules, used to check if all modules are loaded
---@field loadedMods number total number of loaded modules, used to check if all modules are loaded
---@field frame frame frame used to hook PLAYER_ENTERING_WORLD so every loaded module's UpdateStyle runs once medias are ready
local ModuleHandler = {}
--[[
    ModuleHandler is responsible for managing addon modules, including registering, loading, and unloading them.
    It keeps track of registered modules, loaded modules, and provides methods to load and check the status of modules.
    It also manage the test mode for modules, allowing modules to be tested independently of their normal operation.

    Public Methods:
        - Initialize: Initializes the module handler.
        - RegisterModule: Registers a module with the handler.
        - HasModuleLoaded: Checks if a module has been loaded.
        - LoadModule: Loads a specific module.
        - UnloadModule: Unloads a specific module.
        - LoadAllModules: Loads all registered modules.
        - GetModule: Retrieves a module instance.
        - GetModuleName: Retrieves the display name of a module.
        - GetSafeUpdate: Retrieves a safe update function for a module.
        - ToggleModule: Toggles a module on or off.
        - GetModuleList: Retrieves a list of all registered modules.
        - GetLoadedModulesList: Retrieves a list of all loaded modules.
        - GetUnloadedModulesList: Retrieves a list of all unloaded modules.
        - TestMode: Enables or disables test mode for a module.
        - TestModule: Tests a specific module.
        - IsTestOn: Checks if test mode is currently enabled.
]]

-- MARK: Private Methods

---Call UpdateStyle on every currently loaded module
---@param self ModuleHandler
local function UpdateAllModulesStyle(self)
    for mod, _ in pairs(self.modules) do
        self:GetSafeUpdate(mod)()
    end
end

function ModuleHandler:Initialize()
    self.modules = {}
    self.registeredMods = {}
    self.totalMods = 0
    self.loadedMods = 0
    addon.testMode = false

    addon.core.ModuleHandler = self

    -- move all UpdateStyle calls to "PLAYER_ENTERING_WORLD" to make sure all addons have loaded their medias
    -- prevent cannot load the medias which is loaded by other addons loaded later than this addon
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function()
        UpdateAllModulesStyle(self)
    end)
    addon.core:RegisterEvent("PLAYER_ENTERING_WORLD", self.frame, "Core-ModuleHandler")
end

-- MARK: Module Management

---Register module to the manager(not initialized so far)
---@param mod string module key
---@param name string localized display name of the module
---@param initializeFunc function function used to initialize module
function ModuleHandler:RegisterModule(mod, name, initializeFunc)
    self.registeredMods[mod] = {name = name, initialize = initializeFunc}
    self.totalMods = self.totalMods + 1
end

---Check if the module has been loaded
---@param mod string module key
---@return boolean if the module is loaded
function ModuleHandler:HasModuleLoaded(mod)
    return self.modules[mod] and self.modules[mod].enabled
end

---Load(initialize and register events) the module
---@param mod string module key
---@return boolean if the module is loaded after this call
function ModuleHandler:LoadModule(mod)
    local loadedAlready = self:HasModuleLoaded(mod)

    if not loadedAlready and self.registeredMods[mod] and addon.db[mod]["Enabled"] then
        local success, result = pcall(self.registeredMods[mod].initialize)
        self.modules[mod] = success and result or nil
        if not success then -- otherwise the module silently stays unloaded
            addon.Utility:print(string.format("|cffff0000%s failed to load|r: %s", mod, tostring(result)))
            return false
        end
        -- some module will not initialize due to some other reason like wrong class of player
        -- these modules just return a nil but success
        -- check whether the result is nil
        if result == nil then
            return false
        end

        self.modules[mod].enabled = true
        if self.modules[mod] and self.modules[mod].RegisterEvents then
            self.modules[mod]:RegisterEvents()
        end
        self.loadedMods = self.loadedMods + 1
        return true
    elseif loadedAlready then -- if the module is already loaded, it has been loaded
        return true
    end

    return false
end

---Unload a module (disable it and unregister its events)
---@param mod string module key
---@return boolean if the module was successfully unloaded
function ModuleHandler:UnloadModule(mod)
    if self:HasModuleLoaded(mod) then
        -- do not remove the module instance from the core, only disable it and unregister its events
        self.modules[mod].enabled = false

        if self.modules[mod] and self.modules[mod].UnregisterEvents then
            self.modules[mod]:UnregisterEvents()
        end

        if self.modules[mod].Test then
            self.modules[mod]:Test(false) -- turn off the test mode for the module
        end

        self.loadedMods = self.loadedMods - 1

        return true
    end

    return false
end

---Load all registered modules
function ModuleHandler:LoadAllModules()
    for mod, _ in pairs(self.registeredMods) do
        self:LoadModule(mod)
    end
end

---Get a module instance
---@param mod string module key
---@return table|nil module module instance or nil if not loaded
function ModuleHandler:GetModule(mod)
    if self:HasModuleLoaded(mod) then
        return self.modules[mod]
    else
        return nil
    end
end

---Get the display name of a module
---@param mod string module key
---@return string|nil name the display name of the module or nil if not loaded
function ModuleHandler:GetModuleName(mod)
    if self.registeredMods[mod] then
        return self.registeredMods[mod].name
    else
        return nil
    end
end

-- MARK: Get Update Function

---Get the safe update function for module
---@param mod string module key
---@return function update update function for the update module style
function ModuleHandler:GetSafeUpdate(mod)
    if self:HasModuleLoaded(mod) and self.modules[mod].UpdateStyle then
        return function() self.modules[mod]:UpdateStyle() end
    else
        return function() end
    end
end

-- MARK: Toggle Module

---Toggle the module on or off
function ModuleHandler:ToggleModule(mod, on)
    if on then
        local success = self:LoadModule(mod)
        self:TestModule(mod) -- also check whether turn the test mode for the module
        return success
    else
        local success = self:UnloadModule(mod)
        addon.core:ShowReloadPopup()
        return success
    end
end

-- MARK: Get Module List

---Get All Modules List(include not-loaded)
---@return table<string> list of all registered module keys
function ModuleHandler:GetModuleList()
    local output = {}
    for mod, _ in pairs(self.registeredMods) do
        table.insert(output, mod)
    end

    return output
end

---Get the list of loaded modules
---@param useKey boolean|nil if true, return the module keys instead of names
---@return table, number output list of loaded modules, count of loaded modules
function ModuleHandler:GetLoadedModulesList(useKey)
    local output = {}
    for mod, modInstance in pairs(self.modules) do
        if modInstance.enabled then
            if useKey then
                table.insert(output, mod)
            else
                table.insert(output, self.registeredMods[mod].name)
            end
        end
    end

    return output, #output
end

---Get the list of unloaded modules
---@param useKey boolean|nil if true, return the module keys instead of names
---@return table, number list of unloaded modules, count of unloaded modules
function ModuleHandler:GetUnloadedModulesList(useKey)
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

-- MARK: TestMode

---Turn on/off TestMode for all loaded modules
---@param on boolean|nil turn on or off the test mode, nil to toggle the test mode
function ModuleHandler:TestMode(on)
    if on == nil then
        addon.testMode = not addon.testMode -- toggle test mode if on is nil
    else
        addon.testMode = on -- set test mode to on if on is not nil
    end

    for _, module in pairs(self.modules) do -- for all loaded modules, call the Test function if it exists
        if module.Test then
            pcall(module.Test, module, addon.testMode)
        end
    end
end

-- MARK: Module Test Mode

---Attempt to turn the test mod for the module
---@param module string module key
---@return boolean success if the test mode is turned on after this call
function ModuleHandler:TestModule(module)
    if self.modules[module] and self.modules[module].Test and self.modules[module].enabled then
        self.modules[module]:Test(addon.testMode)
        return addon.testMode
    end

    return false
end

-- MARK: Is Test On

---Check whether the test mode is on
---@return boolean on if the test mode is on
function ModuleHandler:IsTestOn()
    return addon.testMode
end

-- MARK: Initialize ModuleHandler
ModuleHandler:Initialize()