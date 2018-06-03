server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Remote
return function()
	server.Remote = {
		Clients = {};
		Returns = {};
		Sessions = {};
		PlayerData = {};
		PendingReturns = {};
		EncodeCache = {};
		DecodeCache = {};
		
		Returnables = {
			Test = function(p,args)
				return "HELLO FROM THE OTHER SIDE :)!"
			end;
			
			Ping = function(p,args)
				return "Pong"
			end;
			
			Filter = function(p,args)
				return service.Filter(args[1],args[2],args[3])
			end;
			
			BroadcastFilter = function(p,args)
				return service.BroadcastFilter(args[1],args[2] or p)
			end;
			
			ClientCheck = function(p,args)
				local key = tostring(p.userId)
				local data = args[1]
				local special = args[2]
				local returner = args[3]
				local keys = server.Remote.Clients[key]
				
				--print("Sent: "..(data.Sent+1).." : "..keys.Received)
				--print("Received: "..data.Received.." : "..keys.Sent)
				
				if (math.abs(data.Received-keys.Sent) > 10) then
					--print("Something is wrong...")
				end
				
				if keys and special and special == keys.Special then
					keys.LastUpdate = tick()
				end
				
				return returner
			end;
			
			TaskManager = function(p,args)
				if server.Admin.GetLevel(p) >= 4 then
					local action = args[1]
					if action == "GetTasks" then
						local tab = {}
						for i,v in next, service.GetTasks() do
							local new = {}
							new.Status = v.Status
							new.Name = v.Name
							new.Index = v.Index
							new.Created = v.Created
							new.Function = tostring(v.Function)
							table.insert(tab,new)
						end
						return tab
					end
				end
			end;
			
			ExecutePermission = function(p,args)
				return server.Core.ExecutePermission(args[1],args[2],true)
			end;
			
			Variable = function(p,args)
				return server.Variables[args[1]]
			end;
			
			Setting = function(p,args)
				local setting = args[1]
				local level = server.Admin.GetLevel(p)
				local ret = nil
				local blocked = {
					DataStore = true;
					DataStoreKey = true;
					
					Trello_Enabled = true;	
					Trello_PrimaryBoard = true;
					Trello_SecondaryBoards = true;
					Trello_AppKey = true;
					Trello_Token = true; 
					
					--G_Access = true;
					--G_Access_Key = true;
					--G_Access_Perms = true;
					--Allowed_API_Calls = true;
				}
				
				if type(setting) == "table" then
					ret = {}
					for i,set in pairs(setting) do
						if server.Settings[set] and not (blocked[set] and not level>=5) then 
							ret[set] = server.Settings[set]
						end
					end
				elseif type(setting) == "string" then
					if server.Settings[setting] and not (blocked[setting] and not level>=5) then 
						ret = server.Settings[setting]
					end
				end
				return ret
			end;
			
			UpdateList = function(p, args)
				local list = args[1]
				local update = server.Logs.ListUpdaters[list]
				if update then
					return update(p, unpack(args,2))
				end
			end;
			
			AllSettings = function(p,args)
				if server.Admin.GetLevel(p) >= 4 then
					local sets = {}
					
					sets.Settings = {}
					sets.Descs = server.Descriptions
					sets.Order = server.Order
					
					for i,v in pairs(server.Settings) do
						sets.Settings[i] = v
					end
					
					local blocked = {
						HideScript = true;  -- Changing in-game will do nothing; Not able to be saved
						DataStore = true;
						DataStoreKey = true;
						DataStoreEnabled = true;
						
						--Trello_Enabled = true;	
						--Trello_PrimaryBoard = true;
						--Trello_SecondaryBoards = true;
						--Trello_AppKey = true;
						--Trello_Token = true;
						
						G_API = true;
						G_Access = true;
						G_Access_Key = true;
						G_Access_Perms = true;
						Allowed_API_Calls = true;
						
						OnStartup = true;
						OnSpawn = true;
						OnJoin = true;
						
						AntiInsert = true;  -- Not supported yet
						CustomRanks = true; -- Not supported yet 
					}
				
					for setting,value in pairs(sets.Settings) do
						if blocked[setting] then
							sets.Settings[setting] = nil
						end
					end
					
					return sets
				end
			end;
			
			AdminLevel = function(p,args)
				return server.Admin.GetLevel(p)
			end;
			
			Keybinds = function(p,args)
				local playerData = server.Core.GetPlayer(p)
				return playerData.Keybinds or {}
			end;
			
			UpdateKeybinds = function(p,args)
				local playerData = server.Core.GetPlayer(p)
				local binds = args[1]
				local resp = "OK"
				if type(binds)=="table" then
					playerData.Keybinds = binds
					server.Core.SavePlayer(p,playerData)
					resp = "Updated"
				else
					resp = "Error"
				end
				return resp
			end;
			
			UpdateClient = function(p,args)
				local playerData = server.Core.GetPlayer(p)
				local setting = args[1]
				local value = args[2]
				local data = playerData.Client or {}
				data[setting] = value
				playerData.Client = data
				server.Core.SavePlayer(p,playerData)
				return "Updated"
			end;
			
			UpdateDonor = function(p,args)
				local playerData = server.Core.GetPlayer(p)
				local donor = args[1]
				local resp = "OK"
				if type(donor)=="table" and donor.Cape and type(donor.Cape)=="table" then
					playerData.Donor = donor
					server.Core.SavePlayer(p,playerData)
					if donor.Enabled then
						server.Functions.Donor(p)
					else
						server.Functions.UnCape(p)
					end
					resp = "Updated"
				else
					resp = "Error"
				end
				return resp
			end;
			
			PlayerData = function(p,args)
				local data = server.Core.GetPlayer(p)
				data.isDonor = server.Admin.CheckDonor(p)
				return data
			end;
			
			CheckAdmin = function(p,args)
				return server.Admin.CheckAdmin(p)
			end;
			
			SearchCommands = function(p,args)
				return server.Admin.SearchCommands(p,args[1] or "all")
			end;
			
			FormattedCommands = function(p,args)
				local commands = server.Admin.SearchCommands(p,args[1] or "all")
				local tab = {}
				for i,v in pairs(commands) do
					table.insert(tab,server.Admin.FormatCommand(v))
				end
				return tab
			end;
			
			TerminalData = function(p,args)
				if server.Admin.GetLevel(p) >= 4 then
					local entry = server.Remote.Terminal.Data[tostring(p.UserId)]
					if not entry then
						server.Remote.Terminal.Data[tostring(p.UserId)] = {
							Player = p;
							Output = {};
						}
					end
					
					return {
						ServerLogs = service.LogService:GetLogHistory();
						ClientLogs = {};
						ScriptLogs = server.Logs.Script;
						AdminLogs = server.Logs.Commands;
						ErrorLogs = server.Logs.Errors;
						ChatLogs = server.Logs.Chats;
						JoinLogs = server.Logs.Joins;
						Replications = server.Logs.Replications;
						Exploit = server.Logs.Exploit;
					}
				end
			end;
			
			Terminal = function(p,args)
				if server.Admin.GetLevel(p) >= 4 then
					local data = args[2]
					local message = args[1]
					local command = message:match("(.-) ") or message
					local argString = message:match("^.- (.+)") or ""
					local comTable = server.Remote.Terminal.GetCommand(command)
					if comTable then
						local cArgs = server.Functions.Split(argString, " ", comTable.Arguments)
						local ran,ret = pcall(comTable.Function,p,cArgs,data)
						if ran then
							return ret
						else
							return {
								"COMMAND ERROR: "..tostring(ret)
							}
						end
					else
						return {
							"Could not find any command matching \""..command.."\""
						}
					end
				end
			end
		};
		
		Terminal = {
			Data = {};
			Format = function(msg,data) (data or {}).Text = msg end;
			Output = function(tab,msg,mata) table.insert(tab,server.Remote.Terminal.Format(msg,mata)) end;
			GetCommand = function(cmd) for i,com in next,server.Remote.Terminal.Commands do if com.Command:lower() == cmd:lower() then return com end end end;
			LiveOutput = function(p,data,type) server.Remote.FireEvent(p,"TerminalLive",{Data = data; Type = type or "Terminal";}) end;
			Commands = {
				Help = {
					Usage = "help";
					Command = "help";
					Arguments = 0;
					Description = "Shows a list of available commands and their usage";
					Function = function(p,args,data)
						local output = {}
						for i,v in next,server.Remote.Terminal.Commands do
							table.insert(output, tostring(v.Usage).. string.rep(" ",30-string.len(tostring(v.Usage))))
							table.insert(output, "- ".. tostring(v.Description))
							table.insert(output, " ")
						end
						return output
					end;
				};
				
				Message = {
					Usage = "message <message>";
					Command = "message";
					Arguments = 1;
					Description = "Sends a message in the ROBLOX chat";
					Function = function(p, args, data)
						for i,v in next,service.GetPlayers() do
							server.Remote.Send(v,"Function","ChatMessage",args[1],Color3.new(1,64/255,77/255))
						end
					end
				};
				
				Test = {
					Usage = "test <return>";
					Command = "test";
					Arguments = 1;
					Description = "Used to test the connection to the server and it's ability to return data";
					Function = function(p,args,data)
						server.Remote.Terminal.LiveOutput(p,"Return Test: "..tostring(args[1]))
					end
				};
				
				Loadstring = {
					Usage = "loadstring <string>";
					Command = "loadstring";
					Arguments = 1;
					Description = "Loads and runs the given lua string";
					Function = function(p,args,data)
						local newenv = GetEnv(getfenv(),{
							print = function(...) local nums = {...} for i,v in pairs(nums) do server.Remote.Terminal.LiveOutput(p,"PRINT: "..tostring(v)) end end;
							warn = function(...) local nums = {...} for i,v in pairs(nums) do server.Remote.Terminal.LiveOutput(p,"WARN: "..tostring(v)) end end;
						})
						
						local func,err = server.Core.Loadstring(args[1], newenv)
						if func then 
							func()
						else
							server.Remote.Terminal.LiveOutput(p,"ERROR: "..tostring(err:match(":(.*)") or err))
						end
					end
				};
				
				Execute = {
					Usage = "execute <command>";
					Command = "execute";
					Arguments = 1;
					Description = "Runs the specified command as the server";
					Function = function(p,args,data)
						server.Process.Command(p, args[1], {DontLog = true, Check = true}, true)
						return {
							"Command ran: "..args[1]
						}
					end
				};
				
				Sudo = {
					Usage = "sudo <player> <command>";
					Command = "sudo";
					Arguments = 1;
					Description = "Runs the specified command on the specified player as the server";
					Function = function(p,args,data)
						server.Process.Command(p, server.Settings.Prefix.."sudo ".. tostring(args[1]), {DontLog = true, Check = true}, true)
						return {
							"Command ran: ".. server.Settings.Prefix.."sudo ".. tostring(args[1])
						}
					end
				};
				
				Kick = {
					Usage = "kick <player> <reason>";
					Command = "kick";
					Arguments = 2;
					Description = "Disconnects the specified player from the server";
					Function = function(p, args, data)
						local plrs = service.GetPlayers(p,args[1])
						if #plrs>0 then
							for i,v in pairs(plrs) do
								v:Kick(args[2] or "Disconnected by server")
								return {"Disconnect "..tostring(v.Name).." from the server"}
							end
						else
							return {"No players matching '"..args[1].."' found"}
						end
					end
				};
				
				Kill = {
					Usage = "kill <player>";
					Command = "kill";
					Arguments = 1;
					Description = "Calls :BreakJoints() on the target player's character";
					Function = function(p,args,data)
						local plrs = service.GetPlayers(p,args[1])
						if #plrs>0 then
							for i,v in pairs(plrs) do
								v.Character:BreakJoints()
								return {"Killed "..tostring(v.Name)}
							end
						else
							return {"No players matching '"..args[1].."' found"}
						end
					end
				};
				
				Respawn = {
					Usage = "respawn <player>";
					Command = "respawn";
					Arguments = 1;
					Description = "Calls :LoadCharacter() on the target player";
					Function = function(p,args,data)
						local plrs = service.GetPlayers(p,args[1])
						if #plrs>0 then
							for i,v in pairs(plrs) do
								v:LoadCharacter()
								return {"Respawned "..tostring(v.Name)}
							end
						else
							return {"No players matching '"..args[1].."' found"}
						end
					end
				};
				
				Shutdown = {
					Usage = "shutdown";
					Command = "shutdown";
					Arguments = 0;
					Description = "Disconnects all players from the server and prevents rejoining";
					Function = function(p,args,data)
						for i,v in next,service.Players:GetPlayers() do
							v:Kick()
						end
						
						service.PlayerAdded:connect(function(p)
							p:Kick()
						end)
					end
				};
			};
		};
		
		SessionHandlers = {
			
		};
		
		UnEncrypted = {
			AddReplication = function(p,action,obj,data)
				local na = "_SERVER"
				local datat
				
				if p then na = p.Name end
				if action == "Created" then
					--local obj = data.obj
					local name = data.name
					local class = data.class
					local parent = data.parent
					local path = data.path
					if not obj then
						datat = {Action=action,Parent=parent,ClassName=class,Player=na,Object=obj,Name=name,Path=path}
					end
				elseif action == "Destroyed" then
					--local obj = data.obj
					local name = data.name
					local class = data.class
					local parent = data.parent
					local path = data.path
					if obj and obj.Parent then
						datat = {Action=action,Parent=parent,ClassName=class,Player=na,Object=obj,Name=name,Path=path}
					end
				end
				
				if datat then
					server.Logs.AddLog(server.Logs.Replications,datat)
				end
			end;
			
			TrustCheck = function(p)
				local keys = server.Remote.Clients[tostring(p.userId)]
				server.Remote.Fire(p, "TrustCheck", keys.Special)
			end;
			
			ProcessChat = function(p,msg)
				server.Process.Chat(p,msg)
			end;
		};
		
		Commands = {
			GetReturn = function(p,args)
				local com = args[1]
				local key = args[2]
				local parms = {unpack(args,3)}
				local retfunc = server.Remote.Returnables[com]
				local retable = (retfunc and {pcall(retfunc,p,parms)}) or {}
				if retable[1] ~= true then
					logError(p,retable[2])
				else
					server.Remote.Send(p,"GiveReturn",key,unpack(retable,2))
				end
			end;
			
			GiveReturn = function(p,args)
				if server.Remote.PendingReturns[args[1]] then
					server.Remote.PendingReturns[args[1]] = nil
					service.Events[args[1]]:fire(unpack(args,2))
				end
			end;
			
			Session = function(p,args)
				local type = args[1]
				local data = args[2]
				local handler = server.Remote.SessionHandlers[type]
				if handler then
					handler(p,data)
				end
			end;
			
			HandleExplore = function(p, args)
				if server.Admin.CheckAdmin(p) then
					local obj = args[1];
					local com = args[2];
					local data = args[3];
					
					if obj then
						if com == "Delete" then
							obj:Destroy()
						end
					end
				end
			end;
			
			PlayerEvent = function(p,args)
				service.Events[tostring(args[1])..p.userId]:fire(unpack(args,2))
			end;
			
			SaveTableAdd = function(p,args) 
				if server.Admin.GetLevel(p)>=4 then
					local tab = args[1]
					local value = args[2]
					
					table.insert(server.Settings[tab],value)
					
					server.Core.DoSave({
						Type = "TableAdd";
						Table = tab;
						Value = value;
					})
					 
				end
			end;
			
			SaveTableRemove = function(p,args) 
				if server.Admin.GetLevel(p)>=4 then
					local tab = args[1]
					local value = args[2]
					local ind = server.Functions.GetIndex(server.Settings[tab],value)
					
					if ind then table.remove(server.Settings[tab],ind) end
					
					server.Core.DoSave({
						Type = "TableRemove";
						Table = tab;
						Value = value;
					})
				end
			end;
			
			SaveSetSetting = function(p,args) 
				if server.Admin.GetLevel(p)>=4 then
					local setting = args[1]
					local value = args[2]
					
					server.Settings[setting] = value
					
					if setting=='Prefix' or setting=='AnyPrefix' or setting=='SpecialPrefix' then
						local orig=server.Settings[setting]
						for i,v in pairs(server.Commands) do
							if v.Prefix==orig then
								v.Prefix = server.Settings[setting]
							end
						end
					end
				
					server.Core.DoSave({
						Type = "SetSetting";
						Setting = setting;
						Value = value;
					})
				end
			end;
			
			ClearSavedSettings = function(p,args) 
				if server.Admin.GetLevel(p)>=4 then
					server.Core.DoSave({Type = "ClearSettings"})
					server.Functions.Hint("Cleared saved settings",{p})
				end
			end;
			
			SetSetting = function(p,args) 
				if server.Admin.GetLevel(p)>=4 then
					server.Settings[args[1]]=args[2]
					if args[1]=='Prefix' or args[1]=='AnyPrefix' or args[1]=='SpecialPrefix' then
						local orig = server[args[1]]
						for i,v in pairs(server.Commands) do
							if v.Prefix == orig then
								v.Prefix = server.Settings[args[1]]
							end
						end
					end
				end
			end;
			
			Detected = function(p,args)
				server.Anti.Detected(p,args[1],args[2])
			end;
			
			TrelloOperation = function(p,args)
				if server.Admin.GetLevel(p) > 2 then
					local data = args[1]
					if data.Action == "MakeCard" then
						local list = data.List
						local name = data.Name
						local desc = data.Desc
						local trello = server.HTTP.Trello.API(server.Settings.Trello_AppKey,server.Settings.Trello_Token)
						local lists = trello.getLists(server.Settings.Trello_Primary)
						local list = trello.getListObj(lists,list)
						if list then
							local card = trello.makeCard(list.id,name,desc)
							server.Hint("Made card \""..card.name.."\"",{p})
							server.Logs.AddLog(server.Logs.Script,{
								Text = tostring(p).." performed Trello operation";
								Desc = "Player created a Trello card";
							})
						end
					end
				end
			end;
			
			ClientLoaded = function(p,args)
				local key = tostring(p.userId)
				local client = server.Remote.Clients[key]
				if client and client.LoadingStatus == "LOADING" then
					client.LastUpdate = tick()
					client.RemoteReady = true
					client.LoadingStatus = "READY"
					server.Process.FinishLoading(p)
				else
					--p:Kick("Loading error [ClientLoaded Failed]")
				end
			end;
			
			ClientCheck = function(p,args)
				--// LastUpdate should be auto updated upon command finding
				--[[local key = tostring(p.userId)
				local special = args[1]
				local client = server.Remote.Clients[key]
				if client then--and special and special == client.Special then
					client.LastUpdate = tick()
				end--]]
			end;
			
			LogError = function(p,args)
				logError(p,args[1])
			end;
			
			Test = function(p,args)
				print("OK WE GOT COMMUNICATION! FROM: "..p.Name.." ORGL: "..args[1])
			end;
			
			ProcessCommand = function(p,args)
				server.Process.Command(p,args[1],{Check=true})	
			end;
			
			ProcessChat = function(p,args)
				server.Process.Chat(p,args[1])
				--server.Process.CustomChat(p,args[1])
			end;
			
			ProcessCustomChat = function(p,args)
				server.Process.Chat(p,args[1],"CustomChat")
				server.Process.CustomChat(p,args[1],args[2],true)
			end;
			
			PrivateMessage = function(p,args)
			--	'Reply from '..localplayer.Name,player,localplayer,ReplyBox.Text
				local title = args[1]
				local target = args[2]
				local from = args[3]
				local message = args[4]
				server.Remote.MakeGui(target,"PrivateMessage",{
					Title = "Reply from ".. p.Name;--title;
					Player = p;
					Message = service.Filter(message, p, target);
				})
				
				server.Logs.AddLog(server.Logs.Script,{
					Text = p.Name.." replied to "..tostring(target),
					Desc = message
				})
			end;
		};
		
		Fire = function(p, ...)
			local keys = server.Remote.Clients[tostring(p.userId)]
			local RemoteEvent = server.Core.RemoteEvent
			if RemoteEvent and RemoteEvent.Object then
				keys.Sent = keys.Sent+1
				pcall(RemoteEvent.Object.FireClient, RemoteEvent.Object, p, {Sent = 0},...)
			end
		end;
		
		Send = function(p,com,...)
			local keys = server.Remote.Clients[tostring(p.userId)]
			if keys and keys.RemoteReady == true then 
				server.Remote.Fire(p, server.Remote.Encrypt(com, keys.Key, keys.Cache),...)
			end
		end;
		
		Get = function(p,com,...)
			local keys = server.Remote.Clients[tostring(p.userId)]
			if keys and keys.RemoteReady == true then 
				local returns
				local key = server.Functions:GetRandom()
				local event = service.Events[key]:connect(function(...) returns = {...} end)
				
				server.Remote.PendingReturns[key] = true
				server.Remote.Send(p,"GetReturn",com,key,...)
				
				if not returns then
					delay(120, function() event:Fire() warn("GetData Request to "..tostring(p).." Timed Out") end)
					returns = {event:Wait()}
				end
				
				event:Disconnect()
				
				if returns then
					return unpack(returns)
				else
					return nil
				end
			end
		end;
		
		CheckClient = function(p)
			local ran,ret = pcall(function() return server.Remote.Get(p,"ClientHooked") end)
			if ran and ret == server.Remote.Clients[tostring(p.userId)].Special then
				return true 
			else
				return false
			end
		end;
		
		Ping = function(p)
			return server.Remote.Get(p,"Ping")
		end;
		
		MakeGui = function(p,GUI,data,themeData)
			local theme = {Desktop = server.Settings.Theme; Mobile = server.Settings.MobileTheme}
			if themeData then for ind,dat in pairs(themeData) do theme[ind] = dat end end
			server.Remote.Send(p,"UI",GUI,theme,data  or {})
		end;
		
		MakeGuiGet = function(p,GUI,data,themeData)
			local theme = {Desktop = server.Settings.Theme; Mobile = server.Settings.MobileTheme}
			if themeData then for ind,dat in pairs(themeData) do theme[ind] = dat end end
			return server.Remote.Get(p,"UI",GUI,theme,data or {})
		end;
		
		GetGui = function(p,GUI,data,themeData)
			return server.Remote.MakeGuiGet(p,GUI,data,themeData)
		end;
		
		RemoveGui = function(p,name,ignore)
			server.Remote.Send(p,"RemoveUI",name,ignore)
		end;
		
		NewParticle = function(p,target,type,properties)
			server.Remote.Send(p,"Function","NewParticle",target,type,properties)
		end;
		
		RemoveParticle = function(p,target,name)
			server.Remote.Send(p,"Function","RemoveParticle",target,name)
		end;
		
		NewLocal = function(p, type, props, parent)
			server.Remote.Send(p,"Function","NewLocal",type,props,parent)
		end;
		
		MakeLocal = function(p,object,parent,clone)
			object.Parent = p
			wait(0.5)
			server.Remote.Send(p,"Function","MakeLocal",object,parent,clone)
		end;
		
		MoveLocal = function(p,object,parent,newParent)
			server.Remote.Send(p,"Function","MoveLocal",object,false,newParent)
		end;
		
		RemoveLocal = function(p,object,parent,match)
			server.Remote.Send(p,"Function","RemoveLocal",object,parent,match)
		end;
		
		SetLighting = function(p,prop,value)
			server.Remote.Send(p,"Function","SetLighting",prop,value)
		end;
		
		FireEvent = function(p,...)
			server.Remote.Send(p,"FireEvent",...)
		end;
		
		NewPlayerEvent = function(p,type,func)
			return service.Events[type..p.userId]:connect(func)
		end;
		
		StartLoop = function(p,name,delay,funcCode)
			server.Remote.Send(p,"StartLoop",name,delay,server.Core.ByteCode(funcCode))
		end;
		
		StopLoop = function(p,name)
			server.Remote.Send(p,"StopLoop",name)
		end;
		
		PlayAudio = function(p,audioId,volume,pitch,looped)
			server.Remote.Send(p,"Function","PlayAudio",audioId,volume,pitch,looped)
		end;
		
		StopAudio = function(p,id)
			server.Remote.Send(p,"Function","StopAudio",id)
		end;
		
		FadeAudio = function(p,id,inVol,pitch,looped,incWait)
			server.Remote.Send(p,"Function","FadeAudio",id,inVol,pitch,looped,incWait)
		end;
		
		StopAllAudio = function(p)
			server.Remote.Send(p,"Function","KillAllLocalAudio")
		end;
		--[[
		StartSession = function(p,type,data)
			local index = server.Functions.GetRandom()
			local data = data or {}
			local custKill = data.Kill
			data.Type = type
			data.Player = p
			data.Index = index
			data.Kill = function()
				server.Remote.Sessions[index] = nil
				if custKill then return custKill() end
				return true
			end
			server.Remote.KillSession(p,type)
			server.Remote.Sessions[index] = data
		end;
		
		GetSession = function(p,type)
			for i,v in pairs(server.Remote.Sessions) do
				if v.Type == type and v.Player == p then
					return v,i
				end
			end
		end;
		
		KillSession = function(p,type)
			for i,v in pairs(server.Remote.Sessions) do
				if v.Type == type and v.Player == p then
					v.Kill()
				end
			end
		end;
		--]]
		LoadCode = function(p,code,getResult)
			if getResult then
				return server.Remote.Get(p,"LoadCode",server.Core.Bytecode(code))
			else
				server.Remote.Send(p,"LoadCode",server.Core.Bytecode(code))
			end
		end;
		
		Encrypt = function(str, key, cache)
			local cache = cache or server.Remote.EncodeCache or {}
			if not key or not str then 
				return str
			elseif cache[key] and cache[key][str] then
				return cache[key][str]
			else
				local keyCache = cache[key] or {}
				local tobyte = string.byte
				local abs = math.abs
				local sub = string.sub
				local len = string.len
				local char = string.char
				local endStr = {}
				local byte = function(str, pos)
					return tobyte(sub(str, pos, pos))
				end
				
				for i = 1,len(str) do
					if i%len(str) > 0 then
						if byte(str, i) + byte(key, (i%len(key))+1) > 255 then
							endStr[i] = char(abs(byte(str,i) - byte(key, (i%len(key))+1)))
						else
							endStr[i] = char(abs(byte(key, (i%len(key))+1) + byte(str, i)))
						end
					else
						if byte(str, i) + byte(key, 1) > 255 then
							endStr[i] = char(abs(byte(str, i) - byte(key, 1)))
						else
							endStr[i] = char(abs(byte(key, 1) + byte(str, i)))
						end
					end
				end
				
				endStr = table.concat(endStr)
				cache[key] = keyCache
				keyCache[str] = endStr
				return endStr
			end
		end;
		
		Decrypt = function(str, key, cache)
			local cache = cache or server.Remote.DecodeCache or {}
			if not key or not str then 
				return str 
			elseif cache[key] and cache[key][str] then
				return cache[key][str]
			else
				local keyCache = cache[key] or {}
				local tobyte = string.byte
				local abs = math.abs
				local sub = string.sub
				local len = string.len
				local char = string.char
				local endStr = {}
				local byte = function(str, pos)
					return tobyte(sub(str, pos, pos))
				end
				
				for i = 1,len(str) do
					if i%len(str) > 0 then
						if byte(str, i) + byte(key, (i%len(key))+1) > 255 then
							endStr[i] = char(abs(byte(str,i) - byte(key, (i%len(key))+1)))
						else
							endStr[i] = char(abs(byte(key, (i%len(key))+1) - byte(str, i)))
						end
					else
						if byte(str, i) + byte(key, 1) > 255 then
							endStr[i] = char(abs(byte(str, i) - byte(key, 1)))
						else
							endStr[i] = char(abs(byte(key, 1) - byte(str, i)))
						end
					end
				end
				
				endStr = table.concat(endStr)
				cache[key] = keyCache
				keyCache[str] = endStr
				return endStr
			end
		end;
	};
end