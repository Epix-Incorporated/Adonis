-------------------
-- Adonis Server --
-------------------
--!nocheck
																																																																																						  --[[
This module is part of Adonis 1.0 and contains lots of old code;
future updates will generally only be made to fix bugs, typos or functionality-affecting problems.

If you find bugs or similar issues, please submit an issue report
on our GitHub repository here: https://github.com/Epix-Incorporated/Adonis/issues/new/choose
																																																																																						]]

--// Module LoadOrder List; Core modules need to be loaded in a specific order; If you create new "Core" modules make sure you add them here or they won't load
local CORE_LOADING_ORDER = table.freeze {
	--// Nearly all modules rely on these to function
	"Logs";
	"Variables";
	"Functions";

	--// Core functionality
	"Core";
	"Remote";
	"Process";

	--// Misc
	"Admin";
	"HTTP";
	"Anti";
	"Commands";
}

--// Todo:
--//   Fix a loooootttttttt of bugged commands
--//   Probably a lot of other stuff idk
--//   Transform from Sceleratis into Dr. Sceleratii; Evil alter-ego; Creator of bugs, destroyer of all code that is good
--//   Maybe add a celery command at some point (wait didn't we do this?)
--//   Say hi to people reading the script
--//   ...
--//   "Hi." - Me

--// Holiday roooaaAaaoooAaaooOod
local _G, game, script, getfenv, setfenv, workspace,
getmetatable, setmetatable, loadstring, coroutine,
rawequal, typeof, print, math, warn, error,  pcall,
xpcall, select, rawset, rawget, ipairs, pairs,
next, Rect, Axes, os, time, Faces, unpack, string, Color3,
newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
NumberSequenceKeypoint, PhysicalProperties, Region3int16,
Vector3int16, require, table, type, wait,
Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, spawn, delay, task, assert =
	_G, game, script, getfenv, setfenv, workspace,
getmetatable, setmetatable, loadstring, coroutine,
rawequal, typeof, print, math, warn, error,  pcall,
xpcall, select, rawset, rawget, ipairs, pairs,
next, Rect, Axes, os, time, Faces, table.unpack, string, Color3,
newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
NumberSequenceKeypoint, PhysicalProperties, Region3int16,
Vector3int16, require, table, type, task.wait,
Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, task.defer, task.delay, task, function(cond, errMsg) return cond or error(errMsg or "assertion failed!", 2) end;

local SERVICES_WE_USE = table.freeze {
	"Workspace";
	"Players";
	"Lighting";
	"ServerStorage";
	"ReplicatedStorage";
	"JointsService";
	"ReplicatedFirst";
	"ScriptContext";
	"ServerScriptService";
	"LogService";
	"Teams";
	"SoundService";
	"StarterGui";
	"StarterPack";
	"StarterPlayer";
	"GroupService";
	"MarketplaceService";
	"MarketplaceService";
	"TestService";
	"HttpService";
	"RunService";
	"InsertService";
	"NetworkServer";
}

local unique = {}
local origEnv = getfenv(); setfenv(1,setmetatable({}, {__metatable = unique}))
local locals = {}
local server = {}
local service = {}
local RbxEvents = {}
local ErrorLogs = {}
local HookedEvents = {}
local ServiceSpecific = {}
local oldReq = require
local Folder = script.Parent
local oldInstNew = Instance.new
local isModule = function(module)
	for ind, modu in pairs(server.Modules) do
		if module == modu then
			return true
		end
	end
	return false
end

local logError = function(plr, err)
	if type(plr) == "string" and not err then
		err = plr;
		plr = nil;
	end

	if server.Core and server.Core.DebugMode then
		warn("::Adonis:: Error: "..tostring(plr)..": "..tostring(err))
	end

	if server and server.Logs then
		server.Logs.AddLog(server.Logs.Errors, {
			Text = ((err and plr and tostring(plr) ..":") or "").. tostring(err),
			Desc = err,
			Player = plr
		})
	end
end

--local message = function(...) local Str = "" game:GetService("TestService"):Message(Str) end
local print = function(...)
	print(":: Adonis ::", ...)
end

local warn = function(...)
	warn(":: Adonis ::", ...)
end

--[[
local require = function(mod, ...)
	if mod and tonumber(mod) then
		warn("Requiring Module by ID; Expand for module URL > ", {URL = "https://www.roblox.com/library/".. moduleId})
	end

	return require(mod, ...)
end
--]]

