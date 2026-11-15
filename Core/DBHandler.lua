local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

---@class DBHandler
---@field dbDefaults table the default database structure and default values for modules' options
local DBHandler = {}
--[[
    DBHandler is responsible for managing the addon's database
    Focus on fetching db for modules, storing and reseting database with default values, and updating database structure.

    Public Methods:
        - Initialize: Initializes the DBHandler and sets up the default database structure.
        - RegisterDBDefaults: Registers the default database structure and default values for a module.
        - ValidateModuleDatabase: Resets the database value for a specific module and option if it doesn't match the default value.
        - ValidateDatabase: Validates the database and sets up default values for first-time use.
]]

---Build a safe copy of the default value, handling tables correctly to avoid reference issues
---@param defaultVal any the default value to copy
---@return any value a copy of defaultVal (shallow copy if it's a table)
local function CopyDefaultValue(defaultVal)
    if type(defaultVal) == "table" then
        local copy = {}
        for k, v in pairs(defaultVal) do
            copy[k] = v
        end
        return copy
    else
        return defaultVal
    end
end

---Initialize the DBHandler instance
function DBHandler:Initialize()
    self.dbDefaults = {}

    addon.core.DBHandler = self
end

---Register default database structure and default values for a module
---@param mod string module key
---@param defaults table default values for the module's options
function DBHandler:RegisterDBDefaults(mod, defaults)
    self.dbDefaults[mod] = defaults
end

---Validate and optionally reset the database values for a specific module
---@param mod string module key
---@param resetValues? boolean whether to reset the module's database values to defaults not only validate the types
---@return boolean success if the value was reset
function DBHandler:ValidateModuleDatabase(mod, resetValues)
	if type(addon.db[mod]) ~= "table" then
		addon.db[mod] = {}
	end

    -- iterate through database of the module
    -- reset default values if existing values don't match the default type
    -- if resetValues is not true, only validate the types and correct the mismatched types to default values
    -- if resetValues is true, reset the value to the default value regardless of its current type
    -- if the default value is a table, need to copy the table instead of directly assigning it to avoid reference issues
    local reset = false
    for name, defaultVal in pairs(self.dbDefaults[mod] or {}) do
        if resetValues then
            addon.db[mod][name] = CopyDefaultValue(defaultVal)
            reset = true
        elseif type(addon.db[mod][name]) ~= type(defaultVal) then
            addon.db[mod][name] = CopyDefaultValue(defaultVal)
            reset = true
        end
    end

    -- also clean up non-matching variables
    for name, value in pairs(addon.db[mod]) do
        if self.dbDefaults[mod][name] == nil then
            addon.db[mod][name] = nil
        end
    end

	return reset
end

---Validate the database and set up default values for first-time use
function DBHandler:ValidateDatabase()
	-- also reset configs before v3.0 version(no DB.Version before v3.0)
	if type(MidnightFocusInterrupt_DB) ~= "table" or not MidnightFocusInterrupt_DB["Version"] then
		MidnightFocusInterrupt_DB = {}
		addon.Utility:print("Profile database initialized.")

		addon.Utility:SetPopupDialog(ADDON_NAME .. "ConfigRest", L["Welecome"], true)
  	end

    -- assign the global database table to the addon's db field
	addon.db = MidnightFocusInterrupt_DB
	addon.db["Version"] = addon.version
	if type(addon.db["MinimapIcon"]) ~= "table" then
		addon.db["MinimapIcon"] = {hide = false}
	end

    if type(self.dbDefaults) == "table" then
        -- iterate through all modules and their default options to ensure the database has the correct structure
        for mod, optionList in pairs(self.dbDefaults or {}) do
            DBHandler:ValidateModuleDatabase(mod, false)
        end
    end
end

-- MARK: Initialize DBHandler
DBHandler:Initialize()
