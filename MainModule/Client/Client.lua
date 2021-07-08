-------------------
-- Adonis Client --
-------------------

math.randomseed(os.time())

--// Load Order List
local LoadingOrder = {
	--// Required by most modules
	"Variables";
	"Functions";

	--// Core functionality
	"Core";
	"Remote";
	"UI";
	"Process";

	--// Misc
	"Anti";
}

--// Loccalllsssss
local _G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, tick, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, elapsedTime, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay, spawn =
	_G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, tick, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, elapsedTime, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay, spawn;

local ServicesWeUse = {
	"Workspace";
	"Players";
	"Lighting";
	"ReplicatedStorage";
	"ReplicatedFirst";
	"ScriptContext";
	"JointsService";
	"LogService";
	"Teams";
	"SoundService";
	"StarterGui";
	"StarterPack";
	"StarterPlayers";
	"TestService";
	"NetworkClient";
};

local unique = {}
local origEnv = getfenv(); setfenv(1,setmetatable({}, {__metatable = unique}))
local origWarn = warn
local startTime = tick()
local clientLocked = false
local oldInstNew = Instance.new
local oldReq = require
local Folder = nil
local locals = {}
local client = {}
local Queues = {}
local service = {}
local RbxEvents = {}
local Debounces = {}
local LoopQueue = {}
local RealMethods = {}
local RunningLoops = {}
local HookedEvents = {}
local WaitingEvents = {}
local ServiceSpecific = {}
local ServiceVariables = {}
local function isModule(module) for ind,modu in next,client.Modules do if rawequal(module, modu) then return true end end end
local function logError(err) warn("ERROR:"..tostring(err)) if client and client.Remote then client.Remote.Send("LogError",err) end end
local message = function(...) game:GetService("TestService"):Message(...) end
local print = function(...) for i,v in next,{...}do print(':: Adonis :: '..tostring(v)) end  end
local warn = function(...) for i,v in next,{...}do warn(tostring(v)) end end
local cPcall = function(func,...) local function cour(...) coroutine.resume(coroutine.create(func),...) end local ran,error=pcall(cour,...) if error then print(error) logError(error) warn('ERROR :: '..error) end end
local Pcall = function(func,...) local ran,error=pcall(func,...) if error then logError(error) end end
local Routine = function(func,...) coroutine.resume(coroutine.create(func),...) end
local sortedPairs = function(t, f) local a = {} for n in next,t do table.insert(a, n) end table.sort(a, f) local i = 0 local iter = function () i = i + 1 if a[i] == nil then return nil else return a[i], t[a[i]] end end return iter end
local Immutable = function(...) local mut = coroutine.wrap(function(...) while true do coroutine.yield(...) end end) mut(...) return mut end
local player = game:GetService("Players").LocalPlayer
local Fire, Detected
local wrap = coroutine.wrap
local Kill; Kill = Immutable(function(info)
	--if true then print(info or "SOMETHING TRIED TO CRASH CLIENT?") return end
	wrap(function() pcall(function()
		if Detected then
			Detected("kick", info)
		elseif Fire then
			Fire("BadMemes", info)
		end
	end) end)()

	wrap(function() pcall(function()
		wait(1)
		service.Player:Kick(info)
	end) end)()

	wrap(function() pcall(function()
		wait(5)
		while true do
			pcall(spawn,function()
				spawn(Kill())
				-- memes
			end)
		end
	end) end)()
end);

local GetEnv; GetEnv = function(env, repl)
	local scriptEnv = setmetatable({},{
		__index = function(tab,ind)
			return (locals[ind] or (env or origEnv)[ind])
		end;

		__metatable = unique;
	})

	if repl and type(repl)=="table" then
		for ind, val in next,repl do
			scriptEnv[ind] = val
		end
	end

	return scriptEnv
end;

