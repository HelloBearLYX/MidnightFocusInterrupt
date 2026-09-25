local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true)

L["Welecome"] = "|cff8788ee" .. ADDON_NAME .. "|r: Welcome! Your profile has been initialized, and you can set up with: /mfi"
L["WelecomeInfo"] = "Welecome! Thank you for using |cff8788ee" .. ADDON_NAME .. "|r!"
L["WelecomeSetting"] = "You can change settings with \"|cff8788ee/mfi|r\""
L["GUITitle"] = "%s" .. ADDON_NAME .. "|r v%s"
L["Notifications"] = "Notifications"
L["NotificationContent"] =
	"The GUI of Configurations panel is totally re-built from scratch and independent from AceGUI\n" ..
	"Hope you enjoy the new UI experience!\n\n" ..
	"The tabs shows modules contained in this addon, you can configure each module separately." .. "\n\n" ..
	"You can find on |cff8788eeHBLyx|r's page:" .. "\n" ..
	"|cff8788eeHBLyx_Tools|r: a collection of modules including Combat Indicator, Combat Timer, Focus Interrupt and more modules" .. "\n" ..
	"|cff8788eeMidnightFocusInterrupt|r: Focus Interrupt module standalone version" .. "\n" ..
	"|cff8788eeSharedMedia_HBLyx|r: an AI-generated Chinese sound pack(LibSharedMedia)"

-- MARK： Downloads/Update
L["Downloads/Update"] = "Downloads/Update"
L["Release_Info"] = "The official release version is |cffff0000only available on the following sites, all others are not from the author|r"

-- MARK: Change Log
L["ChangeLog"] = "Change Log"
L["ChangeLogContent"] = "The full change log can be found on:"
L["ChangeLogLink"] = "https://discord.gg/NkjEKddwDr"

--MARK: Issues
L["Issues"] = "Issues"
L["AnyIssues"] = "If you encounter any issue, please feedback to the author through the contact information"
L["IssuesContent"] = "Q: Can you add XXX spell as an interrupt spell in Focus Interrupt module?\nA: No, spells with GCD cannot be added due to Blizzard's API restrictions. If you want to add a spell without GCD, please inform me with the spell details" .. "\n\n"

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
L["Test"] = "Test/Unlock"
L["Mute"] = "Mute"
L["Enable"] = "Enable"
L["SoundSettings"] = "Sound Settings"
L["IconSize"] = "Icon Size"
L["BackgroundAlpha"] = "Background Alpha"
L["Texture"] = "Texture"
L["Width"] = "Width"
L["Height"] = "Height"
L["Sound"] = "Sound"
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
L["ProfileSettingsDesc"] = "Export and Import your profile with the string below.\nExported string is compatible with |cff8788eeHBLyx_Tools|r, and you can import it in the module profile section if you want to apply the same settings to the module in |cff8788eeHBLyx_Tools|r"
L["ImportSuccess"] = "Profile imported successfully. Please reload your UI to apply the changes."
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
L["TextureSettings"] = "Texture Settings"
L["SizeSettings"] = "Size Settings"
L["ColorSettings"] = "Color Settings"
L["TextSettings"] = "Text Settings"
L["InterruptibleColor"] = "Interruptible Color"
L["NotInterruptibleColor"] = "Non-Interruptible Color"
L["FrameStrata"] = "Frame Strata Level"

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
L["FocusInterruptCooldownFilter"] = "Hide if Kick NOT Ready"
L["FocusInterruptNotReadyColor"] = "Kick Not Ready Color"
L["FocusInterruptibleFilter"] = "Hide if Non-Interruptible"
L["FocusMuteDesc"] = "Due to Blizzard's restrictions(02/06/2026), the sound alert will still play no matter how cast is\nRecommend keep sound alert off(this module contains multiple version of visual display to identify focus casting and interrupt information)"
L["InterruptedFadeTime"] = "Interrpted Fade Time"
L["ShowInterrupter"] = "Show Interrupter"
L["ShowTarget"] = "Show Target"
L["InterruptedSettings"] = "Interrupted Settings"
L["InterruptedSettingsDesc"] = "When the focus is interrupted, there is a short fade time for the cast bar, you can make the fade time zero to make it disappear immediately\nAlso, there is information showing during the fade time"
L["InterruptIconsSettings"] = "Interrupt Icon Settings"
L["InterruptIconDesc"] = "When the player is capable of interrupt(interruptible + interrupt ready), display an icon of interrupt\nMainly for multiple interrupts classes to show which interrupt is available"
L["ShowDemoWarlockOnly"] = "Only Show >1 Kicks"
L["TextProportionDesc"] = "How much proportion of the cast bar the text can take, the length of the string will not exceed the space limits\n0 proportion means no length limit to the text\n"
L["SpellProportion"] = "Spell Proportion"
L["TargetProportion"] = "Target Proportion"
L["TimeProportion"] = "Time Proportion"
-- Target Interrupt Settings
L["TargetBarSettings"] = "Target Cast Bar Settings"
L["TargetBarSettingsDesc"] = "|cffffff00Enable a target cast bar as same as the focus cast bar|r. Most settings are shared, only the style settings below are independent."
-- Spark Settings
L["SparkSettings"] = "Spark Settings"
L["SparkEnabled"] = "Cast Spark"
L["KickSparkEnabled"] = "Kick Spark"
L["SparkColor"] = "Spark Color"
L["SparkWidth"] = "Spark Width"

L["EnabledMarkNotification"] = "Notify Kick Mark"
L["EnabledMarkNotificationDesc"] = "When a ready check starts, notify the party which raid marker is assigned to interrupt\nThis module also generate a macro which automatically sets the focus on mouserover/target with the configured kick mark\nThe macro is named 'HBT_SetFocus' in general macros"
L["KickMark"] = "Kick Mark"
L["KickMarkMessage"] = "My focus mark is: %s"