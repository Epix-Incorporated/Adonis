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
		CommandListGroupBy = "Rank",
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
			"ActivatedCursorIcon", "ActivatedCursorIconContent", "Active", "Adornee", "AdShape",
			"AlwaysOnTop", "Ambient", "AnchorPoint", "Animated", "ApplyStrokeMode",
			"Archivable", "AspectRatio", "AspectType", "AutoButtonColor", "AutoLocalize",
			"AutomaticCanvasSize", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BlurRadius",
			"BorderColor3", "BorderMode", "BorderOffset", "BorderSizePixel", "BorderStrokePosition",
			"BottomImage", "BottomImageContent", "BottomLeftRadius", "BottomRightRadius", "BoundingBehavior",
			"BoundingUI", "Brightness", "CanvasPosition", "CanvasSize", "Capabilities",
			"CellPadding", "CellSize", "Circular", "ClassName", "ClearTextOnFocus",
			"ClipsDescendants", "ClipToDeviceSafeArea", "Color", "CornerRadius", "CurrentCamera",
			"CursorIcon", "CursorIconContent", "CursorPosition", "DisplayOrder", "DistanceStep",
			"DominantAxis", "DragAxis", "Draggable", "DragRelativity", "DragRotation",
			"DragSpace", "DragStyle", "DragUDim2", "EasingDirection", "EasingStyle",
			"ElasticBehavior", "Enabled", "EnableVideoAds", "ExtentsOffset", "ExtentsOffsetWorldSpace",
			"Face", "FallbackImage", "FallbackImageContent", "FillDirection", "FillDirectionMaxCells",
			"FillEmptySpaceColumns", "FillEmptySpaceRows", "FlexMode", "Font", "FontFace",
			"GamepadInputEnabled", "GroupColor3", "GroupTransparency", "GrowRatio", "HorizontalAlignment",
			"HorizontalFlex", "HorizontalScrollBarInset", "HoverHapticEffect", "HoverImage", "HoverImageContent",
			"IgnoreGuiInset", "Image", "ImageColor3", "ImageContent", "ImageRectOffset",
			"ImageRectSize", "ImageTransparency", "InputSink", "Interactable", "InternalVideoUsage",
			"ItemLineAlignment", "LayoutOrder", "LightColor", "LightDirection", "LightInfluence",
			"LineHeight", "LineJoinMode", "Looped", "MajorAxis", "MaxDistance",
			"MaxDragAngle", "MaxDragTranslation", "MaximumResolution", "MaxSize", "MaxTextSize",
			"MaxVisibleGraphemes", "MidImage", "MidImageContent", "MinDragAngle", "MinDragTranslation",
			"MinSize", "MinTextSize", "Modal", "MultiLine", "Name",
			"NextSelectionDown", "NextSelectionLeft", "NextSelectionRight", "NextSelectionUp", "Offset",
			"OpenTypeFeatures", "Padding", "PaddingBottom", "PaddingLeft", "PaddingRight",
			"PaddingTop", "Parent", "PixelsPerStud", "PlaceholderColor3", "PlaceholderText",
			"PlayerToHideFrom", "Playing", "Position", "PressedImage", "PressedImageContent",
			"PressHapticEffect", "ReferenceUIInstance", "ResampleMode", "ResetOnSpawn", "ResponseStyle",
			"RichText", "RollOffMaxDistance", "RollOffMinDistance", "RollOffMode", "RootLocalizationTable",
			"Rotation", "SafeAreaCompatibility", "Sandboxed", "Scale", "ScaleType",
			"ScreenInsets", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollBarThickness", "ScrollingDirection",
			"ScrollingEnabled", "ScrollWheelInputEnabled", "Selectable", "Selected", "SelectionBehaviorDown",
			"SelectionBehaviorLeft", "SelectionBehaviorRight", "SelectionBehaviorUp", "SelectionGroup", "SelectionImageObject",
			"SelectionModeDragSpeed", "SelectionModeRotateSpeed", "SelectionOrder", "SelectionStart", "ShowNativeInput",
			"ShrinkRatio", "Size", "SizeConstraint", "SizeOffset", "SizingMode",
			"SliceCenter", "SliceScale", "SortOrder", "Spread", "StartCorner",
			"StrokeSizingMode", "StudsOffset", "StudsOffsetWorldSpace", "Style", "Text",
			"TextColor3", "TextDirection", "TextEditable", "TextScaled", "TextSize",
			"TextStrokeColor3", "TextStrokeTransparency", "TextTransparency", "TextTruncate", "TextWrapped",
			"TextXAlignment", "TextYAlignment", "Thickness", "TileSize", "TimePosition",
			"Title", "ToolPunchThroughDistance", "TopImage", "TopImageContent", "TopLeftRadius",
			"TopRightRadius", "TouchInputEnabled", "Transparency", "TweenTime", "UIDragSpeedAxisMapping",
			"VerticalAlignment", "VerticalFlex", "VerticalScrollBarInset", "VerticalScrollBarPosition", "Video",
			"VideoColor3", "VideoContent", "VideoRectOffset", "VideoRectSize", "VideoTransparency",
			"Visible", "Volume", "Wraps", "ZIndex", "ZIndexBehavior",
			"ZOffset",
		};
	};
end
