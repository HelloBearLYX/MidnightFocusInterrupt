local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local GUI = addon.GUI
local MOD_KEY = "FocusInterrupt"

addon.LSM:Register("sound", ADDON_NAME.. "_FocusDefault", L["FocusDefaultSound"])

-- MARK: Defaults
addon.configurationList[MOD_KEY] = {
    Enabled = true,
    Mute = true,
    SoundMedia = ADDON_NAME .. "_FocusDefault",
    SoundChannel = "Master",
    CooldownHide = false,
    CooldownColor = "ffC41E3A",
    NotInterruptibleHide = true,
    NotInterruptibleColor = "ffFF7C0A",
    InterruptedColor = "ff828282",
    InterruptibleColor = "ff3fc7eb",
    InterruptedFadeTime = 0.75,
    Hidden = false,
    -- Kick Icons settings
    ShowKickIcons = true,
    ShowDemoWarlockOnly = true,
    KickIconSize = 30,
    KickIconAnchor = "BOTTOMLEFT",
    KickIconGrow = "RIGHT",
    -- global settings
    ShowTarget = true,
    ShowInterrupter = true,
    ShowTotalTime = true,
    FrameStrata = "HIGH",
    -- bar-wise style settings
    focusBackgroundAlpha = 0.3,
    focusWidth = 280,
    focusHeight = 30,
    focusTexture = "Solid",
    focusFont = "",
    focusFontSize = 12,
    focusX = 0,
    focusY = 200,
    focusIconZoom = 0.07,
    focusHideFriendly = false,

    EnabledTargetBar = false,
    targetBackgroundAlpha = 0.3,
    targetWidth = 250,
    targetHeight = 25,
    targetTexture = "Solid",
    targetFont = "",
    targetFontSize = 10,
    targetX = 0,
    targetY = 100,
    targetIconZoom = 0.07,
    targetHideFriendly = false,
}

-- MARK: Safe update
local function update()
    return addon.core:GetSafeUpdate(MOD_KEY)()
end