local LoadModule = function(plugin, yield, envVars)
	local plug = require(plugin)
	if type(plug) == "function" then
		if yield then
			--Pcall(setfenv(plug,GetEnv(getfenv(plug), envVars)))
			local ran,err = service.TrackTask("Plugin: ".. tostring(plugin), setfenv(plug, GetEnv(getfenv(plug), envVars)))
			if not ran then
				warn("Module encountered an error while loading: "..tostring(plugin))
				warn(tostring(err))
			end
		else
			--service.Threads.RunTask("PLUGIN: "..tostring(plugin),setfenv(plug,GetEnv(getfenv(plug), envVars)))
			local ran,err = service.TrackTask("Thread: Plugin: ".. tostring(plugin), setfenv(plug, GetEnv(getfenv(plug), envVars)))
			if not ran then
				warn("Module encountered an error while loading: "..tostring(plugin))
				warn(tostring(err))
			end
		end
	else
		client[plugin.Name] = plug
	end
end;

client = setmetatable({
	Handlers = {};
	Modules = {};
	Service = service;
	Module = script;
	Print = print;
	Warn = warn;
	Deps = {};
	Pcall = Pcall;
	cPcall = cPcall;
	Routine = Routine;
	LogError = logError;
	TestEvent = Instance.new("RemoteEvent");

	Disconnect = function(info)
		service.Player:Kick(info or "Disconnected from server")
		--wait(30)
		--client.Kill()(info)
	end;

	--Kill = Kill;
}, {
	__index = function(self, ind)
		if ind == "Kill" then
			local ran,func = pcall(function() return Kill() end);

			if not ran or type(func) ~= "function" then
				service.Players.LocalPlayer:Kick("Adonis (PlrClientIndexKlErr)");
				while true do end
			end

			return func;
		end
	end

});

locals = {
	Pcall = Pcall;
	Folder = Folder;
	GetEnv = GetEnv;
	cPcall = cPcall;
	client = client;
	Routine = Routine;
	service = service;
	logError = logError;
	sortedPairs = sortedPairs;
	origEnv = origEnv;
}

service = setfenv(require(script.Parent.Shared.Service), GetEnv(nil, {client = client}))(function(eType, msg, desc, ...)
	local extra = {...}
	if eType == "MethodError" and service.Detected then
		Kill()("Shananigans denied")
		--player:Kick("Method error")
		--service.Detected("kick", "Method change detected")
	elseif eType == "ServerError" then
		logError("Client", msg)
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
end, ServiceSpecific)

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

--// Wrap
for i,val in next,service do if type(val) == "userdata" then service[i] = service.Wrap(val, true) end end
pcall(function() return service.Player.Kick end)
script = service.Wrap(script, true)
Enum = service.Wrap(Enum, true)
game = service.Wrap(game, true)
rawequal = service.RawEqual
workspace = service.Wrap(workspace, true)
Instance = {new = function(obj, parent) return service.Wrap(oldInstNew(obj, service.UnWrap(parent)), true) end}
require = function(obj) return service.Wrap(oldReq(service.UnWrap(obj)), true) end
client.Service = service
client.Module = service.Wrap(client.Module, true)

--// Setting things up
for ind,loc in next,{
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
	tick = tick;
	Faces = Faces;
	delay = delay;
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
	elapsedTime = elapsedTime;
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
	service = service;
} do locals[ind] = loc end

