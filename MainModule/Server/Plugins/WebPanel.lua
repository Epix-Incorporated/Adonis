--[[ 

	Currently in beta.
	
	Author: Cald_fan
	Contributors: joritochip (Requests/custom commands)
	
]]

server = nil
service = nil

return function()
	local init = true
	local HTTP = service.HttpService
	local Encode = server.Functions.Base64Encode
	local Decode = server.Functions.Base64Decode
	local Settings = server.Settings

	--[[
		settings.WebPanel_Enabled = true;
		settings.WebPanel_ApiKey = "";
	]]


	local WebPanel = {
		Moderators = {};
		Admins = {};
		Owners = {};
		Creators = {};
		Mutes = {};
		Bans = {};
		Blacklist = {};
		Whitelist = {};
	}

	server.HTTP.WebPanel = WebPanel

	local ownerId = game.CreatorType == Enum.CreatorType.User and game.CreatorId or service.GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id

	-- Create a fake player for use in remote execution
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

	-- Detect custom commands added by other plugins
	local FoundCustomCommands = {}
	local OverrideQueue = {}
	local CommandsMetatable = getmetatable(server.Commands) or {}
	local ExistingNewIndex = CommandsMetatable.__newindex

	CommandsMetatable.__newindex = function(tab, ind, val)
		-- Prevent overwriting the existing metatable
		ExistingNewIndex(tab, ind, val)

		-- Add the new command to a table to send to the web server during the next request
		FoundCustomCommands[ind] = val

		-- Handle panel overrides where no matching command was found
		local command = server.Commands[ind]

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

	setmetatable(server.Commands, CommandsMetatable)

	local function GetCustomCommands() 
		local ret = FoundCustomCommands
		FoundCustomCommands = {} -- Clear queue for next request
		return ret
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
				["init"] = init == true and "true" or "false"
			})
		});

		if success and res.Success then
			local data = HTTP:JSONDecode(res.Body)
			--print(res.Body)

			--// Load table settings (Admins, Creators, Bans, etc)
			--[[ ?
			local moderators = {}
			local admins = {}
			local owners = {}
			local creators = {}
			local mutes = {}
			local bans = {}
			local blacklist = {}
			local whitelist = {}
			local customRanks = {}
			
			for ind, mod in next, data.Levels.Moderators or {} do table.insert(moderators, mod) end
			for ind, admin in next, data.Levels.Admins or {} do table.insert(admins, admin) end
			for ind, owner in next, data.Levels.Owners or {} do table.insert(owners, owner) end
			for ind, creator in next, data.Levels.Creators or {} do table.insert(creators, creator) end
			for ind, mute in next, data.Levels.Mutelist or {} do table.insert(mutes, mute) end
			for ind, ban in next, data.Levels.Banlist or {} do table.insert(bans, ban) end
			for ind, list in next, data.Levels.Blacklist or {} do table.insert(blacklist, list) end
			for ind, list in next, data.Levels.Whitelist or {} do table.insert(whitelist, list) end
			
			if #bans>0 then WebPanel.Bans = bans end
			if #creators>0 then WebPanel.Creators = creators end
			if #admins>0 then WebPanel.Admins = admins end
			if #moderators>0 then WebPanel.Moderators = moderators end
			if #owners>0 then WebPanel.Owners = owners end
			if #mutes>0 then WebPanel.Mutes = mutes end
			if #blacklist>0 then WebPanel.Blacklist = blacklist end
			if #whitelist>0 then WebPanel.Whitelist = whitelist end
			--]]

			WebPanel.Bans = data.Levels.Banlist or {};
			WebPanel.Creators = data.Levels.Creators or {};
			WebPanel.Admins = data.Levels.Admins or {};
			WebPanel.Moderators = data.Levels.Moderators or {};
			WebPanel.Owners = data.Levels.Owners or {};
			WebPanel.Mutes = data.Levels.Mutes or {};
			WebPanel.Blacklist = data.Levels.Blacklist or {};
			WebPanel.Whitelist = data.Levels.Whitelist or {};
			WebPanel.CustomRanks = data.Levels.CustomRanks or {};

			for ind, music in next,data.Levels.Musiclist or {} do 
				if music:match('^(.*):(.*)') and init then
					local a,b = music:match('^(.*):(.*)')
					if not server.Variables.MusicList then
						table.insert(server.Variables.MusicList, {Name = a,ID = tonumber(b)})
					end
				end
			end

			--// Trello Data
			if data.trello.board and data.trello["app-key"] and data.trello.token then
				server.Settings.Trello_Enabled = true
				server.Settings.Trello_Primary = data.trello.board
				server.Settings.Trello_AppKey = data.trello["app-key"]
				server.Settings.Trello_Token = data.trello.token

				server.HTTP.Trello.Update()
			end

			--// Aliases, Perms/Disabling
			for i,v in pairs(data.CommandOverrides) do
				local index,command = server.Admin.GetCommand(server.Settings.Prefix..i)
				if index and command then
					if v.disabled then
						command.Function = function()
							error("Command Disabled!")
						end
					end
					if v.level ~= "Default" then command.AdminLevel = v.level end
					for i, alias in ipairs(v.aliases) do
						command.Commands[#command.Commands + 1] = alias
					end
				else
					-- The command being overridden was not found, add it to a queue for later
					table.insert(OverrideQueue, {
						name = i,
						data = v
					})
				end
			end

			--// Load plugins
			if init then
				print(unpack(data))
				for i,v in next,data.Plugins do
					local func,err = server.Core.Loadstring(Decode(v), getfenv())
					if func then 
						func()
					else
						warn("Error Loading Plugin from WebPanel.")
					end
				end
			end

			--// Load queue
			for i,v in pairs(data.Queue) do
				if typeof(v.action) ~= "string" then v.action = tostring(v.action) end
				if typeof(v.server) ~= "string" then v.server = tostring(v.server) end

				if v.action == "gameshutdown" then
					server.Functions.Shutdown("Game Shutdown")
					break
				end
				if v and v.server == game.JobId then
					if v.action == "shutdown" then
						server.Functions.Shutdown("Game Shutdown")
					elseif v.action == "remoteexecute" then
						if typeof(v.command) ~= "string" then v.command = tostring(v.command) end
						server.Process.Command(fakePlayer, v.command, {AdminLevel = 4, DontLog = true, IgnoreErrors = true})
					end
				end
			end

			if init then
				server.Logs:AddLog("Script", "WebPanel Initialization Complete")
				init = false
			end
		else
			local code, msg = res.StatusCode, res.StatusMessage

			if code ~= 524 then
				if data and data.message then
					error("WebPanel: "..data.message)
				end
				server.Logs:AddLog("Script", "WebPanel Polling Error: "..msg.." ("..code..")")
				break
			end
		end
		wait()
	end
end