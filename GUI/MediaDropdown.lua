local addon = select(2, ...)

local Dropdown = addon.UICore:GetWidgetClass("Dropdown")

-- MARK: Default values
local PREVIEW_FONT_SIZE = 12
local PREVIEW_INSET = 2
local PREVIEW_COLOR = { 1, 1, 1, 1 }
local PREVIEW_PADDING = 16

---Build the list of a LibSharedMedia type as a key to key map
local function GetMediaList(mediaType)
    local list = {}
    for _, key in ipairs(addon.LSM:List(mediaType)) do
        list[key] = key
    end
    return list
end

--[[---------------------------------------------------------------------------
Font dropdown, every entry is rendered with the font it selects
-----------------------------------------------------------------------------]]

---@class FontDropdown : Dropdown
local FontDropdown = setmetatable({ type = "FontDropdown" }, { __index = Dropdown })

local function ApplyFontPreview(fontString, key)
    local path = key and addon.LSM:Fetch("font", key, true)
    if path then
        fontString:SetFont(path, PREVIEW_FONT_SIZE, "OUTLINE")
    end
end

function FontDropdown:FormatItem(item, key)
    Dropdown.FormatItem(self, item, key)
    ApplyFontPreview(item.text, key)
end

function FontDropdown:SetValue(value)
    Dropdown.SetValue(self, value)
    ApplyFontPreview(self.buttonText, value)
end

function FontDropdown:Create(parent, width, height, labelText, value)
    local widget = Dropdown.Create(self, parent, width, height, labelText, GetMediaList("font"))
    widget:SetSearchEnabled(true)
    widget:SetValue(value)
    return widget
end

function FontDropdown:Reuse(parent, width, height, labelText, value)
    Dropdown.Reuse(self, parent, width, height, labelText, GetMediaList("font"))
    self:SetSearchEnabled(true)
    self:SetValue(value)
    return self
end

addon.UICore:RegisterWidget(FontDropdown)

--[[---------------------------------------------------------------------------
Texture dropdown, every entry shows the status bar texture it selects
-----------------------------------------------------------------------------]]

---@class TextureDropdown : Dropdown
local TextureDropdown = setmetatable({ type = "TextureDropdown" }, { __index = Dropdown })

local function CreatePreview(frame)
    local preview = frame:CreateTexture(nil, "BACKGROUND")
    preview:SetPoint("TOPLEFT", frame, "TOPLEFT", PREVIEW_INSET, -PREVIEW_INSET)
    -- limit the preview width to keep size for the dropdown arrow
    preview:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PREVIEW_INSET - PREVIEW_PADDING, PREVIEW_INSET)
    preview:SetVertexColor(unpack(PREVIEW_COLOR))
    return preview
end

function TextureDropdown:OnItemCreated(item)
    item.preview = CreatePreview(item)
end

function TextureDropdown:FormatItem(item, key)
    Dropdown.FormatItem(self, item, key)
    item.preview:SetTexture(key and addon.LSM:Fetch("statusbar", key, true) or nil)
end

function TextureDropdown:SetValue(value)
    Dropdown.SetValue(self, value)

    -- the base constructor sets the value before the button preview exists
    if self.buttonPreview then
        self.buttonPreview:SetTexture(value and addon.LSM:Fetch("statusbar", value, true) or nil)
    end
end

function TextureDropdown:Create(parent, width, height, labelText, value)
    local widget = Dropdown.Create(self, parent, width, height, labelText, GetMediaList("statusbar"))
    widget.buttonPreview = CreatePreview(widget.button)
    widget:SetSearchEnabled(true)
    widget:SetValue(value)
    return widget
end

function TextureDropdown:Reuse(parent, width, height, labelText, value)
    Dropdown.Reuse(self, parent, width, height, labelText, GetMediaList("statusbar"))
    self:SetSearchEnabled(true)
    self:SetValue(value)
    return self
end

addon.UICore:RegisterWidget(TextureDropdown)

--[[---------------------------------------------------------------------------
Sound dropdown, every entry has a speaker which plays it
-----------------------------------------------------------------------------]]

---@class SoundDropdown : Dropdown
local SoundDropdown = setmetatable({ type = "SoundDropdown" }, { __index = Dropdown })

local SPEAKER_SIZE = 14
local SPEAKER_TEXTURE = addon.UICore:GetUIDirectory() .. "Assets\\Media_Play.png" -- Interface\\Common\\VoiceChat-Speaker
local SPEAKER_ON_TEXTURE = addon.UICore:GetUIDirectory() .. "Assets\\Media_Play.png" -- Interface\\Common\\VoiceChat-On

-- the sound list of LibSharedMedia is fetched once and then shared by every sound dropdown
local soundList

local function GetSoundList()
    if not soundList then
        soundList = GetMediaList("sound")
    end
    return soundList
end

local function PreviewSound(key)
    local path = key and addon.LSM:Fetch("sound", key, true)
    if path then
        PlaySoundFile(path, "Master")
    end
end

---A speaker button which previews the sound without changing the selection
local function CreateSpeaker(parent, getKey)
    local speaker = CreateFrame("Button", nil, parent)
    speaker:SetSize(SPEAKER_SIZE, SPEAKER_SIZE)

    local icon = speaker:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(SPEAKER_TEXTURE)
    icon:SetAllPoints(speaker)

    local iconOn = speaker:CreateTexture(nil, "HIGHLIGHT")
    iconOn:SetTexture(SPEAKER_ON_TEXTURE)
    iconOn:SetAllPoints(speaker)

    speaker:SetScript("OnClick", function() PreviewSound(getKey()) end)

    return speaker
end

function SoundDropdown:OnItemCreated(item)
    item.speaker = CreateSpeaker(item, function() return item.key end)
    item.speaker:SetPoint("RIGHT", item, "RIGHT", -PREVIEW_INSET, 0)

    -- keep the text clear of the speaker
    item.text:SetPoint("RIGHT", item.speaker, "LEFT", -PREVIEW_INSET, 0)
end

function SoundDropdown:Create(parent, width, height, labelText, value)
    local widget = Dropdown.Create(self, parent, width, height, labelText, GetSoundList())

    widget.speaker = CreateSpeaker(widget.button, function() return widget.value end)
    widget.speaker:SetPoint("RIGHT", widget.arrow, "LEFT", -PREVIEW_INSET, 0)
    widget.buttonText:SetPoint("RIGHT", widget.speaker, "LEFT", -PREVIEW_INSET, 0)

    widget:SetSearchEnabled(true)
    widget:SetValue(value)

    return widget
end

function SoundDropdown:Reuse(parent, width, height, labelText, value)
    Dropdown.Reuse(self, parent, width, height, labelText, GetSoundList())
    self:SetSearchEnabled(true)
    self:SetValue(value)
    return self
end

addon.UICore:RegisterWidget(SoundDropdown)
