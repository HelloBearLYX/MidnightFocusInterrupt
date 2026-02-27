local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

---@class FocusInterrupt
---@field frame frame frame for FocusInterrupt cast bar
---@field active boolean if the FocusInterrupt active
---@field interruptID integer interrupt id
---@field subInterrupt integer? if there is a second interrupt
---@field timer C_Timer? timer to handle interrupt fade out
---@field cooldownColer ColorMixin? color for interrupt on cooldown cast
---@field interruptibleColor ColorMixin? color for interruptible cast
---@field notInterruptibleColor ColorMixin? color for NOT interruptible cast
---@field interruptedColor ColorMixin? color for interrupted fade time
---@field modName string module name for db access
local FocusInterrupt = {
    modName = "FocusInterrupt",
    frame = CreateFrame("Frame", ADDON_NAME .. "_FocusInterrupt", UIParent),
    bars = {},
}

-- MARK: Constants
local UNKNOWN_SPELL_TEXTURE = 134400
local INTERRUPT_BY_CLASS = {
    DEATHKNIGHT = {DEFAULT = 47528}, -- Mind Freeze
    DEMONHUNTER = {DEFAULT = 183752}, -- Disrupt
    DRUID = {BALANCE = 78675, DEFAULT = 106839},
    EVOKER = {DEFAULT = 351338}, -- Quell
    HUNTER = {DEFAULT = 147362, SURVIVAL = 187707},
    MAGE = {DEFAULT = 2139}, -- Counterspell
    MONK = {DEFAULT = 116705}, -- Spear Hand Strike
    PALADIN = {DEFAULT = 96231}, -- Rebuke
    PRIEST = {DEFAULT = 15487}, -- Silence
    ROGUE = {DEFAULT = 1766}, -- Kick
    SHAMAN = {DEFAULT = 57994}, -- Wind Shear
    WARLOCK = {DEFAULT = 19647, DEMONOLOGY = 119914, DEMONOLOGY_SUB = 132409, GRIMOIRE = 1276467},
    WARRIOR = {DEFAULT = 6552}, -- Pummel
}

-- MARK: Initialize

---Initialize(Constructor)
---@return FocusInterrupt FocusInterrupt a FocusInterrupt object
function FocusInterrupt:Initialize()
    -- after 3.8, as implemented target bar, we need to migrate part of the database to new format(for style settings)
    local oldDBKeys = {"BackgroundAlpha", "Width", "Height", "X", "Y", "IconZoom", "Font", "FontSize"}
    for _, key in pairs(oldDBKeys) do
        if addon.db[self.modName][key] then
            addon.Utilities:print("Migrating data: " .. key)
            addon.db[self.modName]["focus" .. key] = addon.db[self.modName][key]
        end

        addon.db[self.modName][key] = nil -- remove old keys after migration
    end

    self.bars.focus = self:CreateBar()
    self.bars.focus.active = false

    if addon.db[self.modName]["EnabledTargetBar"] then
        self.bars.target = self:CreateBar()
        self.bars.target.active = false
    end

    return self
end

-- private methods

-- MARK: Get Interrupt ID

---Get interruptID depending on class and spec of the player
---@param self FocusInterrupt self
---@param class string Upper-case class string
---@return integer interruptID the interrupt spell ID
local function GetInterruptSpellID(self)
    local output = INTERRUPT_BY_CLASS[addon.states["playerClass"]].DEFAULT
    self.subInterrupt = nil

    if addon.states["playerSpec"] == 266 then -- demonology warlock
        self.subInterrupt = INTERRUPT_BY_CLASS[addon.states["playerClass"]].DEMONOLOGY_SUB
        output = INTERRUPT_BY_CLASS[addon.states["playerClass"]].DEMONOLOGY
    elseif addon.states["playerSpec"] == 102 then -- balance druid
        output = INTERRUPT_BY_CLASS[addon.states["playerClass"]].BALANCE
    elseif addon.states["playerSpec"] == 255 then -- survival hunter
        output = INTERRUPT_BY_CLASS[addon.states["playerClass"]].SURVIVAL
    end

    return output
