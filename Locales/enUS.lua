local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true)

L["Welecome"] = "|cff8788ee" .. ADDON_NAME .. "|r: Welcome! Your profile has been reset, and you can set up in: ESC-Options-AddOns-|cff8788ee" .. ADDON_NAME .. "|r"
L["WelecomeInfo"] = "Welecome! Thank you for using |cff8788ee" .. ADDON_NAME .. "|r!"
L["WelecomeSetting"] = "You can change settings with \"|cff8788ee/mfi|r\" or open configuration panel in ESC-Options-AddOns-|cff8788ee" .. ADDON_NAME .. "|r"
L["WarlockWelecome"] = "Hello, |cff8788eeWarlock|r. Ready to serve you!"
L["GUITitle"] = "|cff8788ee" .. ADDON_NAME .. "|r Configurations Panel"
L["Notifications"] = "Notifications"
L["NotificationContent"] = "The tabs shows modules contained in this addon, you can configure each module separately." .. "\n\n" .. 
"You can find on |cff8788eeHBLyx|r's CurseForge page:" .. "\n" ..
"|cff8788eeHBLyx_Tools|r: a collection of modules including Combat Indicator, Combat Timer, Focus Interrupt and more modules" .. "\n" ..
"|cff8788eeMidnightFocusInterrupt|r: Focus Interrupt module standalone version" .. "\n" ..
"|cff8788eeHBLyx_Encounter_Sound|r: Encounter Sound module standalone version" .. "\n" ..
"|cff8788eeSharedMedia_HBLyx|r: an AI-generated Chinese sound pack(LibSharedMedia)"

-- MARK： Downloads/Update
L["Downloads/Update"] = "Downloads/Update"
L["Release_Info"] = "The official release version is |cffff0000only available on the following sites, all others are not from the author|r"

-- MARK: Change Log
L["ChangeLog"] = "Change Log"
L["ChangeLogContent"] =
"v3.8\n" ..
"-Focus Interrupt: Added an option for a target cast bar, which can create a target cast bar similar to the focus cast bar\n" ..
"v3.7\n" ..
"-Custom Auras Tracker: auras can be loaded by specializations(a new corresponding custom option)\n" ..
"v3.6\n" ..
"-Custom Auras Tracker: add a new module \"Custom Aura Tracker\" which Track aura that are triggered by \"player\" and display and play sound alert with customizable options\n"

--MARK: Issues
L["Issues"] = "Issues"
L["AnyIssues"] = "If you encounter any issue, please feedback to the author through the contact information"
L["IssuesContent"] = "Q: Can you add XXX spell as an interrupt spell in Focus Interrupt module?\nA: No, spells with GCD cannot be added due to Blizzard's API restrictions. If you want to add a spell without GCD, please inform me with the spell details" .. "\n\n" ..
"Q: The BattleRes cannot display at the start of some Beta M+ dungeons and \"reload\" can fix it, why?\nA: It is caused by Blizzard's failure to trigger the CHALLENGE_MODE_START event in some dungeons with M+ mode, there is currently no good solution, wait for Blizzard to fix it"

-- MARK: Contact
L["Contact"] = "Contact"
L["GitHub"] = "Submit issue on GitHub"
L["CurseForge"] = "Comments on CurseForge"

-- MARK: Sound Channel
L["SoundChannelSettings"] = "Sound Channel"
L["SoundChannel"] = {
	Master = "Master",
	SFX = "Effects",
	Music = "Music",
	Ambience = "Ambience",
	Dialog = "Dialog",
}

