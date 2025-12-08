server = nil
service = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

type Card = {id: string, name: string, desc: string, labels: {any}?}
type List = {id: string, name: string, cards: {Card}}

return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
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

		if Settings.Trello_Enabled then
			HTTP.Trello.API = require(server.Deps.TrelloAPI)(Settings.Trello_AppKey, Settings.Trello_Token)
			Logs:AddLog("Script", `Loaded Trello API as {HTTP.Trello.API}`)
		end

		-- Check HTTP asynchronously
		task.spawn(function()
			if service.RunService:IsStudio() then
				HTTP.HttpEnabled = service.HttpService.HttpEnabled
				Logs:AddLog("Script", `Pooled HttpEnabled from service as {HTTP.HttpEnabled}`)
			else
				local success, res = pcall(service.HttpService.GetAsync, service.HttpService, Variables.HTTPCheckUrl)
				HTTP.HttpEnabled = not (not success and res:find("Http requests are not enabled.")) or true
				Logs:AddLog("Script", `Pooled HttpEnabled from request as {HTTP.HttpEnabled}. Status {success}`)
			end
		end)

		HTTP.Init = nil;
		Logs:AddLog("Script", "HTTP Module Initialized")
	end;

	server.HTTP = {
		Init = Init;
		HttpEnabled = service.HttpService.HttpEnabled;
		LoadstringEnabled = pcall(loadstring, "");

		WebPanel = {
			Moderators = {};
			Admins = {};
			HeadAdmins = {};
			Creators = {};
			Mutes = {};
			Bans = {};
			Blacklist = {};
			Whitelist = {};
		};

		Trello = {
			PerformedCommands = {};

			Mutes = {};
			Bans = {};
			Music = {};
			InsertList = {};
			Agents = {};

			Overrides = {
				{
					Lists = {"Banlist", "Ban List", "Bans"},
					Process = function(card, data)
						table.insert(data.Bans, {
							Name = card.name,
							Reason = card.desc
						})
					end
				},
				{
					Lists = {"Commands", "Command List"},
					Process = function(card)
						if not HTTP.Trello.PerformedCommands[tostring(card.id)] then
							local cmd = card.name

							if string.sub(cmd, 1, 1) == "$" then
								local placeid = string.match(string.sub(cmd, 2), ".%d+")
								cmd = string.sub(cmd, #placeid+2)
								if tonumber(placeid) ~= game.PlaceId then
									return
								end
							end

							Admin.RunCommand(cmd)
							HTTP.Trello.PerformedCommands[tostring(card.id)] = true

							Logs.AddLog(Logs.Script, {
								Text = "Trello command executed";
								Desc = cmd;
							})

							if Settings.Trello_Token ~= "" then
								pcall(HTTP.Trello.API.makeComment, card.id, `Ran Command: {cmd}\nPlace ID: {game.PlaceId}\nServer Job Id: {game.JobId}\nServer Players: {#service.GetPlayers()}\nServer Time: {service.FormatTime()}`)
							end
						end
					end
				},
				{
					Lists = {"Moderators", "Moderator List", "Moderatorlist", "Modlist", "Mod List", "Mods"},
					Process = function(card, data)
						table.insert(data.Ranks.Moderators, card.name)
					end
				},
				{
					Lists = {"Admins", "Admin List", "Adminlist"},
					Process = function(card, data)
						table.insert(data.Ranks.Admins, card.name)
					end
				},
				{
					Lists = {"Owners", "HeadAdmins", "HeadAdmin List", "Owner List", "Ownerlist"},
					Process = function(card, data)
						table.insert(data.Ranks.HeadAdmins, card.name)
					end
				},
				{
					Lists = {"Creators", "Creator List", "Creatorlist", "Place Owners"},
					Process = function(card, data)
						table.insert(data.Ranks.Creators, card.name)
					end
				},
				{
					Lists = {"Music", "Music List", "Musiclist", "Songs"},
					Process = function(card, data)
						if string.match(card.name, '^(.*):(.*)') then
							local name, id = string.match(card.name, '^(.*):(.*)')
							table.insert(data.Music, {
								Name = name,
								ID = tonumber(id)
							})
						end
					end
				},
				{
					Lists = {"InsertList", "Insert List", "Insertlist", "Inserts", "ModelList", "Model List", "Modellist", "Models"},
					Process = function(card, data)
						if string.match(card.name, '^(.*):(.*)') then
							local name, id = string.match(card.name, '^(.*):(.*)')
							table.insert(data.InsertList, {
								Name = name,
								ID = tonumber(id)
							})
						end
					end
				},
				{
					Lists = {"Agents","Agent List","Agentlist"},
					Process = function(card, data)
						table.insert(data.Agents, card.name)
					end
				},
				{
					Lists = {"Permissions", "Permission List", "Permlist"},
					Process = function(card)
						local com, level = string.match(card.name, "^(.*):(.*)")
						if com and level then
							Admin.SetPermission(com, level)
						end
					end
				},
				{
					Lists = {"Mutelist", "Mute List"},
					Process = function(card, data)
						table.insert(data.Mutes, card.name)
					end
				},
				{
					Lists = {"Blacklist"},
					Process = function(card, data)
						table.insert(data.Blacklist, card.name)
					end,
				},
				{
					Lists = {"Whitelist"},
					Process = function(card, data)
						table.insert(data.Whitelist, card.name)
					end,
				}
			};

			GetOverrideLists = function()
				local lists = {}
				for _, override in HTTP.Trello.Overrides do
					for _, list in override.Lists do
						table.insert(lists, list)
					end
				end
				for name, rank in Settings.Ranks do
					if not rank.IsExternal and not table.find(lists, name) then
						table.insert(lists, name)
					end
				end
				return lists
			end;
		};
	};
end
