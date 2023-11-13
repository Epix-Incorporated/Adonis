-------------------
-- Adonis Client --
-------------------
--!nocheck
																																																																																						  --[[
This module is part of Adonis 1.0 and contains lots of old code;
future updates will generally only be made to fix bugs, typos or functionality-affecting problems.

If you find bugs or similar issues, please submit an issue report to us!

]]
--// Load Order List
local CORE_LOADING_ORDER = table.freeze({
	--// Required by most modules
	"Variables",
	"Functions",

	--// Core functionality
	"Core",
	"Remote",
	"UI",
	"Process",

	--// Misc
	"Anti",
})

--// Loccalllsssss
local _G, game, script, getfenv, setfenv, workspace, getmetatable, setmetatable, loadstring, coroutine, rawequal, typeof, print, math, warn, error, pcall, xpcall, select, rawset, rawget, ipairs, pairs, next, Rect, Axes, os, time, Faces, unpack, string, Color3, newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor, NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint, NumberSequenceKeypoint, PhysicalProperties, Region3int16, Vector3int16, require, table, type, wait, Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay, spawn, task, tick, assert =
	_G,
game,
script,
getfenv,
setfenv,
workspace,
getmetatable,
setmetatable,
loadstring,
coroutine,
rawequal,
typeof,
print,
math,
warn,
error,
pcall,
xpcall,
select,
rawset,
rawget,
ipairs,
pairs,
next,
Rect,
Axes,
os,
time,
Faces,
table.unpack,
string,
Color3,
newproxy,
tostring,
tonumber,
Instance,
TweenInfo,
BrickColor,
NumberRange,
ColorSequence,
NumberSequence,
ColorSequenceKeypoint,
NumberSequenceKeypoint,
PhysicalProperties,
Region3int16,
Vector3int16,
require,
table,
type,
task.wait,
Enum,
UDim,
UDim2,
Vector2,
Vector3,
Region3,
CFrame,
Ray,
task.delay,
task.defer,
task,
tick,
function(cond, errMsg)
	return cond or error(errMsg or "assertion failed!", 2)
end

local SERVICES_WE_USE = table.freeze({
	"Workspace",
	"Players",
	"Lighting",
	"ReplicatedStorage",
	"ReplicatedFirst",
	"ScriptContext",
	"JointsService",
	"LogService",
	"Teams",
	"SoundService",
	"StarterGui",
	"StarterPack",
	"StarterPlayer",
	"GroupService",
	"MarketplaceService",
	"HttpService",
	"TestService",
	"RunService",
	"NetworkClient",
})

--// Logging
local clientLog = {}
local dumplog = function()
	warn(":: Adonis :: Dumping client log...")

	for _, v in clientLog do
		warn(":: Adonis ::", v)
	end
end
local log = function(...)
	table.insert(clientLog, table.concat({ ... }, " "))
end

--// Dump log on disconnect
local isStudio = game:GetService("RunService"):IsStudio()
game:GetService("NetworkClient").ChildRemoved:Connect(function(p)
	if not isStudio then
		warn("~! PLAYER DISCONNECTED/KICKED! DUMPING ADONIS CLIENT LOG!")
		dumplog()
	end
end)

local unique = {}
local origEnv = getfenv()
local Folder = script.Parent
setfenv(1, setmetatable({}, { __metatable = unique }))
--local origWarn = warn
local startTime = time()
local oldInstNew = Instance.new
local oldReq = require
local locals = {}
local client = {}
local service = {}
local ServiceSpecific = {}

local function isModule(module)
	for _, modu in client.Modules do
		if rawequal(module, modu) then
			return true
		end
	end
	return false
end

local function logError(...)
	warn("ERROR: ", ...)

	if client and client.Remote then
		client.Remote.Send("LogError", table.concat({ ... }, " "))
	end
end

local oldPrint = print
print = function(...)
	oldPrint(":: Adonis ::", ...)
end

--[[
local warn = function(...)
	warn(...)
end
]]
-- Use `task.spawn(pcall, ...)`, `task.spawn(Pcall, f, ...)` or `task.spawn(xpcall, f, handler, ...)` instead
local cPcall = function(func, ...)
	local ran, err = pcall(coroutine.resume, coroutine.create(func), ...)

	if err then
		warn(":: ADONIS_ERROR ::", err)
		logError(tostring(err))
	end

	return ran, err
