--// This module is for stuff specific to cross server communication
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!
return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local thisJobId = game.JobId;
	local messagingService = service.MessagingService;
	local encryptedSubKey = Core.DataStoreEncode("Adonis_CrossServerMessaging");

	local messagesSent = 0;
	local lastMessageSent = os.clock();

	local oldCommands = Core.CrossServerCommands;
	local unsupportedMessage = "Cross-server player messages are not supported; send the message in the current server."
	local unsupportedCommand = "Cross-server commands require one supported command; aliases, batches, and command loops are unavailable."

	-- Restricts shared text publications to editable content and moderation, never conversation.
	local function canPublishCommand(command)
		local metadata = command and command.UserText
		return metadata and (metadata.Kind == "PublicEdit" or metadata.Kind == "Moderation")
			and not command.CrossServerDenied and not metadata.RequiresLocalAuthor
	end

	-- Resolves one native command and retains its original argument spelling for legacy receivers.
	local function resolveCommand(text, suppliedArgs)
		if type(text) ~= "string" or string.match(text, Settings.BatchKey) then return nil, unsupportedCommand end
		text = Functions.Trim(text)
		local name, command, matched = Admin.GetCommand(text)
		if not command then return nil, unsupportedCommand end
		if command.UserText and (command.UserText.Kind == "Chat" or command.UserText.Kind == "Announcement") then
			return nil, unsupportedMessage
		end
		if command.CrossServerDenied or name == "Repeat" then return nil, unsupportedCommand end
		local argumentNames = command.Args or command.Arguments or {}
		local args = suppliedArgs
		if args == nil then
			local argumentString = string.match(text, `^.-{Settings.SplitKey}(.+)`) or ""
			args = if #argumentNames > 0 then Functions.Split(argumentString, Settings.SplitKey, #argumentNames) else {}
		end
		if type(args) ~= "table" then return nil, unsupportedCommand end
		local copy = {}
		for index, value in args do
			if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #argumentNames or type(value) ~= "string" then
				return nil, unsupportedCommand
			end
			copy[index] = value
		end
		local prefix = if type(command.Prefix) == "table" then command.Prefix[1] else command.Prefix
		local canonical = `{prefix}{command.Commands[1]}`
		return name, command, canonical, copy, canonical .. string.sub(text, #matched + 1)
	end

	-- Encodes a complete legacy command only when reparsing preserves every structured argument.
	local function legacyCommandText(name, canonical, args, originalText)
		local count = 0
		for _ in args do count += 1 end
		for index = 1, count do
			if args[index] == nil then return nil end
		end
		local text = originalText or (canonical .. (if count > 0 then Settings.SplitKey .. table.concat(args, Settings.SplitKey) else ""))
		local parsedName, _, _, parsedArgs = resolveCommand(text)
		if parsedName ~= name or #parsedArgs ~= count then return nil end
		for index, value in args do
			if parsedArgs[index] ~= value then return nil end
		end
		return text
	end

	local secondsFormatted = {
		[1800] = "30 minutes",
		[1200] = "20 minutes",
		[600] = "10 minutes",
		[300] = "5 minutes",
		[120] = "2 minutes",
		[60] = "1 minute",
		[45] = "45 seconds"
		-- The server will begin counting down from 30 seconds to 1 second until the restart command is ran.
	};

	--// Cross Server Commands
	Core.CrossServerCommands = {
		ServerChat = function()
			-- Player conversation cannot be delivered through the server messaging bus.
			return false, unsupportedMessage
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

		-- Accepts canonical operational arguments, including validated callers from an older server.
		NewRunCommand = function(jobId, plrData, comString, suppliedArgs)
			local name, command, canonical, args = resolveCommand(comString, suppliedArgs)
			if not name or command.UserText then return end
			Process.Command(Functions.GetFakePlayer(plrData), canonical, {
				AdminLevel = plrData.AdminLevel,
				CrossServer = true, Args = args,
			})
		end;

		-- Executes only typed, origin-filtered command arguments under the existing cross-server permissions.
		RunPublishedCommand = function(jobId, plrData, commandName, args, publication)
			local command = rawget(Commands, commandName)
			if not canPublishCommand(command) then return end
			local records = server.TextPolicy.AcceptPublication(jobId, publication)
			if not records then return end
			local author = Functions.GetFakePlayer(plrData)
			local token, safeArgs = server.TextPolicy.AuthorizePublishedCommand(command, author, args, records)
			if not token then return end
			local prefix = if type(command.Prefix) == "table" then command.Prefix[1] else command.Prefix
			Process.Command(author, `{prefix}{command.Commands[1]}`, {
				AdminLevel = plrData.AdminLevel, CrossServer = true, Args = safeArgs, TextPublication = token,
			})
		end;

		-- Old servers may still publish Message packets; no record format authorizes chat delivery here.
		Message = function()
			return false, unsupportedMessage
		end;

		RemovePlayer = function(jobId, userId, banMessage, publication)
			local records, code = server.TextPolicy.AcceptPublication(jobId, publication)
			if code == "DuplicatePublication" then return end
			local record = records and records.Reason
			local reason = if record and record.Kind == "Moderation" then record.Text else "Reason unavailable"
			local player = if typeof(userId) == "number" then service.Players:GetPlayerByUserId(userId) else service.Players:FindFirstChild(userId)
			if player then
				player:Kick(string.format("Banned | Reason: %s", reason))
			end
		end;

		DataStoreUpdate = function(jobId, key, data)
			if key and data then
				task.defer(Core.LoadData, key, data, jobId)
			end
		end;

		UpdateSetting = function(jobId, setting, newValue)
			if type(setting) == "string" then
				local value = if newValue == nil then require(Deps.DefaultSettings).Settings[setting] else newValue
				Core.LoadData("SavedSettings", {[setting] = value}, jobId)
			end
		end;

		LoadData = function(jobId, key, dat)
			Core.LoadData(key, dat, jobId)
		end;

		Event = function(jobId, eventId, ...)
			service.Events[`CRSSRV:{eventId}`]:Fire(...)
		end;

		-- Keeps the reason in the moderation action while announcing only fixed numeric restart progress.
		GlobalRestartRequest = function(jobId, publication, countdown, abortable)
			local records, code = server.TextPolicy.AcceptPublication(jobId, publication)
			if code == "DuplicatePublication" then return end
			local record = records and records.Reason
			local reason = if record and record.Kind == "Moderation" then record.Text else "Reason unavailable"
			local abortSuccess, abortMessage = Core.CrossServerCommands.GlobalRestartAbort()
			if abortMessage == "This global restart is not abortable." then
				Logs:AddLog("Script", "A global restart has been requested, but a non-abortable restart is already in progress.")
				return
			elseif abortMessage == "Restart aborted for this server." then
				Logs:AddLog("Script", "In progress global restart was aborted to start a new one.")
			end
			Logs:AddLog("Script", `Global restart {if typeof(countdown) == "number" then `in {countdown} seconds` else ``} requested for "{reason}"`)
			if typeof(countdown) == "number" then
				Functions.Hint(`Global restart happening in {if countdown < 60 then countdown..` seconds` else math.floor(countdown / 60)..` minute{if countdown > 119 then "s" else ""}`}.`, service.GetPlayers())
				local resumeTask, adonisTask
				resumeTask, adonisTask = service.Threads.NewTask("Global Restart Countdown", function()
					while countdown > 0 do
						countdown = math.ceil(countdown - task.wait(1))
						if adonisTask.R_Status ~= "Running" then
							-- The thread was killed. Do not continue.
							return
						end
						if secondsFormatted[countdown] then
							Functions.Hint(`Server restart in {secondsFormatted[countdown]}.`, service.GetPlayers())
						elseif countdown > 0 and countdown <= 30 then
							Functions.Hint(`Server restart in {countdown} second{if countdown ~= 1 then `s` else ``}.`, service.GetPlayers(), 1)
						end
					end
					Logs:AddLog("Script", `This server is now restarting due to the global restart. Reason: "{reason}"`)
					Functions.Hint("This server is now restarting.", service.GetPlayers(), 1000)
					Admin.RunCommand(`{Settings.Prefix}restart`, reason)
				end)
				adonisTask.abortable = abortable
				resumeTask()
			else
				Functions.Hint("This server is now restarting.", service.GetPlayers(), 1000)
				Admin.RunCommand(`{Settings.Prefix}restart`, reason)
			end
		end;

		GlobalRestartAbort = function(jobId)
			for index, adonisTask in service.Threads.Tasks do
				if adonisTask.Name == "Global Restart Countdown" then
					if not adonisTask.abortable then return false, "This global restart is not abortable." end
					pcall(coroutine.close, adonisTask.Thread) -- Would use task.Kill() however that appears to call coroutine.yield instead of coroutine.close?
					adonisTask.Remove()
					Functions.Hint("Global restart aborted. This server will no longer restart.", service.GetPlayers())
					return true, "Restart aborted for this server."
				end
			end
			return false, "There is no global restart at the moment."
		end;

		CrossServerVote = function(jobId, data)
			if type(data) ~= "table" or type(data.AnswerCount) ~= "number" or data.AnswerCount < 1 or data.AnswerCount > 63 then return end
			local records = server.TextPolicy.AcceptPublication(jobId, data.Publication)
			if not records or not records.Question or records.Question.Kind ~= "PublicEdit" then return end
			local question = records.Question.Text
			local answers = {}
			for index = 1, data.AnswerCount do
				local record = records[`Answer{index}`]
				if not record or record.Kind ~= "PublicEdit" then return end
				table.insert(answers, record.Text)
			end
			local voteKey = data.VoteKey

			local start = os.clock()

			Logs:AddLog("Commands", {
				Text = `[CRS_SERVER] Vote initiated by {data.Initiator}`,
				Desc = question
			})

			for _, v in service.GetPlayers() do
				task.defer(function()
					local response = Remote.GetGui(v, "Vote", {Question = question, Answers = answers})
					if type(response) == "string" and table.find(answers, response) and (os.clock() - start) <= 120 then
						messagingService:PublishAsync(voteKey, {PlrInfo = {Name = v.Name, UserId = v.UserId}, Response = response})
					end
				end)
			end
		end;
	}

	--// User Commands
	Commands.CrossServer = {
		Prefix = Settings.Prefix;
		Commands = {"crossserver", "cross"};
		Args = {"command"};
		Description = "Runs one supported operational, moderation, or shared-edit command on all servers; player messages, aliases, batches, and loops are unavailable";
		Category = "Server";
		AdminLevel = "HeadAdmins";
		CrossServerDenied = true; --// Makes it so this command cannot be ran via itself causing an infinite spammy loop of cross server commands...
		IsCrossServer = true; --// Used in settings.CrossServerCommands in case a game creator wants to disable the cross-server commands
		Function = function(plr: Player, args: {string})
			local commandName, command, _, commandArgs = resolveCommand(args[1])
			assert(commandName, command)
			if command.UserText then
				assert(canPublishCommand(command), unsupportedCommand)
				local safeArgs, records = server.TextPolicy.PrepareArguments(server.TextPolicy.GetCommandAuthor(plr), commandArgs, command.UserText)
				local namedRecords = {}
				for index, record in records do namedRecords[tostring(index)] = record end
				local publication = assert(server.TextPolicy.CreatePublication(namedRecords))
				assert(Core.CrossServer("RunPublishedCommand", {
					UserId = plr.UserId, Name = plr.Name, DisplayName = plr.DisplayName, AdminLevel = Admin.GetLevel(plr),
				}, commandName, safeArgs, publication), "CrossServer handler not ready (try again later)")
				return
			end
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
		Category = "Server";
		AdminLevel = "Admins";
		CrossServerDenied = true;
		IsCrossServer = true;
		Function = function(plr: Player, args: {string})
			local disced = false
			local updateKey = `SERVERPING_{service.HttpService:GenerateGUID(false)}`
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

				task.delay(500, doDisconnect)
			end
		end;
	};

	Commands.CrossServerVote = {
		-- Poll labels share the same author edit allowance as other editable public text.
		UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1, 2}};
		Prefix = Settings.Prefix;
		Commands = {"crossservervote", "crsvote", "globalvote", "gvote"};
		Args = {"answer1,answer2,etc (NO SPACES)", "question"};
		Filter = true;
		Description = "Lets you ask players in all servers a question with a list of answers and get the results";
		Category = "Messages";
		AdminLevel = "Moderators";
		CrossServerDenied = true;
		IsCrossServer = true;
		Function = function(plr: Player, args: {string}, context: {})
			local question = args[2]
			if not question then error("You forgot to supply a question! (argument #2)") end
			local answers = args[1]
			local anstab = {}
			local responses = {}
			local voteKey = `ADONISVOTE{math.random()}`
			local startTime = os.clock()
			if not answers then
				anstab = {"Yes", "No"}
			else
				for answer in string.gmatch(answers, "([^,]+)") do table.insert(anstab, answer) end
			end
			assert(#anstab > 0 and #anstab <= 63, "Provide between one and 63 poll answers")
			local records = {Question = context.UserTextRecords[2]}
			for index, answer in anstab do
				local record = assert(server.TextPolicy.CreateRecord(answer, server.TextPolicy.GetCommandAuthor(plr), "PublicEdit"), "Poll answer could not be filtered")
				records[`Answer{index}`] = record
				anstab[index] = record.Text
			end

			local msgSub = messagingService:SubscribeAsync(voteKey, function(data)
				if type(data.Data) == "table" and type(data.Data.Response) == "string" and table.find(anstab, data.Data.Response) then
					table.insert(responses, data.Data.Response)
				end
			end)

			local function voteUpdate()
				local results = {}
				local total = #responses
				local tab = {
					`Question: {question}`;
					`Total Responses: {total}`;
					`Time Left: {math.ceil(math.max(0, 120 - (os.clock()-startTime)))}`;
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

			local data = {
				Publication = assert(server.TextPolicy.CreatePublication(records));
				AnswerCount = #anstab;
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

			task.delay(120, function()
				Logs.TempUpdaters[voteKey] = nil
				msgSub:Disconnect()
			end)
		end
	};

	-- Preserves the legacy command string while supplying validated structured arguments to newer receivers.
	Core.CrossServer = function(command, ...)
		local args = table.pack(...)
		if command == "Message" or command == "ServerChat" then return false, unsupportedMessage end
		if command == "NewRunCommand" then
			local name, definition, canonical, parsedArgs, originalText = resolveCommand(args[2], args[3])
			if not name then return false, definition end
			if definition.UserText then return false, unsupportedCommand end
			local text = legacyCommandText(name, canonical, parsedArgs, if args[3] == nil then originalText else nil)
			if not text then return false, unsupportedCommand end
			args[2], args[3], args.n = text, parsedArgs, 3
		elseif command == "RunPublishedCommand" then
			if type(args[2]) ~= "string" or not canPublishCommand(rawget(Commands, args[2])) then return false, unsupportedCommand end
		end
		if not Core.SubEvent then
			return false
		end

		local data = {thisJobId, command, table.unpack(args, 1, args.n)};
		service.Queue("CrossServerMessageQueue", function()
			-- Limit the amount of messages we are publishing to the topic.
			messagesSent += 1
			if messagesSent >= 150 + (60 * #service.Players:GetPlayers()) then
				repeat task.wait() until (os.clock() - lastMessageSent) > 60
			end

			if (os.clock() - lastMessageSent) > 60 then
				lastMessageSent = os.clock()
				messagesSent = 1
			end

			-- Publish the message.
			messagingService:PublishAsync(encryptedSubKey, data)
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

		if not (serverId and command) then
			return
		end

		table.remove(data, 2)

		if Core.CrossServerCommands[command] then
			Core.CrossServerCommands[command](unpack(data))
		end
	end

	task.defer(function()
		Core.SubEvent = not (Variables.IsStudio or Settings.LocalDatastore) and messagingService:SubscribeAsync(encryptedSubKey, function(...)
			if not Settings.CrossServerCommands then
				-- Ignore all incoming events from MessagingService if CrossServerCommands is disabled.
				return
			end
			return Process.CrossServerMessage(...)
		end)
	end)

	--// Check for additions added by other modules in core before this one loaded
	for i, v in oldCommands do
		-- Preserve extensions without restoring a retired relay or bypassing command validation.
		if i ~= "Message" and i ~= "ServerChat" and i ~= "NewRunCommand" and i ~= "RunPublishedCommand" then
			Core.CrossServerCommands[i] = v
		end
	end

	Logs:AddLog("Script", "Cross-Server Module Loaded");
end
