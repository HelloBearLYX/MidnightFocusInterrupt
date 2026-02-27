local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "zhCN")
if not L then return end

L["Welecome"] = "|cff8788ee" .. ADDON_NAME .. "|r: 欢迎! 你的配置已经被重置, 你可以在: ESC-选项-插件-|cff8788ee" .. ADDON_NAME .. "|r里更改设置"
L["WelecomeInfo"] = "欢迎! 感谢你使用|cff8788ee" .. ADDON_NAME .. "|r!"
L["WelecomeSetting"] = "你可以使用 \"|cff8788ee/mfi|r\" 命令或在 ESC-选项-插件-|cff8788ee" .. ADDON_NAME .. "|r 中打开配置面板来更改设置"
L["WarlockWelecome"] = "你好,|cff8788ee术士|r大人,本恶魔随时为你服务!"
L["GUITitle"] = "|cff8788ee" .. ADDON_NAME .. "|r配置面板"
L["Notifications"] = "通知"
L["NotificationContent"] = "选项界面中的标签页显示了本插件包含的模块, 你可以分别配置每个模块" .. "\n\n" ..
"你可以在|cff8788eeHBLyx|r的CurseForge页面里找到:" .. "\n" ..
"|cff8788eeHBLyx_Tools|r: 一个包含战斗指示器, 战斗计时器, 焦点打断以及更多模块的集合" .. "\n" ..
"|cff8788eeMidnightFocusInterrupt|r: 焦点打断模块的独立版本" .. "\n" ..
"|cff8788eeHBLyx_Encounter_Sound|r: BOSS战音效模块的独立版本" .. "\n" ..
"|cff8788eeSharedMedia_HBLyx|r: 一个AI生成的中文语音素材包(LibSharedMedia)"

-- MARK： Downloads/Update
L["Downloads/Update"] = "下载/更新"
L["Release_Info"] = "官方发布版本|cffff0000仅在以下地址提供, 其他所有版本均非作者发布|r"

-- MARK: Change Log
L["ChangeLog"] = "更新日志"
L["ChangeLogContent"] =
"v3.8\n" ..
"-焦点打断: 增加了一个目标施法条选项,可以创建一个与焦点施法条同样的目标施法条\n" ..
"v3.7\n" ..
"-自定义光环追踪: 光环可以通过专精加载(新增相应的自定义选项)\n" ..
"v3.6\n" ..
"-自定义光环追踪: 新增模块\"自定义光环追踪器\", 用于追踪\"玩家\"触发的光环, 并显示和播放声音警报, 支持自定义选项\n"

--MARK: Issues
L["Issues"] = "问题"
L["AnyIssues"] = "如果你遇到任何问题, 请通过联系方式向插件作者反馈"
L["IssuesContent"] = "Q:能否在焦点打断模块中添加XXX技能作为打断技能?\nA: 不能,由于暴雪的API限制,带有GCD的技能无法添加。若你想添加一个无GCD的技能,请告知我(提供技能详情)" .. "\n\n" ..
"Q:战复计时器在部分Beta大秘境开始时无法正确显示,必须重载,这是为什么?\nA: 这是暴雪部分副本的大秘境开始事件(CHALLENGE_MODE_START)没有正确触发导致的,目前没有好的解决方法,只能等暴雪修复了"


-- MARK: Contact
L["Contact"] = "联系方式"
L["GitHub"] = "在GitHub提交问题"
L["CurseForge"] = "在CurseForge发表评论"

-- MARK: Sound Channel
L["SoundChannelSettings"] = "声音通道"
L["SoundChannel"] = {
	Master = "主音量",
	SFX = "效果",
	Music = "音乐",
	Ambience = "环境音",
	Dialog = "对话",
}