local function CloneTable(tab, recursive)
	local clone = table.clone(tab)

	if recursive then
		for i,v in pairs(clone) do
			if type(v) == "table" then
				clone[i] = CloneTable(v, recursive)
			end
		end
	end

	return clone
end

local function Pcall(func, ...)
	local pSuccess, pError = pcall(func, ...)
	if not pSuccess then
		warn(pError)
		logError(pError)
	end

	return pSuccess, pError
end

local function cPcall(func, ...)
	return Pcall(function(...)
		return coroutine.resume(coroutine.create(func), ...)
	end, ...)
end

local function Routine(func, ...)
	return coroutine.resume(coroutine.create(func), ...)
end

local function GetEnv(env, repl)
	local scriptEnv = setmetatable({}, {
		__index = function(tab, ind)
			return (locals[ind] or (env or origEnv)[ind])
		end;

		__metatable = unique;
	})
	if repl and type(repl) == "table" then
		for ind, val in pairs(repl) do
			scriptEnv[ind] = val
		end
	end
	return scriptEnv
end

local function GetVargTable()
	return {
		Server = server;
		Service = service;
	}
end

local function LoadModule(module, yield, envVars, noEnv, isCore)
	noEnv = false --// Seems to make loading take longer when true (?)
	local isFunc = type(module) == "function"
	local module = (isFunc and service.New("ModuleScript", {Name = "Non-Module Loaded"})) or module
	local plug = (isFunc and module) or require(module)

	if server.Modules and type(module) ~= "function" then
		table.insert(server.Modules,module)
	end

	if type(plug) == "function" then
		if isCore then
			local ran,err = service.TrackTask("CoreModule: ".. tostring(module), plug, GetVargTable(), GetEnv)
			if not ran then
				warn("Core Module encountered an error while loading:", module)
				warn(err)
			else
				return err;
			end
		elseif yield then
			--Pcall(setfenv(plug,GetEnv(getfenv(plug), envVars)))
			local ran,err = service.TrackTask("Plugin: ".. tostring(module), (noEnv and plug) or setfenv(plug, GetEnv(getfenv(plug), envVars)), GetVargTable())
			if not ran then
				warn("Plugin Module encountered an error while loading:", module)
				warn(err)
			else
				return err;
			end
		else
			--service.Threads.RunTask("PLUGIN: "..tostring(module),setfenv(plug,GetEnv(getfenv(plug), envVars)))
			local ran, err = service.TrackTask("Thread: Plugin: ".. tostring(module), (noEnv and plug) or setfenv(plug, GetEnv(getfenv(plug), envVars)), GetVargTable())
			if not ran then
				warn("Plugin Module encountered an error while loading:", module)
				warn(err)
			else
				return err;
			end
		end
	else
		server[module.Name] = plug
	end

	if server.Logs then
		server.Logs.AddLog(server.Logs.Script,{
			Text = "Loaded Module: "..tostring(module);
			Desc = "Adonis loaded a core module or plugin";
		})
	end
end;

--// WIP
local function LoadPackage(package, folder, runNow)
	--// runNow - Run immediately after unpacking (default behavior is to just unpack (((only needed if loading after startup))))
	--// runNow currently not used (limitations) so all packages must be present at server startup
	local function unpackFolder(curFolder, unpackInto)
		if unpackInto then
			for _, obj in ipairs(curFolder:GetChildren()) do
				local clone = obj:Clone()
				if obj:IsA("Folder") then
					local realFolder = unpackInto:FindFirstChild(obj.Name)
					if not realFolder then
						clone.Parent = unpackInto
					else
						unpackFolder(obj, realFolder)
					end
				else
					clone.Parent = unpackInto
				end
			end
		else
			warn("Missing parent to unpack into for ".. tostring(curFolder))
		end
	end

	unpackFolder(package, folder)
end;

local function CleanUp()
	--local env = getfenv(2)
	--local ran,ret = pcall(function() return env.script:GetFullName() end)
	warn("Beginning Adonis cleanup & shutdown process...")
	--warn("CleanUp called from "..tostring((ran and ret) or "Unknown"))
	--local loader = server.Core.ClientLoader
	server.Model.Name = "Adonis_Loader"
	server.Model.Parent = service.ServerScriptService
	server.Running = false

	pcall(service.Threads.StopAll)
	pcall(function()
		for i, v in pairs(RbxEvents) do
			print("Disconnecting event")
			v:Disconnect()
			table.remove(RbxEvents, i)
		end
	end)
	--loader.Archivable = false
	--loader.Disabled = true
	--loader:Destroy()
	if server.Core and server.Core.RemoteEvent then
		pcall(server.Core.DisconnectEvent)
	end

	--[[delay(0, function()
		for i,v in next,server do
			server[i] = nil; --// Try to break it to prevent any potential hanging issues; Not very graceful...
		end
	--end)--]]

	warn("Unloading complete")
