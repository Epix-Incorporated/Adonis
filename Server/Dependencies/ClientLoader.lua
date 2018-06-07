--// ACLI - Adonis Client Loading Initializer

local DebugMode = false
local oneTooMany = 1 or 1 or 1 or 1 or 1 or ...,...,...,...,...,...,...,...

local otime = os.time
local time = time
local game = game
local pcall = pcall
local xpcall = xpcall
local error = error
local type = type
local print = print
local assert = assert
local string = string
local setfenv = setfenv
local getfenv = getfenv
local require = require
local tostring = tostring
local coroutine = coroutine
local Instance = Instance
local script = script
local select = select
local unpack = unpack
local debug = debug
local pairs = pairs
local wait = wait
local next = next
local tick = tick
local finderEvent
local realWarn = warn
local realPrint = print
local foundClient = false
local checkedChildren = {}
local replicated = game:GetService("ReplicatedFirst")
local runService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local Kick = player.Kick
local start = tick()
local checkThese = {}
local services = {
	"Chat";
	"Teams";
	"Players";
	"Workspace";
	"LogService";
	"TestService";
	"InsertService";
	"SoundService";
	"StarterGui";
	"StarterPack";
	"StarterPlayer";
	"ReplicatedFirst";
	"ReplicatedStorage";
	"JointsService";
	"Lighting";
}

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
	pcall(function() Kick(player, info) end) 
	wait(1)
	pcall(function() while not DebugMode and wait() do pcall(function() while true do end end) end end)
end

local function Locked(obj)
	return (not obj and true) or not pcall(function() return obj.GetFullName(obj) end)
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

local function lockCheck(obj)
	callCheck(obj)
	obj.Changed:connect(function(p) 
		warn("Child changed; Checking...")
		callCheck(obj) 
	end)
end

local function loadingTime()
	warn("LoadingTime Called")
	setfenv(1,{})
	warn(tostring(tick() - start))
end

local function checkChild(child)
	warn("Checking child: "..child.ClassName.." : "..child:GetFullName())
	callCheck(child)
	if child and not foundClient and not checkedChildren[child] and child:IsA("Folder") and child.Name == "Adonis_Client" then
		warn("Loading Folder...")
		local nameVal
		local origName
		local depsFolder
		local clientModule
		local oldChild = child
		
		warn("Adding child to checked list & setting parent...")
		checkedChildren[child] = true
		
		warn("Waiting for Client & Special")
		nameVal = child:WaitForChild("Special", 30)
		clientModule = child:WaitForChild("Client", 30)
		
		warn("Checking Client & Special")
		callCheck(nameVal)
		callCheck(clientModule)
		
		warn("Getting origName")
		origName = (nameVal and nameVal.Value) or child.Name
		warn("Got name: "..tostring(origName))
		
		warn("Changing child parent...")
		child.Parent = nil
		
		if clientModule and clientModule:IsA("ModuleScript") then
			print("Debug: Loading the client?")
			local meta = require(clientModule)
			warn("Got metatable: "..tostring(meta))
			if meta and type(meta) == "userdata" and tostring(meta) == "Adonis" then
				local ran,ret = pcall(meta,{
					Module = clientModule, 
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
					oldChild:Destroy()
					child.Parent = nil
					foundClient = true
					if finderEvent then
						finderEvent:Disconnect()
					end
				end
			end
		end
	end
end

local function scan()
	warn("Scanning for client...")
	if not doPcall(function()
		for i,child in next,player:GetChildren() do
			doPcall(checkChild, child)
		end
	end) then warn("Scan failed?") Kick(player, "ACLI: Loading Error [Scan failed]"); end
end

--// Load client

print("Debug: ACLI Loading?")
setfenv(1, {})
script.Name = "\0"
script:Destroy()
--lockCheck(script)
--lockCheck(game)

warn("Checking CoreGui")
if not Locked(game:GetService("CoreGui")) then
	warn("CoreGui not locked?")
	Kill("ACLI: Error")
else
	warn("CoreGui Locked: "..tostring(Locked(game:GetService("CoreGui"))))
end

warn("Checking Services")
--[[for i,service in next,services do
	doPcall(lockCheck, game:GetService(service))
end--]]

finderEvent = player.ChildAdded:connect(function(child)
	warn("Child Added")
	doPcall(checkChild, child)
end)

warn("Finding children...")
scan()

warn("Waiting and scanning (incase event fails?)...")
while wait(5) and tick() - start < 60*10 and not foundClient do
	scan()
end

warn("Checking if client found...")
if not foundClient then
	warn("Loading took too long")
	Kick(player, "ACLI: Loading Error [Took Too Long]")
else
	print("Debug: Adonis loaded?")
	warn("Client found")
	warn("Finished")
	warn(time())
end