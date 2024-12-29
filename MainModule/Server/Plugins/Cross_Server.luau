
--// This module is for stuff specific to cross server communication
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!
return function(Vargs, GetEnv)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local ServerId = game.JobId;
	local MsgService = service.MessagingService;
	local subKey = Core.DataStoreEncode("Adonis_CrossServerMessaging");
	local counter = 0;
	local lastTick;

	local oldCommands = Core.CrossServerCommands;

	--// Cross Server Commands
	Core.CrossServerCommands = {
		ServerChat = function(jobId, data)
			if data then
				for _, v in service.GetPlayers() do
					if Admin.GetLevel(v) > 0 then
						Remote.Send(v, "handler", "ChatHandler", data.Player, data.Message, "Cross")
					end
				end
			end
		end;

		Ping = function(jobId, data)
			Core.CrossServer("Pong", {
				JobId = game.JobId;
				NumPlayers = #service.Players:GetPlayers();
			})
		end;

		Pong = function(jobId, data)
			service.Events.ServerPingReplyReceived:Fire(jobId, data)
		end;

		NewRunCommand = function(jobId, plrData, comString)
			Process.Command(Functions.GetFakePlayer(plrData), comString, {AdminLevel = plrData.AdminLevel, CrossServer = true})
		end;

		-- // Unused, unnecessary, at the very least it should use GetEnv, and yes even if GetEnv has an empty table you can still do GetEnv({}).GetEnv().server
		-- If this ever were to be re-enabled it should use Core.Loadstring at all
		--[[Loadstring = function(jobId, source) -- // Im honestly not even sure what to think of this one.
			Core.Loadstring(source, GetEnv{})()
		end;]]

		Message = function(jobId, fromPlayer, message, duration)
			server.Functions.Message(
				nil,
				`Global Message from {fromPlayer or "[Unknown]"}`,
				message,
				nil,
				service.GetPlayers(),
				true,
				duration
			)
		end;

		RemovePlayer = function(jobId, name, BanMessage, reason)
			--// probably should move this to userid
			local player =	service.Players:FindFirstChild(name)
			if player then
				player:Kick(string.format("%s | Reason: %s", BanMessage, reason))
			end
		end;

		DataStoreUpdate = function(jobId, key, data)
			if key and data then
				task.defer(Core.LoadData, key, data)
			end
		end;

		UpdateSetting = function(jobId, setting, newValue)
			if type(setting) == "string" then
				Settings[setting] = if newValue == nil then require(Deps.DefaultSettings).Settings[setting] else newValue
			end
		end;

		LoadData = function(jobId, key, dat)
			Core.LoadData(key, dat, jobId)
		end;

		Event = function(jobId, eventId, ...)
			service.Events[`CRSSRV:{eventId}`]:Fire(...)
		end;

		GlobalRestartRequest = function(jobId, reason, countdown, abortable)
			local taskobj
			if reason == "[CRS_SRV]:abort" then
				for i,t in service.Threads.Tasks do
					if t.Name == "GLOBALRESTART_COUNTDOWN" then
						pcall(task.cancel,t.Thread) -- forcefully close not caring about adonis's task system
						coroutine.close(t.Thread)
						t.Kill() -- mark it as killed so adonis sees it
						Functions.Hint(`Server restart aborted. Server will no longer restart.`, service.GetPlayers())
						return
					end
				end
				return
			end
			if countdown then
				Logs.AddLog("Script", {
					`Global restart issued {countdown} seconds for "{reason}"`
				});
			else
				Logs.AddLog("Script", {
					`Global restart issued for "{reason}"`
				});
			end
			if countdown then
				do
					local time
					if countdown < 60 then time = `{countdown} seconds`
					else time = `{math.floor(countdown/60)} minutes`
					end
					Functions.Hint(`Server restart in {time}.`, service:GetPlayers())
				end
				local forceful_exit = false
				for i,t in service.Threads.Tasks do
					if t.Name == "GLOBALRESTART_COUNTDOWN" then
						pcall(task.cancel,t.Thread) -- forcefully close not caring about adonis's task system
						coroutine.close(t.Thread)
						t.Kill() -- mark it as killed so adonis sees it
					end
				end
				taskobj = service.Threads.NewTask("THREAD: GLOBALRESTART_COUNTDOWN", function()
					local brackets = {
						[1800]="30 minutes",
						[1200]="20 minutes",
						[600]="10 minutes",
						[300]="5 minutes",
						[120]="2 minutes",
						[60]="1 minute",
						[30]="30 seconds",
						[10]="10 seconds"
					}
					local currentbracket,lastbracket
					local function updatebracket()
						local i = 1
						local lastt
						for time,bracket in pairs(brackets) do
							if time <= countdown then
								currentbracket = brackets[lastt]
							end
							i+=1
						end
					end
					updatebracket()
					lastbracket = currentbracket
					while countdown > 0 do
						countdown -= task.wait(1)
						if taskobj.R_Status == "Stopping" and abortable then
							Functions.Hint(`Server restart aborted. Server will no longer restart.`, service.GetPlayers())
							return
						end
						updatebracket()
						if lastbracket ~= currentbracket then
							Functions.Hint(`Server restart in {currentbracket}.`, service.GetPlayers())
						end
						lastbracket = currentbracket
					end
					Logs.AddLog("Script", {
						`Server is restarting NOW. (issued global restart)`
					});
					Admin.RunCommand(`{Settings.Prefix}restart`, reason)
				end)
				taskobj.abortable = abortable
				taskobj.Start()
				return
			end
			Logs.AddLog("Script", {
				`Server is restarting NOW. (issued global restart)`
			});
			Admin.RunCommand(`{Settings.Prefix}restart`, reason)
		end;

		CrossServerVote = function(jobId, data)
			local question = data.Question
			local answers = data.Answers
			local voteKey = data.VoteKey

			local start = os.clock()

			Logs.AddLog("Commands", {
				Text = `[CRS_SERVER] Vote initiated by {data.Initiator}`,
				Desc = question
			})

			for _, v in service.GetPlayers() do
				task.defer(function()
					local response = Remote.GetGui(v, "Vote", {Question = question, Answers = answers})
					if response and os.clock() - start <= 120 then
						MsgService:PublishAsync(voteKey, {PlrInfo = {Name = v.Name, UserId = v.UserId}, Response = response})
					end
				end)
			end
		end;
	}

	local function CrossEvent(eventId)
		return service.Events[`CRSSRV{eventId}`]
	end

	--// User Commands
	Commands.CrossServer = {
		Prefix = Settings.Prefix;
		Commands = {"crossserver", "cross"};
		Args = {"command"};
		Description = "Runs the specified command string on all servers";
		AdminLevel = "HeadAdmins";
		CrossServerDenied = true; --// Makes it so this command cannot be ran via itself causing an infinite spammy loop of cross server commands...
		IsCrossServer = true; --// Used in settings.CrossServerCommands in case a game creator wants to disable the cross-server commands
		Function = function(plr: Player, args: {string})
			if not Core.CrossServer("NewRunCommand", {
				UserId = plr.UserId;
				Name = plr.Name;
				DisplayName = plr.DisplayName;
				AccountAge = plr.AccountAge;
				--MembershipType = plr.MembershipType; -- MessagingService doesn't accept Enums
				FollowUserId = plr.FollowUserId;
				AdminLevel = Admin.GetLevel(plr);
				}, args[1])
			then
				error("CrossServer handler not ready (try again later)")
			end
		end;
	};

	Commands.CrossServerList = {
		Prefix = Settings.Prefix;
		Commands = {"serverlist", "gameservers", "crossserverlist", "listservers"};
		Args = {"autoupdate? (default: true)"};
		Description = "Attempts to list all active servers (at the time the command was ran)";
		AdminLevel = "Admins";
		CrossServerDenied = true;
		IsCrossServer = true;
		Function = function(plr: Player, args: {string})
			local disced = false
			local updateKey = `SERVERPING_{math.random()}`
			local replyList = {}
			local listener = service.Events.ServerPingReplyReceived:Connect(function(jobId, data)
				if jobId then
					replyList[jobId] = data or {}
				end
			end)

			local function listUpdate()
				local tab = {}
				local totalPlayers = 0
				local totalServers = 0

				for jobId,data in replyList do
					totalServers += 1
					totalPlayers = totalPlayers + (data.NumPlayers or 0)
					table.insert(tab, {
						Text = `Players: {data.NumPlayers or 0} | JobId: {jobId}`;
						Desc = `JobId: {jobId}`;
					})
				end

				table.insert(tab, 1, {
					Text = `Total Servers: {totalServers} | Total Players: {totalPlayers}`;
					Desc = "The total number of servers and players";
				})

				return tab;
			end

			local function doDisconnect()
				if not disced then
					disced = true
					Logs.TempUpdaters[updateKey] = nil
					listener:Disconnect()
				end
			end

			if not Core.CrossServer("Ping") then
				doDisconnect()
				error("CrossServer handler not ready (please try again later)")
			else
				local closeEvent = Remote.NewPlayerEvent(plr,updateKey, function()
					doDisconnect()
				end)

				Logs.TempUpdaters[updateKey] = listUpdate;

				Remote.MakeGui(plr, "List", {
					Title = "Server List",
					Tab = listUpdate(),
					Update = "TempUpdate",
					UpdateArgs = {{UpdateKey = updateKey}},
					OnClose = `client.Remote.PlayerEvent('{updateKey}')`,
					AutoUpdate = if args[1] and (args[1]:lower() == "false" or args[1]:lower() == "no") then nil else 1,
					TextSelectable = true;
				})

				delay(500, doDisconnect)
			end
		end;
	};

	Commands.CrossServerVote = {
		Prefix = Settings.Prefix;
		Commands = {"crossservervote", "crsvote", "globalvote", "gvote"};
		Args = {"answer1,answer2,etc (NO SPACES)", "question"};
		Filter = true;
		Description = "Lets you ask players in all servers a question with a list of answers and get the results";
		AdminLevel = "Moderators";
		CrossServerDenied = true;
		IsCrossServer = true;
		Function = function(plr: Player, args: {string})
			local question = args[2]
			if not question then error("You forgot to supply a question! (argument #2)") end
			local answers = args[1]
			local anstab = {}
			local responses = {}
			local voteKey = `ADONISVOTE{math.random()}`
			local startTime = os.clock()

			local msgSub = MsgService:SubscribeAsync(voteKey, function(data)
				table.insert(responses, data.Data.Response)
			end)

			local function voteUpdate()
				local results = {}
				local total = #responses
				local tab = {
					`Question: {question}`;
					`Total Responses: {total}`;
					`Time Left: {math.ceil(math.max(0, 120 - (os.clock()-startTime)))}`;
					--`Didn't Vote: {#players-total}`;
				}

				for _, v in responses do
					if not results[v] then results[v] = 0 end
					results[v] += 1
				end

				for _, v in anstab do
					local ans = v
					local num = results[v]
					local percent
					if not num then
						num = 0
						percent = 0
					else
						percent = math.floor((num/total)*100)
					end

					table.insert(tab, {
						Text = `{ans} | {percent}% - {num}/{total}`,
						Desc = `Number: {num}/{total} | Percent: {percent}`
					})
				end

				return tab
			end

			Logs.TempUpdaters[voteKey] = voteUpdate;

			if not answers then
				anstab = {"Yes","No"}
			else
				for ans in string.gmatch(answers, "([^,]+)") do
					table.insert(anstab, ans)
				end
			end

			local data = {
				Answers = anstab;
				Question = question;
				VoteKey = voteKey;
				Initiator = service.FormatPlayer(plr);
			}

			Core.CrossServer("CrossServerVote", data)

			Remote.MakeGui(plr, "List", {
				Title = "Results",
				Icon = server.MatIcons["Text snippet"];
				Tab = voteUpdate(),
				Update = "TempUpdate",
				UpdateArgs = {{UpdateKey = voteKey}},
				AutoUpdate = 1,
			})

			delay(120, function()
				Logs.TempUpdaters[voteKey] = nil
				msgSub:Disconnect()
			end)
		end
	};

	--// Handlers
	Core.CrossServer = function(...)
		if not Core.SubEvent then
			return false
		end

		local data = {ServerId, ...};
		service.Queue("CrossServerMessageQueue", function()
			--// rate limiting
			counter += 1
			if not lastTick then lastTick = os.clock() end
			if counter >= 150 + 60 * #service.Players:GetPlayers()  then
				repeat task.wait() until os.clock()-lastTick > 60
			end

			if os.clock()-lastTick > 60 then
				lastTick = os.clock()
				counter = 1
			end

			--// publish
			MsgService:PublishAsync(subKey, data)
		end, 300, true)

		return true
	end

	Process.CrossServerMessage = function(msg)
		local data = msg.Data
		assert(data and type(data) == "table", `CrossServer: Invalid data type {type(data)}`)

		local serverId, command = data[1], data[2]

		Logs:AddLog("Script", {
			Text = `Cross-server message received: {command or "[NO COMMAND]"}`;
			Desc = `Origin JobId: {serverId or "[MISSING]"}`
		})

		if not (serverId and command) then return end

		table.remove(data, 2)

		if Core.CrossServerCommands[command] then
			Core.CrossServerCommands[command](unpack(data))
		end
	end

	task.defer(function()
		Core.SubEvent = not (Variables.IsStudio or Settings.LocalDatastore) and MsgService:SubscribeAsync(subKey, function(...)
			if not Settings.CrossServerCommands then return end -- Ignore when disabled
			return Process.CrossServerMessage(...)
		end)
	end)

	--// Check for additions added by other modules in core before this one loaded
	for i, v in oldCommands do
		Core.CrossServerCommands[i] = v
	end

	Logs:AddLog("Script", "Cross-Server Module Loaded");
end
