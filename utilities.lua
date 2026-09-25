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
	CENTER = "CENTER",
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

---@enum raidMarker raid target marker index to icon markup, index matches the "{rt%d}" chat icon shorthand
addon.Utilities.RaidMarkers = {}
for i = 1, 8 do
	addon.Utilities.RaidMarkers[i] = string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:0|t", i)
end

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
	elseif anchorTo == "CENTER" then
		return "CENTER"
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

---Initialize (or reuse) the editFrame layered above "frame" to catch mouse input and show a labeled highlight
---@param frame frame Blizzard frame object
---@param dbTable table the table to persist the position into (e.g. addon.db[mod] or a nested options table)
---@param xKey string the field of dbTable holding the x offset
---@param yKey string the field of dbTable holding the y offset
---@param anchorFrom string? the anchor point to attach the frame from, defaults to "CENTER"
---@param updateFunc function? additional function to call every frame while test mode is active
---@param label string? text to display on the editFrame highlight
local function InitializeEditFrame(frame, dbTable, xKey, yKey, anchorFrom, updateFunc, label)
	local function updatePosition(editFrame)
		local x, y = GetCursorPosition()
		x, y = addon.Utilities:ScreenPositionToUIPosition(x, y)
		x, y = math.floor(x + 0.5), math.floor(y + 0.5) -- round the position to integers

		frame:ClearAllPoints()
		frame:SetPoint(editFrame.anchorFrom, UIParent, "CENTER", x, y)
		return x, y
	end

	if not frame.editFrame then
		local editFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
		editFrame:EnableMouse(true)
		editFrame:SetFrameStrata("FULLSCREEN_DIALOG")
		editFrame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tile = false, tileSize = 1, edgeSize = 1,
			insets = { left = 0, right = 0, top = 0, bottom = 0 }
		})
		editFrame:SetBackdropColor(1, 1, 1, 0.5)
		editFrame:SetBackdropBorderColor(1, 1, 1, 1)

		editFrame.text = editFrame:CreateFontString(nil, "OVERLAY")
		editFrame.text:SetFont(addon.DEFAULTS.font, 10, "OUTLINE")
		editFrame.text:SetPoint("CENTER", editFrame, "TOP", 0, 0)

		editFrame:SetScript("OnMouseDown", function (self, button)
			if button == "LeftButton" and addon.core:IsTestOn() and not InCombatLockdown() then
				self.isDragging = true
				updatePosition(self)
			end
		end)

		editFrame:SetScript("OnMouseUp", function (self, button)
			if button == "LeftButton" and self.isDragging then
				self.isDragging = nil
				self.dbTable[self.xKey], self.dbTable[self.yKey] = updatePosition(self)
			end
		end)

		frame.editFrame = editFrame
	end

	local editFrame = frame.editFrame
	editFrame.dbTable, editFrame.xKey, editFrame.yKey = dbTable, xKey, yKey
	editFrame.anchorFrom = anchorFrom or "CENTER"
	editFrame.text:SetText(label or "")
	editFrame:ClearAllPoints()
	editFrame:SetAllPoints(frame)
	editFrame:SetScript("OnUpdate", function (self)
		if self.isDragging then
			updatePosition(self)
		end

		if updateFunc then
			updateFunc()
		end
	end)

	frame.editFrame = editFrame
end

-- MARK: Drag Region

---Show the drag editFrame (highlight + label + draggability) created by InitializeEditFrame
---@param frame frame Blizzard frame object
---@param dbTable table the table to persist the position into (e.g. addon.db[mod] or a nested options table)
---@param xKey string the field of dbTable holding the x offset
---@param yKey string the field of dbTable holding the y offset
---@param anchorFrom string? the anchor point to attach the frame from, defaults to "CENTER"
---@param updateFunc function? additional function to call every frame while test mode is active
---@param label string? text to display on the editFrame highlight
function addon.Utilities:ShowEditFrame(frame, dbTable, xKey, yKey, anchorFrom, updateFunc, label)
	if not dbTable or not xKey or not yKey then return end -- if missing any parameter just early return
	InitializeEditFrame(frame, dbTable, xKey, yKey, anchorFrom, updateFunc, label)
	frame.editFrame:Show()
end

---Hide the drag editFrame created by ShowEditFrame
---@param frame frame the frame previously passed to ShowEditFrame
function addon.Utilities:HideEditFrame(frame)
	if frame.editFrame then
		frame.editFrame:Hide()
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
		local classColorObj = C_ClassColor.GetClassColor(select(2, GetClassInfo(class)))
		local specsCount = C_SpecializationInfo.GetNumSpecializationsForClassID(class)
		output[class] = {}
		for specIndex = 1, specsCount do
			local specID, name, _, icon = GetSpecializationInfoForClassID(class, specIndex)
			if withColor then
				output[class][specID] = string.format("|T%d:0|t", icon) .. classColorObj:WrapTextInColorCode(name)
			else
				output[class][specID] = string.format("|T%d:0|t%s", icon, name)
			end
		end
	end

	return output
end

-- MARK: version check

---Check if the version is less than current version
---@param version string the current version
---@param targetVersion string|nil the target version to compare against, if nil, compare against the addon's current version
---@return boolean true if the version is less than target version, false otherwise
function addon.Utilities:CheckVersion(version, targetVersion)
	local mainVersion, subVersion = strsplit(".", version)
	targetVersion = targetVersion or addon.db.version or "0.0"
	local currentMainVersion, currentSubVersion = strsplit(".", targetVersion)
	mainVersion, subVersion = tonumber(mainVersion), tonumber(subVersion)
	currentMainVersion, currentSubVersion = tonumber(currentMainVersion), tonumber(currentSubVersion)

	if mainVersion < currentMainVersion or (mainVersion == currentMainVersion and subVersion < currentSubVersion) then
		return true
	end

	return false
end