end

-- MARK: Get Bar Color

---Set statusBar color for the cast
---@param self FocusInterrupt self
---@param interrupted boolean is cast interrupted already(never use secret-value)
---@param notInterruptible boolean is Not-interruptible cast
---@param isInterruptReady boolean is Interrupt ready
---@param subInterruptReady boolean? is subInterrupt ready(optional)
local function GetBarColor(self, interrupted, notInterruptible, isInterruptReady, subInterruptReady)
    local color = self.interruptibleColor
    if interrupted then
        color = C_CurveUtil.EvaluateColorFromBoolean(interrupted, self.interruptedColor, self.interruptibleColor)
        return color
    end

    color = C_CurveUtil.EvaluateColorFromBoolean(isInterruptReady, color, self.cooldownColor)

    if self.subInterrupt then
        color = C_CurveUtil.EvaluateColorFromBoolean(subInterruptReady, self.interruptibleColor, color)
    end

    color = C_CurveUtil.EvaluateColorFromBoolean(notInterruptible, self.notInterruptibleColor, color)

    return color
end

---Get Interrupter from GUID
---@param guid string GUID for the interrupter
---@return string name name of the interrupter
---@return string class class of the interrupter
local function GetInterrupter(guid)
    local name, class
    name = UnitNameFromGUID(guid) -- server is trimmed automatically
    _, class = GetPlayerInfoByGUID(guid)
    
    return name, class
end

-- MARK: Update Kick Icons Style

---Update kick icons, make sure icons are instantialized before use this
---@param self FocusInterrupt self
---@param unit string unit key for the bar's icon to be updated
local function UpdateKickIconsStyle(self, unit)
    local anchorFrom, anchorTo = addon.Utilities:GetAnchorFrom(addon.db[self.modName]["KickIconAnchor"]), addon.db[self.modName]["KickIconAnchor"]
    local anchorChild, anchorParent = addon.Utilities:GetGrowAnchors(addon.db[self.modName]["KickIconGrow"])

    self.bars[unit].kickIcon:SetSize(addon.db[self.modName]["KickIconSize"], addon.db[self.modName]["KickIconSize"])
    self.bars[unit].kickIcon:ClearAllPoints()
    self.bars[unit].kickIcon:SetPoint(anchorFrom, self.bars[unit], anchorTo, 0, 0)
    self.bars[unit].kickIcon.icon:SetTexCoord(
        addon.db[self.modName][unit .. "IconZoom"],
        1 - addon.db[self.modName][unit .. "IconZoom"],
        addon.db[self.modName][unit .. "IconZoom"],
        1 - addon.db[self.modName][unit .. "IconZoom"]
    )

    if self.bars[unit].subKickIcon then
        self.bars[unit].subKickIcon:SetSize(addon.db[self.modName]["KickIconSize"], addon.db[self.modName]["KickIconSize"])
        self.bars[unit].subKickIcon:ClearAllPoints()
        self.bars[unit].subKickIcon:SetPoint(anchorChild, self.bars[unit].kickIcon, anchorParent, 0, 0)
        self.bars[unit].subKickIcon.icon:SetTexCoord(
            addon.db[self.modName][unit .. "IconZoom"],
            1 - addon.db[self.modName][unit .. "IconZoom"],
            addon.db[self.modName][unit .. "IconZoom"],
            1 - addon.db[self.modName][unit .. "IconZoom"]
        )
    end
end

--MARK: Update Kick Icons

