-------------------
-- Adonis Server --
-------------------
																																																																																						  --[[
If you find bugs, typos, or ways to improve something please message me (Sceleratis/Davey_Bones) with 
what you found so the script can be better. 

Also just be aware that I'm a very messy person, so a lot of this may or may not be spaghetti.	
																																																																																							]]
math.randomseed(os.time())

--// Todo:
--//   Fix a loooootttttttt of bugged commands
--//   Probably a lot of other stuff idk
--//   Transform from Sceleratis into Dr. Sceleratii; Evil alter-ego; Creator of bugs, destroyer of all code that is good
--//   Maybe add a celery command at some point
--//   Say hi to people reading the script
--//   ...
--//   "Hi." - Me

--// Holiday roooaaAaaoooAaaooOod 
local _G, game, script, getfenv, setfenv, workspace, 
getmetatable, setmetatable, loadstring, coroutine, 
rawequal, typeof, print, math, warn, error,  pcall, 
xpcall, select, rawset, rawget, ipairs, pairs, 
next, Rect, Axes, os, tick, Faces, unpack, string, Color3, 
newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor, 
NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint, 
NumberSequenceKeypoint, PhysicalProperties, Region3int16, 
Vector3int16, elapsedTime, require, table, type, wait, 
Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, spawn = 
	_G, game, script, getfenv, setfenv, workspace, 
getmetatable, setmetatable, loadstring, coroutine, 
rawequal, typeof, print, math, warn, error,  pcall, 
xpcall, select, rawset, rawget, ipairs, pairs, 
next, Rect, Axes, os, tick, Faces, unpack, string, Color3, 
newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor, 
NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint, 
NumberSequenceKeypoint, PhysicalProperties, Region3int16, 
Vector3int16, elapsedTime, require, table, type, wait, 
Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, spawn


local unique = {}
local origEnv = getfenv(); setfenv(1,setmetatable({}, {__metatable = unique}))
local locals = {}
local server = {}
local Queues = {}
local service = {}
local RbxEvents = {}
local Debounces = {}
local LoopQueue = {}
local ErrorLogs = {} 
local RealMethods = {}
local RunningLoops = {}
local HookedEvents = {}
local WaitingEvents = {}
local ServiceSpecific = {}
local ServiceVariables = {}
local oldReq = require
local Folder = script.Parent
local oldInstNew = Instance.new
local isModule = function(module)for ind,modu in next,server.Modules do if module == modu then return true end end end
local logError = function(plr,err) if server.Core and server.Core.DebugMode then warn("Error: "..tostring(plr)..": "..tostring(err)) end if server then server.Logs.AddLog(server.Logs.Errors,{Text = tostring(plr),Desc = err}) end end
local message = function(...) game:GetService("TestService"):Message(...) end
local print = function(...)for i,v in next,{...}do if server.Core and server.Core.DebugMode then message("::DEBUG:: Adonis ::"..tostring(v)) else print(':: Adonis :: '..tostring(v)) end end  end
local warn = function(...)for i,v in next,{...}do if server.Core and server.Core.DebugMode then message("::DEBUG:: Adonis ::"..tostring(v)) else warn(':: Adonis :: '..tostring(v)) end end end
local cPcall = function(func,...) local function cour(...) coroutine.resume(coroutine.create(func),...) end local ran,error = pcall(cour,...) if error then warn(error) logError("SERVER",error) warn(error) end end
local Pcall = function(func,...) local ran,error = pcall(func,...) if error then warn(error) logError("SERVER",error) warn(error) end end
local Routine = function(func,...)  coroutine.resume(coroutine.create(func),...) end
local sortedPairs = function(t, f) local a = {} for n in next,t do table.insert(a, n) end table.sort(a, f) local i = 0 local iter = function () i = i + 1 if a[i] == nil then return nil else return a[i], t[a[i]] end end return iter end
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

local GetVargTable = function()
	return {
		Server = server;
		Service = service;
	}
end

