--!nonstrict
type TableData = {
	Type: string,
	Table: {string}|string,
	Setting: string?,
	Value: any?,
	LaxCheck: boolean?,

	Action: string?,
	Time: number?
}

--// Core
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Deps;
	local AddLog, Queue, TrackTask
	local logError = env.logError
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
		Deps = server.Deps;

		AddLog = Logs.AddLog;
		Queue = service.Queue;
		TrackTask = service.TrackTask;
		logError = logError or env.logError;

		--// Core variables
		Core.Themes = data.Themes or {}
		Core.Plugins = data.Plugins or {}
		Core.ModuleID = data.ModuleID or 7510592873
		Core.LoaderID = data.LoaderID or 7510622625
		Core.DebugMode = data.DebugMode or false
		Core.Name = Functions:GetRandom()
		Core.LoadstringObj = Core.GetLoadstring()
		Core.Loadstring = require(Core.LoadstringObj)

		service.DataStoreService = require(Deps.MockDataStoreService)(Settings.LocalDatastore)

		local function disableAllGuis(folder: Folder)
			for _, v in folder:GetChildren() do
				if v:IsA("ScreenGui") then
					v.Enabled = false
				elseif v:IsA("Folder") or v:IsA("Model") then
					disableAllGuis(v)
				end
			end
		end
		disableAllGuis(server.Client.UI)

		Core.Init = nil;
		AddLog("Script", "Core Module Initialized")
	end;

	local function RunAfterPlugins(data)
		--// RemoteEvent Handling
		Core.MakeEvent()

		--// Prepare the client loader
		--local existingPlayers = service.Players:GetPlayers();
		--Core.MakeClient()

		local remoteParent = service.ReplicatedStorage;
		remoteParent.ChildRemoved:Connect(function(c)
			task.wait(1/60)

			if server.Core.RemoteEvent and not Core.FixingEvent and (function() for i,v in Core.RemoteEvent do if c == v then return true end end end)() then
				Core.MakeEvent()
			end
		end)

		--// Load data
		Core.DataStore = Core.GetDataStore()
		if Core.DataStore then
			TrackTask("Thread: DSLoadAndHook", function()
				--// Catch any errors and print it to the console; allow for debugging.
				task.defer(env.Pcall, Core.LoadData)
			end)
		end

		--// Start API
		if service.NetworkServer then
			--service.Threads.RunTask("_G API Manager",server.Core.StartAPI)
			TrackTask("Thread: API Manager", Core.StartAPI)
		end

		--// Occasionally save all player data to the datastore to prevent data loss if the server abruptly crashes
		service.StartLoop("SaveAllPlayerData", Core.DS_AllPlayerDataSaveInterval, Core.SaveAllPlayerData, true)

		Core.RunAfterPlugins = nil;
		AddLog("Script", "Core Module RunAfterPlugins Finished");
	end

	server.Core = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		DataQueue = {};
		DataCache = {};
		PlayerData = {};
		CrossServerCommands = {};
		CrossServer = function(...) return false end;
		ExecuteScripts = {};
		LastDataSave = 0;
		FixingEvent = false;
		ScriptCache = {};
		Connections = {};
		BytecodeCache = {};
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

		DS_BLACKLIST = {
			Trello_Enabled = true;
			Trello_Primary = true;
			Trello_Secondary = true;
			Trello_Token = true;
			Trello_AppKey = true;

			DataStore = true;
			DataStoreKey = true;
			DataStoreEnabled = true;
			LocalDatastore = true;

			Creators = true;
			Permissions = true;

			G_API = true;
			G_Access = true;
			G_Access_Key = true;
			G_Access_Perms = true;
			Allowed_API_Calls = true;

			LoadAdminsFromDS = true;

			WebPanel_ApiKey = true;
			WebPanel_Enabled = true;

			["Settings.Ranks.Creators.Users"] = true;
			["Admin.SpecialLevels"] = true;

			OnStartup = true;
			OnSpawn = true;
			OnJoin = true;

			CustomRanks = true;
			Ranks = true;

			--// Not gonna let malicious stuff set DS_Blacklist to {} or anything!
			DS_BLACKLIST = true;
		};

		--// Prevent certain keys from loading from the DataStore
		PlayerDataKeyBlacklist = {
			AdminRank = true;
			AdminLevel = true;
			LastLevelUpdate = true;
		};

		DisconnectEvent = function()
			if Core.RemoteEvent and not Core.FixingEvent then
				Core.FixingEvent = true

				for name,event in Core.RemoteEvent.Events do
					event:Disconnect()
				end

				pcall(function() service.Delete(Core.RemoteEvent.Object) end)
				pcall(function() service.Delete(Core.RemoteEvent.Function) end)

				Core.FixingEvent = false
				Core.RemoteEvent = nil
			end
		end;

		MakeEvent = function()
			local remoteParent = service.ReplicatedStorage
			local ran, err = pcall(function()
				if server.Running then
					local rTable = {};
					local event = service.New("RemoteEvent", {Name = Core.Name, Archivable = false}, true, true)
					local func = service.New("RemoteFunction", {Name = "__FUNCTION", Parent = event}, true, true)
					local secureTriggered = true
					local tripDet = math.random()

					local function secure(ev, name, parent)
						return ev.Changed:Connect(function()
							if Core.RemoteEvent == rTable and not secureTriggered then
								if ev == func then
									func.OnServerInvoke = Process.Remote
								end

								if ev.Name ~= name then
									ev.Name = name
								elseif ev.Parent ~= parent then
									secureTriggered = true;
									Core.DisconnectEvent();
									Core.MakeEvent()
								end
							end
						end)
					end

					Core.DisconnectEvent()
					Core.TripDet = tripDet

					rTable.Events = {}
					rTable.Object = event
					rTable.Function = func

					rTable.Events.Security = secure(event, event.Name, remoteParent)
					rTable.Events.FuncSec = secure(func, func.Name, event)

					func.OnServerInvoke = Process.Remote;
					rTable.Events.ProcessEvent = service.RbxEvent(event.OnServerEvent, Process.Remote)

					Core.RemoteEvent = rTable
					event.Parent = remoteParent
					secureTriggered = false

					AddLog(Logs.Script, {
						Text = "Created RemoteEvent";
						Desc = "RemoteEvent was successfully created";
					})
				end
			end)

			if err then
				warn(err)
			end
		end;

		UpdateConnections = function()
			if service.NetworkServer then
				for _, cli in service.NetworkServer:GetChildren() do
					if cli:IsA("NetworkReplicator") then
						Core.Connections[cli] = cli:GetPlayer()
					end
				end
			end
		end;

		UpdateConnection = function(p)
			if service.NetworkServer then
				for _, cli in service.NetworkServer:GetChildren() do
					if cli:IsA("NetworkReplicator") and cli:GetPlayer() == p then
						Core.Connections[cli] = p
					end
				end
			end
		end;

		GetNetworkClient = function(p)
			if service.NetworkServer then
				for _, cli in service.NetworkServer:GetChildren() do
					if cli:IsA("NetworkReplicator") and cli:GetPlayer() == p then
						return cli
					end
				end
			end
		end;

		MakeClient = function(parent)
			if not parent and Core.ClientLoader then
				local loader = Core.ClientLoader
				loader.Removing = true

				for _, v in loader.Events do
					v:Disconnect()
				end

				loader.Object:Destroy()
			end;

			local depsName = Functions:GetRandom()
			local folder = server.Client:Clone()
			local acli = Deps.ClientMover:Clone();
			local client = folder.Client
			local parentObj = parent or service.StarterPlayer:FindFirstChildOfClass("StarterPlayerScripts");
			local clientLoader = {
				Removing = false;
			};

			Core.MockClientKeys = Core.MockClientKeys or {
				Special = depsName;
				Module = client;
			}

			local depsName = Core.MockClientKeys.Special;
			local specialVal = service.New("StringValue")
			specialVal.Value = Core.Name.."\\"..depsName
			specialVal.Name = "Special"
			specialVal.Parent = folder

			acli.Parent = folder;
			acli.Disabled = false;

			folder.Archivable = false;
			folder.Name = depsName; --"Adonis_Client"
			folder.Parent = parentObj;

			if not parent then
				local oName = folder.Name
				clientLoader.Object = folder
				clientLoader.Events = {}

				clientLoader.Events[folder] = folder.Changed:Connect(function()
					if Core.ClientLoader == clientLoader and not clientLoader.Removing then
						if folder.Name ~= oName then
							folder.Name = oName;
						elseif folder.Parent ~= parentObj then
							clientLoader.Removing = true
							Core.MakeClient()
						end
					end
				end)

				for _, child in folder:GetDescendants() do
					local oParent = child.Parent
					local oName = child.Name

					clientLoader.Events[child.Changed] = child.Changed:Connect(function(c)
						if Core.ClientLoader == clientLoader and not clientLoader.Removing then
							if child.Parent ~= oParent or child == specialVal then
								Core.MakeClient()
							end
						end
					end)

					local nameEvent = child:GetPropertyChangedSignal("Name"):Connect(function()
						if Core.ClientLoader == clientLoader and not clientLoader.Removing then
							child.Name = oName
						end
					end)

					clientLoader.Events[nameEvent] = nameEvent
					clientLoader.Events[child.AncestryChanged] = child.AncestryChanged:Connect(function()
						if Core.ClientLoader == clientLoader and not clientLoader.Removing then
							Core.MakeClient()
						end
					end)
				end

				folder.DescendantAdded:Connect(function(d)
					if Core.ClientLoader == clientLoader and not clientLoader.Removing then
						Core.MakeClient()
					end
				end)

				folder.DescendantRemoving:Connect(function(d)
					if Core.ClientLoader == clientLoader and not clientLoader.Removing then
						Core.MakeClient()
					end
				end)

				Core.ClientLoader = clientLoader
			end


			local ok,err = pcall(function()
				folder.Parent = parentObj
			end)

			clientLoader.Removing = false;

			AddLog("Script", "Created client")
		end;

		HookClient = function(p)
			local key = tostring(p.UserId)
			local keys = Remote.Clients[key]
			if keys then
				local depsName = Functions:GetRandom()
				local eventName = Functions:GetRandom()
				local folder = server.Client:Clone()
				local acli = Deps.ClientMover:Clone();
				local client = folder.Client
				local parentTo = "PlayerGui" --// Roblox, seriously, please give the server access to PlayerScripts already so I don't need to do this.
				local parentObj = p:FindFirstChildOfClass(parentTo) or p:WaitForChild(parentTo, 600);

				if not p.Parent then
					return false
				elseif not parentObj then
					p:Kick("\n[CLI-102495] Loading Error \nPlayerGui Missing (Waited 10 Minutes)")
					return false
				end

				local container = service.New("ScreenGui");
				container.ResetOnSpawn = false;
				container.Enabled = false;
				container.Name = "\0";

				local specialVal = service.New("StringValue")
				specialVal.Value = Core.Name.."\\"..depsName
				specialVal.Name = "Special"
				specialVal.Parent = folder

				keys.Special = depsName
				keys.EventName = eventName
				keys.Module = client

				acli.Parent = folder;
				acli.Disabled = false;

				folder.Name = "Adonis_Client"
				folder.Parent = container;

				--// Event only fires AFTER the client is alive and well
				local event; event = service.Events.ClientLoaded:Connect(function(plr)
					if p == plr and container.Parent == parentObj then

						--container:Destroy(); -- Destroy update causes an issue with this pretty sure
						container.Parent = nil
						local leaveEvent; leaveEvent = p.AncestryChanged:Connect(function() -- after/on remove, not on removing...
							task.wait()
							if p.Parent == nil then
								-- Prevent potential memory leak and ensure this gets properly murdered when they leave and it's no longer needed
								pcall(function()
									container:Destroy()
								end)
							end
						end)

						leaveEvent:Disconnect()
						leaveEvent = nil
						event:Disconnect();
						event = nil
					end
				end)

				local ok, err = pcall(function()
					container.Parent = parentObj
				end)

				if not ok then
					p:Kick("\n[CLI-192385] Loading Error \n[HookClient Error: "..tostring(err).."]")
					return false
				else
					return true
				end
			else
				if p and p.Parent then
					p:Kick("\n[CLI-5691283] Loading Error \n[HookClient: Keys Missing]")
				end
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

			TrackTask("Thread: Setup Existing Player: ".. tostring(p), function()
				Process.PlayerAdded(p)
				--Core.MakeClient(p:FindFirstChildOfClass("PlayerGui") or p:WaitForChild("PlayerGui", 120))
			end)
		end;

		ExecutePermission = function(scr, code, isLocal)
			local fixscr = service.UnWrap(scr)

			for _, val in Core.ExecuteScripts do
				if not isLocal or (isLocal and val.Type == "LocalScript") then
					if (service.UnWrap(val.Script) == fixscr or code == val.Code) and (not val.runLimit or (val.runLimit ~= nil and val.Executions <= val.runLimit)) then
						val.Executions += 1

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

		GetScript = function(scr, code)
			for i, val in Core.ExecuteScripts do
				if val.Script == scr or code == val.Code then
					return val, i
				end
			end
		end;

		UnRegisterScript = function(scr)
			for i, dat in Core.ExecuteScripts do
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
				return Core.RegisterScript({
					Script = service.UnWrap(data.Script):Clone();
					Code = data.Code;
					Source = data.Source;
					noCache = data.noCache;
					runLimit = data.runLimit;
				})
			end)

			for ind,scr in Core.ExecuteScripts do
				if scr.Script == data.Script then
					return scr.Wrapped or scr.Script
				end
			end

			if not data.Code then
				data.Code = Functions.GetRandom()
			end

			table.insert(Core.ExecuteScripts, data)
			return data.Wrapped
		end;

		GetLoadstring = function()
			local newLoad = Deps.Loadstring:Clone()
			local lbi = server.Shared.FiOne:Clone()

			lbi.Parent = newLoad

			return newLoad
		end;

		Bytecode = function(str: string)
			if Core.BytecodeCache[str] then return Core.BytecodeCache[str] end
			local f, buff = Core.Loadstring(str)
			Core.BytecodeCache[str] = buff
			return buff
		end;

		NewScript = function(scriptType: string, source: string, allowCodes: boolean?, noCache: boolean?, runLimit: number?)
			local scr = assert(
				if scriptType == "Script" then Deps.ScriptBase:Clone()
					elseif scriptType == "LocalScript" then Deps.LocalScriptBase:Clone()
					else nil,
				"Invalid script type '"..tostring(scriptType).."'"
			)

			local execCode = Functions.GetRandom()

			scr.Name = "[Adonis] "..scriptType

			if allowCodes then
				service.New("StringValue", {
					Name = "Execute",
					Value = execCode,
					Parent = scr,
				})
			end

			local wrapped = Core.RegisterScript({
				Script = scr;
				Code = execCode;
				Source = Core.Bytecode(source);
				noCache = noCache;
				runLimit = runLimit;
			})

			return wrapped or scr, scr, execCode
		end;

		SavePlayer = function(p, data)
			local key = tostring(p.UserId)
			Core.PlayerData[key] = data
		end;

		DefaultPlayerData = function(p)
			return {
				Donor = {
					Cape = {
						Image = "0";
						Color = "White";
						Material = "Neon";
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
			}
		end;

		GetPlayer = function(p)
			local key = tostring(p.UserId)

			if not Core.PlayerData[key] then
				local PlayerData = Core.DefaultPlayerData(p)

				Core.PlayerData[key] = PlayerData

				if Core.DataStore then
					local data = Core.GetData(key)
					if type(data) == "table" then
						data.AdminNotes = if data.AdminNotes then Functions.DSKeyNormalize(data.AdminNotes, true) else {}
						data.Warnings = if data.Warnings then Functions.DSKeyNormalize(data.Warnings, true) else {}

						local BLOCKED_SETTINGS = Core.PlayerDataKeyBlacklist
						for i, v in data do
							if not BLOCKED_SETTINGS[i] then
								PlayerData[i] = v
							end
						end
					end
				end

				return PlayerData
			else
				return Core.PlayerData[key]
			end
		end;

		ClearPlayer = function(p)
			Core.PlayerData[tostring(p.UserId)] = Core.DefaultData(p)
		end;

		SavePlayerData = function(p, customData)
			local key = tostring(p.UserId)
			local pData = customData or Core.PlayerData[key]

			if Core.DataStore then
				if pData then
					local data = service.CloneTable(pData)

					--// Temporary junk that will be removed on save.
					for _, blacklistedData in ipairs({"LastChat", "AdminRank", "AdminLevel", "LastLevelUpdate", "LastDataSave"}) do
						data[blacklistedData] = nil
					end

					data.AdminNotes = Functions.DSKeyNormalize(data.AdminNotes)
					data.Warnings = Functions.DSKeyNormalize(data.Warnings)

					Core.SetData(key, data)
					AddLog(Logs.Script, {
						Text = "Saved data for ".. p.Name;
						Desc = "Player data was saved to the datastore";
					})

					pData.LastDataSave = os.time()
				end
			end
		end;

		SaveAllPlayerData = function(queueWaitTime)
			local TrackTask = service.TrackTask
			for key,pdata in Core.PlayerData do
				local id = tonumber(key);
				local player = id and service.Players:GetPlayerByUserId(id);
				if player and (not pdata.LastDataSave or os.time() - pdata.LastDataSave >= Core.DS_AllPlayerDataSaveInterval)  then
					TrackTask(string.format("Save data for %s", player.Name), Core.SavePlayerData, player);
				end
			end
			--[[ --// OLD METHOD (Kept in case this messes anything up)
			for i,p in service.Players:GetPlayers() do
				local pdata = Core.PlayerData[tostring(p.UserId)];
				--// Only save player's data if it has not been saved within the last INTERVAL (default 30s)
				if pdata and (not pdata.LastDataSave or os.time() - pdata.LastDataSave >= Core.DS_AllPlayerDataSaveInterval) then
					service.Queue("SavePlayerData", function()
						Core.SavePlayerData(p)
						task.wait(queueWaitTime or Core.DS_AllPlayerDataSaveQueueDelay)
					end)
				end
			end--]]
		end;
		GetDataStore = function()
			local ran,store = pcall(function()

				return service.DataStoreService:GetDataStore(string.sub(Settings.DataStore, 1, 50),"Adonis")
			end)

			-- DataStore studio check.
			if ran and store and service.RunService:IsStudio() then
				local success, res = pcall(store.GetAsync, store, math.random())
				if not success and string.find(res, "502", 1, true) then
					warn("Unable to load data because Studio access to API services is disabled.")
					return;
				end
			end

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

		DS_GetRequestDelay = function(reqTypeName: string)
			local reqType = assert(
				if reqTypeName == "Write" then Enum.DataStoreRequestType.SetIncrementAsync
					elseif reqTypeName == "Read" then Enum.DataStoreRequestType.GetAsync
					elseif reqTypeName == "Update" then Enum.DataStoreRequestType.UpdateAsync
					else nil,
				"Invalid request type name '"..tostring(reqTypeName).."'"
			)

			local reqPerMin = 60 + #service.Players:GetPlayers() * 10
			local reqDelay = 60 / reqPerMin

			local budget
			repeat
				budget = service.DataStoreService:GetRequestBudgetForRequestType(reqType);
			until budget > 0 and task.wait(1)

			return reqDelay + 0.5
		end;

		DS_WriteLimiter = function(reqTypeName: string, func, ...)
			local vararg = table.pack(...)
			return Queue("DataStoreWriteData_"..tostring(reqTypeName), function()
				local gotDelay = Core.DS_GetRequestDelay(reqTypeName); --// Wait for budget; also return how long we should wait before the next request is allowed to go
				func(unpack(vararg, 1, vararg.n))
				task.wait(gotDelay)
			end, 120, true)
		end;

		RemoveData = function(key)
			local DataStore = Core.DataStore
			if DataStore then
				local ran2, err2 = Queue("DataStoreWriteData"..tostring(key), function()
					local ran, ret = Core.DS_WriteLimiter("Write", DataStore.RemoveAsync, DataStore, Core.DataStoreEncode(key))
					if ran then
						Core.DataCache[key] = nil
					else
						logError("DataStore RemoveAsync Failed: ".. tostring(ret))
					end
					task.wait(6)
				end, 120, true)

				if not ran2 then
					warn("DataStore RemoveData Failed: ".. tostring(err2))
				end
			end
		end;

		SetData = function(key: string, value: any?, repeatCount: number?)
			if repeatCount then
				warn("Retrying SetData request for ".. key);
			end

			local DataStore = Core.DataStore
			if DataStore then
				if value == nil then
					return Core.RemoveData(key)
				else
					local ran2, err2 = Queue("DataStoreWriteData"..tostring(key), function()
						local ran, ret = Core.DS_WriteLimiter("Write", DataStore.SetAsync, DataStore, Core.DataStoreEncode(key), value)
						if ran then
							Core.DataCache[key] = value
						else
							logError("DataStore SetAsync Failed: ".. tostring(ret));
						end

						task.wait(6)
					end, 120, true)

					if not ran2 then
						logError("DataStore SetData Failed: ".. tostring(err2))

						--// Attempt 3 times, with slight delay between if failed
						task.wait(1)
						if not repeatCount then
							return Core.SetData(key, value, 3);
						elseif repeatCount > 0 then
							return Core.SetData(key, value, repeatCount - 1);
						end
					end
				end
			end
		end;

		UpdateData = function(key: string, callback: (currentData: any?)->any?, repeatCount: number?)
			if repeatCount then
				warn("Retrying UpdateData request for ".. key)
			end

			local DataStore = Core.DataStore
			if DataStore then
				local err = false
				local ran2, err2 = Queue("DataStoreWriteData"..tostring(key), function()
					local ran, ret = Core.DS_WriteLimiter("Update", DataStore.UpdateAsync, DataStore, Core.DataStoreEncode(key), callback)

					if not ran then
						err = ret
						logError("DataStore UpdateAsync Failed: ".. tostring(ret))
						return error(ret)
					end

					task.wait(6)
				end, 120, true) --// 120 timeout, yield until this queued function runs and completes

				if not ran2 then
					logError("DataStore UpdateData Failed: ".. tostring(err2))

					--// Attempt 3 times, with slight delay between if failed
					task.wait(1)
					if not repeatCount then
						return Core.UpdateData(key, callback, 3)
					elseif repeatCount > 0 then
						return Core.UpdateData(key, callback, repeatCount - 1)
					end
				end

				return err
			end
		end;

		GetData = function(key: string, repeatCount: number?)
			if repeatCount then
				warn("Retrying GetData request for ".. key)
			end

			local DataStore = Core.DataStore
			if DataStore then
				local ran2, err2 = Queue("DataStoreReadData", function()
					--wait(Core.DS_GetRequestDelay("Read")) -- TODO: re-implement this effectively and without an unnecessary delay
					local ran, ret = pcall(DataStore.GetAsync, DataStore, Core.DataStoreEncode(key))
					if ran then
						Core.DataCache[key] = ret
						return ret
					else
						logError("DataStore GetAsync Failed: ".. tostring(ret))
						if Core.DataCache[key] then
							return Core.DataCache[key]
						else
							error(ret)
						end
					end
				end, 120, true)

				if not ran2 then
					logError("DataStore GetData Failed: ".. tostring(err2))
					--// Attempt 3 times, with slight delay between if failed
					task.wait(1)
					if not repeatCount then
						return Core.GetData(key, 3)
					elseif repeatCount > 0 then
						return Core.GetData(key, repeatCount - 1)
					end
				else
					return err2
				end
			end
		end;

		IndexPathToTable = function(tableAncestry)
			local ds_blacklist = Core.DS_BLACKLIST

			if type(tableAncestry) == "string" and not ds_blacklist[tableAncestry] then
				return Settings[tableAncestry], tableAncestry
			elseif type(tableAncestry) == "table" then
				local curTable = server
				local curName = "Server"

				for index, ind in tableAncestry do

					--// Prevent stuff like {t1 = "Settings", t2 = ...} from bypassing datastore blocks
					if type(index) ~= 'number' then
						return nil
					end

					curTable = curTable[ind]
					curName = ind

					if type(curName) == "string" then
						--// Admins do NOT load from the DataStore with this setting
						if curName == "Ranks" and Settings.LoadAdminsFromDS == false then
							return nil
						end
					end

					if not curTable then
						--warn(tostring(ind) .." could not be found");
						--// Not allowed or table is not found
						return nil
					end
				end

				if type(curName) == "string" and ds_blacklist[curName] then
					return nil
				end

				return curTable, curName
			end
			return nil
		end;

		ClearAllData = function()
			local tabs = Core.GetData("SavedTables") or {}

			for _, v in tabs do
				if v.TableKey then
					Core.RemoveData(v.TableKey)
				end
			end

			Core.SetData("SavedSettings", {})
			Core.SetData("SavedTables", {})
			Core.CrossServer("LoadData")
		end;

		GetTableKey = function(indList: {string})
			local tabs = Core.GetData("SavedTables") or {}
			local realTable, tableName = Core.IndexPathToTable(indList)

			local foundTable = nil

			for _, v in tabs do
				if type(v) == "table" and v.TableName and v.TableName == tableName then
					foundTable = v
					break
				end
			end

			if not foundTable then
				foundTable = {
					TableName = tableName;
					TableKey = "SAVEDTABLE_" .. tableName;
				}

				table.insert(tabs, foundTable)
				Core.SetData("SavedTables", tabs)
			end

			if not Core.GetData(foundTable.TableKey) then
				Core.SetData(foundTable.TableKey, {})
			end

			return foundTable.TableKey;
		end;

		DoSave = function(data: TableData)
			if data.Type == "ClearSettings" then
				Core.ClearAllData()
			elseif data.Type == "SetSetting" then
				local setting = data.Setting
				local val = data.Value

				Core.UpdateData("SavedSettings", function(savedSettings)
					savedSettings[setting] = val
					return savedSettings
				end)

				Core.CrossServer("LoadData", "SavedSettings", {[setting] = val})
			elseif data.Type == "TableRemove" then
				local tab = data.Table
				local val = data.Value
				local key = Core.GetTableKey(tab)

				--// Storing an old reference of data.Table as we may override it later on.
				local originalTable = tab

				if type(tab) == "string" then
					tab = {"Settings", tab}
				elseif type(tab) == "table" and tab[1] == "Settings" then
					originalTable = tab[2]
				end

				data.Action = "Remove"
				data.Time = os.time()

				local CheckMatch = if type(data) == "table" and data.LaxCheck then Functions.LaxCheckMatch else Functions.CheckMatch
				Core.UpdateData(key, function(sets)
					sets = sets or {}

					local index = 1
					for i, v in sets do
						if type(i) ~= "number" then
							sets[i] = nil
						elseif (CheckMatch(tab, v.Table) or CheckMatch(originalTable, v.Table)) and CheckMatch(v.Value, val) then
							table.remove(sets, index)
						else
							index += 1
						end
					end

					--// Check that the real table actually has the item to remove; do not create if it does not have it
					--// (prevents snowballing)
					local continueOperation = false
					if tab[1] == "Settings" or tab[2] == "Settings" then
						local indClone = table.clone(tab)
						indClone[1] = "OriginalSettings"
						for _, v in pairs(Core.IndexPathToTable(indClone) or {}) do
							if CheckMatch(v, val) then
								continueOperation = true
								break
							end
						end
					end

					return sets
				end)

				Core.CrossServer("LoadData", "TableUpdate", data)
			elseif data.Type == "TableAdd" then
				local tab = data.Table
				local originalTable = tab
				local val = data.Value
				local key = Core.GetTableKey(tab)

				if type(tab) == "string" then
					tab = {"Settings", tab}
				end

				data.Action = "Add"
				data.Time = os.time()

				local CheckMatch = if type(data) == "table" and data.LaxCheck then Functions.LaxCheckMatch else Functions.CheckMatch
				Core.UpdateData(key, function(sets: {TableData})
					sets = sets or {}

					local index = 1
					for i, v in sets do
						if type(i) ~= "number" then
							sets[i] = nil
						elseif (CheckMatch(tab, v.Table) or CheckMatch(originalTable, v.Table)) and CheckMatch(v.Value, val) then
							table.remove(sets, index)
						else
							index += 1
						end
					end

					--// Check that the real table does not already have the item to add; do not create if it has it
					--// (prevents snowballing)
					local continueOperation = true
					if tab[1] == "Settings" or tab[2] == "Settings" then
						local indClone = table.clone(tab)
						indClone[1] = "OriginalSettings"
						for _, v in Core.IndexPathToTable(indClone) or {} do
							if CheckMatch(v, val) then
								continueOperation = false
								break
							end
						end
					end

					if continueOperation then
						table.insert(sets, data)
					end

					return sets
				end)

				Core.CrossServer("LoadData", "TableUpdate", data)
			else
				error("Invalid data action type '"..tostring(data.Type).."'", 2)
			end

			AddLog(Logs.Script, {
				Text = "Saved setting change to datastore";
				Desc = "A setting change was issued and saved ("..data.Type..")";
			})
		end;

		LoadData = function(key: string, data: TableData, serverId: string?)
			if serverId and serverId == game.JobId then
				return
			end

			local CheckMatch = if type(data) == "table" and data.LaxCheck then Functions.LaxCheckMatch else Functions.CheckMatch
			local ds_blacklist = Core.DS_BLACKLIST

			if key == "TableUpdate" then
				local indList = data.Table
				local nameRankComp = { --// Old settings backwards compatability
					Owners = { "Settings", "Ranks", "HeadAdmins", "Users" },
					Creators = { "Settings", "Ranks", "Creators", "Users" },
					HeadAdmins = { "Settings", "Ranks", "HeadAdmins", "Users" },
					Admins = { "Settings", "Ranks", "Admins", "Users" },
					Moderators = { "Settings", "Ranks", "Moderators", "Users" },
				}

				if type(indList) == "string" and nameRankComp[indList] then
					indList = nameRankComp[indList]
				end

				local realTable, tableName = Core.IndexPathToTable(indList)
				local displayName = type(indList) == "table" and table.concat(indList, ".") or tableName

				if type(displayName) == "string" then
					if ds_blacklist[displayName] then
						return
					end

					if type(indList) == "table" and indList[1] == "Settings" and indList[2] == "Ranks" then
						if
							not Settings.SaveAdmins
							and not Core.WarnedAboutAdminsLoadingWhenSaveAdminsIsOff
							and not Settings.SaveAdminsWarning
							and Settings.LoadAdminsFromDS
						then
							warn(
								'Admins are loading from the Adonis DataStore when Settings.SaveAdmins is FALSE!\nDisable this warning by adding the setting "SaveAdminsWarning" in Settings (and set it to true!) or set Settings.LoadAdminsFromDS to false'
							)
							Core.WarnedAboutAdminsLoadingWhenSaveAdminsIsOff = true
						end
						--// No adding to Trello or WebPanel rank users list via Datastore
						if type(indList[3]) == 'string' and (indList[3]:match("Trello") or indList[3]:match("WebPanel")) then
							return
						end
					end
				end

				if realTable and data.Action == "Add" then
					for i, v in realTable do
						if CheckMatch(v, data.Value) then
							table.remove(realTable, i)
						end
					end

					AddLog("Script", {
						Text = "Added value to " .. displayName,
						Desc = "Added " .. tostring(data.Value) .. " to " .. displayName .. " from datastore",
					})

					table.insert(realTable, data.Value)
					service.Events["DataStoreAdd_" .. displayName]:Fire(data.Value)
				elseif realTable and data.Action == "Remove" then
					for i, v in realTable do
						if CheckMatch(v, data.Value) then
							AddLog("Script", {
								Text = "Removed value from " .. displayName,
								Desc = "Removed " .. tostring(data.Value) .. " from " .. displayName .. " from datastore",
							})

							table.remove(realTable, i)
						end
					end
				end
			else
				local SavedSettings
				local SavedTables

				if Core.DataStore and Settings.DataStoreEnabled then

					local GetData, LoadData, SaveData, DoSave = Core.GetData, Core.LoadData, Core.SaveData, Core.DoSave
					if not key then
						SavedSettings = GetData("SavedSettings")
						SavedTables = GetData("SavedTables")
					elseif key and not data then
						if key == "SavedSettings" then
							SavedSettings = GetData("SavedSettings")
						elseif key == "SavedTables" then
							SavedTables = GetData("SavedTables")
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
							SaveData("SavedSettings", {})
						end

						if not SavedTables then
							SavedTables = {}
							SaveData("SavedTables", {})
						end
					end

					if SavedSettings then
						for setting, value in SavedSettings do
							if not ds_blacklist[setting] then

								if setting == "Prefix" or setting == "AnyPrefix" or setting == "SpecialPrefix" then
									local orig = Settings[setting]
									for _, cmd in server.Commands do
										if cmd.Prefix == orig then
											cmd.Prefix = value
										end
									end
								end

								Settings[setting] = value
							end
						end
					end

					if SavedTables then
						for _, tData in SavedTables do
							if tData.TableName and tData.TableKey and not ds_blacklist[tData.TableName] then
								local data = GetData(tData.TableKey)
								if data then
									for _, v in data do
										LoadData("TableUpdate", v)
									end
								end
							elseif tData.Table and tData.Action then
								LoadData("TableUpdate", tData)
							end
						end

						if Core.Variables.TimeBans then
							for i, v in Core.Variables.TimeBans do
								if v.EndTime - os.time() <= 0 then
									table.remove(Core.Variables.TimeBans, i)
									DoSave({
										Type = "TableRemove",
										Table = { "Core", "Variables", "TimeBans" },
										Value = v,
										LaxCheck = true,
									})
								end
							end
						end
					end

					AddLog(Logs.Script, {
						Text = "Loaded saved data",
						Desc = "Data was retrieved from the datastore and loaded successfully",
					})
				end
			end
		end,

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
			local Routine = env.Routine
			local cPcall = env.cPcall
			local MetaFunc = service.MetaFunc
			local StartLoop = service.StartLoop
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
				Access = MetaFunc(function(...)
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
										AddLog(Logs.Script, {
											Text = "Access to "..tostring(inde).." was granted";
											Desc = "A server script was granted access to "..tostring(inde);
										})

										if targ[inde]~=nil and type(targ[inde]) == "table" and Settings.G_Access_Perms == "Read" then
											return service.ReadOnly(targ[inde])
										else
											return targ[inde]
										end
									elseif API_Special[inde] == false then
										AddLog(Logs.Script, {
											Text = "Access to "..tostring(inde).." was denied";
											Desc = "A server script attempted to access "..tostring(inde).." via _G.Adonis.Access";
										})

										error("Access Denied: "..tostring(inde))
									else
										error("Could not find "..tostring(inde))
									end
								end;
								__newindex = function(tabl, inde, valu)
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
					ExecutePermission = MetaFunc(function(srcScript, code)
						local exists;

						for _, v in Core.ScriptCache do
							if v.Script == srcScript then
								exists = v
							end
						end

						if exists and exists.noCache ~= true and (not exists.runLimit or (exists.runLimit and exists.Executions <= exists.runLimit)) then
							exists.Executions += 1
							return exists.Source, exists.Loadstring
						end

						local data = Core.ExecutePermission(srcScript, code)
						if data and data.Source then
							local module;
							if not exists then
								module = require(server.Shared.FiOne:Clone())
								table.insert(Core.ScriptCache, {
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

				CheckAdmin = MetaFunc(Admin.CheckAdmin);

				IsAdmin = MetaFunc(Admin.CheckAdmin);

				IsBanned = MetaFunc(Admin.CheckBan);

				IsMuted = MetaFunc(Admin.IsMuted);

				CheckDonor = MetaFunc(Admin.CheckDonor);

				GetLevel = MetaFunc(Admin.GetLevel);

				SetLighting = MetaFunc(Functions.SetLighting);

				SetPlayerLighting = MetaFunc(Remote.SetLighting);

				NewParticle = MetaFunc(Functions.NewParticle);

				RemoveParticle = MetaFunc(Functions.RemoveParticle);

				NewLocal = MetaFunc(Remote.NewLocal);

				MakeLocal = MetaFunc(Remote.MakeLocal);

				MoveLocal = MetaFunc(Remote.MoveLocal);

				RemoveLocal = MetaFunc(Remote.RemoveLocal);

				Hint = MetaFunc(Functions.Hint);

				Message = MetaFunc(Functions.Message);

				RunCommandAsNonAdmin = MetaFunc(Admin.RunCommandAsNonAdmin);
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
				__newindex = function()
					error("Read-only")
				end;
				__metatable = true;
			})

			if not rawget(_G, "Adonis") then
				if table.isfrozen and not table.isfrozen(_G) or not table.isfrozen then
					rawset(_G, "Adonis", AdonisGTable)
					StartLoop("APICheck", 1, function()
						if rawget(_G, "Adonis") ~= AdonisGTable then
							if table.isfrozen and not table.isfrozen(_G) or not table.isfrozen then
								rawset(_G, "Adonis", AdonisGTable)
							else
								warn("⚠️ ADONIS CRITICAL WARNING! MALICIOUS CODE IS TRYING TO CHANGE THE ADONIS _G API AND IT CAN'T BE SET BACK! PLEASE SHUTDOWN THE SERVER AND REMOVE THE MALICIOUS CODE IF POSSIBLE!")
							end
						end
					end, true)
				else
					warn("The _G table was locked and the Adonis _G API could not be loaded")
				end
			end


			AddLog(Logs.Script, {
				Text = "Started _G API";
				Desc = "The Adonis _G API was initialized and is ready to use";
			})
		end;
	};
end