---Set Interrupt Icons if needed
---@param self FocusInterrupt self
---@param unit string unit key for the bar's icon to be updated
---@param interrupted boolean if the cast is already interrupted
---@param notInterruptible boolean if the cast is not-interruptible
---@param isInterruptReady boolean if the interrupt ready
---@param subInterruptReady boolean? if the sub-interrupt ready
local function UpdateKickIcons(self, unit, interrupted, notInterruptible, isInterruptReady, subInterruptReady)
    if self.bars[unit].kickIcon then
        if interrupted then -- if interrupted already, just hide both icons
            self.bars[unit].kickIcon:SetAlphaFromBoolean(interrupted, 0, 255)
            if self.subInterrupt then
                self.bars[unit].subKickIcon:SetAlphaFromBoolean(interrupted, 0, 255)
            end
            return
        end

        self.bars[unit].kickIcon:SetAlphaFromBoolean(isInterruptReady)
        self.bars[unit].kickIcon:SetAlphaFromBoolean(notInterruptible, 0, self.bars[unit].kickIcon:GetAlpha())

        if self.subInterrupt then
            self.bars[unit].subKickIcon:SetAlphaFromBoolean(subInterruptReady)
            self.bars[unit].subKickIcon:SetAlphaFromBoolean(notInterruptible, 0, self.bars[unit].subKickIcon:GetAlpha())
        end
    end
end

-- MARK: Interrupt Handle

---Interrupt Handler
---@param self FocusInterrupt self
---@param unit string the unit being interrupted
---@param guid integer the GUID of the interrupter
local function InterruptHandler(self, unit, guid)
    local interrupter, class = GetInterrupter(guid)
    local color = C_ClassColor.GetClassColor(class or "PRIEST"):GenerateHexColor() -- also secret-value

    if addon.db[self.modName]["ShowInterrupter"] then
        self.bars[unit].spellText:SetText(L["Interrupted"] .. ": |c".. color .. interrupter .. "|r")
    else
        self.bars[unit].spellText:SetText(L["Interrupted"])
    end
    local color = GetBarColor(self, true, false, false, false) -- change color to interrupted color
    self.bars[unit].statusBar:GetStatusBarTexture():SetVertexColor(color:GetRGBA())

    UpdateKickIcons(self, unit, true, false, false, false) -- hide interrupt icons
    self.bars[unit].active = false

    if self.bars[unit].timer then
        self.bars[unit].timer:Cancel()
    end

    self.bars[unit].timer = C_Timer.NewTimer(addon.db[self.modName]["InterruptedFadeTime"], function ()
        self.bars[unit].timer = nil
        self.bars[unit]:Hide()
    end)
end

-- MARK: OnUpdate

