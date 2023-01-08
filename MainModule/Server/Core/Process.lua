type table = {[any]: any}

--// Processing
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server
	local service = Vargs.Service

	local Commands, Decrypt, AddLog, TrackTask, Pcall
	local Functions, Admin, Anti, Core, Logs, Remote, Process, Variables, Settings, Defaults
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
		Decrypt = Remote.Decrypt
		AddLog = Logs.AddLog
		TrackTask = service.TrackTask
		Pcall = server.Pcall

		--// NetworkServer Events
		if service.NetworkServer then
			service.RbxEvent(service.NetworkServer.ChildAdded, server.Process.NetworkAdded)
			service.RbxEvent(service.NetworkServer.DescendantRemoving, server.Process.NetworkRemoved)
		end

		--// Necessary checks to prevent first time users from bypassing bans.
		service.Events.DataStoreAdd_Banned:Connect(function(data: table | string)
			local userId = if type(data) == "string" then tonumber(string.match(data, ":(%d+)$"))
				elseif type(data) == "table" then data.UserId
				else nil

			local plr = userId and service.Players:GetPlayerByUserId(userId)
			if plr then
				local reason = if type(data) == "table" and data.Reason then data.Reason
					else "No reason provided"
				pcall(plr.Kick, plr, "{Variables.BanMessage} | Reason: {reason}")
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
					`\nReason: {reason or "(No reason provided.)"}\nBanned until {service.FormatTime(data.EndTime, { WithWrittenDate = true })}`
				)
				AddLog("Script", {
					Text = `Applied TimeBan on {plr.Name}`;
					Desc = `Ban reason: {reason}`;
				})
			end
		end)

		Process.Init = nil
		AddLog("Script", "Processing Module Initialized")
	end;

	local function RunAfterPlugins()
		local existingPlayers = service.Players:GetPlayers()

		--// Events
		service.RbxEvent(service.Players.PlayerAdded, service.EventTask("PlayerAdded", Process.PlayerAdded))
		service.RbxEvent(service.Players.PlayerRemoving, service.EventTask("PlayerRemoving", Process.PlayerRemoving))

		--// Load client onto existing players
		if existingPlayers then
			for _, p in existingPlayers do
				Core.LoadExistingPlayer(p)
			end
		end

		service.TrackTask("Thread: ChatCharacterLimit", function()
			local ChatModules = service.Chat:WaitForChild("ClientChatModules", 5)
			if ChatModules then
				local ChatSettings = ChatModules:WaitForChild("ChatSettings", 5)
				if ChatSettings then
					local success, ChatSettingsModule = pcall(function()
						return require(ChatSettings)
					end)
					if success then
						local NewChatLimit = ChatSettingsModule.MaximumMessageLength
						if NewChatLimit and type(NewChatLimit) == "number" then
							Process.MaxChatCharacterLimit = NewChatLimit
							AddLog("Script", `Chat Character Limit automatically set to {NewChatLimit}`)
						end
					else
						AddLog("Script", "Failed to automatically get ChatSettings Character Limit, ignore if you use a custom chat system")
					end
				end
			end
		end)

		Process.RunAfterPlugins = nil
		AddLog("Script", "Process Module RunAfterPlugins Finished")
	end

	local function newRateLimit(rateLimit, rateKey: any)
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
			local rateCache = cacheLib[rateKey]
			if not rateCache then
				rateCache = {
					Rate = 0;
					Throttle = 0;
					LastUpdated = tick();
					LastThrottled = nil;
				}

				cacheLib[rateKey] = rateCache
			end

			local nowOs = tick()

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
				rateExceeded:fire(rateKey, rateCache.Rate, maxRate)
			end

			if ratePassed and ratePass then
				ratePassed:fire(rateKey, rateCache.Rate, maxRate)
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
		CustomChat = {
			Rates = 10;
			Reset = 1;
		};
		RateLog = {
			Rates = 10;
			Reset = 2;
		};
	}

	local function RateLimit(p: Player, typ)
		local isPlayer = type(p)=="userdata" and p:IsA("Player")
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
		RateLimits = {
			Remote = 0.01;
			Command = 0.1;
			Chat = 0.1;
			CustomChat = 0.1;
			RateLog = 10;
		};

		Remote = function(p: Player, cliData, com, ...)
			local key = tostring(p.UserId)
			local keys = Remote.Clients[key]

			if p and p:IsA("Player") then
				if not com or type(com) ~= "string" or #com > 50 or cliData == "BadMemes" or com == "BadMemes" then
					Anti.Detected(p, "Kick", (tostring(com) ~= "BadMemes" and tostring(com)) or tostring(select(1, ...)))
				elseif cliData and type(cliData) ~= "table" then
					Anti.Detected(p, "Kick", "Invalid Client Data (r10002)")
				else
					local args = {...}
					local rateLimitCheck, _, _, curRemoteRate = RateLimit(p, "Remote")

					if keys then
						keys.LastUpdate = os.time()
						keys.Received += 1

						if type(com) == "string" then
							if com == `{keys.Special}GET_KEY` then
								if keys.LoadingStatus == "WAITING_FOR_KEY" then
									Remote.Fire(p, `{keys.Special}GET_KEY`, keys.Key)
									keys.LoadingStatus = "LOADING"
									keys.RemoteReady = true

									AddLog("Script", `{p.Name} requested client keys`)
								end

								AddLog("RemoteFires", {
									Text = `{p.Name} requested key from server`,
									Desc = "Player requested key from server",
									Player = p;
								})
							elseif rateLimitCheck and string.len(com) <= Remote.MaxLen then
								local comString = Decrypt(com, keys.Key, keys.Cache)
								local command = (cliData.Mode == "Get" and Remote.Returnables[comString]) or Remote.Commands[comString]

								AddLog("RemoteFires", {
									Text = `{tostring(p)} fired {comString}; Arg1: {tostring(args[1])}`;
									Desc = `Player fired remote command {comString}; {Functions.ArgsToString(args)}`;
									Player = p;
								})

								if command then
									local rets = {TrackTask(`Remote: {p.Name}: {tostring(comString)}`, command, p, args)}
									if not rets[1] then
										logError(p, `{tostring(comString)}: {tostring(rets[2])}`)
									else
										return {unpack(rets, 2)}
									end
								else
									Anti.Detected(p, "Kick", "Invalid Remote Data (r10004)")
								end
							elseif rateLimitCheck and RateLimit(p, "RateLog") then
								Anti.Detected(p, "Log", `Firing RemoteEvent too quickly (>Rate: {curRemoteRate}/sec)`);
								warn(`{p.Name} is firing Adonis's RemoteEvent too quickly (>Rate: {curRemoteRate}/sec)`);
							end
						else
							Anti.Detected(p, "Log", "Out of Sync (r10005)")
						end
					end
				end
			end
		end;

		Command = function(p: Player, msg: string, opts, noYield: boolean)
			opts = opts or {}

			if #msg > Process.MsgStringLimit and type(p) == "userdata" and p:IsA("Player") and not Admin.CheckAdmin(p) then
				msg = string.sub(msg, 1, Process.MsgStringLimit)
			end

			msg = Functions.Trim(msg)

			if string.match(msg, Settings.BatchKey) then
				for cmd in string.gmatch(msg, `[^{Settings.BatchKey}]+`) do
					cmd = Functions.Trim(cmd)

					local waiter = `{Settings.PlayerPrefix}wait`
					if string.sub(string.lower(cmd), 1, #waiter) == waiter then
						local num = tonumber(string.sub(cmd, #waiter + 1))

						if num then
							task.wait(tonumber(num))
						end
					else
						Process.Command(p, cmd, opts, false)
					end
				end
			else
				local pData = opts.PlayerData or (p and Core.GetPlayer(p))
				msg = (pData and Admin.AliasFormat(pData.Aliases, msg)) or msg

				if string.match(msg, Settings.BatchKey) then
					return Process.Command(p, msg, opts, false)
				end

				local index, command, matched = Admin.GetCommand(msg)
				if not command then
					if opts.Check then
						Remote.MakeGui(p, "Output", {
							Title = "Output";
							Message = if Settings.SilentCommandDenials
								then `'{msg}' is either not a valid command, or you do not have permission to run it.`
								else `'{msg}' is not a valid command.`;
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
								then `'{msg}' is either not a valid command, or you do not have permission to run it.`
								else `You do not have permission to run '{msg}'.`
						})
					end
					return
				end

				local cmdArgs = command.Args or command.Arguments
				local argString = string.match(msg, `^.-{Settings.SplitKey}(.+)`) or ""
				local args = (opts.Args or opts.Arguments) or (#cmdArgs > 0 and Functions.Split(argString, Settings.SplitKey, #cmdArgs)) or {}

				local taskName = `Command :: {p.Name} : ({msg})`

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

				if opts.CrossServer or (not isSystem and not opts.DontLog) then
					AddLog("Commands", {
						Text = `((opts.CrossServer and "[CRS_SERVER] ") or "")}{p.Name}`;
						Desc = `{matched}{Settings.SplitKey}{table.concat(args, Settings.SplitKey)}`;
						Player = p;
					})

					if Settings.ConfirmCommands then
						Functions.Hint(`Executed Command: [ {msg} ]`, {p})
					end
				end

				if noYield then
					taskName = `Thread: {taskName}`
				end

				Admin.UpdateCooldown(pDat, command)
				local ran, cmdError = TrackTask(taskName, command.Function, p, args, {
					PlayerData = pDat,
					Options = opts
				})

				if not opts.IgnoreErrors then
					if type(cmdError) == "string" then
						AddLog("Errors", `[{matched}] {cmdError}`)

						cmdError = cmdError:match("%d: (.+)$") or cmdError

						if not isSystem then
							Remote.MakeGui(p, "Output", {
								Message = cmdError,
							})
						end
					elseif cmdError ~= nil and cmdError ~= true and not isSystem then
						Remote.MakeGui(p, "Output", {
							Message = `There was an error but the error was not a string? : {tostring(cmdError)}`;
						})
					end
				end

				service.Events.CommandRan:Fire(p, {
					Message = msg,
					Matched = matched,
					Args = args,
					Command = command,
					Index = index,
					Success = ran,
					Error = if type(cmdError) == "string" then cmdError else nil,
					Options = opts,
					PlayerData = pDat
				})
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

		CustomChat = function(p: Player, a, b: string, canCross: boolean)
			local didPassRate, _, _, curRate, _ = RateLimit(p, "CustomChat")

			if didPassRate and not Admin.IsMuted(p) then
				if type(a) == "string" then
					a = string.sub(a, 1, Process.MsgStringLimit)
				end

				if b == "Cross" then
					if canCross and Admin.CheckAdmin(p) then
						Core.CrossServer("ServerChat", {Player = p.Name, Message = a})
					end
				else
					local target = `{Settings.SpecialPrefix}all`
					if not b then
						b = 'Global'
					end
					if not service.Players:FindFirstChild(p.Name) then
						b='Nil'
					end
					if string.sub(a,1,1)=='@' then
						b='Private'
						target,a=string.match(a,'@(.%S+) (.+)')
						Remote.Send(p,'Function','SendToChat',p,a,b)
					elseif string.sub(a,1,1)=='#' then
						if string.sub(a,1,7)=='#ignore' then
							target=string.sub(a,9)
							b='Ignore'
						end
						if string.sub(a,1,9)=='#unignore' then
							target=string.sub(a,11)
							b='UnIgnore'
						end
					end

					for _, v in service.GetPlayers(p, target, {
						DontError = true;
						})
					do
						a = service.Filter(a, p, v)
						if p.Name == v.Name and b ~= "Private" and b ~= "Ignore" and b ~= "UnIgnore" then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == "Global" then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == "Team" and p.TeamColor == v.TeamColor then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == "Local" and p:DistanceFromCharacter(v.Character.Head.Position) < 80 then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == "Admins" and Admin.CheckAdmin(p) then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == "Private" and v.Name ~= p.Name then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == "Nil" then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						end
					end
				end

				service.Events.CustomChat:Fire(p,a,b)
			elseif not didPassRate and RateLimit(p, "RateLog") then
				Anti.Detected(p, "Log", `CustomChatting too quickly (>Rate: {curRate}/sec)`)
				warn(`{p.Name} is CustomChatting too quickly (>Rate: {curRate}/sec)`)
			end
		end;

		Chat = function(p: Player, msg: string)
			local didPassRate, _, _, curRate, _ = RateLimit(p, "Chat")
			if didPassRate then
				local isMuted = Admin.IsMuted(p);
				if utf8.len(utf8.nfcnormalize(msg)) > Process.MaxChatCharacterLimit and not Admin.CheckAdmin(p) then
					Anti.Detected(p, "Kick", "Chatted message over the maximum character limit")
				elseif not isMuted then
					msg = string.sub(msg, 1, Process.MsgStringLimit)
					local filtered = service.LaxFilter(msg, p)

					AddLog(Logs.Chats, {
						Text = `{p.Name}: {tostring(filtered)}`;
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
				elseif isMuted then
					msg = string.sub(msg, 1, Process.MsgStringLimit);
					local filtered = service.LaxFilter(msg, p)
					AddLog(Logs.Chats, {
						Text = `[MUTED] {p.Name}: {tostring(filtered)}`;
						Desc = tostring(filtered);
						Player = p;
					})
				end
			elseif not didPassRate and RateLimit(p, "RateLog") then
				Anti.Detected(p, "Log", `Chatting too quickly (>Rate: {curRate}/sec)`)
				warn(`{p.Name} is chatting too quickly (>Rate: {curRate}/sec)`)
			end
		end;

		PlayerAdded = function(p: Player)
			AddLog("Script", `Doing PlayerAdded Event for {p.Name}`)

			local key = tostring(p.UserId)
			local keyData = {
				Player = p;
				Key = Functions.GetRandom();
				Cache = {};
				Sent = 0;
				Received = 0;
				LastUpdate = os.time();
				FinishedLoading = false;
				LoadingStatus = "WAITING_FOR_KEY";
			}

			Core.PlayerData[key] = nil
			Remote.Clients[key] = keyData

			local ran, err = Pcall(function()
				Routine(function()
					if Anti.UserSpoofCheck(p) then
						Remote.Clients[key] = nil;
						Anti.Detected(p, "kick", "Username Spoofing");
					end
				end)

				local level = Admin.GetLevel(p)
				local banned, reason = Admin.CheckBan(p)

				if banned then
					Remote.Clients[key] = nil;
					p:Kick(`{Variables.BanMessage} | Reason: {(reason or "No reason provided")}`)
					return "REMOVED"
				end

				if Variables.ServerLock and level < 1 then
					Remote.Clients[key] = nil;
					p:Kick(Variables.LockMessage or "::Adonis::\nServer Locked")
					return "REMOVED"
				end

				if Variables.Whitelist.Enabled then
					local listed = false

					local CheckTable = Admin.CheckTable
					for _, list in Variables.Whitelist.Lists do
						if CheckTable(p, list) then
							listed = true
							break;
						end
					end

					if not listed and level == 0 then
						Remote.Clients[key] = nil;
						p:Kick(Variables.LockMessage or "::Adonis::\nWhitelist Enabled")
						return "REMOVED"
					end
				end
			end)

			if not ran then
				AddLog("Errors", `{p.Name} PlayerAdded Failed: {tostring(err)}`)
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
					Text = p.Name;
					Desc = `{p.Name} joined the server`;
					Player = p;
				})

				--// Get chats
				p.Chatted:Connect(function(msg)
					ran, err = TrackTask(`{p.Name} Chatted`, Process.Chat, p, msg)
					if not ran then
						logError(err);
					end
				end)

				--// Character added
				p.CharacterAdded:Connect(function(...)
					ran, err = TrackTask(`{p.Name} CharacterAdded`, Process.CharacterAdded, p, ...)
					if not ran then
						logError(err);
					end
				end)

				task.delay(600, function()
					if p.Parent and Core.PlayerData[key] and Remote.Clients[key] and Remote.Clients[key] == keyData and keyData.LoadingStatus ~= "READY" then
						AddLog("Script", {
							Text = `{p.Name} Failed to Load`,
							Desc = `{tostring(keyData.LoadingStatus)}: Client failed to load in time (10 minutes?)`,
							Player = p;
						});
						--Anti.Detected(p, "kick", "Client failed to load in time (10 minutes?)");
					end
				end)
			elseif ran and err ~= "REMOVED" then
				Anti.RemovePlayer(p, "\n:: Adonis ::\nLoading Error [Missing player, keys, or removed]")
			end
		end;

		PlayerRemoving = function(p)
			local data = Core.GetPlayer(p)
			local key = tostring(p.UserId)

			service.Events.PlayerRemoving:Fire(p)

			task.delay(1, function()
				if not service.Players:GetPlayerByUserId(p.UserId) then
					Core.PlayerData[key] = nil
				end
			end)

			AddLog("Script", {
				Text = `Triggered PlayerRemoving for {p.Name}`;
				Desc = "Player left the game (PlayerRemoving)";
				Player = p;
			})

			AddLog("Leaves", {
				Text = p.Name;
				Desc = `{p.Name} left the server`;
				Player = p;
			})

			Core.SavePlayerData(p, data)

			Variables.TrackingTable[p.Name] = nil
			for otherPlrName, trackTargets in Variables.TrackingTable do
				if trackTargets[p] then
					trackTargets[p] = nil
					local otherPlr = service.Players:FindFirstChild(otherPlrName)
					if otherPlr then
						task.defer(Remote.RemoveLocal, otherPlr, `{p.Name}Tracker`)
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
			local level = Admin.GetLevel(p)
			local key = tostring(p.UserId)

			--// Fire player added
			service.Events.PlayerAdded:Fire(p)
			AddLog("Script", {
				Text = `{p.Name} finished loading`;
				Desc = "Client finished loading";
			})

			--// Run OnJoin commands
			for i,v in Settings.OnJoin do
				TrackTask(`Thread: OnJoin_Cmd: {tostring(v)}`, Admin.RunCommandAsPlayer, v, p)
				AddLog("Script", {
					Text = `OnJoin: Executed {tostring(v)}`;
					Desc = `Executed OnJoin command; {tostring(v)}`
				})
			end

			--// Start keybind listener
			Remote.Send(p, "Function", "KeyBindListener", PlayerData.Keybinds or {})

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
				if Settings.AntiSpeed then
					Remote.Send(p, "LaunchAnti", "Speed", {
						Speed = tostring(60.5 + math.random(9e8)/9e8)
					})
				end

				if Settings.Detection then
					Remote.Send(p, "LaunchAnti", "MainDetection")
				end

				if Settings.AntiBuildingTools then
					Remote.Send(p, "LaunchAnti", "AntiTools", {BTools = true})
				end
			end

			--// Finish things up
			if Remote.Clients[key] then
				Remote.Clients[key].FinishedLoading = true
				if p.Character and p.Character.Parent == workspace then
					local ran, err = TrackTask(`{p.Name} CharacterAdded`, Process.CharacterAdded, p, p.Character)
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

				if Settings.Console and (not Settings.Console_AdminsOnly or level > 0) then
					Remote.MakeGui(p, "Console")
				end

				if Settings.HelpButton then
					Remote.MakeGui(p, "HelpButton")
				end

				if level > 0 then
					local oldVer = (level > 300) and Core.GetData("VersionNumber")
					local newVer = (level > 300) and tonumber(string.match(server.Changelog[1], "Version: (.*)"))

					if Settings.Notification then
						Remote.MakeGui(p, "Notification", {
							Title = "Welcome.";
							Message = "Click here for commands.";
							Icon = server.MatIcons["Verified user"];
							Time = 15;
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`);
						})

						task.wait(1)

						if oldVer and newVer and newVer > oldVer then
							Remote.MakeGui(p, "Notification", {
								Title = "Updated!";
								Message = "Click to view the changelog.";
								Icon = server.MatIcons.Description;
								Time = 10;
								OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}changelog')`);
							})
						end

						task.wait(1)

						if level > 300 and Settings.DataStoreKey == Defaults.Settings.DataStoreKey then
							Remote.MakeGui(p, "Notification", {
								Title = "Warning!";
								Message = "Using default datastore key!";
								Icon = server.MatIcons.Description;
								Time = 10;
								OnClick = Core.Bytecode([[
									local window = client.UI.Make("Window", {
										Title = "How to change the DataStore key";
										Size = {700,300};
										Icon = "rbxassetid://7510994359";
									})

									window:Add("ImageLabel", {
										Image = "rbxassetid://1059543904";
									})

									window:Ready()
								]]);
							})
						end
					end

					if newVer then
						Core.SetData("VersionNumber", newVer)
					end
				end

				for v: Player in Variables.IncognitoPlayers do
					if v == p or v.Parent == service.Players then
						continue
					end

					Remote.LoadCode(p, [[
						local plr = service.Players:GetPlayerByUserId(]] .. v.UserId .. [[)
						if plr then
							if not table.find(service.IncognitoPlayers, plr) then
								table.insert(service.IncognitoPlayers, plr)
							end

							plr:Remove()
						end
					]])
				end
			end
		end;

		CharacterAdded = function(p: Player, char: Model, ...)
			local key = tostring(p.UserId)
			local keyData = Remote.Clients[key]

			if keyData then
				keyData.PlayerLoaded = true
			end

			task.wait(1 / 60)
			if char and keyData and keyData.FinishedLoading then
				local level = Admin.GetLevel(p)

				--// Wait for UI stuff to finish
				task.wait(1)
				if not p:FindFirstChildWhichIsA("PlayerGui") then
					p:WaitForChild("PlayerGui", 9e9)
				end
				Remote.Get(p,"UIKeepAlive")

				--// GUI loading
				if Variables.NotifMessage then
					Remote.MakeGui(p, "Notif", {
						Message = Variables.NotifMessage
					})
				end
				if Settings.TopBarShift then
					Remote.MakeGui(p, "TopBar")
				end

				if level < 1 then
					if Settings.AntiNoclip then
						Remote.Send(p, "LaunchAnti", "HumanoidState")
					end
				end

				task.spawn(Functions.Donor, p)

				--// Fire added event
				service.Events.CharacterAdded:Fire(p, char, ...)

				--// Run OnSpawn commands
				for _, v in Settings.OnSpawn do
					TrackTask(`Thread: OnSpawn_Cmd: {tostring(v)}`, Admin.RunCommandAsPlayer, v, p)
					AddLog("Script", {
						Text = `OnSpawn: Executed {tostring(v)}`;
						Desc = `Executed OnSpawn command; {tostring(v)}`;
					})
				end

				if
					server.Commands.Track
					and char:WaitForChild("Head", 5)
					and char:WaitForChild("HumanoidRootPart", 2)
				then
					for otherPlrName, trackTargets in Variables.TrackingTable do
						if trackTargets[p] then
							server.Commands.Track.Function(service.Players[otherPlrName], {`@{p.Name}`, "true"})
						end
					end
				end
			end
		end;

		NetworkAdded = function(cli)
			task.wait(0.25)

			local p = cli:GetPlayer()

			if p then
				Core.Connections[cli] = p

				AddLog("Script", {
					Text = `{p.Name} connected`;
					Desc = `{p.Name} successfully established a connection with the server`;
					Player = p;
				})
			else
				AddLog("Script", {
					Text = "<UNKNOWN> connected";
					Desc = "An unknown user successfully established a connection with the server";
				})
			end

			service.Events.NetworkAdded:Fire(cli)
		end;

		NetworkRemoved = function(cli)
			local p = cli:GetPlayer() or Core.Connections[cli]

			Core.Connections[cli] = nil

			if p then
				AddLog("Script", {
					Text = `{p.Name} disconnected`;
					Desc = `{p.Name} disconnected from the server`;
					Player = p;
				})
			else
				AddLog("Script", {
					Text = "<UNKNOWN> disconnected";
					Desc = "An unknown user disconnected from the server";
				})
			end

			service.Events.NetworkRemoved:Fire(cli)
		end;
	};
end
