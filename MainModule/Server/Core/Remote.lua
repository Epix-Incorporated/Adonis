server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Remote
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Commands
	local function Init()
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
		Commands = server.Commands

		Logs:AddLog("Script", "Remote Module Initialized")
	end;

	server.Remote = {
		Init = Init;
		Clients = {};
		Returns = {};
		Sessions = {};
		PlayerData = {};
		PendingReturns = {};
		EncodeCache = {};
		DecodeCache = {};

		Returnables = {
			RateLimits = function(p, args)
				return server.Process.RateLimits
			end;

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
				local keys = Remote.Clients[key]

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
				if Admin.GetLevel(p) >= 4 then
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
				return Core.ExecutePermission(args[1],args[2],true)
			end;

			Variable = function(p,args)
				return Variables[args[1]]
			end;

			Setting = function(p,args)
				local setting = args[1]
				local level = Admin.GetLevel(p)
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
					G_Access_Key = true;
					--G_Access_Perms = true;
					--Allowed_API_Calls = true;
				}

				if type(setting) == "table" then
					ret = {}
					for i,set in pairs(setting) do
						if Settings[set] and not (blocked[set] and not level>=5) then
							ret[set] = Settings[set]
						end
					end
				elseif type(setting) == "string" then
					if Settings[setting] and not (blocked[setting] and not level>=5) then
						ret = Settings[setting]
					end
				end

				return ret
			end;

			UpdateList = function(p, args)
				local list = args[1]
				local update = Logs.ListUpdaters[list]
				if update then
					return update(p, unpack(args,2))
				end
			end;

			AllSettings = function(p,args)
				if Admin.GetLevel(p) >= 4 then
					local sets = {}

					sets.Settings = {}
					sets.Descs = server.Descriptions
					sets.Order = server.Order

					for i,v in pairs(Settings) do
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
						Trello_AppKey = true;
						Trello_Token = true;

						G_API = true;
						G_Access = true;
						G_Access_Key = true;
						G_Access_Perms = true;
						Allowed_API_Calls = true;

						OnStartup = true;
						OnSpawn = true;
						OnJoin = true;

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
				return Admin.GetLevel(p)
			end;

			Keybinds = function(p,args)
				local playerData = Core.GetPlayer(p)
				return playerData.Keybinds or {}
			end;

			UpdateKeybinds = function(p,args)
				local playerData = Core.GetPlayer(p)
				local binds = args[1]
				local resp = "OK"
				if type(binds)=="table" then
					playerData.Keybinds = binds
					Core.SavePlayer(p,playerData)
					resp = "Updated"
				else
					resp = "Error"
				end
				return resp
			end;

			UpdateClient = function(p,args)
				local playerData = Core.GetPlayer(p)
				local setting = args[1]
				local value = args[2]
				local data = playerData.Client or {}
				data[setting] = value
				playerData.Client = data
				Core.SavePlayer(p,playerData)
				return "Updated"
			end;

			UpdateDonor = function(p,args)
				local playerData = Core.GetPlayer(p)
				local donor = args[1]
				local resp = "OK"
				if type(donor) == "table" and donor.Cape and type(donor.Cape) == "table" then
					print(donor.Cape.Image)
					playerData.Donor = donor
					Core.SavePlayer(p, playerData)
					if donor.Enabled then
						Functions.Donor(p)
					else
						Functions.UnCape(p)
					end
					resp = "Updated"
				else
					resp = "Error"
				end
				return resp
			end;

			UpdateAliases = function(p, args)
				local aliases = args[1] or {};

				if type(aliases) == "table" then
					local data = Core.GetPlayer(p)

					--// check for stupid stuff
					for i,v in next,aliases do
						if type(i) ~= "string" or type(v) ~= "string" then
							aliases[i] = nil
						end
					end

					data.Aliases = aliases;
				end
			end;

			PlayerData = function(p,args)
				local data = Core.GetPlayer(p)
				data.isDonor = Admin.CheckDonor(p)
				return data
			end;

			CheckAdmin = function(p,args)
				return Admin.CheckAdmin(p)
			end;

			SearchCommands = function(p,args)
				return Admin.SearchCommands(p,args[1] or "all")
			end;

			FormattedCommands = function(p,args)
				local commands = Admin.SearchCommands(p,args[1] or "all")
				local tab = {}
				for i,v in pairs(commands) do
					if not v.Hidden and not v.Disabled then
						table.insert(tab,Admin.FormatCommand(v))
					end
				end
				return tab
			end;

			TerminalData = function(p,args)
				if Admin.GetLevel(p) >= 4 then
					local entry = Remote.Terminal.Data[tostring(p.UserId)]
					if not entry then
						Remote.Terminal.Data[tostring(p.UserId)] = {
							Player = p;
							Output = {};
						}
					end

					return {
						ServerLogs = service.LogService:GetLogHistory();
						ClientLogs = {};
						ScriptLogs = Logs.Script;
						AdminLogs = Logs.Commands;
						ErrorLogs = Logs.Errors;
						ChatLogs = Logs.Chats;
						JoinLogs = Logs.Joins;
						Replications = Logs.Replications;
						Exploit = Logs.Exploit;
					}
				end
			end;

			Terminal = function(p,args)
				if Admin.GetLevel(p) >= 4 then
					local data = args[2]
					local message = args[1]
					local command = message:match("(.-) ") or message
					local argString = message:match("^.- (.+)") or ""
					local comTable = Remote.Terminal.GetCommand(command)
					if comTable then
						local cArgs = Functions.Split(argString, " ", comTable.Arguments)
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
			Output = function(tab,msg,mata) table.insert(tab,Remote.Terminal.Format(msg,mata)) end;
			GetCommand = function(cmd) for i,com in next,Remote.Terminal.Commands do if com.Command:lower() == cmd:lower() then return com end end end;
			LiveOutput = function(p,data,type) Remote.FireEvent(p,"TerminalLive",{Data = data; Type = type or "Terminal";}) end;
			Commands = {
				Help = {
					Usage = "help";
					Command = "help";
					Arguments = 0;
					Description = "Shows a list of available commands and their usage";
					Function = function(p,args,data)
						local output = {}
						for i,v in next,Remote.Terminal.Commands do
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
					Description = "Sends a message in the Roblox chat";
					Function = function(p, args, data)
						for i,v in next,service.GetPlayers() do
							Remote.Send(v,"Function","ChatMessage",args[1],Color3.new(1,64/255,77/255))
						end
					end
				};

				Test = {
					Usage = "test <return>";
					Command = "test";
					Arguments = 1;
					Description = "Used to test the connection to the server and it's ability to return data";
					Function = function(p,args,data)
						Remote.Terminal.LiveOutput(p,"Return Test: "..tostring(args[1]))
					end
				};

				Loadstring = {
					Usage = "loadstring <string>";
					Command = "loadstring";
					Arguments = 1;
					Description = "Loads and runs the given lua string";
					Function = function(p,args,data)
						local newenv = GetEnv(getfenv(),{
							print = function(...) local nums = {...} for i,v in pairs(nums) do Remote.Terminal.LiveOutput(p,"PRINT: "..tostring(v)) end end;
							warn = function(...) local nums = {...} for i,v in pairs(nums) do Remote.Terminal.LiveOutput(p,"WARN: "..tostring(v)) end end;
						})

						local func,err = Core.Loadstring(args[1], newenv)
						if func then
							func()
						else
							Remote.Terminal.LiveOutput(p,"ERROR: "..tostring(err:match(":(.*)") or err))
						end
					end
				};

				Execute = {
					Usage = "execute <command>";
					Command = "execute";
					Arguments = 1;
					Description = "Runs the specified command as the server";
					Function = function(p,args,data)
						Process.Command(p, args[1], {DontLog = true, Check = true}, true)
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
						Process.Command(p, Settings.Prefix.."sudo ".. tostring(args[1]), {DontLog = true, Check = true}, true)
						return {
							"Command ran: ".. Settings.Prefix.."sudo ".. tostring(args[1])
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
			TrustCheck = function(p)
				local keys = Remote.Clients[tostring(p.userId)]
				Remote.Fire(p, "TrustCheck", keys.Special)
			end;

			ProcessChat = function(p,msg)
				Process.Chat(p,msg)
			end;
		};

		Commands = {
			GetReturn = function(p,args)
				local com = args[1]
				local key = args[2]
				local parms = {unpack(args,3)}
				local retfunc = Remote.Returnables[com]
				local retable = (retfunc and {pcall(retfunc,p,parms)}) or {}
				if retable[1] ~= true then
					logError(p,retable[2])
					Remote.Send(p, "GiveReturn", key, "__ADONIS_RETURN_ERROR", retable[2])
				else
					Remote.Send(p, "GiveReturn", key, unpack(retable,2))
				end
			end;

			GiveReturn = function(p,args)
				if Remote.PendingReturns[args[1]] then
					Remote.PendingReturns[args[1]] = nil
					service.Events[args[1]]:fire(unpack(args,2))
				end
			end;

			Session = function(p,args)
				local type = args[1]
				local data = args[2]
				local handler = Remote.SessionHandlers[type]
				if handler then
					handler(p,data)
				end
			end;

			HandleExplore = function(p, args)
				if Admin.CheckAdmin(p) then
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
				service.Events[tostring(args[1])..p.userId]:Fire(unpack(args,2))
			end;

			SaveTableAdd = function(p,args)
				if Admin.GetLevel(p)>=4 then
					local tab = args[1]
					local value = args[2]

					table.insert(Settings[tab],value)

					Core.DoSave({
						Type = "TableAdd";
						Table = tab;
						Value = value;
					})

				end
			end;

			SaveTableRemove = function(p,args)
				if Admin.GetLevel(p)>=4 then
					local tab = args[1]
					local value = args[2]
					local ind = Functions.GetIndex(Settings[tab],value)

					if ind then table.remove(Settings[tab],ind) end

					Core.DoSave({
						Type = "TableRemove";
						Table = tab;
						Value = value;
					})
				end
			end;

			SaveSetSetting = function(p,args)
				if Admin.GetLevel(p) >= 4 then
					local setting = args[1]
					local value = args[2]

					if setting == 'Prefix' or setting == 'AnyPrefix' or setting == 'SpecialPrefix' then
						local orig = Settings[setting]
						for i,v in pairs(Commands) do
							if v.Prefix == orig then
								v.Prefix = value
							end
						end

						server.Admin.CacheCommands()
					end

					Settings[setting] = value

					Core.DoSave({
						Type = "SetSetting";
						Setting = setting;
						Value = value;
					})
				end
			end;

			ClearSavedSettings = function(p,args)
				if Admin.GetLevel(p) >= 4 then
					Core.DoSave({Type = "ClearSettings"})
					Functions.Hint("Cleared saved settings",{p})
				end
			end;

			SetSetting = function(p,args)
				if Admin.GetLevel(p) >= 4 then
					local setting = args[1]
					local value = args[2]

					if setting == 'Prefix' or setting == 'AnyPrefix' or setting == 'SpecialPrefix' then
						local orig = Settings[setting]
						for i,v in pairs(Commands) do
							if v.Prefix == orig then
								v.Prefix = value
							end
						end

						server.Admin.CacheCommands()
					end

					Settings[setting] = value
				end
			end;

			Detected = function(p,args)
				Anti.Detected(p, args[1], args[2])
			end;

			TrelloOperation = function(p,args)
				if Admin.GetLevel(p) > 2 then
					local data = args[1]
					if data.Action == "MakeCard" then
						local list = data.List
						local name = data.Name
						local desc = data.Desc
						local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
						local lists = trello.getLists(Settings.Trello_Primary)
						local list = trello.getListObj(lists,list)
						if list then
							local card = trello.makeCard(list.id,name,desc)
							Functions.Hint("Made card \""..card.name.."\"",{p})
							Logs.AddLog(Logs.Script,{
								Text = tostring(p).." performed Trello operation";
								Desc = "Player created a Trello card";
								Player = p;
							})
						end
					end
				end
			end;

			ClientLoaded = function(p, args)
				local key = tostring(p.userId)
				local client = Remote.Clients[key]

				if client and client.LoadingStatus == "LOADING" then
					client.LastUpdate = tick()
					client.RemoteReady = true
					client.LoadingStatus = "READY"
					Process.FinishLoading(p)
				else
					--p:Kick("Loading error [ClientLoaded Failed]")
				end
			end;

			ClientCheck = function(p,args)
				--// LastUpdate should be auto updated upon command finding
				--[[local key = tostring(p.userId)
				local special = args[1]
				local client = Remote.Clients[key]
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
				if Process.RateLimit(p, "Command") then
					Process.Command(p,args[1],{Check=true})
				elseif Process.RateLimit(p, "RateLog") then
					Anti.Detected(p, "Log", string.format("Running commands too quickly (>Rate: %s/sec)", 1/Process.RateLimits.Chat));
					warn(string.format("%s is running commands too quickly (>Rate: %s/sec)", p.Name, 1/Process.RateLimits.Chat));
				end
			end;

			ProcessChat = function(p,args)
				Process.Chat(p,args[1])
				--Process.CustomChat(p,args[1])
			end;

			ProcessCustomChat = function(p,args)
				Process.Chat(p,args[1],"CustomChat")
				Process.CustomChat(p,args[1],args[2],true)
			end;

			PrivateMessage = function(p,args)
				--	'Reply from '..localplayer.Name,player,localplayer,ReplyBox.Text
				local title = args[1]
				local target = args[2]
				local from = args[3]
				local message = args[4]
				Remote.MakeGui(target,"PrivateMessage",{
					Title = "Reply from ".. p.Name;--title;
					Player = p;
					Message = service.Filter(message, p, target);
				})

				Logs.AddLog(Logs.Script,{
					Text = p.Name.." replied to "..tostring(target),
					Desc = message,
					Player = p;
				})
			end;
		};

		Fire = function(p, ...)
			assert(p and p:IsA("Player"), "Remote.Fire: ".. tostring(p) .." is not a valid Player")
			local keys = Remote.Clients[tostring(p.UserId)]
			local RemoteEvent = Core.RemoteEvent
			if RemoteEvent and RemoteEvent.Object then
				keys.Sent = keys.Sent+1
				pcall(RemoteEvent.Object.FireClient, RemoteEvent.Object, p, {Mode = "Fire", Sent = 0},...)
			end
		end;

		Send = function(p,com,...)
			assert(p and p:IsA("Player"), "Remote.Send: ".. tostring(p) .." is not a valid Player")
			local keys = Remote.Clients[tostring(p.UserId)]
			if keys and keys.RemoteReady == true then
				Remote.Fire(p, Remote.Encrypt(com, keys.Key, keys.Cache),...)
			end
		end;

		GetFire = function(p, ...)
			local keys = Remote.Clients[tostring(p.UserId)]
			local RemoteEvent = Core.RemoteEvent
			if RemoteEvent and RemoteEvent.Function then
				keys.Sent = keys.Sent+1
				return RemoteEvent.Function:InvokeClient(p, {Mode = "Get", Sent = 0}, ...)
			end
		end;

		Get = function(p,com,...)
			local keys = Remote.Clients[tostring(p.UserId)]
			if keys and keys.RemoteReady == true then
				local ret = Remote.GetFire(p, Remote.Encrypt(com, keys.Key, keys.Cache),...)
				if type(ret) == "table" then
					return unpack(ret);
				else
					return ret;
				end
			end
		end;

		OldGet = function(p, com, ...)
			local keys = Remote.Clients[tostring(p.UserId)]
			if keys and keys.RemoteReady == true then
				local returns, finished
				local key = Functions:GetRandom()
				local waiter = service.New("BindableEvent") -- issue with service.Events:Wait()??????
				local event = service.Events[key]:Connect(function(...) print("WE ARE GETTING A RETURN!") finished = true returns = {...} waiter:Fire() wait() waiter:Fire() waiter:Destroy() end)

				Remote.PendingReturns[key] = true
				Remote.Send(p,"GetReturn",com,key,...)

				print("GETTING RETURN");
				if not finished and not returns and p.Parent then
					local pEvent = service.Players.PlayerRemoving:Connect(function(plr) if plr == p then event:Fire() end end)
					delay(600, function() if not finished then event:Fire() end end)
					print(string.format("WAITING FOR RETURN %s", tostring(returns)));
					--returns = returns or {event:Wait()}
					waiter.Event:Wait();
					print(string.format("WE GOT IT! %s", tostring(returns)));
					pEvent:Disconnect()
				end

				print("GOT RETURN");
				event:Disconnect()

				if returns then
					if returns[1] == "__ADONIS_RETURN_ERROR" then
						error(returns[2])
					else
						return unpack(returns)
					end
				else
					return nil
				end
			end
		end;

		CheckClient = function(p)
			local ran,ret = pcall(function() return Remote.Get(p,"ClientHooked") end)
			if ran and ret == Remote.Clients[tostring(p.UserId)].Special then
				return true
			else
				return false
			end
		end;

		Ping = function(p)
			return Remote.Get(p,"Ping")
		end;

		MakeGui = function(p, GUI, data, themeData)
			local theme = {Desktop = Settings.Theme; Mobile = Settings.MobileTheme}
			if themeData then for ind,dat in pairs(themeData) do theme[ind] = dat end end
			Remote.Send(p, "UI", GUI, theme, data or {})
		end;

		MakeGuiGet = function(p,GUI,data,themeData)
			local theme = {Desktop = Settings.Theme; Mobile = Settings.MobileTheme}
			if themeData then for ind,dat in pairs(themeData) do theme[ind] = dat end end
			return Remote.Get(p,"UI",GUI,theme,data or {})
		end;

		GetGui = function(p,GUI,data,themeData)
			return Remote.MakeGuiGet(p,GUI,data,themeData)
		end;

		RemoveGui = function(p,name,ignore)
			Remote.Send(p,"RemoveUI",name,ignore)
		end;

		NewParticle = function(p,target,type,properties)
			Remote.Send(p,"Function","NewParticle",target,type,properties)
		end;

		RemoveParticle = function(p,target,name)
			Remote.Send(p,"Function","RemoveParticle",target,name)
		end;

		NewLocal = function(p, type, props, parent)
			Remote.Send(p,"Function","NewLocal",type,props,parent)
		end;

		MakeLocal = function(p,object,parent,clone)
			object.Parent = p
			wait(0.5)
			Remote.Send(p,"Function","MakeLocal",object,parent,clone)
		end;

		MoveLocal = function(p,object,parent,newParent)
			Remote.Send(p,"Function","MoveLocal",object,false,newParent)
		end;

		RemoveLocal = function(p,object,parent,match)
			Remote.Send(p,"Function","RemoveLocal",object,parent,match)
		end;

		SetLighting = function(p,prop,value)
			Remote.Send(p,"Function","SetLighting",prop,value)
		end;

		FireEvent = function(p,...)
			Remote.Send(p,"FireEvent",...)
		end;

		NewPlayerEvent = function(p,type,func)
			return service.Events[type..p.userId]:Connect(func)
		end;

		StartLoop = function(p,name,delay,funcCode)
			Remote.Send(p,"StartLoop",name,delay,Core.ByteCode(funcCode))
		end;

		StopLoop = function(p,name)
			Remote.Send(p,"StopLoop",name)
		end;

		PlayAudio = function(p,audioId,volume,pitch,looped)
			Remote.Send(p,"Function","PlayAudio",audioId,volume,pitch,looped)
		end;

		StopAudio = function(p,id)
			Remote.Send(p,"Function","StopAudio",id)
		end;

		FadeAudio = function(p,id,inVol,pitch,looped,incWait)
			Remote.Send(p,"Function","FadeAudio",id,inVol,pitch,looped,incWait)
		end;

		StopAllAudio = function(p)
			Remote.Send(p,"Function","KillAllLocalAudio")
		end;
		--[[
		StartSession = function(p,type,data)
			local index = Functions.GetRandom()
			local data = data or {}
			local custKill = data.Kill
			data.Type = type
			data.Player = p
			data.Index = index
			data.Kill = function()
				Remote.Sessions[index] = nil
				if custKill then return custKill() end
				return true
			end
			Remote.KillSession(p,type)
			Remote.Sessions[index] = data
		end;

		GetSession = function(p,type)
			for i,v in pairs(Remote.Sessions) do
				if v.Type == type and v.Player == p then
					return v,i
				end
			end
		end;

		KillSession = function(p,type)
			for i,v in pairs(Remote.Sessions) do
				if v.Type == type and v.Player == p then
					v.Kill()
				end
			end
		end;
		--]]
		LoadCode = function(p,code,getResult)
			if getResult then
				return Remote.Get(p,"LoadCode",Core.Bytecode(code))
			else
				Remote.Send(p,"LoadCode",Core.Bytecode(code))
			end
		end;

		Encrypt = function(str, key, cache)
			local cache = cache or Remote.EncodeCache or {}
			if not key or not str then
				return str
			elseif cache[key] and cache[key][str] then
				return cache[key][str]
			else
				local keyCache = cache[key] or {}
				local byte = string.byte
				local abs = math.abs
				local sub = string.sub
				local len = string.len
				local char = string.char
				local endStr = {}

				for i = 1,len(str) do
					local keyPos = (i%len(key))+1
					endStr[i] = string.char(((byte(sub(str, i, i)) + byte(sub(key, keyPos, keyPos)))%126) + 1)
				end

				endStr = table.concat(endStr)
				cache[key] = keyCache
				keyCache[str] = endStr
				return endStr
			end
		end;

		Decrypt = function(str, key, cache)
			local cache = cache or Remote.DecodeCache or {}
			if not key or not str then
				return str
			elseif cache[key] and cache[key][str] then
				return cache[key][str]
			else
				local keyCache = cache[key] or {}
				local byte = string.byte
				local abs = math.abs
				local sub = string.sub
				local len = string.len
				local char = string.char
				local endStr = {}

				for i = 1,len(str) do
					local keyPos = (i%len(key))+1
					endStr[i] = string.char(((byte(sub(str, i, i)) - byte(sub(key, keyPos, keyPos)))%126) - 1)
				end

				endStr = table.concat(endStr)
				cache[key] = keyCache
				keyCache[str] = endStr
				return endStr
			end
		end;
	};
end