-- GUI
GUI.TagPanels.FocusInterrupt = {}
function GUI.TagPanels.FocusInterrupt:CreateTabPanel(parent)
    -- MARK: General
    local frame = GUI:CreateScrollFrame(parent)
    frame:SetLayout("Flow")
    GUI:CreateInformationTag(frame, L["FocusInterruptSettingsDesc"], "LEFT")
    GUI:CreateToggleCheckBox(frame, L["Enable"] .. "|cff0070DD" .. L["FocusInterruptSettings"] .. "|r", addon.db.FocusInterrupt.Enabled, function(value)
        addon.db.FocusInterrupt.Enabled = value
        if addon.core:HasModuleLoaded(MOD_KEY) then -- if module is loaded
            if not value then -- user try to disable the module
                addon:ShowDialog(ADDON_NAME.."RLNeeded")
            end
        else -- if the module is not loaded yet
            if value then -- user try to enable the module, just load it without asking for reload, since it will be loaded immediately
                addon.core:LoadModule(MOD_KEY)
                addon.core:TestModule(MOD_KEY) -- the test mode will be on if the addon is in test mode
            end
        end
    end)
    GUI:CreateButton(frame, L["ResetMod"], function ()
        addon.Utilities:SetPopupDialog(
            ADDON_NAME .. "ResetMod",
            "|cffC41E3A" .. L["FocusInterruptSettings"] .. "|r: " .. L["ComfirmResetMod"],
            true,
            {button1 = YES, button2 = NO, OnButton1 = function ()
                addon.Utilities:ResetModule(MOD_KEY)
                ReloadUI()
            end}
        )
    end)

    -- MARK: Core - Interrupt
    local interruptGroup = GUI:CreateInlineGroup(frame, L["InteruptSettings"])
    GUI:CreateToggleCheckBox(interruptGroup, L["FocusInterruptCooldownFilter"], addon.db.FocusInterrupt.CooldownHide, function(value)
        addon.db.FocusInterrupt.CooldownHide = value
    end)
    GUI:CreateToggleCheckBox(interruptGroup, L["FocusInterruptibleFilter"], addon.db.FocusInterrupt.NotInterruptibleHide, function(value)
        addon.db.FocusInterrupt.NotInterruptibleHide = value
    end)
    -- MARK: Core - Interrupted
    local interruptedGroup = GUI:CreateInlineGroup(interruptGroup, L["InterruptedSettings"])
    GUI:CreateInformationTag(interruptedGroup, L["InterruptedSettingsDesc"], "LEFT")
    GUI:CreateSlider(interruptedGroup, L["InterruptedFadeTime"], 0, 2, 0.25, addon.db.FocusInterrupt.InterruptedFadeTime, function(value)
        addon.db.FocusInterrupt.InterruptedFadeTime = value
    end)
    GUI:CreateToggleCheckBox(interruptedGroup, L["ShowInterrupter"], addon.db.FocusInterrupt.ShowInterrupter, function(value)
        addon.db.FocusInterrupt.ShowInterrupter = value
    end)
    -- MARK: Core - Color
    local colorGroup = GUI:CreateInlineGroup(interruptGroup, L["ColorSettings"])
    GUI:CreateInformationTag(colorGroup, L["FocusColorPriorityDesc"], "LEFT")
    GUI:CreateColorPicker(colorGroup, L["InterruptibleColor"], true, addon.db.FocusInterrupt.InterruptibleColor, function(value)
        addon.db.FocusInterrupt.InterruptibleColor = value
        update()
    end):SetRelativeWidth(0.25)
    GUI:CreateColorPicker(colorGroup, L["FocusInterruptNotReadyColor"], true, addon.db.FocusInterrupt.CooldownColor, function(value)
        addon.db.FocusInterrupt.CooldownColor = value
        update()
    end):SetRelativeWidth(0.25)
    GUI:CreateColorPicker(colorGroup, L["NotInterruptibleColor"], true, addon.db.FocusInterrupt.NotInterruptibleColor, function(value)
        addon.db.FocusInterrupt.NotInterruptibleColor = value
        update()
    end):SetRelativeWidth(0.25)
    GUI:CreateColorPicker(colorGroup, L["InterruptedColor"], true, addon.db.FocusInterrupt.InterruptedColor, function(value)
        addon.db.FocusInterrupt.InterruptedColor = value
        update()
    end):SetRelativeWidth(0.25)
    local textGroup = GUI:CreateInlineGroup(interruptGroup, L["TextSettings"])
    GUI:CreateToggleCheckBox(textGroup, L["ShowTotalTime"], addon.db.FocusInterrupt.ShowTotalTime, function(value)
        addon.db.FocusInterrupt.ShowTotalTime = value
    end)
    GUI:CreateToggleCheckBox(textGroup, L["ShowTarget"], addon.db.FocusInterrupt.ShowTarget, function(value)
        addon.db.FocusInterrupt.ShowTarget = value
    end)
    -- MARK: Core - Kick Icons
    local interruptIconsGroup = GUI:CreateInlineGroup(interruptGroup, L["InterruptIconsSettings"])
    GUI:CreateInformationTag(interruptIconsGroup, L["InterruptIconDesc"], "LEFT")
    local demoWarlockOnlyCheckBox = GUI:CreateToggleCheckBox(nil, L["ShowDemoWarlockOnly"], addon.db.FocusInterrupt.ShowDemoWarlockOnly, function(value)
        addon.db.FocusInterrupt.ShowDemoWarlockOnly = value
        addon:ShowDialog(ADDON_NAME.."RLNeeded")
    end)
    local iconSizeSlider = GUI:CreateSlider(nil, L["IconSize"], 10, 200, 1, addon.db.FocusInterrupt.KickIconSize, function(value)
        addon.db.FocusInterrupt.KickIconSize = value
        update()
    end)
    local anchorDropdown = GUI:CreateDropdown(nil, L["Anchor"], addon.Utilities.Anchors, nil, addon.db.FocusInterrupt.KickIconAnchor, function(value)
        addon.db.FocusInterrupt.KickIconAnchor = value
        update()
    end)
    local growDropdown = GUI:CreateDropdown(nil, L["Grow"], addon.Utilities.Grows, nil, addon.db.FocusInterrupt.KickIconGrow, function(value)
        addon.db.FocusInterrupt.KickIconGrow = value
        update()
    end)
    GUI:CreateToggleCheckBox(interruptIconsGroup, L["Enable"], addon.db.FocusInterrupt.ShowKickIcons, function(value)
        addon.db.FocusInterrupt.ShowKickIcons = value
        demoWarlockOnlyCheckBox:SetDisabled(not value)
        iconSizeSlider:SetDisabled(not value)
        anchorDropdown:SetDisabled(not value)
        growDropdown:SetDisabled(not value)
        addon:ShowDialog(ADDON_NAME.."RLNeeded")
    end)
    demoWarlockOnlyCheckBox:SetDisabled(not addon.db.FocusInterrupt.ShowKickIcons)
    iconSizeSlider:SetDisabled(not addon.db.FocusInterrupt.ShowKickIcons)
    anchorDropdown:SetDisabled(not addon.db.FocusInterrupt.ShowKickIcons)
    growDropdown:SetDisabled(not addon.db.FocusInterrupt.ShowKickIcons)
    interruptIconsGroup:AddChild(demoWarlockOnlyCheckBox)
    GUI:CreateInformationTag(interruptIconsGroup, "\n")
    interruptIconsGroup:AddChild(iconSizeSlider)
    interruptIconsGroup:AddChild(anchorDropdown)
    interruptIconsGroup:AddChild(growDropdown)

    -- MARK: Core - Sound
    local soundGroup = GUI:CreateInlineGroup(interruptGroup, L["SoundSettings"])
    GUI:CreateInformationTag(soundGroup, L["FocusMuteDesc"], "LEFT")
    local soundSelect = GUI:CreateSoundSelect(nil, L["Sound"], addon.db.FocusInterrupt.SoundMedia, function(value)
        addon.db.FocusInterrupt.SoundMedia = value
    end)
    local soundChannelDropdown = GUI:CreateDropdown(nil, L["SoundChannelSettings"], addon.Utilities.SoundChannels, nil, addon.db.FocusInterrupt.SoundChannel, function(value)
        addon.db.FocusInterrupt.SoundChannel = value
    end)
    GUI:CreateToggleCheckBox(soundGroup, L["Mute"], addon.db.FocusInterrupt.Mute, function(value)
        addon.db.FocusInterrupt.Mute = value
        soundSelect:SetDisabled(value)
        soundChannelDropdown:SetDisabled(value)
    end)
    soundSelect:SetDisabled(addon.db.FocusInterrupt.Mute)
    soundChannelDropdown:SetDisabled(addon.db.FocusInterrupt.Mute)
    soundGroup:AddChild(soundSelect)
    soundGroup:AddChild(soundChannelDropdown)

    -- style
    local styleGroup = GUI:CreateInlineGroup(frame, L["StyleSettings"])
    GUI:CreateToggleCheckBox(styleGroup, L["FocusCastBarHidden"], addon.db.FocusInterrupt.Hidden, function(value)
        addon.db.FocusInterrupt.Hidden = value
    end)
    GUI:CreateToggleCheckBox(styleGroup, L["HideIfFriendly"], addon.db.FocusInterrupt.focusHideFriendly, function(value)
        addon.db.FocusInterrupt.focusHideFriendly = value
    end)
    GUI:CreateFrameStrataDropdown(styleGroup, addon.db.FocusInterrupt.FrameStrata, function(value)
        addon.db.FocusInterrupt.FrameStrata = value
        update()
    end)
    -- MARK: Style - Texture
    local texttureGroup = GUI:CreateInlineGroup(styleGroup, L["TextureSettings"])
    GUI:CreateTextureSelect(texttureGroup, L["Texture"], addon.db.FocusInterrupt.focusTexture, function(value)
        addon.db.FocusInterrupt.focusTexture = value
        update()
    end)
    GUI:CreateSlider(texttureGroup, L["BackgroundAlpha"], 0, 1, 0.01, addon.db.FocusInterrupt.focusBackgroundAlpha, function(value)
        addon.db.FocusInterrupt.focusBackgroundAlpha = value
        update()
    end)
    -- MARK: Style - Position
    local positionGroup = GUI:CreateInlineGroup(styleGroup, L["PositionSettings"])
    GUI:CreateSlider(positionGroup, L["X"], -2000, 2000, 1, addon.db.FocusInterrupt.focusX, function(value)
        addon.db.FocusInterrupt.focusX = value
        update()
    end)
    GUI:CreateSlider(positionGroup, L["Y"], -1000, 1000, 1, addon.db.FocusInterrupt.focusY, function(value)
        addon.db.FocusInterrupt.focusY = value
        update()
    end)
    -- MARK: Style - Size
    local sizeGroup = GUI:CreateInlineGroup(styleGroup, L["SizeSettings"])
    GUI:CreateSlider(sizeGroup, L["Width"], 50, 1000, 1, addon.db.FocusInterrupt.focusWidth, function(value)
        addon.db.FocusInterrupt.focusWidth = value
        update()
    end)
    GUI:CreateSlider(sizeGroup, L["Height"], 10, 200, 1, addon.db.FocusInterrupt.focusHeight, function(value)
        addon.db.FocusInterrupt.focusHeight = value
        update()
    end)
    GUI:CreateSlider(sizeGroup, L["IconZoom"], 0.01, 0.5, 0.01, addon.db.FocusInterrupt.focusIconZoom, function(value)
        addon.db.FocusInterrupt.focusIconZoom = value
        update()
    end)
    -- MARK: Style - Font
    local fontGroup = GUI:CreateInlineGroup(styleGroup, L["FontSettings"])
    GUI:CreateFontSelect(fontGroup, L["Font"], addon.db.FocusInterrupt.focusFont, function(value)
        addon.db.FocusInterrupt.focusFont = value
        update()
    end)
    GUI:CreateSlider(fontGroup, L["FontSize"], 4, 40, 1, addon.db.FocusInterrupt.focusFontSize, function(value)
        addon.db.FocusInterrupt.focusFontSize = value
        update()
    end)

    -- MARK: Target Bar Settings
    local targetStyleGroup = GUI:CreateInlineGroup(styleGroup, L["TargetBarSettings"])
    GUI:CreateInformationTag(targetStyleGroup, L["TargetBarSettingsDesc"], "LEFT")
    local targetHideFriendlyToggle = GUI:CreateToggleCheckBox(nil, L["HideIfFriendly"], addon.db.FocusInterrupt.targetHideFriendly, function(value)
        addon.db.FocusInterrupt.targetHideFriendly = value
    end)
    -- MARK: Target Style - Texture
    local targetTexttureGroup = GUI:CreateInlineGroup(nil, L["TextureSettings"])
    local targetTextureSelect = GUI:CreateTextureSelect(targetTexttureGroup, L["Texture"], addon.db.FocusInterrupt.targetTexture, function(value)
        addon.db.FocusInterrupt.targetTexture = value
        update()
    end)
    local targetBackgroundAlphaSlider = GUI:CreateSlider(targetTexttureGroup, L["BackgroundAlpha"], 0, 1, 0.01, addon.db.FocusInterrupt.targetBackgroundAlpha, function(value)
        addon.db.FocusInterrupt.targetBackgroundAlpha = value
        update()
    end)
    -- MARK: Target Style - Position
    local targetPositionGroup = GUI:CreateInlineGroup(nil, L["PositionSettings"])
    local targetXSlider = GUI:CreateSlider(targetPositionGroup, L["X"], -2000, 2000, 1, addon.db.FocusInterrupt.targetX, function(value)
        addon.db.FocusInterrupt.targetX = value
        update()
    end)
    local targetYSlider = GUI:CreateSlider(targetPositionGroup, L["Y"], -1000, 1000, 1, addon.db.FocusInterrupt.targetY, function(value)
        addon.db.FocusInterrupt.targetY = value
        update()
    end)
    -- MARK: Target Style - Size
    local targetSizeGroup = GUI:CreateInlineGroup(nil, L["SizeSettings"])
    local targetWidthSlider = GUI:CreateSlider(targetSizeGroup, L["Width"], 50, 1000, 1, addon.db.FocusInterrupt.targetWidth, function(value)
        addon.db.FocusInterrupt.targetWidth = value
        update()
    end)
    local targetHeightSlider = GUI:CreateSlider(targetSizeGroup, L["Height"], 10, 200, 1, addon.db.FocusInterrupt.targetHeight, function(value)
        addon.db.FocusInterrupt.targetHeight = value
        update()
    end)
    local targetIconZoomSlider = GUI:CreateSlider(targetSizeGroup, L["IconZoom"], 0.01, 0.5, 0.01, addon.db.FocusInterrupt.targetIconZoom, function(value)
        addon.db.FocusInterrupt.targetIconZoom = value
        update()
    end)
    -- MARK: Target Style - Font
    local targetFontGroup = GUI:CreateInlineGroup(nil, L["FontSettings"])
    local targetFontSelect = GUI:CreateFontSelect(targetFontGroup, L["Font"], addon.db.FocusInterrupt.targetFont, function(value)
        addon.db.FocusInterrupt.targetFont = value
        update()
    end)
    local targetFontSizeSlider = GUI:CreateSlider(targetFontGroup, L["FontSize"], 4, 40, 1, addon.db.FocusInterrupt.targetFontSize, function(value)
        addon.db.FocusInterrupt.targetFontSize = value
        update()
    end)
    
    GUI:CreateToggleCheckBox(targetStyleGroup, L["Enable"], addon.db.FocusInterrupt.EnabledTargetBar, function(value)
        addon.db.FocusInterrupt.EnabledTargetBar = value
        targetHideFriendlyToggle:SetDisabled(not value)
        targetTextureSelect:SetDisabled(not value)
        targetBackgroundAlphaSlider:SetDisabled(not value)
        targetXSlider:SetDisabled(not value)
        targetYSlider:SetDisabled(not value)
        targetWidthSlider:SetDisabled(not value)
        targetHeightSlider:SetDisabled(not value)
        targetIconZoomSlider:SetDisabled(not value)
        targetFontSelect:SetDisabled(not value)
        targetFontSizeSlider:SetDisabled(not value)
        addon:ShowDialog(ADDON_NAME.."RLNeeded")
    end)
    targetHideFriendlyToggle:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetTextureSelect:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetBackgroundAlphaSlider:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetXSlider:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetYSlider:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetWidthSlider:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetHeightSlider:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetIconZoomSlider:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetFontSelect:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetFontSizeSlider:SetDisabled(not addon.db.FocusInterrupt.EnabledTargetBar)
    targetStyleGroup:AddChild(targetHideFriendlyToggle)
    targetStyleGroup:AddChild(targetTexttureGroup)
    targetStyleGroup:AddChild(targetPositionGroup)
    targetStyleGroup:AddChild(targetSizeGroup)
    targetStyleGroup:AddChild(targetFontGroup)

    return frame
end