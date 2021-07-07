server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

local disableAllGUIs;
function disableAllGUIs(folder)
	for i,v in ipairs(folder:GetChildren()) do
		if v:IsA("ScreenGui") then
			v.Enabled = false;
		elseif v:IsA("Folder") or v:IsA("Model") then
			disableAllGUIs(v);
		end
	end
end;

--// Core
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Deps;

	local function Init(data)
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;
		Deps = server.Deps

		--// Core variables
		Core.Themes = data.Themes or {}
		Core.Plugins = data.Plugins or {}
		Core.ModuleID = data.ModuleID or 2373501710
		Core.LoaderID = data.LoaderID or 2373505175
		Core.DebugMode = data.DebugMode or false
		Core.Name = server.Functions:GetRandom()
		Core.LoadstringObj = Core.GetLoadstring()
		Core.Loadstring = require(Core.LoadstringObj)

		disableAllGUIs(server.Client.UI);

		Core.Init = nil;
		Logs:AddLog("Script", "Core Module Initialized")
	end;

	local function RunAfterPlugins(data)
		--// RemoteEvent Handling
		server.Core.MakeEvent()
		service.JointsService.Changed:Connect(function(p) if server.Anti.RLocked(service.JointsService) then server.Core.PanicMode("JointsService RobloxLocked") end end)
		service.JointsService.ChildRemoved:Connect(function(c)
			if server.Core.RemoteEvent and not server.Core.FixingEvent and (function() for i,v in next,server.Core.RemoteEvent do if c == v then return true end end end)() then
				wait();
				server.Core.MakeEvent()
			end
		end)

		--// Load data
		Core.DataStore = server.Core.GetDataStore()
		if Core.DataStore then
			service.TrackTask("Thread: DSLoadAndHook", function()
				pcall(server.Core.LoadData)
			end)
		end

		--// Save all data on server shutdown
		game:BindToClose(Core.SaveAllPlayerData);

		--// Start API
		if service.NetworkServer then
			--service.Threads.RunTask("_G API Manager",server.Core.StartAPI)
			service.TrackTask("Thread: API Manager", Core.StartAPI)
		end

		--// Add existing players in case some are already in the server
		for index,player in next,service.Players:GetPlayers() do
			service.TrackTask("Thread: LoadPlayer ".. tostring(player.Name), Core.LoadExistingPlayer, player);
		end

		--// Occasionally save all player data to the datastore to prevent data loss if the server abruptly crashes
		service.StartLoop("SaveAllPlayerData", Core.DS_AllPlayerDataSaveInterval, Core.SaveAllPlayerData, true)

		Core.RunAfterPlugins = nil;
		Logs:AddLog("Script", "Core Module RunAfterPlugins Finished");
	end

	server.Core = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		DataQueue = {};
		DataCache = {};
		PlayerData = {};
		CrossServerCommands = {};
		CrossServer = function() return false end;
		ExecuteScripts = {};
		LastDataSave = 0;
		PanicMode = false;
		FixingEvent = false;
		ScriptCache = {};
		Connections = {};
		LastEventValue = 1;

		Variables = {
			TimeBans = {};
		};

		--// Datastore update/queue timers/delays
		DS_WriteQueueDelay = 1;
		DS_ReadQueueDelay = 0.5;
		DS_AllPlayerDataSaveInterval = 30;
		DS_AllPlayerDataSaveQueueDelay = 0.5;

		--// Used to change/"reset" specific datastore keys
		DS_RESET_SALTS = {
			SavedSettings = "32K5j4";
			SavedTables = 	"32K5j4";
		};

		Panic = function(reason)
			local hint = Instance.new("Hint", service.Workspace)
			hint.Text = "~= Adonis PanicMode Enabled: "..tostring(reason).." =~"
			Core.PanicMode = true;

			warn("SOMETHING SEVERE HAPPENED; ENABLING PANIC MODE; REASON BELOW;")
			warn(tostring(reason))
			warn("ENABLING CHAT MODE AND DISABLING CLIENT CHECKS;")
			warn("MODS NOW HAVE ACCESS TO PANIC COMMANDS SUCH AS :SHUTDOWN")

			--[[
			for i,v in pairs(service.Players:GetPlayers()) do
				cPcall(function()
					v.Chatted:connect(function(msg)
						Process.Chat(v,msg)
					end)
				end)
			end
			--]]

			Logs.AddLog(Logs.Script,{
				Text = "ENABLED PANIC MODE";
				Desc = tostring(reason);
			})
		end;

		DisconnectEvent = function()
			if Core.RemoteEvent and not Core.FixingEvent then
				Core.FixingEvent = true;
				Core.RemoteEvent.FuncSec:Disconnect()
				Core.RemoteEvent.Security:Disconnect()
				Core.RemoteEvent.Event:Disconnect()
				Core.RemoteEvent.DecoySecurity1:Disconnect()
				Core.RemoteEvent.DecoySecurity2:Disconnect()
				pcall(function() service.Delete(Core.RemoteEvent.Object) end)
				pcall(function() service.Delete(Core.RemoteEvent.Function) end)
				pcall(function() service.Delete(Core.RemoteEvent.Decoy1) end)
				pcall(function() service.Delete(Core.RemoteEvent.Decoy2) end)
				Core.FixingEvent = false;
				Core.RemoteEvent = nil;
			end
		end;

		MakeEvent = function()
			local ran,error = pcall(function()
				if Anti.RLocked(service.JointsService) then
					Core.Panic("JointsService RobloxLocked/Unusable")
				elseif server.Running then
					local rTable = {};
					local event = service.New("RemoteEvent")
					local func = service.New("RemoteFunction", {Parent = event, Name = ""})
					local decoy1 = event:Clone()
					local decoy2 = event:Clone()
					local secureTriggered = false
					local tripDet = math.random()

					Core.DisconnectEvent();
					Core.RemoteEvent = rTable;
					Core.TripDet = tripDet;

					event.Name = Core.Name--..Functions.GetRandom() -- Core.Name
					decoy1.Name = Core.Name..Functions.GetRandom()
					decoy2.Name = Core.Name..Functions.GetRandom()

					event.Archivable = false
					decoy1.Archivable = false
					decoy2.Archivable = false

					Core.RemoteEvent.Object = event
					Core.RemoteEvent.Function = func
					Core.RemoteEvent.Decoy1 = decoy1
					Core.RemoteEvent.Decoy2 = decoy2

					event.Parent = service.JointsService
					--decoy1.Parent = service.JointsService
					--decoy2.Parent = service.JointsService

					local function secure(ev, name)
						return service.RbxEvent(ev.Changed, function(p)
							if Core.RemoteEvent == rTable then
								if ev and ev == Core.RemoteEvent.Function then
									Core.RemoteEvent.Function.OnServerInvoke = Process.Remote
								end

								if p == "Name" then
									event.Name = name--..Functions.GetRandom()--Core.Name
								elseif tripDet == Core.TripDet and wait() and not secureTriggered then
									--print("Secure triggered");
									secureTriggered = true;
									Core.DisconnectEvent();
									Core.MakeEvent()
								end
							end
						end)
					end

					Core.RemoteEvent.Event = service.RbxEvent(event.OnServerEvent, Process.Remote)
					func.OnServerInvoke = Process.Remote

					service.RbxEvent(decoy1.OnServerEvent, function(p,modu,com,sub)
						local keys = Remote.Clients[tostring(p.UserId)]
						if keys and com == "TrustCheck" and modu == keys.Module then
							decoy1:FireClient(p,"TrustCheck",keys.Decoy1)
						end
					end)

					service.RbxEvent(decoy2.OnServerEvent, function(p,modu,com,sub)
						local keys = Remote.Clients[tostring(p.UserId)]
						if keys and com == "TrustCheck" and modu == keys.Module then
							decoy1:FireClient(p,"TrustCheck",keys.Decoy2)
						end
					end)

					Core.RemoteEvent.Security = secure(event, Core.Name)
					Core.RemoteEvent.FuncSec = secure(func, "");
					Core.RemoteEvent.DecoySecurity1 = secure(decoy1, Core.Name)
					Core.RemoteEvent.DecoySecurity2 = secure(decoy2, Core.Name)
					Logs.AddLog(Logs.Script,{
						Text = "Created RemoteEvent";
						Desc = "RemoteEvent was successfully created";
					})
				end
			end)

			if error then
				warn(error)
				Core.Panic("Error while making RemoteEvent")
			end
		end;

		UpdateConnections = function()
			if service.NetworkServer then
				for i,cli in next,service.NetworkServer:GetChildren() do
					Core.Connections[cli] = cli:GetPlayer()
				end
			end
		end;

		UpdateConnection = function(p)
			if service.NetworkServer then
				for i,cli in next,service.NetworkServer:GetChildren() do
					if cli:GetPlayer() == p then
						Core.Connections[cli] = p
					end
				end
			end
		end;

		GetNetworkClient = function(p)
			if service.NetworkServer then
				for i,v in pairs(service.NetworkServer:GetChildren()) do
					if v:GetPlayer() == p then
						return v
					end
				end
			end
		end;

		SetupEvent = function(p)
			local key = tostring(p.UserId)
			local keys = Remote.Clients[key]
			if keys and keys.EventName and p and not Anti.ObjRLocked(p) then
				local event = Instance.new("RemoteEvent")
				event.Name = keys.EventName
				event.Changed:Connect(function()
					if Anti.RLocked(event) or not event or event.Parent ~= p then
						service.Delete(event)
						Core.SetupEvent(p)
					end
				end)
				event.OnServerEvent:Connect(function(np,...)
					if np == p then
						Process.Remote(np,...)
					end
				end)
				event.Parent = p
			else
				p:Kick("Locked")
			end
		end;

		PrepareClient = function()
			if service.NetworkServer and server.Running then
				local ran,err = pcall(function()
					if Core.ClientLoader then
						pcall(function() Core.ClientLoaderEvent:Disconnect() service.Delete(Core.ClientLoader) end)
					end

					local loader = Deps.ClientLoader:Clone()
					loader.Disabled = false
					loader.Archivable = false
					loader.Name = "\0"

					loader.Parent = service.ReplicatedFirst
					Core.ClientLoader = loader
					Core.ClientLoaderEvent = loader.Changed:Connect(function()
						Core.PrepareClient()
					end)
				end)

				if err or not ran then
					Core.Panic("Cannot load ClientLoader "..tostring(err))
				end
			end
		end;

		HookClient = function(p)
			local key = tostring(p.UserId)
			local keys = Remote.Clients[key]
			if keys then
				local depsName = Functions:GetRandom()
				local eventName = Functions:GetRandom()
				local folder = server.Client:Clone()
				local acli = server.Deps.ClientMover:Clone();
				local client = folder.Client
				local parentTo = "PlayerGui" --// Roblox, seriously, please give the server access to PlayerScripts already so I don't need to do this.
				local playerGui = p:FindFirstChildOfClass(parentTo) or p:WaitForChild(parentTo, 600);

				if playerGui and playerGui.ClassName ~= parentTo then
					playerGui = p:FindFirstChildOfClass(parentTo);
				end

				if not p.Parent then
					return false
				elseif not playerGui then
					p:Kick("Loading Error \nPlayerGui Missing (Waited 10 Minutes)")
					return false
				end

				folder.Name = "Adonis_Client" --Core.Name.."\\"..depsName

				local container = service.New("ScreenGui");
				container.ResetOnSpawn = false;
				container.Enabled = false;
				container.Name = "\0";--"Adonis_Container";
				folder.Parent = container;

				local specialVal = service.New("StringValue")
				specialVal.Value = Core.Name.."\\"..depsName
				specialVal.Name = "Special"
				specialVal.Parent = folder

				keys.Loader = Core.ClientLoader
				keys.Special = depsName
				keys.EventName = eventName
				keys.Module = client

				acli.Parent = folder;

				--[[service.Events[p.userId.."_CLIENTLOADER"]:connectOnce(function()
					if container.Parent == playerGui then
						container:Destroy()
					end
				end)--]]

				local ok,err = pcall(function()
					container.Parent = playerGui
					acli.Disabled = false;
				end)

				if not Core.PanicMode and not ok then
					p:Kick("Loading Error \n[HookClient Error: "..tostring(err).."]")
					return false
				else
					return true
				end
			else
				if p then p:Kick("Loading Error \n[HookClient: Keys Missing]") end
			end
		end;

		LoadClientLoader = function(p)
			local loader = Deps.ClientLoader:Clone()
			loader.Name = Functions.GetRandom()
			loader.Parent = p:WaitForChild("PlayerGui", 60) or p:WaitForChild("Backpack")
			loader.Disabled = false
		end;

		LoadExistingPlayer = function(p)
			warn("Loading existing player: ".. tostring(p))
			--Core.LoadClientLoader(p)
			Process.PlayerAdded(p)
		end;

		MakeClient = function()
			local ran,error = pcall(function()
				if Anti.RLocked(service.StarterPlayer) then
					Core.Panic("StarterPlayer RobloxLocked")
				else
					local starterScripts = service.StarterPlayer:FindFirstChild(Core.Name)
					if not starterScripts then
						starterScripts = service.New("StarterPlayerScripts", service.StarterPlayer)
						starterScripts.Name = Core.Name
						starterScripts.Changed:Connect(function(p)
							if p=="Parent" then
								Core.MakeClient()
							elseif p=="Name" then
								starterScripts.Name = Core.Name
							elseif p=="RobloxLocked" and Anti.RLocked(starterScripts) then
								Core.Panic("PlayerScripts RobloxLocked")
							end
						end)

						starterScripts.ChildAdded:Connect(function(c)
							if c.Name ~= Core.Name then
								wait(0.5)
								c:Destroy()
							end
						end)
					end

					starterScripts:ClearAllChildren()
					if Anti.RLocked(starterScripts) then
						Core.Panic("StarterPlayerScripts RobloxLocked")
					else
						if Core.Client then
							local cli = Core.Client
							if Anti.ObjRLocked(cli.Object) then
								Core.Panic("Client RobloxLocked")
							else
								Core.Client.Security:Disconnect()
								pcall(function() Core.Client.Object:Destroy() end)
							end
						end
						Core.Client = {}
						local client = Deps.Client:Clone()
						client.Name = Core.Name
						server.ClientDeps:Clone().Parent = client
						client.Parent = starterScripts
						client.Disabled = false
						Core.Client.Object = client
						Core.Client.Security = client.Changed:Connect(function(p)
							if p == "Parent" or p == "RobloxLocked" then
								Core.MakeClient()
							end
						end)
					end
				end
			end)
			if error then
				print(error)
				Core.Panic("Error while making client")
			end
		end;

		ExecutePermission = function(scr, code, isLocal)
			local fixscr = service.UnWrap(scr)

			for _, val in pairs(Core.ExecuteScripts) do
				if not isLocal or (isLocal and val.Type == "LocalScript") then
					if (service.UnWrap(val.Script) == fixscr or code == val.Code) and (not val.runLimit or (val.runLimit ~= nil and val.Executions <= val.runLimit)) then
						val.Executions = val.Executions+1

						return {
							Source = val.Source;
							noCache = val.noCache;
							runLimit = val.runLimit;
							Executions = val.Executions;
						}
					end
				end
			end
		end;

		GetScript = function(scr,code)
			for i,val in pairs(Core.ExecuteScripts) do
				if val.Script == scr or code == val.Code then
					return val,i
				end
			end
		end;

		UnRegisterScript = function(scr)
			for i,dat in pairs(Core.ExecuteScripts) do
				if dat.Script == scr or dat == scr then
					table.remove(Core.ExecuteScripts, i)
					return dat
				end
			end
		end;

		RegisterScript = function(data)
			data.Executions = 0
			data.Time = os.time()
			data.Type = data.Script.ClassName
			data.Wrapped = service.Wrap(data.Script)
			data.Wrapped:SetSpecial("Clone",function()
				return Core.RegisterScript {
					Script = service.UnWrap(data.Script):Clone();
					Code = data.Code;
					Source = data.Source;
					noCache = data.noCache;
					runLimit = data.runLimit;
				}
			end)

			for ind,scr in pairs(Core.ExecuteScripts) do
				if scr.Script == data.Script then
					return scr.Wrapped or scr.Script
				end
			end

			if not data.Code then
				data.Code = Functions.GetRandom()
			end

			table.insert(Core.ExecuteScripts,data)
			return data.Wrapped
		end;

		GetLoadstring = function()
			local newLoad = Deps.Loadstring:Clone();
			local lbi = server.Shared.FiOne:Clone();

			lbi.Parent = newLoad

			return newLoad;
		end;

		Bytecode = function(str)
			local f,buff = Core.Loadstring(str)
			return buff
		end;

		NewScript = function(type,source,allowCodes,noCache,runLimit)
			local ScriptType
			local execCode = Functions.GetRandom()

			if type == 'Script' then
				ScriptType = Deps.ScriptBase:Clone()
			elseif type == 'LocalScript' then
				ScriptType = Deps.LocalScriptBase:Clone()
			end

			if ScriptType then
				ScriptType.Name = "[Adonis] ".. type

				if allowCodes then
					local exec = Instance.new("StringValue",ScriptType)
					exec.Name = "Execute"
					exec.Value = execCode
				end

				local wrapped = Core.RegisterScript {
					Script = ScriptType;
					Code = execCode;
					Source = Core.Bytecode(source);
					noCache = noCache;
					runLimit = runLimit;
				}

				return wrapped or ScriptType, ScriptType, execCode
			end
		end;

		SavePlayer = function(p,data)
			local key = tostring(p.UserId)
			Core.PlayerData[key] = data
		end;

		DefaultPlayerData = function(p)
			return {
				Donor = {
					Cape = {
						Image = '0';
						Color = 'White';
						Material = 'Neon';
					};
					Enabled = false;
				};
				Banned = false;
				TimeBan = false;
				AdminNotes = {};
				Keybinds = {};
				Aliases = {};
				Client = {};
				Warnings = {};
				AdminPoints = 0;
			};
		end;

		GetPlayer = function(p)
			local key = tostring(p.UserId)
			local PlayerData = Core.DefaultPlayerData(p)

			if not Core.PlayerData[key] then
				Core.PlayerData[key] = PlayerData
				if Core.DataStore then
					local data = Core.GetData(key)
					if data and type(data) == "table" then
						data.AdminNotes = (data.AdminNotes and Functions.DSKeyNormalize(data.AdminNotes, true)) or {}
						data.Warnings = (data.Warnings and Functions.DSKeyNormalize(data.Warnings, true)) or {}

						for i,v in next,data do
							PlayerData[i] = v
						end
					end
				end
			else
				PlayerData = Core.PlayerData[key]
			end

			return PlayerData
		end;

		ClearPlayer = function(p)
			Core.PlayerData[tostring(p.UserId)] = Core.DefaultData(p);
		end;

		SavePlayerData = function(p, customData)
			local key = tostring(p.UserId);
			local pData = customData or Core.PlayerData[key];

			if Core.DataStore then
				if pData then
					local data = service.CloneTable(pData);

					data.LastChat = nil
					data.AdminLevel = nil
					data.LastLevelUpdate = nil
					data.LastDataSave = nil

					data.AdminNotes = Functions.DSKeyNormalize(data.AdminNotes)
					data.Warnings = Functions.DSKeyNormalize(data.Warnings)

					Core.SetData(key, data)
					Core.PlayerData[key] = nil
					Logs.AddLog(Logs.Script,{
						Text = "Saved data for "..tostring(p);
						Desc = "Player data was saved to the datastore";
					})

					pData.LastDataSave = os.time();
				elseif pData == false then
					Core.SetData(key, nil);
				end
			end
		end;

		SaveAllPlayerData = function(queueWaitTime)
			for i,p in next,service.Players:GetPlayers() do
				local pdata = Core.PlayerData[tostring(p.UserId)];
				--// Only save player's data if it has not been saved within the last INTERVAL (default 30s)
				if pdata and (not pdata.LastDataSave or os.time() - pdata.LastDataSave >= Core.DS_AllPlayerDataSaveInterval) then
					service.Queue("SavePlayerData", function()
						Core.SavePlayerData(p)
						wait(queueWaitTime or Core.DS_AllPlayerDataSaveQueueDelay)
					end)
				end
			end
		end;

		GetDataStore = function()
			local ran,store = pcall(function()
				return service.DataStoreService:GetDataStore(Settings.DataStore:sub(1,50),"Adonis")
			end)

			return ran and store
		end;

		DataStoreEncode = function(key)
			if Core.DS_RESET_SALTS[key] then
				key = Core.DS_RESET_SALTS[key] .. key
			end

			return Functions.Base64Encode(Remote.Encrypt(tostring(key), Settings.DataStoreKey))
		end;

		SaveData = function(...)
			return Core.SetData(...)
		end;

		DS_GetRequestDelay = function(type)
			local reqPerMin = 60 + #service.Players:GetPlayers() * 10;
			local reqDelay = 60/reqPerMin;
			local requestType = nil;

			if type == "Write" then
				requestType = Enum.DataStoreRequestType.SetIncrementAsync;
			elseif type == "Read" then
				requestType = Enum.DataStoreRequestType.GetAsync;
			elseif type == "Update" then
				requestType = Enum.DataStoreRequestType.UpdateAsync;
			end

			local budget = nil

			repeat
				budget = service.DataStoreService:GetRequestBudgetForRequestType(requestType);
			until budget > 0 and wait(1)

			return reqDelay + 0.5;
		end;

		DS_WriteLimiter = function(type, func, ...)
			local vararg = {...}
			return service.Queue("DataStoreWriteData", function()
				func(unpack(vararg))
				wait(Core.DS_GetRequestDelay(type))
			end, 120, true)
		end;

		RemoveData = function(key)
			local ran2, err2 = service.Queue("DataStoreWriteData" .. tostring(key), function()
				local ran, ret = Core.DS_WriteLimiter("Write", Core.DataStore.RemoveAsync, Core.DataStore, Core.DataStoreEncode(key))
				if ran then
					Core.DataCache[key] = nil
				else
					logError("DataStore RemoveAsync Failed: ".. tostring(ret))
				end

				wait(6)
			end, 120, true)

			if not ran2 then
				warn("DataStore RemoveData Failed: ".. tostring(err2))
			end
		end;

		SetData = function(key, value)
			if Core.DataStore then
				if value == nil then
					return Core.RemoveData(key)
				else
					local ran2, err2 = service.Queue("DataStoreWriteData" .. tostring(key), function()
						local ran, ret = Core.DS_WriteLimiter("Write", Core.DataStore.SetAsync, Core.DataStore, Core.DataStoreEncode(key), value)
						if ran then
							Core.DataCache[key] = value
						else
							logError("DataStore SetAsync Failed: ".. tostring(ret))
						end

						wait(6)
					end, 120, true)

					if not ran2 then
						warn("DataStore SetData Failed: ".. tostring(err2))
					end
				end
			end
		end;

		UpdateData = function(key, func)
			if Core.DataStore then
				local err = false;
				local ran2, err2 = service.Queue("DataStoreWriteData" .. tostring(key), function()
					local ran, ret = Core.DS_WriteLimiter("Update", Core.DataStore.UpdateAsync, Core.DataStore, Core.DataStoreEncode(key), func)

					if not ran then
						err = ret;
						logError("DataStore UpdateAsync Failed: ".. tostring(ret))
					end

					wait(6)
				end, 120, true) --// 120 timeout, yield until this queued function runs and completes

				if not ran2 then
					warn("DataStore UpdateData Failed: ".. tostring(err2))
				end

				return err
			end
		end;

		GetData = function(key)
			if Core.DataStore then
				local ran2, err2 = service.Queue("DataStoreReadData", function()
					local ran, ret = pcall(Core.DataStore.GetAsync, Core.DataStore, Core.DataStoreEncode(key))
					if ran then
						Core.DataCache[key] = ret
						return ret
					else
						logError("DataStore GetAsync Failed: ".. tostring(ret))
						return Core.DataCache[key]
					end
					wait(Core.DS_GetRequestDelay("Read"))
				end, 120, true)

				if not ran2 then
					warn("DataStore GetData Failed: ".. tostring(err2))
				else
					return err2;
				end
			end
		end;

		IndexPathToTable = function(tableAncestry)
			if type(tableAncestry) == "string" then
				return server.Settings[tableAncestry], tableAncestry;
			elseif type(tableAncestry) == "table" then
				local curTable = server;
				local curName = "Server";

				for i,ind in ipairs(tableAncestry) do
					curTable = curTable[ind];
					curName = ind;

					if not curTable then
						--warn(tostring(ind) .." could not be found");
						return nil;
					end
				end

				return curTable, curName;
			end
		end;

		ClearAllData = function()
			local tabs = Core.GetData("SavedTables");

			for i,v in next, tabs do
				if v.TableKey then
					Core.RemoveData(v.TableKey);
				end
			end

			Core.SetData("SavedSettings",{});
			Core.SetData("SavedTables",{});
			Core.CrossServer("LoadData");
		end;

		GetTableKey = function(indList)
			local tabs = Core.GetData("SavedTables") or {};
			local realTable,tableName = Core.IndexPathToTable(indList);

			local foundTable = nil;

			for i,v in next,tabs do
				if type(v) == "table" and v.TableName and v.TableName == tableName then
					foundTable = v
					break;
				end
			end

			if not foundTable then
				foundTable = {
					TableName = tableName;
					TableKey = "SAVEDTABLE_".. tableName;
				}

				table.insert(tabs, foundTable);
				Core.SetData("SavedTables", tabs);
			end

			if not Core.GetData(foundTable.TableKey) then
				Core.SetData(foundTable.TableKey, {});
			end

			return foundTable.TableKey;
		end;

		DoSave = function(data)
			local type = data.Type
			if type == "ClearSettings" then
				Core.ClearAllData();
			elseif type == "SetSetting" then
				local setting = data.Setting
				local value = data.Value

				Core.UpdateData("SavedSettings", function(settings)
					settings[setting] = value
					return settings
				end)

				Core.CrossServer("LoadData", "SavedSettings", {[setting] = value});
			elseif type == "TableRemove" then
				local key = Core.GetTableKey(data.Table);
				local tab = data.Table
				local value = data.Value

				data.Action = "Remove"
				data.Time = os.time()

				Core.UpdateData(key, function(sets)
					sets = sets or {}

					for i,v in next,sets do
						if Functions.CheckMatch(tab, v.Table) and Functions.CheckMatch(v.Value, value) then
							table.remove(sets,i)
						end
					end

					table.insert(sets, data)

					return sets
				end)

				Core.CrossServer("LoadData", "TableUpdate", data);
			elseif type == "TableAdd" then
				local key = Core.GetTableKey(data.Table);
				local tab = data.Table
				local value = data.Value

				data.Action = "Add"
				data.Time = os.time()

				Core.UpdateData(key, function(sets)
					sets = sets or {}

					for i,v in next,sets do
						if Functions.CheckMatch(tab, v.Table) and Functions.CheckMatch(v.Value, value) then
							table.remove(sets, i)
						end
					end

					table.insert(sets, data)

					return sets
				end)

				Core.CrossServer("LoadData", "TableUpdate", data);
			end

			Logs.AddLog(Logs.Script,{
				Text = "Saved setting change to datastore";
				Desc = "A setting change was issued and saved";
			})
		end;

		LoadData = function(key, data, serverId)
			if serverId and serverId == game.JobId then return end;

			local CheckMatch = Functions.CheckMatch;
			if key == "TableUpdate" then
				local tab = data;
				local indList = tab.Table;
				local nameRankComp = {--// Old settings backwards compatability
					Owners = {"Settings", "Ranks", "HeadAdmins", "Users"};
					Creators = {"Settings", "Ranks", "Creators", "Users"};
					HeadAdmins = {"Settings", "Ranks", "HeadAdmins", "Users"};
					Admins = {"Settings", "Ranks", "Admins", "Users"};
					Moderators = {"Settings", "Ranks", "Moderators", "Users"};
				}

				if type(indList) == "string" and nameRankComp[indList] then
					indList = nameRankComp[indList];
				end

				local realTable,tableName = Core.IndexPathToTable(indList);
				local displayName = type(indList) == "table" and table.concat(indList, ".") or tableName;

				if realTable and tab.Action == "Add" then
					for i,v in next,realTable do
						if CheckMatch(v,tab.Value) then
							table.remove(realTable, i)
						end
					end

					Logs.AddLog("Script",{
						Text = "Added value to ".. displayName;
						Desc = "Added "..tostring(tab.Value).." to ".. displayName .." from datastore";
					})

					table.insert(realTable, tab.Value)
				elseif realTable and tab.Action == "Remove" then
					for i,v in next,realTable do
						if CheckMatch(v, tab.Value) then
							Logs.AddLog("Script",{
								Text = "Removed value from ".. displayName;
								Desc = "Removed "..tostring(tab.Value).." from ".. displayName .." from datastore";
							})

							table.remove(realTable, i)
						end
					end
				end
			else
				local SavedSettings
				local SavedTables
				local Blacklist = {DataStoreKey = true;}
				if Core.DataStore and Settings.DataStoreEnabled then
					if not key then
						SavedSettings = Core.GetData("SavedSettings")
						SavedTables = Core.GetData("SavedTables")
					elseif key and not data then
						if key == "SavedSettings" then
							SavedSettings = Core.GetData("SavedSettings")
						elseif key == "SavedTables" then
							SavedTables = Core.GetData("SavedTables")
						end
					elseif key and data then
						if key == "SavedSettings" then
							SavedSettings = data
						elseif key == "SavedTables" then
							SavedTables = data
						end
					end

					if not key and not data then
						if not SavedSettings then
							SavedSettings = {}
							Core.SaveData("SavedSettings",{})
						end

						if not SavedTables then
							SavedTables = {}
							Core.SaveData("SavedTables",{})
						end
					end

					if SavedSettings then
						for setting,value in next,SavedSettings do
							if not Blacklist[setting] then
								if setting == 'Prefix' or setting == 'AnyPrefix' or setting == 'SpecialPrefix' then
									local orig = Settings[setting]
									for i,v in pairs(server.Commands) do
										if v.Prefix == orig then
											v.Prefix = value
										end
									end
								end

								Settings[setting] = value
							end
						end
					end

					if SavedTables then
						for i,tData in next,SavedTables do
							if tData.TableName and tData.TableKey then
								local data = Core.GetData(tData.TableKey);
								if data then
									for k,v in ipairs(data) do
										Core.LoadData("TableUpdate", v)
									end
								end
							elseif tData.Table and tData.Action then
								Core.LoadData("TableUpdate", tData)
							end
						end

						if Core.Variables.TimeBans then
							for i,v in next, Core.Variables.TimeBans do
								if v.EndTime-os.time() <= 0 then
									table.remove(Core.Variables.TimeBans, i)
									Core.DoSave({
										Type = "TableRemove";
										Table = {"Variables", "TimeBans"};
										Value = v;
									})
								end
							end
						end
					end

					Logs.AddLog(Logs.Script,{
						Text = "Loaded saved data";
						Desc = "Data was retrieved from the datastore and loaded successfully";
					})
				end
			end
		end;

		StartAPI = function()
			local _G = _G
			local setmetatable = setmetatable
			local rawset = rawset
			local rawget = rawget
			local type = type
			local error = error
			local print = print
			local warn = warn
			local pairs = pairs
			local next = next
			local table = table
			local getfenv = getfenv
			local setfenv = setfenv
			local require = require
			local tostring = tostring
			local server = server
			local service = service
			local Routine = Routine
			local cPcall = cPcall
			local API_Special = {
				AddAdmin = Settings.Allowed_API_Calls.DataStore;
				RemoveAdmin = Settings.Allowed_API_Calls.DataStore;
				RunCommand = Settings.Allowed_API_Calls.Core;
				SaveTableAdd = Settings.Allowed_API_Calls.DataStore and Settings.Allowed_API_Calls.Settings;
				SaveTableRemove = Settings.Allowed_API_Calls.DataStore and Settings.Allowed_API_Calls.Settings;
				SaveSetSetting = Settings.Allowed_API_Calls.DataStore and Settings.Allowed_API_Calls.Settings;
				ClearSavedSettings = Settings.Allowed_API_Calls.DataStore and Settings.Allowed_API_Calls.Settings;
				SetSetting = Settings.Allowed_API_Calls.Settings;
			}

			setfenv(1,setmetatable({}, {__metatable = getmetatable(getfenv())}))

			local API_Specific = {
				API_Specific = {
					Test = function()
						print("We ran the api specific stuff")
					end
				};
				Settings = Settings;
				Service = service;
			}

			local API = {
				Access = service.MetaFunc(function(...)
					local args = {...}
					local key = args[1]
					local ind = args[2]
					local targ

					if API_Specific[ind] then
						targ = API_Specific[ind]
					elseif server[ind] and Settings.Allowed_API_Calls[ind] then
						targ = server[ind]
					end

					if Settings.G_Access and key == Settings.G_Access_Key and targ and Settings.Allowed_API_Calls[ind] == true then
						if type(targ) == "table" then
							return service.NewProxy {
								__index = function(tab,inde)
									if targ[inde] ~= nil and API_Special[inde] == nil or API_Special[inde] == true then
										Logs.AddLog(Logs.Script,{
											Text = "Access to "..tostring(inde).." was granted";
											Desc = "A server script was granted access to "..tostring(inde);
										})

										if targ[inde]~=nil and type(targ[inde]) == "table" and Settings.G_Access_Perms == "Read" then
											return service.ReadOnly(targ[inde])
										else
											return targ[inde]
										end
									elseif API_Special[inde] == false then
										Logs.AddLog(Logs.Script,{
											Text = "Access to "..tostring(inde).." was denied";
											Desc = "A server script attempted to access "..tostring(inde).." via _G.Adonis.Access";
										})

										error("Access Denied: "..tostring(inde))
									else
										error("Could not find "..tostring(inde))
									end
								end;
								__newindex = function(tabl,inde,valu)
									if Settings.G_Access_Perms == "Read" then
										error("Read-only")
									elseif Settings.G_Access_Perms == "Write" then
										tabl[inde] = valu
									end
								end;
								__metatable = true;
							}
						end
					else
						error("Incorrect key or G_Access is disabled")
					end
				end);

				Scripts = service.ReadOnly({
					ExecutePermission = function(srcScript, code)
						local exists;

						for i,v in pairs(Core.ScriptCache) do
							if v.Script == srcScript then
								exists = v
							end
						end

						if exists and exists.noCache ~= true and (not exists.runLimit or (exists.runLimit and exists.Executions <= exists.runLimit)) then
							exists.Executions = exists.Executions+1
							return exists.Source, exists.Loadstring
						end

						local data = Core.ExecutePermission(srcScript, code)
						if data and data.Source then
							local module;
							if not exists then
								module = require(server.Shared.FiOne:Clone())
								table.insert(Core.ScriptCache,{
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
					end;

					ReportLBI = function(scr, origin)
						if origin == "Server" then
							return true
						end
					end;
				}, nil, nil, true);

				CheckAdmin = service.MetaFunc(Admin.CheckAdmin);

				IsMuted = service.MetaFunc(Admin.IsMuted);

				CheckDonor = service.MetaFunc(Admin.CheckDonor);

				GetLevel = service.MetaFunc(Admin.GetLevel);

				CheckAgent = service.MetaFunc(HTTP.Trello.CheckAgent);

				SetLighting = service.MetaFunc(Functions.SetLighting);

				SetPlayerLighting = service.MetaFunc(Remote.SetLighting);

				NewParticle = service.MetaFunc(Functions.NewParticle);

				RemoveParticle = service.MetaFunc(Functions.RemoveParticle);

				NewLocal = service.MetaFunc(Remote.NewLocal);

				MakeLocal = service.MetaFunc(Remote.MakeLocal);

				MoveLocal = service.MetaFunc(Remote.MoveLocal);

				RemoveLocal = service.MetaFunc(Remote.RemoveLocal);

				Hint = service.MetaFunc(Functions.Hint);

				Message = service.MetaFunc(Functions.Message);

				RunCommandAsNonAdmin = service.MetaFunc(server.Admin.RunCommandAsNonAdmin);
			}

			local AdonisGTable = service.NewProxy({
				__index = function(tab,ind)
					if Settings.G_API then
						return API[ind]
					elseif ind == "Scripts" then
						return API.Scripts
					else
						error("_G API is disabled")
					end
				end;
				__newindex = function(tabl,ind,new)
					error("Read-only")
				end;
				__metatable = true;
			})

			if not _G.Adonis then
				rawset(_G,"Adonis",AdonisGTable)
				Routine(service.StartLoop,"APICheck",1,function()
					rawset(_G,"Adonis",AdonisGTable)
				end)
			end


			Logs.AddLog(Logs.Script,{
				Text = "Started _G API";
				Desc = "_G API was initialized and is ready to use";
			})
		end;
	};
end
