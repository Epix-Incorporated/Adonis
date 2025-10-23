-------------------
-- Adonis Server --
-------------------
--!nocheck
																																																																																						  --[[
This module is part of Adonis 1.0 and contains lots of old code;
future updates will generally only be made to fix bugs, typos or functionality-affecting problems.

If you find bugs or similar issues, please submit an issue report
on our GitHub repository.
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
--//	Your mom

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
		warn(`::Adonis:: Error: {plr}: {err}`)
	end

	if server and server.Logs then
		server.Logs.AddLog(server.Logs.Errors, {
			Text = ((err and plr and tostring(plr) ..":") or "").. tostring(err),
			Desc = err,
			Player = plr
		})
	end
end

local print = function(...)
	print(":: Adonis ::", ...)
end

local warn = function(...)
	warn(":: Adonis ::", ...)
end

local function Pcall(func, ...)
	local pSuccess, pError = pcall(func, ...)
	if not pSuccess then
		warn(pError)
		logError(pError)
	end

	return pSuccess, pError
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
	local isRaw = type(module) == "string"
	local isValue = not isFunc and not isRaw and module:IsA("StringValue")
	local module = (isFunc and service.New("ModuleScript", {Name = "Non-Module Loaded"})) or module
	local plug = (isFunc and module) or isValue and (server.Core.LoadCode or function(...) return require(server.Shared.FiOne)(...) end)(server.Functions.Base64Decode(module.Value), GetEnv({}, envVars)) or isRaw and assert(assert(server.Core.Loadstring, "Cannot compile plugin due to Core.Loadstring missing")(module, GetEnv({}, envVars)), "Failed to compile module")() or require(module)

	if server.Modules and not isFunc and not isRaw then
		table.insert(server.Modules,module)
	end

	if type(plug) == "function" then
		if isCore then
			local ran, err = service.TrackTask(
				`CoreModule: {module}`,
				((noEnv or isRaw or isValue) and plug) or setfenv(plug, GetEnv(getfenv(plug), envVars)),
				function(err)
					warn(`Module encountered an error while loading: {module}\n{err}\n{debug.traceback()}`)
				end,
				GetVargTable(),
				GetEnv
			)
			return err
		else
			local ran, err = service.TrackTask(
				`Plugin: {module}`,
				((noEnv or isRaw or isValue) and plug) or setfenv(plug, GetEnv(getfenv(plug), envVars)),
				function(err)
					warn(`Module encountered an error while loading: {module}\n{err}\n{debug.traceback()}`)
				end,
				GetVargTable()
			)
			return err
		end
	else
		server[module.Name] = plug
	end

	if server.Logs then
		server.Logs.AddLog(server.Logs.Script,{
			Text = `Loaded Module: {module}`;
			Desc = "Adonis loaded a core module or plugin";
		})
	end
end

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
			warn(`Missing parent to unpack into for {curFolder}`)
		end
	end

	unpackFolder(package, folder)
end;

local function CleanUp(reason)
	if not server.Data or not server.Data.SilentStartup then
		print(`Beginning Adonis cleanup & shutdown process due to {reason}...`)
	end

	local data = service.UnWrap(server.Data)
	if type(data) == "table" and typeof(service.UnWrap(data.Config)) == "Instance" then
		local Settings: ModuleScript = service.UnWrap(data.Config):FindFirstChild("Settings")
		if typeof(Settings) == "Instance" and Settings:IsA("ModuleScript") then
			pcall(function()
				table.clear(require(Settings))
			end)
		end
	end

	server.Model.Name = "Adonis_Loader"
	server.Model.Parent = service.ServerScriptService
	server.Running = false

	server.Logs.SaveCommandLogs()
	server.Core.GAME_CLOSING = true;
	server.Core.SaveAllPlayerData()

	pcall(service.Threads.StopAll)
	pcall(function()
		for i, v in pairs(RbxEvents) do
			print("Disconnecting event")
			v:Disconnect()
			table.remove(RbxEvents, i)
		end
	end)
	if server.Core and server.Core.RemoteEvent then
		pcall(server.Core.DisconnectEvent)
	end

	if not server.Data or not server.Data.SilentStartup then
		print("Unloading complete")
	end
end;

-- TODO: Re-add codename to server but remove it from Variables and directly bake it in to the client too without a remote
server = {
	Running = true;
	Version = 0;
	Modules = {};
	Pcall = Pcall;
	Routine = Routine;
	LogError = logError;
	ErrorLogs = ErrorLogs;
	ServerStartTime = os.time();
};

locals = {
	server = server;
	Settings = server.Settings;
	HookedEvents = HookedEvents;
	ErrorLogs = ErrorLogs;
	logError = logError;
	origEnv = origEnv;
	Routine = Routine;
	Folder = Folder;
	GetEnv = GetEnv;
	Pcall = Pcall;
};

service = require(Folder.Parent.Shared.Service)(function(eType, msg, desc, ...)
	local extra = table.pack(...)
	if eType == "MethodError" then
		if server and server.Logs and server.Logs.AddLog then
			server.Logs.AddLog("Script", {
				Text = `Cached method doesn't match found method: {extra[1]}`;
				Desc = `Method: {extra[1]}`
			})
		end
	elseif eType == "ServerError" then
		logError("Server", msg)
	elseif eType == "TaskError" then
		logError("Task", msg)
	end
end, function(c, parent, tab)
	if not isModule(c) and c ~= server.Loader and c ~= server.Runner and c ~= server.Model and c ~= script and c ~= Folder and parent == nil then
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
						--warn("Adonis module mutex removed; Regenerating...")
						mutex = mutexBackup:Clone()
						mutex.Archivable = false
						mutex.Parent = service.RunService
						makePersistent(mutex)
					end
				end)
				connection2 = m:GetPropertyChangedSignal("Name"):Connect(function()
					pcall(function()
						if m and m.Name ~= "__Adonis_MODULE_MUTEX" then
							m.Name = "__Adonis_MODULE_MUTEX"
						end
					end)
				end)
			end
			makePersistent(mutex)
			mutex.Archivable = false
			mutex.Parent = service.RunService
		end

		--// Begin Script Loading
		data = service.Wrap(data or {}) or {}
		local silentStartup = data.SilentStartup or false

		if not data.Loader and not silentStartup then
			warn("WARNING: MainModule loaded without using the loader!")
		elseif data.Loader and not data.LoaderVersion and server.Model then
			data.LoaderVersion = server.Model:FindFirstChild("Version") and tonumber(server.Model.Version.Value)
		end

		if data.NightlyMode or data.ModuleID == 8612978896 then
			data.NightlyMode = true

			if not silentStartup then
				warn("Currently using Adonis Nightly MainModule; intended for testing & development only!")
			end
		end

		if data.NightlyMode then -- Wrap things that should be wrapped?
			for _, v in {"Folder", "Deps", "CommandModules", "Client", "Dependancies", "PluginsFolder"} do
				server[v] = service.Wrap(server[v])
			end
			locals.Folder = service.Wrap(locals.Folder)
		end

		if data.DebugMode == true then
			if not silentStartup then
				warn("Adonis was loaded with DebugMode enabled; This is intended for development use only, certain debug features intended for development use will be enabled, which can weaken Adonis's security in a production environment.")
			end

			local AdonisDebugEnabled = service.New("BoolValue")
			AdonisDebugEnabled.Name = "ADONIS_DEBUGMODE_ENABLED"
			AdonisDebugEnabled.Value = true
			AdonisDebugEnabled.Parent = Folder.Parent.Client
		end

		setfenv(1, setmetatable({}, {__metatable = unique}))

		--// Server Variables
		local setTab = require(server.Deps.DefaultSettings)
		server.Defaults = setTab
		server.Settings = data.Settings or setTab.Settings or {}
		server.OriginalSettings = service.DeepCopy(server.Settings, true)
		server.Descriptions = data.Descriptions or setTab.Descriptions or {}
		server.Messages = data.Messages or setTab.Settings.Messages or {}
		server.Order = data.Order or setTab.Order or {}
		server.Data = data
		server.Model = data.Model or service.New("Model")
		server.ModelParent = data.ModelParent or service.ServerScriptService;
		server.Loader = data.Loader or service.New("Script")
		server.Runner = data.Runner or service.New("Script")
		server.LoadModule = LoadModule
		server.LoadPackage = LoadPackage
		server.ServiceSpecific = ServiceSpecific

		server.Shared = Folder.Parent.Shared
		server.ServerPlugins = data.ServerPlugins
		server.ClientPlugins = data.ClientPlugins
		server.Client = Folder.Parent.Client

		locals.Settings = server.Settings

		--// THIS NEEDS TO BE DONE **BEFORE** ANY EVENTS ARE CONNECTED
		if server.Settings.HideScript and data.Model then
			data.Model.Parent = nil
			--script:Destroy() -- Unnecessary and potentially harmful?
		end

		--// Copy client themes and plugins modules to the client folder
		local packagesToRunWithPlugins = {}

		for _, module in ipairs(data.ClientPlugins or {}) do
			if type(module) ~= "string" then
				module:Clone().Parent = server.Client.Plugins
			end
		end

		if type(server.Settings.HiddenThemes) == "table" then
			for _, theme in ipairs(server.Client.UI:GetChildren()) do
				if table.find(server.Settings.HiddenThemes, theme.Name) then
					theme:SetAttribute("Hidden", true)
				end
			end
		end

		for _, theme in ipairs(data.Themes or {}) do
			if type(server.Settings.HiddenThemes) == "table" and table.find(server.Settings.HiddenThemes, theme.Name) then
				theme:SetAttribute("Hidden", true)
			end

			theme:Clone().Parent = server.Client.UI
		end

		for _, pkg in ipairs(data.Packages or {}) do
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

		--// Attempts to patch Settings.Prefix to fix issues
		if type(server.Settings.Prefix) == "table" then -- TODO: Move to backwards compatibility module?
			setmetatable(server.Settings.Prefix, {
				__concat = function(self, value)
					return `{self[1]}{value}`
				end,
				__tostring = function(self)
					return self[1]
				end,
				__index = string, -- Fix backwards compatibility for namecall usage of prefix
				__eq = function(self, v)
					return rawequal(self, v) or table.find(self, v) or service.CompareTables(self, v) or false
				end,
			})
		end

		--// Bind cleanup
		service.DataModel:BindToClose(function(...)
			server.CleanUp(...)
		end)
		server.CleanUp = CleanUp

		--// Require some dependencies
		server.Typechecker = require(server.Shared.Typechecker)
		server.Changelog = require(server.Shared.Changelog)
		server.Version = server.Changelog and tonumber(string.match(server.Changelog[1], "^%[?%w*:? ?[Vv]?(%d+)")) or server.Version -- Set server version from changelog
		server.Credits = require(server.Shared.Credits)
		server.DLL = require(server.Shared.DoubleLinkedList)
		server.FormattedChangelog = table.create(#server.Changelog)

		--// Create formatted changelog from standard changelog
	  	local function applyColour(line)
			local prefix = line:sub(1, 2)

  	  	  	if prefix == "[v" or prefix == "[1" or prefix == "[0" or prefix == "1." or line:sub(1, 1) == "v" then
      	  	  	return `<font color='#8FAEFF'>{line}</font>`
  	  	  	elseif line:sub(1, 6) == "[Patch" then
  	  	  	  	return `<font color='#F0B654'>{line}</font>`
  	  	  	elseif line:sub(1, 9) == "Version: " then
				return `<b>{line}</b>`
			elseif line:sub(1,2) == "# " then
				return `<b>{string.sub(line, 3)}</b>`
			else
  	  	  	  	return line
  	  	  	end
	  	end

	  	for i, line in ipairs(server.Changelog) do
          	server.FormattedChangelog[i] = applyColour(line)
  	  	end

		--// Setup MaterialIcons
		do
			local MaterialIcons = require(server.Shared.MatIcons)
			server.MatIcons = setmetatable({}, {
				__index = function(self, ind)
					local materialIcon = MaterialIcons[ind]
					if materialIcon then
						self[ind] = `rbxassetid://{materialIcon}`
						return self[ind]
					end
					return ""
				end,
				__metatable = if data.DebugMode then unique else "Adonis_MatIcons"
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
		server.Core.SilentStartup = data.SilentStartup

		--// Load any afterinit functions from modules (init steps that require other modules to have finished loading)
		for _, f in ipairs(runAfterInit) do
			f(data)
		end

		--// Load Plugins; enforced NoEnv policy, make sure your plugins has the 2nd argument defined!
		for _, module in ipairs(server.PluginsFolder:GetChildren()) do
			LoadModule(module, false, {script = module}, true, true) --noenv
		end

		for _, module in ipairs(data.ServerPlugins or {}) do
			task.defer(xpcall, LoadModule, function(reason)
				warn(`The plugin {type(module) == "string" and string.sub(module, 1, 15) or module} failed to load! Reason: {reason}`)
				logError(`The plugin {type(module) == "string" and string.sub(module, 1, 15) or module} failed to load! Reason: {reason}`)
				table.insert(server.messages, {
					Title = `The plugin {type(module) == "string" and string.sub(module, 1, 15) or module} failed to load!`,
					Icon = "maticon://Dangerous",
					Message = string.match(reason, "Requested module experienced an error while loading") and "The plugin has invalid code or the code fails before return!" or string.match(reason, "Module code did not return exactly one value") and "The plugin returns an invalid amount of values or returns nothing at all!" or `Reason {reason}`,
					Time = 15
				})
			end, module, false, {script = module, cPcall = server.cPcall})
		end

		--// We need to do some stuff *after* plugins are loaded (in case we need to be able to account for stuff they may have changed before doing something, such as determining the max length of remote commands)
		for _, f in ipairs(runAfterPlugins) do
			f(data)
		end

		-- // Load sourcecode clientside plugins
		for _, module in ipairs(data.ClientPlugins or {}) do
			if type(module) == "string" then
				local code = service.New("StringValue")

				code.Name = service.HttpService:GenerateGUID(false)
				code.Value = server.Functions.Base64Encode(module:sub(1, 4) == "\27Lua" or server.Core.Bytecode(module))
				code.Parent = server.Client.Plugins
			end
		end

		--// Below can be used to determine when all modules and plugins have finished loading; service.Events.AllModulesLoaded:Connect(function() doSomething end)
		server.AllModulesLoaded = true
		service.Events.AllModulesLoaded:Fire(os.time())

		--// Queue handler
		--service.StartLoop("QueueHandler", "Heartbeat", service.ProcessQueue)

		--// Stuff to run after absolutely everything else has had a chance to run and initialize and all that
		for _, f in ipairs(runLast) do
			f(data)
		end

		if data.Loader and not silentStartup then
			print(`Loading version {data.NightlyMode and "Nightly" or server.Version} Complete; Required by {data.Loader:GetFullName()}{data.LoaderVersion and (" version: "..data.LoaderVersion) or ""}`)
		elseif not silentStartup then
			print(`Loading version {data.NightlyMode and "Nightly" or server.Version} Complete; No loader location provided`)
		end

		if server.Logs then
			server.Logs.AddLog(server.Logs.Script, {
				Text = `Finished loading version {data.NightlyMode and "Nightly" or server.Version}`;
				Desc = `Adonis has finished loading version {data.NightlyMode and "Nightly" or server.Version} by {data.Loader and data.Loader:GetFullName() or "UNKNOWN"}{data.LoaderVersion and (" version: "..data.LoaderVersion) or ""}`;
			})
		else
			warn("CRITICAL ERROR! SERVER.LOGS TABLE IS MISSING. THIS SHOULDN'T HAPPEN! SOMETHING WENT WRONG WHILE LOADING CORE MODULES(?)");
		end
		service.Events.ServerInitialized:Fire();

		return "SUCCESS"
	end;
	__tostring = function()
		return "Adonis"
	end;
	__metatable = nil; -- This is now set in __call if DebugMode isn't enabled.
})
