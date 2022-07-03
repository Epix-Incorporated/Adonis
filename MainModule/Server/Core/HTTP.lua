server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

type Card = {id: string, name: string, desc: string, labels: {any}?}
type List = {id: string, name: string, cards: {Card}}

type WebhookEmbedMediaData = {url: string, proxy_url: string?, height: number?, width: number?}
type WebhookEmbedData = {
	title: string?,
	description: string?,
	url: string?,
	timestamp: number?,
	color: number?,
	footer: {text: string, icon_url: string?, proxy_icon_url: string?}?,
	image: WebhookEmbedMediaData?,
	thumbnail: WebhookEmbedMediaData?,
	video: WebhookEmbedMediaData?,
	provider: {name: string?, url: string?}?,
	author: {name: string, url: string?, icon_url: string?, proxy_icon_url: string?}?,
	fields: {{name: string, value: string, inline: boolean?}}?
}
type WebhookData = {
	content: string?,
	username: string?,
	avatar_url: string?,
	tts: boolean?,
	embeds: {WebhookEmbedData}?,
}

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

		if Settings.Webhook_Enabled then
			if --Variables.IsStudio or
				not pcall(function()
					HTTP.Webhooks.EmbedQueue = service.MemoryStoreService:GetQueue(Core.DataStoreEncode("Adonis_WebhookEmbeds"))
				end)
			then
				HTTP.Webhooks.EmbedQueue = {}
				warn("Using local webhook embed queue")
			end
			service.StartLoop("WEBHOOK_PROCESSOR", math.random(30, 45), HTTP.Webhooks.ProcessEmbedQueue, true)
			game:BindToClose(HTTP.Webhooks.ProcessEmbedQueue)
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

		Webhooks = {
			FormatPlayer = function(plr, withUserId)
				return string.format("[%s](https://www.roblox.com/users/%d/profile)",
					service.FormatPlayer(plr, withUserId),
					plr.UserId
				)
			end;

			GetUserThumbnail = function(userId, outfitThumbnail)
				return string.format("https://www.roblox.com/%s/image?userId=%d&width=420&height=420&format=png",
					if outfitThumbnail then "outfit-thumbnail" else "bust-thumbnail",
					userId
				)
			end;

			ListPlayers = function(players, withUserIds)
				if not players then
					players = service.Players:GetPlayers()
				end
				local listedPlayers = "- "..HTTP.Webhooks.FormatPlayer(players[1], withUserIds)
				for i, player in players do
					if i ~= 1 then
						listedPlayers ..= "\n- "..HTTP.Webhooks.FormatPlayer(player, withUserIds)
					end
				end
				return listedPlayers
			end;

			GetTimestamp = function(specificTime)
				return os.date("%Y%m%dT%H%M%SZ", specificTime)
			end;

			GetGameLink = function(gameId)
				return "https://www.roblox.com/games/" .. gameId
			end;

			PostEmbed = function(url, embedData: WebhookEmbedData)
				if not Settings.Webhook_Enabled then
					warn("Webhook features are currently disabled in Settings.Webhook_Enabled")
					return
				end

				local success, err
				local tries = 0

				if type(HTTP.Webhooks.EmbedQueue) == "table" then
					success = true
					table.insert(HTTP.Webhooks.EmbedQueue, {Url = url, Embed = embedData})
				else
					repeat
						success, err = pcall(
							HTTP.Webhooks.EmbedQueue.AddAsync, HTTP.Webhooks.EmbedQueue,
							{Url = url, Embed = embedData}, 60 * 5 --// expires in 5 minutes
						)
						tries += 1
					until success or tries == 3
				end

				if success then
					Logs.AddLog("Script", {
						Text = "Added webhook embed to queue";
						Desc = "Attempts: "..tries.." | URL: "..url;
					})
				else
					logError("Error adding webhook embed to queue (3 attempts); "..tostring(err))
				end
			end;

			ProcessEmbedQueue = function()
				if not Settings.Webhook_Enabled then
					warn("Webhook features are currently disabled in Settings.Webhook_Enabled")
					return
				end

				local getQueueSuccess, embedQueue: {{Url: string, Embed: WebhookEmbedData}}, removalId
				local tries = 0

				if type(HTTP.Webhooks.EmbedQueue) == "table" then
					getQueueSuccess, embedQueue = true, table.clone(HTTP.Webhooks.EmbedQueue)
				else
					repeat
						getQueueSuccess, embedQueue, removalId = pcall(
							HTTP.Webhooks.EmbedQueue.ReadAsync, HTTP.Webhooks.EmbedQueue,
							50, false, 0
						)
						tries += 1
						task.wait(0.1)
					until getQueueSuccess or tries == 3
				end

				if getQueueSuccess and #embedQueue > 0 then
					if type(HTTP.Webhooks.EmbedQueue) == "table" then
						table.clear(HTTP.Webhooks.EmbedQueue)
					else
						local clearQueueSuccess, clearQueueError
						local tries = 0
						repeat
							clearQueueSuccess, clearQueueError = pcall(
								HTTP.Webhooks.EmbedQueue.RemoveAsync, HTTP.Webhooks.EmbedQueue,
								removalId
							)
							tries += 1
							task.wait(0.1)
						until clearQueueSuccess or tries == 3
						if not clearQueueSuccess then
							logError("Unable to clear webhook embed queue:", clearQueueError)
						end
					end

					local embedsPerUrl = {}
					for _, item in ipairs(embedQueue) do
						if not (item.Url and item.Embed) then
							continue
						end
						if embedsPerUrl[item.Url] then
							table.insert(embedsPerUrl[item.Url], item.Embed)
						else
							embedsPerUrl[item.Url] = {item.Embed}
						end
					end

					local urlCount = 0
					for url, embeds in pairs(embedsPerUrl) do
						urlCount += 1
						local postSuccess, postError
						local tries = 0
						repeat
							postSuccess, postError = pcall(function()
								service.HttpService:PostAsync(
									url, service.HttpService:JSONEncode({embeds = embeds})
								)
							end)
							tries += 1
						until postSuccess or tries == 3

						if postSuccess then
							Logs.AddLog("Script", {
								Text = "Successfully processed webhook embed batch for URL";
								Desc = "# Embeds: "..#embeds.." | URL: "..url;
							})
						else
							Logs.AddLog("Errors", {
								Text = "Error processing webhook embed batch for URL; "..tostring(postError);
								Desc = "# Embeds: "..#embeds.." | URL: "..url;
							})
						end
					end

					Logs.AddLog("Script", {
						Text = "Finished processing full webhook embed batch queue";
						Desc = "# Total Embeds: "..#embedQueue.." | Unique URLs: "..urlCount;
					})
				elseif not getQueueSuccess then
					logError("Error fetching webhook embed queue: "..tostring(embedQueue))
				end
			end;
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
								IsExternal = true
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