end;

server = {
	Running = true;
	Modules = {};
	Pcall = Pcall;
	cPcall = cPcall;
	Routine = Routine;
	LogError = logError;
	ErrorLogs = ErrorLogs;
	ServerStartTime = os.time();
	CommandCache = {};
};

locals = {
	server = server;
	CodeName = "";
	Settings = server.Settings;
	HookedEvents = HookedEvents;
	ErrorLogs = ErrorLogs;
	logError = logError;
	origEnv = origEnv;
	Routine = Routine;
	Folder = Folder;
	GetEnv = GetEnv;
	cPcall = cPcall;
	Pcall = Pcall;
};

service = require(Folder.Shared.Service)(function(eType, msg, desc, ...)
	local extra = {...}
	if eType == "MethodError" then
		if server and server.Logs and server.Logs.AddLog then
			server.Logs.AddLog("Script", {
				Text = "Cached method doesn't match found method: "..tostring(extra[1]);
				Desc = "Method: "..tostring(extra[1])
			})
		end
	elseif eType == "ServerError" then
		--print("Server error")
		logError("Server", msg)
	elseif eType == "TaskError" then
		--print("Task error")
		logError("Task", msg)
	end
end, function(c, parent, tab)
	if not isModule(c) and c ~= server.Loader and c ~= server.Dropper and c ~= server.Runner and c ~= server.Model and c ~= script and c ~= Folder and parent == nil then
		tab.UnHook()
	end
end, ServiceSpecific, GetEnv(nil, {server = server}))

--// Localize
os = service.Localize(os)
math = service.Localize(math)
table = service.Localize(table)
string = service.Localize(string)
coroutine = service.Localize(coroutine)
Instance = service.Localize(Instance)
Vector2 = service.Localize(Vector2)
Vector3 = service.Localize(Vector3)
CFrame = service.Localize(CFrame)
UDim2 = service.Localize(UDim2)
UDim = service.Localize(UDim)
Ray = service.Localize(Ray)
Rect = service.Localize(Rect)
Faces = service.Localize(Faces)
Color3 = service.Localize(Color3)
NumberRange = service.Localize(NumberRange)
NumberSequence = service.Localize(NumberSequence)
NumberSequenceKeypoint = service.Localize(NumberSequenceKeypoint)
ColorSequenceKeypoint = service.Localize(ColorSequenceKeypoint)
PhysicalProperties = service.Localize(PhysicalProperties)
ColorSequence = service.Localize(ColorSequence)
Region3int16 = service.Localize(Region3int16)
Vector3int16 = service.Localize(Vector3int16)
BrickColor = service.Localize(BrickColor)
TweenInfo = service.Localize(TweenInfo)
Axes = service.Localize(Axes)
task = service.Localize(task)

--// Wrap
Instance = {
	new = function(obj, parent)
		return oldInstNew(obj, service.UnWrap(parent))
	end
}

function require(obj)
	return oldReq(service.UnWrap(obj))
end
rawequal = service.RawEqual
--service.Players = service.Wrap(service.Players)
--Folder = service.Wrap(Folder)
server.Folder = Folder
server.Deps = Folder.Dependencies;
server.CommandModules = Folder.Commands;
server.Client = Folder.Parent.Client;
server.Dependencies = Folder.Dependencies;
server.PluginsFolder = Folder.Plugins;
server.Service = service

