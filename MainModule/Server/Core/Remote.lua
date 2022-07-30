server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Remote
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Defaults, Commands
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
		Defaults = server.Defaults;
		Commands = server.Commands

		Remote.Init = nil;
		Logs:AddLog("Script", "Remote Module Initialized")
	end;

	local function RunAfterPlugins(data)
		for com in next, Remote.Commands do
			if string.len(com) > Remote.MaxLen then
				Remote.MaxLen = string.len(com)
			end
		end

		--// Start key check loop
		service.StartLoop("ClientKeyCheck", 60, Remote.CheckKeys, true);

		Remote.RunAfterPlugins = nil;
		Logs:AddLog("Script", "Remote Module RunAfterPlugins Finished");
	end

	server.Remote = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;

		MaxLen = 0;
		Clients = {};
		Returns = {};
		Sessions = {};
		PendingReturns = {};
		EncodeCache = {};
		DecodeCache = {};
		RemoteExecutionConfirmed = {};

		TimeUntilKeyDestroyed = 60 * 5; --// How long until a player's key data should be completely removed?

		--// Settings any client/user can grab
		AllowedSettings = {
			Theme = true;
			MobileTheme = true;
			DefaultTheme = true;
			HelpButtonImage = true;
			Prefix = true;
			PlayerPrefix = true;
			SpecialPrefix = true;
			BatchKey = true;
			AnyPrefix = true;
			DonorCommands = true;
			DonorCapes = true;
			ConsoleKeyCode = true;
			SplitKey = true;
		};

		--// Settings that are never sent to the client
		--// These are blacklisted at the datastore level and cannot be updated in-game
		BlockedSettings = {
			Trello_Enabled = true;
			Trello_Primary = true;
			Trello_Secondary = true;
			Trello_Token = true;
			Trello_AppKey = true;

			DataStore = true;
			DataStoreKey = true;
			DataStoreEnabled = true;

			LoadAdminsFromDS = true;

			Creators = true;
			Permissions = true;

			G_API = true;
			G_Access = true;
			G_Access_Key = true;
			G_Access_Perms = true;
			Allowed_API_Calls = true;

			OnStartup = true;
			OnSpawn = true;
			OnJoin = true;

			CustomRanks = true;
		};

		Returnables = {
			RateLimits = function(p: Player,args: {[number]: any})
				return server.Process.RateLimits
			end;

			Test = function(p: Player,args: {[number]: any})
				return "HELLO FROM THE OTHER SIDE :)!"
			end;

			Ping = function(p: Player,args: {[number]: any})
				return "Pong"
			end;

			Filter = function(p: Player,args: {[number]: any})
				return service.Filter(args[1],args[2],args[3])
			end;

			BroadcastFilter = function(p: Player,args: {[number]: any})
				return service.BroadcastFilter(args[1],args[2] or p)
			end;

			TaskManager = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local action = args[1]
					if action == "GetTasks" then
						local tab = {}
						for _, v in next, service.GetTasks() do
							local new = {
								Status = v.Status;
								Name = v.Name;
								Index = v.Index;
								Created = v.Created;
								Function = tostring(v.Function);
							}
							table.insert(tab,new)
						end
						return tab
					end
				end
			end;

			ExecutePermission = function(p: Player,args: {[number]: any})
				return Core.ExecutePermission(args[1],args[2],true)
			end;

			Variable = function(p: Player,args: {[number]: any})
				return Variables[args[1]]
			end;

			Default = function(p: Player,args: {[number]: any})
				local setting = args[1]
				local level = Admin.GetLevel(p)
				local ret
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
					WebPanel_ApiKey = true;
					--G_Access_Perms = true;
					--Allowed_API_Calls = true;
				}

				if type(setting) == "table" then
					ret = {}
					for _,set in setting do
						if Defaults[set] and (not blocked[set] or level >= Settings.Ranks.Creators.Level) then
							ret[set] = Defaults[set]
						end
					end
				elseif type(setting) == "string" then
					if Defaults[setting] and (not blocked[setting] or level >= Settings.Ranks.Creators.Level) then
						ret = Defaults[setting]
					end
				end

				return ret
			end;

			AllDefaults = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local sets = {
						Settings = table.clone(Defaults);
						Descs = server.Descriptions;
						Order = server.Order;
					}

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

					for setting in sets.Settings do
						if blocked[setting] then
							sets.Settings[setting] = nil
						end
					end

					return sets
				end
			end;

			Setting = function(p: Player,args: {[number]: any})
				local setting = args[1]
				local level = Admin.GetLevel(p)
				local ret
				local allowed = Remote.AllowedSettings

				if type(setting) == "table" then
					ret = {}
					for _,set in setting do
						if Settings[set] and (allowed[set] or level>=Settings.Ranks.Creators.Level) then
							ret[set] = Settings[set]
						end
					end
				elseif type(setting) == "string" then
					if Settings[setting] and (allowed[setting] or level>=Settings.Ranks.Creators.Level) then
						ret = Settings[setting]
					end
				end

				return ret
			end;

			AllSettings = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local sets = {
						Settings = table.clone(Settings);
						Descs = server.Descriptions;
						Order = server.Order;
					}

					local blocked = Remote.BlockedSettings

					for setting in sets.Settings do
						if blocked[setting] then
							sets.Settings[setting] = nil
						end
					end

					return sets
				end
			end;

			UpdateList = function(p: Player,args: {[number]: any})
				local list = args[1]
				local update = Logs.ListUpdaters[list]
				if update then
					return update(p, unpack(args,2))
				end
			end;

			AdminLevel = function(p: Player,args: {[number]: any})
				return Admin.GetLevel(p)
			end;

			Keybinds = function(p: Player,args: {[number]: any})
				local playerData = Core.GetPlayer(p)
				return playerData.Keybinds or {}
			end;

			UpdateKeybinds = function(p: Player,args: {[number]: any})
				local playerData = Core.GetPlayer(p)
				local binds = args[1]
				local resp = "OK"
				if type(binds) == "table" then
					playerData.Keybinds = binds
					Core.SavePlayer(p,playerData)
					resp = "Updated"
				else
					resp = "Error"
				end

				return resp
			end;

			Playlist = function(p: Player,args: {[number]: any})
				local playerData = Core.GetPlayer(p)
				return playerData.CustomPlaylist or {}
			end;

			UpdatePlaylist = function(p: Player,args: {[number]: any})
				local resp = "Error: Unknown Error"
				if type(args)=="table" then
					if string.len(service.HttpService:JSONEncode(args)) < 4000 then
						local playerData = Core.GetPlayer(p)
						playerData.CustomPlaylist = args[1]
						Core.SavePlayer(p,playerData)
						resp = "Updated"
					else
						resp = "Error: Playlist is too big (4000+ chars)"
					end
				else
					resp = "Error: Data is not a valid table"
				end
				return resp
			end;

			UpdateClient = function(p: Player,args: {[number]: any})
				local playerData = Core.GetPlayer(p)
				local setting = args[1]
				local value = args[2]
				local data = playerData.Client or {}

				data[setting] = value
				playerData.Client = data
				Core.SavePlayer(p, playerData)

				return "Updated"
			end;

			UpdateDonor = function(p: Player,args: {[number]: any})
				local playerData = Core.GetPlayer(p)
				local donor = args[1]
				local resp = "OK"
				if type(donor) == "table" and donor.Cape and type(donor.Cape) == "table" then
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

			UpdateAliases = function(p: Player,args: {[number]: any})
				local aliases = args[1] or {};

				if type(aliases) == "table" then
					local data = Core.GetPlayer(p)

					--// check for stupid stuff
					for i,v in next, aliases do
						if type(i) ~= "string" or type(v) ~= "string" then
							aliases[i] = nil
						end
					end

					data.Aliases = aliases;
				end
			end;

			PlayerData = function(p: Player,args: {[number]: any})
				local data = Core.GetPlayer(p)
				data.isDonor = Admin.CheckDonor(p)
				return data
			end;

			CheckAdmin = function(p: Player,args: {[number]: any})
				return Admin.CheckAdmin(p)
			end;

			SearchCommands = function(p: Player,args: {[number]: any})
				return Admin.SearchCommands(p,args[1] or "all")
			end;

			CheckBackpack = function(p: Player,args: {[number]: any})
				return Anti.CheckBackpack(p,args[1])
			end;

			FormattedCommands = function(p: Player,args: {[number]: any})
				local commands = Admin.SearchCommands(p,args[1] or "all")
				local tab = {}
				for _,v in commands do
					if not v.Hidden and not v.Disabled then
						for a in v.Commands do
							table.insert(tab,Admin.FormatCommand(v,a))
						end
					end
				end
				return tab
			end;

			TerminalData = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
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

			Terminal = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local data = args[2]
					local message = args[1]
					local command = string.match(message, "(.-) ") or message
					local argString = string.match(message, "^.- (.+)") or ""
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
			end;

			AudioLib = function(p,args)
				if Admin.GetLevel(p) >= Settings.Ranks.Moderators.Level then
					if not server.Functions.AudioLib then
						local audioLibFolder = workspace:FindFirstChild("ADONIS_AUDIOLIB")
						if not audioLibFolder then
							audioLibFolder = service.New("Folder")
							audioLibFolder.Name = "ADONIS_AUDIOLIB"
							audioLibFolder.Parent = workspace
						end
						server.Functions.AudioLib = require(server.Shared.AudioLib).new(audioLibFolder)
					end

					return server.Functions.AudioLib[args[1][1]](server.Functions.AudioLib, args[1][2])
				else
					task.spawn(Remote.MakeGui,p,"Notification",{
						Title = "Global Audio";
						Message = "Only Moderators or above may broadcast audio!";
						Icon = server.Shared.MatIcons.Language;
						Time = 3;
					})
				end
			end;
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
						for _,v in service.GetPlayers() do
							Remote.Send(v,"Function","ChatMessage",args[1],Color3.fromRGB(255,64,77))
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
							print = function(...) local nums = {...} for _,v in nums do Remote.Terminal.LiveOutput(p,"PRINT: "..tostring(v)) end end;
							warn = function(...) local nums = {...} for _,v in nums do Remote.Terminal.LiveOutput(p,"WARN: "..tostring(v)) end end;
						})

						if not server.Remote.RemoteExecutionConfirmed[p.UserId] then
							local ans = Remote.GetGui(p, "YesNoPrompt", {
								Icon = server.MatIcons.Warning;
								Question = "Are you sure you want to load this script into the server env?";
								Title = "Adonis DebugLoadstring";
								Delay = 3;
							})

							if ans == "Yes" then
								server.Remote.RemoteExecutionConfirmed[p.UserId] = true
							else
								return
							end
						end

						local func,err = Core.Loadstring(args[1], newenv)
						if func then
							func()
						else
							Remote.Terminal.LiveOutput(p,"ERROR: "..tostring(string.match(err, ":(.*)") or err))
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
							for _,v in plrs do
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
							for _,v in plrs do
								local char = v.Character
								if char and char.ClassName == "Model" then
									char:BreakJoints()
									return {"Killed "..tostring(v.Name)}
								else
									return {tostring(v.Name).." has no character or it's not a model"}
								end
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
							for _,v in plrs do
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
						service.PlayerAdded:Connect(function(p)
							p:Kick()
						end)

						for _,v in service.Players:GetPlayers() do
							v:Kick()
						end
					end
				};
			};
		};

		SessionHandlers = {

		};

		UnEncrypted = setmetatable({}, {
			__newindex = function(_, ind, val)
				warn("Unencrypted remote commands are deprecated; moving", ind, "to Remote.Commands")
				Remote.Commands[ind] = val
			end
		});

		Commands = {
			GetReturn = function(p: Player,args: {[number]: any})
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

			GiveReturn = function(p: Player,args: {[number]: any})
				if Remote.PendingReturns[args[1]] then
					Remote.PendingReturns[args[1]] = nil
					service.Events[args[1]]:Fire(unpack(args,2))
				end
			end;

			ClientCheck = function(p: Player,args: {[number]: any})
				local key = tostring(p.UserId)
				--local data = args[1]
				local special = args[2]
				local keys = Remote.Clients[key]

				if keys and special and special == keys.Special then
					keys.LastUpdate = os.time()
				else
					Anti.Detected(p, "Log", "Client sent incorrect check data")
				end
			end;

			Session = function(p: Player,args: {[number]: any})
				local sessionKey = args[1];
				local session = sessionKey and Remote.GetSession(sessionKey);

				if session and session.Users[p] then
					session:FireEvent(p, unpack(args, 2));
				end
			end;

			HandleExplore = function(p, args)
				local command = Commands.Explore
				local adminLevel = Admin.GetLevel(p)
				if command and Admin.CheckComLevel(adminLevel, command.AdminLevel) then
					local obj = args[1];
					local com = args[2];
					local data = args[3];

					if obj then
						if com == "Delete" then
							if not pcall(function()
									obj:Destroy()
								end) then
								Remote.MakeGui(p ,"Notification", {
									Title = "Error";
									Icon = server.MatIcons.Error;
									Message = "Cannot delete object.";
									Time = 2;
								})
							end
						end
					end
				end
			end;

			PlayerEvent = function(p: Player,args: {[number]: any})
				service.Events[tostring(args[1])..p.UserId]:Fire(unpack(args,2))
			end;

			SaveTableAdd = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local tabName = args[1];
					local value = args[2];
					local tab = Core.IndexPathToTable(tabName);

					table.insert(tab, value);

					Core.DoSave({
						Type = "TableAdd";
						Table = tabName;
						Value = value;
					})
				end
			end;

			SaveTableRemove = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local tabName = args[1];
					local value = args[2];
					local tab = Core.IndexPathToTable(tabName);
					local ind = Functions.GetIndex(tab, value);

					if ind then
						table.remove(tab, ind);
					end

					Core.DoSave({
						Type = "TableRemove";
						Table = tabName;
						Value = value;
					})
				end
			end;

			SaveSetSetting = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local setting = args[1]
					local value = args[2]

					if setting == 'Prefix' or setting == 'AnyPrefix' or setting == 'SpecialPrefix' then
						local orig = Settings[setting]
						for _, v in Commands do
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

			ClearSavedSettings = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					Core.DoSave({Type = "ClearSettings"})
					Functions.Hint("Cleared saved settings", {p})
				end
			end;

			SetSetting = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local setting = args[1]
					local value = args[2]

					if setting == "Prefix" or setting == "AnyPrefix" or setting == "SpecialPrefix" then
						local orig = Settings[setting]
						for _, v in Commands do
							if v.Prefix == orig then
								v.Prefix = value
							end
						end

						server.Admin.CacheCommands()
					end

					Settings[setting] = value
				end
			end;

			Detected = function(p: Player,args: {[number]: any})
				Anti.Detected(p, args[1], args[2])
			end;

			TrelloOperation = function(p: Player,args: {[number]: any})
				local adminLevel = Admin.GetLevel(p)

				local trello = HTTP.Trello.API

				local data = args[1]
				if data.Action == "MakeCard" then
					local command = Commands.MakeCard
					if command and Admin.CheckComLevel(adminLevel, command.AdminLevel) then
						local listName = data.List
						local name = data.Name
						local desc = data.Desc

						for _, overrideList in HTTP.Trello.GetOverrideLists() do 
							if service.Trim(string.lower(overrideList)) == service.Trim(string.lower(listName)) then
								Functions.Hint("You cannot create a card in that list", {p})
								return
							end
						end

						local lists = trello.getLists(Settings.Trello_Primary)
						local list = trello.getListObj(lists, listName)
						if list then
							local card = trello.makeCard(list.id, name, desc)
							Functions.Hint("Made card \""..card.name.."\" in list \""..list.name.."\"", {p})
							Logs.AddLog(Logs.Script,{
								Text = tostring(p).." performed Trello operation";
								Desc = "Player created a Trello card";
								Player = p;
							})
						else
							Functions.Hint("\""..listName.."\" does not exist", {p})
						end
					end
				end
			end;

			ClientLoaded = function(p: Player, args: {[number]: any})
				local key = tostring(p.UserId)
				local client = Remote.Clients[key]

				if client and client.LoadingStatus == "LOADING" then
					client.LastUpdate = os.time()
					client.RemoteReady = true
					client.LoadingStatus = "READY"

					service.Events.ClientLoaded:Fire(p)
					Process.FinishLoading(p)
				else
					warn("[CLI-199524] ClientLoaded fired when not ready for ".. tostring(p))
					Logs:AddLog("Script", string.format("%s fired ClientLoaded too early", tostring(p)));
					--p:Kick("Loading error [ClientLoaded Failed]")
				end
			end;

			LogError = function(p: Player,args: {[number]: any})
				logError(p,args[1])
			end;

			Test = function(p: Player,args: {[number]: any})
				print("OK WE GOT COMMUNICATION! FROM: "..p.Name.." ORGL: "..args[1])
			end;

			ProcessCommand = function(p: Player,args: {[number]: any})
				if Process.RateLimit(p, "Command") then
					Process.Command(p, args[1], {
						Check = true
					})
				elseif Process.RateLimit(p, "RateLog") then
					Anti.Detected(p, "Log", string.format("Running commands too quickly (>Rate: %s/sec)", 1/Process.RateLimits.Command));
					warn(string.format("%s is running commands too quickly (>Rate: %s/sec)", p.Name, 1/Process.RateLimits.Command));
				end
			end;

			ProcessChat = function(p: Player,args: {[number]: any})
				Process.Chat(p,args[1])
			end;

			ProcessCustomChat = function(p: Player,args: {[number]: any})
				Process.Chat(p,args[1],"CustomChat")
				Process.CustomChat(p,args[1],args[2],true)
			end;

			PrivateMessage = function(p: Player,args: {[number]: any})
				if not type(args[1]) == "string" then return end

				--	'Reply from '..localplayer.Name,player,localplayer,ReplyBox.Text
				local target = Variables.PMtickets[args[1]]
				if target or Admin.CheckAdmin(p) then
					if target then
						Variables.PMtickets[args[1]] = nil;
					else
						target = args[2]
					end

					local title = string.format("Reply from %s (@%s)", p.DisplayName, p.Name)
					local message = args[3]

					local replyTicket = Functions.GetRandom()
					Variables.PMtickets[replyTicket] = p
					Remote.MakeGui(target,"PrivateMessage",{
						Title = title;
						Player = p;
						Message = service.Filter(message, p, target);
						replyTicket = replyTicket;
					})

					Logs:AddLog(Logs.Script,{
						Text = p.Name.." replied to "..tostring(target),
						Desc = message,
						Player = p;
					})
				else
					Anti.Detected(p, "info", "Invalid PrivateMessage ticket! Got: ".. tostring(args[2]))
				end
			end;
		};

		NewSession = function(sessionType: string)
			local session = {
				Ended = false;
				NumUsers = 0;
				Data = {};
				Users = {};
				Events = {};
				SessionType = sessionType;
				SessionKey = Functions.GetRandom();
				SessionEvent = service.New("BindableEvent");

				AddUser = function(self, p, defaultData)
					assert(not self.Ended, "Cannot add user to session: Session Ended")
					if not self.Users[p] then
						self.Users[p] = defaultData or {};
						self.NumUsers += 1;
					end
				end;

				RemoveUser = function(self, p)
					assert(not self.Ended, "Cannot remove user from session: Session Ended")
					if self.Users[p] then
						self.Users[p] = nil;
						self.NumUsers -= 1;

						if self.NumUsers == 0 then
							self:FireEvent(nil, "LastUserRemoved");
						else
							self:FireEvent(p, "RemovedFromSession");
						end
					end
				end;

				SendToUsers = function(self, ...)
					if not self.Ended then
						for p in next,self.Users do
							Remote.Send(p, "SessionData", self.SessionKey, ...);
						end;
					end
				end;

				SendToUser = function(self, p, ...)
					if not self.Ended and self.Users[p] then
						Remote.Send(p, "SessionData", self.SessionKey, ...);
					end
				end;

				FireEvent = function(self, ...)
					if not self.Ended then
						self.SessionEvent:Fire(...);
					end
				end;

				End = function(self)
					if not self.Ended then
						for t,event in next,self.Events do
							event:Disconnect();
						end
						table.clear(self.Events)

						self:SendToUsers("SessionEnded");

						table.clear(self.Users);
						self.NumUsers = 0;
						self.SessionEvent:Destroy();

						self.Ended = true;
						Remote.Sessions[self.SessionKey] = nil;
					end
				end;

				ConnectEvent = function(self, func)
					assert(not self.Ended, "Cannot connect session event: Session Ended")

					local connection = self.SessionEvent.Event:Connect(func);
					table.insert(self.Events, connection)

					return connection;
				end;
			};

			session.Events.PlayerRemoving = service.Players.PlayerRemoving:Connect(function(plr)
				if session.Users[plr] then
					session:RemoveUser(plr)
				end
			end)

			Remote.Sessions[session.SessionKey] = session;

			return session;
		end;

		GetSession = function(sessionKey: string)
			return Remote.Sessions[sessionKey];
		end;

		Fire = function(p: Player,...)
			assert(p and p:IsA("Player"), "Remote.Fire: ".. tostring(p) .." is not a valid Player")
			local keys = Remote.Clients[tostring(p.UserId)]
			local RemoteEvent = Core.RemoteEvent
			if RemoteEvent and RemoteEvent.Object then
				keys.Sent += 1
				pcall(RemoteEvent.Object.FireClient, RemoteEvent.Object, p, {Mode = "Fire", Sent = 0},...)
			end
		end;

		Send = function(p: Player,com: string,...)
			assert(p and p:IsA("Player"), "Remote.Send: ".. tostring(p) .." is not a valid Player")
			local keys = Remote.Clients[tostring(p.UserId)]
			if keys and keys.RemoteReady == true then
				Remote.Fire(p, Remote.Encrypt(com, keys.Key, keys.Cache),...)
			end
		end;

		GetFire = function(p: Player,...)
			local keys = Remote.Clients[tostring(p.UserId)]
			local RemoteEvent = Core.RemoteEvent
			if RemoteEvent and RemoteEvent.Function then
				keys.Sent += 1
				return RemoteEvent.Function:InvokeClient(p, {Mode = "Get", Sent = 0}, ...)
			end
		end;

		Get = function(p: Player,com: string,...)
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

		OldGet = function(p: Player,com: string, ...)
			local keys = Remote.Clients[tostring(p.UserId)]
			if keys and keys.RemoteReady == true then
				local returns, finished
				local key = Functions:GetRandom()
				local Yield = service.Yield();
				local event = service.Events[key]:Connect(function(...) print("WE ARE GETTING A RETURN!") finished = true returns = {...} Yield:Release() end)

				Remote.PendingReturns[key] = true
				Remote.Send(p,"GetReturn",com,key,...)

				print("GETTING RETURN");
				if not finished and not returns and p.Parent then
					local pEvent = service.Players.PlayerRemoving:Connect(function(plr) if plr == p then event:Fire() end end)
					task.delay(600, function() if not finished then event:Fire() end end)
					print(string.format("WAITING FOR RETURN %s", tostring(returns)));
					--returns = returns or {event:Wait()}
					Yield:Wait();
					Yield:Destroy();

					print(string.format("WE GOT IT! %s", tostring(returns)));
					pEvent:Disconnect()
					pEvent = nil
				end

				print("GOT RETURN");
				event:Disconnect()
				event = nil

				if returns then
					if returns[1] == "__ADONIS_RETURN_ERROR" then
						error(returns[2])
					else
						return unpack(returns)
					end
				else
					return
				end
			end
		end;

		CheckClient = function(p: Player)
			local ran,ret = pcall(function() return Remote.Get(p,"ClientHooked") end)
			if ran and ret == Remote.Clients[tostring(p.UserId)].Special then
				return true
			else
				return false
			end
		end;

		CheckKeys = function()
			--// Check all keys for ones no longer in use for >10 minutes (so players who actually left aren't tracked forever)
			for key, data in Remote.Clients do
				local continue = true;

				if data.Player and data.Player.Parent == service.Players then
					continue = false;
				else
					local Player = service.Players:GetPlayerByUserId(key)
					if Player then
						data.Player = Player
						continue = false
					end
				end

				if continue and (data.LastUpdate and os.time() - data.LastUpdate > Remote.TimeUntilKeyDestroyed) then
					Remote.Clients[key] = nil;
					--print("Client key removed for UserId ".. tostring(key))
					Logs:AddLog("Script", "Client key removed for UserId ".. tostring(key))
				end
			end

			return;
		end;

		Ping = function(p: Player)
			return Remote.Get(p,"Ping")
		end;

		MakeGui = function(p: Player,GUI: string,data: {[any]: any},themeData: {[string]: any})
			if not p then return end
			local theme = {Desktop = Settings.Theme; Mobile = Settings.MobileTheme}
			if themeData then for ind,dat in themeData do theme[ind] = dat end end
			Remote.Send(p,"UI",GUI,theme,data or {})
		end;

		MakeGuiGet = function(p: Player,GUI: string,data: {[any]: any},themeData: {[string]: any})
			if not p then return nil end
			local theme = {Desktop = Settings.Theme; Mobile = Settings.MobileTheme}
			if themeData then for ind,dat in themeData do theme[ind] = dat end end
			return Remote.Get(p,"UI",GUI,theme,data or {})
		end;

		GetGui = function(p: Player,GUI: string,data: {[any]: any},themeData: {[string]: any})
			return Remote.MakeGuiGet(p,GUI,data,themeData)
		end;

		RemoveGui = function(p: Player,name: string | boolean | Instance,ignore: string)
			if not p then return end
			Remote.Send(p,"RemoveUI",name,ignore)
		end;

		RefreshGui = function(p: Player,name: string | boolean | Instance,ignore: string,data: {[any]: any},themeData: {[string]: any})
			if not p then return end
			local theme = {Desktop = Settings.Theme; Mobile = Settings.MobileTheme}
			if themeData then for ind,dat in themeData do theme[ind] = dat end end
			Remote.Send(p,"RefreshUI",name,ignore,themeData,data or {})
		end;

		NewParticle = function(p: Player,target: Instance,class: string,properties: {[string]: any})
			Remote.Send(p,"Function","NewParticle",target,class,properties)
		end;

		RemoveParticle = function(p: Player,target: Instance,name: string)
			Remote.Send(p,"Function","RemoveParticle",target,name)
		end;

		NewLocal = function(p: Player,class: string,props: {[string]: any},parent: string?)
			Remote.Send(p,"Function","NewLocal",class,props,parent)
		end;

		MakeLocal = function(p: Player,object: Instance,parent: string?,clone: boolean?)
			object.Parent = p
			task.wait(0.5)
			Remote.Send(p,"Function","MakeLocal",object,parent,clone)
		end;

		MoveLocal = function(p: Player,object: string,parent: string?,newParent: Instance)
			Remote.Send(p,"Function","MoveLocal",object,false,newParent)
		end;

		RemoveLocal = function(p: Player,object: string,parent: string?,match: boolean?)
			Remote.Send(p,"Function","RemoveLocal",object,parent,match)
		end;

		SetLighting = function(p: Player,prop: string,value: any)
			Remote.Send(p,"Function","SetLighting",prop,value)
		end;

		FireEvent = function(p: Player,...)
			Remote.Send(p,"FireEvent",...)
		end;

		NewPlayerEvent = function(p: Player,type: string,func: (...any) -> (...any))
			return service.Events[type..p.UserId]:Connect(func)
		end;

		StartLoop = function(p: Player,name: string,delay: number | string,funcCode: string)
			Remote.Send(p,"StartLoop",name,delay,Core.ByteCode(funcCode))
		end;

		StopLoop = function(p: Player,name: string)
			Remote.Send(p,"StopLoop",name)
		end;

		PlayAudio = function(p: Player,audioId: number,volume: number?,playbackSpeed: number?,looped: boolean?)
			Remote.Send(p,"Function","PlayAudio",audioId,volume,playbackSpeed,looped)
		end;

		StopAudio = function(p: Player,audioId: number)
			Remote.Send(p,"Function","StopAudio",audioId)
		end;

		FadeAudio = function(p: Player,audioId: number,inVol: number?,playbackSpeed: number?,looped: boolean?,incWait: number?)
			Remote.Send(p,"Function","FadeAudio",audioId,inVol,playbackSpeed,looped,incWait)
		end;

		StopAllAudio = function(p: Player)
			Remote.Send(p,"Function","KillAllLocalAudio")
		end;

		LoadCode = function(p: Player,code: string,getResult: boolean)
			if getResult then
				return Remote.Get(p,"LoadCode",Core.Bytecode(code))
			else
				Remote.Send(p,"LoadCode",Core.Bytecode(code))
			end
		end;

		Encrypt = function(str: string?, key: string?, cache: {[string]: any}?)
			cache = cache or Remote.EncodeCache or {}

			if not key or not str then
				return str
			elseif cache[key] and cache[key][str] then
				return cache[key][str]
			else
				local byte = string.byte
				local sub = string.sub
				local char = string.char

				local keyCache = cache[key] or {}
				local endStr = {}

				for i = 1, #str do
					local keyPos = (i % #key) + 1
					endStr[i] = char(((byte(sub(str, i, i)) + byte(sub(key, keyPos, keyPos)))%126) + 1)
				end

				endStr = table.concat(endStr)
				cache[key] = keyCache
				keyCache[str] = endStr
				return endStr
			end
		end;

		Decrypt = function(str: string?, key: string?, cache: {[string]: any}?)
			cache = cache or Remote.DecodeCache or {}

			if not key or not str then
				return str
			elseif cache[key] and cache[key][str] then
				return cache[key][str]
			else
				local keyCache = cache[key] or {}
				local byte = string.byte
				local sub = string.sub
				local char = string.char
				local endStr = {}

				for i = 1, #str do
					local keyPos = (i % #key)+1
					endStr[i] = char(((byte(sub(str, i, i)) - byte(sub(key, keyPos, keyPos)))%126) - 1)
				end

				endStr = table.concat(endStr)
				cache[key] = keyCache
				keyCache[str] = endStr
				return endStr
			end
		end;
	};
end
