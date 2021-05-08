server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

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
		Core.Loadstring = require(Deps.Loadstring)

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

		--// Start API
		if service.NetworkServer then
			--service.Threads.RunTask("_G API Manager",server.Core.StartAPI)
			service.TrackTask("Thread: API Manager", server.Core.StartAPI)
		end

		--// Add existing players in case some are already in the server
		for index,player in next,service.Players:GetPlayers() do
			service.TrackTask("Thread: LoadPlayer ".. tostring(player.Name), server.Core.LoadExistingPlayer, player);
		end

		Core.RunAfterPlugins = nil;
		Logs:AddLog("Script", "Core Module RunAfterPlugins Finished");
	end

	server.Core = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		DataQueue = {};
		DataCache = {};
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

		DS_RESET_SALTS = { --// Used to change/"reset" specific datastore keys
			SavedSettings = "32K5j4";
			SavedTables = 	"32K5j4";
		};

		Panic = function(reason)
			local hint = Instance.new("Hint", service.Workspace)
			hint.Text = "-= Adonis PanicMode Enabled: "..tostring(reason).." =~"
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
					Core.Panic("JointsService RobloxLocked")
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
				local playerGui = p:FindFirstChildOfClass("PlayerGui") or p:WaitForChild("PlayerGui", 600);

				if playerGui and playerGui.ClassName ~= "PlayerGui" then
					playerGui = p:FindFirstChildOfClass("PlayerGui");
				end

				if not p.Parent then
					return false
				elseif not playerGui then
					p:Kick("Loading Error: PlayerGui Missing (Waited 10 Minutes)")
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
				acli.Disabled = false;

				--[[service.Events[p.userId.."_CLIENTLOADER"]:connectOnce(function()
					if container.Parent == playerGui then
						container:Destroy()
					end
				end)--]]

				local ok,err = pcall(function()
					container.Parent = playerGui
				end)

				if not Core.PanicMode and not ok then
					p:Kick("Loading Error [HookClient Error: "..tostring(err).."]")
					return false
				else
					return true
				end
			else
				if p then p:Kick("Loading Error [HookClient: Keys Missing]") end
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
			for i,val in next,Core.ExecuteScripts do
				if not isLocal or (isLocal and val.Type == "LocalScript") then
					if (service.UnWrap(val.Script) == service.UnWrap(scr) or code == val.Code) and (not val.runLimit or (val.runLimit ~= nil and val.Executions <= val.runLimit)) then
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
			for i,val in next,Core.ExecuteScripts do
				if val.Script == scr or code == val.Code then
					return val,i
				end
			end
		end;

		UnRegisterScript = function(scr)
			for i,dat in next,Core.ExecuteScripts do
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

			for ind,scr in next,Core.ExecuteScripts do
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

		Loadstring = function(str, env)
			return require(Deps.Loadstring:Clone())(str, env)
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
				ScriptType.Name = type

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

		DoSave = function(data)
			local type = data.Type
			if type == "ClearSettings" then
				Core.SetData("SavedSettings",{});
				Core.SetData("SavedTables",{});
				Core.CrossServer("LoadData");
			elseif type == "SetSetting" then
				local setting = data.Setting
				local value = data.Value

				Core.UpdateData("SavedSettings", function(settings)
					settings[setting] = value
					return settings
				end)

				Core.CrossServer("LoadData", "SavedSettings", {[setting] = value});
			elseif type == "TableRemove" then
				local tab = data.Table
				local value = data.Value
				data.Time = os.time()

				Core.UpdateData("SavedTables", function(sets)
					sets = sets or {}
					for i,v in next,sets do
						if tab == v.Table then
							if Functions.CheckMatch(v.Value,value) then
								table.remove(sets,i)
							end
						end
					end

					data.Action = "Remove"
					table.insert(sets,data)
					return sets
				end)


				Core.CrossServer("LoadData", "SavedTables");
			elseif type == "TableAdd" then
				local tab = data.Table
				local value = data.Value
				data.Time = os.time()
				Core.UpdateData("SavedTables", function(sets)
					sets = sets or {}
					for i,v in next,sets do
						if tab == v.Table then
							if Functions.CheckMatch(v.Value,value) then
								table.remove(sets,i)
							end
						end
					end
					data.Action = "Add"
					table.insert(sets,data)
					return sets
				end)

				Core.CrossServer("LoadData", "SavedTables");
			end

			Logs.AddLog(Logs.Script,{
				Text = "Saved setting change to datastore";
				Desc = "A setting change was issued and saved";
			})
		end;

		SavePlayer = function(p,data)
			local key = tostring(p.UserId)
			Remote.PlayerData[key] = data
		end;

		DefaultData = function(p)
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
			local PlayerData = Core.DefaultData(p)

			if not Remote.PlayerData[key] then
				Remote.PlayerData[key] = PlayerData
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
				PlayerData = Remote.PlayerData[key]
			end

			return PlayerData
		end;

		ClearPlayer = function(p)
			Remote.PlayerData[tostring(p.UserId)] = Core.DefaultData(p);
		end;

		SavePlayerData = function(p)
			local key = tostring(p.UserId)
			local data = Remote.PlayerData[key]
			if data and Core.DataStore then
				data.LastChat = nil
				data.AdminLevel = nil
				data.LastLevelUpdate = nil

				data.AdminNotes = Functions.DSKeyNormalize(data.AdminNotes)
				data.Warnings = Functions.DSKeyNormalize(data.Warnings)

				Core.SetData(key, data)
				Remote.PlayerData[key] = nil
				Logs.AddLog(Logs.Script,{
					Text = "Saved data for "..tostring(p);
					Desc = "Player data was saved to the datastore";
				})
			end
		end;

		GetDataStore = function()
			local lastUpdate = 0
			local keyCache = {}
			local saveCache = {}
			local updateCache = {}
			local ran,store = pcall(function() return service.DataStoreService:GetDataStore(Settings.DataStore:sub(1,50),"Adonis") end)

			--[[

			--// Todo:
			--// Implement reru's idea
			--// AutoAssign a server to handle datastore updates
			--// Cache all datastore updates
			--// Update everything using one UpdateAsync per server every 30-60 seconds
			--// Have main server handle check for new data and update datastore keys accordingly

			if ran and store then
				local original = store:GetObject()
				local prepareTable; prepareTable = function(tab)
					if true then return tab end
					if type(tab) == "table" then
						local tabUpdates = {}
						for i,v in next,tab do
							tab[i] = prepareTable(v)
						end

						return setmetatable(tab,{
							__newindex = function(old, ind, val)
								table.insert(tabUpdates,{

								})
							end
						}), tabUpdates
					else
						return tab
					end
				end

				store:SetSpecial("SetAsync", function(wrapped, key, value)
					table.insert(updateCache, {
						Key = key;
						Time = os.time;
						Value = value;
					})

					keyCache[key] = value
				end)

				store:SetSpecial("UpdateAsync", function(wrapped, key, func)
					original:UpdateAsync(key, function(data)
						local metaTab,tabUpdates = prepareTable(data)
						local returns = func(metaTab)
						if type(data) == "table" and tabUpdates then

						end
					end)
				end)

				store:SetSpecial("GetAsync", function(wrapped, key)
					if not keyCache[key] then
						keyCache[key] = original:GetAsync(key)
					end

					return keyCache[key]
				end)

				store:SetSpecial("Update", function(wrapped)
					lastUpdate = os.time()
					keyCache = {}
				end)

				service.StartLoop("DataUpdate",30,store.Update,true)
			end--]]

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

		SetData = function(key, value)
			if Core.DataStore then
				service.Queue("DataStoreSetData".. tostring(key), function()
					local ran, ret = pcall(Core.DataStore.SetAsync, Core.DataStore, Core.DataStoreEncode(key), value)
					if ran then
						Core.DataCache[key] = value
					else
						logError("DataStore SetAsync Failed: ".. tostring(ret))
					end
				end)
			end
		end;

		UpdateData = function(key, func)
			if Core.DataStore then
				local didUpdate = false;
				local err = false;

				delay(120, function() didUpdate = true err = "Took too long" end)
				service.Queue("DataStoreUpdateData".. tostring(key), function()
					local ran, ret = pcall(Core.DataStore.UpdateAsync, Core.DataStore, Core.DataStoreEncode(key), func)

					if ran then
						--return ret
					else
						logError("DataStore UpdateAsync Failed: ".. tostring(ret))
					end

					wait(5)
					didUpdate = true
				end)
				repeat wait() until didUpdate
				return err
			end
		end;

		GetData = function(key)
			if Core.DataStore then
				local ran, ret = pcall(Core.DataStore.GetAsync, Core.DataStore, Core.DataStoreEncode(key))
				if ran then
					Core.DataCache[key] = ret
					return ret
				else
					logError("DataStore GetAsync Failed: ".. tostring(ret))
					return Core.DataCache[key]
				end
			end
		end;

		LoadData = function(key, data)
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
					for ind,tab in next,SavedTables do
						--// Owners to HeadAdmins compatability
						if tab.Table == "Owners" then
							tab.Table = "HeadAdmins"
						end

						local parentTab = (tab.Parent == "Variables" and Core.Variables) or Settings
						if (not Blacklist[tab.Table]) and parentTab[tab.Table] ~= nil then
							if tab.Action == "Add" then
								local tabl = parentTab[tab.Table]
								if tabl then
									for i,v in next,tabl do
										if Functions.CheckMatch(v,tab.Value) then
											table.remove(parentTab[tab.Table],i)
										end
									end
								end

								Logs.AddLog("Script",{
									Text = "Added to "..tostring(tab.Table);
									Desc = "Added "..tostring(tab.Value).." to "..tostring(tab.Table).." from datastore";
								})
								table.insert(parentTab[tab.Table],tab.Value)
							elseif tab.Action == "Remove" then
								local tabl = parentTab[tab.Table]
								if tabl then
									for i,v in next,tabl do
										if Functions.CheckMatch(v,tab.Value) then
											Logs.AddLog("Script",{
												Text = "Removed from "..tostring(tab.Table);
												Desc = "Removed "..tostring(tab.Value).." from "..tostring(tab.Table).." from datastore";
											})
											table.remove(parentTab[tab.Table],i)
										end
									end
								end
							end
						end
					end

					if Core.Variables.TimeBans then
						for i,v in next, Core.Variables.TimeBans do
							if v.EndTime-os.time() <= 0 then
								table.remove(Core.Variables.TimeBans, i)
								Core.DoSave({
									Type = "TableRemove";
									Table = "TimeBans";
									Parent = "Variables";
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
					ExecutePermission = function(code)
						local exists;

						if not Settings.CodeExecution then
							return nil
						end

						for i,v in pairs(Core.ScriptCache) do
							if v.Script == rawget(getfenv(2), "script") then
								exists = v
							end
						end

						if exists and exists.noCache ~= true and (not exists.runLimit or (exists.runLimit and exists.Executions <= exists.runLimit)) then
							exists.Executions = exists.Executions+1
							return exists.Source, exists.Loadstring
						end

						local data = Core.ExecutePermission(rawget(getfenv(2), "script"),code)
						if data and data.Source then
							local module;
							if not exists then
								module = require(Deps.Loadstring.FiOne:Clone())
								table.insert(Core.ScriptCache,{
									Script = rawget(getfenv(2), "script");
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
