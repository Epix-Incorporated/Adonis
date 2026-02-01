--[[
	Settings Module
	
	The Module to configure settings
]]

-- ADONIS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dex_RemoteFunction = ReplicatedStorage:WaitForChild("NewDex_Event") :: RemoteFunction

-- Common Locals
local Main, Lib, Apps, Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
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
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local AboutMenu = {}

	local scrollV, scrollH
	local settingsListFrame
	local expanded, viewList = {}, {}

	local aboutFrame

	AboutMenu.AboutFrame = function()
		local aboutFrame = create({
			{
				1,
				"Frame",
				{
					Size = UDim2.new(1, 0, 1, 0),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					Name = "AboutFrame",
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				},
			},
			{
				2,
				"Frame",
				{
					Parent = { 1 },
					Size = UDim2.new(1, 0, 1, 0),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					Name = "Container",
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				},
			},
			{
				3,
				"UIListLayout",
				{
					Parent = { 2 },
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				},
			},
		})

		--local Container = aboutFrame.Container

		return aboutFrame
	end

	AboutMenu.CreditsEntry = (function()
		local funcs = {}

		local function createGui()
			local creditsEntry = create({
				{
					1,
					"Frame",
					{
						Size = UDim2.new(1, 0, 0, 10),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						Name = "TextEntry",
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					},
				},
				{
					2,
					"TextBox",
					{
						Parent = { 1 },
						BorderSizePixel = 0,
						RichText = true,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						TextWrapped = true,
						TextSize = 20,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Size = UDim2.new(1, 0, 1, 0),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						Text = "text",
						Font = Enum.Font.SourceSans,
						BackgroundTransparency = 1,
						ClearTextOnFocus = false,
						TextEditable = false,
					},
				},
			})

			return creditsEntry
		end

		function funcs:ChangeText(text)
			self.GuiElems.TextBox.Text = text
		end

		local mt = { __index = funcs }
		local function new(text)
			local obj = setmetatable({}, mt)

			obj.Gui = createGui()

			obj.GuiElems = {
				TextBox = obj.Gui.TextBox,
			}

			if text then
				obj:ChangeText(text)
			end

			-- Parent
			obj.Gui.Parent = aboutFrame.Container

			return obj
		end

		return { new = new }
	end)()

	AboutMenu.AddCreditsEntry = function(text, properties)
		local creditsEntry = create({
			{
				1,
				"Frame",
				{
					Size = UDim2.new(1, 0, 0, 10),
					AutomaticSize = Enum.AutomaticSize.XY,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					Name = "TextEntry",
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				},
			},
			{
				2,
				"TextLabel",
				{
					Parent = { 1 },
					AutomaticSize = Enum.AutomaticSize.XY,
					BorderSizePixel = 0,
					RichText = true,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					TextWrapped = true,
					TextSize = 14,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.new(1, 0, 1, 0),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					Text = "text",
					Font = Enum.Font.SourceSans,
					BackgroundTransparency = 1,
				},
			},
		})

		local entryText = creditsEntry.TextLabel
		entryText.Text = text

		-- Default text size
		entryText.TextSize = 16

		if properties then
			for property, val in pairs(properties) do
				entryText[property] = val
			end
		end

		creditsEntry.Parent = aboutFrame.Container

		return creditsEntry
	end

	-- Init
	AboutMenu.Init = function()
		local window = Lib.Window.new()
		AboutMenu.Window = window

		window:SetTitle("About")
		window.Resizable = true

		-- Setup Results ScrollingFrame
		AboutMenu.Window.GuiElems.Main.Parent.Name = "Dex_AboutWindow" -- Change ScreenGui name

		-- Create Gui
		aboutFrame = AboutMenu.AboutFrame()

		AboutMenu.AddCreditsEntry("<b>About Dex</b>", {
			TextSize = 30,
		})

		AboutMenu.AddCreditsEntry("<b>Version:</b> " .. Main.Version)
		AboutMenu.AddCreditsEntry("\n", { TextSize = 5 })
		AboutMenu.AddCreditsEntry("Developed by Moon aka. LorekeeperZinnia")
		AboutMenu.AddCreditsEntry("This version is modified, the official release was never finished.", {
			TextSize = 12,
		})
		AboutMenu.AddCreditsEntry("\n\n", { TextSize = 10 })
		AboutMenu.AddCreditsEntry("<b>Additional Contributors:</b>", { TextSize = 17 })
		AboutMenu.AddCreditsEntry("SnowyShiro", { TextSize = 17 })
		AboutMenu.AddCreditsEntry("<i>Modified GuiToLuaAE</i>")
		AboutMenu.AddCreditsEntry("")
		AboutMenu.AddCreditsEntry("karl-police", { TextSize = 17 })
		AboutMenu.AddCreditsEntry("EasternBloxxer", { TextSize = 17 })
		AboutMenu.AddCreditsEntry("xs4u", { TextSize = 17 })
		AboutMenu.AddCreditsEntry("GuestDaProtogen", { TextSize = 17 })
		AboutMenu.AddCreditsEntry("DrewBokman", { TextSize = 17 })
		AboutMenu.AddCreditsEntry("<i>Added additional features, Adonis Plugin</i>")

		-- Window Add, adds things to the "Content"
		window:Add(aboutFrame)
	end

	return AboutMenu
end

return { InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main }
