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

	local Anti, Process, UI, Variables
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

	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Variables = client.Variables;
		Process = client.Process;

		Anti.Init = nil;
	end

	local function RunAfterLoaded()
		service.Player.Changed:Connect(function()
			if service.Player.Parent ~= service.Players then
				wait(5)
				Anti.Detected("kick", "Parent not players", true)
			elseif Anti.RLocked(service.Player) then
				Anti.Detected("kick", "Player is Roblox Locked")
			end
		end)

		Anti.RunAfterLoaded = nil;
	end

	local function RunLast()
		Anti.RunLast = nil;
	end

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

	local idleTamper
	do
		local hasActivated = false
		idleTamper = function(message)
			if hasActivated then
				return
			end
			hasActivated = true
			Detected("crash", "Tamper Protection 790438; "..tostring(message).."; "..debug.traceback())
			wait(1)
			pcall(Disconnect, "Adonis_790438")
			pcall(Kill, "Adonis_790438")
			pcall(Kick, Player, "Adonis_790438")
		end
	end

	coroutine.wrap(function()
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end

		if not service.UnWrap(Player).Character and service.UnWrap(game):GetService("Players").CharacterAutoLoads then
			service.UnWrap(Player).CharacterAdded:Wait()
		end

		local RunService = service.RunService
		if
			RunService:IsStudio() == true and
			RunService:IsClient() == true and
			RunService:IsRunning() == true and
			RunService:IsServer() == false
		then
			return
		end

		while true do
			local connection
			local idledEvent = service.UnWrap(Player).Idled
			connection = idledEvent:Connect(function(time)
				if type(time) ~= "number" or not (time > 0) then
					idleTamper("Invalid time data")
				elseif time > 30 * 60 then
					Detected("kick", "Anti-idle detected")
				end
			end)

			if
				type(connection) ~= "userdata" or
				not rawequal(typeof(connection), "RBXScriptConnection") or
				connection.Connected ~= true or
				not rawequal(type(connection.Disconnect), "function") or
				not rawequal(typeof(idledEvent), "RBXScriptSignal") or
				not rawequal(type(idledEvent.Connect), "function") or
				not rawequal(type(idledEvent.Wait), "function")
			then
				idleTamper("Userdata disrepencies detected")
			end

			task.wait(200)
			connection:Disconnect()
		end
	end)()

	do
		local callStacks = {
			indexInstance1 = {},
			indexInstance2 = {},
			namecallInstance = {},
			indexEnum = {},
			eqEnum = {},
			--[[indexString = {},
			namecallString = {},
			eqString = {},]]
		}
		local errorMessages = {}
		local rawGame = service.UnWrap(game)

		local function checkStack(method)
			local firstTime = #callStacks[method] <= 0

			for i = 3, 4 do
				local func = debug.info(i, "f")

				if firstTime then
					callStacks[method][i] = func
				elseif callStacks[method][i] ~= func then
					return true
				end
			end

			return false
		end

		local detectors = {
			indexInstance = {"kick", function()
				local callstackInvalid = false

				local success, err = xpcall(function()
					local c = game.____________
				end, function()
					if callstackInvalid or checkStack("indexInstance1") then
						callstackInvalid = true
					end
				end)
				local success2, err2 = xpcall(function()
					local c = game[nil]
				end, function()
					if callstackInvalid or checkStack("indexInstance2") then
						callstackInvalid = true
					end
				end)

				if callstackInvalid or success or success2 then
					return true
				elseif not errorMessages["indexInstance"] then
					errorMessages["indexInstance"] = {err, err2}
				end

				return errorMessages["indexInstance"][1] ~= err or errorMessages["indexInstance"][2] ~= err2
			end},
			namecallInstance = {"kick", function()
				local callstackInvalid = false

				local success, err = xpcall(function()
					local c = game:____________()
				end, function()
					if callstackInvalid or checkStack("namecallInstance") then
						callstackInvalid = true
					end
				end)

				if callstackInvalid or success then
					return true
				elseif not errorMessages["namecallInstance"] then
					errorMessages["namecallInstance"] = err
				end

				return errorMessages["namecallInstance"] ~= err
			end},
			indexEnum = {"kick", function()
				local callstackInvalid = false

				local success, err = xpcall(function()
					local c = Enum.HumanoidStateType.____________
				end, function()
					if callstackInvalid or checkStack("indexEnum1") then
						callstackInvalid = true
					end
				end)
				local success2, err2 = xpcall(function()
					local c = Enum.HumanoidStateType[nil]
				end, function()
					if callstackInvalid or checkStack("indexEnum2") then
						callstackInvalid = true
					end
				end)

				if callstackInvalid or success or success2 then
					return true
				elseif not errorMessages["indexEnum"] then
					errorMessages["indexEnum"] = {err, err2}
				end

				return errorMessages["indexEnum"][1] ~= err or errorMessages["indexEnum"][2] ~= err2
			end},
			eqEnum = {"kick", function()
				return not (Enum.HumanoidStateType.Running == Enum.HumanoidStateType.Running)
			end},
		}

		Routine(function()
			while wait(5) do
				if not Detected("_", "_", true) then -- detects the current bypass
					while true do end
				end

				for method, detector in pairs(detectors) do
					local action, callback = detector[1],  detector[2]

					local success, value = pcall(callback)
					if not success or value ~= false and value ~= true then
						Detected("crash", "Tamper Protection 906287")
						wait(1)
						pcall(Disconnect, "Adonis_906287")
						pcall(Kill, "Adonis_906287")
						pcall(Kick, Player, "Adonis_906287")
					elseif value then
						Detected(action, method.." detector detected")
					end
				end

				local hasCompleted = false
				coroutine.wrap(function()
					local LocalPlayer = service.UnWrap(Player)
					local success, err = pcall(LocalPlayer.Kick, service.UnWrap(workspace), "If this appears, you have a glitch. Method 1")
					local success2, err2 = pcall(function()
						workspace:Kick("If this appears, you have a glitch. Method 1")
					end)

					if
						success or
						not string.match(err, "Expected ':' not '.' calling member function Kick") or
						success2 or
						not string.match(err2, "Kick is not a valid member of Workspace \"Workspace\"")
					then
						Detected("kick", "Anti kick found! Method 1")
					end

					if #service.Players:GetPlayers() > 1 then
						for _, v in ipairs(service.Players:GetPlayers()) do
							local otherPlayer = service.UnWrap(v)

							if otherPlayer and otherPlayer.Parent and otherPlayer ~= LocalPlayer then
								local success, err = pcall(LocalPlayer.Kick, otherPlayer, "If this appears, you have a glitch. Method 2")
								local success2, err2 = pcall(function()
									otherPlayer:Kick("If this appears, you have a glitch. Method 2")
								end)

								if
									success or
									err ~= "Cannot kick a non-local Player from a LocalScript" or
									success2 or
									err2 ~= "Cannot kick a non-local Player from a LocalScript"
								then
									Detected("kick", "Anti kick found! Method 2")
								end
							end
						end
					end
					hasCompleted = true
				end)()

				coroutine.wrap(function()
					task.wait(4)
					if not hasCompleted then
						Detected("kick", "Anti kick found! Method 3")
					end
					local success, err = pcall(service.UnWrap(workspace).GetRealPhysicsFPS, rawGame)
					if success or not string.match(err, "Expected ':' not '.' calling member function GetRealPhysicsFPS") then
						Detected("kick", "Anti FPS detection found!")
					end
				end)()

				-- this part you can choose whether or not you wanna use
				for _, v in pairs({"SentinelSpy", "ScriptDumper", "VehicleNoclip", "Strong Stand"}) do -- recursive findfirstchild check that yeets some stuff; --[["Sentinel",]]
					local object = Player and Player.Name ~= v and rawGame.FindFirstChild(rawGame, v, true)            -- ill update the list periodically
					if object then
						Detected("log", "Malicious Object?: " .. v)
					end
				end
			end
		end)
	end

	local Detectors = service.ReadOnly({
		Speed = function(data)
			service.StartLoop("AntiSpeed", 1, function()
				if workspace:GetRealPhysicsFPS() > tonumber(data.Speed) then
					Detected("kill", "Speed exploiting")
				end
			end)
		end;

		AntiGui = function() --// Future
			service.Player.DescendantAdded:Connect(function(c)
				if c:IsA("GuiMain") or c:IsA("PlayerGui") and rawequal(c.Parent, service.PlayerGui) and not UI.Get(c) then
					local d = c.Name
					c:Destroy()
					Detected("log", "Unknown GUI detected and destroyed: "..d)
				end
			end)
		end;

		AntiTools = function()
			if service.Player:WaitForChild("Backpack", 120) then
				--local btools = data.BTools --Remote.Get("Setting","AntiBuildingTools")  used for??
				--local tools = data.AntiTools --Remote.Get("Setting","AntiTools")				(must be recovered in order for it to be used again)
				--local allowed = data.AllowedList --Remote.Get("Setting","AllowedToolsList")	(must be recovered in order for it to be used again)
				local function check(t)
					if (t:IsA("Tool") or t.ClassName == "HopperBin") and not t:FindFirstChild(Variables.CodeName) then
						if client.AntiBuildingTools and t.ClassName == "HopperBin" and (rawequal(t.BinType, Enum.BinType.Grab) or rawequal(t.BinType, Enum.BinType.Clone) or rawequal(t.BinType, Enum.BinType.Hammer) or rawequal(t.BinType, Enum.BinType.GameTool)) then
							t.Active = false
							t:Destroy()
							Detected("log", "HopperBin Detected (BTools)")
						--elseif not Get("CheckBackpack", t) then
							--t:Destroy() --// Temp disabled pending full fix
							--Detected('log','Client-Side Tool Detected')
						end
					end
				end

				for _,t in pairs(service.Player.Backpack:GetChildren()) do
					check(t)
				end

				service.Player.Backpack.ChildAdded:Connect(check)
			end
		end;

		HumanoidState = function()
			wait(1)
			local humanoid = service.Player.Character:WaitForChild("Humanoid", 2) or service.Player.Character:FindFirstChildOfClass("Humanoid")
			local event
			local doing = true
			if humanoid then
				event = humanoid.StateChanged:Connect(function(_,new)
					if not doing then
						event:Disconnect()
					end
					if rawequal(new, Enum.HumanoidStateType.StrafingNoPhysics) and doing then
						doing = false
						Detected("kill", "NoClipping")
						event:Disconnect()
					end
				end)

				while humanoid and humanoid.Parent and humanoid.Parent.Parent and doing and wait(0.1) do
					if
						not (Enum.HumanoidStateType.StrafingNoPhysics == Enum.HumanoidStateType.StrafingNoPhysics) or
						not rawequal(Enum.HumanoidStateType.StrafingNoPhysics, Enum.HumanoidStateType.StrafingNoPhysics)
					then
						Detected("crash", "Enum tampering detected")
					elseif rawequal(humanoid:GetState(), Enum.HumanoidStateType.StrafingNoPhysics) and doing then
						doing = false
						Detected("kill", "NoClipping")
					end
				end
			end
		end;

		MainDetection = function()
			local game = service.DataModel
			local isStudio = select(2, pcall(service.RunService.IsStudio, service.RunService))
			local findService = service.DataModel.FindService
			local lastUpdate = time()
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
				"current identity is [0789]";
				"gui made by kujo";
				"tetanus reloaded hooked";
				"hookmetamethod";
				"hookfunction";
				"HttpGet";
				"^Chunk %w+, at Line %d+";
				"syn%.";
                                "reviz admin";
                                "iy is already loaded";
                                "infinite yield is already loaded";
                                "infinite yield is already";
                                "iy_debug";
                                "returning json";
                                "shattervast";
                                "failed to parse json";
				"newcclosure", -- // Kicks all non chad exploits which do not support newcclosure like jjsploit
			}

			local soundIds = {
				5032588119,
			}

			local function check(Message)
				for _,v in pairs(lookFor) do
					if string.find(string.lower(Message),string.lower(v)) or string.match(Message, v) and not string.find(string.lower(Message),"failed to load") then
						return true
					end
				end
			end

			local function checkServ()
				if not pcall(function()
					if not isStudio and (findService("ServerStorage", game) or findService("ServerScriptService", game)) then
						Detected("crash","Disallowed Services Detected")
					end
				end) then
					Detected("kick","Disallowed Services Finding Error")
				end
			end

			local function soundIdCheck(Sound)
				for _,v in pairs(soundIds) do
					if Sound.SoundId and (string.find(string.lower(tostring(Sound.SoundId)), tostring(v)) or Sound.SoundId == tostring(v)) then
						return true
					end
				end
				return false
			end

			local function checkTool(t)
				if (t:IsA("Tool") or t.ClassName == "HopperBin") and not t:FindFirstChild(Variables.CodeName) and service.Player:FindFirstChild("Backpack") and t:IsDescendantOf(service.Player.Backpack) then
					if t.ClassName == "HopperBin" and (rawequal(t.BinType, Enum.BinType.Grab) or rawequal(t.BinType, Enum.BinType.Clone) or rawequal(t.BinType, Enum.BinType.Hammer) or rawequal(t.BinType, Enum.BinType.GameTool)) then
						Detected("kick", "Building Tools detected; "..tostring(t.BinType))
					end
				end
			end

			checkServ()

			service.DataModel.ChildAdded:Connect(checkServ)

			service.Events.CharacterRemoving:Connect(function()
				for i, _ in next,coreNums do
					if coreClears[i] then
						coreNums[i] = 0
					end
				end
			end)

			service.ScriptContext.ChildAdded:Connect(function(child)
				if Anti.GetClassName(child) ~= "CoreScript" then
					Detected("kick","Non-CoreScript Detected; "..tostring(child))
				end
			end)

			service.PolicyService.ChildAdded:Connect(function(child)
				if child:IsA("Sound") then
					if soundIdCheck(child) then
						Detected("crash", "CMDx Detected; "..tostring(child))
					else
						wait()
						if soundIdCheck(child) then
							Detected("crash", "CMDx Detected; "..tostring(child))
						end
					end
				end
			end)

			service.ReplicatedFirst.ChildAdded:Connect(function(child)
				if Anti.GetClassName(child) == "LocalScript" then
					Detected("kick", "Localscript Detected; "..tostring(child))
				end
			end)

			service.LogService.MessageOut:Connect(function(Message)
				if check(Message) then
					Detected("crash", "Exploit detected; "..Message)
				end
			end)

			service.Selection.SelectionChanged:Connect(function()
				Detected("kick", "Selection changed")
			end)

			service.ScriptContext.Error:Connect(function(Message, Trace, Script)
				local Message, Trace, Script = tostring(Message), tostring(Trace), tostring(Script)
				if Script and Script == "tpircsnaisyle" then
					Detected("kick", "Elysian Detected")
				elseif check(Message) or check(Trace) or check(Script) then
					Detected("crash", "Exploit detected; "..Message.." "..Trace.." "..Script)
				elseif not Script or (not Trace or Trace == "") then
					local tab = service.LogService:GetLogHistory()
					local continue = false
					if Script then
						for i, v in pairs(tab) do
							if v.message == Message and tab[i+1] and tab[i+1].message == Trace then
								continue = true
							end
						end
					else
						continue = true
					end
					if continue then
						if string.match(Trace, "CoreGui") or string.match(Trace, "PlayerScripts") or string.match(Trace, "Animation_Scripts") or string.match(Trace, "^(%S*)%.(%S*)") then
							return
						else
							Detected("log", "Traceless/Scriptless error")
						end
					end
				end
			end)

			service.RunService.Stepped:Connect(function()
				lastUpdate = time()
			end)

			if service.Player:WaitForChild("Backpack", 120) then
				service.Player.Backpack.ChildAdded:Connect(checkTool)
			end

			--// Detection Loop
			local hasPrinted = false
			service.StartLoop("Detection", 10, function()
				--// Prevent event stopping
				-- if time() - lastUpdate > 60 then -- commented to stop vscode from yelling at me
					--Detected("crash", "Events stopped")
					-- this apparently crashes you when minimizing the windows store app (?) (I assume it's because rendering was paused and so related events also stop)
				-- end

				--// Check player parent
				if service.Player.Parent ~= service.Players then
					Detected("kick", "Parent not players")
				end

				--// Stuff
				local ran,_ = pcall(function() service.ScriptContext.Name = "ScriptContext" end)
				if not ran then
					Detected("log" ,"ScriptContext error?")
				end

				--// Check Log History
				local Logs = service.LogService:GetLogHistory()
				local First = Logs[1]

				if not hasPrinted and not First then
					client.OldPrint(" ")
					client.OldPrint(" ")
					for i = 1, 5 do
						task.wait()
					end

					Logs = service.LogService:GetLogHistory()
					First = Logs[1]
					hasPrinted = true
				else
					if not First then
						Detected("kick", "Suspicious log amount detected 5435345")
						client.OldPrint(" ") -- // To prevent the log amount check from firing every 10 seconds (Just to be safe)
					end
				end

				if
					not rawequal(type(First), "table") or
					not rawequal(type(First.message), "string") or
					not rawequal(typeof(First.messageType), "EnumItem") or
					notrawequal(type(First.timestamp), "number") or First.timestamp < tick() - elapsedTime() - 60 * 60 * 15
				then
					Detected("kick", "Bypass detected 5435345")
				else
					for _, v in ipairs(Logs) do
						if check(v.message) then
							Detected("crash", "Exploit detected; "..v.message)
						end
					end
				end

				--// Check Loadstring
				local ran, _ = pcall(function()
					local func, err = loadstring("print('LolloDev5123 was here')")
				end)
				if ran then
					Detected("crash", "Exploit detected; Loadstring usable")
				end

				--// Check Context Level
				local ran, _ = pcall(function()
					local test = Instance.new("StringValue")
					test.RobloxLocked = true
				end)
				if ran then
					Detected("crash", "RobloxLocked usable")
				end

				local function getDictionaryLenght(dictionary)
					local len = 0

					for _, _ in pairs(dictionary) do
						len += 1
					end

					return len
				end

				local mt = {
					__mode = "v"
				}

				-- // Detects certain anti-dex bypasses
				local tbl = setmetatable({}, mt)
				if mt.__mode ~= "v" or rawget(mt, "__mode") ~= "v" or getmetatable(tbl) ~= mt or getDictionaryLenght(mt) ~= 1 or "_" == "v" or "v" ~= "v" then
					Detected("crash", "Anti-dex bypass found. Method 1")
				else
					local success, value = pcall(function()
						return setmetatable(tbl, mt)
					end)

					if not success or value ~= tbl or not rawequal(value, tbl) then
						Detected("crash", "Anti-dex bypass found. Method 2")
					end
				end

				-- // Checks for anti-coregui detetection bypasses 
				xpcall(function()
					local testDecal = service.UnWrap(Instance.new("Decal"))
					testDecal.Texture = "rbxasset://textures/face.png" -- Its a local asset and it's probably likely to never get removed, so it will never fail to load, unless the users PC is corrupted
					local activated = false
					service.UnWrap(service.ContentProvider):PreloadAsync({testDecal}, function(url, status)
						if url == "rbxasset://textures/face.png" and status == Enum.AssetFetchStatus.Success then
							activated = true
						end
					end)

					testDecal:Destroy()
					task.wait(0.1)
					if not activated then
						Detected("kick", "Coregui detection bypass found")
					end
				end, function()
					Detected("kick", "Tamper Protection 568234")
				end)

				-- // Checks disallowed content URLs in the CoreGui
				xpcall(function()
					if isStudio then
						return
					end

					local hasDetected = false
					local tempDecal = service.UnWrap(Instance.new("Decal"))
					service.UnWrap(service.ContentProvider):PreloadAsync({tempDecal, tempDecal, service.UnWrap(service.CoreGui), tempDecal}, function(url, status)
						if not hasDetected and (string.match(url, "^rbxassetid://") or string.match(url, "^http://www%.roblox%.com/asset/%?id=")) then
							hasDetected = true
							Detected("Kick", "Disallowed content URL detected in CoreGui")
						end
					end)

					tempDecal:Destroy()
				end, function()
					Detected("kick", "Tamper Protection 456754")
				end)
			end)
		end
	}, false, true)

	local Launch = function(mode,data)
		if Anti.Detectors[mode] and service.NetworkClient then
			Anti.Detectors[mode](data)
		end
	end;

	Anti = service.ReadOnly({
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		Launch = Launch;
		Detected = Detected;
		Detectors = Detectors;

		GetClassName = function(obj)
			local testName = tostring(math.random()..math.random())
			local _,err = pcall(function()
				local _ = obj[testName]
			end)
			if err then
				local class = string.match(err, testName.." is not a valid member of (.*)")
				if class then
					return class
				end
			end
		end;

		RLocked = function(obj)
			return not pcall(function()
				return obj.GetFullName(obj)
			end)
		end;

		CoreRLocked = function(obj)
			local testName = tostring(math.random()..math.random())
			local _,err = pcall(function()
				game:GetService("GuiService"):AddSelectionParent(testName, obj)
				game:GetService("GuiService"):RemoveSelectionGroup(testName)
			end)
			if err and string.find(err, testName) and string.find(err, "GuiService:") then
				return true
			else
				wait(0.5)
				for _,v in pairs(service.LogService:GetLogHistory()) do
					if string.find(v.message, testName) and string.find(v.message, "GuiService:") then
						return true
					end
				end
			end
		end;
	}, {["Init"] = true, ["RunLast"] = true, ["RunAfterLoaded"] = true}, true)

	client.Anti = Anti

	do
		local meta = service.MetaFunc
		local track = meta(service.TrackTask)
		local opcall = meta(pcall)
		local oWait = meta(wait)
		local time = meta(time)

		track("Thread: TableCheck", meta(function()
			while oWait(1) do
				local ran, core, remote, functions, anti, send, get, detected, disconnect, kill = coroutine.resume(coroutine.create(function()
					return client.Core, client.Remote, client.Functions, client.Anti, client.Remote.Send, client.Remote.Get, client.Anti.Detected, client.Disconnect, client.Kill
				end))
				if not ran or core ~= Core or remote ~= Remote or functions ~= Functions or anti ~= Anti or send ~= Send or get ~= Get or detected ~= Detected or disconnect ~= Disconnect or kill ~= Kill then
					opcall(Detected, "crash", "Tamper Protection 10042")
					oWait(1)
					opcall(Disconnect, "Adonis_10042")
					opcall(Kill, "Adonis_10042")
					opcall(Kick, Player, "Adonis_10042")
				end
			end
		end))
	end
end
