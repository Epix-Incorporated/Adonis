client = nil
service = nil
cPcall = nil
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

	local _G, script, getfenv, setfenv, getmetatable, setmetatable,
		warn, error, rawset, rawget, require, table, type =
		_G, script, getfenv, setfenv, getmetatable, setmetatable,
		warn, error, rawset, rawget, require, table, type

	local service = Vargs.Service
	local client = Vargs.Client
	local Anti, Core, Process, Remote, UI
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Process = client.Process;
		Remote = client.Remote;

		Core.Name = "\0"
		Core.Special = client.DepsName
		Core.MakeGui = UI.Make;
		Core.GetGui = UI.Get;
		Core.RemoveGui = UI.Remove;

		Core.Init = nil;
	end

	local function RunAfterPlugins()
		Core.GetEvent()

		Core.RunAfterPlugins = nil;
	end

	local function RunLast()
		--// API
		if service.NetworkClient then
			service.TrackTask("Thread: API Manager", Core.StartAPI)
		end

		Core.RunLast = nil
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.Core = {
		Init = Init;
		RunLast = RunLast;
		RunAfterPlugins = RunAfterPlugins;
		Name = script.Name;
		Special = script.Name;
		ScriptCache = {};

		GetEvent = function()
			if Core.RemoteEvent then
				log("Disconnect old RemoteEvent")

				for _,event in Core.RemoteEvent.Events do
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
						Remote.Fire(`{client.DepsName}GET_KEY`)
					end
				end
			end
		end;

		LoadPlugin = function(plugin)
			local plug = require(plugin)
			local func = setfenv(plug,GetEnv(getfenv(plug)))
			cPcall(func)
		end;

		LoadBytecode = function(str, env2)
			return require(client.Shared.FiOne)(str, env2)
		end;

		LoadCode = function(str, env2)
			return Core.LoadBytecode(str, env2)
		end;

		StartAPI = function()
			local ScriptCache = Core.ScriptCache
			local FiOne = client.Shared.FiOne
			local Get = Remote.Get
			local G_API = client.G_API
			local Allowed_API_Calls = client.Allowed_API_Calls
			local NewProxy = service.NewProxy
			local MetaFunc = service.MetaFunc
			local StartLoop = service.StartLoop
			local ReadOnly = service.ReadOnly
			local UnWrap = service.UnWrap
			_G = _G
			setmetatable = setmetatable
			type = type
			error = error
			warn = warn
			table = table
			rawset = rawset
			rawget = rawget
			getfenv = getfenv
			setfenv = setfenv
			require = require

			setfenv(1,setmetatable({}, {__metatable = getmetatable(getfenv())}))

			local API = {
				Access = ReadOnly({}, nil, nil, true);

				Scripts = ReadOnly({
					ExecutePermission = (function(srcScript, code)
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
								module = require(FiOne:Clone())
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
					end);
				}, nil, nil, true);
			}

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
				if table.isfrozen and not table.isfrozen(_G) or not table.isfrozen then
					rawset(_G, "Adonis", AdonisGTable)
					StartLoop("APICheck", 1, function()
						if rawget(_G, "Adonis") ~= AdonisGTable then
							if table.isfrozen and not table.isfrozen(_G) or not table.isfrozen then
								rawset(_G, "Adonis", AdonisGTable)
							else
								warn("ADONIS CRITICAL WARNING! MALICIOUS CODE IS TRYING TO CHANGE THE ADONIS _G API AND IT CAN'T BE SET BACK! PLEASE SHUTDOWN THE SERVER AND REMOVE THE MALICIOUS CODE IF POSSIBLE!")
							end
						end
					end, true)
				else
					warn("The _G table was locked and the Adonis _G API could not be loaded")
				end
			end
		end;
	};
end
