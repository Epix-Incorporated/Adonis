server = nil
service = nil
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
	local logError
	-- Bounds personal alias updates without retaining players after they leave.
	local aliasUpdateTimes = setmetatable({}, {__mode = "k"})
	-- Applies a validated setting edit and reports only fixed failure descriptions to its author.
	local function changeSetting(player, setting, value, save)
		local accepted, prepared, record = server.Core.PrepareSetting(player, setting, value)
		if not accepted then
			server.Functions.Hint(prepared, {player})
			return false
		end
		server.Settings[setting] = prepared
		server.Core.RegisterSettingText(setting, prepared, record)
		if save then server.Core.DoSave({Type = "SetSetting", Setting = setting, Value = prepared, TextRecord = record}) end
		server.Logs.AddAudit("Script", "Setting", player, {Outcome = "Completed"})
		return true
	end

	-- Edits a declared settings list using fresh authored input or an opaque viewer-specific handle.
	local function editSettingsTable(player, action, path, value)
		if server.Admin.GetLevel(player) < server.Settings.Ranks.Creators.Level then return {Success = false, Message = "Permission denied"} end
		local tab = server.Core.GetEditableSettingsTable(path)
		if not tab then return {Success = false, Message = "This table cannot be edited in game"} end
		if action == "Add" then
			if type(value) ~= "string" or #value == 0 or #value > 200 then return {Success = false, Message = "Invalid entry"} end
			-- Selectors contain only a username/id or supported numeric access selector, never arbitrary labels.
			local valid = value:match("^%d+$") or value:match("^[%w_]+:%d+$") or value:match("^[%w_]+$")
				or value:match("^Group:%d+:%-?%d+$") or value:match("^Group:%d+$")
				or value:match("^Item:%d+$") or value:match("^GamePass:%d+$")
			if not valid then return {Success = false, Message = "Use a username, user ID, or supported access selector"} end
			if not server.TextPolicy.TryPublicEdit(player) then return {Success = false, Message = "Wait 60 seconds between shared text edits"} end
			local record = server.TextPolicy.CreateRecord(value, player, "PublicEdit")
			if not record then return {Success = false, Message = "Text could not be filtered"} end
			table.insert(tab, value)
			server.Core.RegisterTableText(tab, value, record)
			server.Core.DoSave({Type = "TableAdd", Table = path, Value = value, TextRecord = record})
		elseif action == "Remove" then
			if type(value) ~= "string" then return {Success = false, Message = "Invalid entry handle"} end
			local current, index, original = server.Core.ResolveSettingsEntry(player, path, value)
			if not current then return {Success = false, Message = "Entry expired; reopen this table"} end
			table.remove(current, index)
			server.Core.DoSave({Type = "TableRemove", Table = path, Value = original})
		else
			return {Success = false, Message = "Unknown table operation"}
		end
		server.Logs.AddAudit("Script", "Setting", player, {Outcome = "Completed"})
		return {Success = true, Entries = server.Core.GetSettingsTableEntries(player, path)}
	end
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
		Defaults = server.Defaults.Settings;
		Commands = server.Commands;
		logError = env.logError;
		Remote.NewDecrypt = function(str, key, cache) -- Bxor works both ways. May want to make a seperate function tho
			return Remote.NewEncrypt(str, key, cache or Remote.NewDecodeCache)
		end;

		Remote.Init = nil;
		Logs:AddLog("Script", "Remote Module Initialized")
	end;

	local function RunAfterPlugins(data)
		for com in Remote.Commands do
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
		NewEncodeCache = {};
		NewDecodeCache = {};
		RemoteExecutionConfirmed = {};

		TimeUntilKeyDestroyed = 60 * 5; --// How long until a player's key data should be completely removed?

		--// Settings any client/user can grab
		AllowedSettings = {
			Theme = true;
			MobileTheme = true;
			DefaultTheme = true;
			HelpButtonImage = true;
			BatchKey = true;
			AnyPrefix = true;
			DonorCommands = true;
			DonorCapes = true;
			SplitKey = true;
			Prefix = true;
			PlayerPrefix = true;
			SpecialPrefix = true;
			ConsoleKeyCode = true;
			G_API = true;
			G_Access = true;
			G_Access_Perms = true;
			Allowed_API_Calls = true;
			MusicList = true;
		};

		--// Settings that are never sent to the client
		--// These are blacklisted at the datastore level and cannot be updated in-game
		BlockedSettings = {
			Trello_Enabled = true;
			Trello_Primary = true;
			Trello_Secondary = true;
			Trello_Token = true;
			Trello_AppKey = true;

			HideScript = true;  -- Changing in-game will do nothing; Not able to be saved
			DataStore = true;
			DataStoreKey = true;
			DataStoreEnabled = true;
			LocalDatastore = true;

			LoadAdminsFromDS = true;

			Creators = true;
			Permissions = true;

			Prefix = true; -- Changes in-game only happen on current session; Not able to be saved (also breaks console)
			PlayerPrefix = true; -- Completely breaks usage
			SpecialPrefix = true; -- Completely breaks usage
			ConsoleKeyCode = true; -- Has no effect

			G_API = true;
			G_Access = true;
			G_Access_Key = true;
			G_Access_Perms = true;
			Allowed_API_Calls = true;

			WebPanel_ApiKey = true;
			WebPanel_Enabled = true;

			OnStartup = true;
			OnSpawn = true;
			OnJoin = true;

			CustomRanks = true;
		};

		WhitelistedVariable = {
			MusicList = true,
			CodeName = true,
			ChatCreateRobloxCommands = true,
		};

		Returnables = {
			-- Returns safe display rows and opaque handles for an authorized settings editor.
			SettingsTable = function(p, args)
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then return Core.GetSettingsTableEntries(p, args[1]) end
			end;

			-- Completes a table mutation before returning the new projected list to the editor.
			EditSettingsTable = function(p, args)
				return editSettingsTable(p, args[1], args[2], args[3])
			end;
			RateLimits = function(p: Player, args: {[number]: any})
				return Process.RateLimits
			end;

			Test = function(p: Player, args: {[number]: any})
				return "HELLO FROM THE OTHER SIDE :)!"
			end;

			Ping = function(p: Player, args: {[number]: any})
				return "Pong"
			end;

			-- The remote caller is the only valid author and recipient for this local preview.
			Filter = function(p: Player, args: {[number]: any})
				if type(args[1]) == "string" then
					return service.Filter(args[1], p, p)
				end
			end;

			BroadcastFilter = function(p: Player, args: {[number]: any})
				if type(args[1]) == "string" then
					return service.BroadcastFilter(args[1], p)
				end
			end;

			TaskManager = function(p: Player, args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local action = args[1]
					if action == "GetTasks" then
						local tab = {}
						for _, v in service.GetTasks() do
							table.insert(tab, {
								Status = v.Status;
								Name = "Tracked task";
								Index = v.Index;
								Created = v.Created;
								Function = tostring(v.Function);
							})
						end
						return tab
					end
				end
			end;

			ExecutePermission = function(p: Player,args: {[number]: any})
				if typeof(args[1]) == "Instance" and type(args[2]) == "string" then
					return Core.ExecutePermission(args[1], args[2], true)
				end
			end;

			Variable = function(p: Player,args: {[number]: any})
				if Remote.WhitelistedVariable[args[1]] then
					return if args[1] == "MusicList" then Core.ProjectSettingValue(Variables.MusicList, "MusicList") else Variables[args[1]]
				elseif Core.DebugMode then
					print("Blocked attempted index of Variable from Remote")
				end
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
						LocalDatastore = true;

						--Trello_Enabled = true;
						--Trello_PrimaryBoard = true;
						--Trello_SecondaryBoards = true;
						Trello_AppKey = true;
						Trello_Token = true;

						--G_API = true;
						--G_Access = true;
						G_Access_Key = true;
						--G_Access_Perms = true;
						--Allowed_API_Calls = true;

						WebPanel_ApiKey = true;
						WebPanel_Enabled = true;

						OnStartup = true;
						OnSpawn = true;
						OnJoin = true;

						CustomRanks = true; -- Not supported yet
						Ranks = true;
						Commands = true;
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
							ret[set] = Core.ProjectSetting(set)
						end
					end
				elseif type(setting) == "string" then
					if Settings[setting] and (allowed[setting] or level>=Settings.Ranks.Creators.Level) then
						ret = Core.ProjectSetting(setting)
					end
				end

				return ret
			end;

			AllSettings = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local sets = {
						Settings = {};
						Descs = server.Descriptions;
						Order = server.Order;
					}

					local blocked = Remote.BlockedSettings

					for setting in Settings do
						if not blocked[setting] then
							sets.Settings[setting] = Core.ProjectSetting(setting)
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
				if type(args[1]) == "table" then
					if string.len(service.HttpService:JSONEncode(args)) < 4000 then
						local playerData = Core.GetPlayer(p)
						playerData.CustomPlaylist = args[1]
						Core.SavePlayer(p, playerData)
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

			UpdateDonor = function(p: Player, args: {[number]: any})
				local playerData = Core.GetPlayer(p)
				local resp = "OK"

				if Settings.DonorCapes and playerData.isDonor then
					local donor = args[1]
					if type(donor) == "table" and donor.Cape and type(donor.Cape) == "table" then
						playerData.Donor = donor
						if donor.Enabled then
							Functions.Donor(p)
						else
							Functions.UnCape(p)
						end

						Core.SavePlayer(p, playerData)
						resp = "Updated"
					else
						resp = "Error"
					end
				else
					resp = "Error"
				end

				return resp
			end;

			-- Accepts bounded alias maps or strict deletions from legacy maps, then installs native sinks.
			UpdateAliases = function(p: Player, args: {[number]: any})
				local now = os.clock()
				if aliasUpdateTimes[p] and now - aliasUpdateTimes[p] < 1 then
					return {Success = false, Message = "Wait one second between alias changes."}
				end
				aliasUpdateTimes[p] = now
				if type(args[1]) ~= "table" then return {Success = false, Message = "Invalid alias settings."} end
				local data = Core.GetPlayer(p)
				local previous = data.Aliases or {}
				local previousCount = 0
				for _ in previous do previousCount += 1 end
				local aliases, count, commandBarOnly, removalOnly, bounded = {}, 0, false, true, true
				for key, value in args[1] do
					count += 1
					if count > math.max(64, previousCount) or type(key) ~= "string" or type(value) ~= "string" then
						return {Success = false, Message = "Use at most 64 aliases, with names up to 128 characters and commands up to 4096 characters."}
					end
					if count > 64 or #key == 0 or #key > 128 or #value == 0 or #value > 4096 then bounded = false end
					if previous[key] ~= value then removalOnly = false end
					aliases[key] = value
					if not Admin.GetNativeAliasToken(key) then commandBarOnly = true end
				end
				-- Legacy cleanup may retain existing oversized entries, but cannot add or alter them.
				if not bounded and not (removalOnly and count < previousCount) then
					return {Success = false, Message = "Use at most 64 aliases, with names up to 128 characters and commands up to 4096 characters."}
				end
				local unchanged = true
				for key, value in aliases do if previous[key] ~= value then unchanged = false; break end end
				if unchanged then
					for key in previous do if aliases[key] == nil then unchanged = false; break end end
				end
				if not unchanged then data.Aliases = aliases end
				local ok = pcall(Admin.CacheNativeChatCommands, true, unchanged)
				if not ok then
					data.Aliases = previous
					pcall(Admin.CacheNativeChatCommands, true)
					return {Success = false, Message = "Aliases could not be installed. Please try again later."}
				end
				return {Success = true, CommandBarOnly = commandBarOnly or not bounded}
			end;

			-- Returns only the caller's supported UI preferences, excluding moderation and plugin records.
			PlayerData = function(p: Player,args: {[number]: any})
				local data = Core.GetPlayer(p)
				data.isDonor = Admin.CheckDonor(p)
				local donor = if type(data.Donor) == "table" then data.Donor else {}
				local cape = if type(donor.Cape) == "table" then donor.Cape else {}
				local color = cape.Color
				if type(color) == "table" then
					color = {tonumber(color[1]) or 1, tonumber(color[2]) or 1, tonumber(color[3]) or 1}
				elseif type(color) ~= "string" then
					color = "White"
				end
				local result = {
					AdminLevel = Admin.GetLevel(p), isDonor = data.isDonor == true,
					Aliases = {}, Keybinds = {},
					Donor = {Enabled = donor.Enabled == true, Cape = {
						Image = if type(cape.Image) == "string" or type(cape.Image) == "number" then cape.Image else "0",
						Material = if type(cape.Material) == "string" then cape.Material else "Neon",
						Color = color,
					}},
				}
				for _, key in {"Aliases", "Keybinds"} do
					for name, value in if type(data[key]) == "table" then data[key] else {} do
						if type(name) == "string" and type(value) == "string" then result[key][name] = value end
					end
				end
				return result
			end;

			CheckAdmin = function(p: Player,args: {[number]: any})
				return Admin.CheckAdmin(p)
			end;

			SearchCommands = function(p: Player,args: {[number]: any})
				return Admin.SearchCommands(p, args[1] or "all")
			end;

			CheckBackpack = function(p: Player,args: {[number]: any})
				if type(args[1]) == "string" then
					return Anti.CheckBackpack(p, args[1])
				end
			end;

			FormattedCommands = function(p: Player,args: {[number]: any})
				local commands = Admin.SearchCommands(p, args[1] or "all")
				local tab = {}
				for _,v in commands do
					if not v.Hidden and not v.Disabled then
						for a in v.Commands do
							table.insert(tab, Admin.FormatCommand(v,a))
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
						ServerLogs = Logs.ProjectConsole(service.LogService:GetLogHistory());
						ClientLogs = {};
						ScriptLogs = Logs.Project(Logs.Script, "Script");
						AdminLogs = Logs.Project(Logs.Commands, "Commands");
						ErrorLogs = Logs.Project(Logs.Errors, "Errors");
						ChatLogs = {};
						JoinLogs = Logs.Project(Logs.Joins, "Joins");
						Replications = {};
						Exploit = Logs.Project(Logs.Exploit, "Exploit");
					}
				end
			end;

			Terminal = function(p: Player,args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					local message = args[1]
					if type(message) ~= "string" then return {"Invalid terminal command"} end
					local data = {UserCommandOrigin = server.ChatTransport.NewOrigin(p, message)}
					local command = string.match(message, "(.-) ") or message
					local argString = string.match(message, "^.- (.+)") or ""
					local comTable = Remote.Terminal.GetCommand(command)
					if comTable then
						local cArgs = Functions.Split(argString, " ", comTable.Arguments)
						local ran,ret = pcall(comTable.Function,p,cArgs,data)
						if ran then
							return if comTable == Remote.Terminal.Commands.Help then ret else {"Command completed"}
						else
							return {
								"Command failed"
							}
						end
					else
						return {
							"Unknown terminal command"
						}
					end
				end
			end;

			AudioLib = function(p, args)
				local AdminLevel = Admin.GetLevel(p)
				if Commands.Music and Admin.CheckComLevel(AdminLevel, Commands.Music) then
					local audioLib = Functions.AudioLib

					if not Functions.AudioLib then
						local audioLibFolder = service.SoundService:FindFirstChild("ADONIS_AUDIOLIB")
						if not audioLibFolder then
							audioLibFolder = service.New("Folder")
							audioLibFolder.Name = "ADONIS_AUDIOLIB"
							audioLibFolder.Parent = service.SoundService
						end
						audioLib = require(server.Shared.AudioLib).new(service.UnWrap(audioLibFolder))
						Functions.AudioLib = audioLib
					end

					if type(args[1]) == "table" then
						args = service.UnWrap(args[1])
					else
						return
					end

					if args[1] == "index" then
						return audioLib[args[2]]
					elseif args[1] == "newindex" then
						audioLib[args[2]] = args[3]
					elseif args[1] == "call" then
						return audioLib[args[2]](audioLib, table.unpack(args, 3))
					end
				end
			end;

			CommandListData = function(p)
				local playerAliases = table.clone(Core.GetPlayer(p).Aliases or {})

				if Settings.LegacyCommandList then
					local tab = {}

					for _, cmd in Admin.SearchCommands(p, "all") do
						local cmdAliases = table.create(#cmd.Commands)

						if cmd.Hidden or cmd.Disabled then
							continue
						end

						for _, alias in cmd.Commands do
							if #cmdAliases >= 6 and (#cmd.Commands - #cmdAliases) ~= 0 then
								table.insert(cmdAliases, `and {#cmd.Commands - #cmdAliases} more...`)
								break
							end

							table.insert(cmdAliases, alias)
						end

						table.remove(cmdAliases, 1)

						local permissionDesc = Admin.FormatCommandAdminLevel(cmd)
						table.insert(tab, {
							Text = Admin.FormatCommand(cmd),
							Desc = `[{permissionDesc}] {if #cmdAliases >= 1 then `\nAliases: {table.concat(cmdAliases, ", ")}` else ""} \n\n{cmd.Description or "(No description provided)"}`,
							Filter = permissionDesc
						})
					end

					for alias, command in playerAliases do
						table.insert(tab, {
							Text = alias,
							Desc = `[User Alias] {command}`,
							Filter = command
						})
					end

					table.sort(tab, function(a, b) return a.Text < b.Text end)

					return {
						Legacy = true,
						Table = tab,
						PlayerPrefix = Settings.PlayerPrefix
					}
				end

				local ranks = {}
				local commands = {}

				local pDat = {
					Player = p;
					Level = Admin.GetLevel(p);
					isDonor = Admin.CheckDonor(p);
				}

				local maxDisplayLevel = pDat.Level

				for name, data in Settings.Ranks do
					local purchasables = {}
					for _, user in data.Users do
						if typeof(user) ~= "string" then continue end

						local id, idType

						if string.sub(user, 1, 5) == "Item:" then
							id = tonumber(string.sub(user, 6))
							idType = Enum.InfoType.Asset
						elseif string.sub(user, 1, 9) == "GamePass:" then
							id = tonumber(string.sub(user, 10))
							idType = Enum.InfoType.GamePass
						elseif string.sub(user, 1, 13) == "Subscription:" then
							id = string.sub(user, 14)
							table.insert(purchasables, {
								Id = id;
								Type = Enum.InfoType.Subscription;
							})
							continue
						else
							continue
						end

						local info = service.GetProductInfo(id, idType)
						if not info or not info.Created then continue end
						if not info.IsForSale then continue end
						--if idType == Enum.InfoType.GamePass and (not info.CanBeSoldInThisGame) then continue end

						table.insert(purchasables, {
							Id = id;
							Type = idType;
						})
					end

					local displayRank = Core.ProjectRank(name)
					table.insert(ranks, {
						Rank = displayRank.Name;
						Level = displayRank.Level;
						Purchasables = purchasables;
					})

					if #purchasables > 0 then
						maxDisplayLevel = math.max(data.Level, maxDisplayLevel)
					end
				end

				for i = #ranks, 1, -1 do
					if ranks[i].Level > maxDisplayLevel then
						table.remove(ranks, i)
					end
				end

				table.insert(ranks, {
					Rank = "Players";
					Level = 0;
					Purchasables = {};
				})

				if Settings.DonorCommands then
					table.insert(ranks, {
						Rank = "Donors";
						Level = "Donors";
						Purchasables = {};
					})
				end

				for key, command in Commands do
					local hasPerm, err = Admin.CheckPermission(pDat, command, true)
					if err then continue end

					if hasPerm == true or (hasPerm == false and ((Settings.DonorCommands and command.Donors) or Admin.CheckComLevel(maxDisplayLevel, command.AdminLevel))) then
						local newCommand = table.clone(command)
						newCommand.HasPermission = hasPerm
						commands[key] = newCommand
					end
				end

				return {
					PlayerData = pDat,
					Ranks = ranks,
					Commands = commands,
					PlayerAliases = playerAliases
				}
			end;
		};

		Terminal = {
			Data = {};
			Format = function(msg, data) (data or {}).Text = msg end;
			Output = function(tab, msg, mata) table.insert(tab, Remote.Terminal.Format(msg, mata)) end;
			GetCommand = function(cmd) for i, com in Remote.Terminal.Commands do if com.Command:lower() == cmd:lower() then return com end end end;
			-- Terminal output may originate in arbitrary evaluated code and has no verified text author.
			LiveOutput = function(p, data, outputType) Remote.FireEvent(p, "TerminalLive", {Data = "[Output unavailable: source cannot be verified]"; Type = "Terminal";}) end;
			Commands = {
				Help = {
					Usage = "help";
					Command = "help";
					Arguments = 0;
					Description = "Shows a list of available commands and their usage";
					Function = function(p,args,data)
						local output = {}
						for i,v in Remote.Terminal.Commands do
							table.insert(output, `{v.Usage}{string.rep(" ",30-string.len(tostring(v.Usage)))}`)
							table.insert(output, `- {v.Description}`)
						end
						return output
					end;
				};

				Message = {
					Usage = "message <message>";
					Command = "message";
					Arguments = 1;
					Description = "Sends a message in the Roblox chat";
					-- Only literal input from the actual terminal caller can authorize a channel send.
					Function = function(p, args, data)
						local input = server.ChatTransport.CommandInput(p, {UserText = {Args = {1}}}, args, data)
						server.ChatTransport.SubmitCommand(p, service.GetPlayers(), args[1], input, "Notification", "ChatMessage")
					end
				};

				Test = {
					Usage = "test <return>";
					Command = "test";
					Arguments = 1;
					Description = "Used to test the connection to the server and it's ability to return data";
					Function = function(p,args,data)
						Remote.Terminal.LiveOutput(p,`Return Test: {args[1]}`)
					end
				};

				Loadstring = {
					Usage = "loadstring <string>";
					Command = "loadstring";
					Arguments = 1;
					Description = "Loads and runs the given lua string";
					Function = function(p,args,data)
						local oError = error
						local newenv = GetEnv(getfenv(), {
							print = function(...) local args = table.pack(...) for i = 1, args.n do args[i] = tostring(args[i]) end Remote.Terminal.LiveOutput(p, `PRINT: {table.concat(args, " ")}`) end;
							warn = function(...) local args = table.pack(...) for i = 1, args.n do args[i] = tostring(args[i]) end Remote.Terminal.LiveOutput(p, `WARN: {table.concat(args, " ")}`) end;
							error = function(reason, level)
								if level ~= nil and type(level) ~= "number" then
									oError(string.format("bad argument #2 to 'error' (number expected, got %s)", type(level)), 2)
								end

								Remote.Terminal.LiveOutput(p, `LUA_DEMAND_ERROR: {reason}`)
								oError("Adonis terminal error", (level or 1) + 1)
							end;
						})

						if not Remote.RemoteExecutionConfirmed[tostring(p.UserId)] then
							local ans = Remote.GetGui(p, "YesNoPrompt", {
								Icon = server.MatIcons.Warning;
								Question = "Are you sure you want to load this script into the server env?";
								Title = "Adonis DebugLoadstring";
								Delay = 3;
							})

							if ans == "Yes" then
								Remote.RemoteExecutionConfirmed[tostring(p.UserId)] = true
							else
								return
							end
						end

						local func, err = Core.Loadstring(args[1], newenv)
						if func then
							xpcall(func, function(reason)
								Remote.Terminal.LiveOutput(p,`LUA_ERROR: {string.match(reason, ":(.*)") or reason}`)
							end)
						else
							Remote.Terminal.LiveOutput(p,`SYNTAX_ERROR: {string.match(err, ":(.*)") or err}`)
						end
					end
				};

				Kick = {
					Usage = "kick <player> <reason>";
					Command = "kick";
					Arguments = 2;
					Description = "Disconnects the specified player from the server";
					Function = function(p, args, data)
						local plrs = service.GetPlayers(p, args[1], {UseFakePlayer = true})
						if #plrs > 0 then
							local ret = {}
							for _,v in plrs do
								v:Kick((args[2] and server.TextPolicy.FilterForUser(args[2], p, v)) or "Disconnected by server")
								table.insert(ret, `Disconnect {service.FormatPlayer(v)} from the server`)
							end
							return ret
						else
							return {`No players matching '{args[1]}' found`}
						end
					end
				};

				Kill = {
					Usage = "kill <player>";
					Command = "kill";
					Arguments = 1;
					Description = "Calls :BreakJoints() on the target player's character";
					Function = function(p,args,data)
						local plrs = service.GetPlayers(p, args[1], {UseFakePlayer = true})
						if #plrs > 0 then
							for _, v in plrs do
								local ret = {}
								local char = v.Character
								if char and char.ClassName == "Model" then
									char:BreakJoints()
									table.insert(ret, `Killed {service.FormatPlayer(v)}`)
								else
									table.insert(ret, `{service.FormatPlayer(v)} has no character or it's not a model`)
								end
								return ret
							end
						else
							return {`No players matching '{args[1]}' found`}
						end
					end
				};

				Respawn = {
					Usage = "respawn <player>";
					Command = "respawn";
					Arguments = 1;
					Description = "Calls :LoadCharacter() on the target player";
					Function = function(p,args,data)
						local plrs = service.GetPlayers(p, args[1], {UseFakePlayer = true})
						if #plrs > 0 then
							local ret = {}
							for _, v in plrs do
								v:LoadCharacter()
								table.insert(ret, `Respawned {service.FormatPlayer(v)}`)
							end
						else
							return {`No players matching '{args[1]}' found`}
						end
					end
				};

				Shutdown = {
					Usage = "shutdown <reason>";
					Command = "shutdown";
					Arguments = 1;
					Description = "Disconnects all players from the server and prevents rejoining";
					-- Reuses one broadcast-safe snapshot for current and later arrivals in this server.
					Function = function(p,args,data)
						local record = args[1] and server.TextPolicy.CreateRecord(args[1], p, "Moderation")
						local reason = (record and server.TextPolicy.GetRecordText(record)) or "Server shut down"
						service.PlayerAdded:Connect(function(player)
							player:Kick(reason)
						end)

						for _, v in service.Players:GetPlayers() do
							v:Kick(reason)
						end
					end
				};

				Panic = {
					Usage = "panic <reason>";
					Command = "panic";
					Arguments = 1;
					Description = "Enables Adonis panic mode";
					Function = function(p, args, data)
						local record = args[1] and server.TextPolicy.CreateRecord(args[1], p, "Moderation")
						server.Panic((record and server.TextPolicy.GetRecordText(record)) or "Panic mode requested by an administrator")
					end
				};
			};
		};

		SessionHandlers = {

		};

		Commands = {
			GetReturn = function(p: Player, args: {[number]: any})
				local com = args[1]
				local key = args[2]
				local parms = table.pack(table.unpack(args, 3))
				local retfunc = Remote.Returnables[com]
				local retable = retfunc and table.pack(pcall(retfunc, p, parms)) or {}
				if retable[1] ~= true then
					logError(p, retable[2])
					Remote.Send(p, "GiveReturn", key, "__ADONIS_RETURN_ERROR", retable[2])
				else
					Remote.Send(p, "GiveReturn", key, table.unpack(retable, 2, retable.n))
				end
			end;

			GiveReturn = function(p: Player,args: {[number]: any})
				if Remote.PendingReturns[args[1]] then
					Remote.PendingReturns[args[1]] = nil
					service.Events[args[1]]:Fire(table.unpack(args, 2))
				end
			end;

			ClientCheck = function(p: Player, args: {[number]: any})
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
				local session = type(sessionKey) == "string" and Remote.GetSession(sessionKey);

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
								Functions.Notification("Error", "Cannot delete object.", {p}, 2, "MatIcon://Error")
							end
						end
					end
				end
			end;

			PlayerEvent = function(p: Player, args: {[number]: any})
				if service.GetEvent(tostring(args[1]) .. p.UserId) then
					service.Events[tostring(args[1]) .. p.UserId]:Fire(unpack(args,2))
				end
			end;

			-- Legacy editor events use the same validated path as the request/response editor.
			SaveTableAdd = function(p: Player, args: {[number]: any})
				local result = editSettingsTable(p, "Add", args[1], args[2])
				if not result.Success then Functions.Hint(result.Message, {p}) end
			end;

			-- Removal accepts only an entry handle previously issued to the current viewer.
			SaveTableRemove = function(p: Player, args: {[number]: any})
				local result = editSettingsTable(p, "Remove", args[1], args[2])
				if not result.Success then Functions.Hint(result.Message, {p}) end
			end;

			-- Persists a validated primitive and its text provenance under the existing settings key.
			SaveSetSetting = function(p: Player, args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then changeSetting(p, args[1], args[2], true) end
			end;

			ClearSavedSettings = function(p: Player, args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then
					Core.DoSave({Type = "ClearSettings"})
					Functions.Hint("Cleared saved settings", {p})
				end
			end;

			-- Applies the same publication policy to settings that last only for this server session.
			SetSetting = function(p: Player, args: {[number]: any})
				if Admin.GetLevel(p) >= Settings.Ranks.Creators.Level then changeSetting(p, args[1], args[2], false) end
			end;

			Detected = function(p: Player, args: {[number]: any})
				if type(args[1]) == "string" then
					Anti.Detected(p, args[1], args[2])
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
					task.defer(Process.FinishLoading, p)
				else
					warn(`[CLI-199524] ClientLoaded fired when not ready for {p}`)
					Logs:AddLog("Script", string.format("%s fired ClientLoaded too early", tostring(p)));
					--p:Kick("Loading error [ClientLoaded Failed]")
				end
			end;

			LogError = function(p: Player, args: {[number]: any})
				if type(args[1]) == "string" then
					logError(p, string.sub(args[1], 1, 200))
				end
			end;

			Test = function(p: Player,args: {[number]: any})
				print("Client test event received")
			end;

			-- Processes explicit submissions; only server dispatch supplies native-chat provenance.
			ProcessCommand = function(p: Player, args: {[number]: any}, fromNativeChat: boolean?)
				if Process.RateLimit(p, "Command") and type(args[1]) == "string" then
					Process.Command(p, args[1], {
						Check = true,
						Chat = fromNativeChat == true,
						UserCommandOrigin = server.ChatTransport.NewOrigin(p, args[1]),
					})
				elseif Process.RateLimit(p, "RateLog") then
					Anti.Detected(p, "Log", string.format("Running commands too quickly (>Rate: %s/sec)", 1/Process.RateLimits.Command));
					warn(string.format("%s is running commands too quickly (>Rate: %s/sec)", p.Name, 1/Process.RateLimits.Command));
				end
			end;

			ProcessChat = function(p: Player, args: {[number]: any})
				-- Modern commands are intercepted by native Triggered before any public delivery.
				if service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then return end
				if type(args[1]) == "string" then
					Process.Chat(p, args[1])
				end
			end;

			-- Legacy reply tickets never authorize relaying text outside TextChannels.
			PrivateMessage = function(p: Player)
				Remote.MakeGui(p, "Output", {Message = "This reply window has expired. Open a new conversation to reply."})
			end;

			SaveScript = function(p: Player, args: {})
				local se = Variables.ScriptEditor[tostring(p.UserId)]
				-- Ignore the request
				if not se then
					return
				end
				local Name = args[1]["Name"]
				local Variable = se[Name]

				Variable.Script = args[1]["Text"]
			end,
			-- Executes an authorized personal script draft and returns only fixed error classifications.
			RunScript = function(p: Player, args: {})
				local adminLevel = Admin.GetLevel(p)

				local command = Commands.ScriptEditor
				-- This is redundant because the only way to gain an entry in Variables.ScriptEditor is to have the command run on yourself
				-- However, better safe than sorry!
				if command and Admin.CheckComLevel(adminLevel, command.AdminLevel) then
					local se = Variables.ScriptEditor[tostring(p.UserId)]
					-- Ignore the request
					if not se then
						return
					end
					local Name = args[1][1]
					local Variable = se[Name]

					local oError = error
					local newenv = GetEnv(getfenv(), {
						print = function(...) local args = table.pack(...) for i = 1, args.n do args[i] = tostring(args[i]) end Remote.Terminal.LiveOutput(p, `PRINT: {table.concat(args, " ")}`) end;
						warn = function(...) local args = table.pack(...) for i = 1, args.n do args[i] = tostring(args[i]) end Remote.Terminal.LiveOutput(p, `WARN: {table.concat(args, " ")}`) end;
						error = function(reason, level)
							if level ~= nil and type(level) ~= "number" then
								oError(string.format("bad argument #2 to 'error' (number expected, got %s)", type(level)), 2)
							end

							Remote.MakeGui(p, "Output", {Title = 'LUA_DEMAND_ERROR'; Message = "Script failed; details are unavailable."})
							oError("Adonis ScriptEditor error; details are unavailable.", (level or 1) + 1)
						end;
					})

					-- TODO: Maybe make it not work with the server Env?
					service.TrackTask(`Thread: ScriptEditor: {p.UserId}`, function()
						local func = Core.Loadstring(Variable["Script"], newenv)
						if func then
							xpcall(func, function()
								Remote.MakeGui(p, "Output", {Title = "LUA_ERROR"; Message = "Script failed; details are unavailable."})
							end)
						else
							Remote.MakeGui(p, "Output", {Title = "SYNTAX_ERROR"; Message = "Script syntax is invalid; details are unavailable."})
						end
					end)
				end
			end,

			PromptBulkPurchase = function(p: Player, args: {{number}})
				local ids = args[1]
				local lineItems = {}
				for _, id in ids do
					table.insert(lineItems, {
						Type = Enum.MarketplaceProductType.AvatarAsset,
						Id = tostring(id)
					})
				end
				service.MarketplaceService:PromptBulkPurchase(p, lineItems, {})
			end;

			BulkPurchaseFinished = function(p: Player, args: {[number]: any})
				Admin.ClearDonorCheckCache(p)
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
				SessionKey = service.HttpService:GenerateGUID(false);
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
						for p in self.Users do
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
						for t,event in self.Events do
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
			assert(p and p:IsA("Player"), `Remote.Fire: {p.Name} is not a valid Player`)
			local keys = Remote.Clients[tostring(p.UserId)]
			local RemoteEvent = Core.RemoteEvent
			if RemoteEvent and RemoteEvent.Object then
				keys.Sent += 1
				pcall(RemoteEvent.Object.FireClient, RemoteEvent.Object, p, { Mode = "Fire", Sent = 0 }, ...)
			end
		end;

		Send = function(p: Player,com: string,...)
			assert(p and p:IsA("Player"), `Remote.Send: {p.Name} is not a valid Player`)
			local keys = Remote.Clients[tostring(p.UserId)]
			if keys and keys.RemoteReady == true then
				Remote.Fire(p, Remote.NewEncrypt(com, keys.Key, keys.Cache), ...)
			end
		end;

		GetFire = function(p: Player, ...)
			local keys = Remote.Clients[tostring(p.UserId)]
			local RemoteEvent = Core.RemoteEvent
			if RemoteEvent and RemoteEvent.Function then
				keys.Sent += 1
				local ran, ret = pcall(RemoteEvent.Function.InvokeClient, RemoteEvent.Function, p, { Mode = "Get", Sent = 0 }, ...)
				if ran then
					return ret
				end
			end
		end;

		Get = function(p: Player, com: string, ...)
			local keys = Remote.Clients[tostring(p.UserId)]
			if keys and keys.RemoteReady == true then
				local ret = Remote.GetFire(p, Remote.NewEncrypt(com, keys.Key, keys.Cache), ...)
				if type(ret) == "table" then
					return unpack(ret)
				else
					return ret
				end
			end
		end;

		OldGet = function(p: Player, com: string, ...) -- TODO: Add oldget (both on client and server) to backwards compatibility plugin
			local keys = Remote.Clients[tostring(p.UserId)]

			if keys and keys.RemoteReady == true then
				local returns, finished
				local key = service.HttpService:GenerateGUID(false)
				local Yield = service.Signal.new();
				local event = service.Events[key]:Connect(function(...) print("WE ARE GETTING A RETURN!") finished = true returns = {...} Yield:Fire() end)

				Remote.PendingReturns[key] = true
				Remote.Send(p, "GetReturn", com, key, ...)

				print("GETTING RETURN")
				if not finished and not returns and p.Parent then
					local pEvent = service.Players.PlayerRemoving:Connect(function(plr) if plr == p then event:Fire() end end)
					task.delay(600, function() if not finished then event:Fire() end end)
					print(string.format("WAITING FOR RETURN %s", tostring(returns)))
					Yield:Wait()
					Yield:Destroy()

					print(string.format("WE GOT IT! %s", tostring(returns)))
					pEvent:Disconnect()
					pEvent = nil
				end

				print("GOT RETURN")
				event:Disconnect()
				event = nil

				if returns then
					if returns[1] == "__ADONIS_RETURN_ERROR" then
						error(returns[2])
					else
						return table.unpack(returns)
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
				local continueNext = true;

				if data.Player and data.Player.Parent == service.Players then
					continueNext = false;
				else
					local Player = service.Players:GetPlayerByUserId(key)
					if Player then
						data.Player = Player
						continueNext = false
					end
				end

				if continueNext and (data.LastUpdate and os.time() - data.LastUpdate > Remote.TimeUntilKeyDestroyed) then
					Remote.Clients[key] = nil;
					--print(`Client key removed for UserId {key}`)
					Logs:AddLog("Script", `Client key removed for UserId {key}`)
				end
			end

			return;
		end;

		Ping = function(p: Player)
			return Remote.Get(p,"Ping")
		end;

		MakeGui = function(p: Player, GUI: string, data: {[any]: any}, themeData: {[string]: any})
			if not p then return end
			local theme = {Desktop = Core.ProjectSetting("Theme"); Mobile = Core.ProjectSetting("MobileTheme")}
			if themeData then for ind,dat in themeData do theme[ind] = dat end end
			Remote.Send(p,"UI",GUI,theme,data or {})
		end;

		MakeGuiGet = function(p: Player, GUI: string, data: {[any]: any}, themeData: {[string]: any})
			if not p then return nil end
			local theme = {Desktop = Core.ProjectSetting("Theme"); Mobile = Core.ProjectSetting("MobileTheme")}
			if themeData then for ind,dat in themeData do theme[ind] = dat end end
			return Remote.Get(p,"UI",GUI,theme,data or {})
		end;

		GetGui = function(p: Player, GUI: string, data: {[any]: any}, themeData: {[string]: any})
			return Remote.MakeGuiGet(p,GUI,data,themeData)
		end;

		RemoveGui = function(p: Player, name: string | boolean | Instance, ignore: string)
			if not p then return end
			Remote.Send(p,"RemoveUI",name,ignore)
		end;

		RefreshGui = function(p: Player, name: string | boolean | Instance, ignore: string, data: {[any]: any}, themeData: {[string]: any})
			if not p then return end
			local theme = {Desktop = Core.ProjectSetting("Theme"); Mobile = Core.ProjectSetting("MobileTheme")}
			if themeData then for ind,dat in themeData do theme[ind] = dat end end
			Remote.Send(p,"RefreshUI",name,ignore,themeData or theme,data or {})
		end;

		NewParticle = function(p: Player, target: Instance, class: string, properties: { [string]: any })
			Remote.Send(p, "Function", "NewParticle", target, class, properties)
		end;

		RemoveParticle = function(p: Player, target: Instance, name: string)
			Remote.Send(p, "Function", "RemoveParticle", target, name)
		end;

		NewLocal = function(p: Player, class: string, props: { [string]: any }, parent: string?)
			Remote.Send(p, "Function", "NewLocal", class, props, parent)
		end;

		MakeLocal = function(p: Player, object: Instance, parent: string?, clone: boolean?)
			object.Parent = p:FindFirstChildOfClass("PlayerGui") or p
			task.wait(0.5)
			Remote.Send(p, "Function", "MakeLocal", object, parent, clone)
		end;

		MoveLocal = function(p: Player, object: string, parent: string?, newParent: Instance)
			Remote.Send(p, "Function", "MoveLocal", object, false, newParent)
		end;

		RemoveLocal = function(p: Player, object: string, parent: string?, match: boolean?)
			Remote.Send(p, "Function", "RemoveLocal", object, parent, match)
		end;

		SetLighting = function(p: Player, prop: string, value: any)
			Remote.Send(p, "Function", "SetLighting", prop, value)
		end;

		SetAtmosphere = function(p: Player, prop: string, value: any)
			Remote.Send(p, "Function", "SetAtmosphere", prop, value)
		end;

		FireEvent = function(p: Player, ...)
			Remote.Send(p, "FireEvent", ...)
		end;

		NewPlayerEvent = function(p: Player,type: string,func: (...any) -> (...any))
			return service.Events[`{type}{p.UserId}`]:Connect(func)
		end;

		StartLoop = function(p: Player, name: string, delay: number | string, funcCode: string)
			Remote.Send(p, "StartLoop", name, delay, Core.ByteCode(funcCode))
		end;

		StopLoop = function(p: Player, name: string)
			Remote.Send(p, "StopLoop", name)
		end;

		PlayAudio = function(p: Player, audioId: number, volume: number?, playbackSpeed: number?, looped: boolean?)
			Remote.Send(p, "Function", "PlayAudio", audioId, volume, playbackSpeed, looped)
		end;

		StopAudio = function(p: Player, audioId: number)
			Remote.Send(p, "Function", "StopAudio", audioId)
		end;

		FadeAudio = function(p: Player, audioId: number, inVol: number?, playbackSpeed: number?, looped: boolean?, incWait: number?)
			Remote.Send(p, "Function", "FadeAudio", audioId, inVol, playbackSpeed, looped, incWait)
		end;

		StopAllAudio = function(p: Player)
			Remote.Send(p, "Function", "KillAllLocalAudio")
		end;

		LoadCode = function(p: Player, code: string, getResult: boolean)
			if getResult then
				return Remote.Get(p, "LoadCode", Core.Bytecode(code))
			else
				Remote.Send(p, "LoadCode", Core.Bytecode(code))
			end
		end;

		Encrypt = function(str: string, key: string, cache: {[string]: (buffer|{[string]: string})}?)
			cache = cache or Remote.EncodeCache or {}
			local keyCache = cache[key] or {}

			if not key or not str then
				return str
			elseif keyCache[str] then
				return keyCache[str]
			else
				local writeu8, readu8 = buffer.writeu8, buffer.readu8
				local rawStr, rawKey = buffer.fromstring(str), keyCache[1] or buffer.fromstring(key)
				local keyLen = #key

				for i = 0, #str - 1 do
					writeu8(rawStr, i, (readu8(rawStr, i) + readu8(rawKey, (i + 1) % keyLen)) % 126 + 1)
				end

				cache[key] = keyCache
				keyCache[str], keyCache[1] = buffer.tostring(rawStr), rawKey
				return keyCache[str]
			end
		end;

		Decrypt = function(str: string, key: string, cache: {[string]: (buffer|{[string]: string})}?)
			cache = cache or Remote.DecodeCache or {}
			local keyCache = cache[key] or {}

			if not key or not str then
				return str
			elseif keyCache[str] then
				return keyCache[str]
			else
				local writeu8, readu8 = buffer.writeu8, buffer.readu8
				local rawStr, rawKey = buffer.fromstring(str), keyCache[1] or buffer.fromstring(key)
				local keyLen = #key

				for i = 0, #str - 1 do
					writeu8(rawStr, i, (readu8(rawStr, i) - readu8(rawKey, (i + 1) % keyLen)) % 126 - 1)
				end

				cache[key] = keyCache
				keyCache[str], keyCache[1] = buffer.tostring(rawStr), rawKey
				return keyCache[str]
			end
		end;

		NewEncrypt = function(str: string, key: string, cache: {[string]: (buffer|{[string]: string})}?)
			cache = cache or Remote.NewEncodeCache or {}
			local keyCache = cache[key] or {}

			if not key or not str then
				return str
			elseif keyCache[str] then
				return keyCache[str]
			else
				local writeu8, readu8, bxor = buffer.writeu8, buffer.readu8, bit32.bxor
				local rawStr, rawKey = buffer.fromstring(str), keyCache[1] or buffer.fromstring(key)
				local keyLen = #key

				for i = 0, #str - 1 do
					writeu8(rawStr, i, bxor(readu8(rawStr, i), readu8(rawKey, i % keyLen)))
				end

				cache[key] = keyCache
				keyCache[str], keyCache[1] = buffer.tostring(rawStr), rawKey
				return keyCache[str]
			end
		end;
	};
end
