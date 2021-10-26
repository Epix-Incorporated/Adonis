server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Processing
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Commands, Decrypt, Encrypt, UnEncrypted, AddLog, TrackTask
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

		--// NetworkServer Events
		if service.NetworkServer then
			service.RbxEvent(service.NetworkServer.ChildAdded, server.Process.NetworkAdded)
			service.RbxEvent(service.NetworkServer.DescendantRemoving, server.Process.NetworkRemoved)
		end

		Process.Init = nil;
		AddLog("Script", "Processing Module Initialized")
	end;

	local function RunAfterPlugins(data)
		local existingPlayers = service.Players:GetPlayers();

		--// Events
		service.RbxEvent(service.Players.PlayerAdded, service.EventTask("PlayerAdded", Process.PlayerAdded))
		service.RbxEvent(service.Players.PlayerRemoving, service.EventTask("PlayerRemoving", Process.PlayerRemoving))

		--[[
			-- Not used in adonis anymore
			service.RbxEvent(service.Workspace.ChildAdded, Process.WorkspaceChildAdded)
			service.RbxEvent(service.LogService.MessageOut, Process.LogService)
			service.RbxEvent(service.ScriptContext.Error, Process.ErrorMessage)
		]]

		--// Load client onto existing players
		if existingPlayers then
			for i,p in ipairs(existingPlayers) do
				Core.LoadExistingPlayer(p);
			end
		end

		service.TrackTask("Thread: ChatCharacterLimit", function()
			local ChatModules = service.Chat:WaitForChild("ClientChatModules",5)
			if ChatModules then
				local ChatSettings = ChatModules:WaitForChild("ChatSettings",5)
				if ChatSettings then
					local success, ChatSettingsModule = pcall(function()
						return require(ChatSettings)
					end)
					if success then
						local NewChatLimit = ChatSettingsModule.MaximumMessageLength
						if NewChatLimit and type(NewChatLimit) == 'number' then
							Process.MaxChatCharacterLimit = NewChatLimit
							AddLog("Script", "Chat Character Limit automatically set to " .. NewChatLimit);
						end
					else
						AddLog("Script", "Failed to automatically get ChatSettings Character Limit, ignore if you use a custom chat system");
					end
				end
			end
		end)

		Process.RunAfterPlugins = nil;
		AddLog("Script", "Process Module RunAfterPlugins Finished");
	end



	local RateLimiter = {
		Remote = {};
		Command = {};
		Chat = {};
		CustomChat = {};
		RateLog = {};
	}

	local function RateLimit(p, typ)
		if p and type(p) == "userdata" and p:IsA("Player") then
			local ready = (not RateLimiter[typ][p.UserId] or (RateLimiter[typ][p.UserId] and time() - RateLimiter[typ][p.UserId] >= server.Process.RateLimits[typ]));
			RateLimiter[typ][p.UserId] = time();
			return ready;
		else
			return true;
		end
	end

	server.Process = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		RateLimit = RateLimit;
		MsgStringLimit = 500; --// Max message string length to prevent long length chat spam server crashing (chat & command bar); Anything over will be truncated;
		MaxChatCharacterLimit = 250; --// Roblox chat character limit; The actual limit of the Roblox chat's textbox is 200 characters; I'm paranoid so I added 50 characters; Users should not be able to send a message larger than that;
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
						keys.Received = keys.Received + 1

						if type(com) == "string" then
							if com == keys.Special.."GET_KEY" then
								if keys.LoadingStatus == "WAITING_FOR_KEY" then
									Remote.Fire(p,keys.Special.."GIVE_KEY",keys.Key)
									keys.LoadingStatus = "LOADING"
									keys.RemoteReady = true

									Logs:AddLog("Script", string.format("%s requested client keys", p.Name))
								else
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
										return {unpack(rets, 2)};
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
							Remote.MakeGui(p, 'Output', {
								Title = 'Output',
								Message = msg .. ' is not a valid command.'
							})
							return;
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

						if allowed and opts.Chat and command.Chattable == false then
							Remote.MakeGui(p, 'Output', {
								Title = '',
								Color = Color3.new(1,0,0),
								Message = "Specified command not permitted as chat message (Command not chattable)"
							})

							return
						end

						if allowed then
							if not command.Disabled then
								local argString = string.match(msg, "^.-"..Settings.SplitKey..'(.+)') or ''

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
									AddLog("Commands",{
										Text = ((opts.CrossServer and "[CRS_SERVER] ") or "") .. p.Name,
										Desc = matched .. Settings.SplitKey .. table.concat(args, Settings.SplitKey),
										Player = p;
									})

									if Settings.ConfirmCommands then
										Functions.Hint('Executed Command: [ '..msg..' ]', {p})
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
										AddLog("Errors", (command.Commands[1] or 'Unknown command?') .. " " .. error)

										error = (error and string.match(error, ":(.+)$")) or error or "Unknown error"

										if not isSystem then
											Remote.MakeGui(p, 'Output', {
												Title = '',
												Message = error,
												Color = Color3.new(1,0,0)
											})
										end
									elseif error and type(error) ~= "string" then
										if not isSystem then
											Remote.MakeGui(p,'Output', {
												Title = '';
												Message = "There was an error but the error was not a string? "..tostring(error),
												Color = Color3.new(1,0,0)
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
									Remote.MakeGui(p, 'Output', {
										Title = '';
										Message = 'This command has been disabled.';
										Color = Color3.new(1,0,0)
									})
								end
							end
						else
							if not isSystem and not opts.NoOutput then
								Remote.MakeGui(p,'Output', {
									Title = '',
									Message = 'You are not allowed to run ' .. msg,
									Color = Color3.new(1,0,0)
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
				for i,v in next,service.GetPlayers() do
					if Admin.GetLevel(v) > 0 then
						Remote.Send(v,"handler", "ChatHandler", data.Player, data.Message, "Cross")
					end
				end
			end
		end;

		CustomChat = function(p, a, b, canCross)
			if RateLimit(p, "CustomChat") and not Admin.IsMuted(p) then
				if type(a) == "string" then
					a = string.sub(a, 1, Process.MsgStringLimit);
				end

				if b == "Cross" then
					if canCross and Admin.CheckAdmin(p) then
						Core.CrossServer("ServerChat", {Player = p.Name, Message = a});
						--Core.SetData("CrossServerChat",{Player = p.Name, Message = a})
					end
				else
					local target = Settings.SpecialPrefix..'all'
					if not b then b = 'Global' end
					if not service.Players:FindFirstChild(p.Name) then b='Nil' end
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

					for i,v in pairs(service.GetPlayers(p,target,{
						DontError = true;
						})) do
						--Routine(function()
						local a = service.Filter(a,p,v)
						if p.Name == v.Name and b ~= 'Private' and b ~= 'Ignore' and b ~= 'UnIgnore' then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == "Global" then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == 'Team' and p.TeamColor == v.TeamColor then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == 'Local' and p:DistanceFromCharacter(v.Character.Head.Position)<80 then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == 'Admins' and Admin.CheckAdmin(p) and Admin.CheckAdmin(p) then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == 'Private' and v.Name ~= p.Name then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
						elseif b == 'Nil' then
							Remote.Send(v,"Handler","ChatHandler",p,a,b)
							--[[elseif b == 'Ignore' and v.Name ~= p.Name then
								Remote.Send(v,'AddToTable','IgnoreList',v.Name)
							elseif b == 'UnIgnore' and v.Name ~= p.Name then
								Remote.Send(v,'RemoveFromTable','IgnoreList',v.Name)--]]
						end
						--end)
					end
				end

				service.Events.CustomChat:fire(p,a,b)
			elseif RateLimit(p, "RateLog") then
				Anti.Detected(p, "Log", string.format("CustomChatting too quickly (>Rate: %s/sec)", 1/Process.RateLimits.Chat));
				warn(string.format("%s is CustomChatting too quickly (>Rate: %s/sec)", p.Name, 1/Process.RateLimits.Chat));
			end
		end;

		Chat = function(p, msg)
			if RateLimit(p, "Chat") then
				local isMuted = Admin.IsMuted(p);
				if utf8.len(utf8.nfcnormalize(msg)) > Process.MaxChatCharacterLimit and not Admin.CheckAdmin(p) then
					Anti.Detected(p, "Kick", "Chatted message over the maximum character limit")
				elseif not isMuted then
					local msg = string.sub(msg, 1, Process.MsgStringLimit);
					local filtered = service.LaxFilter(msg, p)

					AddLog(Logs.Chats,{
						Text = p.Name..": " .. tostring(filtered);
						Desc = tostring(filtered);
						Player = p;
					})

					if Settings.ChatCommands then
						if Admin.DoHideChatCmd(p, msg) then
							Remote.Send(p,"Function","ChatMessage","> "..msg,Color3.new(255, 255, 255))
							Process.Command(p,msg,{Chat = true;})
						elseif string.sub(msg,1,3)=="/e " then
							service.Events.PlayerChatted:Fire(p,msg)
							msg = string.sub(msg,4)
							Process.Command(p,msg,{Chat = true;})
						elseif string.sub(msg,1,8)=="/system " then
							service.Events.PlayerChatted:Fire(p,msg)
							msg = string.sub(msg,9)
							Process.Command(p,msg,{Chat = true;})
						else
							service.Events.PlayerChatted:Fire(p,msg)
							Process.Command(p,msg,{Chat = true;})
						end
					else
						service.Events.PlayerChatted:Fire(p,msg)
					end
				elseif isMuted then
					local msg = string.sub(msg, 1, Process.MsgStringLimit);
					local filtered = service.LaxFilter(msg, p)
					AddLog(Logs.Chats,{
						Text = "[MUTED] ".. p.Name ..": "..tostring(filtered);
						Desc = tostring(filtered);
						Player = p;
					})
				end
			elseif RateLimit(p, "RateLog") then
				Anti.Detected(p, "Log", string.format("Chatting too quickly (>Rate: %s/sec)", 1/Process.RateLimits.Chat));
				warn(string.format("%s is chatting too quickly (>Rate: %s/sec)", p.Name, 1/Process.RateLimits.Chat));
			end
		end;

		--[==[
				WorkspaceChildAdded = function(c)
					--[[if c:IsA("Model") then
						local p = service.Players:GetPlayerFromCharacter(c)
						if p then
							service.TrackTask(p.Name..": CharacterAdded", Process.CharacterAdded, p)
						end
					end

					-- Moved to PlayerAdded handler
					--]]
				end;

				LogService = function(Message, Type)
					--service.Events.Output:fire(Message, Type)
				end;

				ErrorMessage = function(Message, Trace, Script)
					--[[if Running then
						service.Events.ErrorMessage:fire(Message, Trace, Script)
						if Message:lower():find("adonis") or Message:find(script.Name) then
							logError(Message)
						end
					end--]]
				end;
		]==]

		PlayerAdded = function(p)
			Logs:AddLog("Script", "Doing PlayerAdded Event for ".. p.Name)

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
				--Special = Core.MockClientKeys and Core.MockClientKeys.Special;
				--Module = Core.MockClientKeys and Core.MockClientKeys.Module;
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

				--p:SetSpecial("Kick", Anti.RemovePlayer)
				--p:SetSpecial("Detected", Anti.Detected)
				--Core.UpdateConnection(p)

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
					p:Kick(Variables.LockMessage or "::Adonis::\nServer Locked")
					return "REMOVED"
				end

				if Variables.Whitelist.Enabled then
					local listed = false

					local CheckTable = Admin.CheckTable
					for listName, list in pairs(Variables.Whitelist.Lists) do
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
				Logs:AddLog("Errors", p.Name .." PlayerAdded Failed: ".. tostring(err))
				warn("~! :: Adonis :: SOMETHING FAILED DURING PLAYERADDED:");
				warn(tostring(err))
			end

			if Remote.Clients[key] then
				Core.HookClient(p)

				AddLog("Script",{
					Text = p.Name .. " loading started";
					Desc = p.Name .. " successfully joined the server";
				})

				AddLog("Joins",{
					Text = p.Name;
					Desc = p.Name.." joined the server";
					Player = p;
				})

				--// Get chats
				p.Chatted:Connect(function(msg)
					local ran,err = TrackTask(p.Name .. "Chatted", Process.Chat, p, msg);
					if not ran then
						logError(err);
					end
				end)

				--// Character added
				p.CharacterAdded:Connect(function(...)
					local ran,err = TrackTask(p.Name .. "CharacterAdded", Process.CharacterAdded, p, ...);
					if not ran then
						logError(err);
					end
				end)

				delay(600, function()
					if p.Parent and Core.PlayerData[key] and Remote.Clients[key] and Remote.Clients[key] == keyData and keyData.LoadingStatus ~= "READY" then
						AddLog("Script", {
							Text = p.Name .. " Failed to Load",
							Desc = tostring(keyData.LoadingStatus)..": Client failed to load in time (10 minutes?)",
							Player = p;
						});
						--Anti.Detected(p, "kick", "Client failed to load in time (10 minutes?)");
					end
				end)
			elseif (ran and err ~= "REMOVED") then
				Anti.RemovePlayer(p, "\n:: Adonis ::\nLoading Error [Missing player, keys, or removed]")
			end
		end;

		PlayerRemoving = function(p)
			local data = Core.GetPlayer(p)
			local key = tostring(p.UserId)

			service.Events.PlayerRemoving:Fire(p)

			spawn(function()
				local level = (p and data.AdminLevel) or 0
				if Settings.AntiNil and level < 1 then
					pcall(function() local p = service.UnWrap(p) p:Kick("Anti Nil") wait() if p then pcall(service.Delete, p) end end)
				end
			end)

			delay(1, function()
				if not service.Players:GetPlayerByUserId(p.UserId) then
					Core.PlayerData[key] = nil
				end
			end)

			Logs.AddLog("Script", {
				Text = string.format("Triggerd PlayerRemoving for %s", p.Name);
				Desc = "Player left the game (PlayerRemoving)";
				Player = p;
			})

			Core.SavePlayerData(p, data)
			return;
		end;

		FinishLoading = function(p)
			local PlayerData = Core.GetPlayer(p)
			local level = Admin.GetLevel(p)
			local key = tostring(p.UserId)

			--// Fire player added
			service.Events.PlayerAdded:Fire(p)
			AddLog("Script", {
				Text = string.format("%s finished loading", p.Name);
				Desc = "Client finished loading";
			})

			--// Run OnJoin commands
			for i,v in pairs(Settings.OnJoin) do
				TrackTask("Thread: OnJoin_Cmd: ".. tostring(v), Admin.RunCommandAsPlayer, v, p)
				AddLog("Script", {
					Text = "OnJoin: Executed "..tostring(v);
					Desc = "Executed OnJoin command; "..tostring(v)
				})
			end

			--// Start keybind listener
			Remote.Send(p, "Function", "KeyBindListener", PlayerData.Keybinds or {})

			--// Load some playerdata stuff
			if PlayerData.Client and type(PlayerData.Client) == "table" then
				if PlayerData.Client.CapesEnabled == true or PlayerData.Client.CapesEnabled == nil then
					Remote.Send(p,"Function","MoveCapes")
				end
				Remote.Send(p,"SetVariables",PlayerData.Client)
			else
				Remote.Send(p,"Function","MoveCapes")
			end

			--// Load all particle effects that currently exist
			Functions.LoadEffects(p)

			--// Load admin or non-admin specific things
			if level<1 then
				if Settings.AntiSpeed then
					Remote.Send(p,"LaunchAnti","Speed",{
						Speed = tostring(60.5+math.random(9e8)/9e8)
					})
				end

				if Settings.Detection then
					Remote.Send(p,"LaunchAnti","MainDetection")
				end

				if Settings.AntiBuildingTools then
					Remote.Send(p,"LaunchAnti","AntiTools", {BTools = true})
				end
			end

			--// Finish things up
			if Remote.Clients[key] then
				Remote.Clients[key].FinishedLoading = true
				if p.Character and p.Character.Parent == service.Workspace then
					--service.Threads.TimeoutRunTask(p.Name..";CharacterAdded",Process.CharacterAdded,60,p)
					local ran, err = TrackTask(p.Name .." CharacterAdded", Process.CharacterAdded, p, p.Character);
					if not ran then
						logError(err)
					end
				end

				if level>0 then
					local oldVer = Core.GetData("VersionNumber");
					local newVer = tonumber(string.match(server.Changelog[1], "Version: (.*)"));

					if Settings.Notification then
						wait(2)

						Remote.MakeGui(p,"Notification",{
							Title = "Welcome.";
							Message = "Click here for commands.";
							Icon = "rbxassetid://7536783953";
							Time = 15;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})

						wait(1)

						if oldVer and newVer and newVer>oldVer and level > 300 then
							Remote.MakeGui(p,"Notification",{
								Title = "Updated!";
								Message = "Click to view the changelog.";
								Icon = "rbxassetid://7495471249";
								Time = 10;
								OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."changelog')");
							})
						end

						wait(1)

						if level > 300 and Settings.DataStoreKey == Defaults.Settings.DataStoreKey then
							Remote.MakeGui(p,"Notification",{
								Title = "Warning!";
								Message = "Using default datastore key!";
								Icon = "rbxassetid://7495468117";
								Time = 10;
								OnClick = Core.Bytecode([[
									local window = client.UI.Make("Window",{
										Title = "How to change the DataStore key";
										Size = {700,300};
										Icon = "rbxassetid://357249130";
									})

									window:Add("ImageLabel",{
										Image = "rbxassetid://1059543904";
									})

									window:Ready()
								]]);
							})
						end
					end

					if newVer then
						Core.SetData("VersionNumber",newVer)
					end
				end

				--// REF_1_ALBRT - 57s_Dxl - 100392_659;
				--// COMP[[CHAR+OFFSET] < INT[0]]
				--// EXEC[[BYTE[N]+BYTE[x]] + ABS[CHAR+OFFSET]]
				--// ELSE[[BYTE[A]+BYTE[x]] + ABS[CHAR+OFFSET]]
				--// VALU -> c_BYTE ; CAT[STR,x,c_BYTE] -> STR ; OUT[STR]]]
				--// [-150x261x247x316x246x243x238x248x302x316x261x247x316x246x234x247x247x302]
				--// END_ReF - 100392_659
			end
		end;

		CharacterAdded = function(p, Character, ...)
			local key = tostring(p.UserId)
			local keyData = Remote.Clients[key];

			if keyData then
				keyData.PlayerLoaded = true;
			end

			wait();
			if Character and keyData and keyData.FinishedLoading then
				local level = Admin.GetLevel(p)

				--// Anti Exploit stuff
				pcall(Anti.CheckNameID, p)

				--// Wait for UI stuff to finish
				wait(1);
				if not p:FindFirstChildWhichIsA("PlayerGui") then
					p:WaitForChild("PlayerGui", 9e9);
				end
				Remote.Get(p,"UIKeepAlive");

				--//GUI loading
				local MakeGui = Remote.MakeGui
				if Variables.NotifMessage then
					MakeGui(p,"Notif",{
						Message = Variables.NotifMessage
					})
				end

				if Settings.Console and (not Settings.Console_AdminsOnly or (Settings.Console_AdminsOnly and level > 0)) then
					MakeGui(p,"Console")
				end

				if Settings.HelpButton then
					MakeGui(p,"HelpButton")
				end

				if Settings.TopBarShift then
					MakeGui(p, "TopBar")
				end

				if Settings.CustomChat then
					MakeGui(p,"Chat")
				end

				if Settings.PlayerList then
					MakeGui(p,"PlayerList")
				end

				if level < 1 then
					if Settings.AntiNoclip then
						Remote.Send(p,"LaunchAnti","HumanoidState")
					end

					if Settings.AntiParanoid then
						Remote.Send(p,"LaunchAnti","Paranoid")
					end
				end

				--// Check muted
				--[=[for ind,admin in pairs(Settings.Muted) do
					if Admin.DoCheck(p,admin) then
						Remote.LoadCode(p,[[service.StarterGui:SetCoreGuiEnabled("Chat",false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
					end
				end--]=]

				spawn(Functions.Donor, p)

				--// Fire added event
				service.Events.CharacterAdded:Fire(p, Character, ...)

				--// Run OnSpawn commands
				for i,v in pairs(Settings.OnSpawn) do
					TrackTask("Thread: OnSpawn_Cmd: ".. tostring(v), Admin.RunCommandAsPlayer, v, p)
					AddLog("Script", {
						Text = "OnSpawn: Executed "..tostring(v);
						Desc = "Executed OnSpawn command; "..tostring(v)
					})
				end
			end
		end;

		NetworkAdded = function(cli)
			wait(0.25)

			local p = cli:GetPlayer()

			if p then
				Core.Connections[cli] = p;

				AddLog("Script", {
					Text = p.Name .. " connected";
					Desc = p.Name .. " successfully established a connection with the server";
					Player = p;
				})
			else
				AddLog("Script", {
					Text = "<UNKNOWN> connected";
					Desc = "An unknown user successfully established a connection with the server";
				})
			end

			service.Events.NetworkAdded:fire(cli)
		end;

		NetworkRemoved = function(cli)
			local p = cli:GetPlayer() or Core.Connections[cli]

			Core.Connections[cli] = nil

			if p then
				AddLog("Script", {
					Text = p.Name .. " disconnected";
					Desc = p.Name .. " disconnected from the server";
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

		--[[
		PlayerTeleported = function(p,data)

		end;
		]]
	};
end
