client = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Processing
return function()
	local _G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, elapsedTime, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, elapsedTime, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local UIFolder = client.UIFolder
	local script = script
	local service = service
	local client = client
	local Anti, Core, Functions, Process, Remote, UI, Variables, Deps
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;
		Deps = client.Deps;

		UI.Init = nil;
	end

	local function RunLast()
		--[[client = service.ReadOnly(client, {
				[client.Variables] = true;
				[client.Handlers] = true;
				G_API = true;
				G_Access = true;
				G_Access_Key = true;
				G_Access_Perms = true;
				Allowed_API_Calls = true;
				HelpButtonImage = true;
				Finish_Loading = true;
				RemoteEvent = true;
				ScriptCache = true;
				Returns = true;
				PendingReturns = true;
				EncodeCache = true;
				DecodeCache = true;
				Received = true;
				Sent = true;
				Service = true;
				Holder = true;
				GUIs = true;
				LastUpdate = true;
				RateLimits = true;

				Init = true;
				RunLast = true;
				RunAfterInit = true;
				RunAfterLoaded = true;
				RunAfterPlugins = true;
			}, true)--]]
			UI.DefaultTheme = Remote.Get("Setting","DefaultTheme");
			UI.RunLast = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.UI = {
		Init = Init;
		RunLast = RunLast;
		GetHolder = function()
			if UI.Holder and UI.Holder.Parent == service.PlayerGui then
				return UI.Holder
			else
				pcall(function()if UI.Holder then UI.Holder:Destroy()end end)
				local new = service.New("ScreenGui");
				new.Name = Functions.GetRandom()
				new.Parent = service.PlayerGui
				UI.Holder = new
				return UI.Holder
			end
		end;

		Prepare = function(gui)
			if true then return gui end	--// Disabled

			local gTable = UI.Get(gui,false,true)
			if gui:IsA("ScreenGui") or gui:IsA("GuiMain") then
				local new = Instance.new("TextLabel")
				new.BackgroundTransparency = 1
				new.Size = UDim2.new(1,0,1,0)
				new.Name = gui.Name
				new.Active = true
				new.Text = ""

				for ind,child in next,gui:GetChildren()do
					child.Parent = new
				end

				if gTable then
					gTable:Register(new)
				end

				gui:Destroy()

				return new
			else
				return gui
			end
		end;

		LoadModule = function(module, data, env)
			local ran,func = pcall(require, module)
			local newEnv = GetEnv(env)
			local data = data or {}

			newEnv.script = module
			newEnv.client = service.CloneTable(client)
			newEnv.service = service.CloneTable(service)
			newEnv.service.Threads = service.CloneTable(service.Threads)

			for i,v in next,newEnv.client do
				if type(v) == "table" and i ~= "Variables" and i ~= "Handlers" then
					newEnv.client[i] = service.CloneTable(v)
				end
			end

			if ran then
				local rets = {service.TrackTask("UI: ".. module:GetFullName(), setfenv(func,newEnv), data)}
				local ran = rets[1]
				if ran then
					return unpack(rets,2)
				else
					warn("Error while running module "..module.Name,tostring(rets[2]))
					client.LogError("Error loading "..tostring(module).." - "..tostring(rets[2]))
				end
			else
				warn("Error while loading module "..module.Name,tostring(func))
			end
		end;

		GetNew = function(theme, name)
			local foundConfigs = {}
			local endConfig = {}
			local endConfValues = {}
			local confFolder = Instance.new("Folder")
			local func
			local debounce = false
			function func(theme, name, depth)
				local depth = (depth or 11) - 1
				local folder = UIFolder:FindFirstChild(theme) or UIFolder.Default
				if folder then
					local baseValue = folder:FindFirstChild("Base_Theme")
					local baseTheme = baseValue and baseValue.Value
					local foundGUI = folder:FindFirstChild(name) --local foundGUI = (baseValue and folder:FindFirstChild(name)) or UIFolder.Default:FindFirstChild(name)

					if foundGUI then
						local config = foundGUI:FindFirstChild("Config")
						table.insert(foundConfigs, {
							Theme = theme;
							Folder = folder;
							Name = name;
							Found = foundGUI;
							Config = config;
							isModule = foundGUI:IsA("ModuleScript");
						})

						if config then
							baseValue = config:FindFirstChild("BaseTheme") or baseValue
							baseTheme = baseValue and baseValue.Value
						end
					end 
					if baseTheme and depth > 0 then
						if UI.DefaultTheme and baseTheme == "Default" and theme ~= UI.DefaultTheme and not debounce then
							func(UI.DefaultTheme, name, depth)
						else
							debounce = true
							func(baseTheme, name, depth)
						end
					end
				end
			end

			--// Find GUI and all default versions under it
			func(theme, name)
			confFolder.Name = "Config"
			
			--// Create the final config for the found GUI.

			if #foundConfigs > 0 then
				--// Combine all configs found in order  to build full config (in order of closest from target gui to furthest)
				for i,v in next,foundConfigs do
					if v.Config then
						for k,m in next,v.Config:GetChildren() do
							if not endConfig[m.Name] then
								endConfig[m.Name] = m
							end
						end
					end
				end

				--// Load all config values into the new Config folder
				for i,v in next,endConfig do
					v:Clone().Parent = confFolder;
				end

				--// Find next module based theme GUI if code not found or first in sequence is module (in theme)
				if foundConfigs[1].isModule then
					return foundConfigs[1].Found, foundConfigs[1].Folder, confFolder
				elseif not endConfig.Code then
					warn("Window config missing code.lua. Are your Base_Themes correct? client.UI.GetNew line 236")
				end

				--// Get rid of an old Config folder and throw the new combination Config folder in
				local new = foundConfigs[1].Found:Clone()
				local oldFolder = new:FindFirstChild'Config'

				if oldFolder then oldFolder:Destroy() end

				confFolder.Parent = new
				return new, foundConfigs[1].Folder, confFolder
			end
		end;

		Make = function(name, data, themeData)
			local data = data or {}
			local defaults = {Desktop = "Default"; Mobile = "Mobilius"}
			local themeData = themeData or Variables.LastServerTheme or defaults
			local theme = Variables.CustomTheme or (service.IsMobile() and themeData.Mobile) or themeData.Desktop
			local folder = UIFolder:FindFirstChild(theme) or UIFolder.Default
			local newGui, folder2, foundConf = UI.GetNew(theme, name)

			if newGui then
				local isModule = newGui:IsA("ModuleScript")
				local conf = newGui:FindFirstChild("Config")
				local mod = conf and conf:FindFirstChild("Modifier")

				if isModule then
					return UI.LoadModule(newGui, data, {
						script = newGui;
					})
				elseif conf and foundConf and foundConf ~= true then
					local code = foundConf.Code
					local mult = foundConf.AllowMultiple
					local keep = foundConf.CanKeepAlive

					local allowMult = mult and mult.Value or true
					local found, num = UI.Get(name)

					if not found or ((num and num>0) and allowMult) then
						local gTable,gIndex = UI.Register(newGui)
						local newEnv = {}

						if folder:IsA("ModuleScript") then
							newEnv.script = folder
							newEnv.gTable = gTable
							local ran,func = pcall(require, folder)
							local newEnv = GetEnv(newEnv)
							local rets = {pcall(setfenv(func,newEnv),newGui, gTable, data)}
							local ran = rets[1]
							local ret = rets[2]

							if ret ~= nil then
								if type(ret) == "userdata" and Anti.GetClassName(ret) == "ScreenGui" then
									code = (ret:FindFirstChild("Config") and ret.Config:FindFirstChild("Code")) or code
								else
									return ret
								end
							end
						end

						newGui.Parent = Variables.GUIHolder
						newGui.Name = Functions.GetRandom()

						data.gIndex = gIndex
						data.gTable = gTable

						code.Parent = conf
						code.Name = name

						if mod then
							UI.LoadModule(mod, data, {
								script = mod;
								gTable = gTable;
								Data = data;
								GUI = newGui;
							})
						end

						return UI.LoadModule(code, data, {
							script = code;
							gTable = gTable;
							Data = data;
							GUI = newGui;
						})
					end
				end
			else
				print("GUI "..tostring(name).." not found")
			end
		end;

		Get = function(obj,ignore,returnOne)
			local found = {}
			local num = 0
			if obj then
				for ind,g in next,client.GUIs do
					if g.Name ~= ignore and g.Object ~= ignore and g ~= ignore then
						if type(obj) == "string" then
							if g.Name == obj then
								found[ind] = g
								num = num+1
								if returnOne then return g end
							end
						elseif type(obj) == "userdata" then
							if service.RawEqual(g.Object, obj) then
								found[ind] = g
								num = num+1
								if returnOne then return g end
							end
						elseif type(obj) == "boolean" and obj == true then
							found[ind] = g
							num = num+1
							if returnOne then return g end
						end
					end
				end
			end
			if num<1 then
				return false
			else
				return found,num
			end
		end;

		Remove = function(name, ignore)
			local gui = UI.Get(name, ignore)
			if gui then
				for i,v in next,gui do
					v.Destroy()
				end
			end
		end;

		Register = function(gui, data)
			local gIndex = Functions.GetRandom()
			local gTable;gTable = {
				Object = gui,
				Config = gui:FindFirstChild'Config';
				Name = gui.Name,
				Events = {},
				Class = gui.ClassName,
				Index = gIndex,
				Active = true,
				Ready = function()
					if gTable.Config then gTable.Config.Parent = nil end
					local ran,err = pcall(function()
						local obj = gTable.Object;
						if gTable.Class == "ScreenGui" or gTable.Class == "GuiMain" then
							if obj.DisplayOrder == 0 then
								obj.DisplayOrder = 90000
							end

							obj.Enabled = true
							obj.Parent = service.PlayerGui
						else
							obj.Parent = UI.GetHolder()
						end
					end);

					if ran then
						gTable.Active = true
					else
						warn("Something happened while trying to set the parent of "..tostring(gTable.Name))
						warn(tostring(err))
						gTable:Destroy()
					end
				end,

				BindEvent = function(event, func)
					local signal = event:Connect(func)
					local origDisc = signal.Disconnect
					local Events = gTable.Events
					local disc = function()
						origDisc(signal)
						for i,v in next, Events do
							if v.Signal == signal then
								table.remove(Events, i)
							end
						end
					end

					table.insert(Events, {
						Signal = signal;
						Remove = disc
					})

					return {
						Disconnect = disc;
						disconnect = disc;
						wait = service.CheckProperty(signal, "wait") and signal.wait
					}, signal
				end,

				ClearEvents = function()
					for i,v in next,gTable.Events do
						v:Remove()
					end
				end,

				Destroy = function()
					pcall(function()
						if gTable.CustomDestroy then
							gTable.CustomDestroy()
						else
							service.UnWrap(gTable.Object):Destroy()
						end
					end)
					gTable.Destroyed = true
					gTable.Active = false
					client.GUIs[gIndex] = nil
					gTable.ClearEvents()
				end,

				UnRegister = function()
					client.GUIs[gIndex] = nil
					if gTable.AncestryEvent then
						gTable.AncestryEvent:Disconnect()
					end
				end,

				Register = function(tab,new)
					if not new then new = tab end

					new:SetSpecial("Destroy", gTable.Destroy)
					gTable.Object = service.Wrap(new)
					gTable.Class = new.ClassName

					if gTable.AncestryEvent then
						gTable.AncestryEvent:Disconnect()
					end

					gTable.AncestryEvent = new.AncestryChanged:Connect(function(c, parent)
						if client.GUIs[gIndex] then
							if rawequal(c, gTable.Object) and gTable.Class == "TextLabel" and parent == service.PlayerGui then
								wait()
								gTable.Object.Parent = UI.GetHolder()
							elseif rawequal(c, gTable.Object) and parent == nil and not gTable.KeepAlive then
								gTable:Destroy()
							elseif rawequal(c, gTable.Object) and parent ~= nil then
								gTable.Active = true
								client.GUIs[gIndex] = gTable
							end
						end
					end)
					client.GUIs[gIndex] = gTable
				end
			}

			if data then
				for i,v in next,data do
					gTable[i] = v
				end
			end

			gui.Name = Functions.GetRandom()
			gTable:Register(gui)

			return gTable,gIndex
		end
	}

	client.UI.RegisterGui 	= client.UI.Register
	client.UI.GetGui 		= client.UI.Get
	client.UI.PrepareGui 	= client.UI.Prepare
	client.UI.MakeGui 		= client.UI.Make
end