--// Setting things up
for ind, loc in pairs({
	_G = _G;
	game = game;
	spawn = spawn;
	script = script;
	getfenv = getfenv;
	setfenv = setfenv;
	workspace = workspace;
	getmetatable = getmetatable;
	setmetatable = setmetatable;
	loadstring = loadstring;
	coroutine = coroutine;
	rawequal = rawequal;
	typeof = typeof;
	print = print;
	math = math;
	warn = warn;
	error = error;
	assert = assert;
	pcall = pcall;
	xpcall = xpcall;
	select = select;
	rawset = rawset;
	rawget = rawget;
	ipairs = ipairs;
	pairs = pairs;
	next = next;
	Rect = Rect;
	Axes = Axes;
	os = os;
	time = time;
	Faces = Faces;
	unpack = unpack;
	string = string;
	Color3 = Color3;
	newproxy = newproxy;
	tostring = tostring;
	tonumber = tonumber;
	Instance = Instance;
	TweenInfo = TweenInfo;
	BrickColor = BrickColor;
	NumberRange = NumberRange;
	ColorSequence = ColorSequence;
	NumberSequence = NumberSequence;
	ColorSequenceKeypoint = ColorSequenceKeypoint;
	NumberSequenceKeypoint = NumberSequenceKeypoint;
	PhysicalProperties = PhysicalProperties;
	Region3int16 = Region3int16;
	Vector3int16 = Vector3int16;
	require = require;
	table = table;
	type = type;
	wait = wait;
	Enum = Enum;
	UDim = UDim;
	UDim2 = UDim2;
	Vector2 = Vector2;
	Vector3 = Vector3;
	Region3 = Region3;
	CFrame = CFrame;
	Ray = Ray;
	task = task;
	service = service
	})
do
	locals[ind] = loc
end