end

local Pcall = function(func, ...)
	local ran, err = pcall(func, ...)

	if err then
		logError(tostring(err))
	end

	return ran, err
end

local Routine = function(func, ...)
	return coroutine.resume(coroutine.create(func), ...)
end

local Immutable = function(...)
	local mut = coroutine.wrap(function(...)
		while true do
			coroutine.yield(...)
		end
	end)
	mut(...)
	return mut
end

local Kill
local Fire, Detected = nil, nil
do
	Kill = Immutable(function(info)
		--if true then print(info or "SOMETHING TRIED TO CRASH CLIENT?") return end
		spawn(pcall, function()
			if Detected then
				Detected("kick", info)
			elseif Fire then
				Fire("BadMemes", info)
			end
		end)

		spawn(pcall, function()
			task.wait(1)
			service.Player:Kick(info)
		end)
		
		if not isStudio then
			spawn(pcall, function()
				task.wait(5)
				while true do
					pcall(task.spawn, function()
						task.spawn(Kill())
						-- memes
					end)
				end
			end)
		end
	end)
end

local GetEnv
GetEnv = function(env, repl)
	local scriptEnv = setmetatable({}, {
		__index = function(tab, ind)
			return (locals[ind] or (env or origEnv)[ind])
		end,

		__metatable = if Folder:FindFirstChild("ADONIS_DEBUGMODE_ENABLED") then nil else unique,
	})

	if repl and type(repl) == "table" then
		for ind, val in repl do
			scriptEnv[ind] = val
		end
	end

	return scriptEnv
end

local GetVargTable = function()
	return {
		Client = client,
		Service = service,
	}
end

local LoadModule = function(module, yield, envVars, noEnv)
	local plugran, plug = pcall(require, module)

	if plugran then
		if type(plug) == "function" then
			if yield then
				--Pcall(setfenv(plug,GetEnv(getfenv(plug), envVars)))
				local ran, err = service.TrackTask(
					`Plugin: {module}`,
					(noEnv and plug) or setfenv(plug, GetEnv(getfenv(plug), envVars)),
					function(err)
						warn(`Module encountered an error while loading: {module}\n{err}\n{debug.traceback()}`)
					end,
					GetVargTable(),
					GetEnv
				)
			else
				-- service.Threads.RunTask(`PLUGIN: {module,setfenv(plug,GetEnv(getfenv(plug), envVars))}`)
				local ran, err = service.TrackTask(
					`Thread: Plugin: {module}`,
					(noEnv and plug) or setfenv(plug, GetEnv(getfenv(plug), envVars)),
					function(err)
						warn(`Module encountered an error while loading: {module}\n{err}\n{debug.traceback()}`)
					end,
					GetVargTable(),
					GetEnv
				)
			end
		else
			client[module.Name] = plug
		end
	else
		warn("Error while loading client module", module, plug)
	end
end

log("Client setmetatable")

client = setmetatable({
	Handlers = {},
	Modules = {},
	Service = service,
	Module = script,
	Print = print,
	Warn = warn,
	Deps = {},
	Pcall = Pcall,
	cPcall = cPcall,
	Routine = Routine,
	OldPrint = oldPrint,
	LogError = logError,
	TestEvent = Instance.new("RemoteEvent"),

	Disconnect = function(info)
		service.Player:Kick(info or "Disconnected from server")
		--wait(30)
		--client.Kill()(info)
	end,

	--Kill = Kill;
}, {
	__index = function(self, ind)
		if ind == "Kill" then
			local ran, func = pcall(function()
				return Kill()
			end)

			if not ran or type(func) ~= "function" then
				service.Players.LocalPlayer:Kick("Adonis (PlrClientIndexKlErr)")
				while true do
				end
			end

			return func
		end
	end,
})

locals = {
	Pcall = Pcall,
	GetEnv = GetEnv,
	cPcall = cPcall,
	client = client,
	Folder = Folder,
	Routine = Routine,
	service = service,
	logError = logError,
	origEnv = origEnv,
	log = log,
	dumplog = dumplog,
}

log("Create service metatable")

