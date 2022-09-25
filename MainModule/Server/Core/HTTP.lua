server = nil
service = nil
cPcall = nil
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
			service.StartLoop("TRELLO_UPDATER", Settings.HttpWait, HTTP.Trello.Update, true)
		end

		HTTP.Init = nil;
		Logs:AddLog("Script", "HTTP Module Initialized")
	end;

	server.HTTP = {
		Init = Init;
		HttpEnabled = (function()
			local success, res = pcall(service.HttpService.GetAsync, service.HttpService, "https://google.com/robots.txt")
			if not success and res:find("Http requests are not enabled.") then
				return false
			end
			return true
		end)();
		LoadstringEnabled = pcall(loadstring, "");

		CheckHttp = function()
			return HTTP.HttpEnabled
		end;

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
				{ -- // Was this really a good idea? Since when should databases run code
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
								pcall(HTTP.Trello.API.makeComment, card.id, "Ran Command: "..cmd.."\nPlace ID: "..game.PlaceId.."\nServer Job Id: "..game.JobId.."\nServer Players: "..#service.GetPlayers().."\nServer Time: "..service.FormatTime())
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

			Update = function()
				if not HTTP.Trello.API or not Settings.Trello_Enabled then
					return;
				end

				if not HTTP.CheckHttp() then
					warn("Unable to connect to Trello. Make sure HTTP Requests are enabled in Game Settings.")
					return;
				else
					local data = {
						Bans = {};
						Mutes = {};
						Music = {};
						Whitelist = {};
						Blacklist = {};
						InsertList = {};
						Ranks = {
							["Moderators"] = {},
							["Admins"] = {},
							["HeadAdmins"] = {},
							["Creators"] = {}
						};
					}

					local function grabData(board)
						local lists: {List} = HTTP.Trello.API.getListsAndCards(board, true)
						if #lists == 0 then error("L + ratio") end --TODO: Improve TrelloAPI error handling so we don't need to assume no lists = failed request

						for _, list in pairs(lists) do 
							local foundOverride = false

							for _, override in pairs(HTTP.Trello.Overrides) do 
								if table.find(override.Lists, list.name) then
									foundOverride = true
									for _, card in ipairs(list.cards) do 
										override.Process(card, data)
									end
									break
								end
							end

							-- Allow lists for custom ranks
							if not foundOverride and not data.Ranks[list.name] then
								local rank = Settings.Ranks[list.name]

								if rank and not rank.IsExternal then
									local users = {}
									for _, card in ipairs(list.cards) do
										table.insert(users, card.name)
									end
									data.Ranks[list.name] = users
								end
							end
						end
					end

					local success = true
					local boards = {
						Settings.Trello_Primary, 
						unpack(Settings.Trello_Secondary)
					}
					for i,v in pairs(boards) do
						if not v or service.Trim(v) == "" then 
							continue 
						end
						local ran, err = pcall(grabData, v)
						if not ran then
							warn("Unable to reach Trello. Ensure your board IDs, Trello key, and token are all correct. If issue persists, try increasing HttpWait in your Adonis settings.")
							success = false
							break
						end
					end

					-- Only replace existing values if all data was fetched successfully
					if success then
						HTTP.Trello.Bans = data.Bans
						HTTP.Trello.Music = data.Music
						HTTP.Trello.InsertList = data.InsertList
						HTTP.Trello.Mutes = data.Mutes

						Variables.Blacklist.Lists.Trello = data.Blacklist
						Variables.Whitelist.Lists.Trello = data.Whitelist
          
						--// Clear any custom ranks that were not fetched from Trello
						for rank, info in pairs(Settings.Ranks) do 
							if rank.IsExternal and not data.Ranks[rank] then
								Settings.Ranks[rank] = nil
							end
						end

						for rank, users in pairs(data.Ranks) do 
							local name = string.format("[Trello] %s", server.Functions.Trim(rank))
							Settings.Ranks[name] = {
								Level = Settings.Ranks[rank].Level or 1;
								Users = users,
								IsExternal = true,
								Hidden = Settings.Trello_HideRanks;
							}
						end

						for i, v in pairs(service.GetPlayers()) do
							local isBanned, Reason = Admin.CheckBan(v)
							if isBanned then
								v:Kick(string.format("%s | Reason: %s", Variables.BanMessage, (Reason or "No reason provided")))
								continue
							end

							Admin.UpdateCachedLevel(v)
						end

						Logs.AddLog(Logs.Script,{
							Text = "Updated Trello data";
							Desc = "Data was retreived from Trello";
						})
					end
				end
			end;
			
			GetOverrideLists = function()
				local lists = {}
				for _, override in ipairs(HTTP.Trello.Overrides) do 
					for _, list in ipairs(override.Lists) do 
						table.insert(lists, list)
					end
				end
				for name, rank in pairs(Settings.Ranks) do 
					if not rank.IsExternal and not table.find(lists, name) then
						table.insert(lists, name)
					end
				end
				return lists
			end;
		};
	};
end
