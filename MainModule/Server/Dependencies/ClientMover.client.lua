--// Adonis Client Loader (Non-ReplicatedFirst Version)

local DebugMode = false;

local wait = wait;
local tick = tick;
local pcall = pcall;
local xpcall = xpcall;
local setfenv = setfenv;
local tostring = tostring;

local players = game:GetService("Players");
local player = players.LocalPlayer;
local folder = script.Parent;
local Kick = player.Kick;
local module = folder:WaitForChild("Client");
local target = player;
local realPrint = print;
local realWarn = warn;
local start = tick();

local function print(...)
	if true then
		--realPrint(...)
	end
end

local function warn(str)
	if DebugMode or player.UserId == 1237666 then
		realWarn("ACLI: "..tostring(str))
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
	warn(tostring(tick() - start))
end

local function callCheck(child)
	warn("CallCheck: "..tostring(child))
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
		Kill("ACLI: Error\n"..tostring(ret))
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
	warn("Got name: "..tostring(origName))

	--// Sometimes we load a little too fast and generate a warning from Roblox so we need to introduce some (minor) artificial loading lag...
	warn("Changing child parent...")
	wait(0.01)
	folder.Parent = nil --// We cannot do this asynchronously or it will disconnect events that manage to connect before it changes parent to nil...

	warn("Destroying parent...")

	print("Debug: Loading the client?")
	local meta = require(module)
	warn("Got metatable: "..tostring(meta))
	if meta and type(meta) == "userdata" and tostring(meta) == "Adonis" then
		local ran,ret = pcall(meta,{
			Module = module,
			Start = start,
			Loader = script,
			Name = origName,
			LoadingTime = loadingTime,
			CallCheck = callCheck,
			Kill = Kill
		})

		warn("Got return: "..tostring(ret))
		if ret ~= "SUCCESS" then
			warn(ret)
			Kill("ACLI: Loading Error [Bad Module Return]")
		else
			print("Debug: The client was found and loaded?")
			warn("Client Loaded")
		end
	end
end
