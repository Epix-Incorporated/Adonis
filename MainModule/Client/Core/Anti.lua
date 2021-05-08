client = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Anti-Exploit
return function()
	local _G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, tick, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, elapsedTime, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, tick, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, elapsedTime, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local Anti, Process, UI, Variables
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Variables = client.Variables;
		Process = client.Process;
	end

	local script = script
	local service = service
	local client = client
	local Core = client.Core
	local Remote = client.Remote
	local Functions = client.Functions
	local Disconnect = client.Disconnect
	local Send = client.Remote.Send
	local Get = client.Remote.Get
	local NetworkClient = service.NetworkClient
	local Kill = client.Kill
	local Player = service.Players.LocalPlayer
	local Kick = Player.Kick
	local toget = tostring(getfenv)

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	local Detected = function(action, info, nocrash)
		if NetworkClient and action ~= "_" then
			pcall(Send, "Detected", action, info)
			wait(0.5)
			if action == "kick" then
				if not service.RunService:IsStudio() then
					if nocrash then
						Player:Kick(info); -- service.Players.LocalPlayer
					else
						Disconnect(info)
					end
				end
			elseif action == "crash" then
				Kill(info)
			end
		end
		return true
	end;

	do
		local OldEnviroment = getfenv()
		local OldSuccess, OldError = pcall(function() return game:________() end)
		Routine(function()
			while wait(5) do
				if not Detected("_", "_", true) then -- detects the current bypass
					while true do end
				end

				if not rawequal(OldSuccess, OldSuccess) or not rawequal(OldError, OldError) or rawequal(OldError, "new") or not OldError == OldError or OldError == "new" or rawequal(OldEnviroment, {1}) or OldEnviroment == {1} or not OldEnviroment == OldEnviroment then
					Detected("crash", "Tamper Protection 658947")
					wait(1)
					pcall(Disconnect, "Adonis_658947")
					pcall(Kill, "Adonis_658947")
					pcall(Kick, Player, "Adonis_658947")
				end

				-- Detects all skidded exploits which do not have newcclosure
				do
					xpcall(function() return game:________() end, function()
						for i = 1, 11 do
							if not rawequal(getfenv(i), OldEnviroment) or getfenv(i) ~= OldEnviroment then
								Detected("kick", "Methamethod tampering 5634345")
							end
						end
					end)

					local Success, Error = pcall(function() return game:________() end)

					if not Success == OldSuccess or not OldError == Error then
						Detected("kick", "Methamethod tampering 456456")
					end
				end

				-- this part you can choose whether or not you wanna use
				for _, v in pairs({"SentinelSpy", "ScriptDumper", "VehicleNoclip", "Strong Stand"}) do -- recursive findfirstchild check that yeets some stuff; --[["Sentinel",]]
					local object = Player and Player.Name ~= v and game.FindFirstChild(game, v, true)            -- ill update the list periodically
					if object then
						Detected("log", "Malicious Object?: " .. v)
					end
				end
			end
		end)
	end

	local CheckEnv = function()
		if tostring(getfenv) ~= toget or type(getfenv) ~= "function" then

		end
	end

	local Detectors = service.ReadOnly({
		Speed = function(data)
			service.StartLoop("AntiSpeed",1,function()
				--if service.CheckMethod(workspace, "GetRealPhysicsFPS") then
					if workspace:GetRealPhysicsFPS() > tonumber(data.Speed) then
						Detected('kill','Speed exploiting')
					end
				--else
				--	Detected('kick','Method change detected')
				--end
			end)
		end;

		NameId = function(data)
			local realId = data.RealID
			local realName = data.RealName

			service.StartLoop("NameIDCheck",10,function()
				if service.Player.Name ~= realName then
					Detected('log','Local username does not match server username')
				end

				if service.Player.userId ~= realId then
					Detected('log','Local userID does not match server userID')
				end
			end)
		end;

		AntiGui = function(data) --// Future
			service.Player.DescendantAdded:connect(function(c)
				if c:IsA("GuiMain") or c:IsA("PlayerGui") and rawequal(c.Parent, service.PlayerGui) and not UI.Get(c) then
					c:Destroy()
					Detected("log","Unknown GUI detected and destroyed")
				end
			end)
		end;

		AntiTools = function(data)
			if service.Player:WaitForChild("Backpack", 120) then
				local btools = data.BTools --Remote.Get("Setting","AntiBuildingTools")
				local tools = data.AntiTools --Remote.Get("Setting","AntiTools")
				local allowed = data.AllowedList --Remote.Get("Setting","AllowedToolsList")
				local function check(t)
					if (t:IsA("Tool") or t:IsA("HopperBin")) and not t:FindFirstChild(Variables.CodeName) then
						if client.AntiBuildingTools and t:IsA("HopperBin") and (rawequal(t.BinType, Enum.BinType.Grab) or rawequal(t.BinType, Enum.BinType.Clone) or rawequal(t.BinType, Enum.BinType.Hammer) or rawequal(t.BinType, Enum.BinType.GameTool)) then
							t.Active = false
							t:Destroy()
							Detected("log","Building tools detected")
						end
						if tools then
							local good = false
							for i,v in pairs(client.AllowedToolsList) do
								if t.Name==v then
									good = true
								end
							end
							if not good then
								t:Destroy()
								Detected("log","Tool detected")
							end
						end
					end
				end

				for i,t in pairs(service.Player.Backpack:children()) do
					check(t)
				end

				service.Player.Backpack.ChildAdded:connect(check)
			end
		end;

		--[[
		CheatEngineFinder = function(data)
			for i,v in pairs(service.LogService:GetLogHistory()) do
				for k,m in pairs(v) do
					if type(m)=='string' and m:lower():find('program files') and m:lower():find('cheat engine') and m:lower():find('failed to resolve texture format') then
						Detected('kick','Cheat Engine installation detected.')
					end
				end
			end
		end;
		--]]

		HumanoidState = function(data)
			wait(1)
			local humanoid = service.Player.Character:WaitForChild("Humanoid")
			local event
			local doing = true
			event = humanoid.StateChanged:connect(function(old,new)
				if not doing then event:disconnect() end
				if rawequal(new, Enum.HumanoidStateType.StrafingNoPhysics) and doing then
					doing = false
					Detected("kill","Noclipping")
					event:disconnect()
				end
			end)

			while humanoid and humanoid.Parent and humanoid.Parent.Parent and doing and wait(0.1) do
				if rawequal(humanoid:GetState(), Enum.HumanoidStateType.StrafingNoPhysics) and doing then
					doing = false
					Detected("kill","Noclipping")
				end
			end
		end;

		Paranoid = function(data)
			wait(1)
			local char = service.Player.Character
			local torso = char:WaitForChild("Head")
			local humPart = char:WaitForChild("HumanoidRootPart")
			local hum = char:WaitForChild("Humanoid")
			while torso and humPart and rawequal(torso.Parent, char) and rawequal(humPart.Parent, char) and char.Parent ~= nil and hum.Health>0 and hum and hum.Parent and wait(1) do
				if (humPart.Position-torso.Position).magnitude>10 and hum and hum.Health>0 then
					Detected("kill","HumanoidRootPart too far from Torso (Paranoid?)")
				end
			end
		end;

		MainDetection = function(data)
			local game = service.DataModel
			local isStudio = select(2, pcall(service.RunService.IsStudio, service.RunService))
			local findService = service.DataModel.FindService
			local lastUpdate = tick()
			local doingCrash = false
			local goodCores = {}
			local gettingGood = false
			local gettingMenu = false
			local menuOpened = false
			local gotGoodTime = tick()
			local coreNums = {}
			local coreClears = service.ReadOnly({
				FriendStatus = true;
				ImageButton = false;
				ButtonHoverText = true;
				HoverMid = true;
				HoverLeft = true;
				HoverRight = true;
				ButtonHoverTextLabel = true;
				Icon = true;
				ImageLabel = true;
				NameLabel = true;
				Players = true;
				ColumnValue = true;
				ColumnName = true;
				Frame = false;
				StatText = false;
			})

			local lookFor = {
				--'stigma';
				--'sevenscript';
				--"a".."ssh".."ax";
				--"a".."ssh".."urt";
				--'elysian';
				'current identity is 0';
				'gui made by kujo';
				"tetanus reloaded hooked";
				--"brackhub";
				"newcclosure", -- // Kicks all non chad exploits which do not support newcclosure like jjsploit
			}

			local files = {
				["C:\RC7\rc7.dat"] = true;
			}

			local function check(Message)
				for i,v in pairs(lookFor) do
					if string.find(string.lower(Message),string.lower(v)) and not string.find(string.lower(Message),"failed to load") then
						return true
					end
				end
			end

			local function findLog(msg)
				for i,v in pairs(service.LogService:GetLogHistory()) do
					if string.find(string.lower(v.message),string.lower(msg)) then
						return true
					end
				end
			end

			local function findFiles()
				local image = service.New("Decal",service.Workspace)
				for i,v in next,files do
					image.Texture = i;
					wait(0.5)
					if findLog(i) then
					else
						--// Detected
						warn("RC7 DETECTION WORKED?")
					end
				end
			end

			local function isGood(item)
				for i,v in next,goodCores do
					if rawequal(item, v) then
						return true
					end
				end
			end

			local function checkServ(c) if not pcall(function()
				if not isStudio and (findService("ServerStorage", game) or findService("ServerScriptService", game)) then
					Detected("crash","Disallowed Services Detected")
				end
			end) then Detected("kick","Finding Error") end end

			local function chkObj(item)
				local coreNav = service.GuiService.CoreGuiNavigationEnabled
				service.GuiService.CoreGuiNavigationEnabled = false
				if Anti.ObjRLocked(item) and not service.GuiService:IsTenFootInterface() then
					local cont = true
					local ran,err = pcall(function()
						local checks = {
							service.Chat;
							service.Teams;
							service.Lighting;
							service.StarterGui;
							service.TestService;
							service.StarterPack;
							service.StarterPlayer;
							service.JointsService;
							service.InsertService;
							service.ReplicatedStorage;
							service.ReplicatedFirst;
							service.SoundService;
							service.HttpService;
							service.Workspace;
							service.Players;
						}
						for i,v in next,checks do
							if item:IsDescendantOf(v) then cont = false end
						end
					end)

					if cont then
						local cont = false
						local class = Anti.GetClassName(item)
						local name = tostring(item)
						local checks = {
							"Script";
							"LocalScript";
							"CoreScript";
							"ScreenGui";
							"Frame";
							"TextLabel";
							"TextButton";
							"ImageLabel";
							"TextBox";
							"ImageButton";
							"GuiMain";
						}

						if class then
							if class == "LocalScript" then
								return true
							end

							for i,v in next,checks do
								if rawequal(class, v) then
									cont = true
								end
							end

							--[[
								Menu:
								FriendStatus - TextButton;
								EVERY SINGLE MENU GUI ON CLICK FFS

								Reset:
								ImageButton - ImageButton
								ButtonHoverText - Frame
								HoverMid - ImageLabel
								HoverLeft - ImageLabel
								HoverRight - ImageLabel
								ButtonHoverTextLabel - TextLabel

								PlayerList:
								Icon - ImageLabel;
								ImageLabel - ImageLabel;
								NameLabel - TextLabel;
								Players - Frame;
								ColumnValue - TextLabel;
								ColumnName - TextLabel;
								Frame - Frame;
								StatText - TextLabel;
							]]--
						end

						if not true and cont and menuOpened == false then
							local players = 0
							local leaderstats = {}
							local totStats = 0
							local teams = 0
							local total = 0

							for i,v in pairs(service.Players:GetChildren()) do
								if v:IsA("Player") then
									players = players+1
									local stats = v:FindFirstChild("leaderstats")
									if stats then
										for k,m in pairs(stats:GetChildren()) do
											if not leaderstats[m.Name] then
												leaderstats[m.Name] = 0
											end
											leaderstats[m.Name] = leaderstats[m.Name]+1
										end
									end
								end
							end

							for i,v in pairs(leaderstats) do
								totStats = totStats+1
							end

							for i,v in pairs(service.Teams:GetChildren()) do
								if v:IsA("Team") then
									teams = teams+1
								end
							end

							total = (teams+players+((teams+players)*totStats)+totStats)-1
							if not coreNums[name] then coreNums[name] = 0 end
							coreNums[name] = coreNums[name]+1

							print(name.." : "..class.." : "..coreNums[name])
							print(total)
							--[[
							if name == "FriendStatus" and coreNums.FriendStatus > players then
								print("FRIEND STATUS EXCEEDED PLAYER COUNT")
							elseif name == "Icon" and coreNums.Icon > players then
								print("ICON EXCEEDED PLAYER COUNT")
							elseif name == "ColumnValue" and coreNums.ColoumnValue > totPlayerItems then
								print("COLUMN VALUE EXCEEDS PLAYER ITEMS COUNT")
							elseif name == "ColumnName" and coreNums.ColumnName > totPlayerItems then
								print("COLUMN NAME EXCEEDS PLAYER ITEMS COUNT")
							elseif name == "NameLabel" and coreNums.NameLabel > totPlayerItems then
								print("NAME LABEL EXCEEDS PLAYER ITEMS COUNT")
							end--]]

							if menuOpen or (gettingGood or (gettingMenu and (name == "FriendStatus" and class == "TextButton"))) then
								table.insert(goodCores,item)
							elseif not isGood(item) then
								--print("-------------------------------")
								--print("FOUND NAME: "..tostring(item))
								--print("FOUND CLASS: "..tostring(class))
								--print("FOUND TYPE: "..tostring(type(item)))
								--print("FOUND TYPEOF: "..tostring(type(item)))
								--print("-------------------------------")

								local testName = tostring(math.random()..math.random())
								local ye,err = pcall(function()
									service.GuiService:AddSelectionParent(testName, item) -- Christbru figured out the detection method
									service.GuiService:RemoveSelectionGroup(testName)
								end)

								--print(ye,err)

								if err and string.find(err,testName) and string.find(err,"GuiService:") then return true end
								wait(0.5)
								for i,v in next,service.LogService:GetLogHistory() do
									if string.find(v.message,testName) and string.find(v.message,"GuiService:") then
										return true
									end
								end--]]
							end
						end
					end
				end
				service.GuiService.CoreGuiNavigationEnabled = coreNav
			end

			local function checkTool(t)
				if (t:IsA("Tool") or t:IsA("HopperBin")) and not t:FindFirstChild(Variables.CodeName) and service.Player:FindFirstChild("Backpack") and t:IsDescendantOf(service.Player.Backpack) then
					if t:IsA("HopperBin") and (rawequal(t.BinType, Enum.BinType.Grab) or rawequal(t.BinType, Enum.BinType.Clone) or rawequal(t.BinType, Enum.BinType.Hammer) or rawequal(t.BinType, Enum.BinType.GameTool)) then
						Detected("log","Building tools detected; "..tostring(t.BinType))
					end
				end
			end

			checkServ()

			service.DataModel.ChildAdded:connect(checkServ)
			--service.Player.DescendantAdded:connect(checkTool)

			service.Players.PlayerAdded:connect(function(p)
				gotGoodTime = tick()
			end)

			service.Events.CharacterRemoving:connect(function()
				for i,v in next,coreNums do
					if coreClears[i] then
						coreNums[i] = 0
					end
				end
				--[[
				gettingGood = true
				wait()
				gettingGood = false--]]
			end)

			service.GuiService.MenuClosed:connect(function()
				menuOpen = false
			end)

			service.GuiService.MenuOpened:connect(function()
				menuOpen = true
			end)

			service.ScriptContext.ChildAdded:connect(function(child)
				if Anti.GetClassName(child) == "LocalScript" then
					Detected("kick","Localscript Detected; "..tostring(child))
				end
			end)

			service.ReplicatedFirst.ChildAdded:connect(function(child)
				if Anti.GetClassName(child) == "LocalScript" then
					Detected("kick","Localscript Detected; "..tostring(child))
				end
			end)

			service.LogService.MessageOut:connect(function(Message, Type)
				if check(Message) then
					Detected('crash','Exploit detected; '..Message)
				end
			end)

			service.Selection.SelectionChanged:connect(function()
				Detected('kick','Selection changed')
			end)

			service.ScriptContext.Error:Connect(function(Message, Trace, Script)
				local Message, Trace, Script = tostring(Message), tostring(Trace), tostring(Script)
				if Script and Script=='tpircsnaisyle'then
					Detected("kick","Elysian")
				elseif check(Message) or check(Trace) or check(Script) then
					Detected('crash','Exploit detected; '..Message.." "..Trace.." "..Script)
				elseif (not Script or ((not Trace or Trace == ""))) then
					local tab = service.LogService:GetLogHistory()
					local continue = false
					if Script then
						for i,v in next,tab do
							if v.message == Message and tab[i+1] and tab[i+1].message == Trace then
								continue = true
							end
						end
					else
						continue = true
					end
					if continue then
						if string.match(Trace,"CoreGui") or string.match(Trace,"PlayerScripts") or string.match(Trace,"Animation_Scripts") or string.match(Trace,"^(%S*)%.(%S*)") then
							return
						else
							Detected("log","Traceless/Scriptless error")
						end
					end
				end
			end)

			service.NetworkClient.ChildRemoved:connect(function(child)
				wait(30)
				client.Kill("Client disconnected from server")
			end)

			service.RunService.Stepped:connect(function()
				lastUpdate = tick()
			end)

			--[[game.DescendantAdded:connect(function(c)
				if chkObj(c) and type(c)=="userdata" and not doingCrash then
					doingCrash = true
					--print("OK WE DETECTED THINGS")
					Detected("crash","New CoreGui Object; "..tostring(c))
				end
			end)--]]

			if service.Player:WaitForChild("Backpack", 120) then
				service.Player.Backpack.ChildAdded:connect(checkTool)
			end

			--// Detection Loop
			service.StartLoop("Detection",10,function()
				--// Prevent event stopping
				if tick()-lastUpdate > 60 then
					Detected("crash","Events stopped")
				end

				--// Check player parent
				if service.Player.Parent ~= service.Players then
					Detected("crash","Parent not players")
				end

				--// Stuff
				local ran,err = pcall(function() service.ScriptContext.Name = "ScriptContext" end)
				if not ran then
					Detected("log","ScriptContext error?")
				end

				--// Check Log History
				for i,v in next,service.LogService:GetLogHistory() do
					if check(v.message) then
						Detected('crash','Exploit detected')
					end
				end

				--// Check Loadstring
				local ran,err = pcall(function()
					local func,err = loadstring("print('LOADSTRING TEST')")
				end)
				if ran then
					Detected('crash','Exploit detected; Loadstring usable')
				end

				--// Check Context Level
				local ran,err = pcall(function()
					local test = Instance.new("StringValue")
					test.RobloxLocked = true
				end)
				if ran then
					Detected('crash','RobloxLocked usable')
				end
			end)
		end;
	}, false, true)

	local Launch = function(mode,data)
		if Anti.Detectors[mode] and service.NetworkClient then
			Anti.Detectors[mode](data)
		end
	end;

	Anti = service.ReadOnly({
		LastChanges = {
			Lighting = {};
		};

		Init = Init;
		Launch = Launch;
		Detected = Detected;
		Detectors = Detectors;

		GetClassName = function(obj)
			local testName = tostring(math.random()..math.random())
			local ran,err = pcall(function()
				local test = obj[testName]
			end)
			if err then
				local class = string.match(err,testName.." is not a valid member of (.*)")
				if class then
					return class
				end
			end
		end;

		RLocked = function(obj)
			return not pcall(function() return obj.GetFullName(obj) end)
			--[[local ran,err = pcall(function() service.New("StringValue", obj):Destroy() end)
			if ran then
				return false
			else
				return true
			end--]]
		end;

		ObjRLocked = function(obj)
			return not pcall(function() return obj.GetFullName(obj) end)
			--[[local ran,err = pcall(function() obj.Parent = obj.Parent end)
			if ran then
				return false
			else
				return true
			end--]]
		end;

		CoreRLocked = function(obj)
			local testName = tostring(math.random()..math.random())
			local ye,err = pcall(function()
				game:GetService("GuiService"):AddSelectionParent(testName, obj)
				game:GetService("GuiService"):RemoveSelectionGroup(testName)
			end)
			if err and string.find(err, testName) and string.find(err, "GuiService:") then
				return true
			else
				wait(0.5)
				for i,v in next,service.LogService:GetLogHistory() do
					if string.find(v.message,testName) and string.find(v.message,"GuiService:") then
						return true
					end
				end
			end
		end;
	}, false, true)

	client.Anti = Anti

	do
		local meta = service.MetaFunc
		local track = meta(service.TrackTask)
		local loop = meta(service.StartLoop)
		local opcall = meta(pcall)
		local oWait = meta(wait)
		local resume = meta(coroutine.resume)
		local create = meta(coroutine.create)
		local tick = meta(tick)
		local loopAlive = tick()
		local otostring = meta(tostring)

		track("Thread: TableCheck", meta(function()
			while oWait(1) do
				loopAlive = tick()
				local ran, core, remote, functions, anti, send, get, detected, disconnect, kill = coroutine.resume(coroutine.create(function() return client.Core, client.Remote, client.Functions, client.Anti, client.Remote.Send, client.Remote.Get, client.Anti.Detected, client.Disconnect, client.Kill end))
				if not ran or core ~= Core or remote ~= Remote or functions ~= Functions or anti ~= Anti or send ~= Send or get ~= Get or detected ~= Detected or disconnect ~= Disconnect or kill ~= Kill then
					opcall(Detected, "crash", "Tamper Protection 10042")
					oWait(1)
					opcall(Disconnect, "Adonis_10042")
					opcall(Kill, "Adonis_10042")
					opcall(Kick, Player, "Adonis_10042")
					--pcall(function() while true do end end)
				end
			end
		end))
		--[[
		loop("Thread: CheckLoop", "Stepped", meta(function()
			local ran,ret = resume(create(function() return tick()-loopAlive end))
			if not ran or not ret or ret > 5 then
				opcall(Detected, "crash", "Tamper Protection 10043")
				oWait(1)
				opcall(Disconnect, "Adonis_10043")
				opcall(Kill, "Adonis_10043")
				opcall(Kick, Player, "Adonis_10043")
			end
		end), true)--]]
	end
end
