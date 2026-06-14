client = nil
service = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local _G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local script = script
	local service = Vargs.Service
	local client = Vargs.Client

	local Anti, Core, Functions, Process, Remote, UI, Variables
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;
		Variables.GuiClasses.Cache = service.Lookupify(Variables.GuiClasses)

		Variables.Init = nil;
	end

	local function RunAfterLoaded()
		client.Variables.CodeName = client.Remote.Get("Variable", "CodeName")
		Variables.RunAfterLoaded = nil;
	end

	local function RunLast()
		Variables.RunLast = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	local atmosphere = service.Lighting:FindFirstChildWhichIsA("Atmosphere")

	client.GUIs = {}
	client.GUIHolder = service.New("Folder")
	client.Variables = {
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		CodeName = "";
		UIKeepAlive = true;
		KeybindsEnabled = true;
		ParticlesEnabled = true;
		CapesEnabled = true;
		HideChatCommands = false;
		KeepWindowWidthOnMinimize = false;
		CanUseEditableImages = false; -- TODO: Pool from FFlag
		Particles = {};
		KeyBinds = {};
		Aliases = {};
		Capes = {};
		savedUI = {};
		localSounds = {};
		ESPObjects = {};
		CommunicationsHistory = {};
		LightingSettings = {
			Ambient = service.Lighting.Ambient;
			Brightness = service.Lighting.Brightness;
			ColorShift_Bottom = service.Lighting.ColorShift_Bottom;
			ColorShift_Top = service.Lighting.ColorShift_Top;
			GlobalShadows = service.Lighting.GlobalShadows;
			OutdoorAmbient = service.Lighting.OutdoorAmbient;
			Outlines = service.Lighting.Outlines;
			ShadowColor = service.Lighting.ShadowColor;
			GeographicLatitude = service.Lighting.GeographicLatitude;
			Name = service.Lighting.Name;
			TimeOfDay = service.Lighting.TimeOfDay;
			FogColor = service.Lighting.FogColor;
			FogEnd = service.Lighting.FogEnd;
			FogStart = service.Lighting.FogStart;
		};
		AtmosphereSettings = {
			Name = atmosphere and atmosphere.Name,
			Density = atmosphere and atmosphere.Density,
			Offset = atmosphere and atmosphere.Offset,
			Color = atmosphere and atmosphere.Color,
			Decay = atmosphere and atmosphere.Decay,
			Glare = atmosphere and atmosphere.Glare,
			Haze = atmosphere and atmosphere.Haze,
		};
		KeycodeNames = require(client.Shared.KeycodeNames);
		HelpButtonAction = "Info",
		GuiClasses = {
			"AdGui", "BillboardGui", "CanvasGroup",
			"DockWidgetPluginGui", "Frame", "GuiBase", "GuiBase2d",
			"GuiButton", "GuiLabel", "GuiMain", "GuiObject",
			"ImageButton", "ImageLabel", "LayerCollector", "PluginGui",
			"QWidgetPluginGui", "RelativeGui", "ScreenGui", "ScrollingFrame",
			"SurfaceGui", "SurfaceGuiBase", "TextBox", "TextButton",
			"TextLabel", "UIAspectRatioConstraint", "UIBase", "UIComponent",
			"UIConstraint", "UICorner", "UIDragDetector", "UIFlexItem",
			"UIGradient", "UIGridLayout", "UIGridStyleLayout", "UILayout",
			"UIListLayout", "UIPadding", "UIPageLayout", "UIScale",
			"UIShadow", "UISizeConstraint", "UIStroke", "UITableLayout",
			"UITextSizeConstraint", "VideoDisplay", "VideoFrame", "ViewportFrame"
		};
		GuiProperties = {
			"ActivatedCursorIcon", "ActivatedCursorIconContent", "Adornee",
			"AdShape", "AlwaysOnTop", "BackgroundColor", "BlurRadius",
			"BorderColor", "BorderMode", "BorderOffset", "BorderStrokePosition",
			"BottomImageContent", "BottomLeftRadius", "BottomRightRadius", "BoundingBehavior",
			"BoundingUI", "Brightness", "ClearTextOnFocus", "ClipToDeviceSafeArea",
			"CursorIcon", "CursorIconContent", "CursorPosition", "DistanceLowerLimit",
			"DistanceStep", "DistanceUpperLimit", "DragAxis", "DragRelativity",
			"DragRotation", "DragSpace", "DragStyle", "DragUDim2",
			"EnableVideoAds", "ExtentsOffset", "ExtentsOffsetWorldSpace", "Face",
			"FallbackImage", "FallbackImageContent", "FillDirectionMaxCells", "FillEmptySpaceRows",
			"FlexMode", "FontFace", "FontSize", "GrowRatio",
			"HorizontalFlex", "HorizontalScrollBarInset", "HoverHapticEffect", "HoverImage",
			"HoverImageContent", "IgnoreGuiInset", "ImageContent", "InputSink",
			"Interactable", "InternalVideoUsage", "ItemLineAlignment", "LightInfluence",
			"LineHeight", "Localize", "MaxDistance", "MaxDragAngle",
			"MaxDragTranslation", "MaximumResolution", "MaxVisibleGraphemes", "MidImageContent",
			"MinDragAngle", "MinDragTranslation", "MultiLine", "OpenTypeFeatures",
			"PixelsPerStud", "PlayerToHideFrom", "PressedImage", "PressedImageContent",
			"PressHapticEffect", "ReferenceUIInstance", "ResampleMode", "ResetOnSpawn",
			"ResponseStyle", "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode",
			"SafeAreaCompatibility", "ScreenInsets", "ScrollBarImageColor3", "Selected",
			"SelectionBehaviorDown", "SelectionBehaviorLeft", "SelectionBehaviorRight", "SelectionBehaviorUp",
			"SelectionGroup", "SelectionModeDragSpeed", "SelectionModeRotateSpeed", "SelectionOrder",
			"SelectionStart", "ShowNativeInput", "ShrinkRatio", "SizeOffset",
			"SizingMode", "SliceScale", "Spread", "StartCorner",
			"StrokeSizingMode", "StudsOffset", "StudsOffsetWorldSpace", "TextColor",
			"TextEditable", "TextTruncate", "TextWrap", "TileSize",
			"Title", "ToolPunchThroughDistance", "TopImageContent", "TopLeftRadius",
			"TopRightRadius", "UIDragSpeedAxisMapping", "VerticalFlex", "VideoColor3",
			"VideoContent", "VideoRectOffset", "VideoRectSize", "VideoTransparency",
			"Wraps", "ZIndexBehavior", "ZOffset"
		};
	};
end