---Handle Casts by passed information
---@param self FocusInterrupt self
---@param unit string the unit being handled
---@param duration LuaDurationObject Blizzard's LuaDurationObject
---@param isChannel boolean if the cast is a channel cast
local function OnUpdate(self, unit, duration, isChannel, notInterruptible)
    -- after 3.2, self.active is still significant to halt update, but control it in RegisterEvent instead of handler
    if not self.bars[unit].active then
        return
    end

    -- get remaining time by cast types
    local remaining
    if isChannel then
        remaining = duration:GetRemainingDuration()
    else
        remaining = duration:GetElapsedDuration()
    end

    -- update statusBar
    self.bars[unit].statusBar:SetValue(remaining)
    
    -- update time text
    -- considering remove total duration text
    if addon.db[self.modName]["ShowTotalTime"] then
        self.bars[unit].timeText:SetText(string.format("%.1f/%.1f", duration:GetRemainingDuration(), duration:GetTotalDuration()))
    else
        self.bars[unit].timeText:SetText(string.format("%.1f", duration:GetRemainingDuration()))
    end

    -- general interrupt cooldown check
    local isInterruptReady = C_Spell.GetSpellCooldownDuration(self.interruptID):IsZero()

    -- for Demonology Warlocks/Two interrupts specs
    -- since the GRIMOIRE is also a kick, this part can only used for Demo Warlock so far. Prot Paladin cannot use this as GCD issue(IsZero includes GCD)
    local subInterruptReady
    if self.subInterrupt then
        -- the SpellLock(player version) is obtained to the SpellBook after used GRIMOIRE
        if not C_SpellBook.IsSpellInSpellBook(self.subInterrupt) then -- if SpellLock not in SpellBook-> GRIMOIRE not used yet/GRIMOIRE not learned(ignore it)
            -- if GRIMOIRE in SpellBook -> GRIMOIRE not on cooldown yet -> also a sub-interrupt ready
            subInterruptReady = C_SpellBook.IsSpellInSpellBook(INTERRUPT_BY_CLASS["WARLOCK"]["GRIMOIRE"])
        else -- SpellLock(player version) is in SpellBook -> GRIMOIRE used
            -- check SpellLock(player version)
            subInterruptReady = C_Spell.GetSpellCooldownDuration(self.subInterrupt):IsZero()
        end
    end

    -- handle colors for the statusBar
    -- after 3.2 use color constrol instead of overlays
    local color = GetBarColor(self, false, notInterruptible, isInterruptReady, subInterruptReady)
    self.bars[unit].statusBar:GetStatusBarTexture():SetVertexColor(color:GetRGBA())

    -- handle interrupt icons
    UpdateKickIcons(self, unit, false, notInterruptible, isInterruptReady, subInterruptReady)

    -- Hidden-Control
        -- As secret-value cannot compute, even compare between secret-values are not allowed
        -- use func(bool, trueVal, falseVal) to replace not/and/or
        -- NOT: reverse the values, then
            -- func(bool, trueVal = falseVal, falseVal = trueVal)
        -- AND: any false is false -> need currentVal = value after first bool execution, then
            -- func(bool, trueVal = trueVal, falseVal = falseVal) + func(bool, trueVal = currentVal, falseVal = falseVal)
        -- OR: any true is true -> need currentVal = value after first bool execution, then
            -- func(bool, trueVal = trueVal, falseVal = falseVal) + func(bool, trueVal = trueVal, falseVal = currentVal)
    if addon.db[self.modName]["CooldownHide"] then
        -- func(isInterruptReady or subInterruptReady, show, hide)
            -- func = Region:SetAlphaFromBoolean(bool, trueVal, falseVal)
            -- show = 255
            -- hide = 0
            -- currentVal = frame:GetAlpha()
        self.bars[unit]:SetAlphaFromBoolean(isInterruptReady) -- func(isInterruptReady, show, hide)
        if self.subInterrupt then
            self.bars[unit]:SetAlphaFromBoolean(subInterruptReady, 255, self.bars[unit]:GetAlpha()) -- func(subInterruptReady, show, currentVal)
        end
    end

    if addon.db[self.modName]["NotInterruptibleHide"] then
        -- func(any(InterruptReady) and not notInterruptible, show hide)
            -- any(InterruptReady) is above, then func(not notInterruptible, currentVal, hide)
            -- then, func(notInterruptible, hide, currentVal)
        self.bars[unit]:SetAlphaFromBoolean(notInterruptible, 0, self.bars[unit]:GetAlpha())
    end
end

-- MARK: Create KickIcon

local function CreateKickIcon(self,unit)
    local kickIcon = CreateFrame("Frame", nil, self.bars[unit])
    kickIcon.border = CreateFrame("Frame", nil, kickIcon, "BackdropTemplate")
    kickIcon.border:SetAllPoints()
    kickIcon.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1, insets = {left = 1, right = 1, top = 1, bottom = 1}})
    kickIcon.border:SetBackdropBorderColor(0, 0, 0, 1)
    kickIcon.icon = kickIcon:CreateTexture(nil, "ARTWORK")
    kickIcon.icon:SetAllPoints()

    return kickIcon
end

-- MARK: Update InterruptID

