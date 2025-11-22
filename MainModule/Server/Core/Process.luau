--// Processing
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server
	local service = Vargs.Service

	local Commands, Decrypt, Encrypt, AddLog, TrackTask, Pcall
	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Defaults
	local logError = env.logError
	local Routine = env.Routine
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
		Defaults = server.Defaults;

		logError = logError or env.logError;
		Routine = Routine or env.Routine;
		Commands = Remote.Commands
		Decrypt = Remote.NewDecrypt
		Encrypt = Remote.NewEncrypt
		AddLog = Logs.AddLog
		TrackTask = service.TrackTask
		Pcall = server.Pcall

		--// NetworkServer Events
		if service.NetworkServer then
			service.RbxEvent(service.NetworkServer.ChildAdded, server.Process.NetworkAdded)
			service.RbxEvent(service.NetworkServer.DescendantRemoving, server.Process.NetworkRemoved)
		end

		--// Necessary checks to prevent first time users from bypassing bans.
		service.Events.DataStoreAdd_Banned:Connect(function(data: table|string)
			local userId = if type(data) == "string" then tonumber(string.match(data, ":(%d+)$"))
				elseif type(data) == "table" then data.UserId
				else nil

			local plr = userId and service.Players:GetPlayerByUserId(userId)
			if plr then
				local reason = if type(data) == "table" and data.Reason then data.Reason
					else "No reason provided"
				pcall(plr.Kick, plr, string.format("%s | Reason: %s", Variables.BanMessage, reason))
				AddLog("Script", {
					Text = `Applied ban on {plr.Name}`;
					Desc = `Ban reason: {reason}`;
				})
			end
		end)
		service.Events["DataStoreAdd_Core.Variables.TimeBans"]:Connect(function(data)
			local userId = if type(data) == "string" then tonumber(string.match(data, ":(%d+)$"))
				elseif type(data) == "table" then data.UserId
				else nil

			local plr = userId and service.Players:GetPlayerByUserId(userId)
			if plr then
				local reason = if type(data) == "table" and data.Reason then data.Reason
					else "No reason provided"

				pcall(
					plr.Kick,
					plr,
					string.format(
						"\n Reason: %s\n Banned until %s",
						(reason or "(No reason provided."),
						service.FormatTime(data.EndTime, { WithWrittenDate = true })
					)
				)
				AddLog("Script", {
					Text = `Applied TimeBan on {plr.Name}`;
					Desc = `Ban reason: {reason}`;
				})
			end
		end)

		if Settings.G_Access_Key ~= "Example_Key" and Settings.Allowed_API_Calls.Client then
			Remote._globalAccessHash = Functions.SHA256(Settings.G_Access_Key..game.GameId)
		end

		Process.Init = nil
		AddLog("Script", "Processing Module Initialized")
	end;

	local function RunAfterPlugins(data)
		local existingPlayers = service.Players:GetPlayers()

		--// Events
		service.RbxEvent(service.Players.PlayerAdded, service.EventTask("PlayerAdded", Process.PlayerAdded))
		service.RbxEvent(service.Players.PlayerRemoving, service.EventTask("PlayerRemoving", Process.PlayerRemoving))

		task.spawn(function()
			local oldVer = tonumber(Core.GetData("VersionNumber"))

			if oldVer and server.Version and server.Version > oldVer then
				Process.SaveDatastoreVersionDebounce = true
				table.insert(server.Messages, {
					Level = 1;
					Title = "Updated!";
					Message = "Click to view the changelog.";
					Time = 10;
					Icon = "MatIcon://System upgrade";
					onClick = Core.Bytecode(`client.Remote.Send("ProcessCommand","{Settings.Prefix}changelog")`);
				})
			end
		end)

		if Core.DebugMode == true then
			table.insert(server.Messages, {
				Level = 301;
				Title = "Debug Mode Enabled";
				Message = "Adonis is currently running in Debug Mode.";
				Time = 10;
				Icon = "MatIcon://Bug report";
				onClick = Core.Bytecode(`client.Remote.Send("ProcessCommand","{Settings.Prefix}debugcmds")`);
			})
		end

		if Settings.DataStoreKey == Defaults.Settings.DataStoreKey and Core.DebugMode == false then
			table.insert(server.Messages, {
				Level = 301;
				Title = "Warning!";
				Message = "Using default datastore key!";
				Time = 15;
				Icon = "MatIcon://Description";
				onClick = Core.Bytecode([[
					local window = client.UI.Make("Window", {
						Title = "How to change the DataStore key";
						Size = {700,300};
						Icon = "rbxassetid://7510994359";
					})

					window:Add("ImageLabel", {
						Image = "rbxassetid://1059543904";
					})

					window:Ready()
			]])})
		end

		--// Load client onto existing players
		if existingPlayers then
			for i, p in existingPlayers do
				Core.LoadExistingPlayer(p)
			end
		end

		Process.RunAfterPlugins = nil
		AddLog("Script", "Process Module RunAfterPlugins Finished")
	end

	local function newRateLimit(rateLimit: table, rateKey: string|number)
		-- Ratelimit: table
		-- Ratekey: string or number

		local rateData = (type(rateLimit)=="table" and rateLimit) or nil

		if not rateData then
			error("Rate data doesn't exist (unable to check)")
		else
			-- RATELIMIT TABLE
		--[[

			Table:
				{
					Rates = 100; 	-- Max requests per traffic
					Reset = 1; 		-- Interval seconds since the cache last updated to reset

					ThrottleEnabled = false/true; -- Whether throttle can be enabled
					ThrottleReset = 10; -- Interval seconds since the cache last throttled to reset
					ThrottleMax = 10; -- Max interval count of throttles

					Caches = {}; -- DO NOT ADD THIS. IT WILL AUTOMATICALLY BE CREATED ONCE RATELIMIT TABLE IS CHECKING-
					--... FOR RATE PASS AND THROTTLE CHECK.
				}

		]]

			-- RATECACHE TABLE
		--[[

			Table:
				{
					Rate = 0;
					Throttle = 0; 		-- Interval seconds since the cache last updated to reset

					LastUpdated = 0; -- Last checked for rate limit
					LastThrottled = nil or 0; -- Last checked for throttle (only changes if rate limit failed)
				}

		]]
			local maxRate: number = math.abs(rateData.Rates) -- Max requests per traffic
			local resetInterval: number = math.floor(math.abs(rateData.Reset or 1)) -- Interval seconds since the cache last updated to reset

			local rateExceeded: boolean? = rateLimit.Exceeded or rateLimit.exceeded
			local ratePassed: boolean? = rateLimit.Passed or rateLimit.passed

			local canThrottle: boolean? = rateLimit.ThrottleEnabled
			local throttleReset: number? = rateLimit.ThrottleReset
			local throttleMax: number? = math.floor(math.abs(rateData.ThrottleMax or 1))

			-- Ensure minimum requirement is followed
			maxRate = (maxRate>1 and maxRate) or 1
			-- Max rate must have at least one rate else anything below 1 returns false for all rate checks

			local cacheLib = rateData.Caches

			if not cacheLib then
				cacheLib = {}
				rateData.Caches = cacheLib
			end

			-- Check cache
			local rateCache: table = cacheLib[rateKey]
			local throttleCache
			if not rateCache then
				rateCache = {
					Rate = 0;
					Throttle = 0;
					LastUpdated = os.clock();
					LastThrottled = nil;
				}

				cacheLib[rateKey] = rateCache
			end

			local nowOs = os.clock()

			if nowOs-rateCache.LastUpdated > resetInterval then
				rateCache.LastUpdated = nowOs
				rateCache.Rate = 0
			end

			local ratePass: boolean = rateCache.Rate+1<=maxRate

			local didThrottle: boolean = canThrottle and rateCache.Throttle+1<=throttleMax
			local throttleResetOs: number? = rateCache.ThrottleReset
			local canResetThrottle: boolean = throttleResetOs and nowOs-throttleResetOs <= 0

			rateCache.Rate += 1

			-- Check can throttle and whether throttle could be reset
			if canThrottle and canResetThrottle then
				rateCache.Throttle = 0
			end

			-- If rate failed and can also throttle, count tick
			if canThrottle and (not ratePass and didThrottle) then
				rateCache.Throttle += 1
				rateCache.LastThrottled = nowOs

				-- Check whether cache time expired and replace it with a new one or set a new one
				if not throttleResetOs or canResetThrottle then
					rateCache.ThrottleReset = nowOs
				end
			elseif canThrottle and ratePass then
				rateCache.Throttle = 0
			end

			if rateExceeded and not ratePass then
				rateExceeded:Fire(rateKey, rateCache.Rate, maxRate)
			end

			if ratePassed and ratePass then
				ratePassed:Fire(rateKey, rateCache.Rate, maxRate)
			end

			return ratePass, didThrottle, canThrottle, rateCache.Rate, maxRate, throttleResetOs
		end
	end

	local RateLimiter = {
		Remote = {
			Rates = 120;
			Reset = 60;
		};
		Command = {
			Rates = 20;
			Reset = 40;
		};
		Chat = {
			Rates = 10;
			Reset = 1;
		};
		RateLog = {
			Rates = 10;
			Reset = 2;
		};
	}

	local unWrap = service.unWrap
	local function RateLimit(p, typ)
		local isPlayer = type(p)=="userdata" and p:IsA"Player"
		if isPlayer then
			local rateData = RateLimiter[typ]
			assert(rateData, `No rate limit data available for the given type {typ}`)
			local ratePass, didThrottle, canThrottle, curRate, maxRate = newRateLimit(rateData, p.UserId)
			return ratePass, didThrottle, canThrottle, curRate, maxRate
		else
			return true
		end
	end

	server.Process = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		RateLimit = RateLimit;
		newRateLimit = newRateLimit;
		MsgStringLimit = 500; --// Max message string length to prevent long length chat spam server crashing (chat & command bar); Anything over will be truncated;
		MaxChatCharacterLimit = 250; --// Roblox chat character limit; The actual limit of the Roblox chat's textbox is 200 characters; I'm paranoid so I added 50 characters; Users should not be able to send a message larger than that;
		RemoteMaxArgCount = 5; --// The maximum argument count Adonis will take from Remote (alter if your script requires more arguments)
		RateLimits = {
			Remote = 0.01;
			Command = 0.1;
			Chat = 0.1;
			RateLog = 10;
		};

		Remote = function(p, cliData, com, ...)
			if p and p:IsA("Player") then
				if Anti.KickedPlayers[p] then
					p:Kick(":: Adonis :: Communication following disconnect.")
				elseif not com or type(com) ~= "string" or #com > 50 or cliData == "BadMemes" or com == "BadMemes" then
					Anti.Detected(p, "Kick", service.MaxLen((tostring(com) ~= "BadMemes" and tostring(com)) or tostring(select(1, ...)), 150))
				elseif cliData and type(cliData) ~= "table" then
					Anti.Detected(p, "Kick", "Invalid Client Data (r10002)")
					--elseif cliData and keys and cliData.Module ~= keys.Module then
					--	Anti.Detected(p, "Kick", "Invalid Client Module (r10006)")
				else
					local keys = Remote.Clients[tostring(p.UserId)]
					if keys and select("#", ...) <= Process.RemoteMaxArgCount then
						local args = table.pack(...)
						local rateLimitCheck, _, _, curRemoteRate = RateLimit(p, "Remote")

						keys.LastUpdate = os.time()
						keys.Received += 1

						if type(com) == "string" then
							if com == `{keys.Special}GET_KEY` then
								if cliData.Mode == "Get" then
									AddLog("RemoteFires", {
										Text = `{p.Name} requested key from server`,
										Desc = "Player requested key from server",
										Player = p;
									})

									if keys.LoadingStatus == "WAITING_FOR_KEY" then
										keys.LoadingStatus = "LOADING"
										keys.RemoteReady = true
										AddLog("Script", string.format("%s requested client keys", p.Name))

										return keys.Key
										--else
										--Anti.Detected(p, "kick", "Communication Key Error (r10003)")
									end
								elseif cliData.Mode == "Fire" then
									if keys.LoadingStatus == "WAITING_FOR_KEY" then
										Remote.Fire(p, `{keys.Special}GIVE_KEY`, keys.Key)
										keys.LoadingStatus = "LOADING"
										keys.RemoteReady = true

										AddLog("Script", string.format("%s requested client keys", p.Name))
										--else
										--Anti.Detected(p, "kick","Communication Key Error (r10003)")
									end

									AddLog("RemoteFires", {
										Text = `{p.Name} requested key from server`,
										Desc = "Player requested key from server",
										Player = p;
									})
								else
									Anti.Detected(p, "kick", "Communication Key Error (r10003)")
								end
							elseif rateLimitCheck and string.len(com) <= Remote.MaxLen then
								local comString = Decrypt(com, keys.Key, keys.Cache)
								local command = cliData.Mode == "Get" and Remote.Returnables[comString] or Remote.Commands[comString]

								AddLog("RemoteFires", {
									Text = string.format("%s fired %s; Arg1: %s", p.Name, comString, service.MaxLen(tostring(args[1]), 50));
									Desc = string.format("Player fired remote command %s; %s", comString, Functions.ArgsToString(args));
									Player = p;
								})

								if command then
									local rets = {TrackTask(`Remote: {p.Name}: {comString}`, command, false, p, args)}
									if not rets[1] then
										logError(p, `{comString}: {rets[2]}`)
									else
										return {table.unpack(rets, 2)}
									end
								else
									Anti.Detected(p, "Kick", "Invalid Remote Data (r10004)")
								end
							elseif rateLimitCheck and RateLimit(p, "RateLog") then
								Anti.Detected(p, "Log", string.format("Firing RemoteEvent too quickly (>Rate: %s/sec)", curRemoteRate))
								warn(string.format("%s is firing Adonis's RemoteEvent too quickly (>Rate: %s/sec)", p.Name, curRemoteRate))
							end
						else
							Anti.Detected(p, "Log", "Out of Sync (r10005)")
						end
					end
				end
			end
		end;

		GetOverrideMap = function(str)
			local inputs, outputs = string.match(str, `{Settings.BatchKey}([%d,]+)>([%d,]+)`)
			local tbl1, tbl2 = {}, {}
			local i = 0

			for num in string.gmatch(inputs or "", "(%d+),?") do
				table.insert(tbl1, tonumber(num) or 1)
			end

			for num in string.gmatch(outputs or "", "(%d+),?") do
				i += 1
				if tbl1[i] then
					tbl2[tbl1[i]] = tonumber(num) or 1
				end
			end

			return tbl2
		end;

		Command = function(p, msg, opts, noYield)
			opts = opts or {}

			if #msg > Process.MsgStringLimit and type(p) == "userdata" and p:IsA("Player") and not Admin.CheckAdmin(p) then
				msg = string.sub(msg, 1, Process.MsgStringLimit)
			end

			msg = Functions.Trim(msg)

			if string.match(msg, Settings.BatchKey) then
				local overrideArgs = {}

				for cmd, overrideMap in string.gmatch(msg, `([^{Settings.BatchKey}]+)({Settings.BatchKey}?[%d,>]*)`) do
					cmd, overrideMap = Functions.Trim(cmd), Process.GetOverrideMap(overrideMap)
					local returnArgs = table.pack(Process.Command(p, cmd, opts, false))
					table.clear(overrideArgs)

					for i, i2 in overrideMap do
						overrideArgs[i2] = returnArgs[i + 1]
					end

					opts.OverrideArgs = overrideArgs
				end
			else
				msg = Admin.AliasFormat(Admin.GetAliases(p), msg) or msg

				if string.match(msg, Settings.BatchKey) then
					return Process.Command(p, msg, opts, false)
				end

				local index, command, matched = Admin.GetCommand(msg)
				if not command then
					if opts.Check then
						Remote.MakeGui(p, "Output", {
							Title = "Invalid command";
							Message = if Settings.SilentCommandDenials
								then string.format("'%s' is either not a valid command, or you do not have permission to run it.", msg)
								else string.format("'%s' is not a valid command.", msg);
						})
					end
					return
				end

				local allowed, denialMessage = false, nil
				local isSystem = false

				local pDat = {
					Player = opts.Player or p;
					Level = opts.AdminLevel or Admin.GetLevel(p);
					isDonor = opts.IsDonor or (Admin.CheckDonor(p) and (Settings.DonorCommands or command.AllowDonors));
				}

				if opts.isSystem or p == "SYSTEM" then
					isSystem = true
					allowed = not command.Disabled
					p = p or "SYSTEM"
				else
					allowed, denialMessage = Admin.CheckPermission(pDat, command, false, opts)
				end

				if not allowed then
					if not (isSystem or opts.NoOutput) and (denialMessage or not Settings.SilentCommandDenials or opts.Check) then
						Remote.MakeGui(p, "Output", {
							Message = denialMessage or (if Settings.SilentCommandDenials
								then string.format("'%s' is either not a valid command, or you do not have permission to run it.", msg)
								else string.format("You do not have permission to run '%s'.", msg));
						})
					end
					return
				end

				local cmdArgs = command.Args or command.Arguments
				local argString = string.match(msg, `^.-{Settings.SplitKey}(.+)`) or ""
				local args = (opts.Args or opts.Arguments) or (#cmdArgs > 0 and Functions.Split(argString, Settings.SplitKey, #cmdArgs)) or {}

				local taskName = string.format("Command :: %s : (%s)", p.Name, msg)

				if #args > 0 and not isSystem and command.Filter or opts.Filter then
					for i, arg in args do
						local cmdArg = cmdArgs[i]
						if cmdArg then
							if Admin.IsLax(cmdArg) == false then
								args[i] = service.LaxFilter(arg, p)
							end
						else
							args[i] = service.LaxFilter(arg, p)
						end
					end
				end

				if command.Dangerous and Settings.WarnDangerousCommand and not isSystem then
					-- more checks
					for i, argname in ipairs(cmdArgs) do
						if string.find(argname, "player") ~= nil or string.find(argname, "plr") ~= nil then
							local playersamount = #(service.GetPlayers(p, args[i], {UseFakePlayer = true}));
							if playersamount > 1 then
								if Remote.GetGui(p, "YesNoPrompt", {
									Question = string.format("Are you sure you want to proceed? (%s selected %s possible players)", msg, playersamount);
									Title = "Dangerous command"
								}) == "No" then
									Functions.Hint(string.format("Aborted command %s", msg), { p })
									return
								end
							end
						end
					end
				end

				if opts.OverrideArgs then
					for i, v in opts.OverrideArgs do
						args[i] = v
					end
				end

				if (opts.CrossServer or (not isSystem and not opts.DontLog)) and not command.NoLog then
					local noSave = command.AdminLevel == "Player" or command.Donors or command.AdminLevel == 0
					AddLog("Commands", {
						Text = `{((opts.CrossServer and "[CRS_SERVER] ") or "")}{p.Name}`;
						Desc = `{matched}{Settings.SplitKey}{table.concat(args, Settings.SplitKey)}`;
						Player = p;
						NoSave = noSave;
					})

					if Settings.ConfirmCommands then
						Functions.Hint(`Executed Command: [ {msg} ]`, {p})
					end
				end

				if noYield then
					taskName = `Thread: {taskName}`
				end

				Admin.UpdateCooldown(pDat, command)
				local returnArgs = table.pack(TrackTask(taskName, command.Function, function(cmdError)
					if not opts.IgnoreErrors then
						if type(cmdError) == "string" then
							AddLog("Errors", `[{matched}] {cmdError}`)

							cmdError = cmdError:match("%d: (.+)$") or cmdError

							if not isSystem then
								Remote.MakeGui(p, "Output", {
									Message = cmdError,
								})
								if Core.DebugMode == true then
									warn(`Encountered an error while running a command: {msg}\n{cmdError}\n{debug.traceback()}`)
								end
							end
						elseif cmdError ~= nil and cmdError ~= true and not isSystem then
							Remote.MakeGui(p, "Output", {
								Message = `There was an error but the error was not a string? : {cmdError}`;
							})
						end
					end
				end, p, args, {
					PlayerData = pDat,
					Options = opts
				}))
				local ran, cmdError = returnArgs[1], returnArgs[2]

				service.Events.CommandRan:Fire(p, {
					Message = msg,
					Matched = matched,
					Args = args,
					Command = command,
					Index = index,
					Success = ran,
					Error = if not ran then cmdError else nil,
					Options = opts,
					PlayerData = pDat
				})

				return unpack(returnArgs)
			end
		end;

		CrossServerChat = function(data)
			if data then
				for _, v in service.GetPlayers() do
					if Admin.GetLevel(v) > 0 then
						Remote.Send(v, "handler", "ChatHandler", data.Player, data.Message, "Cross")
					end
				end
			end
		end;

		Chat = function(p, msg)
			local didPassRate, didThrottle, canThrottle, curRate, maxRate = RateLimit(p, "Chat")
			if didPassRate then
				local isMuted = Admin.IsMuted(p);
				if utf8.len(utf8.nfcnormalize(msg)) > Process.MaxChatCharacterLimit and not Admin.CheckAdmin(p) then
					Anti.Detected(p, "Kick", "Chatted message over the maximum character limit")
				elseif not isMuted then
					if not Admin.CheckSlowMode(p) then
						msg = service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService and service.UnsanitizeXML(msg) or msg -- Hack to fix TextChatService invalidly XML escaping messages
						local msg = string.sub(msg, 1, Process.MsgStringLimit)
						local filtered = service.LaxFilter(msg, p)

						AddLog(Logs.Chats, {
							Text = `{p.Name}: {filtered}`;
							Desc = tostring(filtered);
							Player = p;
						})

						if Settings.ChatCommands then
							if Admin.DoHideChatCmd(p, msg) then
								Remote.Send(p,"Function","ChatMessage",`> {msg}`,Color3.new(1, 1, 1))
								Process.Command(p, msg, {Chat = true;})
							elseif string.sub(msg, 1, 3) == "/e " then
								service.Events.PlayerChatted:Fire(p, msg)
								msg = string.sub(msg, 4)
								Process.Command(p, msg, {Chat = true;})
							elseif string.sub(msg, 1, 8) == "/system " then
								service.Events.PlayerChatted:Fire(p, msg)
								msg = string.sub(msg, 9)
								Process.Command(p, msg, {Chat = true;})
							else
								service.Events.PlayerChatted:Fire(p, msg)
								Process.Command(p, msg, {Chat = true;})
							end
						else
							service.Events.PlayerChatted:Fire(p, msg)
						end
					else
						local msg = string.sub(msg, 1, Process.MsgStringLimit)

						if Settings.ChatCommands then
							if Admin.DoHideChatCmd(p, msg) then
								Remote.Send(p,"Function","ChatMessage",`> {msg}`,Color3.new(1, 1, 1))
								Process.Command(p, msg, {Chat = true;})
							else
								Process.Command(p, msg, {Chat = true;})
							end
						end
					end
				elseif isMuted then
					local msg = string.sub(msg, 1, Process.MsgStringLimit);
					service.Events.MutedPlayerChat_UnFiltered:Fire(p, msg)
					local filtered = service.LaxFilter(msg, p)
					AddLog(Logs.Chats, {
						Text = `[MUTED] {p.Name}: {filtered}`;
						Desc = tostring(filtered);
						Player = p;
					})
					service.Events.MutedPlayerChat_Filtered:Fire(p, filtered)
				end
			elseif not didPassRate and RateLimit(p, "RateLog") then
				Anti.Detected(p, "Log", string.format("Chatting too quickly (>Rate: %s/sec)", curRate))
				warn(string.format("%s is chatting too quickly (>Rate: %s/sec)", p.Name, curRate))
			end
		end;

		--[==[
				LogService = function(Message, Type)
					--service.Events.Output:Fire(Message, Type)
				end;

				ErrorMessage = function(Message, Trace, Script)
					--[[if Running then
						service.Events.ErrorMessage:Fire(Message, Trace, Script)
						if Message:lower():find("adonis") or Message:find(script.Name) then
							logError(Message)
						end
					end--]]
				end;
		]==]

		PlayerAdded = function(p)
			AddLog("Script", `Doing PlayerAdded Event for {p.Name}`)

			local key = tostring(p.UserId)
			local keyData = {
				Player = p;
				Key = service.HttpService:GenerateGUID(false);
				Cache = {};
				Sent = 0;
				Received = 0;
				LastUpdate = os.time();
				FinishedLoading = false;
				LoadingStatus = "WAITING_FOR_KEY";
				--Special = Core.MockClientKeys and Core.MockClientKeys.Special;
				--Module = Core.MockClientKeys and Core.MockClientKeys.Module;
			}

			Core.UpdatePlayerConnection(p)
			Core.PlayerData[key] = nil
			Remote.Clients[key] = keyData

			local ran, err = Pcall(function()
				task.spawn(function()
					if Anti.UserSpoofCheck(p) then
						Remote.Clients[key] = nil;
						Anti.Detected(p, "kick", "Username Spoofing");
					end
				end)

				local PlayerData = Core.GetPlayer(p)
				local level = Admin.GetLevel(p)
				local banned, reason = Admin.CheckBan(p)

				if banned then
					Remote.Clients[key] = nil;
					p:Kick(string.format("%s | Reason: %s", Variables.BanMessage, (reason or "No reason provided")))
					return "REMOVED"
				end

				if Variables.ServerLock and level < 1 then
					Remote.Clients[key] = nil;
					p:Kick(Variables.LockMessage or "::Adonis:: Server Locked")
					return "REMOVED"
				end

				if Variables.Whitelist.Enabled then
					local listed = false

					local CheckTable = Admin.CheckTable
					for listName, list in Variables.Whitelist.Lists do
						if CheckTable(p, list) then
							listed = true
							break;
						end
					end

					if not listed and level == 0 then
						Remote.Clients[key] = nil;
						p:Kick(Variables.LockMessage or "::Adonis:: Whitelist Enabled")
						return "REMOVED"
					end
				end

				do
					local Removed = false
					local success, err = pcall(function()
						for filter,func in pairs(server.Variables.PlayerJoinFilters) do
							local success, res, message = pcall(func, p, PlayerData)
							if success and res == false then
								p:Kick(`::Adonis:: {message or Settings.CustomJoinFilterKickMessage or "You are not allowed to join this experience"}`)
								Logs.AddLog(server.Logs.Script, `{tostring(p)} failed the join filter {filter}`)
								Removed = true
								break
							elseif not success then
								Logs.AddLog(server.Logs.Errors, `{filter} failed for {res}`)
							end
						end
					end)
					if Removed then
						return "REMOVED"
					end
				end


			end)

			if not ran then
				AddLog("Errors", `{p.Name} PlayerAdded Failed: {err}`)
				warn("~! :: Adonis :: SOMETHING FAILED DURING PLAYERADDED:")
				warn(tostring(err))
			end

			if Remote.Clients[key] then
				Core.HookClient(p)

				AddLog("Script", {
					Text = `{p.Name} loading started`;
					Desc = `{p.Name} successfully joined the server`;
				})

				AddLog("Joins", {
					Text = service.FormatPlayer(p);
					Desc = `{p.Name} joined the server`;
					Player = p;
				})

				--// Get chats
				p.Chatted:Connect(function(msg)
					local ran, err = TrackTask(`{p.Name}Chatted`, Process.Chat, false, p, msg)
					if not ran then
						logError(err);
					end
				end)

				--// Character added
				p.CharacterAdded:Connect(function(...)
					local ran, err = TrackTask(`{p.Name}CharacterAdded`, Process.CharacterAdded, false, p, ...)
					if not ran then
						logError(err);
					end
				end)

				task.delay(600, function()
					if p.Parent and Core.PlayerData[key] and Remote.Clients[key] and Remote.Clients[key] == keyData and keyData.LoadingStatus ~= "READY" then
						AddLog("Script", {
							Text = `{p.Name} Failed to Load`,
							Desc = `{keyData.LoadingStatus}: Client failed to load in time (10 minutes?)`,
							Player = p;
						});
						--Anti.Detected(p, "kick", "Client failed to load in time (10 minutes?)");
					end
				end)
			elseif ran and err ~= "REMOVED" then
				Anti.RemovePlayer(p, ":: Adonis :: Loading Error [Missing player, keys, or removed]")
			end
		end;

		PlayerRemoving = function(p, r)
			local data = Core.GetPlayer(p)
			local key = tostring(p.UserId)

			service.Events.PlayerRemoving:Fire(p)

			task.delay(1, function()
				if not service.Players:GetPlayerByUserId(p.UserId) then
					Core.PlayerData[key] = nil
				end
			end)

			AddLog("Script", {
				Text = string.format("Triggered PlayerRemoving for %s", p.Name);
				Desc = "Player left the game (PlayerRemoving)";
				Player = p;
			})

			local reasons = {
				["Unknown"] = "Unknown Reason",
				["PlatformKick"] = "Kicked by Roblox",
				["CreatorKick"] = "Kicked by Creator"
			}
			
			local reason = reasons[r.Name] or r.Name

			AddLog("Leaves", {
				Text = service.FormatPlayer(p);
				Desc = `{p.Name} left the server ({reason})`;
				Player = p;
			})

			for _,rateLimit in RateLimiter do
				if not rateLimit.Caches then
					continue
				end
				rateLimit.Caches[p.UserId] = nil
			end

			Core.SavePlayerData(p, data)

			if Settings.ReJail then
				for i,v in pairs(Variables.Jails) do
					if v.Mod == p then
						if service.Players:FindFirstChild(v.Name) then
							Pcall(function()
								for _, tool in v.Tools do
									tool.Parent = v.Player.Backpack
								end
							end)
							Pcall(function() v.Jail:Destroy() end)
							Variables.Jails[i] = nil
						else
							local ind = v.Index
							service.StopLoop(`{ind}JAIL`)
							Pcall(function() v.Jail:Destroy() end)
							Variables.Jails[ind] = nil
						end
					end
				end
			end

			Variables.TrackingTable[p.Name] = nil
			if Variables.ReturnPoints[p] then
				Variables.ReturnPoints[p] = nil
			end

			for otherPlrName, trackTargets in Variables.TrackingTable do
				if trackTargets[p] then
					trackTargets[p] = nil
					local otherPlr = service.Players:FindFirstChild(otherPlrName)
					if otherPlr then
						task.defer(Remote.RemoveLocal, otherPlr, `{p.Name}_Tracker`)
					end
				end
			end

			if Commands.UnDisguise then
				Commands.UnDisguise.Function(p, {"me"})
			end

			Variables.IncognitoPlayers[p] = nil
		end;

		FinishLoading = function(p)
			local PlayerData = Core.GetPlayer(p)
			local level, rank = Admin.GetLevel(p)
			local key = tostring(p.UserId)

			--// Fire player added
			service.Events.PlayerAdded:Fire(p)
			AddLog("Script", {
				Text = string.format("%s finished loading", p.Name);
				Desc = "Client finished loading";
			})

			--// Run OnJoin commands
			for i,v in Settings.OnJoin do
				TrackTask(`Thread: OnJoin_Cmd: {v}`, Admin.RunCommandAsPlayer, false, v, p)
				AddLog("Script", {
					Text = `OnJoin: Executed {v}`;
					Desc = `Executed OnJoin command; {v}`
				})
			end

			--// Start keybind listener
			Remote.Send(p, "Function", "KeyBindListener", PlayerData.Keybinds or {})

			-- // Send server variables to client
			Remote.Send(p, "SetVariables", {
				TopBarShift = Settings.TopBarShift,
				NightlyMode = server.Data.NightlyMode or server.Data.ModuleID == 8612978896,
				G_Access_Key = Remote._globalAccessHash
			})

			--// Load some playerdata stuff
			if type(PlayerData.Client) == "table" then
				if PlayerData.Client.CapesEnabled == true or PlayerData.Client.CapesEnabled == nil then
					Remote.Send(p, "Function", "MoveCapes")
				end
				Remote.Send(p, "SetVariables", PlayerData.Client)
			else
				Remote.Send(p, "Function", "MoveCapes")
			end

			--// Load all particle effects that currently exist
			Functions.LoadEffects(p)

			--// Load admin or non-admin specific things
			if level < 1 then
				if Settings.AntiSpeed and Settings.AllowClientAntiExploit then
					Remote.Send(p, "LaunchAnti", "Speed", {
						Speed = tostring(60.5 + math.random(9e8)/9e8)
					})
				end

				if Settings.Detection and Settings.AllowClientAntiExploit then
					Remote.Send(p, "LaunchAnti", "MainDetection")

					Remote.Send(p, "LaunchAnti", "AntiAntiIdle", {
						Enabled = (Settings.AntiAntiIdle ~= false or Settings.AntiClientIdle ~= false)
					})

					--if Settings.ExploitGuiDetection and Settings.AllowClientAntiExploit then
					--	Remote.Send(p, "LaunchAnti", "AntiCoreGui")
					--end
				end

				if Settings.AntiBuildingTools and Settings.AllowClientAntiExploit then
					Remote.Send(p, "LaunchAnti", "AntiTools", {BTools = true})
				end
			end

			--// Finish things up
			if Remote.Clients[key] then
				Remote.Clients[key].FinishedLoading = true
				if p.Character and p.Character.Parent == workspace then
					local ran, err = TrackTask(`{p.Name} CharacterAdded`, Process.CharacterAdded, false, p, p.Character, {FinishedLoading = true})
					if not ran then
						logError(err)
					end
				else
					--// probably could make this RefreshGui instead of MakeGui down the road
					if Settings.Console and (not Settings.Console_AdminsOnly or level > 0) then
						Remote.MakeGui(p, "Console")
					end

					if Settings.HelpButton then
						Remote.MakeGui(p, "HelpButton")
					end
				end

				if level > 0 then
					if Settings.Notification then
						task.wait(1)
						Functions.Notification("Welcome.", `Your rank is {rank} ({level}). Click here for commands.`, {p}, 15, "MatIcon://Verified user", Core.Bytecode(`client.Remote.Send("ProcessCommand","{Settings.Prefix}cmds")`))

						if #server.Messages > 0 then
							for _, message in server.Messages do
								local isString = type(message) == "string"

								if level >= (not isString and message.Level or 300) then
									task.delay(
										1,
										Functions.Notification,
										not isString and message.Title or "Message",
										isString and message or not isString and message.Message or "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
										{p},
										isString and math.round((#message/19)+2.5) or not isString and message.Time or 10,
										not isString and message.Icon,
										not isString and message.onClick
									)
								end
							end
						end
					end

					if Process.SaveDatastoreVersionDebounce then
						Process.SaveDatastoreVersionDebounce = false
						Core.SetData("VersionNumber", server.Version)
					end
				end

				--// REF_1_ALBRT - 57s_Dxl - 100392_659;
				--// COMP[[CHAR+OFFSET] < INT[0]]
				--// EXEC[[BYTE[N]+BYTE[x]] + ABS[CHAR+OFFSET]]
				--// ELSE[[BYTE[A]+BYTE[x]] + ABS[CHAR+OFFSET]]
				--// VALU -> c_BYTE ; CAT[STR,x,c_BYTE] -> STR ; OUT[STR]]]
				--// [-150x261x247x316x246x243x238x248x302x316x261x247x316x246x234x247x247x302]
				--// END_ReF - 100392_659

				for v: Player, pdata: table in Variables.IncognitoPlayers do
					--// Check if the Player still exists before doing incognito to prevent LoadCode spam.
					if v == p or v.Parent ~= service.Players then
						continue
					end
					if level > 0 and not pdata.hide_from_everyone then
						continue
					end
					if pdata.hide_character then
						Remote.LoadCode(p, [[
							local plr = service.Players:GetPlayerByUserId(]] .. v.UserId .. [[)
							if plr then
								if not table.find(service.IncognitoPlayers, plr) then
									table.insert(service.IncognitoPlayers, plr)
								end
								if plr.Character then
									plr.Character:Destroy()
								end
								plr:Destroy()
							end
						]])
					else
						Remote.LoadCode(p, [[
							local plr = service.Players:GetPlayerByUserId(]] .. v.UserId .. [[)
							if plr then
								if not table.find(service.IncognitoPlayers, plr) then
									table.insert(service.IncognitoPlayers, plr)
								end
								plr:Destroy()
							end
						]])
					end
				end
			end
		end;

		CharacterAdded = function(p, char, ...)
			local key = tostring(p.UserId)
			local keyData = Remote.Clients[key]

			local args = {...}

			if keyData then
				keyData.PlayerLoaded = true
			end

			task.wait(1 / 60)
			if char and keyData and keyData.FinishedLoading then
				local level = Admin.GetLevel(p)

				--// Wait for UI stuff to finish
				task.wait(1)
				if not p:FindFirstChildWhichIsA("PlayerGui") then
					p:WaitForChild("PlayerGui", 60)
					if not p.Parent then
						return
					end
				end
				Remote.Get(p,"UIKeepAlive")

				--// GUI loading
				if Variables.NotifMessage then
					Remote.MakeGui(p, "Notif", {
						Message = Variables.NotifMessage
					})
				end

				if
					(not args[1] or
						(args[1] and type(args[1]) == "table" and args[1].FinishedLoading == nil or args[1].FinishedLoading == true))
					and
						(Settings.Console and (not Settings.Console_AdminsOnly or level > 0)) then
					Remote.RefreshGui(p, "Console")
				end

				if Settings.HelpButton then
					Remote.MakeGui(p, "HelpButton")
				end

				if level < 1 then
					if Settings.AntiNoclip and Settings.AllowClientAntiExploit then
						Remote.Send(p, "LaunchAnti", "HumanoidState")
					end
				end

				task.spawn(Functions.Donor, p)

				--// Fire added event
				service.Events.CharacterAdded:Fire(p, char, ...)

				--// Run OnSpawn commands
				for _, v in Settings.OnSpawn do
					TrackTask(`Thread: OnSpawn_Cmd: {v}`, Admin.RunCommandAsPlayer, false, v, p)
					AddLog("Script", {
						Text = `OnSpawn: Executed {v}`;
						Desc = `Executed OnSpawn command; {v}`;
					})
				end

				if
					server.Commands.Track
					and char:WaitForChild("Head", 5)
					and char:WaitForChild("HumanoidRootPart", 2)
				then
					for otherPlrName, trackTargets in Variables.TrackingTable do
						if trackTargets[p] and service.Players:FindFirstChild(otherPlrName) then
							Admin.RunCommandAsPlayer(`{Settings.Prefix}track`, service.Players[otherPlrName], `@{p.Name}`, "true")
						end
					end
				end

				local Hum = char:FindFirstChildOfClass("Humanoid")
				if not Hum then return end
				local Health = Variables.Starter.Health[tostring(p.UserId)]
				if Health then
					Hum.MaxHealth = Health
					Hum.Health = Hum.MaxHealth
				end
				local Speed = Variables.Starter.Speed[tostring(p.UserId)]
				if Speed then
					Hum.WalkSpeed = Speed
				end
			end
		end;

		NetworkAdded = function(cli)
			if cli.ClassName == "ServerReplicator" then
				task.wait(0.25)

				local p = cli:GetPlayer()
				if p then
					Core.Connections[cli] = p

					AddLog("Script", {
						Text = `{p.Name} connected`;
						Desc = `{p.Name} successfully established a RakPeer network connection with the server (RakNet)`;
						Player = p;
					})
				else
					AddLog("Script", {
						Text = "<UNKNOWN> connected";
						Desc = "An unknown user without a player instance successfully established a RakPeer network connection with the server (RakNet)";
					})
				end

				service.Events.NetworkAdded:Fire(cli)
			end
		end;

		NetworkRemoved = function(cli)
			if cli.ClassName == "ServerReplicator" then
				local p = cli:GetPlayer() or Core.Connections[cli]

				Core.Connections[cli] = nil

				if p then
					Anti.KickedPlayers[p] = nil
					AddLog("Script", {
						Text = `{p.Name} disconnected`;
						Desc = `{p.Name} disconnected from the server (RakNet)`;
						Player = p;
					})
				else
					AddLog("Script", {
						Text = "<UNKNOWN> disconnected";
						Desc = "An unknown user without a player instance disconnected from the server (RakNet)";
					})
				end

				service.Events.NetworkRemoved:Fire(cli)
			end
		end;

		--[[
		PlayerTeleported = function(p,data)

		end;
		]]
	};
end
