--[[

	Currently in beta.

	Author: Cald_fan
	Contributors: joritochip (Requests, handling custom commands, command overrides)

]]

return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local Encode = Functions.Base64Encode
	local Decode = Functions.Base64Decode

	local HttpService = service.HttpService

	Variables.WebPanel_Initiated = false

	--[[
		settings.WebPanel_Enabled = true;
		settings.WebPanel_ApiKey = "";
	]]

	local WebPanel = HTTP.WebPanel

	local ownerId = game.CreatorType == Enum.CreatorType.User and game.CreatorId or service.GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id

	local FoundCustomCommands = {}
	local CachedAliases = {}
	local CachedDefaultLevels = {}

	local OverrideQueue = {}

	local fakePlayer = service.Wrap(service.New("Folder"))
	for i,v in pairs({
		Name = "Server";
		ToString = "Server";
		ClassName = "Player";
		AccountAge = 0;
		CharacterAppearanceId = -1;
		UserId = ownerId;
		userId = ownerId;
		Parent = service.Players;
		Character = Instance.new("Model");
		Backpack = Instance.new("Folder");
		PlayerGui = Instance.new("Folder");
		PlayerScripts = Instance.new("Folder");
		Kick = function() fakePlayer:Destroy() fakePlayer:SetSpecial("Parent", nil) end;
		IsA = function(ignore, arg) if arg == "Player" then return true end end;
	}) do fakePlayer:SetSpecial(i, v) end

	local function CopyCommand(tbl)
		local ret = {}
		if tbl and type(tbl) == "table" then
			for i,v in pairs(tbl) do
				if typeof(v) == "string" or typeof(v) == "number" or typeof(v) == "boolean" then
					ret[i] = v
				elseif typeof(v) == "table" then
					ret[i] = CopyCommand(v)
				end
			end
		end
		return ret
	end

	local function GetCustomCommands()
		local ret = FoundCustomCommands
		FoundCustomCommands = {} -- Clear queue for next request
		return ret
	end

	local function WebPanelCleanUp(notBindToClose)
		if Variables.WebPanel_Initiated then
			pcall(HttpService.RequestAsync, HttpService, {
				Url = "https://robloxconnection.adonis.dev/remove";
				Method = "DELETE";
				Headers = {
					["api-key"] = Settings.WebPanel_ApiKey,
					["Content-Type"] = "application/json"
				};
				Body = HttpService:JSONEncode({
					["JobId"] = game.JobId
				})
			});
		end

		if not notBindToClose then
			wait(4)
		end
	end

	local delta, frames = 0, 0
	service.RunService.Stepped:Connect(function(time, step)
		delta += step
		frames += 1
		if delta > 1 then
			delta, frames = 0, 0
		end
	end)

	local function GetServerStats()
		local stats = {}

		local admins = {}
		for _, v in pairs(service.NetworkServer:GetChildren()) do
			if v and v:GetPlayer() and Admin.CheckAdmin(v:GetPlayer(), false) then
				table.insert(admins, v:GetPlayer().Name)
			end
		end

		stats.PlayerCount = #game.Players:GetPlayers() == 0 and #service.NetworkServer:GetChildren() or #game.Players:GetPlayers()
		stats.MaxPlayers = game.Players.MaxPlayers
		stats.ServerStartTime = server.ServerStartTime
		stats.ServerSpeed = math.min(frames/60, 1)*100
		stats.Admins = admins
		stats.JobId = game.JobId
		stats.PrivateServer = game.PrivateServerOwnerId > 0

		return stats
	end

	local function ResetCommandAdminLevel(index, command)
		local metatbl = getmetatable(command)
		if metatbl and metatbl.WebPanel then
			setmetatable(command, nil)
			if string.match(command.AdminLevel, "^WebPanel.+") then
				command.AdminLevel = CachedDefaultLevels[index] or "Creators" -- in case something borks, fall back to Creators
			end
		end
	end

	local function ResetCommandAliases(index, command)
		if CachedAliases[index] then
			local aliases = rawget(command, "Commands")
			local newaliases = {}

			for _, alias in pairs(aliases) do
				Admin.CommandCache[string.lower(command.Prefix..alias)] = nil
			end

			for _, alias in ipairs(CachedAliases[index]) do
				table.insert(newaliases, alias)
				Admin.CommandCache[string.lower(command.Prefix..alias)] = index
			end

			command.Commands = newaliases
		end
	end

	local function ResetCommands()
		for index, command in pairs(Commands) do
			if type(command) == "table" then
				if command.Disabled == "WebPanel" then
					command.Disabled = nil
				end

				ResetCommandAdminLevel(index, command)
				ResetCommandAliases(index, command)
			end
		end
	end

	local function UpdateCommand(index, command, v)
		command.Disabled = v.disabled and "WebPanel" or nil

		local aliases = rawget(command, "Commands")
		local newaliases = {}

		-- Remove old aliases from command cache
		for _, alias in pairs(aliases) do
			if command.Prefix then
				Admin.CommandCache[string.lower(command.Prefix..alias)] = nil
			end
		end

		if CachedAliases[index] then
			for _, alias in ipairs(CachedAliases[index]) do
				if not table.find(v.aliases, "-"..alias) then
					table.insert(newaliases, alias)

					if command.Prefix then
						Admin.CommandCache[string.lower(command.Prefix..alias)] = index
					end
				end
			end
		end
		for _, alias in ipairs(v.aliases) do
			if string.sub(alias, 1, 1) ~= "-" then
				table.insert(newaliases, alias)
				Admin.CommandCache[string.lower(command.Prefix..alias)] = index
			end
		end

		command.Commands = newaliases

		if v.level ~= "Default" then
			rawset(command, "AdminLevel", "WebPanel"..v.level)
			setmetatable(command, {
				WebPanel = true,
				__index = function(tbl, index)
					local rawlevel = rawget(command, "AdminLevel")

					if rawlevel and index == "AdminLevel" and string.match(rawlevel, "^WebPanel.+") then
						return {AdminLevel = string.sub(rawlevel, 9)}
					end
				end,
			})
		else
			ResetCommandAdminLevel(index, command)
		end
	end

	local function UpdateCommands(data)
		local didrun = false
		for i,v in pairs(data.CommandOverrides) do
			didrun = true

			local index, command = Admin.GetCommand(Settings.Prefix..i)
			if not index or not command then index,command = Admin.GetCommand(Settings.PlayerPrefix..i) end

			if index and command then
				UpdateCommand(index, command, v)
			else
				-- The command being overridden was not found, add it to a queue for later
				table.insert(OverrideQueue, {
					name = i,
					data = v
				})
			end
		end
		if not didrun then
			ResetCommands()
		end
	end

	local function UpdateSettings(data)
		WebPanel.Bans = data.Levels.Banlist or {};
		WebPanel.Creators = data.Levels.Creators or {};
		WebPanel.Admins = data.Levels.Admins or {};
		WebPanel.Moderators = data.Levels.Moderators or {};
		WebPanel.HeadAdmins = data.Levels.Owners or {};
		WebPanel.Mutes = data.Levels.Mutelist or {};
		WebPanel.Blacklist = data.Levels.Blacklist or {};
		WebPanel.Whitelist = data.Levels.Whitelist or {};
		WebPanel.CustomRanks = data.Levels.CustomRanks or {};

		Settings.Ranks["[WebPanel] Creators"] = {
			Level = 900;
			Users = WebPanel.Creators;
		}

		Settings.Ranks["[WebPanel] HeadAdmins"] = {
			Level = 300;
			Users = WebPanel.HeadAdmins;
		}

		Settings.Ranks["[WebPanel] Admins"] = {
			Level = 200;
			Users = WebPanel.Admins;
		}

		Settings.Ranks["[WebPanel] Moderators"] = {
			Level = 100;
			Users = WebPanel.Moderators;
		}

		if Variables.MusicList then
			for i = #Variables.MusicList, 1, -1 do -- Iterating backwards to prevent wonky behavior with table.remove
				local v = Variables.MusicList[i]

				if v and v.WebPanel then
					table.remove(Variables.MusicList, i)
				end
			end

			for ind, music in pairs(data.Levels.Musiclist or {}) do
				if string.match(music, '^(.*):(.*)') then
					local a,b = string.match(music, '^(.*):(.*)')

					if Variables.MusicList then
						table.insert(Variables.MusicList, {
							Name = a,
							ID = tonumber(b),
							WebPanel=true
						})
					end
				end
			end
		end
	end

	do -- Create a cache of the default admin levels for all commands
		for name, command in pairs(Commands) do
			if type(command) == "table" then
				CachedDefaultLevels[name] = rawget(command, "AdminLevel")

				local aliases = {}
				for _, cmd in pairs(rawget(command, "Commands")) do
					table.insert(aliases, cmd)
				end

				CachedAliases[name] = aliases
			end
		end
	end

	do -- Keep track of custom commands added by other plugins
		local CommandsMetatable = getmetatable(Commands) or {}
		local ExistingNewIndex = CommandsMetatable.__newindex

		CommandsMetatable.__newindex = function(tab, ind, val)
			if tab and ind and val then
				-- Prevent overwriting the existing metatable
				if ExistingNewIndex then
					ExistingNewIndex(tab, ind, val)
				end

				-- Add the new command to a table to send to the web server during the next request
				FoundCustomCommands[ind] = CopyCommand(val)
				CachedDefaultLevels[ind] = rawget(val, "AdminLevel")
				local aliases = {}
				for _, cmd in pairs(rawget(val, "Commands")) do
					table.insert(aliases, cmd)
				end
				CachedAliases[ind] = aliases

				-- Handle panel overrides where no matching command was found
				local command = Commands[ind]

				for i,v in pairs(OverrideQueue) do
					if command.Commands and table.find(command.Commands, v.name) then
						UpdateCommand(ind, val, v.data)
						break
					end
				end
			end
		end

		setmetatable(Commands, CommandsMetatable)
	end

	service.DataModel:BindToClose(WebPanelCleanUp)

	-- Long polling to listen for any changes on the panel
	while Settings.WebPanel_Enabled do
		local success, res = pcall(HttpService.RequestAsync, HttpService, {
			Url = "https://robloxconnection.adonis.dev/load";
			Method = "POST";
			Headers = {
				["api-key"] = Settings.WebPanel_ApiKey,
				["Content-Type"] = "application/json"
			};
			Body = HttpService:JSONEncode({
				["custom-commands"] = Encode(HttpService:JSONEncode(GetCustomCommands())), -- For loading custom commands in command settings!
				["server-stats"] = Encode(HttpService:JSONEncode(GetServerStats())),
				["init"] = Variables.WebPanel_Initiated and "false" or "true",
			})
		});

		if success and res.Success then
			local data = HttpService:JSONDecode(res.Body)

			--// Load plugins
		--[[if init then
			for i,v in next,data.Plugins do
				local func,err = server.Core.Loadstring(Decode(v), getfenv())
				if func then
					func()
				else
					warn("Error Loading Plugin from WebPanel.")
				end
			end
		end]]

			if not Variables.WebPanel_Initiated then
				UpdateCommands(data)
				UpdateSettings(data)

				if data.trello.board and data.trello["app-key"] and data.trello.token then
					Settings.Trello_Enabled = true
					Settings.Trello_Primary = data.trello.board
					Settings.Trello_AppKey = data.trello["app-key"]
					Settings.Trello_Token = data.trello.token

					service.StartLoop("TRELLO_UPDATER", Settings.HttpWait, HTTP.Trello.Update, true)
				end
			end

			--// Handle queue items
			for i,v in pairs(data.Queue) do
				if typeof(v.action) ~= "string" then v.action = tostring(v.action) end
				if typeof(v.server) ~= "string" then v.server = tostring(v.server) end

				if v.action == "gameshutdown" then
					Functions.Shutdown("[WebPanel] Server Shutdown")
					WebPanelCleanUp(true)
					break
				elseif v.action == "updatecommands" then
					UpdateCommands(data)
				elseif v.action == "updatesettings" then
					UpdateSettings(data)

					for _, p in pairs(service.GetPlayers()) do
						if Admin.CheckBan(p) then
							Admin.AddBan(p, false)
						else
							Admin.UpdateCachedLevel(p)
						end
					end
				end

				if (v and v.server == game.JobId) or (service.RunService:IsStudio() and v and v.server == "Roblox Studio") then
					if v.action == "shutdown" then
						Functions.Shutdown("[WebPanel] Server Shutdown")
						WebPanelCleanUp(true)
					elseif v.action == "remoteexecute" then
						if typeof(v.command) ~= "string" then
							v.command = tostring(v.command)
						end

						Process.Command(fakePlayer, v.command, {
							AdminLevel = 900,
							DontLog = true,
							IgnoreErrors = true
						})
					end
				end
			end

			if not Variables.WebPanel_Initiated then
				Logs:AddLog("Script", "WebPanel Initialization Complete")
				Variables.WebPanel_Initiated = true
				wait(3)
			end
		else
			local code, msg = res.StatusCode, res.StatusMessage

			if code ~= 520 and code ~= 524 then
				Logs:AddLog("Script", "WebPanel Polling Error: "..msg.." ("..code..")")
				Logs:AddLog("Errors", "WebPanel Polling Error: "..msg.." ("..code..")")
				break
			elseif code == 520 then
				wait(5) --After the server restarts we want to make sure that it has time to inititate everything
			end
		end

		wait()
	end
end