local function LoadInterruptIcon(self, unit)
    -- if show kick icon and (not only demo warlock or (only demo warlock and spec is demo)) -> show kick icon
    if addon.db[self.modName]["ShowKickIcons"] and (not addon.db[self.modName]["ShowDemoWarlockOnly"] or (addon.db[self.modName]["ShowDemoWarlockOnly"] and self.subInterrupt)) then
        if self.subInterrupt then -- if demo warlock, load two icons
            if not self.bars[unit].kickIcon then
                self.bars[unit].kickIcon = CreateKickIcon(self, unit)
            end
            if not self.bars[unit].subKickIcon then
                self.bars[unit].subKickIcon = CreateKickIcon(self, unit)
            end
        else -- if not demo warlock, only load main kick icon
            if not self.bars[unit].kickIcon then
                self.bars[unit].kickIcon = CreateKickIcon(self, unit)
            end
            if self.bars[unit].subKickIcon then
                self.bars[unit].subKickIcon:Hide()
            end
        end

        UpdateKickIconsStyle(self, unit) -- update icons' position and size according to settings
        self.bars[unit].kickIcon.icon:SetTexture(C_Spell.GetSpellInfo(self.interruptID).iconID or UNKNOWN_SPELL_TEXTURE) -- set main kick icon texture
        self.bars[unit].kickIcon:Show()
        if self.bars[unit].subKickIcon and self.subInterrupt then
            self.bars[unit].subKickIcon.icon:SetTexture(C_Spell.GetSpellInfo(self.subInterrupt).iconID or UNKNOWN_SPELL_TEXTURE) -- set sub kick icon texture
            self.bars[unit].subKickIcon:Show()
        end
    else
        if self.bars[unit].kickIcon then
            self.bars[unit].kickIcon:Hide()
        end
        if self.bars[unit].subKickIcon then
            self.bars[unit].subKickIcon:Hide()
        end
    end
end

---Update FocusInterrupt's interruptID
---@param self FocusInterrupt self
local function UpdateInterruptId(self)
    self.interruptID = GetInterruptSpellID(self)

    for unit, _ in pairs(self.bars) do
        LoadInterruptIcon(self, unit)
    end
end

-- MARK: Handler

---Handler for FocusInterrupt
---@param self FocusInterrupt self
---@param unit string the unit to handle
local function Handler(self, unit)
    if addon.db[self.modName][unit .. "HideFriendly"] and UnitIsFriend("player", unit) then
        self.bars[unit].active = false
        self.bars[unit]:Hide()
        return
    end

    -- auto detemine isChannel and handle focus change situation
    -- check if this cast is a channel cast -> check if it is a cast
    local name, _, texture, _, _, _, notInterruptible, _ = UnitChannelInfo(unit)
    local isChannel = false
    if name then -- channel cast
        isChannel = true
    else -- NOT channel
        name, _, texture, _, _, _, _, notInterruptible, _ =  UnitCastingInfo(unit)
    end
    
    if not name then -- not a cast (for switching focus to a new unit)
        -- if the new focus is not casting, halt it 
        self.bars[unit].active = false
        self.bars[unit]:Hide()
        return
    end

    -- get duration according to cast types
    local duration
    if isChannel then
        duration = UnitChannelDuration(unit)
    else
        duration = UnitCastingDuration(unit)
    end

    -- handle target
    -- channel target is not naturally provided through API, a complicated way is to use focus's target but involves more events and too much excessive information
    local target = UnitSpellTargetName(unit) -- only attempt to get non-channel cast target
    if addon.db[self.modName]["ShowTarget"] and target then
        local color = C_ClassColor.GetClassColor(UnitSpellTargetClass(unit) or "PRIEST"):GenerateHexColor() -- 8 digits Hex(also secret-value, do not directly compute it)
        local targetNameTrimed = (select(1, UnitName(target))) or target -- trim server name for formatting
        self.bars[unit].spellText:SetText(string.format("%.16s-|c%s%.16s|r", name, color, targetNameTrimed))
    else
        self.bars[unit].spellText:SetText(name)
    end

    

    -- handle icon
    self.bars[unit].icon:SetTexture(texture or UNKNOWN_SPELL_TEXTURE)

    -- set the max time earlier for performance
    self.bars[unit].statusBar:SetMinMaxValues(0, duration:GetTotalDuration())

    -- still use "OnUpdate", as there are many things we need to keep real-time update
    -- attempted to restrict the refresh rate(update interval), but a smooth function is highly demanded for it -> temperarily gave it up
    self.bars[unit]:SetScript("OnUpdate", function (_, _)
        OnUpdate(self, unit, duration, isChannel, notInterruptible)
    end)

    -- use alpha hiden instead of Hide() to prevent bugs on any hooked script or potential future hooked script
    self.bars[unit]:SetAlphaFromBoolean(addon.db[self.modName]["Hidden"], 0, 255)

    -- attempted to use "HookScript("OnShow", func)" for sound alert, nontheless frames are seen as shown while zero alpha and SetShown() cannot take secret-values
    if not addon.db[self.modName]["Mute"] then
        PlaySoundFile(addon.LSM:Fetch("sound", addon.db[self.modName]["SoundMedia"]), addon.db[self.modName]["SoundChannel"])
    end

    self.bars[unit]:Show()
