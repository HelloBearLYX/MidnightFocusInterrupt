local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

---@class Utilities
addon.Utilities = {}

-- MARK: Enums

---@enum anchor anchor_To = anchor_From
addon.Utilities.Anchors = {
	LEFT = "LEFT",
	RIGHT = "RIGHT",
	TOP = "TOP",
	BOTTOM = "BOTTOM",
	TOPLEFT = "TOPLEFT",
	BOTTOMLEFT = "BOTTOMLEFT",
	TOPRIGHT = "TOPRIGHT",
	BOTTOMRIGHT = "BOTTOMRIGHT",
}

---@enum growDirection the direction to grow from anchor point
addon.Utilities.Grows = {
	LEFT = "LEFT",
	RIGHT = "RIGHT",
	UP = "UP",
	DOWN = "DOWN",
}

---@enum soundChannel sound channel
addon.Utilities.SoundChannels = {
	Master = L["SoundChannel"]["Master"],
	SFX = L["SoundChannel"]["SFX"],
	Music = L["SoundChannel"]["Music"],
	Ambience = L["SoundChannel"]["Ambience"],
	Dialog = L["SoundChannel"]["Dialog"],
}

---@enum frameStrata frame strata
addon.Utilities.FrameStrata = {
	BACKGROUND = "BACKGROUND",
	LOW = "LOW",
	MEDIUM = "MEDIUM",
	HIGH = "HIGH",
	DIALOG = "DIALOG",
	FULLSCREEN = "FULLSCREEN",
	FULLSCREEN_DIALOG = "FULLSCREEN_DIALOG",
}

-- MARK: print

---Use addon's identifier to print
---@param message string message to print
function addon.Utilities:print(message)
	print("|cff8788ee" .. ADDON_NAME .. "|r: " .. message)
end

---Debug print
---@param message string debug message
---@param callback function? additional function to call after print
function addon:debug(message, callback)
	addon.Utilities:print("|cffff0000[Debug]|r " .. message)
	if callback then
		callback()
	end
end

-- MARK: RGB Handle

---Convert a Hex string into a RGBa
---@param hex string a hex color string(6 or 8)
---@return number r red
---@return number g green
---@return number b blue
---@return number a alpha
function addon.Utilities:HexToRGB(hex)
	if string.len(hex) == 8 then
		return tonumber("0x" .. hex:sub(3, 4)) / 255, tonumber("0x" .. hex:sub(5, 6)) / 255, tonumber("0x" .. hex:sub(7, 8)) / 255, tonumber("0x" .. hex:sub(1, 2)) / 255
	end

	return tonumber("0x" .. hex:sub(1, 2)) / 255, tonumber("0x" .. hex:sub(3, 4)) / 255, tonumber("0x" .. hex:sub(5, 6)) / 255
end

---Convert a RGBa(seperated) into a Hex string
---@param r number red
---@param g number green
---@param b number blue
---@param a? number alpha
---@return string hex a Hex string of the RGBa
function addon.Utilities:RGBToHex(r, g, b, a)
	r = math.ceil(255 * r)
	g = math.ceil(255 * g)
	b = math.ceil(255 * b)
	if not a then
		return string.format("FF%02x%02x%02x", r, g, b)
	end

	a = math.ceil(255 * a)
	return string.format("%02x%02x%02x%02x", a, r, g, b)
end

-- MARK: Position Handle

---Convert a screen position into a UIParent position
---@param x number x position(screen position)
---@param y number y position(screen position)
---@return number x x position(UIParent position)
---@return number y y position(UIParent position)
function addon.Utilities:ScreenPositionToUIPosition(x, y)
	local scale = UIParent:GetEffectiveScale()
	x, y = x / scale, y / scale
	
	local centerX = GetScreenWidth() / 2
	local centerY = GetScreenHeight() / 2

	return x - centerX, y - centerY
end

-- MARK: Get AnchorTo

---Get anchor_from by anchor_to
---@param anchorTo string anchor_to
---@return string anchor_from anchor_from
function addon.Utilities:GetAnchorFrom(anchorTo)
	if anchorTo == "LEFT" then
		return "RIGHT"
	elseif anchorTo == "RIGHT" then
		return "LEFT"
	elseif anchorTo == "TOP" then
		return "BOTTOM"
	elseif anchorTo == "BOTTOM" then
		return "TOP"
	elseif anchorTo == "TOPLEFT" then
		return "BOTTOMLEFT"
	elseif anchorTo == "BOTTOMLEFT" then
		return "TOPLEFT"
	elseif anchorTo == "TOPRIGHT" then
		return "BOTTOMRIGHT"
	elseif anchorTo == "BOTTOMRIGHT" then
		return "TOPRIGHT"
	else
		error("Invalid Input")
	end
end

-- MARK: Get anchors by grow direction

---GetGrowAnchor
---@param direction string Grow direction
---@return string anchorFrom anchor point to grow from
---@return string anchorTo anchor point to grow to
function addon.Utilities:GetGrowAnchors(direction)
	if direction == "LEFT" then
		return "RIGHT", "LEFT"
	elseif direction == "RIGHT" then
		return "LEFT", "RIGHT"
	elseif direction == "UP" then
		return "BOTTOM", "TOP"
	elseif direction == "DOWN" then
		return "TOP", "BOTTOM"
	else
		error("Invalid Input")
	end
end

-- MARK: Drag Position

