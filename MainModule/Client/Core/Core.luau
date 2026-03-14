client = nil
service = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil
log = nil

--// Core
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local _G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local script = script
	local service = Vargs.Service
	local client = Vargs.Client
	local Anti, Core, Functions, Process, Remote, UI, Variables
	local t
	local function Init(data)
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;

		t = client.Typechecker;

		Core.Name = "\0"
		Core.Special = client.DepsName
		Core.MakeGui = UI.Make;
		Core.GetGui = UI.Get;
		Core.RemoveGui = UI.Remove;

		if data.DebugMode == true then
			Core.DebugMode = true
		end

		Core.Init = nil;
	end

	local function RunAfterPlugins(data)
		Core.GetEvent()

		Core.RunAfterPlugins = nil;
	end

	local function RunLast()
		--// API
		if service.NetworkClient then
			service.TrackTask("Thread: API Manager", Core.StartAPI)
			--service.Threads.RunTask("_G API Manager",client.Core.StartAPI)
		end

		Core.RunLast = nil
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.Core = {
		Init = Init;
		RunLast = RunLast;
		--RunAfterLoaded = RunAfterLoaded;
		RunAfterPlugins = RunAfterPlugins;
		Name = script.Name;
		Special = script.Name;
		ScriptCache = {};

		GetEvent = function()
			if Core.RemoteEvent then
				log("Disconnect old RemoteEvent")

				for name,event in Core.RemoteEvent.Events do
					event:Disconnect()
				end

				Core.RemoteEvent = nil;
			end

			log("Getting RemoteEvent");

			local eventData = {}
			local remoteParent = service.ReplicatedStorage;
			local event = remoteParent:WaitForChild(client.RemoteName, 300)

			if not event then
				Anti.Detected("Kick", "RemoteEvent Not Found");
			else
				log("Getting RemoteFunction");

				local rFunc = event:WaitForChild("__FUNCTION", 120);

				if not rFunc then
					Anti.Detected("Kick", "RemoteFunction Not Found");
				else
					local events = {};

					rFunc.OnClientInvoke = Process.Remote;

					eventData.Object = event;
					eventData.Function = rFunc;
					eventData.FireServer = event.FireServer;
					eventData.Events = events;

					events.ProcessRemote = event.OnClientEvent:Connect(Process.Remote)
					events.ParentChildRemoved = remoteParent.ChildRemoved:Connect(function(child)
						if (Core.RemoteEvent == eventData) and child == event and task.wait() then
							warn("::ADONIS:: REMOTE EVENT REMOVED? RE-GRABBING");
							log("~! REMOTEEVENT WAS REMOVED?")
							Core.GetEvent();
						end
					end)

					Core.RemoteEvent = eventData

					if not Core.Key then
						log("~! Getting key from server")
						Core.Key = Remote.Get(`{client.DepsName}GET_KEY`)
						if Core.Key then
							client.Finish_Loading()
						else
							Remote.Fire(`{client.DepsName}GET_KEY`)
						end
					end
				end
			end
		end;

		DebugMode = client.DebugMode;

		LoadPlugin = function(plugin)
			local plug = require(plugin)
			local func = setfenv(plug,GetEnv(getfenv(plug)))
			task.spawn(Pcall, func)
		end;

		LoadBytecode = function(str, env)
			return require(client.Shared.FiOne, true)(str, env)
		end;

		LoadCode = function(str, env)
			return Core.LoadBytecode(str, env)
		end;

		StartAPI = function()
			local ScriptCache = Core.ScriptCache
			local FiOne = client.Shared.FiOne
			local Get = Remote.Get
			local GetFire = Remote.GetFire
			local G_API = client.G_API
			local Allowed_API_Calls = client.Allowed_API_Calls
			local NewProxy = service.NewProxy
			local ReplicatedStorage = service.ReplicatedStorage
			local MetaFunc = service.MetaFunc
			local ReadOnly = service.ReadOnly
			local StartLoop = service.StartLoop
			local ReadOnly = service.ReadOnly
			local UnWrap = service.UnWrap
			local service = service
			local client = client
			local _G = _G
			local setmetatable = setmetatable
			local type = type
			local print = print
			local error = error
			local pairs = pairs
			local ipairs = ipairs
			local warn = warn
			local next = next
			local table = table
			local rawset = rawset
			local rawget = rawget
			local getfenv = getfenv
			local setfenv = setfenv
			local require = require
			local tostring = tostring
			local client = client
			local Routine = Routine
			local Pcall = Pcall

			--// Get Settings
			local API_Special = {

			}

			setfenv(1,setmetatable({}, {__metatable = getmetatable(getfenv())}))

			local API_Specific = {
				API_Specific = {
					Test = function()
						print("We ran the api specific stuff")
					end
				};
				Service = service;
			}

			local API = {
				Access = service.MetaFunc(function(...)
					if not Variables.G_Access_Key then
						return
					end

					local args = {...}
					local key = args[1]
					local ind = args[2]
					local targ

					setfenv(1,setmetatable({}, {__metatable = getmetatable(getfenv())}))

					if API_Specific[ind] then
						targ = API_Specific[ind]
					elseif client[ind] and client.Allowed_API_Calls[ind] then
						targ = client[ind]
					end

					assert(client.G_Access and (type(key) == "string" and Functions.SHA256(key..game.GameId) == Variables.G_Access_Key) and targ and client.Allowed_API_Calls[ind], "Incorrect key or G_Access is disabled")

					if type(targ) == "table" then
						return service.NewProxy {
							__index = function(tab, inde)
								if targ[inde] ~= nil and API_Special[inde] == nil or API_Special[inde] == true then
									if targ[inde] ~= nil and type(targ[inde]) == "table" and client.G_Access_Perms == "Read" then
										return service.ReadOnly(targ[inde])
									else
										return targ[inde]
									end
								elseif API_Special[inde] == false then
									error(`Access Denied: {inde}`)
								else
									error(`Could not find {inde}`)
								end
							end;
							__newindex = function(tabl, inde, valu)
								error("Read-only")
							end;
							__metatable = true;
						}
					end
				end, true, { t.string, t.string });

				Scripts = ReadOnly({
					ExecutePermission = MetaFunc(function(srcScript, code)
						local exists;

						for i,v in ScriptCache do
							if UnWrap(v.Script) == srcScript then
								exists = v
							end
						end

						if exists and exists.noCache ~= true and (not exists.runLimit or (exists.runLimit and exists.Executions <= exists.runLimit)) then
							exists.Executions = exists.Executions+1
							return exists.Source, exists.Loadstring
						end

						local data = Get("ExecutePermission", srcScript, code, true)
						if data and data.Source then
							local module;
							if not exists then
								module = require(FiOne:Clone(), true)
								table.insert(ScriptCache,{
									Script = srcScript;
									Source = data.Source;
									Loadstring = module;
									noCache = data.noCache;
									runLimit = data.runLimit;
									Executions = data.Executions;
								})
							else
								module = exists.Loadstring
								exists.Source = data.Source
							end
							return data.Source, module
						end
					end, true, { t.instanceOf("LocalScript"), t.string });
				}, nil, nil, true);
			}

			if Core.DebugMode == true then
				local DebugAPI = {
					Env = Vargs
				}
				API.Debug = DebugAPI -- Allows fetching of the Debug API from within the _G API

				local pointers = {}

				local function getRealEnvResult(PointerOrPath)
					if tonumber(PointerOrPath) and pointers[PointerOrPath] then
						return pointers[PointerOrPath], true
					else
						local envPath = PointerOrPath:split('/.\\')
						local RealEnvResult = Vargs
						for i, pathArg in ipairs(envPath) do
							RealEnvResult = RealEnvResult[pathArg]
						end
						return RealEnvResult, false
					end
				end

				local AdonisDebugAPIBindable = ReplicatedStorage:FindFirstChild("Adonis_Debug_API")
				if AdonisDebugAPIBindable then
					AdonisDebugAPIBindable.OnInvoke = function(DebugCommand, ...)
						local args = table.unpack(...)
						if DebugCommand == "RunEnvFunc" then
							local FunctionInEnvToRunPath = args[1]
							if FunctionInEnvToRunPath and type(FunctionInEnvToRunPath) == "string" then
								local realEnvResult, isResultPointer = getRealEnvResult(FunctionInEnvToRunPath)
								return realEnvResult(table.unpack(args, 2, args.n))
							end
						elseif DebugCommand == "GetEnvTableMeta" then
							local TableInEnvPath = args[1]
							if TableInEnvPath and type(TableInEnvPath) == "string" then
								local realEnvResult, isResultPointer = getRealEnvResult(TableInEnvPath)
								return getmetatable(realEnvResult)
							end
						elseif DebugCommand == "RunEnvTableMetaFunc" then
							local TableInEnvPath = args[1]
							local FuncToRun = args[2]
							if TableInEnvPath and type(TableInEnvPath) == "string" then
								local realEnvResult, isResultPointer = getRealEnvResult(TableInEnvPath)
								local metaTableInEnv = getmetatable(realEnvResult)
								local result = metaTableInEnv[FuncToRun](realEnvResult,table.unpack(args, 3, args.n))
								local resultPointer = service.HttpService:GenerateGUID(false)
								pointers[resultPointer] = result

								return UnWrap(result), resultPointer
							end
						elseif DebugCommand == "GetApi" or not DebugCommand then
							return DebugAPI
						end
					end
				end
			end

			local AdonisGTable = NewProxy({
				__index = function(tab,ind)
					if ind == "Scripts" then
						return API.Scripts
					elseif G_API and Allowed_API_Calls.Client == true then
						if type(API[ind]) == "function" then
							return MetaFunc(API[ind])
						else
							return API[ind]
						end
					else
						error("_G API is disabled")
					end
				end;
				__newindex = function()
					error("Read-only")
				end;
				__metatable = "API";
			})

			if not rawget(_G, "Adonis") then
				if not table.isfrozen(_G) then
					rawset(_G, "Adonis", AdonisGTable)
					StartLoop("APICheck", 1, function()
						if rawget(_G, "Adonis") ~= AdonisGTable then
							if not table.isfrozen(_G) then
								rawset(_G, "Adonis", AdonisGTable)
							else
								warn("⚠️ ADONIS CRITICAL WARNING! MALICIOUS CODE IS TRYING TO CHANGE THE ADONIS _G API AND IT CAN'T BE SET BACK! PLEASE SHUTDOWN THE SERVER AND REMOVE THE MALICIOUS CODE IF POSSIBLE! 0x02412")
							end
						end
					end, true)
				else
					warn("The _G table was locked and the Adonis _G API could not be loaded. Error code 0x02417")
				end
			end
		end;
	};
end
