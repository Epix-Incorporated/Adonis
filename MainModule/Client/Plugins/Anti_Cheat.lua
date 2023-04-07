--!nolint DeprecatedGlobal
--# selene: allow(deprecated)
script.Archivable = false
task.spawn(function()
	if not game:GetService("RunService"):IsStudio() then
		script.Name = "\n\n\n\n\n\n\n\nModuleScript"
	end
end)

GetEnv = nil

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
	local Detected = Anti.Detected;

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil
	script.Parent = nil
	local compareTables
	compareTables = function(t1, t2)
		if service.CountTable(t1) ~= service.CountTable(t2) then
			return false
		end

		for k, _ in pairs(t1) do
			local val1, val2 = t1[k], t2[k]
			local isTable = type(val1) == "table"

			if isTable and not compareTables(val1, val2) or not isTable and not rawequal(val1, val2) then
				return false
			end
		end

		return true
	end

	local proxyDetector = newproxy(true)

	do
		local proxyMt = getmetatable(proxyDetector)

		proxyMt.__index = function()
			Detected("kick", "Proxy methamethod 0x215F")

			return task.wait(2e2)
		end

		proxyMt.__newindex = function()
			Detected("kick", "Proxy methamethod 0x86F1")

			return task.wait(2e2)
		end

		proxyMt.__tostring = function()
			Detected("kick", "Proxy methamethod 0xC0BD0")

			return task.wait(2e2)
		end

		proxyMt.__unm = function()
			Detected("kick", "Proxy methamethod 0x10F00")

			return task.wait(2e2)
		end

		proxyMt.__add = function()
			Detected("kick", "Proxy methamethod 0x60DC3")

			return task.wait(2e2)
		end

		proxyMt.__sub = function()
			Detected("kick", "Proxy methamethod 0x90F5D")

			return task.wait(2e2)
		end

		proxyMt.__mul = function()
			Detected("kick", "Proxy methamethod 0x19999")

			return task.wait(2e2)
		end

		proxyMt.__div = function()
			Detected("kick", "Proxy methamethod 0x1D14AC")

			return task.wait(2e2)
		end

		proxyMt.__mod = function()
			Detected("kick", "Proxy methamethod 0x786C64")

			return task.wait(2e2)
		end

		proxyMt.__pow = function()
			Detected("kick", "Proxy methamethod 0x1D948C")

			return task.wait(2e2)
		end

		proxyMt.__len = function()
			Detected("kick", "Proxy methamethod 0xBE931")

			return task.wait(2e2)
		end

		proxyMt.__metatable = "The metatable is locked"
	end

	local Detectors = {
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
				Detected("crash", "Tamper Protection 0xC0FA6; "..tostring(message).."; ")
				wait(1)
				pcall(Disconnect, "Adonis_0xC0FA6")
				pcall(Kill, "Adonis_0xC0FA6")
				pcall(Kick, Player, "Adonis_0xC0FA6")
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
					elseif time > 30 * 60 and isAntiAntiIdlecheck ~= false and not clientHasClosed then
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

				task.wait(200 + math.random() * 5)
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

		AntiCoreGui = function()
			if isStudio then
				return
			end

			-- // Checks disallowed content URLs in the CoreGui
			service.StartLoop("AntiCoreGui", 15, function()
				xpcall(function()
					local function getCoreUrls()
						local coreUrls = {}
						local backpack = Player:FindFirstChildOfClass("Backpack")
						local character = Player.Character
						local screenshotHud = service.GuiService:FindFirstChildOfClass("ScreenshotHud")

						if character then
							for _, v in ipairs(character:GetChildren()) do
								if v:IsA("BackpackItem") and service.Trim(v.TextureId) ~= "" then
									table.insert(coreUrls, service.Trim(v.TextureId))
								end
							end
						end

						if backpack then
							for _, v in ipairs(backpack:GetChildren()) do
								if v:IsA("BackpackItem") and service.Trim(v.TextureId) ~= "" then
									table.insert(coreUrls, service.Trim(v.TextureId))
								end
							end
						end

						if screenshotHud and service.Trim(screenshotHud.CameraButtonIcon) ~= "" then
							table.insert(coreUrls, service.Trim(screenshotHud.CameraButtonIcon))
						end

						return coreUrls
					end

					local hasDetected = false
					local activated = false
					local rawContentProvider = service.UnWrap(service.ContentProvider)
					local workspace = service.UnWrap(workspace)
					local tempDecal = service.UnWrap(Instance.new("Decal"))
					tempDecal.Texture = "rbxasset://textures/face.png" -- Its a local asset and it's probably likely to never get removed, so it will never fail to load, unless the users PC is corrupted
					local coreUrls = getCoreUrls()

					if not (service.GuiService.MenuIsOpen or service.ContentProvider.RequestQueueSize >= 50 or Player:GetNetworkPing() >= 750) then
						rawContentProvider.PreloadAsync(rawContentProvider, {tempDecal, tempDecal, tempDecal, service.UnWrap(service.CoreGui), tempDecal}, function(url, status)
							if url == "rbxasset://textures/face.png" and status == Enum.AssetFetchStatus.Success then
								activated = true
							elseif not hasDetected and (string.match(url, "^rbxassetid://") or string.match(url, "^http://www%.roblox%.com/asset/%?id=")) then
								local isItemIcon = false

								for _, v in ipairs(coreUrls) do
									if string.find(url, v, 1, true) then
										isItemIcon = true
										break
									end
								end

								if isItemIcon == true then
									return
								end

								hasDetected = true
								Detected("Kick", "Disallowed content URL detected in CoreGui")
							end
						end)

						tempDecal:Destroy()
						task.wait(6)
						if not activated then -- // Checks for anti-coregui detetection bypasses
							Detected("kick", "Coregui detection bypass found")
						end
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
						success or (string.match(err, "^%a+ is not a valid member of ContentProvider \"(.+)\"$") or "") ~= rawContentProvider:GetFullName() or
						success2 or err2 ~= "Expected ':' not '.' calling member function PreloadAsync" or
						success3 or (string.match(err3, "^PreloadAsync is not a valid member of Workspace \"(.+)\"$") or "") ~= workspace:GetFullName()
					then
						Detected("kick", "Content provider spoofing detected")
					end
					
					-- // GetFocusedTextBox detection
					local textbox = service.UserInputService:GetFocusedTextBox()
					local success, value = pcall(service.StarterGui.GetCore, service.StarterGui, "DeveloperConsoleVisible")
					local textChatService = service.TextChatService
					local chatBarConfig = textChatService and textChatService:FindFirstChildOfClass("ChatInputBarConfiguration")

					if
						textbox and Anti.RLocked(textbox) and not ((success and value) or service.GuiService.MenuIsOpen or (
							service.Chat.LoadDefaultChat and
							textChatService and
							textChatService.ChatVersion == Enum.ChatVersion.TextChatService and
							chatBarConfig and
							chatBarConfig.Enabled
						))
					then
						Detected("Kick", "Invalid CoreGui Textbox has been selected")
					end
				end, function()
					Detected("kick", "Tamper Protection 0x6F832")
				end)
			end)
		end,

		MainDetection = function()
			local game = service.DataModel
			local findService = service.DataModel.FindService
			local lastLogOutput = os.clock()
			local spoofedHumanoidCheck = Instance.new("Humanoid")

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
				"setrawmetatable";
				"getnamecallmethod";
				"setnamecallmethod";
				--"setfflag";
				--"getfflag";
				"gethui";
				"isreadonly";
				"setreadonly";
				"isfile";
				"writefile";
				"appendfile";
				"delfile";
				"readfile";
				"loadfile";
				--"isfolder";
				"makefolder";
				"delfolder";
				"listfiles";
				"secure_call"; -- synapse specific (?)
				"getsynasset"; -- synapse specific
				"getcustomasset";
				"cloneref";
				--"clonefunction";
				"getspecialinfo";
				"saveinstance";
				--"messagebox";
				"protect_gui"; -- specific to synapse and smaller executors like sirhurt, temple, etc
				"unprotect_gui"; -- specific to synapse and smaller executors like sirhurt, temple, etc
				"rconsoleprint";
				"rconsoleinfo";
				"rconsolewarn";
				"rconsoleerr";
				"rconsoleclear";
				"rconsolename";
				"rconsoleinput";
				--"printconsole";
				"checkcaller";
				--"dumpstring";
				"islclosure";
				"getscriptclosure";
				"getscripthash";
				"getcallingscript";
				"getgenv";
				"getsenv";
				"getrenv";
				"getmenv";
				"gettenv"; -- script-ware specific
				"identifyexecutor";
				"getreg";
				"getgc";
				"getnilinstances";
				"getconnections";
				"getloadedmodules";
				"firesignal";
				--"fireclickdetector";
				"fireproximityprompt";
				"firetouchinterest";
				"setsimulationradius";
				"getsimulationradius";
				"sethiddenproperty";
				"gethiddenproperty";
				"setscriptable";
				--"isnetworkowner";
				"setclipboard";
				"getconstants";
				"getconstant";
				"setconstant";
				"getupvalues";
				"getupvalue";
				"setupvalue";
				"getprotos";
				"getproto";
				"setproto";
				"getstack";
				"setstack";
				"getregistry";
				"cache_replace"; -- synapse specific (?)
				"cache_invalidate"; -- synapse specific (?)
				"get_thread_identity"; -- synapse specific (?)
				"set_thread_identity"; -- synapse specific (?)
				"setthreadcontext";
				--"setidentity";
				--"is_cached"; -- synapse specific (?)
				"write_clipboard"; -- synapse specific (?)
				"replicatesignal";
				"hooksignal";
				"queue_on_teleport";
				--"is_beta"; -- synapse specific (?)
				"create_secure_function";  -- synapse specific (?)
				"run_secure_function";  -- synapse specific (?)
				"Kill by Avexus#1234 initialized";
				--"FilteringEnabled Kill"; -- // Disabled due to potential of having false flags
				"Couldn't find target with input:";
				"Found target with input:";
				"Couldn't find the target's root part%. :[";
			}

			local soundIds = {
				5032588119,
			}

			local function check(Message)
				for _, v in lookFor do
					if
						not string.find(string.lower(Message), "failed to load", 1, true) and
						not string.find(string.lower(Message), "meshcontentprovider failed to process", 1, true) and
						(string.match(string.lower(Message), string.lower(v)) or string.match(Message, v))
					then
						return true
					end
				end
			end

			local function checkServ()
				if
					not service.GuiService:IsTenFootInterface() and
					not service.VRService.VREnabled and
					not service.UserInputService.GamepadEnabled and
					not service.UserInputService.TouchEnabled
				then
					if not pcall(function()
						if not isStudio and (findService(game, "VirtualUser") or findService(game, "VirtualInputManager")) then
							Detected("crash", "Disallowed Services Detected")
						end
					end) then
						Detected("kick", "Disallowed Services Finding Error")
					end
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
					pcall(Detected, "crash", "Tamper Protection 0x600D")
					task.wait(1)
					pcall(Disconnect, "Adonis_0x600D")
					pcall(Kill, "Adonis_0x600D")
					pcall(Kick, Player, "Adonis_0x600D")
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

					if (lastLogOutput + 3) < startTime then
						Detected("kick", "Log event not outputting to console")
					end
				else
					if not First then
						Detected("kick", "Suspicious log amount detected 0x48248")
						client.OldPrint(" ") -- // To prevent the log amount check from firing every 10 seconds (Just to be safe)
					end
				end

				if
					not rawequal(type(First), "table") or
					not rawequal(type(First.message), "string") or
					not rawequal(typeof(First.messageType), "EnumItem") or
					not rawequal(type(First.timestamp), "number") or
					First.timestamp < os.time() - os.clock() - 60 * 60 * 48 or
					First.timestamp > os.time() + 60 * 60 * 24 * 7 * 4 * 5 -- If the timestamp is five months in the future, it's safe to say its invalid
				then
					Detected("kick", "Bypass detected 0x48248")
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
					Detected("crash", "Anti-dex bypass found. Method 0x1")
				else
					local success, value = pcall(function()
						return setmetatable(tbl, mt)
					end)

					if not success or value ~= tbl or not service.OrigRawEqual(value, tbl) then
						Detected("crash", "Anti-dex bypass found. Method 0x2")
					end
				end

				-- // Anti RAKNET based DoS detection
				--[[xpcall(function()
					if isStudio then
						return
					end

					if service.Stats.DataSendKbps >= 1000 then -- // Roblox shouldn't allow this much data if im wrong though it should be made higher
						Detected("kick", "RAKNET based volumetric DoS attack detected, or other data send unlocked DoS")
					end
				end, function()
					Detected("kick", "Tamper Protection 0x11984")
				end)--]]

				-- // Anti humanoid data spoof
				xpcall(function()
					local eventCount = 0
					local oldWalkSpeed, oldJumpPower = spoofedHumanoidCheck.WalkSpeed, spoofedHumanoidCheck.JumpPower
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
						Detected("kick", "Humanoid tampering detected. Method 0x1")
					end

					if newWalkSpeed == oldWalkSpeed then
						eventCount += 2
					end

					if newJumpPower == oldJumpPower then
						eventCount += 2
					end

					task.spawn(function()
						task.wait(5)
						connection1:Disconnect()
						connection2:Disconnect()
						connection3:Disconnect()

						if eventCount < 4 then
							Detected("kick", "Humanoid tampering detected. Method 0x2. Count: "..tostring(eventCount))
						end
					end)
				end, function()
					Detected("kick", "Tamper Protection 0x16C1D")
				end)
	
				if gcinfo() ~= collectgarbage("count") then
					Detected("kick", "GC spoofing detected")
				end

				xpcall(function()
					local strings = {
						"Loaded press z to", "press x to respawn", "Fe Invisible Fling By",
						"Diemiers#4209", "Respawning dont spam"
					}

					for _, object in ipairs(workspace:GetChildren()) do
						if object:IsA("Message") then
							local text = object.Text

							for _, v in ipairs(strings) do
								if string.find(text, v, 1, true) then
									Detected("kick", "Invisible FE fling GUI detected")
								end
							end
						end
					end
				end, warn)
			end)
		end
	}

	for k, v in pairs(Detectors) do
		Anti.AddDetector(k, v)
	end

	-- // The tamper checks below are quite bad but they are sufficient for now
	local lastChanged1, lastChanged2, lastChanged3 = os.clock(), os.clock(), os.clock()
	local checkEvent = service.UnWrap(script).Changed:Connect(function(prop)
		if prop == "Name" and string.match(script.Name, "^\n\n+ModuleScript$") then
			lastChanged1 = os.clock()
		elseif not isStudio then
			Detected("kick", "Tamper Protection 0xC1E7")
		end
	end)

	do
		local meta = service.MetaFunc
		local track = meta(service.TrackTask)
		local opcall = meta(pcall)
		local oWait = meta(wait)
		local time = meta(time)
		local oldName = ""

		track("Thread: TableCheck", meta(function()
			while oWait(1) do
				local success, value = pcall(function()
					return Anti.Detectors
				end)
				if
					not success or
					script.Archivable ~= false or
					not isStudio and (not string.match(script.Name, "^\n\n+ModuleScript$") or os.clock() - lastChanged1 > 60) or
					os.clock() - lastChanged3 > 60 or
					not checkEvent or
					typeof(checkEvent) ~= "RBXScriptConnection" or
					checkEvent.Connected ~= true
				then
					opcall(Detected, "crash", "Tamper Protection 0x16471")
					oWait(1)
					opcall(Disconnect, "Adonis_0x16471")
					opcall(Kill, "Adonis_0x16471")
					opcall(Kick, Player, "Adonis_0x16471")
				end

				if not isStudio then
					local newName = "\n\n"..string.rep("\n", math.random(1, 50)).."ModuleScript"

					if newName == oldName then
						lastChanged1 = os.clock()
					end

					script.Name, oldName = newName, newName
				else
					lastChanged1 = os.clock()
				end
				lastChanged2 = os.clock()
			end
		end))

		task.spawn(xpcall, function()
			while true do
				if
					not isStudio and math.abs(os.clock() - lastChanged1) > 60 or
					math.abs(os.clock() - lastChanged2) > 60 or
					math.abs(os.clock() - lastChanged3) > 60
				then
					opcall(Detected, "crash", "Tamper Protection 0xE28D")
					oWait(1)
					opcall(Disconnect, "Adonis_0xE28D")
					opcall(Kill, "Adonis_0xE28D")
					opcall(Kick, Player, "Adonis_0xE28D")
				end

				task.wait(1)
				lastChanged3 = os.clock()
			end
		end, function()
			opcall(Detected, "crash", "Tamper Protection 0x36C6")
			oWait(1)
			opcall(Disconnect, "Adonis_0x36C6")
			opcall(Kill, "Adonis_0x36C6")
			opcall(Kick, Player, "Adonis_0x36C6")
		end)
	end
end
