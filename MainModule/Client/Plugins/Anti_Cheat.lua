script.Archivable = false
task.spawn(function()
	if not game:GetService("RunService"):IsStudio() then
		script.Name = "\n\n\n\n\n\n\n\n"
	end
end)

return function(Vargs)
	local client, service = Vargs.Client, Vargs.Service
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

	local Anti, Process, UI, Variables
	local script = script
	local Core = client.Core
	local Remote = client.Remote
	local Functions = client.Functions
	local Disconnect = client.Disconnect
	local Send = client.Remote.Send
	local Get = client.Remote.Get
	local NetworkClient = service.NetworkClient
	local Kill = client.Kill
	local Player = service.Players.LocalPlayer
	local isStudio = select(2, pcall(service.RunService.IsStudio, service.RunService))
	local Kick = Player.Kick
	local UI = client.UI;
	local Anti = client.Anti;
	local Variables = client.Variables;
	local Process = client.Process;

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil
	script.Parent = nil
	local function compareTables(t1, t2)
		if service.CountTable(t1) ~= service.CountTable(t2) then
			return false
		end

		for k, _ in pairs(t1) do
			if not rawequal(t1[k], t2[k]) then
				return false
			end
		end

		return true
	end

	local proxyDetector = newproxy(true)

	do
		local proxyMt = getmetatable(proxyDetector)

		proxyMt.__index = function()
			Detected("kick", "Proxy methamethod 8543")

			return task.wait(2e2)
		end

		proxyMt.__newindex = function()
			Detected("kick", "Proxy methamethod 34545")

			return task.wait(2e2)
		end

		proxyMt.__tostring = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__unm = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__add = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__sub = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__mul = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__div = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__mod = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__pow = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__len = function()
			Detected("kick", "Proxy methamethod 789456")

			return task.wait(2e2)
		end

		proxyMt.__metatable = "The metatable is locked"
	end

	local Detectors = service.ReadOnly({
		Speed = function(data)
			service.StartLoop("AntiSpeed", 1, function()
				if workspace:GetRealPhysicsFPS() > tonumber(data.Speed) then
					Detected("kill", "Speed exploiting")
				end
			end)
		end;

		AntiAntiIdle = function(data)
			local hasActivated = false
			local function idleTamper(message)
				if hasActivated then
					return
				end
				hasActivated = true
				Detected("crash", "Tamper Protection 790438; "..tostring(message).."; ")
				wait(1)
				pcall(Disconnect, "Adonis_790438")
				pcall(Kill, "Adonis_790438")
				pcall(Kick, Player, "Adonis_790438")
			end

			if isStudio then
				return
			else
				if not game:IsLoaded() then
					game.Loaded:Wait()
				end

				if not Player.Character and service.Players.CharacterAutoLoads then
					Player.CharacterAdded:Wait()
				end
			end

			local isAntiAntiIdlecheck, clientHasClosed = data.Enabled, false

			task.spawn(pcall, function()
				local connection
				local networkClient = service.UnWrap(service.NetworkClient)
				local clientReplicator = networkClient.ClientReplicator

				if
					#networkClient:GetChildren() == 1 and
					#networkClient:GetDescendants() == 1 and
					networkClient:GetChildren()[1] == clientReplicator and
					networkClient:GetDescendants()[1] == clientReplicator and
					networkClient:FindFirstChild("ClientReplicator") == clientReplicator and
					networkClient:FindFirstChildOfClass("ClientReplicator") == clientReplicator and
					networkClient:FindFirstChildWhichIsA("ClientReplicator") == clientReplicator and
					networkClient:FindFirstDescendant("ClientReplicator") == clientReplicator and
					clientReplicator:FindFirstAncestor("NetworkClient") == networkClient
				then
					connection = networkClient.DescendantRemoving:Connect(function(object)
						if
							object == clientReplicator and
							object.Parent == networkClient and
							object:IsA("NetworkReplicator") and
							object:GetPlayer() == service.UnWrap(Player)
						then
							connection:Disconnect()
							clientHasClosed = true
						end
					end)
				end
			end)

			while true do
				local connection
				local idledEvent = service.UnWrap(Player).Idled
				connection = idledEvent:Connect(function(time)
					if type(time) ~= "number" or not (time > 0) then
						idleTamper("Invalid time data")
					elseif time > 30 * 60 and isAntiAntiIdlecheck ~= false then
						Detected("kick", "Anti-idle detected. "..tostring(math.ceil(time/60) - 20).." minutes above maximum possible Roblox value")
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

				if clientHasClosed then
					return
				end
			end
		end;

		--elseif not Get("CheckBackpack", t) then
		--t:Destroy() --// Temp disabled pending full fix
		--Detected('log','Client-Side Tool Detected')

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
			local findService = service.DataModel.FindService
			local lastLogOutput = os.clock()
			local spoofedHumanoidCheck = Instance.new("Humanoid")
			local remoEventCheck = Instance.new("RemoteEvent")
			local remFuncCheck = Instance.new("RemoteFunction")

			local lookFor = {
				"current identity is [0789]";
				"gui made by kujo";
				"tetanus reloaded hooked";
				"hookmetamethod";
				"hookfunction";
				"HttpGet";
				"^Chunk %w+, at Line %d+";
				"reviz admin";
				"iy is already loaded";
				"infinite yield is already loaded";
				"infinite yield is already";
				"iy_debug";
				"returning json";
				"shattervast";
				"failed to parse json";
				"newcclosure", -- // Kicks all non chad exploits which do not support newcclosure like jjsploit
				"getrawmetatable";
				"setfflag";
			}

			local soundIds = {
				5032588119,
			}

			local function check(Message)
				for _,v in pairs(lookFor) do
					if not string.find(string.lower(Message), "failed to load") and (string.find(string.lower(Message), string.lower(v)) or string.match(Message, v)) then
						return true
					end
				end
			end

			local function checkServ()
				if not pcall(function()
					if not isStudio and (findService(game, "ServerStorage") or findService(game, "ServerScriptService")  or findService(game, "VirtualUser") or findService(game, "VirtualInputManager")) then
						Detected("crash", "Disallowed Services Detected")
					end
				end) then
					Detected("kick", "Disallowed Services Finding Error")
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
				task.wait()

				if t and (t:IsA("Tool") or t.ClassName == "HopperBin") and not t:FindFirstChild(Variables.CodeName) and service.Player:FindFirstChild("Backpack") and t:IsDescendantOf(service.Player.Backpack) then
					if t.ClassName == "HopperBin" and (rawequal(t.BinType, Enum.BinType.Grab) or rawequal(t.BinType, Enum.BinType.Clone) or rawequal(t.BinType, Enum.BinType.Hammer) or rawequal(t.BinType, Enum.BinType.GameTool)) then
						Detected("kick", "Building Tools detected; "..tostring(t.BinType))
					end
				end
			end

			checkServ()

			service.DataModel.ChildAdded:Connect(checkServ)

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

			service.LogService.MessageOut:Connect(function(Message)
				if Message == " " then
					lastLogOutput = os.clock()
				elseif type(Message) ~= "string" then
					pcall(Detected, "crash", "Tamper Protection 24589")
					task.wait(1)
					pcall(Disconnect, "Adonis_24589")
					pcall(Kill, "Adonis_24589")
					pcall(Kick, Player, "Adonis_24589")
				elseif check(Message) then
					Detected("crash", "Exploit detected; "..Message)
				end
			end)

			--[[
			service.ScriptContext.ChildAdded:Connect(function(child)
				if Anti.GetClassName(child) ~= "CoreScript" then
					Detected("kick","Non-CoreScript Detected; "..tostring(child))
				end
			end)

			service.ReplicatedFirst.ChildAdded:Connect(function(child)
				if Anti.GetClassName(child) == "LocalScript" then
					Detected("kick", "Localscript Detected; "..tostring(child))
				end
			end)
			]]

			service.ScriptContext.Error:Connect(function(Message, Trace, Script)
				Message, Trace, Script = tostring(Message), tostring(Trace), tostring(Script)

				if Script and Script == "tpircsnaisyle" then
					Detected("kick", "Elysian Detected")
				elseif check(Message) or check(Trace) or check(Script) then
					Detected("crash", "Exploit detected; "..Message.." "..Trace.." "..Script)
				elseif not Script or (not Trace or Trace == "") then
					local tab = service.LogService:GetLogHistory()
					local found = false
					if Script then
						for i, v in pairs(tab) do
							if v.message == Message and tab[i+1] and tab[i+1].message == Trace then
								found = true
							end
						end
					else
						found = true
					end
					if found then
						if string.match(Trace, "CoreGui") or string.match(Trace, "PlayerScripts") or string.match(Trace, "Animation_Scripts") or string.match(Trace, "^(%S*)%.(%S*)") then
							return
						else
							Detected("log", "Traceless/Scriptless error")
						end
					end
				end
			end)

			if service.Player:WaitForChild("Backpack", 120) then
				service.Player.Backpack.ChildAdded:Connect(checkTool)
			end

			--// Detection Loop
			local hasPrinted = false
			service.StartLoop("Detection", 15, function()
				--// Stuff
				local ran,_ = pcall(function() service.ScriptContext.Name = "ScriptContext" end)
				if not ran then
					Detected("log", "ScriptContext error?")
				end

				--// Check Log History
				local Logs = service.LogService.GetLogHistory(service.LogService)
				local rawLogService = service.UnWrap(service.LogService)
				local First = Logs[1]

				if not compareTables(Logs, rawLogService:GetLogHistory()) then
					Detected("kick", "Log spoofing found")
				elseif not hasPrinted and not First then
					local startTime = os.clock()
					client.OldPrint(" ")
					for i = 1, 5 do
						task.wait()
					end

					Logs = service.LogService:GetLogHistory()
					First = Logs[1]
					hasPrinted = true

					if (lastLogOutput + 3) > startTime then
						Detected("kick", "Log event not outputting to console")
					end
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
					not rawequal(type(First.timestamp), "number") or
					First.timestamp < tick() - os.clock() - 60 * 60 * 5 or
					First.timestamp > tick() + 60 * 60 * 24 * 7 * 4 * 5 or -- If the timestamp is five months in the future, it's safe to say its invalid
				then
					Detected("kick", "Bypass detected 5435345")
				else
					for _, v in ipairs(Logs) do
						if check(v.message) then
							Detected("crash", "Exploit detected; "..v.message)
						end
					end
				end

				-- // GetLogHistory hook detection
				do
					local success, err = pcall(function()
						rawLogService:getlogHistory())
					end)
					local success2, err2 = pcall(function()
						rawLogService.GetLogHistory(workspace)
					end)
					local success3, err3 = pcall(function()
						workspace:GetLogHistory()
					end)

					if
						success or string.match(err, "^%a+ is not a valid member of ContentProvider \"(.+)\"$") ~= rawLogService:GetFullName() or
						success2 or err2 ~= "Expected ':' not '.' calling member function GetLogHistory" or
						success3 or string.match(err3, "^GetLogHistory is not a valid member of Workspace \"(.+)\"$") ~= workspace:GetFullName()
					then
						Detected("kick", "GetLogHistory function hooks detected")
					end
				end

				-- // RemoteEvent hook detection
				do
					local success, err = pcall(function()
						remEventCheck:fireserver())
					end)
					local success2, err2 = pcall(function()
						remEventCheck.FireServer(workspace)
					end)
					local success3, err3 = pcall(function()
						workspace:FireServer()
					end)

					if
						success or string.match(err, "^%a+ is not a valid member of RemoteEvent \"(.+)\"$") ~= remEventCheck:GetFullName() or
						success2 or err2 ~= "Expected ':' not '.' calling member function FireServer" or
						success3 or string.match(err3, "^FireServer is not a valid member of Workspace \"(.+)\"$") ~= workspace:GetFullName()
					then
						Detected("kick", "FireServer function hooks detected")
					end
				end
				pcall(remEventCheck.FireServer, remEventCheck, proxyDetector)

				-- // RemoteFunction hook detection
				do
					local success, err = pcall(function()
						remFuncCheck:invokeserver())
					end)
					local success2, err2 = pcall(function()
						remFuncCheck.InvokeServer(workspace)
					end)
					local success3, err3 = pcall(function()
						workspace:InvokeServer()
					end)

					if
						success or string.match(err, "^%a+ is not a valid member of RemoteFunction \"(.+)\"$") ~= remFuncCheck:GetFullName() or
						success2 or err2 ~= "Expected ':' not '.' calling member function InvokeServer" or
						success3 or string.match(err3, "^InvokeServer is not a valid member of Workspace \"(.+)\"$") ~= workspace:GetFullName()
					then
						Detected("kick", "InvokeServer function hooks detected")
					end
				end
				pcall(remFuncCheck.InvokeServer, remFuncCheck, proxyDetector)

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

				-- // Checks for certain disallowed object names in the core GUI which wouldnt otherwise be detectable
				for _, v in pairs({"SentinelSpy", "ScriptDumper", "VehicleNoclip", "Strong Stand"}) do -- recursive findfirstchild check that yeets some stuff; --[["Sentinel",]]
					local object = Player and Player.Name ~= v and service.UnWrap(game).FindFirstChild(service.UnWrap(game), v, true)            -- ill update the list periodically
					if object then
						Detected("kick", "Malicious Object?: " .. v)
					end
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

					if not success or value ~= tbl or not service.OrigRawEqual(value, tbl) then
						Detected("crash", "Anti-dex bypass found. Method 2")
					end
				end

				-- // Checks disallowed content URLs in the CoreGui
				xpcall(function()
					if isStudio then
						return
					end

					local hasDetected = false
					local activated = false
					local rawContentProvider = service.UnWrap(service.ContentProvider)
					local workspace = service.UnWrap(workspace)
					local tempDecal = service.UnWrap(Instance.new("Decal"))
					tempDecal.Texture = "rbxasset://textures/face.png" -- Its a local asset and it's probably likely to never get removed, so it will never fail to load, unless the users PC is corrupted
					rawContentProvider.PreloadAsync(rawContentProvider, {tempDecal, tempDecal, tempDecal, service.UnWrap(service.CoreGui), tempDecal}, function(url, status)
						if url == "rbxasset://textures/face.png" and status == Enum.AssetFetchStatus.Success then
							activated = true
						elseif not hasDetected and (string.match(url, "^rbxassetid://") or string.match(url, "^http://www%.roblox%.com/asset/%?id=")) then
							hasDetected = true
							Detected("Kick", "Disallowed content URL detected in CoreGui")
						end
					end)

					tempDecal:Destroy()
					task.wait(6)
					if not activated then -- // Checks for anti-coregui detetection bypasses
						Detected("kick", "Coregui detection bypass found")
					end

					local success, err = pcall(function()
						rawContentProvider:preloadasync({tempDecal})
					end)
					local success2, err2 = pcall(function()
						rawContentProvider.PreloadAsync(workspace, {tempDecal})
					end)
					local success3, err3 = pcall(function()
						workspace:PreloadAsync({tempDecal})
					end)

					if
						success or string.match(err, "^%a+ is not a valid member of ContentProvider \"(.+)\"$") ~= rawContentProvider:GetFullName() or
						success2 or err2 ~= "Expected ':' not '.' calling member function PreloadAsync" or
						success3 or string.match(err3, "^PreloadAsync is not a valid member of Workspace \"(.+)\"$") ~= workspace:GetFullName()
					then
						Detected("kick", "Content provider spoofing detected")
					end
				end, function()
					Detected("kick", "Tamper Protection 456754")
				end)

				-- // GetFocusedTextBox detection
				xpcall(function()
					if isStudio then
						return
					end

					local textbox = service.UserInputService:GetFocusedTextBox()
					local success, value = pcall(service.StarterGui.GetCore, service.StarterGui, "DeveloperConsoleVisible")

					if textbox and Anti.RLocked(textbox) and not (success and value) and not service.GuiService.MenuIsOpen then
						Detected("Kick", "Invalid CoreGui Textbox has been selected")
					end
				end, function()
					Detected("kick", "Tamper Protection 356745234")
				end)

				-- // Anti RAKNET based DoS detection
				xpcall(function()
					if isStudio then
						return
					end

					if service.Stats.DataSendKbps >= 600 then -- // Roblox shouldn't allow this much data if im wrong though it should be made higher
						Detected("kick", "RAKNET based volumetric DoS attack detected, or other data send unlocked DoS")
					end
				end, function()
					Detected("kick", "Tamper Protection 879676")
				end)

				-- // Anti humanoid data spoof
				xpcall(function()
					local eventCount = 0
					local newWalkSpeed, newJumpPower = math.random(1, 100), math.random(1, 100)
					local connection1, connection2, connection3

					connection1 = spoofedHumanoidCheck.Changed:Connect(function()
						eventCount += 1
					end)
					connection2 = spoofedHumanoidCheck:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
						eventCount += 1
					end)
					connection3 = spoofedHumanoidCheck:GetPropertyChangedSignal("JumpPower"):Connect(function()
						eventCount += 1
					end)

					spoofedHumanoidCheck.WalkSpeed = newWalkSpeed
					spoofedHumanoidCheck.JumpPower = newJumpPower

					if
						spoofedHumanoidCheck.WalkSpeed ~= newWalkSpeed or
						spoofedHumanoidCheck.JumpPower ~= newJumpPower
					then
						Detected("kick", "Humanoid tampering detected. Method 1")
					end
					
					task.spawn(function()
						task.wait(5)
						connection1:Disconnect()
						connection2:Disconnect()
						connection3:Disconnect()

						if eventCount < 4 then
							Detected("kick", "Humanoid tampering detected. Method 2")
						end
					end)
				end, function()
					Detected("kick", "Tamper Protection 879676")
				end)
	
				if gcinfo() ~= collectgarbage("count") then
					Detected("kick", "GC spoofing detected")
				end
			end)
		end
	}, false, true)

	Anti.Detectors = Detectors

	-- // The tamper checks below are quite bad but they are sufficient for now
	local lastChanged1, lastChanged2, lastChanged3 = os.clock(), os.clock(), os.clock()
	script.Changed:Connect(function(prop)
		if prop == "Name" and string.match(script.Name "^\n\n+ModuleScript$") then
			lastChanged1 = os.clock()
		elseif not isStudio then
			Detected("kick", "Tamper Protection 324435")
		end
	end)

	do
		local meta = service.MetaFunc
		local track = meta(service.TrackTask)
		local opcall = meta(pcall)
		local oWait = meta(wait)
		local time = meta(time)

		track("Thread: TableCheck", meta(function()
			while oWait(1) do
				local success, value = pcall(function()
					return Anti.Detectors
				end)
				if
					not success or
					script.Archivable ~= false or
					not isStudio and (not string.match(script.Name "^\n\n+ModuleScript$") or os.clock() - lastChanged1 > 60) or
					os.clock() - lastChanged3 > 60
				then
					opcall(Detected, "crash", "Tamper Protection 98744")
					oWait(1)
					opcall(Disconnect, "Adonis_98744")
					opcall(Kill, "Adonis_98744")
					opcall(Kick, Player, "Adonis_98744")
				end

				if not isStudio then
					script.Name = "\n\n"..string.rep("\n", math.random(1, 50)).."ModuleScript"
				end
				lastChanged2 = os.clock()
			end
		end))

		task.spawn(xpcall, function()
			while true do
				if
					not isStudio and math.abs(os.clock() - lastChanged1) > 60 or
					math.abs(os.clock() - lastChanged2) > 60 or
					math.abs(os.clock() - lastChanged3) > 60 or
				then
					opcall(Detected, "crash", "Tamper Protection 178945")
					oWait(1)
					opcall(Disconnect, "Adonis_178945")
					opcall(Kill, "Adonis_178945")
					opcall(Kick, Player, "Adonis_178945")
				end

				task.wait(1)
				lastChanged3 = os.clock()
			end
		end, function()
			opcall(Detected, "crash", "Tamper Protection 1543")
			oWait(1)
			opcall(Disconnect, "Adonis_1543")
			opcall(Kill, "Adonis_1543")
			opcall(Kick, Player, "Adonis_1543")
		end)
	end
end
