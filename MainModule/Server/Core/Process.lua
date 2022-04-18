server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Processing
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server
	local service = Vargs.Service

	local Commands, Decrypt, Encrypt, UnEncrypted, AddLog, TrackTask, Pcall
	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Defaults
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
		Defaults = server.Defaults

		Commands = Remote.Commands
		Decrypt = Remote.Decrypt
		Encrypt = Remote.Encrypt
		UnEncrypted = Remote.UnEncrypted
		AddLog = Logs.AddLog
		TrackTask = service.TrackTask
		Pcall = server.Pcall

		--// NetworkServer Events
		if service.NetworkServer then
			service.RbxEvent(service.NetworkServer.ChildAdded, server.Process.NetworkAdded)
			service.RbxEvent(service.NetworkServer.DescendantRemoving, server.Process.NetworkRemoved)
		end

		Process.Init = nil
		AddLog("Script", "Processing Module Initialized")
	end;

	local function RunAfterPlugins(data)
		local existingPlayers = service.Players:GetPlayers()

		--// Events
		service.RbxEvent(service.Players.PlayerAdded, service.EventTask("PlayerAdded", Process.PlayerAdded))
		service.RbxEvent(service.Players.PlayerRemoving, service.EventTask("PlayerRemoving", Process.PlayerRemoving))

		--// Load client onto existing players
		if existingPlayers then
			for i, p in ipairs(existingPlayers) do
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
							AddLog("Script", "Chat Character Limit automatically set to " .. NewChatLimit)
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



	local RateLimiter = {
		Remote = {};
		Command = {};
		Chat = {};
		CustomChat = {};
		RateLog = {};
	}

	local limitViolations = {
		Remote = {};
		Command = {};
		Chat = {};
		CustomChat = {};
		RateLog = {};
	}

	local function RateLimit(p, typ)
		if p and type(p) == "userdata" and p:IsA("Player") then
			if not RateLimiter[typ][p.UserId] then
				RateLimiter[typ][p.UserId] = os.clock()
				limitViolations[typ][p.UserId] = 1
			elseif RateLimiter[typ][p.UserId] < os.clock() + server.Process.RateLimits[typ] * server.Process.RatelimitSampleMultiplier then
				RateLimiter[typ][p.UserId] = os.clock()
				limitViolations[typ][p.UserId] = 0
			else
				limitViolations[typ][p.UserId] += 1
			end

			return limitViolations[typ][p.UserId] > server.Process.RatelimitSampleMultiplier
		else
			return true
		end
	end

	server.Process = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		RateLimit = RateLimit;
		MsgStringLimit = 500; --// Max message string length to prevent long length chat spam server crashing (chat & command bar); Anything over will be truncated;
		MaxChatCharacterLimit = 250; --// Roblox chat character limit; The actual limit of the Roblox chat's textbox is 200 characters; I'm paranoid so I added 50 characters; Users should not be able to send a message larger than that;
		RatelimitSampleMultiplier = 4; --// What is the multiplication for the violations count, lower levels can be false fired (like it currently does), but higher levels have issues with not detecting at all, so its good to have between 2 and 10
		RateLimits = {
			Remote = 0.01;
			Command = 0.1;
			Chat = 0.1;
			CustomChat = 0.1;
			RateLog = 10;
		};

		Remote = function(p, cliData, com, ...)
			local key = tostring(p.UserId)
			local keys = Remote.Clients[key]

			if p and p:IsA("Player") then
				if not com or type(com) ~= "string" or #com > 50 or cliData == "BadMemes" or com == "BadMemes" then
					Anti.Detected(p, "Kick", (tostring(com) ~= "BadMemes" and tostring(com)) or tostring(select(1, ...)))
				elseif cliData and type(cliData) ~= "table" then
					Anti.Detected(p, "Kick", "Invalid Client Data (r10002)")
					--elseif cliData and keys and cliData.Module ~= keys.Module then
					--	Anti.Detected(p, "Kick", "Invalid Client Module (r10006)")
				else
					local args = {...}
					local rateLimitCheck = RateLimit(p, "Remote")

					if keys then
						keys.LastUpdate = os.time()
						keys.Received += 1

						if type(com) == "string" then
							if com == keys.Special.."GET_KEY" then
								if keys.LoadingStatus == "WAITING_FOR_KEY" then
									Remote.Fire(p,keys.Special.."GIVE_KEY",keys.Key)
									keys.LoadingStatus = "LOADING"
									keys.RemoteReady = true

									AddLog("Script", string.format("%s requested client keys", p.Name))
								--else
									--Anti.Detected(p, "kick","Communication Key Error (r10003)")
								end

								AddLog("RemoteFires", {
									Text = p.Name.." requested key from server",
									Desc = "Player requested key from server",
									Player = p;
								})
							elseif UnEncrypted[com] then
								AddLog("RemoteFires", {
									Text = p.Name.." fired "..tostring(com),
									Desc = "Player fired unencrypted remote command "..com,
									Player = p;
								})

								return {UnEncrypted[com](p,...)}
							elseif rateLimitCheck and string.len(com) <= Remote.MaxLen then
								local comString = Decrypt(com, keys.Key, keys.Cache)
								local command = (cliData.Mode == "Get" and Remote.Returnables[comString]) or Remote.Commands[comString]

								AddLog("RemoteFires", {
									Text = p.Name.." fired "..tostring(comString).."; Arg1: "..tostring(args[1]),
									Desc = "Player fired remote command "..comString.."; "..Functions.ArgsToString(args),
									Player = p;
								})

								if command then
									local rets = {TrackTask("Remote: ".. p.Name ..": ".. tostring(comString), command, p, args)}
									if not rets[1] then
										logError(p, tostring(comString) .. ": ".. tostring(rets[2]))
									else
										return {unpack(rets, 2)}
									end
								else
									Anti.Detected(p, "Kick", "Invalid Remote Data (r10004)")
								end
							elseif rateLimitCheck and RateLimit(p, "RateLog") then
								Anti.Detected(p, "Log", string.format("Firing RemoteEvent too quickly (>Rate: %s/sec)", 1/Process.RateLimits.Remote));
								warn(string.format("%s is firing Adonis's RemoteEvent too quickly (>Rate: %s/sec)", p.Name, 1/Process.RateLimits.Remote));
							end
						else
							Anti.Detected(p, "Log", "Out of Sync (r10005)")
						end
					end
				end
			end
		end;

		Command = function(p, msg, opts, noYield)
			opts = opts or {}

			if Admin.IsBlacklisted(p) then
				return false
			end

			if #msg > Process.MsgStringLimit and type(p) == "userdata" and p:IsA("Player") and not Admin.CheckAdmin(p) then
				msg = string.sub(msg, 1, Process.MsgStringLimit);
			end

			msg = Functions.Trim(msg)

			if string.match(msg, Settings.BatchKey) then
				for cmd in string.gmatch(msg,'[^'..Settings.BatchKey..']+') do
					cmd = Functions.Trim(cmd)

					local waiter = Settings.PlayerPrefix.."wait"
					if string.sub(string.lower(cmd), 1, #waiter) == waiter then
						local num = string.sub(cmd, #waiter + 1)

						if num and tonumber(num) then
							wait(tonumber(num))
						end
					else
						Process.Command(p, cmd, opts, false)
					end
				end
			else
				local pData = opts.PlayerData or (p and Core.GetPlayer(p));
				msg = (pData and Admin.AliasFormat(pData.Aliases, msg)) or msg;

				if string.match(msg, Settings.BatchKey) then
					Process.Command(p, msg, opts, false)
				else
					local index, command, matched = Admin.GetCommand(msg)

					if not command then
						if opts.Check then
							Remote.MakeGui(p, "Output", {
								Title = "Output";
								Message = msg .. " is not a valid command.";
							})
							return
						end
					else
						local allowed = false
						local isSystem = false

						local pDat = {
							Player = opts.Player or p;
							Level = opts.AdminLevel or Admin.GetLevel(p);
							isDonor = opts.IsDonor or (Admin.CheckDonor(p) and (Settings.DonorCommands or command.AllowDonors));
						}

						if opts.isSystem or p == "SYSTEM" then
							isSystem = true
							allowed = true
							p = p or "SYSTEM"
						else
							allowed = Admin.CheckPermission(pDat, command)
						end

						if opts.CrossServer and command.CrossServerDenied then
							allowed = false;
						end

						if allowed and Variables.IsStudio and command.NoStudio then
							Remote.MakeGui(p, "Output", {
								Title = "";
								Message = "This command cannot be used in Roblox Studio.";
								Color = Color3.new(1, 0, 0);
							})
							return
						end

						if allowed and opts.Chat and command.Chattable == false then
							Remote.MakeGui(p, "Output", {
								Title = "";
								Color = Color3.new(1, 0, 0);
								Message = "Specified command not permitted as chat message (Command not chattable)";
							})

							return
						end

						if allowed then
							if not command.Disabled then
								local argString = string.match(msg, "^.-"..Settings.SplitKey..'(.+)') or ""

								local cmdArgs = command.Args or command.Arguments
								local args = (opts.Args or opts.Arguments) or (#cmdArgs > 0 and Functions.Split(argString, Settings.SplitKey, #cmdArgs)) or {}

								local taskName = "Command:: ".. p.Name ..": ("..msg..")"

								if #args > 0 and not isSystem and command.Filter or opts.Filter then
									local safe = {
										plr = true;
										plrs = true;
										username = true;
										usernames = true;
										players = true;
										player = true;
										users = true;
										user = true;
										brickcolor = true;
									}

									for i, arg in pairs(args) do
										if not (cmdArgs[i] and safe[string.lower(cmdArgs[i])]) then
											args[i] = service.LaxFilter(arg, p)
										end
									end
								end

								if opts.CrossServer or (not isSystem and not opts.DontLog) then
									AddLog("Commands", {
										Text = ((opts.CrossServer and "[CRS_SERVER] ") or "") .. p.Name;
										Desc = matched .. Settings.SplitKey .. table.concat(args, Settings.SplitKey);
										Player = p;
									})

									if Settings.ConfirmCommands then
										Functions.Hint("Executed Command: [ "..msg.." ]", {p})
									end
								end

								if noYield then
									taskName = "Thread: " .. taskName
								end

								local ran, error = TrackTask(taskName,
									command.Function,
									p,
									args,
									{
										PlayerData = pDat,
										Options = opts
									}
								)
								if not opts.IgnoreErrors then
									if error and type(error) == "string" then
										AddLog("Errors", (command.Commands[1] or "Unknown command?") .. " " .. error)

										error = (error and string.match(error, ":(.+)$")) or error or "Unknown error"

										if not isSystem then
											Remote.MakeGui(p, 'Output', {
												Title = '',
												Message = error,
												Color = Color3.new(1, 0, 0)
											})
										end
									elseif error and type(error) ~= "string" and error ~= true then
										if not isSystem then
											Remote.MakeGui(p,"Output", {
												Title = "";
												Message = "There was an error but the error was not a string? "..tostring(error);
												Color = Color3.new(1, 0, 0);
											})
										end
									end
								end

								service.Events.CommandRan:Fire(p, {
									Message = msg,
									Matched = matched,
									Args = args,
									Command = command,
									Index = index,
									Success = ran,
									Error = error,
									Options = opts,
									PlayerData = pDat
								})
							else
								if not isSystem and not opts.NoOutput then
									Remote.MakeGui(p, "Output", {
										Title = "";
										Message = "This command has been disabled.";
										Color = Color3.new(1, 0, 0);
									})
								end
							end
						else
							if not isSystem and not opts.NoOutput then
								Remote.MakeGui(p, "Output", {
									Title = "";
									Message = "You are not allowed to run " .. msg;
									Color = Color3.new(1, 0, 0);
								})
							end

							return;
						end
					end
				end
			end
		end;

		CrossServerChat = function(data)
			if data then
				for _, v in pairs(service.GetPlayers()) do
					if Admin.GetLevel(v) > 0 then
						Remote.Send(v, "handler", "ChatH
