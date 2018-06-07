server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Core
return function()
	server.Core = {
		DataQueue = {};
		DataCache = {};
		ExecuteScripts = {};
		LastDataSave = 0;
		PanicMode = false;
		ScriptCache = {};
		Connections = {};
		Variables = {
			TimeBans = {};
		};
		
		Panic = function(reason)
			local hint = Instance.new("Hint", service.Workspace)
			hint.Text = "-= Adonis PanicMode Enabled: "..tostring(reason).." =~"
			server.Core.PanicMode = true;
			
			warn("SOMETHING SEVERE HAPPENED; ENABLING PANIC MODE; REASON BELOW;")
			warn(tostring(reason))
			warn("ENABLING CHAT MODE AND DISABLING CLIENT CHECKS;")
			warn("MODS NOW HAVE ACCESS TO PANIC COMMANDS SUCH AS :SHUTDOWN")
			
			--[[
			for i,v in pairs(service.Players:GetPlayers()) do 
				cPcall(function()
					v.Chatted:connect(function(msg)
						server.Process.Chat(v,msg)
					end)
				end)
			end
			--]]
			
			server.Logs.AddLog(server.Logs.Script,{
				Text = "ENABLED PANIC MODE";
				Desc = tostring(reason);
			})
		end;
		
		MakeEvent = function()
			local ran,error = ypcall(function()
				if server.Anti.RLocked(service.JointsService) then
					server.Core.Panic("JointsService RobloxLocked")
				elseif server.Running then
					if server.Core.RemoteEvent then
						server.Core.RemoteEvent.Security:Disconnect()
						server.Core.RemoteEvent.Event:Disconnect()
						server.Core.RemoteEvent.DecoySecurity1:Disconnect()
						server.Core.RemoteEvent.DecoySecurity2:Disconnect()
						pcall(function() service.Delete(server.Core.RemoteEvent.Object) end)
						pcall(function() service.Delete(server.Core.RemoteEvent.Decoy1) end)
						pcall(function() service.Delete(server.Core.RemoteEvent.Decoy2) end)
					end
					
					server.Core.RemoteEvent = {}
					
					local event = service.New("RemoteEvent")
					local decoy1 = event:Clone()
					local decoy2 = event:Clone()
					
					event.Name = server.Core.Name--..server.Functions.GetRandom() -- server.Core.Name
					decoy1.Name = server.Core.Name..server.Functions.GetRandom()
					decoy2.Name = server.Core.Name..server.Functions.GetRandom()
					
					event.Archivable = false
					decoy1.Archivable = false
					decoy2.Archivable = false
					
					server.Core.RemoteEvent.Object = event
					server.Core.RemoteEvent.Decoy1 = decoy1
					server.Core.RemoteEvent.Decoy2 = decoy2
					
					event.Parent = service.JointsService
					--decoy1.Parent = service.JointsService
					--decoy2.Parent = service.JointsService
					
					local function secure(ev)
						return service.RbxEvent(ev.Changed, function(p)
							if p=="Name" then
								event.Name = server.Core.Name--..server.Functions.GetRandom()--server.Core.Name
							else
								server.Core.MakeEvent()
							end
						end)
					end
					
					server.Core.RemoteEvent.Event = service.RbxEvent(event.OnServerEvent, server.Process.Remote)
					service.RbxEvent(decoy1.OnServerEvent, function(p,modu,com,sub)
						local keys = server.Remote.Clients[tostring(p.userId)]
						if keys and com == "TrustCheck" and modu == keys.Module then
							decoy1:FireClient(p,"TrustCheck",keys.Decoy1)
						end
					end)
					
					service.RbxEvent(decoy2.OnServerEvent, function(p,modu,com,sub)
						local keys = server.Remote.Clients[tostring(p.userId)]
						if keys and com == "TrustCheck" and modu == keys.Module then
							decoy1:FireClient(p,"TrustCheck",keys.Decoy2)
						end
					end)
					
					server.Core.RemoteEvent.Security = secure(event)
					server.Core.RemoteEvent.DecoySecurity1 = secure(decoy1)
					server.Core.RemoteEvent.DecoySecurity2 = secure(decoy2)
					server.Logs.AddLog(server.Logs.Script,{
						Text = "Created RemoteEvent";
						Desc = "RemoteEvent was successfully created";
					})
				end
			end)
			
			if error then
				warn(error)
				server.Core.Panic("Error while making RemoteEvent")
			end
		end;
		
		CheckAllClients = function()
			if server.Settings.CheckClients and not server.Core.PanicMode and server.Running then
				server.Logs.AddLog(server.Logs.Script,{
					Text = "Checking Clients";
					Desc = "Making sure all clients are active";
				})
				local parent = service.NetworkServer or service.Players
				local net = service.NetworkServer or false
				for ind,p in next,parent:GetChildren() do
					if net then p = p:GetPlayer() end
					if p then
						if server.Anti.ObjRLocked(p) then
							p:Detected("kick", "RobloxLocked")
						else
							local client = server.Remote.Clients[tostring(p.userId)]
							if client and client.LoadingStatus == "READY" then
								local lastTime = client.LastUpdate
								if lastTime and tick()-lastTime > 60*5 then
									p:Detected("kick","Client Not Responding [Client hasn't checked in >5 minutes]")
								end
							end
						end
					end
				end
			end
		end;
		
		UpdateConnections = function()
			if service.NetworkServer then
				for i,cli in next,service.NetworkServer:GetChildren() do
					server.Core.Connections[cli] = cli:GetPlayer()
				end
			end
		end;
		
		UpdateConnection = function(p)
			if service.NetworkServer then
				for i,cli in next,service.NetworkServer:GetChildren() do
					if cli:GetPlayer() == p then
						server.Core.Connections[cli] = p
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
			local key = tostring(p.userId)
			local keys = server.Remote.Clients[key]
			if keys and keys.EventName and p and not server.Anti.ObjRLocked(p) then
				local event = Instance.new("RemoteEvent")
				event.Name = keys.EventName
				event.Changed:connect(function()
					if server.Anti.RLocked(event) or not event or event.Parent ~= p then
						service.Delete(event)
						server.Core.SetupEvent(p)
					end
				end)
				event.OnServerEvent:connect(function(np,...)
					if np == p then
						server.Process.Remote(np,...)
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
					if server.Core.ClientLoader then 
						pcall(function() server.Core.ClientLoaderEvent:Disconnect() service.Delete(server.Core.ClientLoader) end) 
					end
					
					local loader = server.Deps.ClientLoader:Clone()
					loader.Disabled = false
					loader.Archivable = false
					loader.Name = "\0"
					
					loader.Parent = service.ReplicatedFirst
					server.Core.ClientLoader = loader
					server.Core.ClientLoaderEvent = loader.Changed:connect(function() 
						server.Core.PrepareClient()
					end)
				end)
				
				if err or not ran then 
					server.Core.Panic("Cannot load ClientLoader "..tostring(err))
				end
			end
		end;
		
		HookClient = function(p)
			local key = tostring(p.userId)
			local keys = server.Remote.Clients[key]
			if keys then
				local depsName = server.Functions:GetRandom()
				local eventName = server.Functions:GetRandom()
				local folder = server.Client:Clone()
				local client = folder.Client
				
				folder.Name = "Adonis_Client" --server.Core.Name.."\\"..depsName
				
				local specialVal = service.New("StringValue")
				specialVal.Value = server.Core.Name.."\\"..depsName
				specialVal.Name = "Special"
				specialVal.Parent = folder
				
				keys.Loader = server.Core.ClientLoader
				keys.Special = depsName
				keys.EventName = eventName
				keys.Module = client
				
				service.Events[p.userId.."_CLIENTLOADER"]:connectOnce(function()
					if folder.Parent == p then
						folder:Destroy()
					end
				end)
				
				local ok,err = ypcall(function()
					folder.Parent = p
				end)
				
				if not server.Core.PanicMode and not ok then
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
			local loader = server.Deps.ClientLoader:Clone()
			loader.Name = server.Functions.GetRandom()
			loader.Disabled = false
			loader.Parent = p:WaitForChild("Backpack")
		end;
		
		LoadExistingPlayer = function(p)
			server.Core.LoadClientLoader(p)
			server.Process.PlayerAdded(p)
		end;
		
		MakeClient = function()
			local ran,error = ypcall(function()
				if server.Anti.RLocked(service.StarterPlayer) then
					server.Core.Panic("StarterPlayer RobloxLocked")
				else
					local starterScripts = service.StarterPlayer:FindFirstChild(server.Core.Name)
					if not starterScripts then
						starterScripts = service.New("StarterPlayerScripts",service.StarterPlayer)
						starterScripts.Name = server.Core.Name
						starterScripts.Changed:connect(function(p)
							if p=="Parent" then
								server.MakeClient()
							elseif p=="Name" then
								starterScripts.Name = server.Core.Name
							elseif p=="RobloxLocked" and server.Anti.RLocked(starterScripts) then
								server.Core.Panic("PlayerScripts RobloxLocked")
							end
						end)
						starterScripts.ChildAdded:connect(function(c)
							if c.Name~=server.Core.Name then
								wait(0.5)
								c:Destroy()
							end
						end)
					end
					starterScripts:ClearAllChildren()
					if server.Anti.RLocked(starterScripts) then
						server.Core.Panic("StarterPlayerScripts RobloxLocked")
					else
						if server.Core.Client then
							local cli = server.Core.Client
							if server.Anti.ObjRLocked(cli.Object) then
								server.Core.Panic("Client RobloxLocked")
							else
								server.Core.Client.Security:disconnect()
								pcall(function() server.Core.Client.Object:Destroy() end)
							end
						end
						server.Core.Client = {}
						local client = server.Deps.Client:clone()
						client.Name = server.Core.Name
						server.ClientDeps:Clone().Parent = client
						client.Parent = starterScripts
						client.Disabled = false
						server.Core.Client.Object = client
						server.Core.Client.Security = client.Changed:connect(function(p)
							if p == "Parent" or p == "RobloxLocked" then
								server.Core.MakeClient()
							end
						end)
					end
				end
			end)
			if error then
				print(error)
				server.Core.Panic("Error while making client")
			end
		end;
		
		ExecutePermission = function(scr, code, isLocal)
			for i,val in next,server.Core.ExecuteScripts do
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
			for i,val in next,server.Core.ExecuteScripts do
				if val.Script == scr or code == val.Code then
					return val,i
				end
			end
		end;
		
		UnRegisterScript = function(scr)
			for i,dat in next,server.Core.ExecuteScripts do
				if dat.Script == scr or dat == scr then
					table.remove(server.Core.ExecuteScripts, i)
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
				return server.Core.RegisterScript {
					Script = service.UnWrap(data.Script):Clone();
					Code = data.Code;
					Source = data.Source;
					noCache = data.noCache;
					runLimit = data.runLimit;	
				}
			end)
			
			for ind,scr in next,server.Core.ExecuteScripts do
				if scr.Script == data.Script then
					return scr.Wrapped or scr.Script
				end
			end
			
			if not data.Code then
				data.Code = server.Functions.GetRandom()
			end
			
			table.insert(server.Core.ExecuteScripts,data)
			return data.Wrapped
		end;
		
		Loadstring = function(str, env)
			return require(server.Deps.Loadstring:Clone())(str, env)
		end;
		
		Bytecode = function(str)
			local f,buff = server.Core.Loadstring(str)
			return buff
		end;
		
		NewScript = function(type,source,allowCodes,noCache,runLimit)
			local ScriptType
			local execCode = server.Functions.GetRandom()
			
			if type == 'Script' then 
				ScriptType = server.Deps.ScriptBase:Clone()
			elseif type == 'LocalScript' then 
				ScriptType = server.Deps.LocalScriptBase:Clone()
			end
			
			if ScriptType then
				ScriptType.Name = type
				
				if allowCodes then
					local exec = Instance.new("StringValue",ScriptType)
					exec.Name = "Execute"
					exec.Value = execCode
				end
				
				local wrapped = server.Core.RegisterScript {
					Script = ScriptType;
					Code = execCode;
					Source = server.Core.Bytecode(source);
					noCache = noCache;
					runLimit = runLimit;
				}
				
				return wrapped or ScriptType, ScriptType, execCode
			end
		end;
		
		DoSave = function(data)
			local type = data.Type
			if type == "ClearSettings" then
				server.Core.SetData("SavedSettings",{})
				server.Core.SetData("SavedTables",{})
			elseif type == "SetSetting" then
				local setting = data.Setting
				local value = data.Value
				server.Core.UpdateData("SavedSettings", function(settings)
					settings[setting] = value
					return settings
				end)
			elseif type == "TableRemove" then
				local tab = data.Table
				local value = data.Value
				data.Time = os.time()
				server.Core.UpdateData("SavedTables", function(sets)
					sets = sets or {}
					for i,v in next,sets do 
						if tab == v.Table then
							if server.Functions.CheckMatch(v.Value,value) then
								table.remove(sets,i)
							end
						end
					end
					data.Action = "Remove"
					table.insert(sets,data)
					return sets
				end)
			elseif type == "TableAdd" then
				local tab = data.Table
				local value = data.Value
				data.Time = os.time()
				server.Core.UpdateData("SavedTables", function(sets)
					sets = sets or {}
					for i,v in next,sets do 
						if tab == v.Table then
							if server.Functions.CheckMatch(v.Value,value) then
								table.remove(sets,i)
							end
						end
					end
					data.Action = "Add"
					table.insert(sets,data)
					return sets
				end)
			end
			
			server.Logs.AddLog(server.Logs.Script,{
				Text = "Saved setting change to datastore";
				Desc = "A setting change was issued and saved";
			})
		end;
		
		SavePlayer = function(p,data)
			local key = tostring(p.userId)
			server.Remote.PlayerData[key] = data
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
				Client = {};
				Warnings = {};
				AdminPoints = 0;
			};
		end;
		
		GetPlayer = function(p)
			local key = tostring(p.userId)
			local PlayerData = server.Core.DefaultData(p)
			
			if not server.Remote.PlayerData[key] then
				server.Remote.PlayerData[key] = PlayerData
				if server.Core.DataStore then
					local data = server.Core.GetData(key)
					if data and type(data) == "table" then
						for i,v in next,data do
							PlayerData[i] = v
						end
					end
				end
			else
				PlayerData = server.Remote.PlayerData[key]
			end
			
			return PlayerData
		end;
		
		ClearPlayer = function(p)
			server.Remote.PlayerData[tostring(p.userId)] = server.Core.DefaultData(p);
		end;
		
		SavePlayerData = function(p)
			local key = tostring(p.userId)
			local data = server.Remote.PlayerData[key]
			if data and server.Core.DataStore then
				data.LastChat = nil
				data.AdminLevel = nil
				data.LastLevelUpdate = nil
				server.Core.SetData(key, data)
				server.Remote.PlayerData[key] = nil
				server.Logs.AddLog(server.Logs.Script,{
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
			local ran,store = pcall(function() return service.DataStoreService:GetDataStore(server.Settings.DataStore:sub(1,50),"Adonis") end)
			
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
			return server.Remote.Encrypt(tostring(key), server.Settings.DataStoreKey)
		end;
		
		SaveData = function(...)
			return server.Core.SetData(...)
		end;
		
		SetData = function(key, value)
			if server.Core.DataStore then
				local ran, ret = pcall(server.Core.DataStore.SetAsync, server.Core.DataStore, server.Core.DataStoreEncode(key), value)
				if ran then
					server.Core.DataCache[key] = value
					return ret
				else
					logError("DataStore SetAsync Failed: ".. tostring(ret))
				end
			end
		end;
		
		UpdateData = function(key, func)
			if server.Core.DataStore then
				local ran, ret = pcall(server.Core.DataStore.UpdateAsync, server.Core.DataStore, server.Core.DataStoreEncode(key), func)
				if ran then
					return ret
				else
					logError("DataStore UpdateAsync Failed: ".. tostring(ret))
				end
			end
		end;
		
		GetData = function(key)
			if server.Core.DataStore then
				local ran, ret = pcall(server.Core.DataStore.GetAsync, server.Core.DataStore, server.Core.DataStoreEncode(key))
				if ran then
					server.Core.DataCache[key] = ret
					return ret
				else
					logError("DataStore GetAsync Failed: ".. tostring(ret))
					return server.Core.DataCache[key]
				end
			end
		end;
		
		LoadData = function(key, data)
			local SavedSettings
			local SavedTables
			local Blacklist = {DataStoreKey = true;}
			if server.Core.DataStore and server.Settings.DataStoreEnabled then
				if not key then
					SavedSettings = server.Core.GetData("SavedSettings")
					SavedTables = server.Core.GetData("SavedTables")
				elseif key and not data then
					if key == "SavedSettings" then
						SavedSettings = server.Core.GetData("SavedSettings")
					elseif key == "SavedTables" then
						SavedTables = server.Core.GetData("SavedTables")
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
						server.Core.SaveData("SavedSettings",{}) 
					end
					
					if not SavedTables then 
						SavedTables = {} 
						server.Core.SaveData("SavedTables",{}) 
					end
				end
				
				if SavedSettings then
					for setting,value in next,SavedSettings do
						if not Blacklist[setting] then
							server.Settings[setting] = value
						end
					end
				end
				
				if SavedTables then	
					for ind,tab in next,SavedTables do
						local parentTab = (tab.Parent == "Variables" and server.Core.Variables) or server.Settings
						if (not Blacklist[tab.Table]) and parentTab[tab.Table] ~= nil then
							if tab.Action == "Add" then
								local tabl = parentTab[tab.Table]
								if tabl then
									for i,v in next,tabl do
										if server.Functions.CheckMatch(v,tab.Value) then
											table.remove(parentTab[tab.Table],i)
										end
									end
								end
								
								server.Logs.AddLog("Script",{
									Text = "Added to "..tostring(tab.Table);
									Desc = "Added "..tostring(tab.Value).." to "..tostring(tab.Table).." from datastore";
								})
								table.insert(parentTab[tab.Table],tab.Value)
							elseif tab.Action == "Remove" then
								local tabl = parentTab[tab.Table]
								if tabl then
									for i,v in next,tabl do
										if server.Functions.CheckMatch(v,tab.Value) then
											server.Logs.AddLog("Script",{
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
					
					if server.Core.Variables.TimeBans then
						for i,v in next, server.Core.Variables.TimeBans do
							if v.EndTime-os.time() <= 0 then
								table.remove(server.Core.Variables.TimeBans, i)
								server.Core.DoSave({
									Type = "TableRemove";
									Table = "TimeBans";
									Parent = "Variables";
									Value = v;
								})
							end
						end
					end
				end
				
				server.Logs.AddLog(server.Logs.Script,{
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
				AddAdmin = server.Settings.Allowed_API_Calls.DataStore;
				RemoveAdmin = server.Settings.Allowed_API_Calls.DataStore;
				RunCommand = server.Settings.Allowed_API_Calls.Core;
				SaveTableAdd = server.Settings.Allowed_API_Calls.DataStore and server.Settings.Allowed_API_Calls.Settings;
				SaveTableRemove = server.Settings.Allowed_API_Calls.DataStore and server.Settings.Allowed_API_Calls.Settings;
				SaveSetSetting = server.Settings.Allowed_API_Calls.DataStore and server.Settings.Allowed_API_Calls.Settings;
				ClearSavedSettings = server.Settings.Allowed_API_Calls.DataStore and server.Settings.Allowed_API_Calls.Settings;
				SetSetting = server.Settings.Allowed_API_Calls.Settings;
			}
			
			setfenv(1,setmetatable({}, {__metatable = getmetatable(getfenv())}))
			
			local API_Specific = {
				API_Specific = {
					Test = function()
						print("We ran the api specific stuff")
					end
				};
				Settings = server.Settings;
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
					elseif server[ind] and server.Settings.Allowed_API_Calls[ind] then
						targ = server[ind]
					end
					
					if server.Settings.G_Access and key == server.Settings.G_Access_Key and targ and server.Settings.Allowed_API_Calls[ind] == true then
						if type(targ) == "table" then
							return service.NewProxy {
								__index = function(tab,inde)
									if targ[inde] ~= nil and API_Special[inde] == nil or API_Special[inde] == true then
										if targ[inde]~=nil and type(targ[inde]) == "table" and server.Settings.G_Access_Perms == "Read" then
											return service.ReadOnly(targ[inde])
										else
											return targ[inde]
										end
										server.Logs.AddLog(server.Logs.Script,{
											Text = "Access to "..tostring(inde).." was granted";
											Desc = "A server script was granted access to "..tostring(inde);
										})
									elseif API_Special[inde] == false then
										server.Logs.AddLog(server.Logs.Script,{
											Text = "Access to "..tostring(inde).." was denied";
											Desc = "A server script attempted to access "..tostring(inde).." via _G.Adonis.Access";
										})
										error("Access Denied: "..tostring(inde))
									else
										error("Could not find "..tostring(inde))
									end
								end;
								__newindex = function(tabl,inde,valu)
									if server.Settings.G_Access_Perms == "Read" then
										error("Read-only")
									elseif server.Settings.G_Access_Perms == "Write" then
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
						
						if not server.Settings.CodeExecution then
							return nil
						end
						
						for i,v in pairs(server.Core.ScriptCache) do
							if v.Script == getfenv(2).script then
								exists = v
							end
						end
						
						if exists and exists.noCache ~= true and (not exists.runLimit or (exists.runLimit and exists.Executions <= exists.runLimit)) then
							exists.Executions = exists.Executions+1
							return exists.Source, exists.Loadstring
						end
						
						local data = server.Core.ExecutePermission(getfenv(2).script,code)
						if data and data.Source then
							local module;
							if not exists then
								module = require(server.Deps.Loadstring.Rerubi:Clone())
								table.insert(server.Core.ScriptCache,{
									Script = getfenv(2).script; 
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
				
				CheckAdmin = service.MetaFunc(server.Admin.CheckAdmin); 
				
				CheckDonor = service.MetaFunc(server.Admin.CheckDonor);
				
				GetLevel = service.MetaFunc(server.Admin.GetLevel);
				
				CheckAgent = service.MetaFunc(server.HTTP.Trello.CheckAgent);
				
				SetLighting = service.MetaFunc(server.Functions.SetLighting);
				
				SetPlayerLighting = service.MetaFunc(server.Remote.SetLighting);
				
				NewParticle = service.MetaFunc(server.Functions.NewParticle);
				
				RemoveParticle = service.MetaFunc(server.Functions.RemoveParticle);
				
				NewLocal = service.MetaFunc(server.Remote.NewLocal);
				
				MakeLocal = service.MetaFunc(server.Remote.MakeLocal);
				
				MoveLocal = service.MetaFunc(server.Remote.MoveLocal);
				
				RemoveLocal = service.MetaFunc(server.Remote.RemoveLocal);
				
				Hint = service.MetaFunc(server.Functions.Hint);
				
				Message = service.MetaFunc(server.Functions.Message);
			}
			
			local AdonisGTable = service.NewProxy({
				__index = function(tab,ind)
					if server.Settings.G_API then
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
			
			
			server.Logs.AddLog(server.Logs.Script,{
				Text = "Started _G API";
				Desc = "_G API was initialized and is ready to use";
			})
		end;
	};
end