--// Init
return service.NewProxy({__metatable = "Adonis"; __tostring = function() return "Adonis" end; __call = function(tab,data)
	local folder = script.Parent
	local remoteName,depsName = string.match(data.Name, "(.*)\\(.*)")
	Folder = folder:Clone()

	setfenv(1,setmetatable({}, {__metatable = unique}))
	client.UIFolder = Folder.UI
	client.Shared = Folder.Shared
	client.Loader = data.Loader
	client.Module = data.Module
	client.DepsName = depsName
	client.TrueStart = data.Start
	client.LoadingTime = data.LoadingTime
	client.RemoteName = remoteName

	--// Toss deps into a table so we don't need to directly deal with the Folder instance they're in
	for ind,obj in next,Folder.Dependencies:GetChildren() do client.Deps[obj.Name] = obj end

	--// Do this before we start hooking up events
	folder:Destroy()
	script:Destroy()

	--// Intial setup
	for ind, serv in next,ServicesWeUse do local temp = service[serv] end

	--// Client specific service variables/functions
	ServiceSpecific.Player = service.Players.LocalPlayer;
	ServiceSpecific.PlayerGui = service.Player:FindFirstChild("PlayerGui");
	ServiceSpecific.SafeTweenSize = function(obj,...) pcall(obj.TweenSize,obj,...) end;
	ServiceSpecific.SafeTweenPos = function(obj,...) pcall(obj.TweenPosition,obj,...) end;
	ServiceSpecific.Filter = function(str,from,to)
		return client.Remote.Get("Filter",str,(to and from) or service.Player,to or from)
	end;

	ServiceSpecific.LaxFilter = function(str,from)
		return service.Filter(str,from or service.Player,from or service.Player)
	end;

	ServiceSpecific.BroadcastFilter = function(str,from)
		return client.Remote.Get("BroadcastFilter",str,from or service.Player)
	end;

	ServiceSpecific.IsMobile = function()
		if service.UserInputService.TouchEnabled and not service.UserInputService.MouseEnabled and not service.UserInputService.KeyboardEnabled then
			return true
		else
			return false
		end
	end;

	ServiceSpecific.LocalContainer = function()
		if not client.Variables.LocalContainer or not client.Variables.LocalContainer.Parent then
			client.Variables.LocalContainer = service.New("Camera")
			client.Variables.LocalContainer.Name = client.Functions.GetRandom()
			client.Variables.LocalContainer.Parent = service.Workspace
		end
		return client.Variables.LocalContainer
	end;

	--// Load Core Modules
	for ind,load in next,LoadingOrder do
		local modu = Folder.Core:FindFirstChild(load)
		if modu then
			LoadModule(modu, true, {script = script})
		end
	end

	--// Start of module loading and server connection process
	local runLast = {}
	local runAfterInit = {}
	local runAfterLoaded = {}
	local runAfterPlugins = {}

	--// Loading Finisher
	client.Finish_Loading = function()
		if client.Core.Key then
			--// Run anything from core modules that needs to be done after the client has finished loading
			for i,f in next,runAfterLoaded do
				f(data);
			end

			--// Stuff to run after absolutely everything else
			for i,f in next,runLast do
				f(data);
			end

			--// Finished loading
			clientLocked = true
			client.Finish_Loading = function() end
			client.LoadingTime() --origWarn(tostring(tick()-(client.TrueStart or startTime)))
			service.Events.FinishedLoading:Fire(os.time())
		else
			client.Kill()("Missing remote key")
		end
	end

	--// Initialize Cores
	for i,name in next,LoadingOrder do
		local core = client[name]

		if core then
			if type(core) == "table" or (type(core) == "userdata" and getmetatable(core) == "ReadOnly_Table") then
				if core.RunLast then
					table.insert(runLast, core.RunLast);
					core.RunLast = nil;
				end

				if core.RunAfterInit then
					table.insert(runAfterInit, core.RunAfterInit);
					core.RunAfterInit = nil;
				end

				if core.RunAfterPlugins then
					table.insert(runAfterPlugins, core.RunAfterPlugins);
					core.RunAfterPlugins = nil;
				end

				if core.RunAfterLoaded then
					table.insert(runAfterLoaded, core.RunAfterLoaded);
					core.RunAfterLoaded = nil;
				end

				if core.Init then
					core.Init(data);
					core.Init = nil;
				end
			end
		end
	end

	--// Load any afterinit functions from modules (init steps that require other modules to have finished loading)
	for i,f in next,runAfterInit do
		f(data);
	end

	--// Load Plugins
	for index,plugin in next,Folder.Plugins:GetChildren() do
		LoadModule(plugin, false, {script = plugin}); --noenv
	end

	--// We need to do some stuff *after* plugins are loaded (in case we need to be able to account for stuff they may have changed before doing something, such as determining the max length of remote commands)
	for i,f in next,runAfterPlugins do
		f(data);
	end

	--// Below can be used to determine when all modules and plugins have finished loading; service.Events.AllModulesLoaded:Connect(function() doSomething end)
	client.AllModulesLoaded = true;
	service.Events.AllModulesLoaded:Fire(os.time());

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

	service.Events.ClientInitialized:Fire();
	return "SUCCESS"
end})