service = require(Folder.Shared.Service)(function(eType, msg, desc, ...)
	--warn(eType, msg, desc, ...)
	local extra = { ... }
	if eType == "MethodError" then
		--Kill()("Shananigans denied")
		--player:Kick("Method error")
		--service.Detected("kick", "Method change detected")
		logError("Client", `Method Error Occured: {msg}`)
	elseif eType == "ServerError" then
		logError("Client", tostring(msg))
	elseif eType == "ReadError" then
		--message("===== READ ERROR:::::::")
		--message(tostring(msg))
		--message(tostring(desc))
		--message("    ")

		Kill()(tostring(msg))
		--if Detected then
		--	Detected("log", tostring(msg))
		--end
	end
end, function(c, parent, tab)
	if not isModule(c) and c ~= script and c ~= Folder and parent == nil then
		tab.UnHook()
	end
end, ServiceSpecific, GetEnv(nil, { client = client }))

--// Localize
log("Localize")
local Localize = service.Localize
os = Localize(os)
math = Localize(math)
table = Localize(table)
string = Localize(string)
coroutine = Localize(coroutine)
Instance = Localize(Instance)
Vector2 = Localize(Vector2)
Vector3 = Localize(Vector3)
CFrame = Localize(CFrame)
UDim2 = Localize(UDim2)
UDim = Localize(UDim)
Ray = Localize(Ray)
Rect = Localize(Rect)
Faces = Localize(Faces)
Color3 = Localize(Color3)
NumberRange = Localize(NumberRange)
NumberSequence = Localize(NumberSequence)
NumberSequenceKeypoint = Localize(NumberSequenceKeypoint)
ColorSequenceKeypoint = Localize(ColorSequenceKeypoint)
PhysicalProperties = Localize(PhysicalProperties)
ColorSequence = Localize(ColorSequence)
Region3int16 = Localize(Region3int16)
Vector3int16 = Localize(Vector3int16)
BrickColor = Localize(BrickColor)
TweenInfo = Localize(TweenInfo)
Axes = Localize(Axes)
task = Localize(task)

--// Wrap
log("Wrap")

local service_Wrap = service.Wrap
local service_UnWrap = service.UnWrap

for i, val in service do
	if type(val) == "userdata" then
		service[i] = service_Wrap(val, true)
	end
end

--// Folder Wrap
Folder = service_Wrap(Folder, true)

--// Global Wrapping
Enum = service_Wrap(Enum, true)
rawequal = service.RawEqual
script = service_Wrap(script, true)
game = service_Wrap(game, true)
workspace = service_Wrap(workspace, true)
Instance = {
	new = function(obj, parent)
		return service_Wrap(oldInstNew(obj, service_UnWrap(parent)), true)
	end,
}
require = function(obj, noWrap: boolean?)
	return if noWrap == true then oldReq(service_UnWrap(obj)) else service_Wrap(oldReq(service_UnWrap(obj)), true)
end

client.Service = service
client.Module = service_Wrap(client.Module, true)

--// Setting things up
log("Setting things up")
for ind, loc in
	{
		_G = _G,
		game = game,
		spawn = spawn,
		script = script,
		getfenv = getfenv,
		setfenv = setfenv,
		workspace = workspace,
		getmetatable = getmetatable,
		setmetatable = setmetatable,
		loadstring = loadstring,
		coroutine = coroutine,
		rawequal = rawequal,
		typeof = typeof,
		print = print,
		math = math,
		warn = warn,
		error = error,
		assert = assert,
		pcall = pcall,
		xpcall = xpcall,
		select = select,
		rawset = rawset,
		rawget = rawget,
		ipairs = ipairs,
		pairs = pairs,
		next = next,
		Rect = Rect,
		Axes = Axes,
		os = os,
		time = time,
		Faces = Faces,
		delay = delay,
		unpack = unpack,
		string = string,
		Color3 = Color3,
		newproxy = newproxy,
		tostring = tostring,
		tonumber = tonumber,
		Instance = Instance,
		TweenInfo = TweenInfo,
		BrickColor = BrickColor,
		NumberRange = NumberRange,
		ColorSequence = ColorSequence,
		NumberSequence = NumberSequence,
		ColorSequenceKeypoint = ColorSequenceKeypoint,
		NumberSequenceKeypoint = NumberSequenceKeypoint,
		PhysicalProperties = PhysicalProperties,
		Region3int16 = Region3int16,
		Vector3int16 = Vector3int16,
		require = require,
		table = table,
		type = type,
		wait = wait,
		Enum = Enum,
		UDim = UDim,
		UDim2 = UDim2,
		Vector2 = Vector2,
		Vector3 = Vector3,
		Region3 = Region3,
		CFrame = CFrame,
		Ray = Ray,
		task = task,
		tick = tick,
		service = service,
	}