local LoadModule = function(plugin, yield, envVars, noEnv)
	noEnv = false --// Seems to make loading take longer when true (?)
	local plug = require(plugin)

	if server.Modules then
		table.insert(server.Modules,plugin)
	end

	if type(plug) == "function" then
		if yield then
			--Pcall(setfenv(plug,GetEnv(getfenv(plug), envVars)))
			local ran,err = service.TrackTask("Plugin: ".. tostring(plugin), (noEnv and plug) or setfenv(plug, GetEnv(getfenv(plug), envVars)), GetVargTable())
			if not ran then
				warn("Module encountered an error while loading: "..tostring(plugin))
				warn(tostring(err))
			end
		else
			--service.Threads.RunTask("PLUGIN: "..tostring(plugin),setfenv(plug,GetEnv(getfenv(plug), envVars)))
			local ran, err = service.TrackTask("Thread: Plugin: ".. tostring(plugin), (noEnv and plug) or setfenv(plug, GetEnv(getfenv(plug), envVars)),GetVargTable())
			if not ran then
				warn("Module encountered an error while loading: "..tostring(plugin))
				warn(tostring(err))
			end
		end
	else
		server[plugin.Name] = plug
	end

	if server.Logs then
		server.Logs.AddLog(server.Logs.Script,{
			Text = "Loaded "..tostring(plugin).." Module";
			Desc = "Adonis loaded a core module or plugin";
		})
	end
end;

local CleanUp = function()
	--local env = getfenv(2)
	--local ran,ret = pcall(function() return env.script:GetFullName() end)
	warn("Beginning Adonis cleanup & shutdown process...")
	--warn("CleanUp called from "..tostring((ran and ret) or "Unknown"))
	--local loader = server.Core.ClientLoader
	server.Model.Parent = service.ServerScriptService
	server.Model.Name = "Adonis_Loader"
	server.Running = false
	service.Threads.StopAll()
	for i,v in next,RbxEvents do 
		print("Disconnecting event") 
		v:Disconnect() 
		table.remove(RbxEvents, i) 
	end
	--loader.Archivable = false
	--loader.Disabled = true
	--loader:Destroy()
	if server.Core.RemoteEvent then
		server.Core.RemoteEvent.Security:Disconnect()
		server.Core.RemoteEvent.Event:Disconnect()
		server.Core.RemoteEvent.DecoySecurity1:Disconnect()
		server.Core.RemoteEvent.DecoySecurity2:Disconnect()
		pcall(service.Delete,server.Core.RemoteEvent.Object)
		pcall(service.Delete,server.Core.RemoteEvent.Decoy1)
		pcall(service.Delete,server.Core.RemoteEvent.Decoy2)
	end
	warn'Unloading complete'
end;

server = {
	Running = true;
	Modules = {};
	Pcall = Pcall;
	cPcall = cPcall;
	Routine = Routine;
	LogError = logError;
	ErrorLogs = ErrorLogs;
	FilteringEnabled = workspace.FilteringEnabled;
	ServerStartTime = os.time();
	CommandCache = {};
};

locals = {
	server = server;
	CodeName = "";
	Settings = server.Settings;
	HookedEvents = HookedEvents;
	sortedPairs = sortedPairs;
	ErrorLogs = ErrorLogs;
	logError = logError;
	origEnv = origEnv;
	Routine = Routine;
	Folder = Folder;
	GetEnv = GetEnv;
	cPcall = cPcall;
	Pcall = Pcall;
}

service = setfenv(require(Folder.Core.Service), GetEnv(nil, {server = server}))(function(eType, msg, desc, ...)
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
--[[for i,val in next,service do if type(val) == "userdata" then service[i] = service.Wrap(val) end end
script = service.Wrap(script)
Enum = service.Wrap(Enum)
game = service.Wrap(game)
workspace = service.Wrap(workspace)
Instance = {new = function(obj, parent) return service.Wrap(oldInstNew(obj, service.UnWrap(parent))) end}
require = function(obj) return service.Wrap(oldReq(service.UnWrap(obj))) end --]]
Instance = {new = function(obj, parent) return oldInstNew(obj, service.UnWrap(parent)) end}
require = function(obj) return oldReq(service.UnWrap(obj)) end
rawequal = service.RawEqual
--service.Players = service.Wrap(service.Players)
--Folder = service.Wrap(Folder)
server.Folder = Folder
server.Deps = Folder.Dependencies;
server.Client = Folder.Parent.Client;
server.Dependencies = Folder.Dependencies;
server.PluginsFolder = Folder.Plugins;
server.Service = service

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
	service = service
	}do locals[ind] = loc end

