--// Adonis Client Loader (Non-ReplicatedFirst Version)

local DebugMode = false;

local wait = wait;
local time = time;
local pcall = pcall;
local xpcall = xpcall;
local setfenv = setfenv;
local tostring = tostring;

-- This stops all of the public Adonis bypasses. Though they would still be detected in time but it may be better to kick them before load??
do
	local game = game
	local task_spawn, xpcall, require, task_wait
		= task.spawn, xpcall, require, task.wait
	local Players =  game:FindFirstChildWhichIsA("Players") or game:FindService("Players")
	local localPlayer = Players.LocalPlayer
	local triggered = false

	local function loadingDetected(reason)
		(localPlayer or Players.LocalPlayer):Kick(`:: Adonis Loader - Security ::\n{reason}`)
		while true do end
	end

	local proxyDetector = newproxy(true)

	do
		local proxyMt = getmetatable(proxyDetector)

		proxyMt.__index = function()
			loadingDetected("Proxy methamethod 0xEC7E1")

			return task.wait(2e2)
		end

		proxyMt.__newindex = function()
			loadingDetected("Proxy methamethod 0x28AEC")

			return task.wait(2e2)
		end

		proxyMt.__tostring = function()
			loadingDetected("Proxy methamethod 0x36F14")

			return task.wait(2e2)
		end

		proxyMt.__unm = function()
			loadingDetected("Proxy methamethod 0x50B7F")

			return task.wait(2e2)
		end

		proxyMt.__add = function()
			loadingDetected("Proxy methamethod 0xCD67D")

			return task.wait(2e2)
		end

		proxyMt.__sub = function()
			loadingDetected("Proxy methamethod 0x8110D")

			return task.wait(2e2)
		end

		proxyMt.__mul = function()
			loadingDetected("Proxy methamethod 0x6A01B")

			return task.wait(2e2)
		end

		proxyMt.__div = function()
			loadingDetected("Proxy methamethod 0x5A975")

			return task.wait(2e2)
		end

		proxyMt.__mod = function()
			loadingDetected("Proxy methamethod 0x6CFEB")

			return task.wait(2e2)
		end

		proxyMt.__pow = function()
			loadingDetected("Proxy methamethod 0x20A50")

			return task.wait(2e2)
		end

		proxyMt.__len = function()
			loadingDetected("Proxy methamethod 0x3B96C")

			return task.wait(2e2)
		end

		proxyMt.__metatable = "The metatable is locked"
	end

	task_spawn(xpcall, function()
		local exampleService = game:GetService("Workspace") or game:GetService("ReplicatedStorage")
		local success, err = pcall(require, game)

		if not exampleService then
			task_spawn(xpcall, function() loadingDetected("Service not returning") end, function(err) loadingDetected(err) end)
			while true do end
		end

		if success or not string.match(err, "^Attempted to call require with invalid argument%(s%)%.$") then
			task_spawn(xpcall, function() loadingDetected(`Require load fail. {err}`) end, function(err) loadingDetected(err) end)
			while true do end
		end

		task.spawn(pcall, require, proxyDetector)

		triggered = true
	end, function(err) task_spawn(loadingDetected, err) while true do end end)

	task_spawn(xpcall, function()
		task_wait()
		task_wait()

		if not triggered then
			task_spawn(xpcall, function() loadingDetected(`Loading detectors failed to load{triggered}`) end, function(err) loadingDetected(err) end)
			while true do end
		end
	end, function(err) task_spawn(loadingDetected, err) while true do end end)
end

local players = game:GetService("Players");
local player = players.LocalPlayer;
local folder = script.Parent;
local container = folder.Parent;
local Kick = player.Kick;
local module = folder:WaitForChild("Client");
local target = player;
local realPrint = print;
local realWarn = warn;
local start = time();

local function print(...)
	--realPrint(...)
end

local function warn(str)
	if DebugMode or player.UserId == 1237666 then
		realWarn(`ACLI: {str}`)
	end
end

local function Kill(info)
	if DebugMode then warn(info) return end
	pcall(function() Kick(player, info) end)
	wait(1)
	pcall(function() while not DebugMode and wait() do pcall(function() while true do end end) end end)
end

local function Locked(obj)
	return (not obj and true) or not pcall(function() return obj.GetFullName(obj) end)
end

local function loadingTime()
	warn("LoadingTime Called")
	setfenv(1,{})
	warn(tostring(time() - start))
end

local function callCheck(child)
	warn(`CallCheck: {child}`)
	if Locked(child) then
		warn("Child locked?")
		Kill("ACLI: Locked")
	else
		warn("Child not locked")
		xpcall(function()
			return child[{}]
		end, function()
			if getfenv(1) ~= getfenv(2) then
				Kill("ACLI: Error")
			end
		end)
	end
end

local function doPcall(func, ...)
	local ran,ret = pcall(func, ...)
	if ran then
		return ran,ret
	else
		warn(tostring(ret))
		Kill(`ACLI: Error\n{ret}`)
		return ran,ret
	end
end

if module and module:IsA("ModuleScript") then
	warn("Loading Folder...")
	local nameVal
	local origName
	local depsFolder
	local clientModule

	warn("Waiting for Client & Special")
	nameVal = folder:WaitForChild("Special", 30)

	warn("Checking Client & Special")
	--callCheck(nameVal)
	--callCheck(clientModule)

	warn("Getting origName")
	origName = (nameVal and nameVal.Value) or folder.Name
	warn(`Got name: {origName}`)

	warn("Removing old client folder...")
	local starterPlayer = game:GetService("StarterPlayer");
	local playerScripts = starterPlayer:FindFirstChildOfClass("StarterPlayerScripts");
	local found = playerScripts:FindFirstChild(folder.Name);
	warn(`FOUND?! {found}`);
	warn(`LOOKED FOR : {folder.Name}`)
	if found then
		print("REMOVED!")
		found.Parent = nil --found:Destroy();
	end
	--// Sometimes we load a little too fast and generate a warning from Roblox so we need to introduce some (minor) artificial loading lag...
	warn("Changing child parent...")
	folder.Name = "";
	wait(0.01);
	folder.Parent = nil; --// We cannot do this assynchronously or it will disconnect events that manage to connect before it changes parent to nil...

	warn("Destroying parent...")

	print("Debug: Loading the client?")
	local meta = require(module)
	warn(`Got metatable: {meta}`)
	if meta and type(meta) == "userdata" and tostring(meta) == "Adonis" then
		local ran,ret = pcall(meta,{
			Module = module,
			Start = start,
			Loader = script,
			Name = origName,
			Folder = folder;
			LoadingTime = loadingTime,
			CallCheck = callCheck,
			Kill = Kill
		})

		warn(`Got return: {ret}`)
		if ret ~= "SUCCESS" then
			realWarn(ret)
			Kill("ACLI: Loading Error [Bad Module Return]")
		else
			print("Debug: The client was found and loaded?")
			warn("Client Loaded")

			if container and container:IsA("ScreenGui") then
				container.Parent = nil --container:Destroy();
			end
		end
	end
end