-- MARK: Config
L["ConfigPanel"] = "打开配置面板"
L["Test"] = "测试/解锁(拖动移动)"
L["Mute"] = "静音"
L["Enable"] = "启用"
L["SoundSettings"] = "声音设置"
L["PetSettings"] = "宠物提醒设置"
L["PetStanceEnable"] = "启用宠物姿态检查"
L["PetTypeSettings"] = "启用宠物类型检查"
L["FadeTime"] = "淡入/淡出时间"
L["IconSize"] = "图标大小"
L["BackgroundAlpha"] = "背景透明度"
L["Texture"] = "材质"
L["Width"] = "宽度"
L["Height"] = "高度"
L["Sound"] = "音效"
L["TimeFontScale"] = "时间大小缩放"
L["StackFontSize"] = "层数/充能字体大小"
L["Reminders"] = "提醒"
L["Ready"] = "就绪"
L["NotLearned"] = "尚未学习"
L["Reload"] = "重载(RL)"
L["ReloadNeeded"] = "需要重载(Reload)才能使更改生效"
L["IconZoom"] = "图标缩放"
L["ResetMod"] = "重置本模块"
L["ComfirmResetMod"] = "您确定要重置此模块的所有设置吗?(同时重载)"
L["Anchor"] = "锚点"
L["Grow"] = "成长方向"
L["General"] = "综合"
L["Profile"] = "配置文件"
L["Export"] = "导出"
L["Import"] = "导入"
L["ProfileSettingsDesc"] = "使用下面的字符串导出和导入你的配置文件\n\n导出的字符串是和|cff8788eeHBLyx_Tools|r兼容的,如果你想把同样的设置应用到|cff8788eeHBLyx_Tools|r里的模块,你可以在|cff8788eeHBLyx_Tools|r的模块配置部分导入这个字符串"
L["ImportSuccess"] = "配置文件导入成功,请重载界面以应用更改"
L["ModuleProfile"] = "模块配置文件"
L["ModuleProfileDesc"] = "你可以选择一个模块来单独导出/导入配置文件\n\n导出时先在下面选择模块,导入时字符串会自动识别模块"
L["SelectModule"] = "选择模块"
L["LeftButton"] = "左键"
L["RightButton"] = "右键"
L["HideMinimapIcon"] = "隐藏小地图图标"
L["HideIfFriendly"] = "友方则隐藏"

-- MARK: Style
L["StyleSettings"] = "样式设置"
L["Font"] = "字体"
L["FontSize"] = "字体大小"
L["FontSettings"] = "字体设置"
L["X"] = "水平位置"
L["Y"] = "垂直位置"
L["PositionSettings"] = "位置设置"
L["IconSettings"] = "图标设置"
L["TextureSettings"] = "材质设置"
L["SizeSettings"] = "大小设置"
L["ColorSettings"] = "颜色设置"
L["TextSettings"] = "文字设置"
L["InterruptibleColor"] = "可打断颜色"
L["NotInterruptibleColor"] = "不可打断颜色"

-- MARK: Default values
-- focus interrupt
L["FocusDefaultSound"] = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\kick_chinese.ogg"

-- MARK: Focus Interrupt
L["FocusInterruptSettings"] = "焦点打断"
L["FocusInterruptSettingsDesc"] = "焦点打断警报与焦点施法条设置"
L["Interrupted"] = "被打断"
L["InterruptedColor"] = "被打断颜色"
-- Focus Cast Bar Settings
L["FocusCastBarHidden"] = "隐藏焦点施法条"
L["FocusColorPriorityDesc"] = "不可打断颜色 > 可打断颜色 > 打断未就绪颜色"
L["ShowTotalTime"] = "显示总时间"
-- Focus Interrupt Settings
L["InteruptSettings"] = "打断设置"
L["FocusInterruptCooldownFilter"] = "打断技能未就绪时隐藏"
L["FocusInterruptNotReadyColor"] = "打断未就绪颜色"
L["FocusInterruptibleFilter"] = "不可打断时隐藏"
L["FocusMuteDesc"] = "基于暴雪的限制(02/06/2026), 打断音效任然会任意施法时播放\n\n建议不使用音效(本模块包含多种视觉上的焦点施法过滤)"
L["InterruptedFadeTime"] = "被打断淡出时间"
L["ShowInterrupter"] = "显示打断者"
L["ShowTarget"] = "显示目标"
L["InterruptedSettings"] = "被打断设置"
L["InterruptedSettingsDesc"] = "当焦点被打断时, 施法条会有一个短暂的淡出时间, 你可以将淡出时间设置为0来让它立即消失.\n\n同时, 在淡出时间内会显示一些信息"
L["InterruptIconsSettings"] = "打断图标设置"
L["InterruptIconDesc"] = "在可以打断的时候(可打断+打断就绪)的情况下,显示打断图标\n\n主要为恶魔术提供,在可打断时显示哪个打断可用"
L["ShowDemoWarlockOnly"] = "只为恶魔术显示"
-- Target Interrupt Settings
L["TargetBarSettings"] = "目标施法条设置"
L["TargetBarSettingsDesc"] = "|cffffff00启用一个与焦点施法条相同的目标施法条|r。大部分设置是共享的, 只有下面的样式设置是独立的。"