--// Init
return service.NewProxy({__metatable = "Adonis"; __tostring = function() return "Adonis" end; __call = function(tab, data)
	if _G["__Adonis_MODULE_MUTEX"] and type(_G["__Adonis_MODULE_MUTEX"])=="string" then
		warn("\n-----------------------------------------------"
			.."\nAdonis server-side is already running! Aborting..."
			.."\n-----------------------------------------------")
		script:Destroy()
		return "FAILED"
	else
		_G["__Adonis_MODULE_MUTEX"] = "Running"
	end

	if not data or not data.Loader then 
		warn("WARNING: MainModule loaded without using the loader;")
	end

	--// Begin Script Loading
	setfenv(1,setmetatable({}, {__metatable = unique}))
	data = service.Wrap(data or {})

	--// Server Variables
	local setTab = require(server.Deps.DefaultSettings)
	server.Defaults = setTab
	server.Settings = data.Settings or setTab.Settings or {}
	server.Descriptions = data.Descriptions or setTab.Descriptions or {}
	server.Order = data.Order or setTab.Order or {}
	server.Data = data or {}
	server.Model = data.Model or service.New("Model")
	server.Dropper = data.Dropper or service.New("Script")
	server.Loader = data.Loader or service.New("Script")
	server.Runner = data.Runner or service.New("Script")
	server.ServerPlugins = data.ServerPlugins
	server.ClientPlugins = data.ClientPlugins
	server.Threading = require(server.Deps.ThreadHandler)
	server.Changelog = require(server.Client.Dependencies.Changelog)
	server.Credits = require(server.Client.Dependencies.Credits)
	server.Parser = require(server.Deps.Parser)
	locals.Settings = server.Settings
	locals.CodeName = server.CodeName

	if server.Settings.HideScript and data.Model then
		data.Model.Parent = nil
		script:Destroy()
	end

	for setting,value in next,setTab.Settings do 
		if server.Settings[setting] == nil then 
			server.Settings[setting] = value 
		end 
	end

	for desc,value in next,setTab.Descriptions do 
		if server.Descriptions[desc] == nil then 
			server.Descriptions[desc] = value 
		end 
	end

	--// Load services
	for ind, serv in next,{
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
		"StarterPlayers";
		"TestService";
		"HttpService";
		"InsertService";
		"NetworkServer"		
		}do local temp = service[serv] end

	--// Module LoadOrder List
	local LoadingOrder = {
		"Logs";
		"Variables";
		"Core";
		"Remote";
		"Functions";
		"Process";
		"Admin";
		"HTTP";
		"Anti";
		"Commands";
	}

	--// Load core modules
	for ind,load in next,LoadingOrder do 
		local modu = Folder.Core:FindFirstChild(load) 
		if modu then 
			LoadModule(modu,true,{script = script}, true) --noenv
		end 
	end

	--// Initialize Cores
	for i,name in next,LoadingOrder do
		local core = server[name]
		if core and type(core) == "table" and core.Init then
			core.Init()
			core.Init = nil
		elseif type(core) == "userdata" and getmetatable(core) == "ReadOnly_Table" and core.Init then
			core.Init()
		end
	end

	--// More Variable Initialization
	server.Variables.CodeName = server.Functions:GetRandom()
	server.Remote.MaxLen = 0
	server.Logs.Errors = ErrorLogs
	server.Client = Folder.Parent.Client
	server.Core.Name = server.Functions:GetRandom()
	server.Core.Themes = data.Themes or {}
	server.Core.Plugins = data.Plugins or {}
	server.Core.ModuleID = data.ModuleID or 359948692
	server.Core.LoaderID = data.LoaderID or 360052698
	server.Core.DebugMode = data.DebugMode or false
	server.Core.DataStore = server.Core.GetDataStore()
	server.Core.Loadstring = require(server.Deps.Loadstring)
	server.HTTP.Trello.API = require(server.Deps.TrelloAPI)

	--// Bind cleanup
	service.DataModel:BindToClose(CleanUp)

	--// Server Specific Service Functions
	ServiceSpecific.GetPlayers = server.Functions.GetPlayers

	--// Load data
	if server.Core.DataStore then
		pcall(server.Core.LoadData)

		--// Occasionally the below line causes a script execution timeout error, so lets just pcall the whole thing and hope loading doesn't break yolo(?)
		local ds = server.Core.DataStore;
		pcall(ds.OnUpdate, ds, server.Core.DataStoreEncode("CrossServerChat"), server.Process.CrossServerChat) -- WE NEED TO UPGRADE THIS TO THAT CROSS SERVER MESSAGE SERVICE THING. This is big bad currently.
		pcall(ds.OnUpdate, ds, server.Core.DataStoreEncode("SavedSettings"), function(data) server.Process.DataStoreUpdated("SavedSettings",data) end)
		pcall(ds.OnUpdate, ds, server.Core.DataStoreEncode("SavedTables"), function(data) server.Process.DataStoreUpdated("SavedTables",data) end)
		--server.Core.DataStore:OnUpdate(server.Core.DataStoreEncode("CrossServerChat"), server.Process.CrossServerChat)
		--server.Core.DataStore:OnUpdate(server.Core.DataStoreEncode("SavedSettings"), function(data) server.Process.DataStoreUpdated("SavedSettings",data) end)
		--server.Core.DataStore:OnUpdate(server.Core.DataStoreEncode("SavedTables"), function(data) server.Process.DataStoreUpdated("SavedTables",data) end)
		--server.Core.DataStore:OnUpdate(server.Core.DataStoreEncode("SavedVariables"), function(data) server.Process.DataStoreUpdated("SavedVariables",data) end)
		--server.Core.DataStore:OnUpdate(server.Core.DataStoreEncode("FullShutdown"), function(data) if data then local id,user,reason = data.ID,data.User,data.Reason if id == game.PlaceId then server.Functions.Shutdown(reason) end end end)
	end

	if not server.FilteringEnabled then
		service.RbxEvent(service.DataModel.DescendantAdded, server.Process.ObjectAdded)
		service.RbxEvent(service.DataModel.DescendantRemoving, server.Process.ObjectRemoving)
		service.RbxEvent(service.Workspace.DescendantAdded, server.Process.WorkspaceObjectAdded)
		--service.RbxEvent(service.Workspace.DescendantRemoving, server.Process.WorkspaceObjectRemoving)
	end

	--// NetworkServer Events
	if service.NetworkServer then
		service.RbxEvent(service.NetworkServer.ChildAdded, server.Process.NetworkAdded)
		service.RbxEvent(service.NetworkServer.DescendantRemoving, server.Process.NetworkRemoved)
	end

	--// Load Plugins
	for index,plugin in next,server.PluginsFolder:GetChildren() do
		LoadModule(plugin, false, {script = plugin}, true); --noenv
	end

	for index,plugin in next,(data.ServerPlugins or {}) do 
		LoadModule(plugin, false, {script = plugin});
	end

	--// RemoteEvent Handling
	server.Core.MakeEvent()	
	service.JointsService.Changed:Connect(function(p) if server.Anti.RLocked(service.JointsService) then server.Core.PanicMode("JointsService RobloxLocked") end end)
	service.JointsService.ChildRemoved:Connect(function(c) 
		if server.Core.RemoteEvent and (c == server.Core.RemoteEvent.Object or c == server.Core.RemoteEvent.Decoy1 or c == c == server.Core.RemoteEvent.Decoy2) then 
			server.Core.MakeEvent() 
		end 
	end)

	--// Do some things
	for com in next,server.Remote.Commands do if string.len(com)>server.Remote.MaxLen then server.Remote.MaxLen = string.len(com) end end
	for index,plugin in next,(data.ClientPlugins or {}) do plugin:Clone().Parent = server.Client.Plugins end
	for index,theme in next,(data.Themes or {}) do theme:Clone().Parent = server.Client.Dependencies.UI end

	--// Prepare the client loader
	--server.Core.PrepareClient()	

	--// Add existing players in case some are already in the server
	for index,player in next,service.Players:GetPlayers() do
		service.TrackTask("Thread: LoadPlayer ".. tostring(player.Name), server.Core.LoadExistingPlayer, player);
	end

	--// Events
	service.RbxEvent(service.Players.PlayerAdded, service.EventTask("PlayerAdded", server.Process.PlayerAdded))
	service.RbxEvent(service.Players.PlayerRemoving, service.EventTask("PlayerRemoving", server.Process.PlayerRemoving))
	service.RbxEvent(service.Workspace.ChildAdded, server.Process.WorkspaceChildAdded)
	service.RbxEvent(service.LogService.MessageOut, server.Process.LogService)
	service.RbxEvent(service.ScriptContext.Error, server.Process.ErrorMessage)

	--// Fake finder
	service.RbxEvent(service.Players.ChildAdded, server.Anti.RemoveIfFake)

	--// Start API
	if service.NetworkServer then
		--service.Threads.RunTask("_G API Manager",server.Core.StartAPI)
		service.TrackTask("Thread: API Manager", server.Core.StartAPI)
	end

	--// Queue handler
	--service.StartLoop("QueueHandler","Heartbeat",service.ProcessQueue)

	--// Client check
	service.StartLoop("ClientCheck",30,server.Core.CheckAllClients,true)

	--// Trello updater
	if server.Settings.Trello_Enabled then
		service.StartLoop("TRELLO_UPDATER",server.Settings.HttpWait,server.HTTP.Trello.Update,true)
	end

	--// Load minor stuff
	server.Threading.NewThread(function()
		for ind, music in next,server.Settings.MusicList or {} do table.insert(server.Variables.MusicList,music) end
		for ind, music in next,server.Settings.InsertList or {} do table.insert(server.Variables.InsertList,music) end
		for ind, cape in next,server.Settings.CapeList or {} do table.insert(server.Variables.Capes,cape) end
		for ind, cmd in next,server.Settings.Permissions or {} do 
			local com,level = cmd:match("^(.*):(.*)") 
			if com and level then 
				if level:find(",") then
					local newLevels = {}
					for lvl in level:gmatch("[^%,]+") do
						table.insert(newLevels, service.Trim(lvl))
					end
					server.Admin.SetPermission(com, newLevels)
				else
					server.Admin.SetPermission(com, level)
				end
			end 
		end
		pcall(function() service.Workspace.AllowThirdPartySales = true end)	
		server.Functions.GetOldDonorList()
	end)

	--// Backup Map
	if server.Settings.AutoBackup then
		service.TrackTask("Thread: Initial Map Backup", server.Admin.RunCommand, server.Settings.Prefix.."backupmap")
	end 
	--service.Threads.RunTask("Initial Map Backup",server.Admin.RunCommand,server.Settings.Prefix.."backupmap")

	--// AutoClean
	if server.Settings.AutoClean then
		service.StartLoop("AUTO_CLEAN",server.Settings.AutoCleanDelay,server.Functions.CleanWorkspace,true)
	end

	--// Worksafe
	service.TrackTask("WorkSafe",function()
		if server.Settings.AntiUnAnchor and not service.ServerScriptService:FindFirstChild("ADONIS_AnchorSafe") then 
			local ancsafe = server.Deps.Assets.WorkSafe:clone() 
			ancsafe.Mode.Value = "AnchorSafe" 
			ancsafe.Name = "ADONIS_AnchorSafe" 
			ancsafe.Archivable = false 
			ancsafe.Parent = service.ServerScriptService 
			ancsafe.Disabled = false 
		end

		if server.Settings.AntiDelete and not service.ServerScriptService:FindFirstChild("ADONIS_ObjectSafe") then 
			local ancsafe = server.Deps.Assets.WorkSafe:clone() 
			ancsafe.Mode.Value = "ObjectSafe" 
			ancsafe.Name = "ADONIS_ObjectSafe" 
			ancsafe.Archivable = false 
			ancsafe.Parent = service.ServerScriptService 
			ancsafe.Disabled = false 
		end

		if server.Settings.AntiLeak and not service.ServerScriptService:FindFirstChild("ADONIS_AntiLeak") then 
			local ancsafe = server.Deps.Assets.WorkSafe:clone() 
			ancsafe.Mode.Value = "AntiLeak" 
			ancsafe.Name = "ADONIS_AntiLeak" 
			ancsafe.Archivable = false 
			ancsafe.Parent = service.ServerScriptService 
			ancsafe.Disabled = false 
		end
	end)

	--// Finished loading
	server.Variables.BanMessage = server.Settings.BanMessage
	server.Variables.LockMessage = server.Settings.LockMessage
	for i,v in next,server.Settings.OnStartup do server.Logs.AddLog("Script",{Text = "Startup: Executed "..tostring(v); Desc = "Executed startup command; "..tostring(v)}) server.Threading.NewThread(server.Admin.RunCommand, v) end

	server.Logs.AddLog(server.Logs.Script,{
		Text = "Finished Loading";
		Desc = "Adonis finished loading";
	})

	if data.Loader then
		warn("Loading Complete; Required by "..tostring(data.Loader:GetFullName()))
	else
		warn("Loading Complete;")
	end

	return "SUCCESS"
end})