end

-- MARK: Update Bar Style

---Update style of a bar
---@param self FocusInterrupt self
---@param unit string unit key for the bar to be updated style
local function UpdateBarStyle(self, unit)
    -- frame strata level for the bar
    self.bars[unit]:SetFrameStrata(addon.db[self.modName]["FrameStrata"] or "HIGH")
    -- basic size and position of bar
    self.bars[unit]:SetSize(addon.db[self.modName][unit .. "Width"], addon.db[self.modName][unit .. "Height"])
    self.bars[unit]:SetPoint("CENTER", UIParent, "CENTER", addon.db[self.modName][unit .. "X"], addon.db[self.modName][unit .. "Y"])
    
    -- background is kind of Blizzard's texture, only color and alpha are customizable
    self.bars[unit].background:SetColorTexture(0, 0, 0, addon.db[self.modName][unit .. "BackgroundAlpha"])

    -- icon zoom and size
    self.bars[unit].icon:SetTexCoord( -- prevent Blizzard's raw icons' border and fill all space with texture
        addon.db[self.modName][unit .. "IconZoom"],
        1 - addon.db[self.modName][unit .. "IconZoom"],
        addon.db[self.modName][unit .. "IconZoom"],
        1 - addon.db[self.modName][unit .. "IconZoom"]
    )
    self.bars[unit].icon:SetSize(addon.db[self.modName][unit .. "Height"], addon.db[self.modName][unit .. "Height"]) -- keep icon has the same height as bar and keep it a cube

    -- bar texture and size
    -- after 3.2, only keep one status bar instead of 3(1 bar + 2 overlays)
    self.bars[unit].statusBar:SetStatusBarTexture(addon.LSM:Fetch("statusbar", addon.db[self.modName][unit .. "Texture"]))
    self.bars[unit].statusBar:SetSize(addon.db[self.modName][unit .. "Width"] - addon.db[self.modName][unit .. "Height"], addon.db[self.modName][unit .. "Height"])
    self.bars[unit].statusBar:GetStatusBarTexture():SetVertexColor(self.interruptibleColor:GetRGBA())

    -- font/text positions/
    -- left texts(spell + target)
    -- after 3.2, allow change the font size but change the margin to 0 for formatting more information
    self.bars[unit].spellText:SetFont(
        addon.LSM:Fetch("font", addon.db[self.modName][unit .. "Font"]) or "Fonts\\FRIZQT__.TTF",
        addon.db[self.modName][unit .. "FontSize"],
        "OUTLINE"
    )
    self.bars[unit].spellText:SetPoint("LEFT", self.bars[unit], "LEFT", addon.db[self.modName][unit .. "Height"], 0)
    self.bars[unit].spellText:SetSize(0.7 * (addon.db[self.modName][unit .. "Width"] - addon.db[self.modName][unit .. "Height"]), addon.db[self.modName][unit .. "FontSize"]) -- how much propotion of space is allowd
    -- right texts(time)
    self.bars[unit].timeText:SetFont(
        addon.LSM:Fetch("font", addon.db[self.modName][unit .. "Font"]) or "Fonts\\FRIZQT__.TTF",
        addon.db[self.modName][unit .. "FontSize"],
        "OUTLINE"
    )
    self.bars[unit].timeText:SetSize(0.3 * (addon.db[self.modName][unit .. "Width"] - addon.db[self.modName][unit .. "Height"]), addon.db[self.modName][unit .. "FontSize"]) -- how much propotion of space is allowd
