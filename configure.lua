local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

addon.LSM = LibStub("LibSharedMedia-3.0")
addon.LSM:Register("sound", "[HBLyx] Notification", "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Sound\\notification.ogg")
addon.LSM:Register("sound", "[HBLyx] Info", "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Sound\\info.ogg")
addon.DEFAULTS = {
	font = addon.LSM:Fetch("font", addon.LSM:GetDefault("font")) or "Fonts\\FRIZQT__.TTF",
}

-- MARK: Config set ups
-- set up  configurationList
addon.configurationList = {}

--set up RLNeeded popup dialog
addon.Utilities:SetPopupDialog(ADDON_NAME .. "RLNeeded", L["ReloadNeeded"], false, {button1 = L["Reload"], button2 = CLOSE, OnButton1 = ReloadUI})