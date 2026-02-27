local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

addon.LSM = LibStub("LibSharedMedia-3.0")

local optionOrder = 1

---Show the RLNeeded popup dialog
---@param dialogName string dialog name
function addon:ShowDialog(dialogName)
	StaticPopup_Show(dialogName)
end

---Handle option group order for options creations
-- ---@return integer order the order of this option group
-- function addon:OptionOrderHandler()
-- 	local output = optionOrder
-- 	optionOrder = optionOrder + 1
-- 	return output
-- end

-- function addon:AppendOptionsList(optionName, optionMap)
-- 	addon.optionsList[optionName] = optionMap
-- end

-- MARK: Config set ups
-- set up  configurationList
addon.configurationList = {}
-- set up optionsList according to ACEConfig format
-- make the Test(Unlock) option at the beginning
local optionsList = {
	Welecome = {
		type = "group",
		name = "Welcome",
		order = 1,
		args = {
			Welecome = {
				type = "description",
				name = L["WelecomeSetting"],
				order = 1,
			},
			OpenMenu = {
				type = "execute",
				name = "|cff8788ee/mfi|r",
				func = function()
					addon.GUI:OpenGUI()
				end,
				order = 2,
				width = "full",
			},
		},
		inline = true,
	},
	DeveloperTools = {
		type = "group",
		name = "Developer Tools",
		order = 2,
		args = {
			PrintInfo = {
				type = "execute",
				name = "Print Addon Info",
				func = function()
					addon.DeveloperTools:DisplayAddonInfo()
				end,
			},
		},
		inline = true,
	},
}
addon.optionsList = optionsList
--set up RLNeeded popup dialog
addon.Utilities:SetPopupDialog(ADDON_NAME .. "RLNeeded", L["ReloadNeeded"], false, {button1 = L["Reload"], button2 = CLOSE, OnButton1 = ReloadUI})