end

-- public methods
-- MARK: Create Bar

---Create a FocusInterrupt Bar
---@return frame bar the created FocusInterrupt Bar
function FocusInterrupt:CreateBar()
    local bar = CreateFrame("Frame", nil, self.frame)
    bar:Hide()

    bar.background = bar:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints()

    bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.border:SetAllPoints()
    bar.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1, insets = {left = 1, right = 1, top = 1, bottom = 1}})
    bar.border:SetFrameLevel(bar:GetFrameLevel() + 10)
    bar.border:SetBackdropBorderColor(0, 0, 0, 1)

    bar.icon = bar:CreateTexture(nil, "ARTWORK")
    bar.icon:SetPoint("LEFT", bar, "LEFT", 0, 0)

    bar.statusBar = CreateFrame("StatusBar", nil, bar)
    bar.statusBar:SetMinMaxValues(0, 1)
    bar.statusBar:SetValue(0)
    bar.statusBar:SetPoint("RIGHT", bar, "RIGHT")

    -- frame which takes texts
    bar.textFrame = CreateFrame("Frame", nil, bar)
    bar.textFrame:SetAllPoints()
    bar.textFrame:SetFrameLevel(bar:GetFrameLevel() + 10)
    -- set spell text
    bar.spellText = bar.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bar.spellText:SetJustifyH("LEFT")
    bar.spellText:SetTextColor(1, 1, 1, 1)
    -- set time text
    bar.timeText = bar.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bar.timeText:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    bar.timeText:SetJustifyH("RIGHT")
    bar.timeText:SetTextColor(1, 1, 1, 1)

    return bar
end

-- MARK: UpdateStyle

---Update style settings and render them in-game for FocusInterrupt
function FocusInterrupt:UpdateStyle()
    -- color settings
    -- after 3.2, by accessing texture's color instead of SetStatusBarColor() to use secret-value to decide color instead of overlays manipulations
    self.cooldownColor = CreateColorFromHexString(addon.db[self.modName]["CooldownColor"])
    self.interruptibleColor = CreateColorFromHexString(addon.db[self.modName]["InterruptibleColor"])
    self.notInterruptibleColor = CreateColorFromHexString(addon.db[self.modName]["NotInterruptibleColor"])
    self.interruptedColor = CreateColorFromHexString(addon.db[self.modName]["InterruptedColor"])

    for unit, _ in pairs(self.bars) do
        UpdateBarStyle(self, unit)
        if self.bars[unit].kickIcon then
            UpdateKickIconsStyle(self, unit) -- update icons if exist
        end
    end
end

-- MARK: Test

---Test Mode for FocusInterrupt
---@param on boolean turn the Test mode on or off
function FocusInterrupt:Test(on)
    if not addon.db[self.modName]["Enabled"] or addon.db[self.modName]["Hidden"] then
        for unit, _ in pairs(self.bars) do
            self.bars[unit]:Hide()
            self.bars[unit].active = false
        end
        return
    end

    local function TestBar(unit)
        -- generate a demo cast bar
        self.bars[unit].active = true
        local name, target = "MaximumTestSpell", "Target"
        if addon.db[self.modName]["ShowTarget"] then
            self.bars[unit].spellText:SetText(string.sub(name, 1, 16) .. "-" .. "|c" .. C_ClassColor.GetClassColor("WARLOCK"):GenerateHexColor() .. target .. "|r")
        else
            self.bars[unit].spellText:SetText(string.sub(name, 1, 16))
        end
        
        self.bars[unit].icon:SetTexture(UNKNOWN_SPELL_TEXTURE)
        self.bars[unit].statusBar:SetMinMaxValues(0, 30)
        local testDuration = C_DurationUtil.CreateDuration() -- use a Blizzard LuaDurationObject to test
        testDuration:SetTimeFromStart(GetTime(), 30)
        UpdateInterruptId(self)

        addon.Utilities:MakeFrameDragPosition(self.bars[unit], self.modName, unit .. "X", unit .. "Y", function() -- drag for re-positioning and capable of running test mode simultaneously
            OnUpdate(self, unit, testDuration, false, false)
        end)

        self.bars[unit]:Show()
    end

    if on then
        for unit, _ in pairs(self.bars) do
            TestBar(unit)
        end
    else
        for unit, _ in pairs(self.bars) do
            self.bars[unit].active = false
            self.bars[unit]:Hide()
        end
    end