---Make a "frame" object draggable for re-positioning
---@param frame frame Blizzard frame object
---@param mod string the mod to access addon profile(the mod key for the addon.db[mod])
---@param xKey string the option to access addon profile(the option key for the addon.db[mod][xKey])
---@param yKey string the option to access addon profile(the option key for the addon.db[mod][xKey])
---@param updateFunc function? additional function to call in update
function addon.Utilities:MakeFrameDragPosition(frame, mod, xKey, yKey, updateFunc)
	local function updatePosition(frame)
		local x, y = GetCursorPosition()
		x, y = addon.Utilities:ScreenPositionToUIPosition(x, y)
		x, y = math.floor(x + 0.5), math.floor(y + 0.5) -- round the position to integers

		frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
		return x, y
	end

	frame:SetScript("OnMouseDown", function (self, button)
		if button == "LeftButton" and addon.core:IsTestOn() and not InCombatLockdown() then
			self.isDragging = true
			updatePosition(self)
		end
	end)

	frame:SetScript("OnMouseUp", function (self, button)
		if button == "LeftButton" and self.isDragging then
			self.isDragging = nil
			
			updatePosition(self)

			addon.db[mod][xKey], addon.db[mod][yKey] = updatePosition(self)
		end
	end)

	frame:SetScript("OnUpdate", function (self)
		if self.isDragging then
			updatePosition(self)
		end

		if updateFunc then
			updateFunc()
		end
	end)
end

-- MARK: Drag Region

---Create a drag region backgound for frame(especially non-texture like text frame)
---@param frame frame (parent)frame to take the drag region
function addon.Utilities:ShowDragRegion(frame, name)
	if frame.dragRegion then
		frame.dragRegion:Show()
		frame.dragRegion.text:Show()
		return
	end

	frame.dragRegion = frame:CreateTexture(nil, "BACKGROUND")
	frame.dragRegion:SetAllPoints()
	frame.dragRegion:SetColorTexture(0, 0, 1, 0.5)
	frame.dragRegion.text = frame:CreateFontString(nil, "OVERLAY")
	frame.dragRegion.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	frame.dragRegion.text:SetPoint("CENTER", frame.dragRegion, "TOP", 0, 0)
	frame.dragRegion.text:SetText(name or "")
end

function addon.Utilities:HideDragRegion(frame)
	if frame.dragRegion then
		frame.dragRegion:Hide()
		frame.dragRegion.text:Hide()
	end
end

-- MARK: Popup Dialog

---@param dialogName string key stored in _G.StaticPopupDialogs
---@param text string text to show in the dialog
---@param show? boolean show this dialog immediately
---@param extraFields? table extra fields to set up this dialog
function addon.Utilities:SetPopupDialog(dialogName, text, show, extraFields)
	local popupDialogs = _G.StaticPopupDialogs
	if type(popupDialogs) ~= "table" then
		popupDialogs = {}
	end

	if type(popupDialogs[dialogName]) ~= "table" then
		popupDialogs[dialogName] = {}
	end

	popupDialogs[dialogName] = {
		text = text,
		button1 = CLOSE,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	if extraFields then
		for k, v in pairs(extraFields) do
			popupDialogs[dialogName][k] = v
		end
	end

	if show then
		StaticPopup_Show(dialogName)
	end
end

-- MARK: Reset Config

---Reset a module's settings into default
---@param mod string mod key
function addon.Utilities:ResetModule(mod)
	if addon.configurationList[mod] then
		for key, value in pairs(addon.configurationList[mod]) do
			addon.db[mod][key] = value
		end
	end
end

-- MARK: OpenURL

---Create pop a dialog with url which can be copied
---@param title string title
---@param url string url to show in the dialog
function addon.Utilities:OpenURL(title, url)
    local popupDialogs = _G.StaticPopupDialogs

    if type(popupDialogs) ~= "table" then
		popupDialogs = {}
	end

    if type(popupDialogs[ADDON_NAME .. "_OpenURL"]) ~= "table" then
        popupDialogs[ADDON_NAME .. "_OpenURL"] = {}
    end

    popupDialogs[ADDON_NAME .. "_OpenURL"] = {
        text = title or "",
        button1 = CLOSE,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        hasEditBox = true,
        OnShow = function(self)
            self.EditBox:SetText(url)
            self.EditBox:SetFocus()
            self.EditBox:HighlightText()
        end,
        editBoxWidth = 300,
    }

    StaticPopup_Show(ADDON_NAME .. "_OpenURL")
end

-- MARK: Get Spell Icon String

---Get a Icon_Name(id) string by spell id
---@param spellID integer spell id
---@return string output a Icon_Name(id) string
function addon.Utilities:GetSpellIconString(spellID)
	if not spellID then return tostring(spellID) end

	local info = C_Spell.GetSpellInfo(spellID)
	local name = info and info.name or "UNKNOWN"
	local icon = info and info.iconID and "|T" .. info.iconID .. ":0|t" or ""
	
	return string.format("%s%s(%d)", icon, name, spellID)
end

---Get all specializations' Icon List
---@param withColor boolean whether to include class color in the output
---@return table<string, table<string>> specsList a table of specID to Icon_Name(specID) string for all specs, indexed by class name
function addon.Utilities:GetAllSpecIconList(withColor)
	local output = {}

	for class = 1, 13 do
		local classColor = C_ClassColor.GetClassColor(select(2, GetClassInfo(class))):GenerateHexColor()
		local specsCount = C_SpecializationInfo.GetNumSpecializationsForClassID(class)
		output[class] = {}
		for specIndex = 1, specsCount do
			local specID, name, _, icon = GetSpecializationInfoForClassID(class, specIndex)
			if withColor then
				output[class][specID] = string.format("|T%d:0|t|c%s%s|r", icon, classColor, name)
			else
				output[class][specID] = string.format("|T%d:0|t%s", icon, name)
			end
		end
	end

	return output
end