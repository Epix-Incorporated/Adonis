--[[
	Console App Module
	
	Yes this does not exist on original Dex
	]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dex_RemoteFunction = ReplicatedStorage:WaitForChild("NewDex_Event") :: RemoteFunction

-- Common Locals
local Main, Lib, Apps, Settings -- Main Containers
local Explorer, Properties, Console, Notebook -- Major Apps
local API, RMD, env, service, plr, create, createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	Console = Apps.Console
	Notebook = Apps.Notebook
end

local function main()
	local Console = {}

	local window, ConsoleFrame

	local OutputLimit = 500 -- Same as Roblox Console.

	-- Instances: 29 | Scripts: 1 | Modules: 1 | Tags: 0
	local G2L = {}

	-- StarterGui.ScreenGui
	window = Lib.Window.new()
	window:SetTitle("Console")
	window:Resize(500, 400)
	Console.Window = window

	-- StarterGui.ScreenGui.Console
	ConsoleFrame = Instance.new("ImageButton")
	ConsoleFrame.Parent = window.GuiElems.Content
	ConsoleFrame["BorderSizePixel"] = 0
	ConsoleFrame["AutoButtonColor"] = false
	ConsoleFrame["BackgroundTransparency"] = 1
	ConsoleFrame["BackgroundColor3"] = Color3.fromRGB(47, 47, 47)
	ConsoleFrame["Selectable"] = false
	ConsoleFrame["Size"] = UDim2.fromScale(1, 1)
	ConsoleFrame["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	ConsoleFrame["Name"] = [[Console]]
	ConsoleFrame["Position"] = UDim2.new(0, 0, 0, 0)

	-- StarterGui.ScreenGui.Console.CommandLine
	G2L["3"] = Lib.Frame.new().Gui --Instance.new("Frame", ConsoleFrame);
	G2L["3"].Parent = ConsoleFrame
	G2L["3"]["BorderSizePixel"] = 0
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(37, 37, 37)
	G2L["3"]["AnchorPoint"] = Vector2.new(0.5, 1)
	G2L["3"]["ClipsDescendants"] = true
	G2L["3"]["Size"] = UDim2.new(1, -8, 0, 22)
	G2L["3"]["Position"] = UDim2.new(0.5, 0, 1, -5)
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["3"]["Name"] = [[CommandLine]]

	-- StarterGui.ScreenGui.Console.CommandLine.UIStroke
	G2L["4"] = Instance.new("UIStroke")
	G2L["4"].Parent = G2L["3"]
	G2L["4"]["Transparency"] = 0.65
	G2L["4"]["Thickness"] = 1.25

	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame
	G2L["5"] = Instance.new("ScrollingFrame")
	G2L["5"].Parent = G2L["3"]
	G2L["5"]["Active"] = true
	G2L["5"]["ScrollingDirection"] = Enum.ScrollingDirection.X
	G2L["5"]["BorderSizePixel"] = 0
	G2L["5"]["CanvasSize"] = UDim2.new(0, 0, 0, 0)
	G2L["5"]["ElasticBehavior"] = Enum.ElasticBehavior.Never
	G2L["5"]["TopImage"] = [[rbxasset://textures/ui/Scroll/scroll-middle.png]]
	G2L["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["5"]["HorizontalScrollBarInset"] = Enum.ScrollBarInset.Always
	G2L["5"]["BottomImage"] = [[rbxasset://textures/ui/Scroll/scroll-middle.png]]
	G2L["5"]["AutomaticCanvasSize"] = Enum.AutomaticSize.X
	G2L["5"]["Size"] = UDim2.new(1, 0, 1, 0)
	G2L["5"]["ScrollBarImageColor3"] = Color3.fromRGB(57, 57, 57)
	G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["5"]["ScrollBarThickness"] = 2
	G2L["5"]["BackgroundTransparency"] = 1

	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.TextBox
	G2L["6"] = Instance.new("TextBox")
	G2L["6"].Parent = G2L["5"]
	G2L["6"]["CursorPosition"] = -1
	G2L["6"]["TextXAlignment"] = Enum.TextXAlignment.Left
	G2L["6"]["PlaceholderColor3"] = Color3.fromRGB(211, 211, 211)
	G2L["6"]["BorderSizePixel"] = 0
	G2L["6"]["TextSize"] = 13
	G2L["6"]["TextColor3"] = Color3.fromRGB(211, 211, 211)
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["6"]["FontFace"] =
		Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	G2L["6"]["AutomaticSize"] = Enum.AutomaticSize.X
	G2L["6"]["ClearTextOnFocus"] = false
	G2L["6"]["PlaceholderText"] = [[Run a command]]
	G2L["6"]["Size"] = UDim2.new(0, 246, 0, 22)
	G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["6"]["Text"] = [[]]
	G2L["6"]["BackgroundTransparency"] = 1

	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.TextBox.UIPadding
	G2L["7"] = Instance.new("UIPadding")
	G2L["7"].Parent = G2L["6"]
	G2L["7"]["PaddingLeft"] = UDim.new(0, 7)

	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.Highlight
	G2L["8"] = Instance.new("TextLabel")
	G2L["8"].Parent = G2L["5"]
	G2L["8"]["Interactable"] = false
	G2L["8"]["ZIndex"] = 2
	G2L["8"]["BorderSizePixel"] = 0
	G2L["8"]["TextSize"] = 13
	G2L["8"]["TextXAlignment"] = Enum.TextXAlignment.Left
	G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["8"]["FontFace"] =
		Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	G2L["8"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["8"]["BackgroundTransparency"] = 1
	G2L["8"]["RichText"] = true
	G2L["8"]["Size"] = UDim2.new(0, 246, 0, 22)
	G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["8"]["Text"] = [[]]
	G2L["8"]["Selectable"] = true
	G2L["8"]["AutomaticSize"] = Enum.AutomaticSize.X
	G2L["8"]["Name"] = [[Highlight]]

	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.Highlight.UIPadding
	G2L["9"] = Instance.new("UIPadding")
	G2L["9"].Parent = G2L["8"]
	G2L["9"]["PaddingLeft"] = UDim.new(0, 7)

	G2L["backgroundOutput"] = Instance.new("Frame")
	G2L["backgroundOutput"].Parent = ConsoleFrame
	G2L["backgroundOutput"]["BorderSizePixel"] = 0
	G2L["backgroundOutput"]["BackgroundColor3"] = Color3.fromRGB(36, 36, 36)
	G2L["backgroundOutput"]["Name"] = [[BackgroundOutput]]
	G2L["backgroundOutput"]["AnchorPoint"] = Vector2.new(0, 0)
	G2L["backgroundOutput"]["Size"] = UDim2.new(1, -8, 1, -55)
	G2L["backgroundOutput"]["Position"] = UDim2.new(0, 4, 0, 23)
	G2L["backgroundOutput"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["backgroundOutput"]["ZIndex"] = 1

	local scrollbar = Lib.ScrollBar.new()
	scrollbar.Gui.Parent = ConsoleFrame
	scrollbar.Gui.Size = UDim2.new(0, 16, 1, -55)
	scrollbar.Gui.Position = UDim2.new(1, -20, 0, 23)
	scrollbar.Gui.Up.ZIndex = 3
	scrollbar.Gui.Down.ZIndex = 3

	-- StarterGui.ScreenGui.Console.Output
	G2L["a"] = Instance.new("ScrollingFrame")
	G2L["a"].Parent = ConsoleFrame
	G2L["a"]["Active"] = true
	G2L["a"]["BorderSizePixel"] = 0
	G2L["a"]["CanvasSize"] = UDim2.new(0, 0, 0, 0)
	G2L["a"]["TopImage"] = ""
	G2L["a"]["BackgroundColor3"] = Color3.fromRGB(36, 36, 36)
	G2L["a"].BackgroundTransparency = 1
	G2L["a"]["Name"] = [[Output]]
	G2L["a"]["ScrollBarImageTransparency"] = 0
	G2L["a"]["BottomImage"] = ""
	G2L["a"]["AnchorPoint"] = Vector2.new(0, 0)
	G2L["a"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y
	G2L["a"]["Size"] = UDim2.new(1, -8, 1, -55)
	G2L["a"]["Position"] = UDim2.new(0, 4, 0, 23)
	G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["a"].ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
	G2L["a"]["ScrollBarThickness"] = 16
	G2L["a"]["ZIndex"] = 1

	if Settings.Window.Transparency then
		G2L["a"].BackgroundTransparency = Settings.Window.Transparency
	end

	G2L["a"]:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
		if G2L["a"].AbsoluteCanvasSize ~= G2L["a"].AbsoluteWindowSize then
			scrollbar.Gui.Visible = true
		else
			scrollbar.Gui.Visible = false
		end
	end)

	-- StarterGui.ScreenGui.Console.Output.UIListLayout
	G2L["b"] = Instance.new("UIListLayout")
	G2L["b"].Parent = G2L["a"]
	G2L["b"]["SortOrder"] = Enum.SortOrder.LayoutOrder

	-- StarterGui.ScreenGui.Console.Output.UIStroke
	G2L["c"] = Instance.new("UIStroke")
	G2L["c"].Parent = G2L["a"]
	G2L["c"]["Transparency"] = 0.7
	G2L["c"]["Thickness"] = 1.25
	G2L["c"]["Color"] = Color3.fromRGB(12, 12, 12)

	-- StarterGui.ScreenGui.Console.Output.OutputTextSize
	G2L["d"] = Instance.new("NumberValue")
	G2L["d"].Parent = G2L["a"]
	G2L["d"]["Name"] = [[OutputTextSize]]
	G2L["d"]["Value"] = 15

	-- StarterGui.ScreenGui.Console.Output.OutputLimit
	G2L["e"] = Instance.new("NumberValue")
	G2L["e"].Parent = G2L["a"]
	G2L["e"]["Name"] = [[OutputLimit]]
	G2L["e"]["Value"] = OutputLimit

	-- StarterGui.ScreenGui.Console.Output.UIPadding
	G2L["f"] = Instance.new("UIPadding")
	G2L["f"].Parent = G2L["a"]
	G2L["f"]["PaddingTop"] = UDim.new(0, 2)

	-- StarterGui.ScreenGui.Console.TextSizeBox
	G2L["10"] = Instance.new("Frame")
	G2L["10"].Parent = ConsoleFrame
	G2L["10"]["BorderSizePixel"] = 0
	G2L["10"]["BackgroundColor3"] = Color3.fromRGB(37, 37, 37)
	G2L["10"]["ClipsDescendants"] = true
	G2L["10"]["Size"] = UDim2.new(0, 37, 0, 15)
	G2L["10"]["Position"] = UDim2.new(0, 4, 0, 4)
	G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["10"]["Name"] = [[TextSizeBox]]

	-- StarterGui.ScreenGui.Console.TextSizeBox.TextBox
	G2L["11"] = Instance.new("TextBox")
	G2L["11"].Parent = G2L["10"]
	G2L["11"]["PlaceholderColor3"] = Color3.fromRGB(108, 108, 108)
	G2L["11"]["BorderSizePixel"] = 0
	G2L["11"]["TextWrapped"] = true
	G2L["11"]["TextSize"] = 15
	G2L["11"]["TextColor3"] = Color3.fromRGB(211, 211, 211)
	G2L["11"]["TextScaled"] = true
	G2L["11"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["11"]["FontFace"] =
		Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	G2L["11"]["PlaceholderText"] = [[Size]]
	G2L["11"]["Size"] = UDim2.new(1, 0, 1, 0)
	G2L["11"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["11"]["Text"] = [[]]
	G2L["11"]["BackgroundTransparency"] = 1

	-- StarterGui.ScreenGui.Console.TextSizeBox.TextBox.UIPadding
	G2L["12"] = Instance.new("UIPadding")
	G2L["12"].Parent = G2L["11"]
	G2L["12"]["PaddingTop"] = UDim.new(0, 2)
	G2L["12"]["PaddingRight"] = UDim.new(0, 5)
	G2L["12"]["PaddingLeft"] = UDim.new(0, 5)
	G2L["12"]["PaddingBottom"] = UDim.new(0, 2)

	-- StarterGui.ScreenGui.Console.TextSizeBox.UIStroke
	G2L["13"] = Instance.new("UIStroke")
	G2L["13"].Parent = G2L["10"]
	G2L["13"]["Transparency"] = 0.65
	G2L["13"]["Thickness"] = 1.25

	-- StarterGui.ScreenGui.Console.Clear
	G2L["14"] = Instance.new("ImageButton")
	G2L["14"].Parent = ConsoleFrame
	G2L["14"]["BorderSizePixel"] = 0
	G2L["14"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57)
	G2L["14"]["Size"] = UDim2.new(0, 37, 0, 15)
	G2L["14"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["14"]["Name"] = [[Clear]]
	G2L["14"]["Position"] = UDim2.new(1, -42, 0, 4)

	-- StarterGui.ScreenGui.Console.Clear.TextLabel
	G2L["15"] = Instance.new("TextLabel")
	G2L["15"].Parent = G2L["14"]
	G2L["15"]["TextWrapped"] = true
	G2L["15"]["Interactable"] = false
	G2L["15"]["BorderSizePixel"] = 0
	G2L["15"]["TextSize"] = 20
	G2L["15"]["TextScaled"] = true
	G2L["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["15"]["FontFace"] =
		Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	G2L["15"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["15"]["BackgroundTransparency"] = 1
	G2L["15"]["Size"] = UDim2.new(1, 0, 1, 0)
	G2L["15"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["15"]["Text"] = [[Clear]]

	-- StarterGui.ScreenGui.Console.Clear.UIPadding
	G2L["16"] = Instance.new("UIPadding")
	G2L["16"].Parent = G2L["14"]
	G2L["16"]["PaddingTop"] = UDim.new(0, 1)
	G2L["16"]["PaddingBottom"] = UDim.new(0, 1)

	-- StarterGui.ScreenGui.Console.OutputTemplate
	G2L["17"] = Instance.new("TextBox")
	G2L["17"].Parent = ConsoleFrame
	G2L["17"]["Visible"] = false
	G2L["17"]["Active"] = false
	G2L["17"]["Name"] = [[OutputTemplate]]
	G2L["17"]["TextXAlignment"] = Enum.TextXAlignment.Left
	G2L["17"]["BorderSizePixel"] = 0
	G2L["17"]["TextEditable"] = false
	G2L["17"]["TextWrapped"] = true
	G2L["17"]["TextSize"] = 15
	G2L["17"]["TextColor3"] = Color3.fromRGB(171, 171, 171)
	G2L["17"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["17"]["RichText"] = true
	G2L["17"]["FontFace"] =
		Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	G2L["17"]["AutomaticSize"] = Enum.AutomaticSize.Y
	G2L["17"]["Selectable"] = false
	G2L["17"]["ClearTextOnFocus"] = false
	G2L["17"]["Size"] = UDim2.new(1, 0, 0, 1)
	G2L["17"]["Position"] = UDim2.new(0, 20, 0, 0)
	G2L["17"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["17"]["Text"] = [[(timestamp) <font color="rgb(255, 255, 255)">Output</font>]]
	G2L["17"]["BackgroundTransparency"] = 1

	-- StarterGui.ScreenGui.Console.OutputTemplate.UIPadding
	G2L["18"] = Instance.new("UIPadding")
	G2L["18"].Parent = G2L["17"]
	G2L["18"]["PaddingRight"] = UDim.new(0, 6)
	G2L["18"]["PaddingLeft"] = UDim.new(0, 6)

	-- StarterGui.ScreenGui.Console.CtrlScroll
	G2L["19"] = Instance.new("ImageButton")
	G2L["19"].Parent = ConsoleFrame
	G2L["19"]["BorderSizePixel"] = 0
	G2L["19"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57)
	G2L["19"]["Size"] = UDim2.new(0, 60, 0, 15)
	G2L["19"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["19"]["Name"] = [[CtrlScroll]]
	G2L["19"]["Position"] = UDim2.new(0, 46, 0, 4)

	-- StarterGui.ScreenGui.Console.CtrlScroll.TextLabel
	G2L["1a"] = Instance.new("TextLabel")
	G2L["1a"].Parent = G2L["19"]
	G2L["1a"]["TextWrapped"] = true
	G2L["1a"]["Interactable"] = false
	G2L["1a"]["BorderSizePixel"] = 0
	G2L["1a"]["TextSize"] = 20
	G2L["1a"]["TextScaled"] = true
	G2L["1a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["1a"]["FontFace"] =
		Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	G2L["1a"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["1a"]["BackgroundTransparency"] = 1
	G2L["1a"]["Size"] = UDim2.new(1, 0, 1, 0)
	G2L["1a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["1a"]["Text"] = [[Ctrl Scroll]]

	-- StarterGui.ScreenGui.Console.CtrlScroll.UIPadding
	G2L["1b"] = Instance.new("UIPadding")
	G2L["1b"].Parent = G2L["19"]
	G2L["1b"]["PaddingTop"] = UDim.new(0, 1)
	G2L["1b"]["PaddingBottom"] = UDim.new(0, 1)

	-- StarterGui.ScreenGui.Console.AutoScroll
	G2L["20"] = Instance.new("ImageButton")
	G2L["20"].Parent = ConsoleFrame
	G2L["20"]["BorderSizePixel"] = 0
	G2L["20"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57)
	G2L["20"]["Size"] = UDim2.new(0, 60, 0, 15)
	G2L["20"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["20"]["Name"] = [[AutoScroll]]
	G2L["20"]["Position"] = UDim2.new(0, 110, 0, 4)

	-- StarterGui.ScreenGui.Console.AutoScroll.TextLabel
	G2L["1e"] = Instance.new("TextLabel")
	G2L["1e"].Parent = G2L["20"]
	G2L["1e"]["TextWrapped"] = true
	G2L["1e"]["Interactable"] = false
	G2L["1e"]["BorderSizePixel"] = 0
	G2L["1e"]["TextSize"] = 20
	G2L["1e"]["TextScaled"] = true
	G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["1e"]["FontFace"] =
		Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	G2L["1e"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["1e"]["BackgroundTransparency"] = 1
	G2L["1e"]["Size"] = UDim2.new(1, 0, 1, 0)
	G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["1e"]["Text"] = [[Auto Scroll]]

	-- StarterGui.ScreenGui.Console.AutoScroll.UIPadding
	G2L["1f"] = Instance.new("UIPadding")
	G2L["1f"].Parent = G2L["20"]
	G2L["1f"]["PaddingTop"] = UDim.new(0, 1)
	G2L["1f"]["PaddingBottom"] = UDim.new(0, 1)

	-- StarterGui.ScreenGui.Console.ContextSwitcher (Client/Server)
	G2L["21"] = Instance.new("ImageButton")
	G2L["21"].Parent = ConsoleFrame
	G2L["21"]["BorderSizePixel"] = 0
	G2L["21"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57)
	G2L["21"]["Size"] = UDim2.new(0, 60, 0, 15)
	G2L["21"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["21"]["Name"] = [[ContextSwitcher]]
	G2L["21"]["Position"] = UDim2.new(0, 175, 0, 4)

	-- StarterGui.ScreenGui.Console.ContextSwitcher.TextLabel
	G2L["22"] = Instance.new("TextLabel")
	G2L["22"].Parent = G2L["21"]
	G2L["22"]["TextWrapped"] = true
	G2L["22"]["Interactable"] = false
	G2L["22"]["BorderSizePixel"] = 0
	G2L["22"]["TextSize"] = 20
	G2L["22"]["TextScaled"] = true
	G2L["22"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["22"]["FontFace"] =
		Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	G2L["22"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
	G2L["22"]["BackgroundTransparency"] = 1
	G2L["22"]["Size"] = UDim2.new(1, 0, 1, 0)
	G2L["22"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
	G2L["22"]["Text"] = [[Client]]

	-- StarterGui.ScreenGui.Console.ContextSwitcher.UIPadding
	G2L["23"] = Instance.new("UIPadding")
	G2L["23"].Parent = G2L["21"]
	G2L["23"]["PaddingTop"] = UDim.new(0, 1)
	G2L["23"]["PaddingBottom"] = UDim.new(0, 1)

	-- StarterGui.ScreenGui.ConsoleHandler
	G2L["1c"] = Instance.new("LocalScript")
	G2L["1c"].Parent = G2L["1"]
	G2L["1c"]["Name"] = [[ConsoleHandler]]

	-- StarterGui.ScreenGui.ConsoleHandler.SyntaxHighlighter
	G2L["1d"] = Instance.new("ModuleScript")
	G2L["1d"].Parent = G2L["1c"]
	G2L["1d"]["Name"] = [[SyntaxHighlighter]]

	-- Require G2L wrapper
	local G2L_REQUIRE = require
	local G2L_MODULES = {}
	local function require(Module: ModuleScript)
		local ModuleState = G2L_MODULES[Module]
		if ModuleState then
			if not ModuleState.Required then
				ModuleState.Required = true
				ModuleState.Value = ModuleState.Closure()
			end
			return ModuleState.Value
		end
		return G2L_REQUIRE(Module)
	end

	G2L_MODULES[G2L["1d"]] = {
		Closure = function()
			local script = G2L["1d"]
			local highlighter = {}
			local keywords = {
				lua = {
					"and",
					"break",
					"or",
					"else",
					"elseif",
					"if",
					"then",
					"until",
					"repeat",
					"while",
					"do",
					"for",
					"in",
					"end",
					"local",
					"return",
					"function",
					"export",
				},
				rbx = {
					"game",
					"workspace",
					"script",
					"math",
					"string",
					"table",
					"task",
					"wait",
					"select",
					"next",
					"Enum",
					"error",
					"warn",
					"tick",
					"assert",
					"shared",
					"loadstring",
					"tonumber",
					"tostring",
					"type",
					"typeof",
					"unpack",
					"print",
					"Instance",
					"CFrame",
					"Vector3",
					"Vector2",
					"Color3",
					"UDim",
					"UDim2",
					"Ray",
					"BrickColor",
					"OverlapParams",
					"RaycastParams",
					"Axes",
					"Random",
					"Region3",
					"Rect",
					"TweenInfo",
					"collectgarbage",
					"not",
					"utf8",
					"pcall",
					"xpcall",
					"_G",
					"setmetatable",
					"getmetatable",
					"os",
					"pairs",
					"ipairs",
				},
				exploit = {
					"hookmetamethod",
					"hookfunction",
					"getgc",
					"filtergc",
					"Drawing",
					"getgenv",
					"getsenv",
					"getrenv",
					"getfenv",
					"setfenv",
					"decompile",
					"saveinstance",
					"getrawmetatable",
					"setrawmetatable",
					"checkcaller",
					"cloneref",
					"clonefunction",
					"iscclosure",
					"islclosure",
					"isexecutorclosure",
					"newcclosure",
					"getfunctionhash",
					"crypt",
					"writefile",
					"appendfile",
					"loadfile",
					"readfile",
					"listfiles",
					"makefolder",
					"isfolder",
					"isfile",
					"delfile",
					"delfolder",
					"getcustomasset",
					"fireclickdetector",
					"firetouchinterest",
					"fireproximityprompt",
				},
				operators = {
					"#",
					"+",
					"-",
					"*",
					"%",
					"/",
					"^",
					"=",
					"~",
					"=",
					"<",
					">",
					",",
					".",
					"(",
					")",
					"{",
					"}",
					"[",
					"]",
					";",
					":",
				},
			}

			local colors = {
				numbers = Color3.fromRGB(255, 198, 0),
				boolean = Color3.fromRGB(255, 198, 0),
				operator = Color3.fromRGB(204, 204, 204),
				lua = Color3.fromRGB(132, 214, 247),
				exploit = Color3.fromRGB(171, 84, 247),
				rbx = Color3.fromRGB(248, 109, 124),
				str = Color3.fromRGB(173, 241, 132),
				comment = Color3.fromRGB(102, 102, 102),
				null = Color3.fromRGB(255, 198, 0),
				call = Color3.fromRGB(253, 251, 172),
				self_call = Color3.fromRGB(253, 251, 172),
				local_color = Color3.fromRGB(248, 109, 115),
				function_color = Color3.fromRGB(248, 109, 115),
				self_color = Color3.fromRGB(248, 109, 115),
				local_property = Color3.fromRGB(97, 161, 241),
			}

			local function createKeywordSet(keywords)
				local keywordSet = {}
				for _, keyword in ipairs(keywords) do
					keywordSet[keyword] = true
				end
				return keywordSet
			end

			local luaSet = createKeywordSet(keywords.lua)
			local exploitSet = createKeywordSet(keywords.exploit)
			local rbxSet = createKeywordSet(keywords.rbx)
			local operatorsSet = createKeywordSet(keywords.operators)

			local function getHighlight(tokens, index)
				local token = tokens[index]

				if colors[token .. "_color"] then
					return colors[token .. "_color"]
				end

				if tonumber(token) then
					return colors.numbers
				elseif token == "nil" then
					return colors.null
				elseif token:sub(1, 2) == "--" then
					return colors.comment
				elseif operatorsSet[token] then
					return colors.operator
				elseif luaSet[token] then
					return colors.rbx
				elseif rbxSet[token] then
					return colors.lua
				elseif exploitSet[token] then
					return colors.exploit
				elseif token:sub(1, 1) == '"' or token:sub(1, 1) == "'" then
					return colors.str
				elseif token == "true" or token == "false" then
					return colors.boolean
				end

				if tokens[index + 1] == "(" then
					if tokens[index - 1] == ":" then
						return colors.self_call
					end

					return colors.call
				end

				if tokens[index - 1] == "." then
					if tokens[index - 2] == "Enum" then
						return colors.rbx
					end

					return colors.local_property
				end
			end

			function highlighter.run(source)
				local tokens = {}
				local currentToken = ""

				local inString = false
				local inComment = false
				local commentPersist = false

				for i = 1, #source do
					local character = source:sub(i, i)

					if inComment then
						if character == "\n" and not commentPersist then
							table.insert(tokens, currentToken)
							table.insert(tokens, character)
							currentToken = ""

							inComment = false
						elseif source:sub(i - 1, i) == "]]" and commentPersist then
							currentToken ..= "]"

							table.insert(tokens, currentToken)
							currentToken = ""

							inComment = false
							commentPersist = false
						else
							currentToken = currentToken .. character
						end
					elseif inString then
						currentToken = currentToken .. character
						if (character == inString and source:sub(i - 1, i - 1) ~= "\\") or character == "\n" then
							inString = false
						end
					else
						local shouldInsertToken = false
						local shouldInsertCharacter = false

						if source:sub(i, i + 1) == "--" then
							table.insert(tokens, currentToken)
							currentToken = "-"
							inComment = true
							commentPersist = source:sub(i + 2, i + 3) == "[["
						elseif character == '"' or character == "'" then
							table.insert(tokens, currentToken)
							currentToken = character
							inString = character
						elseif operatorsSet[character] or character:match("%s") then
							shouldInsertToken = true
							shouldInsertCharacter = true
						elseif character:match("[%w_]") then
							currentToken = currentToken .. character
						end

						if shouldInsertToken then
							table.insert(tokens, currentToken)
							if shouldInsertCharacter then
								table.insert(tokens, character)
							end
							currentToken = ""
						end
					end
				end

				table.insert(tokens, currentToken)

				local highlighted = {}

				for i, token in ipairs(tokens) do
					local highlight = getHighlight(tokens, i)

					if highlight then
						local syntax = string.format(
							'<font color = "#%s">%s</font>',
							highlight:ToHex(),
							token:gsub("<", "&lt;"):gsub(">", "&gt;")
						)

						table.insert(highlighted, syntax)
					else
						table.insert(highlighted, token)
					end
				end

				return table.concat(highlighted)
			end

			return highlighter
		end,
	}

	Console.Init = function()
		-- StarterGui.ScreenGui.ConsoleHandler
		local script = G2L["1c"]

		local CtrlScroll = false
		local AutoScroll = false
		local IsServerMode = false -- false = Client mode, true = Server mode
		local ServerLogConnection = nil -- Connection for server logs

		local LogService = game:GetService("LogService")
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Mouse = LocalPlayer:GetMouse()
		local UserInputService = game:GetService("UserInputService")
		local RunService = game:GetService("RunService")

		local Console = ConsoleFrame
		local SyntaxHighlightingModule = require(script.SyntaxHighlighter)
		local OutputTextSize = Console.Output.OutputTextSize

		local function Tween(obj, info, prop)
			local tween = game:GetService("TweenService"):Create(obj, info, prop)
			tween:Play()
			return tween
		end

		-- MOUSE STUFFS

		if CtrlScroll == true then
			Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
		elseif CtrlScroll == false then
			Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
		end
		Console.CtrlScroll.MouseButton1Click:Connect(function()
			CtrlScroll = not CtrlScroll
			if CtrlScroll == true then
				Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
			elseif CtrlScroll == false then
				Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
			end
		end)

		local IsHoldingCTRL = false
		UserInputService.InputBegan:Connect(function(input, gameproc)
			if not gameproc then
				if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
					IsHoldingCTRL = true
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(input, gameproc)
			if not gameproc then
				if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
					IsHoldingCTRL = false
				end
			end
		end)

		if AutoScroll == true then
			Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
		elseif AutoScroll == false then
			Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
		end
		Console.AutoScroll.MouseButton1Click:Connect(function()
			AutoScroll = not AutoScroll
			if AutoScroll == true then
				Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
				Console.Output.CanvasPosition = Vector2.new(0, 9e9)
			elseif AutoScroll == false then
				Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
			end
		end)

		-- Console part
		local displayedOutput = {}
		local OutputLimit = Console.Output.OutputLimit

		Console.TextSizeBox.TextBox.Text = tostring(OutputTextSize.Value)

		Console.TextSizeBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			local tonum = tonumber(Console.TextSizeBox.TextBox.Text)
			if tonum then
				OutputTextSize.Value = tonum
			end
		end)
		OutputTextSize:GetPropertyChangedSignal("Value"):Connect(function()
			Console.TextSizeBox.TextBox.Text = tostring(OutputTextSize.Value)
		end)

		local scrollConsoleInput
		Console.Output.MouseEnter:Connect(function()
			scrollConsoleInput = UserInputService.InputChanged:Connect(function(input)
				if CtrlScroll and input.UserInputType == Enum.UserInputType.MouseWheel and IsHoldingCTRL == true then
					Console.Output.ScrollingEnabled = false
					local newTextSize = OutputTextSize.Value + input.Position.Z
					if newTextSize >= 1 then
						OutputTextSize.Value = newTextSize
					end
				else
					Console.Output.ScrollingEnabled = true
				end
			end)
		end)
		Console.Output.MouseLeave:Connect(function()
			if scrollConsoleInput then
				scrollConsoleInput:Disconnect()
				scrollConsoleInput = nil
			end
		end)

		Console.Clear.MouseButton1Click:Connect(function()
			for _, log in pairs(Console.Output:GetChildren()) do
				if log:IsA("TextBox") then
					log:Destroy()
				end
			end
		end)

		local focussedOutput

		local function addOutputMessage(msg, msgtype)
			local formattedText = ""
			local unformattedText = ""
			local newOutputText = Console.OutputTemplate:Clone()
			table.insert(displayedOutput, newOutputText)

			if #displayedOutput > OutputLimit.Value then
				local oldest = table.remove(displayedOutput, 1)
				if oldest and typeof(oldest) == "Instance" then
					oldest:Destroy()
				end
			end

			unformattedText = os.date("%H:%M:%S") .. "   " .. msg
			if msgtype == Enum.MessageType.MessageOutput then
				formattedText = os.date("%H:%M:%S") .. '   <font color="rgb(204, 204, 204)">' .. msg .. "</font>"
				newOutputText.Text = formattedText
			elseif msgtype == Enum.MessageType.MessageWarning then
				formattedText = os.date("%H:%M:%S") .. '   <b><font color="rgb(255, 142, 60)">' .. msg .. "</font></b>"
				newOutputText.Text = formattedText
			elseif msgtype == Enum.MessageType.MessageError then
				formattedText = os.date("%H:%M:%S") .. '   <b><font color="rgb(255, 68, 68)">' .. msg .. "</font></b>"
				newOutputText.Text = formattedText
			elseif msgtype == Enum.MessageType.MessageInfo then
				formattedText = os.date("%H:%M:%S") .. '   <font color="rgb(128, 215, 255)">' .. msg .. "</font>"
				newOutputText.Text = formattedText
			end

			newOutputText.TextSize = OutputTextSize.Value
			OutputTextSize:GetPropertyChangedSignal("Value"):Connect(function()
				newOutputText.TextSize = OutputTextSize.Value
			end)

			newOutputText.Focused:Connect(function()
				focussedOutput = newOutputText
				newOutputText.Text = unformattedText
			end)
			newOutputText.FocusLost:Connect(function()
				focussedOutput = nil
				newOutputText.Text = formattedText
			end)

			newOutputText.Parent = Console.Output
			newOutputText.Visible = true

			if AutoScroll then
				Console.Output.CanvasPosition = Vector2.new(0, 9e9)
			end
		end

		-- Context Switcher (Client/Server Mode)
		local function updateContextSwitcher()
			if IsServerMode then
				Console.ContextSwitcher.TextLabel.Text = "Server"
				Console.ContextSwitcher.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
			else
				Console.ContextSwitcher.TextLabel.Text = "Client"
				Console.ContextSwitcher.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
			end
		end

		local function switchToServerMode()
			IsServerMode = true
			updateContextSwitcher()

			-- Clear current output
			for _, log in pairs(Console.Output:GetChildren()) do
				if log:IsA("TextBox") then
					log:Destroy()
				end
			end

			-- Request server logs from server
			local serverLogs = Dex_RemoteFunction:InvokeServer("GetServerLogs")
			if serverLogs and type(serverLogs) == "table" then
				for _, logData in ipairs(serverLogs) do
					addOutputMessage(logData.message, logData.messageType)
				end
			end

			-- Start listening for server log updates
			if not ServerLogConnection then
				ServerLogConnection = RunService.Heartbeat:Connect(function()
					local newLogs = Dex_RemoteFunction:InvokeServer("PollServerLogs")
					if newLogs and type(newLogs) == "table" then
						for _, logData in ipairs(newLogs) do
							addOutputMessage(logData.message, logData.messageType)
						end
					end
				end)
			end
		end

		local function switchToClientMode()
			IsServerMode = false
			updateContextSwitcher()

			-- Disconnect server log polling
			if ServerLogConnection then
				ServerLogConnection:Disconnect()
				ServerLogConnection = nil
			end

			-- Clear current output
			for _, log in pairs(Console.Output:GetChildren()) do
				if log:IsA("TextBox") then
					log:Destroy()
				end
			end
		end

		Console.ContextSwitcher.MouseButton1Click:Connect(function()
			if IsServerMode then
				switchToClientMode()
			else
				switchToServerMode()
			end
		end)

		updateContextSwitcher()

		LogService.MessageOut:Connect(function(msg, msgtype)
			-- Only show client logs when in client mode
			if not IsServerMode then
				addOutputMessage(msg, msgtype)
			end
		end)

		Console.Output.MouseLeave:Connect(function()
			if focussedOutput then
				focussedOutput:ReleaseFocus()
			end
		end)

		Console.CommandLine.ScrollingFrame.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			local oneliner = string.gsub(Console.CommandLine.ScrollingFrame.TextBox.Text, "\n", "    ")
			Console.CommandLine.ScrollingFrame.TextBox.Text = oneliner

			Console.CommandLine.ScrollingFrame.Highlight.Text =
				SyntaxHighlightingModule.run(Console.CommandLine.ScrollingFrame.TextBox.Text)
		end)

		Console.CommandLine.ScrollingFrame.TextBox.FocusLost:Connect(function(enterPressed)
			if enterPressed and Console.CommandLine.ScrollingFrame.TextBox.Text ~= "" then
				local code = Console.CommandLine.ScrollingFrame.TextBox.Text
				print("> " .. code)

				-- Execute on server or client based on mode
				if IsServerMode then
					-- Execute on server
					local success, err = Dex_RemoteFunction:InvokeServer("Loadstring", code)
					if not success and err then
						warn("Server execution error: " .. tostring(err))
					end
				else
					-- Execute on client through Adonis (checks CodeExecution setting)
					-- Remote.LoadCode handles all the bytecode compilation and client execution
					local success = Dex_RemoteFunction:InvokeServer("LoadstringClient", code)
					if not success then
						warn("Client execution failed - check if CodeExecution is enabled")
					end
				end

				Console.CommandLine.ScrollingFrame.TextBox.Text = ""
			end
		end)
	end

	return Console
end

-- TODO: Remove when open source

return { InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main }