--// Init
return service.NewProxy({
	__call = function(tab, data)
		local mutex = service.RunService:FindFirstChild("__Adonis_MODULE_MUTEX")
		if mutex then
			warn("\n-----------------------------------------------"
				.."\nAdonis server-side is already running! Aborting..."
				.."\n-----------------------------------------------")
			script:Destroy()
			return "FAILED"
		else
			mutex = service.New("StringValue", {Name = "__Adonis_MODULE_MUTEX", Value = "Running"})
			local mutexBackup = mutex:Clone()
			local function makePersistent(m)
				local connection1, connection2 = nil, nil
				connection1 = m:GetPropertyChangedSignal("Parent"):Connect(function()
					if not m or m.Parent ~= service.RunService then
						connection1:Disconnect()
						connection2:Disconnect()
						warn("Adonis module mutex removed; Regenerating...")
						makePersistent(mutexBackup)
						mutexBackup.Parent = service.RunService
						mutexBackup = mutexBackup:Clone()
					end
				end)
				connection2 = m:GetPropertyChangedSignal("Name"):Connect(function()
					if m and m.Name ~= "__Adonis_MODULE_MUTEX" then
						warn("Adonis module mutex renamed; Refreshing...")
						m.Name = "__Adonis_MODULE_MUTEX"
					end
				end)
			end
			makePersistent(mutex)
			mutex.Parent = service.RunService
		end

		--// Begin Script Loading
		setfenv(1, setmetatable({}, {__metatable = unique}))
		data = service.Wrap(data or {})

		if not (data and data.Loader) then
			warn("WARNING: MainModule loaded without using the loader!")
		end

		if data and data.ModuleID == 8612978896 then
			warn("Currently using Adonis Nightly MainModule; intended for testing & development only!")
		end

		--// Server Variables
		local setTab = require(server.Deps.DefaultSettings)
		server.Defaults = setTab
		server.Settings = data.Settings or setTab.Settings or {}
		server.OriginalSettings = CloneTable(server.Settings, true)
		server.Descriptions = data.Descriptions or setTab.Descriptions or {}
		server.Messages = data.Messages or setTab.Settings.Messages or {}
		server.Order = data.Order or setTab.Order or {}
		server.Data = data or {}
		server.Model = data.Model or service.New("Model")
		server.ModelParent = data.ModelParent or service.ServerScriptService;
		server.Dropper = data.Dropper or service.New("Script")
		server.Loader = data.Loader or service.New("Script")
		server.Runner = data.Runner or service.New("Script")
		server.LoadModule = LoadModule
		server.LoadPackage = LoadPackage
		server.ServiceSpecific = ServiceSpecific

		server.Shared = Folder.Shared
		server.ServerPlugins = data.ServerPlugins
		server.ClientPlugins = data.ClientPlugins
		server.Client = Folder.Parent.Client

		locals.Settings = server.Settings
		locals.CodeName = server.CodeName

		--// THIS NEEDS TO BE DONE **BEFORE** ANY EVENTS ARE CONNECTED
		if server.Settings.HideScript and data.Model then
			data.Model.Parent = nil
			script:Destroy()
		end

		--// Copy client themes, plugins, and shared modules to the client folder
		local packagesToRunWithPlugins = {}
		local shared = service.New("Folder", {
			Name = "Shared";
			Parent = server.Client;
		})

		for _, module in ipairs(Folder.Shared:GetChildren()) do
			module:Clone().Parent = shared
		end

		for _, module in pairs(data.ClientPlugins or {}) do
			module:Clone().Parent = server.Client.Plugins
		end

		for _, theme in pairs(data.Themes or {}) do
			theme:Clone().Parent = server.Client.UI
		end

		for _, pkg in pairs(data.Packages or {}) do
			LoadPackage(pkg, Folder.Parent, false)
		end

		for setting, value in pairs(server.Defaults.Settings) do
			if server.Settings[setting] == nil then
				server.Settings[setting] = value
			end
		end

		for desc, value in pairs(server.Defaults.Descriptions) do
			if server.Descriptions[desc] == nil then
				server.Descriptions[desc] = value
			end
		end

		--// Bind cleanup
		service.DataModel:BindToClose(CleanUp)
		--server.CleanUp = CleanUp;

		--// Require some dependencies
		server.Typechecker = require(server.Shared.Typechecker)
		server.Threading = require(server.Deps.ThreadHandler)
		server.Changelog = require(server.Shared.Changelog)
		server.Credits = require(server.Shared.Credits)
		do
			local MaterialIcons = require(server.Shared.MatIcons)
			server.MatIcons = setmetatable({}, {
				__index = function(self, ind)
					local materialIcon = MaterialIcons[ind]
					if materialIcon then
						self[ind] = "rbxassetid://"..materialIcon
						return self[ind]
					end
					return ""
				end,
				__metatable = "Adonis_MatIcons"
			})
		end


		--// Load services
		for ind, serv in ipairs(SERVICES_WE_USE) do
			local temp = service[serv]
		end

		--// Load core modules
		for _, load in ipairs(CORE_LOADING_ORDER) do
			local CoreModule = Folder.Core:FindFirstChild(load)
			if CoreModule then
				LoadModule(CoreModule, true, nil, nil, true) --noenv, CoreModule
			end
		end

		--// Server Specific Service Functions
		ServiceSpecific.GetPlayers = server.Functions.GetPlayers
		--// Experimental, may have issues with Adonis tables that are protected metatables
		--ServiceSpecific.CloneTable = CloneTable

		--// Initialize Cores
		local runLast = {}
		local runAfterInit = {}
		local runAfterPlugins = {}

		for _, name in ipairs(CORE_LOADING_ORDER) do
			local core = server[name]

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

					if core.Init then
						core.Init(data)
						core.Init = nil
					end
				end
			end
		end

		--// Variables that rely on core modules being initialized
		server.Logs.Errors = ErrorLogs

		--// Load any afterinit functions from modules (init steps that require other modules to have finished loading)
		for _, f in pairs(runAfterInit) do
			f(data)
		end

		--// Load Plugins; enforced NoEnv policy, make sure your plugins has the 2nd argument defined!
		for _, module in ipairs(server.PluginsFolder:GetChildren()) do
			LoadModule(module, false, {script = module}, true, true) --noenv
		end

		for _, module in pairs(data.ServerPlugins or {}) do
			LoadModule(module, false, {script = module})
		end

		--// We need to do some stuff *after* plugins are loaded (in case we need to be able to account for stuff they may have changed before doing something, such as determining the max length of remote commands)
		for _, f in pairs(runAfterPlugins) do
			f(data)
		end

		--// Below can be used to determine when all modules and plugins have finished loading; service.Events.AllModulesLoaded:Connect(function() doSomething end)
		server.AllModulesLoaded = true
		service.Events.AllModulesLoaded:Fire(os.time())

		--// Queue handler
		--service.StartLoop("QueueHandler","Heartbeat",service.ProcessQueue)

		--// Stuff to run after absolutely everything else has had a chance to run and initialize and all that
		for _, f in pairs(runLast) do
			f(data)
		end

		if data.Loader then
			warn("Loading Complete; Required by "..tostring(data.Loader:GetFullName()))
		else
			warn("Loading Complete; No loader location provided")
		end

		if server.Logs then
			server.Logs.AddLog(server.Logs.Script, {
				Text = "Finished Loading";
				Desc = "Adonis has finished loading";
			})
		else
			warn("SERVER.LOGS TABLE IS MISSING. THIS SHOULDN'T HAPPEN! SOMETHING WENT WRONG WHILE LOADING CORE MODULES(?)");
		end
		service.Events.ServerInitialized:Fire();

		return "SUCCESS"
	end;
	__tostring = function()
		return "Adonis"
	end;
	__metatable = "Adonis";
})
