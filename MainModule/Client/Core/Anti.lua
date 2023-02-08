client = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Anti-Exploit
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
	local isStudio = select(2, pcall(service.RunService.IsStudio, service.RunService))
	local Kick = Player.Kick

	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Variables = client.Variables;
		Process = client.Process;

		Anti.Init = nil;
	end

	local function RunAfterLoaded()
		service.Player.Changed:Connect(function()
			if Anti.RLocked(service.Player) then
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
			task.wait(0.5)
			if action == "kick" then
				if not isStudio then
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


	do
		local callStacks = {
			indexInstance = {},
			newindexInstance = {},
			namecallInstance = {},
			indexEnum = {},
			namecallEnum = {},
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
		
		local function isMethamethodValid(metamethod)
			if
				not metamethod or
				type(metamethod) ~= "function" or
				debug.info(metamethod, "s") ~= "[C]" or
				debug.info(metamethod, "l") ~= -1 or
				debug.info(metamethod, "n") ~= "" or
				debug.info(metamethod, "a") ~= 0
			then
				return false
			else
				return true
			end
		end

		local detectors = {
			indexInstance = {"kick", function()
				local callstackInvalid = false
				local metamethod

				local success, err = xpcall(function()
					local c = rawGame.____________
				end, function()
					metamethod = debug.info(2, "f")
					if callstackInvalid or checkStack("indexInstance") then
						callstackInvalid = true
					end
				end)

				if not isMethamethodValid(metamethod) then
					return true
				end

				local success3, err3 = pcall(metamethod, rawGame)
				local success2, err2 = pcall(metamethod)
				pcall(metamethod, proxyDetector, "GetChildren")
				pcall(metamethod, proxyDetector)
				pcall(metamethod, rawGame, proxyDetector)

				if callstackInvalid or success or success2 or success3 then
					return true
				elseif not errorMessages["indexInstance"] then
					errorMessages["indexInstance"] = {err, err2, err3}
				end

				return not compareTables(errorMessages["indexInstance"], {err, err2, err3})
			end},
			newindexInstance = {"kick", function()
				local callstackInvalid = false
				local metamethod

				local success, err = xpcall(function()
					rawGame.____________ = 5
				end, function()
					metamethod = debug.info(2, "f")
					if callstackInvalid or checkStack("newindexInstance") then
						callstackInvalid = true
					end
				end)

				if not isMethamethodValid(metamethod) then
					return true
				end

				local success3, err3 = pcall(metamethod, rawGame)
				local success2, err2 = pcall(metamethod)
				pcall(metamethod, proxyDetector, "GetChildren")
				pcall(metamethod, proxyDetector)
				pcall(metamethod, rawGame, proxyDetector)
				pcall(metamethod, rawGame, "AllowThirdPartySales", proxyDetector)

				if callstackInvalid or success or success2 or success3 then
					return true
				elseif not errorMessages["newindexInstance"] then
					errorMessages["newindexInstance"] = {err, err2, err3}
				end

				return not compareTables(errorMessages["newindexInstance"], {err, err2, err3})
			end},
			namecallInstance = {"kick", function()
				local callstackInvalid = false
				local metamethod

				local success, err = xpcall(function()
					local c = rawGame:____________()
				end, function()
					metamethod = debug.info(2, "f")
					if callstackInvalid or checkStack("namecallInstance") then
						callstackInvalid = true
					end
				end)

				if not isMethamethodValid(metamethod) then
					return true
				end

				local success3, err3 = pcall(metamethod, rawGame)
				local success2, err2 = pcall(metamethod)
				pcall(metamethod, proxyDetector)
				pcall(metamethod, rawGame, proxyDetector)

				if callstackInvalid or success or success2 or success3 then
					return true
				elseif not errorMessages["namecallInstance"] then
					errorMessages["namecallInstance"] = {err, err2, err3}
				end

				return not compareTables(errorMessages["namecallInstance"], {err, err2, err3})
			end},
			indexEnum = {"kick", function()
				local callstackInvalid = false
				local metamethod

				local success, err = xpcall(function()
					local c = Enum.HumanoidStateType.____________
				end, function()
					metamethod = debug.info(2, "f")
					if callstackInvalid or checkStack("indexEnum") then
						callstackInvalid = true
					end
				end)

				if not isMethamethodValid(metamethod) then
					return true
				end

				local success3, err3 = pcall(metamethod, Enum.HumanoidStateType)
				local success2, err2 = pcall(metamethod)
				pcall(metamethod, proxyDetector, "Name")
				pcall(metamethod, proxyDetector)
				pcall(metamethod, Enum.HumanoidStateType, proxyDetector)

				if callstackInvalid or success or success2 or success3 then
					return true
				elseif not errorMessages["indexEnum"] then
					errorMessages["indexEnum"] = {err, err2, err3}
				end

				return not compareTables(errorMessages["indexEnum"], {err, err2, err3})
			end},
			namecallEnum = {"kick", function()
				local callstackInvalid = false
				local metamethod

				local success, err = xpcall(function()
					local c = Enum.HumanoidStateType:____________()
				end, function()
					metamethod = debug.info(2, "f")
					if callstackInvalid or checkStack("namecallEnum") then
						callstackInvalid = true
					end
				end)

				if not isMethamethodValid(metamethod) then
					return true
				end

				local success3, err3 = pcall(metamethod, Enum.HumanoidStateType)
				local success2, err2 = pcall(metamethod)
				pcall(metamethod, proxyDetector)
				pcall(metamethod, Enum.HumanoidStateType, proxyDetector)

				if callstackInvalid or success or success2 or success3 then
					return true
				elseif not errorMessages["namecallEnum"] then
					errorMessages["namecallEnum"] = {err, err2, err3}
				end

				return not compareTables(errorMessages["namecallEnum"], {err, err2, err3})
			end},
			eqEnum = {"kick", function()
				return not (Enum.HumanoidStateType.Running == Enum.HumanoidStateType.Running)
			end},
		}

		Routine(function()
			while task.wait(5) do
				if not Detected("_", "_", true) then -- detects the current bypass
					while true do end
				end

				for method, detector in detectors do
					local action, callback = detector[1],  detector[2]

					local success, value = pcall(callback)
					if not success or value ~= false and value ~= true then
						Detected("crash", "Tamper Protection 906287")
						task.wait(1)
						pcall(Disconnect, "Adonis_906287")
						pcall(Kill, "Adonis_906287")
						pcall(Kick, Player, "Adonis_906287")
					elseif value then
						Detected(action, method.." detector detected")
					end
				end

				local hasCompleted = false
				task.spawn(xpcall, function()
					local LocalPlayer = service.UnWrap(Player)
					local workspace = service.UnWrap(workspace)
					local nilPlayers = setmetatable({}, {__mode = "v"})

					service.UnWrap(service.Players).ChildRemoved:Connect(function(child)
						if child:IsA("Player") then
							table.insert(nilPlayers, child)
						end
					end)

					local success, err = pcall(function()
						LocalPlayer.Kick(workspace, "If this message appears, report it to Adonis maintainers. 0x1")
					end)
					local success2, err2 = pcall(function()
						workspace:Kick("If this message appears, report it to Adonis maintainers. 0x2")
					end)

					if
						success or err ~= "Expected ':' not '.' calling member function Kick" or
						success2 or string.match(err2, "^Kick is not a valid member of Workspace \"(.+)\"$") ~= workspace:GetFullName()
					then
						Detected("kick", "Anti kick found! Method 0x1")
						warn(success, err, "|", success2, err2)
					end

					if #service.Players:GetPlayers() > 1 then
						local unwrappedPlayers = service.Players

						for _, v in unwrappedPlayers:GetPlayers() do
							local otherPlayer = service.UnWrap(v)

							if otherPlayer and not table.find(nilPlayers, otherPlayer) and otherPlayer.Parent == unwrappedPlayers and otherPlayer ~= LocalPlayer then
								local success, err = pcall(LocalPlayer.Kick, otherPlayer, "If this message appears, report it to Adonis maintainers. 0x2")
								local success2, err2 = pcall(function()
									otherPlayer:Kick("If this message appears, report it to Adonis maintainers. 0x4")
								end)

								if
									success or
									err ~= "Cannot kick a non-local Player from a LocalScript" or
									success2 or
									err2 ~= "Cannot kick a non-local Player from a LocalScript"
								then
									Detected("kick", "Anti kick found! Method 0x2")
									warn(success, err, "|", success2, err2)
								end
							end
						end
					end

					 -- // Detects Kaids antikick
					local success, err = pcall(function()
						LocalPlayer:KicK("If this message appears, report it to Adonis maintainers. 0x5")
					end)

					if success or string.match(err, "^%a+ is not a valid member of Player \"(.+)\"$") ~= LocalPlayer:GetFullName() then
						Detected("kick", "Anti kick found! Method 0x4")
					end

					local success, err = pcall(service.UnWrap(workspace).GetRealPhysicsFPS, rawGame)
					if success or not string.match(err, "Expected ':' not '.' calling member function GetRealPhysicsFPS") then
						Detected("kick", "Anti FPS detection found!")
					end

					hasCompleted = true
				end, function()
					Detected("crash", "Tamper Protection 234654")
					task.wait(1)
					pcall(Disconnect, "Adonis_234654")
					pcall(Kill, "Adonis_234654")
					pcall(Kick, Player, "Adonis_234654")
				end)

				task.spawn(xpcall, function()
					task.wait(4)
					if not hasCompleted then
						Detected("kick", "Anti kick found! Method 3")
					end
				end, function()
					Detected("crash", "Tamper Protection 1897")
					task.wait(1)
					pcall(Disconnect, "Adonis_1897")
					pcall(Kill, "Adonis_1897")
					pcall(Kick, Player, "Adonis_1897")
				end)
			end
		end)
	end

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
		Detectors = {};

		RLocked = function(obj)
			return not pcall(function()
				return obj.GetFullName(obj)
			end)
		end;
	}, {["Init"] = true, ["RunLast"] = true, ["RunAfterLoaded"] = true}, true)

	client.Anti = Anti

	do
		local meta = service.MetaFunc
		local track = meta(service.TrackTask)
		local opcall = meta(pcall)
		local oWait = meta(task.wait)
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
