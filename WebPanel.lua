--[[ 

	Currently in beta.
	
	Author: Cald_fan
	Contributors: joritochip (Requests, handling custom commands, command overrides)
	
]]

return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service

	local HTTP = service.HttpService
	local Encode = server.Functions.Base64Encode
	local Decode = server.Functions.Base64Decode
	local Variables = server.Variables
	local Settings = server.Settings
	local Commands = server.Commands
	local Admin = server.Admin

	Variables.WebPanel_Initiated = false

	--[[
		settings.WebPanel_Enabled = true;
		settings.WebPanel_ApiKey = "";
	]]

	local WebPanel = server.HTTP.WebPanel

	local ownerId = game.CreatorType == Enum.CreatorType.User and game.CreatorId or service.GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
	local fakePlayer = service.Wrap(service.New("Folder"))
	local data = {
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
	}
	for i,v in next,data do fakePlayer:SetSpecial(i, v) end

	local FoundCustomCommands = {}
	local CachedAliases = {}
	local CachedDefaultLevels = {}

	local OverrideQueue = {}

	do -- Create a cache of the default admin levels for all commands
		for name, command in pairs(Commands) do
			CachedDefaultLevels[name] = rawget(command, "AdminLevel")
			local aliases = {}
			for _, cmd in pairs(rawget(command, "Commands")) do
				table.insert(aliases, cmd)
			end
			CachedAliases[name] = aliases
		end
	end

	do -- Keep track of custom commands added by other plugins
		local CommandsMetatable = getmetatable(Commands) or {}
		local ExistingNewIndex = CommandsMetatable.__newindex

		CommandsMetatable.__newindex = function(tab, ind, val)
			-- Prevent overwriting the existing metatable
			if ExistingNewIndex then
				ExistingNewIndex(tab, ind, val)
			end

			-- Add the new command to a table to send to the web server during the next request
			FoundCustomCommands[ind] = val
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
					if v.data.disabled then 
						command.Function = function()
							error("Command Disabled!")
						end
					end
					if v.data.level ~= "Default" then command.AdminLevel = v.data.level end
					for i, alias in ipairs(v.data.aliases) do
						command.Commands[#command.Commands + 1] = alias
					end

					table.remove(OverrideQueue, i)
				end
			end
		end

		setmetatable(Commands, CommandsMetatable)
	end

	local function GetCustomCommands() 
		local ret = FoundCustomCommands
		FoundCustomCommands = {} -- Clear queue for next request
		return ret
	end
	
	local delta, frames = 0, 0
	game:GetService("RunService").Stepped:Connect(function(time, step)
		delta += step
		frames += 1
		if delta > 1 then
			delta, frames = 0, 0
		end
	end)

	local function GetServerStats()
		local stats = {}

		local admins = {}
		for i,v in pairs(service.NetworkServer:GetChildren()) do
			if v and v:GetPlayer() and server.Admin.CheckAdmin(v:GetPlayer(), false) then
				table.insert(admins, v:GetPlayer().Name)
			end
		end

		stats.PlayerCount = #game.Players:GetPlayers() == 0 and #service.NetworkServer:children() or #game.Players:GetPlayers()
		stats.MaxPlayers = game.Players.MaxPlayers
		stats.ServerStartTime = server.ServerStartTime
		stats.ServerSpeed = math.min(frames/60, 1)*100
		stats.Admins = admins
		stats.JobId = game.JobId
		stats.PrivateServer = true

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
			if command.Disabled == "WebPanel" then
				command.Disabled = nil
			end
			ResetCommandAdminLevel(index, command)
			ResetCommandAliases(index, command)
		end
	end

	local function UpdateCommands(data)
		local didrun = false
		for i,v in pairs(data.CommandOverrides) do
			didrun = true

			local index, command = server.Admin.GetCommand(Settings.Prefix..i)
			if not index or not command then index,command = server.Admin.GetCommand(Settings.PlayerPrefix..i) end

			if index and command then
				command.Disabled = v.disabled and "WebPanel" or nil

				local aliases = rawget(command, "Commands")
				local newaliases = {}

				-- Remove old aliases from command cache
				for _, alias in pairs(aliases) do
					Admin.CommandCache[string.lower(command.Prefix..alias)] = nil
				end

				if CachedAliases[index] then
					for _, alias in ipairs(CachedAliases[index]) do
						if not table.find(v.aliases, "-"..alias) then
							table.insert(newaliases, alias)
							Admin.CommandCache[string.lower(command.Prefix..alias)] = index
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
							if index == "AdminLevel" and string.match(rawlevel, "^WebPanel.+") then
								return {AdminLevel = string.sub(rawlevel, 9)}
							end
						end,
					})
				else
					ResetCommandAdminLevel(index, command)
				end
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
		WebPanel.Owners = data.Levels.Owners or {};
		WebPanel.Mutes = data.Levels.Mutelist or {};
		WebPanel.Blacklist = data.Levels.Blacklist or {};
		WebPanel.Whitelist = data.Levels.Whitelist or {};
		WebPanel.CustomRanks = data.Levels.CustomRanks or {};

		if Variables.MusicList then
			for i = #Variables.MusicList, 1, -1 do -- Iterating backwards to prevent wonky behavior with table.remove
				local v = Variables.MusicList[i]
				if v and v.WebPanel then
					table.remove(Variables.MusicList, i)
				end
			end
			for ind, music in next,data.Levels.Musiclist or {} do 
				if music:match('^(.*):(.*)') then
					local a,b = music:match('^(.*):(.*)')
					if server.Variables.MusicList then
						table.insert(server.Variables.MusicList, {Name = a,ID = tonumber(b),WebPanel=true})
					end
				end
			end
		end
	end

	-- Long polling to listen for any changes on the panel
	while Settings.WebPanel_Enabled do
		local success, res = pcall(HTTP.RequestAsync, HTTP, {
			Url = "https://robloxconnection.adonis.dev/load";
			Method = "POST";
			Headers = {
				["api-key"] = Settings.WebPanel_ApiKey,
				["Content-Type"] = "application/json"
			};
			Body = HTTP:JSONEncode({
				["custom-commands"] = Encode(HTTP:JSONEncode(GetCustomCommands())), -- For loading custom commands in command settings!
				["server-stats"] = Encode(HTTP:JSONEncode(GetServerStats())),
				["init"] = Variables.WebPanel_Initiated and "false" or "true",
			})
		});

		if success and res.Success then
			local data = HTTP:JSONDecode(res.Body)

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

					service.StartLoop("TRELLO_UPDATER", Settings.HttpWait, server.HTTP.Trello.Update, true)
				end
			end

			--// Handle queue items
			for i,v in pairs(data.Queue) do
				if typeof(v.action) ~= "string" then v.action = tostring(v.action) end
				if typeof(v.server) ~= "string" then v.server = tostring(v.server) end

				if v.action == "gameshutdown" then
					server.Functions.Shutdown("Game Shutdown")
					break
				elseif v.action == "updatecommands" then
					UpdateCommands(data)
				elseif v.action == "updatesettings" then
					UpdateSettings(data)

					for _, p in pairs(service.GetPlayers()) do
						if server.Admin.CheckBan(p) then 
							server.Admin.AddBan(p, false) 
						else
							Admin.UpdateCachedLevel(p)
						end
					end
				end

				if (v and v.server == game.JobId) or (game:GetService("RunService"):IsStudio() and v.server == "Roblox Studio") then
					if v.action == "shutdown" then
						server.Functions.Shutdown("Game Shutdown")
					elseif v.action == "remoteexecute" then
						if typeof(v.command) ~= "string" then v.command = tostring(v.command) end
						server.Process.Command(fakePlayer, v.command, {AdminLevel = 4, DontLog = true, IgnoreErrors = true})
					end
				end
			end

			if not Variables.WebPanel_Initiated then
				server.Logs:AddLog("Script", "WebPanel Initialization Complete")
				Variables.WebPanel_Initiated = true
			end
		else
			local code, msg = res.StatusCode, res.StatusMessage

			if code ~= 520 and code ~= 524 then
				server.Logs:AddLog("Script", "WebPanel Polling Error: "..msg.." ("..code..")")
				server.Logs:AddLog("Errors", "WebPanel Polling Error: "..msg.." ("..code..")")
				break
			elseif code == 520 then
				wait(5) --After the server restarts we want to make sure that it has time to inititate everything
			end
		end
		wait()
	end
end
