--# selene: allow(empty_loop)
--// Adonis Client Loader (Non-ReplicatedFirst Version)

local DebugMode = script.Parent:FindFirstChild("ADONIS_DEBUGMODE_ENABLED", true) ~= nil

local wait = task.wait
local time = time
local pcall = pcall
local xpcall = xpcall
local setfenv = setfenv
local tostring = tostring

do
	local game = game
	local task_spawn, xpcall, require, task_wait
		= task.spawn, xpcall, require, task.wait
	local Players = game:FindFirstChildWhichIsA("Players") or game:FindService("Players")
	local localPlayer = Players.LocalPlayer
	local triggered = false

	local function loadingDetected(reason)
		(localPlayer or Players.LocalPlayer):Kick(`[ACLI-0x6E2FA164] Loading Error [Environment integrity violation error: {reason}]`)
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

-- ccuser44 was here ^_^
local players = game:GetService("Players")
local player = players.LocalPlayer
local mainFolder = script.Parent
local folder = mainFolder:WaitForChild("Client")
local container = mainFolder.Parent
local Kick = player.Kick
local module = folder:WaitForChild("Client")
local target = player
local realPrint = print
local realWarn = warn
local start = time()
local acliLogs = {}

local function print(...)
	if DebugMode or player.UserId == 1237666 then
		realPrint("ACLI:", ...)
	end
	table.insert(acliLogs, select(2, pcall(table.concat, {"ACLI:", ...}, " ")))
end

local function warn(...)
	realWarn("ACLI:", ...)
	table.insert(acliLogs, select(2, pcall(table.concat, {"ACLI WARNING:", ...}, " ")))
end


local function Kill(info)
	if DebugMode then warn(info) return end
	pcall(function() Kick(player, info) end)
	task.wait(1)
	pcall(function() while not DebugMode and task.wait() do pcall(function() while true do end end) end end)
end

local function Locked(obj)
	return not obj and true or not pcall(function() return obj.GetFullName(obj) end)
end

local function loadingTime()
	setfenv(1, {})
	print("LoadingTime Called:", tostring(time() - start))
end

local function callCheck(child)
	print(`CallCheck: {child}`)
	if Locked(child) then
		warn("Child locked?")
		Kill("[ACLI-0x213A7768D]: Locked")
	else
		print("Child not locked")
		xpcall(function()
			return child[{}]
		end, function()
			if getfenv(1) ~= getfenv(2) then
				Kill("[ACLI-0xBC34ADD8]: Check caller error")
			end
		end)
	end
end

if module and module:IsA("ModuleScript") then
	print("Loading Folder...")
	local nameVal
	local origName
	local depsFolder
	local clientModule

	print("Waiting for Client & Special")
	nameVal = folder:WaitForChild("Special", 30)

	print("Checking Client & Special")
	--callCheck(nameVal)
	--callCheck(clientModule)

	print("Getting origName")
	origName = nameVal and nameVal.Value or folder.Name
	print(`Got name: {origName}`)

	print("Removing old client folder...")
	local starterPlayer = game:GetService("StarterPlayer")
	local playerScripts = starterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
	local found = playerScripts:FindFirstChild(folder.Name)
	print(`FOUND?! {found}`)
	print(`LOOKED FOR : {folder.Name}`)
	if found then
		warn("REMOVED!")
		found.Parent = nil --found:Destroy()
	end
	--// Sometimes we load a little too fast and generate a warning from Roblox so we need to introduce some (minor) artificial loading lag...
	print("Changing child parent...")
	mainFolder.Name = ""
	task.wait(0.01)
	mainFolder.Parent = nil --// We cannot do this asynchronously or it will disconnect events that manage to connect before it changes parent to nil...

	print("Debug: Loading the client?")
	local success, meta = pcall(require, module)
	print(`Got metatable: {meta}`)
	if not success then
		Kill(`[ACLI-0x20D21CEE7]: Loading Error [Module failed to load due to {meta}]`)
	elseif meta and type(meta) == "userdata" and tostring(meta) == "Adonis" then
		local ran, ret = pcall(meta, {
			Module = module,
			Start = start,
			Loader = script,
			Name = origName,
			Folder = folder;
			LoadingTime = loadingTime,
			CallCheck = callCheck,
			Kill = Kill,
			acliLogs = acliLogs
		})

		print(`Got return: {ret}`)
		if ret ~= "SUCCESS" then
			warn("Loading failed! Reason", ret)
			Kill("[ACLI-0x102134B1E]: Loading Error [Bad Module Return]")
		else
			print("Debug: The client was found and loaded?")
			if container and container:IsA("ScreenGui") then
				container.Parent = nil --container:Destroy()
			end
		end
	else
		warn(`Invalid metatable: {meta}!`)
		Kill("[ACLI-0xCE8CEF67]: Loading Error [Bad Module Return]")
	end
end
