return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	HTTP.Trello.Update = function()
		if not HTTP.Trello.API or not Settings.Trello_Enabled then
			return
		end

		if not HTTP.HttpEnabled then
			warn("Unable to connect to Trello. Make sure HTTP Requests are enabled in Game Settings.")
			return
		else
			local data = {
				Bans = {};
				Mutes = {};
				Music = {};
				Whitelist = {};
				Blacklist = {};
				InsertList = {};
				Agents = {};
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

				for _, list in lists do
					local foundOverride = false

					for _, override in HTTP.Trello.Overrides do
						if table.find(override.Lists, list.name) then
							foundOverride = true
							for _, card in list.cards do
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
							for _, card in list.cards do
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
			for i,v in boards do
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
				HTTP.Trello.Agents = data.Agents

				Variables.Blacklist.Lists.Trello = data.Blacklist
				Variables.Whitelist.Lists.Trello = data.Whitelist

				--// Clear any custom ranks that were not fetched from Trello
				for rank, info in Settings.Ranks do
					if rank.IsExternal and not data.Ranks[rank] then
						Settings.Ranks[rank] = nil
					end
				end

				for rank, users in data.Ranks do
					local name = string.format("[Trello] %s", server.Functions.Trim(rank))
					Settings.Ranks[name] = {
						Level = Settings.Ranks[rank].Level or 1;
						Users = users,
						IsExternal = true,
						Hidden = Settings.Trello_HideRanks;
					}
				end

				for i, v in service.GetPlayers() do
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
	end

	Remote.Commands.TrelloOperation = function(p: Player, args: {[number]: any})
		local adminLevel = Admin.GetLevel(p)

		local data = args[1]
		if data.Action == "MakeCard" then
			local command = Commands.MakeCard
			if command and Admin.CheckComLevel(adminLevel, command.AdminLevel) then
				local trello = HTTP.Trello.API

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
					Functions.Hint(`Made card "{card.name}" in list "{list.name}"`, {p})
					Logs.AddLog(Logs.Script,{
						Text = `{p} performed Trello operation`;
						Desc = "Player created a Trello card";
						Player = p;
					})
				else
					Functions.Hint(`"{listName}" does not exist"`, {p})
				end
			end
		end
	end

	-- // Moderator commands
	Commands.ShowTrelloBansList = {
		Prefix = Settings.Prefix;
		Commands = {"trellobans", "trellobanlist", "syncedtrellobans", "showtrellobans"};
		Args = {};
		Description = "Shows bans synced from Trello.";
		TrelloRequired = true;
		AdminLevel = "Moderators";
		ListUpdater = function(plr: Player)
			local tab = table.create(#HTTP.Trello.Bans)
			for _, banData in HTTP.Trello.Bans do
				table.insert(tab, {
					Text = banData.Name,
					Desc = banData.Reason or "No reason specified",
				})
			end
			table.insert(tab, 1, `# Banned Users: {#HTTP.Trello.Bans}`)
			table.insert(tab, 2, "―――――――――――――――――――――――")
			return tab
		end;
		Function = function(plr: Player, args: {string})
			local trello = HTTP.Trello.API
			if not Settings.Trello_Enabled or trello == nil then
				Functions.Notification("Trello Synced Ban List", "Trello has not been enabled.", {plr})
			else
				Remote.MakeGui(plr, "List", {
					Title = "Trello Synced Bans List";
					Icon = server.MatIcons.Gavel;
					Tab = Logs.ListUpdaters.ShowTrelloBansList(plr);
					Update = "ShowTrelloBansList";
				})
			end
		end;
	}

	-- // Admin commands
	Commands.TrelloBan = {
		Prefix = Settings.Prefix;
		Commands = {"trelloban"};
		Args = {"player/user", "reason"};
		Description = "Adds a user to the Trello ban list (Trello needs to be configured)";
		Filter = true;
		CrossServerDenied = true;
		TrelloRequired = true;
		AdminLevel = "Admins";
		Function = function(plr: Player, args: {string}, data: {any})
			local trello = HTTP.Trello.API
			if not Settings.Trello_Enabled or trello == nil then
				Functions.Notification("Trelloban", "Trello has not been configured.", {plr}, 10, "MatIcon://Description")
				return
			end

			local lists = trello.getLists(Settings.Trello_Primary)
			local list = trello.getListObj(lists, {"Banlist", "Ban List", "Bans"})

			local level = data.PlayerData.Level
			local reason = string.format("Administrator: %s\nReason: %s", service.FormatPlayer(plr), (args[2] or "N/A"))

			for _, v in service.GetPlayers(plr, args[1], {
				IsKicking = true;
				NoFakePlayer = false;
				})
			do
				if level > Admin.GetLevel(v) then
					trello.makeCard(
						list.id,
						string.format("%s:%d", (v and tostring(v.Name) or tostring(v)), v.UserId),
						reason
					)

					pcall(function() v:Kick(reason) end)
					Functions.LogAdminAction(plr, "Trello Ban", v.Name, `Reason: {args[2] or "N/A"}`)
					Functions.Notification("Notification", `Trello-banned {service.FormatPlayer(v, true)}`, {plr}, 5, "MatIcons://Gavel")
				end
			end

			HTTP.Trello.Update()
		end;
	}

	-- // HeadAdmin commands
	Commands.MakeList = {
		Prefix = Settings.Prefix;
		Commands = {"makelist", "newlist", "newtrellolist", "maketrellolist"};
		Args = {"name"};
		Description = "Adds a list to the Trello board set in Settings. AppKey and Token MUST be set and have write perms for this to work.";
		TrelloRequired = true;
		AdminLevel = "HeadAdmins";
		Function = function(plr: Player, args: {string})
			assert(args[1], "You need to supply a list name.")

			local trello = HTTP.Trello.API
			if not Settings.Trello_Enabled or trello == nil then return Functions.Hint('Trello has not been configured in settings', {plr}) end

			local list = trello.Boards.MakeList(Settings.Trello_Primary, args[1])
			Functions.Hint(`Made list {list.name}`, {plr})
		end
	}

	Commands.ViewList = {
		Prefix = Settings.Prefix;
		Commands = {"viewlist", "viewtrellolist"};
		Args = {"name"};
		Description = "Views the specified Trello list from the primary board set in Settings.";
		TrelloRequired = true;
		AdminLevel = "HeadAdmins";
		Function = function(plr: Player, args: {string})
			local trello = HTTP.Trello.API
			if not Settings.Trello_Enabled or trello == nil then return Functions.Hint('Trello has not been configured in settings', {plr}) end
			local list = assert(trello.Boards.GetList(Settings.Trello_Primary, assert(args[1], "Enter a valid list name")), "List not found.")

			local cards = trello.Lists.GetCards(list.id)
			local temp = table.create(#cards)
			for _, v in cards do
				table.insert(temp, {Text = v.name, Desc = v.desc})
			end
			Remote.MakeGui(plr, "List", {Title = list.name; Tab = temp})
		end
	}

	Commands.MakeCard = {
		Prefix = Settings.Prefix;
		Commands = {"makecard", "maketrellocard", "createcard"};
		Args = {};
		Description = "Opens a gui to make new Trello cards. AppKey and Token MUST be set and have write perms for this to work.";
		TrelloRequired = true;
		AdminLevel = "HeadAdmins";
		Function = function(plr: Player, args: {string})
			Remote.MakeGui(plr, "CreateCard")
		end
	}

	-- // Initialization
	if Settings.Trello_Enabled then
		service.StartLoop("TRELLO_UPDATER", Settings.HttpWait, HTTP.Trello.Update, true)
	end
	Logs:AddLog("Script", "Trello Module Loaded")
end
