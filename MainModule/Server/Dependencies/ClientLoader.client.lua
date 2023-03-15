--// ACLI - Adonis Client Loading Initializer
if true then return end --// #DISABLED

local DebugMode = false
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
local spawn = spawn
local debug = debug
local pairs = pairs
local wait = wait
local next = next
local time = time
local finderEvent
local realWarn = warn
local realPrint = print
local foundClient = false
local checkedChildren = {}
local replicated = game:GetService("ReplicatedFirst")
local runService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local Kick = player.Kick
local start = time()
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
	--realPrint(...)
end

local function warn(str)
	if DebugMode or player.UserId == 1237666 then
		realWarn(`ACLI: {tostring(str)}`)
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

local function callCheck(child)
	warn(`CallCheck: {tostring(child)}`)
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
		Kill(`ACLI: Error\n{tostring(ret)}`)
		return ran,ret
	end
end

local function lockCheck(obj)
	callCheck(obj)
	obj.Changed:Connect(function(p)
		warn("Child changed; Checking...")
		callCheck(obj)
	end)
end

local function loadingTime()
	warn("LoadingTime Called")
	setfenv(1,{})
	warn(tostring(time() - start))
end

local function checkChild(child)
	warn(`Checking child: {tostring(child and child.ClassName)} : {tostring(child and child:GetFullName())}`)
	callCheck(child)
	if child and not foundClient and not checkedChildren[child] and child:IsA("Folder") and child.Name == "Adonis_Client" then
		warn("Loading Folder...")
		local nameVal
		local origName
		local depsFolder
		local clientModule
		local oldChild = child
		local container = child.Parent

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
		warn(`Got name: {tostring(origName)}`)

		warn("Changing child parent...")
		child.Parent = nil

		warn("Destroying parent...")
		if container and container:IsA("ScreenGui") and container.Name == "Adonis_Container" then
			spawn(function()
				wait(0.5);
				container:Destroy();
			end)
		end

		if clientModule and clientModule:IsA("ModuleScript") then
			print("Debug: Loading the client?")
			local meta = require(clientModule)
			warn(`Got metatable: {tostring(meta)}`)
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

				warn(`Got return: {tostring(ret)}`)
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
						finderEvent = nil
					end
				end
			end
		end
	end
end

local function scan(folder)
	warn("Scanning for client...")
	if not doPcall(function()
		for i,child in folder:GetChildren() do
			if child.Name == "Adonis_Container" then
				local client = child:FindFirstChildOfClass("Folder") or child:WaitForChild("Adonis_Client", 5);
				if client then
					doPcall(checkChild, client);
				end
			end
		end
	end) then warn("Scan failed?") Kick(player, "ACLI: Loading Error [Scan failed]"); end
end

--// Load client

if _G.__CLIENTLOADER then
	warn("ClientLoader already running;");
else
	_G.__CLIENTLOADER = true;

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
		warn(`CoreGui Locked: {tostring(Locked(game:GetService("CoreGui")))}`)
	end

	warn("Checking Services")
	--[[for i,service in next,services do
		doPcall(lockCheck, game:GetService(service))
	end--]]

	warn("Waiting for PlayerGui...");
	local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 600);

	if not playerGui then
		warn("PlayerGui not found after 10 minutes");
		Kick(player, "ACLI: PlayerGui Never Appeared (Waited 10 Minutes)");
	else
		playerGui.Changed:Connect(function()
			if playerGui.Name ~= "PlayerGui" then
				playerGui.Name = "PlayerGui";
			end
		end)
	end

	finderEvent = playerGui.ChildAdded:Connect(function(child)
		warn("Child Added")
		if not foundClient and child.Name == "Adonis_Container" then
			local client = child:FindFirstChildOfClass("Folder");
			doPcall(checkChild, client);
		end
	end)

	warn("Waiting and scanning (incase event fails)...")
	repeat
		scan(playerGui);
		wait(5);
	until (time() - start > 600) or foundClient

	warn(`Elapsed: {tostring(time() - start)}`);
	warn(`Timeout: {tostring(time() - start > 600)}`);
	warn(`Found Client: {tostring(foundClient)}`);

	warn("Disconnecting finder event...");
	if finderEvent then
		finderEvent:Disconnect();
	end

	warn("Checking if client found...")
	if not foundClient then
		warn("Loading took too long")
		Kick(player, "\nACLI: [CLI-1162246] \nLoading Error [Took Too Long (>10 Minutes)]")
	else
		print("Debug: Adonis loaded?")
		warn("Client found")
		warn("Finished")
		warn(time())
	end
end
