local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
--[[
    Core structure, mirrored from the HBLyx_Tools re-factor (see that addon's HB_Addon.md for the full rationale):
		- addon utility methods(static) load with core(before) with "Utility" (renamed from "Utilities")
        - event and state management is seperated into EventsHandler
        - module management is seperated into ModuleHandler
        - core manages addon db directly through DBHandler
        - the initialize and configuration initialize in the core itself(in this file)

	Thus, the toc file contains core.xml first, and get modules and config also loaded through xml also
]]--

---@class Core
---@field EventsHandler table the event handler instance
---@field ModuleHandler table the module handler instance
---@field DBHandler table the database handler instance
local Core = {}
addon.core = Core

-- MARK: Facade

---Forward addon.core:<methodName>(...) calls to the sub-handler that actually implements it,
---so existing call sites across Modules/Configs/GUI keep working against a single addon.core API.
---@param handlerField string field on Core holding the sub-handler instance ("ModuleHandler"/"EventsHandler"/"DBHandler")
---@param methodName string name of the method to forward
local function Delegate(handlerField, methodName)
	Core[methodName] = function(self, ...)
		return self[handlerField][methodName](self[handlerField], ...)
	end
end

for _, methodName in ipairs({
	"RegisterModule", "HasModuleLoaded", "LoadModule", "UnloadModule", "LoadAllModules",
	"GetModule", "GetModuleName", "GetSafeUpdate", "ToggleModule", "GetModuleList",
	"GetLoadedModulesList", "GetUnloadedModulesList", "TestMode", "TestModule", "IsTestOn",
}) do
	Delegate("ModuleHandler", methodName)
end

for _, methodName in ipairs({
	"RegisterEvent", "UnregisterEvent", "RegisterState", "RegisterStateMonitor", "UnregisterStateMonitor",
	"GetEventInfo", "GetStateEventInfo", "GetStatesInfo", "GetStatesMonitorInfo",
}) do
	Delegate("EventsHandler", methodName)
end

for _, methodName in ipairs({
	"RegisterDBDefaults", "ValidateModuleDatabase", "ValidateDatabase",
}) do
	Delegate("DBHandler", methodName)
end

---Show the "reload needed" popup (owned by Utility, forwarded here since most callers go through addon.core)
function Core:ShowReloadPopup()
	addon.Utility:ShowReloadPopup()
end

---Register in-game Slash Command
local function SetUpSlashCommand()
	SLASH_MFI1 = "/mfi"
	SLASH_MFI2 = "/midnightfocusinterrupt"
	SlashCmdList["MFI"] = function(message)
		local command, rest = strsplit(" ", message, 2)
		if command == "" then
			if addon.GUI and addon.GUI.isOpened then
				addon.GUI:CloseGUI()
			else
				addon.GUI:OpenGUI()
			end
		elseif command == "dev" or command == "developer" then
			addon.Developer:DisplayAddonInfo()
		elseif command == "test" or command == "unlock" then
			addon.core:TestMode()
		end
	end
end

---Register the LibDataBroker (LDB) object for the addon
local function RegisterLDB()
	-- LDB register
	local ldb = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
		type = "data source",
		text = ADDON_NAME,
		label = "|cff8788ee" .. ADDON_NAME .. "|r",
		icon = "Interface\\AddOns\\MidnightFocusInterrupt\\Media\\HBLyx.png",
		OnClick = function(_, button)
			if button == "LeftButton" then
				addon.GUI:OpenGUI()
			elseif button == "RightButton" then
				addon.core:TestMode()
			end
		end,

		OnTooltipShow = function(tooltip)
			tooltip:AddLine("|cff8788ee" .. ADDON_NAME .. "|r")
			tooltip:AddLine(string.format("|cff00ff00%s|r: %s", L["LeftButton"], L["ConfigPanel"]))
			tooltip:AddLine(string.format("|cff00ff00%s|r: %s", L["RightButton"], L["EditMode"]))
		end,
	})
	LibStub("LibDBIcon-1.0"):Register(ADDON_NAME, ldb, addon.db["MinimapIcon"])
end

-- MARK: Initialize Core

---Initialize the core of the addon, including setting up the LDB, slash commands, and default configurations.
function Core:Initialize()
    addon.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

    self.DBHandler:ValidateDatabase()
    RegisterLDB()
    SetUpSlashCommand()
    self.EventsHandler:InitializeStates()
    self.ModuleHandler:LoadAllModules()

    addon.Utility:print(L["WelecomeSetting"])
end

---Configure the basic environment for the addon, including popup dialogs and media settings
function Core:Configure()
    -- set up RLNeeded popup dialog
    addon.Utility:SetPopupDialog(ADDON_NAME .. "RLNeeded", L["ReloadNeeded"], false, {button1 = L["Reload"], button2 = CLOSE, OnButton1 = ReloadUI})
    -- set up LibSharedMedia and defult media for the addon
    addon.LSM = LibStub("LibSharedMedia-3.0")
    addon.LSM:Register("sound", "[HBLyx] Notification", "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Sound\\notification.ogg")
    addon.LSM:Register("sound", "[HBLyx] Info", "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Sound\\info.ogg")
    addon.DEFAULTS = {
        font = addon.LSM:Fetch("font", addon.LSM:GetDefault("font")) or "Fonts\\FRIZQT__.TTF",
    }
end

Core:Configure()