-- MARK: Config
L["ConfigPanel"] = "Open Configurations Panel"
L["Test"] = "Test/Unlock(Drag to Move)"
L["Mute"] = "Mute"
L["Enable"] = "Enable"
L["SoundSettings"] = "Sound Settings"
L["PetSettings"] = "Pet Reminder Settings"
L["PetStanceEnable"] = "Enable Pet Stance Check"
L["PetTypeSettings"] = "Enable Pet Type Check"
L["FadeTime"] = "Fade Time"
L["IconSize"] = "Icon Size"
L["BackgroundAlpha"] = "Background Alpha"
L["Texture"] = "Texture"
L["Width"] = "Width"
L["Height"] = "Height"
L["Sound"] = "Sound"
L["TimeFontScale"] = "Time Font Scale"
L["StackFontSize"] = "Stack/Charge Font Size"
L["Reminders"] = "Reminders"
L["Ready"] = "Ready"
L["NotLearned"] = "Not Learned"
L["Reload"] = "Reload(RL)"
L["ReloadNeeded"] = "Need to reload to take effect of changes"
L["IconZoom"] = "Icon Zoom"
L["ResetMod"] = "Reset Module"
L["ComfirmResetMod"] = "Are you sure you want to reset all settings for this module?(also reload UI)"
L["Anchor"] = "Anchor"
L["Grow"] = "Grow Direction"
L["General"] = "General"
L["Profile"] = "Profile"
L["Export"] = "Export"
L["Import"] = "Import"
L["ProfileSettingsDesc"] = "Export and Import your profile with the string below.\n\nExported string is compatible with |cff8788eeHBLyx_Tools|r, and you can import it in the module profile section if you want to apply the same settings to the module in |cff8788eeHBLyx_Tools|r"
L["ImportSuccess"] = "Profile imported successfully. Please reload your UI to apply the changes."
L["ModuleProfile"] = "Module Profile"
L["ModuleProfileDesc"] = "You can select a module to export/import profile separately.\n\nTo export, select the module below first. To import, the module will be automatically recognized from the string"
L["SelectModule"] = "Select Module"
L["LeftButton"] = "Left Click"
L["RightButton"] = "Right Click"
L["HideMinimapIcon"] = "Hide Minimap Icon"
L["HideIfFriendly"] = "Hide if Friendly"

-- MARK: Style
L["StyleSettings"] = "Style Settings"
L["Font"] = "Font"
L["FontSize"] = "Font Size"
L["FontSettings"] = "Font Settings"
L["X"] = "Horizontal Position"
L["Y"] = "Vertical Position"
L["PositionSettings"] = "Position Settings"
L["IconSettings"] = "Icon Settings"
L["TextureSettings"] = "Texture Settings"
L["SizeSettings"] = "Size Settings"
L["ColorSettings"] = "Color Settings"
L["TextSettings"] = "Text Settings"
L["InterruptibleColor"] = "Interruptible Color"
L["NotInterruptibleColor"] = "NotInterruptible Color"
L["FrameStrata"] = "Frame Strata Level"

-- MARK: Default values
-- focus interrupt
L["FocusDefaultSound"] = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\kick.ogg"

-- MARK: Focus Interrupt
L["FocusInterruptSettings"] = "Focus Interrupt"
L["FocusInterruptSettingsDesc"] = "Focus Interrupt alert and Focus Cast Bar settings"
L["Interrupted"] = "Interrupted"
L["InterruptedColor"] = "Interrupted Color"
-- Focus Cast Bar Settings
L["FocusCastBarHidden"] = "Hide Focus Cast Bar"
L["FocusColorPriorityDesc"] = "NotInterruptibleColor > InterruptibleColor > InterruptNotReadyColor"
L["ShowTotalTime"] = "Show Total Time"
-- Focus Interrupt Settings
L["InteruptSettings"] = "Focus Interupt Settings"
L["FocusInterruptCooldownFilter"] = "Disable when Interrupt NOT Ready"
L["FocusInterruptNotReadyColor"] = "Interrupt Not Ready Color"
L["FocusInterruptibleFilter"] = "Disable when NOT Interrupible"
L["FocusMuteDesc"] = "Due to Blizzard's restrictions(02/06/2026), the sound alert will still play no matter how cast is\n\nRecommend keep sound alert off(this module contains multiple version of visual display to identify focus casting and interrupt information)"
L["InterruptedFadeTime"] = "Interrpted Fade Time"
L["ShowInterrupter"] = "Show Interrupter"
L["ShowTarget"] = "Show Target"
L["InterruptedSettings"] = "Interrupted Settings"
L["InterruptedSettingsDesc"] = "When the focus is interrupted, there is a short fade time for the cast bar, you can make the fade time zero to make it disappear immediately.\n\nAlso, there is information showing during the fade time"
L["InterruptIconsSettings"] = "Interrupt Icon Settings"
L["InterruptIconDesc"] = "When the player is capable of interrupt(interruptible + interrupt ready), display an icon of interrupt\n\nThis is mainly designed for Demonology Warlock, display which interrupt is available"
L["ShowDemoWarlockOnly"] = "Show Only if Demonology Warlock"
-- Target Interrupt Settings
L["TargetBarSettings"] = "Target Cast Bar Settings"
L["TargetBarSettingsDesc"] = "|cffffff00Enable a target cast bar as same as the focus cast bar|r. Most settings are shared, only the style settings below are independent."