do
	locals[ind] = loc
end

--// Init
log("Return init function")
return service.NewProxy({
	__call = function(self, data)
		log("Begin init")

		local remoteName, depsName = string.match(data.Name, "(.*)\\(.*)")
		Folder = service.Wrap(data.Folder --[[or folder and folder:Clone()]] or Folder)

		if Folder:FindFirstChild("ADONIS_DEBUGMODE_ENABLED") then
			data.DebugMode = true
		else
			data.DebugMode = false
		end

		setfenv(1, setmetatable({}, { __metatable = unique }))

		client.Folder = Folder
		client.UIFolder = Folder:WaitForChild("UI", 9e9)
		client.Shared = Folder:WaitForChild("Shared", 9e9)

		client.Loader = data.Loader
		client.Module = data.Module
		client.DepsName = depsName
		client.TrueStart = data.Start
		client.LoadingTime = data.LoadingTime
		client.RemoteName = remoteName
		client.DebugMode = data.DebugMode

		client.Typechecker = oldReq(service_UnWrap(client.Shared.Typechecker))
		client.Changelog = oldReq(service_UnWrap(client.Shared.Changelog))
		do
			local MaterialIcons = oldReq(service_UnWrap(client.Shared.MatIcons))
			client.MatIcons = setmetatable({}, {
				__index = function(self, ind)
					local materialIcon = MaterialIcons[ind]
					if materialIcon then
						self[ind] = `rbxassetid://{materialIcon}`
						return self[ind]
					end
				end,
				__metatable = if not data.DebugMode then "Adonis" else unique,
			})
		end

		--// Toss deps into a table so we don't need to directly deal with the Folder instance they're in
		log("Get dependencies")
		for _, obj in Folder:WaitForChild("Dependencies", 9e9):GetChildren() do
			client.Deps[obj.Name] = obj
		end

		--// Do this before we start hooking up events
		log("Destroy script object")
		--folder:Destroy()
		script.Parent = nil --script:Destroy()

		--// Intial setup
		log("Initial services caching")
		for _, serv in SERVICES_WE_USE do
			local _ = service[serv]
		end

		--// Client specific service variables/functions
		log("Add service specific")
		ServiceSpecific.Player = service.Players.LocalPlayer
			or (function()
				service.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
				return service.Players.LocalPlayer
			end)()
		ServiceSpecific.PlayerGui = ServiceSpecific.Player:FindFirstChildWhichIsA("PlayerGui")
		if not ServiceSpecific.PlayerGui then
			Routine(function()
				local PlayerGui = ServiceSpecific.Player:WaitForChild("PlayerGui", 120)
				if not PlayerGui then
					logError("PlayerGui unable to be fetched? [Waited 120 Seconds]")
					return
				end
				ServiceSpecific.PlayerGui = PlayerGui
			end)
		end

		--[[
		-- // Doesn't seem to be used anymore

		ServiceSpecific.SafeTweenSize = function(obj, ...)
			pcall(obj.TweenSize, obj, ...)
		end;
		ServiceSpecific.SafeTweenPos = function(obj, ...)
			pcall(obj.TweenPosition, obj, ...)
		end;
		]]

		ServiceSpecific.Filter = function(str, from, to)
			return client.Remote.Get("Filter", str, (to and from) or service.Player, to or from)
		end
		ServiceSpecific.LaxFilter = function(str, from)
			return service.Filter(str, from or service.Player, from or service.Player)
		end
		ServiceSpecific.BroadcastFilter = function(str, from)
			return client.Remote.Get("BroadcastFilter", str, from or service.Player)
		end

		ServiceSpecific.IsMobile = function()
			return service.UserInputService.TouchEnabled
				and not service.UserInputService.MouseEnabled
				and not service.UserInputService.KeyboardEnabled
		end

		ServiceSpecific.LocalContainer = function()
			local Variables = client.Variables
			if not (Variables.LocalContainer and Variables.LocalContainer.Parent) then
				Variables.LocalContainer = service.New("Folder", {
					Parent = workspace,
          Archivable = false,
					Name = `__ADONIS_LOCALCONTAINER_{service.HttpService:GenerateGUID(false)}`,
				})
			end
			return Variables.LocalContainer
		end

		ServiceSpecific.IncognitoPlayers = {}

		--// Load Core Modules
		log("Loading core modules")
		for _, load in CORE_LOADING_ORDER do
			local modu = Folder.Core:FindFirstChild(load)
			if modu then
				log(`~! Loading Core Module: {load}`)
				LoadModule(modu, true, { script = script }, true)
			end
		end

		--// Start of module loading and server connection process
		local runLast = {}
		local runAfterInit = {}
		local runAfterLoaded = {}
		local runAfterPlugins = {}

		--// Loading Finisher
		client.Finish_Loading = function()
			log("Client fired finished loading")
			if client.Core.Key then
				--// Run anything from core modules that needs to be done after the client has finished loading
				log("~! Doing run after loaded")
				for _, f in runAfterLoaded do
					Pcall(f, data)
				end

				--// Stuff to run after absolutely everything else
				log("~! Doing run last")
				for _, f in runLast do
					Pcall(f, data)
				end

				--// Finished loading
				log("Finish loading")
				client.Finish_Loading = function() end
				client.LoadingTime() --origWarn(tostring(time()-(client.TrueStart or startTime)))
				service.Events.FinishedLoading:Fire(os.time())

				log("~! FINISHED LOADING!")
			else
				log("Client missing remote key")
				client.Kill()("Missing remote key")
			end
		end

		--// Initialize Cores
		log("~! Init cores")
		for _, name in CORE_LOADING_ORDER do
			local core = client[name]
			log(`~! INIT: {name}`)

			if core then
				if type(core) == "table" or (type(core) == "userdata" and getmetatable(core) == "ReadOnly_Table") then
					if core.RunLast then
						table.insert(runLast, core.RunLast)
						core.RunLast = nil
					end

					if core.RunAfterInit then
						table.insert(runAfterInit, core.RunAfterInit)
						core.RunAfterInit = nil
					end

					if core.RunAfterPlugins then
						table.insert(runAfterPlugins, core.RunAfterPlugins)
						core.RunAfterPlugins = nil
					end

					if core.RunAfterLoaded then
						table.insert(runAfterLoaded, core.RunAfterLoaded)
						core.RunAfterLoaded = nil
					end

					if core.Init then
						log(`Run init for {name}`)
						Pcall(core.Init, data)
						core.Init = nil
					end
				end
			end
		end

		--// Load any afterinit functions from modules (init steps that require other modules to have finished loading)
		log("~! Running after init")
		for _, f in runAfterInit do
			Pcall(f, data)
		end

		--// Load Plugins
		log("~! Running plugins")
		for _, module in Folder.Plugins:GetChildren() do
			--// Pass example/README plugins.
			if module.Name == "README" then
				continue
			end

			LoadModule(module, false, { script = module }) --noenv
		end

		--// We need to do some stuff *after* plugins are loaded (in case we need to be able to account for stuff they may have changed before doing something, such as determining the max length of remote commands)
		log("~! Running after plugins")
		for _, f in runAfterPlugins do
			Pcall(f, data)
		end

		log("Initial loading complete")

		--// Below can be used to determine when all modules and plugins have finished loading; service.Events.AllModulesLoaded:Connect(function() doSomething end)
		client.AllModulesLoaded = true
		service.Events.AllModulesLoaded:Fire(os.time())

		--[[client = service.ReadOnly(client, {
			[client.Variables] = true;
			[client.Handlers] = true;
			G_API = true;
			G_Access = true;
			G_Access_Key = true;
			G_Access_Perms = true;
			Allowed_API_Calls = true;
			HelpButtonImage = true;
			Finish_Loading = true;
			RemoteEvent = true;
			ScriptCache = true;
			Returns = true;
			PendingReturns = true;
			EncodeCache = true;
			DecodeCache = true;
			Received = true;
			Sent = true;
			Service = true;
			Holder = true;
			GUIs = true;
			LastUpdate = true;
			RateLimits = true;

			Init = true;
			RunAfterInit = true;
			RunAfterLoaded = true;
			RunAfterPlugins = true;
		}, true)--]]

		service.Events.ClientInitialized:Fire()

		log("~! Return success")
		return "SUCCESS"
	end,
	__metatable = if not Folder:FindFirstChild("ADONIS_DEBUGMODE_ENABLED") then "Adonis" else unique,
	__tostring = function()
		return "Adonis"
	end,
})