end

--MARK: Register Event

---Register events for FocusInterrupt on EventsHandler
function FocusInterrupt:RegisterEvents() -- for cast-start events
    local function StartCastHandle(...)
        local unit = select(1, ...)
        if self.bars[unit].timer then -- if the interrupted fade Timer is still there, we should immediately halt it and handle new cast
            self.bars[unit].timer:Cancel()
            self.bars[unit].timer = nil
        end
        
        self.bars[unit].active = true
        Handler(self, unit)
    end
    
    local function StopCastHandle(...)
        local unit = select(1, ...)
        if not self.bars[unit].timer then -- since the stop-cast events also triggered after the interrupted-events, must avoid stop-cast events override the interrupted-events
            self.bars[unit].active = false
            self.bars[unit]:Hide()
        end
    end

    local function InterruptedHandle(...)
        local unit, _, _, guid = ... -- if guid != null -> some one interrupted it
        if guid then -- handle interrupted
            InterruptHandler(self, unit, guid)
        else -- potential a normal stop cast
            StopCastHandle(...)
        end
    end

    local function UpdateID()
        UpdateInterruptId(self)
    end

    local function BarOnEvent(_, event, ...)
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            StartCastHandle(...)
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" then
            StopCastHandle(...)
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            InterruptedHandle(...)
        elseif event == "PLAYER_FOCUS_CHANGED" then -- only hooked on focus bar
            if self.bars.focus.timer then
                self.bars.focus.timer:Cancel()
                self.bars.focus.timer = nil
            end

            self.bars.focus.active = true
            Handler(self, "focus")
        elseif event == "PLAYER_TARGET_CHANGED" then -- only hooked on target bar if target bar exist
            if self.bars.target.timer then
                self.bars.target.timer:Cancel()
                self.bars.target.timer = nil
            end

            self.bars.target.active = true
            Handler(self, "target")
        end
    end

    -- active cast
    for unit, bar in pairs(self.bars) do
        addon.core:RegisterEvent("UNIT_SPELLCAST_START", bar, self.modName, unit)
        addon.core:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", bar, self.modName, unit)
    end
    -- switch focus/target
    addon.core:RegisterEvent("PLAYER_FOCUS_CHANGED", self.bars.focus, self.modName)
    if self.bars.target then -- only register target change event when target bar exist
        addon.core:RegisterEvent("PLAYER_TARGET_CHANGED", self.bars.target, self.modName)
    end
    -- switch spec
    addon.core:RegisterStateMonitor("playerSpec", self.modName, UpdateID)
    -- stop cast
    for unit, bar in pairs(self.bars) do
        addon.core:RegisterEvent("UNIT_SPELLCAST_STOP", bar, self.modName, unit)
        addon.core:RegisterEvent("UNIT_SPELLCAST_FAILED", bar, self.modName, unit)
    end
    -- interrupted/stop cast
    for unit, bar in pairs(self.bars) do
        addon.core:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", bar, self.modName, unit)
        addon.core:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", bar, self.modName, unit)
    end

    -- hook to events
    -- bar events
    for _, bar in pairs(self.bars) do
        bar:SetScript("OnEvent", BarOnEvent)
    end
end

-- MARK: Register Module
addon.core:RegisterModule(FocusInterrupt.modName, function() return FocusInterrupt:Initialize() end)