return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	local Routine = env.Routine
	local Pcall = env.Pcall
	local cPcall = env.cPcall

	return {
		ACIMInfo = {
            Prefix = Settings.Prefix;
            Commands = {"ACIMInfo"};
            Args = {};
            Description = "Show a list of functionality loss.";
            AdminLevel = 1;
            Hidden = false;
            Function = function(plr: Player, args: {string}, data)
                Remote.MakeGui(plr,"List",{
                    Title = "Adonis Critical Incident",
                    Icon = "rbxassetid://7467273592",
                    Table = require(server.Dependencies.ACIMInfo),
                    Font = "Code",
                    PageSize = 100;
                    Size = {750, 400},
					PagesEnabled = false;
					Dots = true;
					Sanitize = false;
					Stacking = true;
					RichText = true;
				
                })
            end
        };

		Kick = {
			Prefix = Settings.Prefix;
			Commands = {"kick"};
			Args = {"player", "optional reason"};
			Filter = true;
			Description = "Disconnects the target player from the server";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)"), {
					IsKicking = true;
					NoFakePlayer = true; --// Can't really kick someone not in game...
					})
				do
					if Admin.CheckAuthority(plr, v, "kick") then
						local playerName = service.FormatPlayer(v)
						if not service.Players:FindFirstChild(v.Name) then
							Remote.Send(v, "Function", "Kill")
						else
							v:Kick(args[2])
						end
						Functions.Hint(`Kicked {playerName}`, {plr})
					end
				end
			end
		};

		TimeBanList = {
			Prefix = Settings.Prefix;
			Commands = {"timebanlist", "timebanned", "timebans"};
			Args = {};
			Description = "Shows you the list of time banned users";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local variables = Core.Variables
				local timeBans = variables.TimeBans or {}
				local tab = table.create(#timeBans)

				for ind, v in timeBans do
					local timeLeft = v.EndTime - os.time()
					local minutes = Functions.RoundToPlace(timeLeft / 60, 2)

					if timeLeft <= 0 then
						table.remove(variables.TimeBans, ind)
					else
						table.insert(tab, {
							Text = `{v.Name}:{v.UserId}`,
							Desc = string.format("Issued by: %s | Minutes left: %d", v.Moderator or "%UNKNOWN%", minutes)
						})
					end
				end

				Remote.MakeGui(plr, "List", {Title = "Time Bans", Tab = tab})
			end
		};

		Notification = {
			Prefix = Settings.Prefix;
			Commands = {"notify", "notification", "notice"};
			Args = {"player", "message"};
			Description = "Sends the player a notification";
			Filter = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing message")

				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Notification", {
						Title = "Notification";
						Message = service.Filter(args[2], plr, v);
					})
				end
			end
		};

		Notify = {
			Prefix = Settings.Prefix;
			Commands = {"n", "smallmessage", "nmessage", "nmsg", "smsg", "smessage"};
			Args = {"message"};
			Filter = true;
			Description = "Makes a small message";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing message")

				Functions.Notify(`Message from {service.FormatPlayer(plr)}`, service.BroadcastFilter(args[1], plr), service.GetPlayers())
			end
		};

		Hint = {
			Prefix = Settings.Prefix;
			Commands = {"h", "hint"};
			Args = {"message"};
			Filter = true;
			Description = "Makes a hint";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing message")

				Functions.Hint(service.BroadcastFilter(args[1], plr), service.GetPlayers(), nil, service.FormatPlayer(plr), `rbxthumb://type=AvatarHeadShot&id={plr.UserId}&w=48&h=48`)
			end
		};

		Warn = {
			Prefix = Settings.Prefix;
			Commands = {"warn", "warning"};
			Args = {"player/user", "reason"};
			Filter = true;
			Description = "Warns players";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target player(s) (argument #1)")
				local reason = assert(args[2], "Missing reason (argument #2)")

				for _, v in service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = false;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "warn", false) then
						local playerData = Core.GetPlayer(v)
						table.insert(playerData.Warnings, {
							From = plr.Name;
							Message = reason;
							Time = os.time();
						})
						service.Events.WarningAdded:Fire(v, args[2], plr)

						--// Check if its a fake player, this should allow it to save.
						if service.Wrapped(v) then
							task.defer(Core.SavePlayerData, v, playerData)
						end

						Remote.RemoveGui(v, "Notify")
						Remote.MakeGui(v, "Notify", {
							Title = `Warning from {service.FormatPlayer(plr)}`;
							Message = reason;
						})

						Remote.MakeGui(plr, "Notification", {
							Title = "Notification";
							Icon = server.MatIcons.Shield;
							Message = `Warned {service.FormatPlayer(v)}`;
							Time = 5;
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}warnings {v.Name}')`)
						})
					end
				end
			end
		};

		KickWarn = {
			Prefix = Settings.Prefix;
			Commands = {"kickwarn", "kwarn", "kickwarning"};
			Args = {"player/user", "reason"};
			Filter = true;
			Description = "Warns & kicks a player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target player(s) (argument #1)")
				local reason = assert(args[2], "Missing reason (argument #2)")

				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					NoFakePlayer = true;
					})
				do
					if Admin.CheckAuthority(plr, v, "kick-warn", false) then
						local playerData = Core.GetPlayer(v)
						table.insert(playerData.Warnings, {
							From = plr.Name;
							Message = reason;
							Time = os.time();
						})

						service.Events.WarningAdded:Fire(v, reason, plr)

						if typeof(v) == "Instance" then
							v:Kick(string.format("\n[Warning from %s]\nReason: %s", service.FormatPlayer(plr), reason))
						else
							Core.CrossServer("RemovePlayer", v.Name, `Warning from {service.FormatPlayer(plr)}`, reason)
						end

						Remote.MakeGui(plr, "Notification", {
							Title = "Notification";
							Icon = server.MatIcons.Shield;
							Message = `Kick-warned {service.FormatPlayer(v)}`;
							Time = 5;
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}warnings {v.Name}')`)
						})
					end
				end
			end
		};

		RemoveWarning = {
			Prefix = Settings.Prefix;
			Commands = {"removewarning", "unwarn"};
			Args = {"player/user", "warning reason"};
			Description = "Removes the specified warning from the target player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target player(s) (argument #1)")
				local reason = string.lower(assert(args[2], "Missing warning reason (argument #2)"))

				for _, v in service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = false;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "remove warning(s) from") then
						local playerData = Core.GetPlayer(v)
						local playerWarnings = playerData.Warnings

						local count = 0

						--// remove warnings by index
						local indexReason = tonumber(reason)
						if indexReason and playerWarnings[indexReason] then
							service.Events.PlayerWarningRemoved:Fire(v, playerWarnings[indexReason].Message, plr)
							table.remove(playerWarnings, indexReason)

							count += 1
						else
							for i, playerWarning in playerWarnings do
								if string.match(string.lower(playerWarning.Message), `^{reason}`) then
									service.Events.PlayerWarningRemoved:Fire(v, playerWarning.Message, plr)
									table.remove(playerWarnings, i)

									count += 1
								end
							end
						end


						--// Check if its a fake player, this should allow it to save.
						if service.Wrapped(v) then
							task.defer(Core.SavePlayerData, v, playerData)
						end

						Remote.MakeGui(plr, "Notification", {
							Title = "Notification";
							Icon = server.MatIcons.Shield;
							Message = string.format("Removed %d warning%s from %s.", count, count == 1 and "" or "s", service.FormatPlayer(v));
							Time = 5;
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}warnings {v.Name}')`)
						})
					end
				end
			end
		};

		ClearWarnings = {
			Prefix = Settings.Prefix;
			Commands = {"clearwarnings", "clearwarns"};
			Args = {"player"};
			Description = "Clears any warnings on a player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local playerData = Core.GetPlayer(v)
					table.clear(playerData.Warnings)

					--// Check if its a fake player, this should allow it to save.
					if service.Wrapped(v) then
						task.defer(Core.SavePlayerData, v, playerData)
					end

					Remote.MakeGui(plr, "Notification", {
						Title = "Notification";
						Icon = server.MatIcons.Shield;
						Message = `Cleared warning(s) for {service.FormatPlayer(v)}`;
						Time = 5;
						OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}warnings {v.Name}')`)
					})
				end
			end
		};

		ShowWarnings = {
			Prefix = Settings.Prefix;
			Commands = {"warnings", "showwarnings", "warns", "showwarns", "warnlist"};
			Args = {"player"};
			Description = "Shows a list of warnings a player has";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, target: Player)
				local data = Core.GetPlayer(target)
				local tab = table.create(#(data.Warnings or {}))
				for k, m in data.Warnings or {} do
					table.insert(tab, {
						Text = `[{k}] {m.Message}`;
						Desc = `Issued by: {m.From}; {m.Message}`;
						Time = m.Time;
					})
				end
				return tab
			end,
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = false;
					NoFakePlayer = false;
					})
				do

					--// For fake players
					local fake_data
					if service.Wrapped(v) then
						fake_data = {UserId = v.UserId, Name = v.Name}
					end

					Remote.MakeGui(plr, "List", {
						Title = `Warnings - {service.FormatPlayer(v)}`;
						Icon = server.MatIcons.Gavel;
						Table = Logs.ListUpdaters.ShowWarnings(plr, v);
						Update = "ShowWarnings";
						UpdateArg = fake_data or v;
						TimeOptions = {
							WithDate = true;
						}
					})
				end
			end
		};

		ForceField = {
			Prefix = Settings.Prefix;
			Commands = {"ff";"forcefield";};
			Args = {"player", "visible? (default: true)"};
			Description = "Gives a force field to the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						service.New("ForceField", v.Character).Visible = if args[2] and args[2]:lower() == "false" then false else true
					end
				end
			end
		};

		UnForcefield = {
			Prefix = Settings.Prefix;
			Commands = {"unff", "unforcefield"};
			Args = {"player"};
			Description = "Removes force fields on the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						Routine(function()
							for _, c in v.Character:GetChildren() do
								if c:IsA("ForceField") and c.Name ~= "ADONIS_FULLGOD" then
									c:Destroy()
								end
							end
						end)
					end
				end
			end
		};

		Freeze = {
			Prefix = Settings.Prefix;
			Commands = {"freeze"};
			Args = {"player"};
			Description = "Freezes the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						if v.Character then
							for a, obj in v.Character:GetChildren() do
								if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then obj.Anchored = true end
							end
						end
					end)
				end
			end
		};

		Thaw = {
			Prefix = Settings.Prefix;
			Commands = {"thaw", "unfreeze", "unice"};
			Args = {"player"};
			Description = "UnFreezes the target players, thaws them out";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							local ice = v.Character:FindFirstChild("Adonis_Ice")
							local plate
							if ice then
								plate = service.New("Part", {
									Parent = v.Character;
									Name = "Adonis_Water";
									Anchored = true;
									CanCollide = false;
									TopSurface = "Smooth";
									BottomSurface = "Smooth";
									Size = Vector3.new(0.2, 0.2, 0.2);
									BrickColor = BrickColor.new("Steel blue");
									Transparency = ice.Transparency;
									CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0);
								})
								service.New("CylinderMesh", plate)
								for i = 0.2, 3, 0.2 do
									ice.Size = Vector3.new(5, ice.Size.Y - i, 5)
									ice.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, -i, 0)
									plate.Size = Vector3.new(i + 5, 0.2, i + 5)
									wait()
								end
								ice:Destroy()
							end

							for _, obj in v.Character:GetChildren() do
								if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" and obj ~= plate then
									obj.Anchored = false
								end
							end
							wait(3)
							pcall(function() plate:Destroy() end)
						end
					end)
				end
			end
		};

		AFK = {
			Prefix = Settings.Prefix;
			Commands = {"afk"};
			Args = {"player"};
			Description = "FFs, Gods, Names, Freezes, and removes the target player's tools until they jump.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						local ff = service.New("ForceField", v.Character)
						local hum = v.Character.Humanoid
						local orig = hum.MaxHealth
						local tools = service.New("Model")
						hum.MaxHealth = math.huge
						wait()
						hum.Health = hum.MaxHealth
						for k, t in v.Backpack:GetChildren() do
							t.Parent = tools
						end
						Admin.RunCommand(`{Settings.Prefix}name`, v.Name, `-AFK-_{service.FormatPlayer(v)}_-AFK-`)
						local torso = v.Character.HumanoidRootPart
						local pos = torso.CFrame
						local running=true
						local event
						event = v.Character.Humanoid.Jumping:Connect(function()
							running = false
							ff:Destroy()
							hum.Health = orig
							hum.MaxHealth = orig
							for k, t in tools:GetChildren() do
								t.Parent = v.Backpack
							end
							Admin.RunCommand(`{Settings.Prefix}unname`, v.Name)
							event:Disconnect()
						end)
						repeat torso.CFrame = pos wait() until not v or not v.Character or not torso or not running or not torso.Parent
					end)
				end
			end
		};

		Heal = {
			Prefix = Settings.Prefix;
			Commands = {"heal"};
			Args = {"player"};
			Description = "Heals the target player(s) (Regens their health)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = hum.MaxHealth
					end
				end
			end
		};

		God = {
			Prefix = Settings.Prefix;
			Commands = {"god", "immortal"};
			Args = {"player"};
			Description = "Makes the target player(s) immortal, makes their health so high that normal non-explosive weapons can't kill them";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.MaxHealth = math.huge
						hum.Health = 9e9
						if Settings.CommandFeedback then
							Functions.Notification("God mode", "Character God mode has been enabled. You will not take damage from non-explosive weapons.", {v}, 15, "Info")
						end
					end
				end
			end
		};

		UnGod = {
			Prefix = Settings.Prefix;
			Commands = {"ungod", "mortal", "unfullgod", "untotalgod"};
			Args = {"player"};
			Description = "Makes the target player(s) mortal again";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.MaxHealth = 100
						hum.Health = hum.MaxHealth
						local fullGodFF = v.Character:FindFirstChild("ADONIS_FULLGOD")
						if fullGodFF and fullGodFF:IsA("ForceField") then
							fullGodFF:Destroy()
						end
						if Settings.CommandFeedback then
							Functions.Notification("God Mode", "Character god mode has been disabled.", {v}, 15, "Info")
						end
					end
				end
			end
		};

		FullGod = {
			Prefix = Settings.Prefix;
			Commands = {"fullgod", "totalgod"};
			Args = {"player"};
			Description = `Same as {server.Settings.Prefix}god, but also provides blast protection`;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.MaxHealth = math.huge
						hum.Health = 9e9
						service.New("ForceField", {
							Parent = hum.Parent;
							Name = "ADONIS_FULLGOD";
							Visible = false;
						})
						if Settings.CommandFeedback then
							Functions.Notification("God Mode", "Character god mode has been enabled. You will not take any damage.", {v}, 15, "Info")
						end
					end
				end
			end
		};

		PrivateChat = {
			Prefix = Settings.Prefix;
			Commands = {"privatechat", "dm", "pchat"};
			Args = {"player", "message (optional)"};
			Filter = true;
			Description = "Send a private message to a player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")

				local sessionName = Functions.GetRandom() --// Used by the private chat windows
				local newSession = Remote.NewSession("PrivateChat")
				local history = {}

				newSession.Data.History = history

				local function getPeerList()
					local peers = {}
					for peer in newSession.Users do
						table.insert(peers, {
							Name = peer.Name;
							DisplayName = peer.DisplayName;
							UserId = peer.UserId;
							--Instance = service.UnWrap(peer);
						})
					end
					return peers
				end

				local function systemMessage(msg)
					local data = {
						Name = "* SYSTEM *";
						UserId = 0;
						Icon = 0;
					};
					table.insert(history, {
						Sender = data;
						Message = msg;
					});
					newSession:SendToUsers("PlayerSentMessage", data, msg)
				end;

				newSession:ConnectEvent(function(p, cmd, ...)
					local args = {...}

					if not p then -- System event(s)
						if cmd == "LastUserRemoved" then
							newSession:End()
						end
					else	-- Player event(s)
						if cmd == "SendMessage" then
							local message = string.sub(tostring(args[1]), 1, 140)
							local filtered = service.BroadcastFilter(message, p)
							if filtered ~= message then
								Remote.MakeGui(p, "Output", {
									Message = "A message filtering error occurred; please try again."
								})
							else
								local gotIcon, status = service.Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
								local data, msg = {
									Name = p.Name;
									DisplayName = p.DisplayName;
									UserId = p.UserId;
									Icon = status and gotIcon or "rbxasset://textures/ui/GuiImagePlaceholder.png";
								}, filtered

								table.insert(history, {
									Sender = data;
									Message = msg;
								})

								if #history > 200 then
									table.remove(history, 1)
								end

								newSession:SendToUsers("PlayerSentMessage", data, msg)
							end
						elseif cmd == "LeaveSession" or cmd == "RemovedFromSession" then
							newSession:RemoveUser(p)

							systemMessage(string.format("<i>%s has left the session</i>", p.Name))
							newSession:SendToUsers("UpdatePeerList", getPeerList())

							if p == plr then
								systemMessage("<i>Session ended: Session owner left</i>")
								newSession:End()
							end
						elseif cmd == "EndSession" and p == plr then
							systemMessage("<i>Session ended</i>")

							newSession:End()
						elseif cmd == "AddPlayerToSession" and (p == plr or Admin.CheckAdmin(p)) then
							local player = args[1]

							if player then
								newSession:AddUser(player)
								newSession:SendToUser(player, "AddedToSession")

								systemMessage(string.format("<i>%s added %s to the session</i>", p.Name, player.Name))
								Remote.MakeGui(player, "PrivateChat", {
									Owner = plr;
									SessionKey = newSession.SessionKey;
									SessionName = sessionName;
									History = history;
									CanManageUsers = Admin.CheckAdmin(player);
								})

								newSession:SendToUsers("UpdatePeerList", getPeerList());
							end
						elseif cmd == "RemovePlayerFromSession" and (p == plr or Admin.CheckAdmin(p)) then
							local peer = args[1];

							if peer then
								for pr in newSession.Users do
									if peer.UserId and peer.UserId == pr.UserId then
										newSession:SendToUser(pr, "RemovedFromSession")
										newSession:RemoveUser(pr)
										systemMessage(string.format("<i>%s removed %s from the session</i>", p.Name, pr.Name))
									end
								end
							end

							newSession:SendToUsers("UpdatePeerList", getPeerList())
						elseif cmd == "GetPeerList" then
							newSession:SendToUser(p, "UpdatePeerList", getPeerList())
						end
					end
				end)

				systemMessage("<i>Chat session started</i>")

				if args[2] then
					local gotIcon, status = service.Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);

					local data = {
						Name = plr.Name;
						DisplayName = plr.DisplayName;
						UserId = plr.UserId;
						Icon = status and gotIcon or "rbxasset://textures/ui/GuiImagePlaceholder.png";
					};

					table.insert(history, {
						Sender = data;
						Message = args[2];
					});
				end

				newSession:AddUser(plr);
				Remote.MakeGui(plr, "PrivateChat", {
					Owner = plr;
					SessionKey = newSession.SessionKey;
					SessionName = sessionName;
					History = history;
					CanManageUsers = true;
				})

				for i, v in service.GetPlayers(plr, args[1]) do
					if v ~= plr then
						newSession:AddUser(v)

						Remote.MakeGui(v, "PrivateChat", {
							Owner = plr;
							SessionKey = newSession.SessionKey;
							SessionName = sessionName;
							History = history;
							CanManageUsers = Admin.CheckAdmin(v);
						})
					end
				end
			end
		};

		PrivateMessage = {
			Prefix = Settings.Prefix;
			Commands = {"pm", "privatemessage"};
			Args = {"player", "message"};
			Filter = true;
			Description = "Send a private message to a player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing message")
				for _, v in service.GetPlayers(plr, args[1]) do
					local replyTicket = Functions.GetRandom()
					Variables.PMtickets[replyTicket] = plr

					Remote.MakeGui(v, "PrivateMessage", {
						Title = `Message from {service.FormatPlayer(plr)}`;
						Player = plr;
						Message = service.Filter(args[2], plr, v);
						replyTicket = replyTicket;
					})
				end
			end
		};

		ShowTrelloBansList = {
			Prefix = Settings.Prefix;
			Commands = {"SyncedTrelloBans", "TrelloBans", "TrelloBanList", "ShowTrelloBans"};
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
					Remote.MakeGui(plr, "Notification", {
						Title = "Trello Synced Ban List";
						Message = "Trello has not been enabled.";
					})
				else
					Remote.MakeGui(plr, "List", {
						Title = "Trello Synced Bans List";
						Icon = server.MatIcons.Gavel;
						Tab = Logs.ListUpdaters.ShowTrelloBansList(plr);
						Update = "ShowTrelloBansList";
					})
				end
			end;
		};

		ShowBackpack = {
			Prefix = Settings.Prefix;
			Commands = {"showtools", "viewtools", "seebackpack", "viewbackpack", "showbackpack", "displaybackpack", "displaytools", "listtools"};
			Args = {"player",  "autoupdate? (default: false)"};
			Description = "Shows you a list of items currently in the target player(s) backpack";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, target: Player)
				local tab = {}
				local equippedTool = target.Character and target.Character:FindFirstChildWhichIsA("BackpackItem")
				if equippedTool then
					table.insert(tab, {
						Text = `[EQUIPPED] {equippedTool.Name}`;
						Desc = string.format("Class: %s | %s", equippedTool.ClassName, if equippedTool:IsA("Tool") then `ToolTip: {equippedTool.ToolTip}` else `BinType: {equippedTool.BinType}`);
					})
				end
				local backpack = target:FindFirstChildOfClass("Backpack")
				if backpack then
					for _, t in backpack:GetChildren() do
						table.insert(tab, {
							Text = t.Name;
							Desc = if t:IsA("BackpackItem") then
								string.format("Class: %s | %s", t.ClassName, if t:IsA("Tool") then `ToolTip: {t.ToolTip}` else `BinType: {t.BinType}`)
								else `Class: {t.ClassName}`;
						})
					end
				else
					table.insert(tab, "This player has no backpack present.")
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						Remote.MakeGui(plr, "List", {
							Title = `{service.FormatPlayer(v)}'s tools`;
							Icon = server.MatIcons["Inventory 2"];
							Table = Logs.ListUpdaters.ShowBackpack(plr, v);
							AutoUpdate = if args[2] and (args[2]:lower() == "true" or args[2]:lower() == "yes") then 1 else nil;
							Update = "ShowBackpack";
							UpdateArg = v;
							Size = {280, 225};
							TitleButtons = {
								{
									Text = "";
									OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}tools')`);
									Children = {
										{
											Class = "ImageLabel";
											Size = UDim2.new(0, 18, 0, 18);
											Position = UDim2.new(0, 6, 0, 1);
											Image = server.MatIcons.Build;
											BackgroundTransparency = 1;
											ZIndex = 3;
										}
									}
								}
							};
						})
					end)
				end
			end
		};

		PlayerList = {
			Prefix = Settings.Prefix;
			Commands = {"players", "playerlist", "listplayers"};
			Args = {"autoupdate? (default: true)"};
			Description = "Shows you all players currently in-game, including nil ones";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local players = Functions.GrabNilPlayers("all")
				local tab = {
					`# Players: {#players}`,
					"―――――――――――――――――――――――",
				}
				for _, v in players do
					cPcall(function()
						if type(v) == "string" and v == "NoPlayer" then
							table.insert(tab, {
								Text = "PLAYERLESS CLIENT";
								Desc = "PLAYERLESS SERVERREPLICATOR: COULD BE LOADING/LAG/EXPLOITER. CHECK AGAIN IN A MINUTE!";
							})
						else
							local ping

							Routine(function()
								ping = `{Remote.Ping(v)}ms`
							end)

							for i = 0.1, 5, 0.1 do
								if ping then break end
								wait(0.1)
							end

							if not ping then
								ping = ">5000ms"
							end

							if v and service.Players:FindFirstChild(v.Name) then
								local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
								table.insert(tab, {
									Text = string.format("[%s] %s", ping, service.FormatPlayer(v, true));
									Desc = string.format("Lower: %s | Health: %d | MaxHealth: %d | WalkSpeed: %d | JumpPower: %d | Humanoid Name: %s", v.Name:lower(), hum and hum.Health or 0, hum and hum.MaxHealth or 0, hum and hum.WalkSpeed or 0, hum and hum.JumpPower or 0, hum and hum.Name or "?");
								})
							else
								table.insert(tab, {
									Text = `[LOADING] {service.FormatPlayer(v, true)}`;
									Desc = `Lower: {string.lower(v.Name)} | Ping: {ping}`;
								})
							end
						end
					end)
				end
				for i = 0.1, 5, 0.1 do
					if service.CountTable(tab) - 2 >= service.CountTable(players) then break end
					wait(0.1)
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Functions.Hint("Pinging players. Please wait. No ping = Ping > 5sec.", {plr})
				Remote.MakeGui(plr, "List", {
					Title = "Players",
					Icon = server.MatIcons.People;
					Tab = Logs.ListUpdaters.PlayerList(plr);
					Size = {300, 240};
					AutoUpdate = if not args[1] or (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Update = "PlayerList";
				})
			end
		};

		View = {
			Prefix = Settings.Prefix;
			Commands = {"view", "watch", "nsa", "viewplayer"};
			Args = {"player"};
			Description = "Makes you view the target player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if not hum then
						Functions.Hint(`{service.FormatPlayer(v)} doesn't have a character humanoid`, {plr})
						continue
					end
					local rootPart = v.Character.PrimaryPart
					if not rootPart then
						Functions.Hint(`{service.FormatPlayer(v)} doesn't have a HumanoidRootPart`, {plr})
						continue
					end
					Functions.ResetReplicationFocus(plr)
					plr.ReplicationFocus = rootPart
					Remote.Send(plr, "Function", "SetView", hum)
				end
			end
		};

		ResetView = {
			Prefix = Settings.Prefix;
			Commands = {"resetview", "rv", "fixview", "fixcam", "unwatch", "unview"};
			Args = {"optional player"};
			Description = "Resets your view";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character.PrimaryPart then
						Functions.ResetReplicationFocus(v)
					else
						Functions.Hint(`{service.FormatPlayer(v)} doesn't have a character and/or HumanoidRootPart`, {plr})
					end
					Remote.Send(v, "Function", "SetView", "reset")
				end
			end
		};

		Clean = {
			Prefix = Settings.Prefix;
			Commands = {"clean"};
			Args = {};
			Description = "Cleans some useless junk out of workspace";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				Functions.CleanWorkspace()
			end
		};

		CommandBox = {
			Prefix = Settings.Prefix;
			Commands = {"cmdbox", "commandbox"};
			Args = {};
			Description = "Command Box";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Window", {
					Title = "Command Box";
					Name = "CommandBox";
					Icon = server.MatIcons.Code;
					Size  = {300, 250};
					Ready = true;
					Content = {
						{
							Class = "TextBox";
							Name = "ComText";
							Size = UDim2.new(1, -10, 1, -40);
							Text = "";
							BackgroundTransparency = 0.5;
							PlaceholderText = "Enter commands here";
							TextYAlignment = "Top";
							MultiLine = true;
							ClearTextOnFocus = false;
							TextChanged = Core.Bytecode[[
								if not Object.TextFits then
									Object.TextYAlignment = "Bottom"
								else
									Object.TextYAlignment = "Top"
								end
							]]
						};
						{
							Class = "TextButton";
							Name = "Execute";
							Size = UDim2.new(1, -10, 0, 35);
							Position = UDim2.new(0, 5, 1, -40);
							Text = "Execute";
							OnClick = Core.Bytecode[[
								local textBox = Object.Parent:FindFirstChild("ComText")
								if textBox then
									client.Remote.Send("ProcessCommand", textBox.Text)
								end
							]]
						};
					}
				})
			end;
		};

		ShowTasks = {
			Prefix = "";
			Commands = {":tasks", ":tasklist", `{Settings.Prefix}tasks`, `{Settings.Prefix}tasklist`};
			Args = {"player"};
			Description = "Displays running tasks";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, target)
				if target then
					for _, v in Functions.GetPlayers(plr, target) do
						local cTasks = Remote.Get(v, "TaskManager", "GetTasks") or {}
						local temp = table.create(#cTasks + 1)

						table.insert(temp, {
							Text = "Client Tasks",
							Desc = "Tasks their client is performing"})

						for _, t in cTasks do
							table.insert(temp, {
								Text = `{t.Name or t.Function}- Status: {t.Status} - Elapsed: {t.CurrentTime - t.Created}`;
								Desc = tostring(t.Function);
							})
						end

						return temp
					end
				else
					local tasks = service.GetTasks()
					local temp = {}
					local cTasks = Remote.Get(plr, "TaskManager", "GetTasks") or {}

					table.insert(temp, {Text = "Server Tasks"; Desc = "Tasks the server is performing";})

					for _, v in tasks do
						table.insert(temp, {
							Text = `{v.Name or v.Function} - Status: {v.Status} - Elapsed: {os.time()-v.Created}`;
							Desc = tostring(v.Function);
						})
					end

					table.insert(temp, " ")
					table.insert(temp, {
						Text = "Client Tasks",
						Desc = "Tasks your client is performing"
					})

					for _, v in cTasks do
						table.insert(temp, {
							Text = `{v.Name or v.Function} - Status: {v.Status} - Elapsed: {v.CurrentTime-v.Created}`;
							Desc = tostring(v.Function);
						})
					end

					return temp
				end
			end;
			Function = function(plr: Player, args: {string})
				if args[1] then
					for i, v in service.GetPlayers(plr, args[1]) do
						Remote.MakeGui(plr, "List", {
							Title = `{v.Name}'s Tasks`;
							Table = Logs.ListUpdaters.ShowTasks(plr, v);
							Font = "Code";
							Update = "ShowTasks";
							UpdateArgs = {v};
							AutoUpdate = 1;
							Size = {500, 400};
						})
					end
				else
					Remote.MakeGui(plr, "List", {
						Title = "Tasks",
						Table = Logs.ListUpdaters.ShowTasks(plr),
						Font = "Code",
						Update = "ShowTasks",
						AutoUpdate = 1,
						Size = {500, 400},
					})
				end
			end
		};

		AdminList = {
			Prefix = Settings.Prefix;
			Commands = {"admins", "adminlist", "headadmins", "owners", "moderators", "ranks"};
			Args = {};
			Description = "Shows you the list of admins, also shows admins that are currently in the server";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local RANK_DESCRIPTION_FORMAT = "Rank: %s; Level: %d"
				local RANK_RICHTEXT = "<b><font color='rgb(77, 77, 255)'>%s (Level: %d)</font></b>"
				local RANK_TEXT_FORMAT = "%s [%s]"

				local temptable = {}
				local unsorted = {}

				table.insert(temptable, "<b><font color='rgb(60, 180, 0)'>Admins In-Game:</font></b>")

				for _, v in service.Players:GetPlayers() do
					local level, rankName = Admin.GetLevel(v);
					if level > 0 then
						table.insert(unsorted, {
							Text = string.format(RANK_TEXT_FORMAT, service.FormatPlayer(v), (rankName or (`Level: {level}`)));
							Desc = string.format(RANK_DESCRIPTION_FORMAT, rankName or (level >= 1000 and "Place Owner") or "Unknown", level);
							SortLevel = level;
						})
					end
				end

				table.sort(unsorted, function(one, two)
					return one.SortLevel > two.SortLevel
				end)

				for _, v in unsorted do
					v.SortLevel = nil
					table.insert(temptable, v)
				end

				table.clear(unsorted)

				table.insert(temptable, "")
				table.insert(temptable, "<b><font color='rgb(180, 60, 0)'>All Admins:</font></b>")

				for rank, data in Settings.Ranks do
					if not data.Hidden then
						table.insert(unsorted, {
							Text = string.format(RANK_RICHTEXT, rank, data.Level);
							Desc = "";
							Level = data.Level;
							Users = data.Users;
							Rank = rank;
						})
					end
				end

				table.sort(unsorted, function(one, two)
					return one.Level > two.Level
				end)

				for _, v in unsorted do
					local Users = v.Users or {};
					local Level = v.Level or 0;
					local Rank = v.Rank or "Unknown";

					v.Users = nil
					v.Level = nil
					v.Rank = nil

					table.insert(temptable, v)

					for _, user in Users do
						table.insert(temptable, {
							Text = `  {user}`;
							Desc = string.format(RANK_DESCRIPTION_FORMAT, Rank, Level);
							--SortLevel = data.Level;
						})
					end
				end

				return temptable
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Admin List";
					Icon = server.MatIcons["Admin panel settings"];
					Table = Logs.ListUpdaters.AdminList(plr);
					Update = "AdminList";
					RichText = true;
				})
			end;
		};

		BanList = {
			Prefix = Settings.Prefix;
			Commands = {"banlist", "banned", "bans", "banland"};
			Args = {};
			Description = "Shows you the normal ban list";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local tab = table.create(#Settings.Banned + 2)
				local count = 0
				for _, v in Settings.Banned do
					local entry = type(v) == "string" and v
					local reason = "No reason provided"
					local moderator = "%UNKNOWN%"
					count +=1
					if type(v) == "table" then
						if v.Name and v.UserId then
							entry = `{v.Name}:{v.UserId}`
						elseif v.UserId then
							entry = `ID: {v.UserId}`
						elseif v.Name then
							entry = v.Name
						end
						if v.Reason then
							reason = v.Reason
						end
						if v.Moderator then
							moderator = v.Moderator
						end
					end
					table.insert(tab, {
						Text = tostring(entry),
						Desc = string.format("Issued by: %s | Reason: %s", moderator, reason)
					})
				end
				table.insert(tab, 1, `# Banned Users: {count}`)
				table.insert(tab, 2, "―――――――――――――――――――――――")
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Ban List";
					Icon = server.MatIcons.Gavel;
					Tab = Logs.ListUpdaters.BanList(plr);
					Update = "BanList";
				})
			end;
		};

		Clear = {
			Prefix = Settings.Prefix;
			Commands = {"clear", "cleargame", "clr"};
			Args = {};
			Description = "Remove admin objects";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				service.StopLoop("ChickenSpam")
				Functions.CleanWorkspace()
				for _, v in Variables.Objects do
					if v.ClassName == "Script" or v.ClassName == "LocalScript" then
						v.Disabled = true
					end
					v:Destroy()
				end

				for i, v in Variables.Cameras do
					if v then
						table.remove(Variables.Cameras, i)
						v:Destroy()
					end
				end

				for _, v in Variables.Jails do
					if not v.Player or not v.Player.Parent then
						local ind = v.Index
						service.StopLoop(`{ind}JAIL`)
						Pcall(function() v.Jail:Destroy() end)
						Variables.Jails[ind] = nil
					end
				end

				for _, v in workspace:GetChildren() do
					if v.ClassName == "Message" or v.ClassName == "Hint" then
						v:Destroy()
					end

					if string.match(v.Name, "A_Probe (.*)") then
						v:Destroy()
					end
				end

				table.clear(Variables.Objects)
				--RemoveMessage()
			end
		};

		ShowServerInstances = {
			Prefix = Settings.Prefix;
			Commands = {"serverinstances"};
			Args = {};
			Description = "Shows all instances created server-side by Adonis";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, updateArgs)
				local objects = service.GetAdonisObjects()
				local tab = table.create(#objects)
				for _, v in objects do
					table.insert(tab, {
						Text = v:GetFullName();
						Desc = `Class: {v.ClassName}`;
					})
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Adonis Instances";
					Table = Logs.ListUpdaters.ShowServerInstances(plr);
					Stacking = false;
					Update = "ShowServerInstances";
				})
			end
		};

		ShowClientInstances = {
			Prefix = Settings.Prefix;
			Commands = {"clientinstances"};
			Args = {"player"};
			Description = "Shows all instances created client-side by Adonis";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, target: Player)
				if target then
					local temp = {"Player is currently unreachable"}
					if target then
						temp = Remote.Get(target, "InstanceList") or temp
					end
					return temp
				else
					local objects = service.GetAdonisObjects()
					local temp = table.create(#objects)
					for _, v in objects do
						table.insert(temp, {
							Text = v:GetFullName();
							Desc = v.ClassName;
						})
					end
					return temp
				end
			end;
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(plr, "List", {
						Title = `{service.FormatPlayer(v)}'s Client Instances`;
						Table = Logs.ListUpdaters.ShowClientInstances(plr, v);
						Stacking = false;
						Update = "ShowClientInstances";
						UpdateArg = v;
					})
				end
			end
		};

		ClearGUIs = {
			Prefix = Settings.Prefix;
			Commands = {"clearadonisguis", "clearguis", "clearmessages", "clearhints", "clrguis"};
			Args = {"player", "delete all? (default: false)"};
			Description = `Removes Adonis on-screen GUIs for the target player(s); if <delete all> is false, wil, only clear {Settings.Prefix}m, {Settings.Prefix}n, {Settings.Prefix}h, {Settings.Prefix}alert and screen effect GUIs`;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local deleteAll = args[2] and (args[2]:lower() == "true" or args[2]:lower() == "yes")
				for _, v in service.GetPlayers(plr, args[1]) do
					if deleteAll then
						Routine(Remote.RemoveGui, v, true)
					else
						Routine(function()
							for _, guiName in {"Message", "Hint", "Notify", "Effect", "Alert"} do
								Remote.RemoveGui(v, guiName)
							end
						end)
					end
				end
			end
		};

		ResetStats = {
			Prefix = Settings.Prefix;
			Commands = {"resetstats", "rs"};
			Args = {"player"};
			Description = "Sets target player(s)'s leader stats to 0";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, string.lower(args[1])) do
					cPcall(function()
						if v and v:FindFirstChild("leaderstats") then
							for a, q in v.leaderstats:GetChildren() do
								if q:IsA("IntValue") or q:IsA("NumberValue") then q.Value = 0 end
							end
						end
					end)
				end
			end
		};

		NoClip = {
			Prefix = Settings.Prefix;
			Commands = {"noclip"};
			Args = {"player"};
			Description = "NoClips the target player(s); allowing them to walk through walls";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local clipper = Deps.Assets.Clipper:Clone()
				clipper.Name = "ADONIS_NoClip"

				for i, p in service.GetPlayers(plr, args[1]) do
					Admin.RunCommand(`{Settings.Prefix}clip`, p.Name)
					local new = clipper:Clone()
					new.Parent = p.Character.Humanoid
					new.Disabled = false
					if Settings.CommandFeedback then
						Functions.Notification("Noclip", "Character noclip has been enabled. You will now be able to walk though walls.", {p}, 15, "Info") -- Functions.Notification(title,message,player,time,icon)
					end
				end
			end
		};

		Clip = {
			Prefix = Settings.Prefix;
			Commands = {"clip", "unnoclip"};
			Args = {"player"};
			Description = "Un-NoClips the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, p in service.GetPlayers(plr, args[1]) do
					local old = p.Character.Humanoid:FindFirstChild("ADONIS_NoClip")
					if old then
						local enabled = old:FindFirstChild("Enabled")
						if enabled then
							enabled.Value = false
							wait(0.5)
						end
						old.Parent = nil
						wait(0.5)
						old:Destroy()
						if Settings.CommandFeedback then
							Functions.Notification("Noclip", "Character noclip has been disabled. You will no longer be able to walk though walls.", {p}, 15, "Info") -- Functions.Notification(title,message,player,time,icon)
						end
					end
				end
			end
		};

		Jail = {
			Prefix = Settings.Prefix;
			Commands = {"jail", "imprison"};
			Args = {"player", "BrickColor"};
			Description = "Jails the target player(s), removing their tools until they are un-jailed; Specify a BrickColor to change the color of the jail bars";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local opt = BrickColor.new("White")
				if args[2] then
					if string.lower(args[2]) == "rainbow" then
						opt = "rainbow"
					else
						opt = BrickColor.new(args[2]) or BrickColor.new("White")
					end
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					local cHumanoidRootPart	= v.Character and v.Character.PrimaryPart or v.Character and v.Character:FindFirstChild("HumanoidRootPart")
					if cHumanoidRootPart then

						local cf = CFrame.new(cHumanoidRootPart.CFrame.p + Vector3.new(0, 1, 0))
						local origpos = cHumanoidRootPart.Position

						local mod = service.New("Model", {
							Name = `{v.Name}_ADONISJAIL`,
						})
						local top = service.New("Part", {
							Locked = true,
							Size = Vector3.new(6, 1, 6),
							TopSurface = 0,
							BottomSurface = 0,
							Anchored = true,
							CanCollide = true,
							BrickColor = BrickColor.new("Really black"),
							Transparency = 1,
							CFrame = cf*CFrame.new(0, 3.5, 0),

							Parent = mod,
						})

						local bottom = top:Clone()
						bottom.Transparency = 0
						bottom.CanCollide = true
						bottom.CFrame = cf * CFrame.new(0,-3.5, 0)
						local front = top:Clone()
						front.Transparency = 1
						front.Reflectance = 0
						front.Size = Vector3.new(6, 6, 1)
						front.CFrame = cf * CFrame.new(0, 0,-3)
						local back = front:Clone()
						back.Transparency = 1
						back.CFrame = cf * CFrame.new(0, 0, 3)
						back.Parent = mod
						local right = front:Clone()
						right.Transparency = 1
						right.Size = Vector3.new(1, 6, 6)
						right.CFrame = cf * CFrame.new(3, 0, 0)
						local left = right:Clone()
						left.Transparency = 1
						left.CFrame = cf * CFrame.new(-3, 0, 0)

						bottom.Parent = mod
						front.Parent = mod
						right.Parent = mod
						left.Parent = mod

						local msh = service.New("BlockMesh", {
							Scale = Vector3.new(1, 1, 0),
							Parent = front
						})

						local msh2 = msh:Clone()
						local msh3 = msh:Clone()
						msh3.Scale = Vector3.new(0, 1, 1)

						local msh4 = msh3:Clone()
						msh2.Parent = back
						msh3.Parent = right
						msh4.Parent = left

						local brick = service.New("Part", mod)
						local box = service.New("SelectionBox", {
							Adornee = brick,
							Parent = brick,
						})
						if typeof(opt) == "BrickColor" then
							box.Color = BrickColor.new("White")
						end

						brick.Anchored = true
						brick.CanCollide = false
						brick.Transparency = 1
						brick.Size = Vector3.new(5, 7, 5)
						brick.CFrame = cf
						--table.insert(Variables.Objects, mod)

						local value = service.New("StringValue", {
							Name = "Player",
							Value = v.Name,
							Parent = mod,
						})

						cHumanoidRootPart.CFrame = cf

						local ind = tostring(v.UserId)
						local jail = {
							Player = v;
							Name = v.Name;
							Index = ind;
							Jail = mod;
							Tools = {};
						}
						Variables.Jails[ind] = jail

						local Backpack = v:FindFirstChildOfClass("Backpack")
						if Backpack then
							for _, k in Backpack:GetChildren() do
								if k:IsA("BackpackItem") then
									table.insert(jail.Tools,k)
									k.Parent = nil
								end
							end
						end

						mod.Parent = workspace
						service.TrackTask(`Thread: JailLoop{ind}`, function()
							while wait() and Variables.Jails[ind] == jail and mod.Parent == workspace do
								if Variables.Jails[ind] == jail and v.Parent == service.Players then
									if opt == "rainbow" then
										box.Color3 = Color3.fromHSV(tick()%5/5, 1, 1)
									end

									if v.Character then
										local torso = v.Character:FindFirstChild("HumanoidRootPart")
										if torso then

											local Backpack = v:FindFirstChildOfClass("Backpack")
											if Backpack then
												for _, k in Backpack:GetChildren() do
													if k:IsA("BackpackItem") then
														table.insert(jail.Tools, k)
														k.Parent = nil
													end
												end
											end

											if (torso.Position-origpos).Magnitude > 3.3 then
												torso.CFrame = cf
											end
										end
									end
								elseif Variables.Jails[ind] ~= jail then
									mod:Destroy()
									break;
								end
							end

							if mod then
								mod:Destroy()
							end
						end)
					end
				end
			end
		};

		UnJail = {
			Prefix = Settings.Prefix;
			Commands = {"unjail", "free", "release"};
			Args = {"player"};
			Description = "UnJails the target player(s) and returns any tools that were taken from them while jailed";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local found = false

				for _, v in service.GetPlayers(plr, args[1]) do
					local ind = tostring(v.UserId)
					local jail = Variables.Jails[ind]
					if jail then
						--service.StopLoop(`{ind}JAIL`)
						Pcall(function()
							for _, tool in jail.Tools do
								tool.Parent = v.Backpack
							end
						end)
						Pcall(function() jail.Jail:Destroy() end)
						Variables.Jails[ind] = nil
						found = true
					end
				end

				if not found then
					for i, v in Variables.Jails do
						if string.sub(string.lower(v.Name), 1, #args[1]) == string.lower(args[1]) then
							local ind = v.Index
							service.StopLoop(`{ind}JAIL`)
							Pcall(function() v.Jail:Destroy() end)
							Variables.Jails[ind] = nil
						end
					end
				end
			end
		};

		Track = {
			Prefix = Settings.Prefix,
			Commands = {"track", "trace", "find", "locate"},
			Args = {"player", "persistent? (default: false)"},
			Description = "Shows you where the target player(s) is/are",
			AdminLevel = "Moderators",
			Function = function(plr: Player, args: { string })
				local plrChar = assert(plr.Character, "You don't have a character")
				local plrHum = assert(plrChar:FindFirstChildOfClass("Humanoid", "You don't have a humanoid"))

				local persistent = args[2] and (args[2]:lower() == "true" or args[2]:lower() == "yes")
				if persistent and type(Variables.TrackingTable[plr.Name]) ~= "table" then
					Variables.TrackingTable[plr.Name] = {}
				end

				for _, v: Player in service.GetPlayers(plr, args[1]) do
					if persistent and Variables.TrackingTable[plr.Name] then
						Variables.TrackingTable[plr.Name][v] = true
					end

					local char = v.Character
					if not char then
						Functions.Hint(`{service.FormatPlayer(v)} doesn't currently have a character`, { plr })
						continue
					end

					local rootPart = char:FindFirstChild("HumanoidRootPart")
					local head = char:FindFirstChild("Head")

					if not (rootPart and head) then
						Functions.Hint(`{service.FormatPlayer(v)} doesn't currently have a HumanoidRootPart/Head`, { plr })
						continue
					end

					task.defer(function()
						local gui = service.New("BillboardGui", {
							Name = `{v.Name}_Tracker`,
							Adornee = head,
							AlwaysOnTop = true,
							StudsOffset = Vector3.new(0, 2, 0),
							Size = UDim2.fromOffset(100, 40),
						})
						local beam = service.New("SelectionPartLasso", {
							Parent = gui,
							Part = rootPart,
							Humanoid = plrHum,
							Color3 = v.TeamColor.Color,
						})
						local frame = service.New("Frame", {
							Parent = gui,
							BackgroundTransparency = 1,
							Size = UDim2.fromScale(1, 1),
						})
						local name = service.New("TextLabel", {
							Parent = frame,
							Text = service.FormatPlayer(v),
							BackgroundTransparency = 1,
							Font = Enum.Font.Arial,
							TextColor3 = Color3.new(1, 1, 1),
							TextStrokeColor3 = Color3.new(0, 0, 0),
							TextStrokeTransparency = 0,
							Size = UDim2.new(1, 0, 0, 20),
							TextScaled = true,
							TextWrapped = true,
						})

						local arrow = name:Clone()
						arrow.Position = UDim2.fromOffset(0, 20)
						arrow.Text = "v"
						arrow.Parent = frame

						Remote.MakeLocal(plr, gui, false)

						local charRemovingConn
						local teamChangeConn = v:GetPropertyChangedSignal("TeamColor"):Connect(function()
							beam.Color3 = v.TeamColor.Color
						end)
						local plrCharRemovingConn = plr.CharacterRemoving:Once(function()
							Remote.RemoveLocal(plr, `{v.Name}Tracker`)
							teamChangeConn:Disconnect()
							if charRemovingConn then
								charRemovingConn:Disconnect()
							end
						end)
						charRemovingConn = v.CharacterRemoving:Once(function()
							Remote.RemoveLocal(plr, `{v.Name}Tracker`)
							teamChangeConn:Disconnect()
							plrCharRemovingConn:Disconnect()
						end)
					end)
				end
			end,
		};

		UnTrack = {
			Prefix = Settings.Prefix;
			Commands = {"untrack", "untrace", "unfind", "unlocate", "notrack"};
			Args = {"player"};
			Description = "Stops tracking the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[1] and args[1]:lower() == `{Settings.SpecialPrefix}all` then
					Variables.TrackingTable[plr.Name] = nil
					Remote.RemoveLocal(plr, "Tracker", false, true)
				else
					local trackTargets = Variables.TrackingTable[plr.Name]
					for _, v in service.GetPlayers(plr, args[1]) do
						Remote.RemoveLocal(plr, `{v.Name}Tracker`)
						if trackTargets then
							trackTargets[v] = nil
						end
					end
				end
			end
		};

		Phase = {
			Prefix = Settings.Prefix;
			Commands = {"phase"};
			Args = {"player"};
			Description = "Makes the player(s) character completely local";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeLocal(v, v.Character)
				end
			end
		};

		UnPhase = {
			Prefix = Settings.Prefix;
			Commands = {"unphase"};
			Args = {"player"};
			Description = "UnPhases the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						Remote.MoveLocal(v, v.Character.Name, false, workspace)
						v.Character.Parent = workspace
					end
				end
			end
		};

		Refresh = {
			Prefix = Settings.Prefix;
			Commands = {"refresh", "ref"};
			Args = {"player"};
			Description = "Refreshes the target player(s)'s character";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, p in service.GetPlayers(plr, args[1]) do
					task.defer(function()
						local oChar = p.Character;
						local oTools, pBackpack, oHumanoid, oPrimary, oPos;

						if oChar then
							oHumanoid = oChar:FindFirstChildOfClass("Humanoid");
							oPrimary = oChar.PrimaryPart or (oHumanoid and oHumanoid.RootPart) or oChar:FindFirstChild("HumanoidRootPart");

							if oPrimary then
								oPos = oPrimary.CFrame;
							end
						end

						--// Handle tool saving
						pBackpack = p:FindFirstChildOfClass("Backpack")

						local ev
						if pBackpack then
							oTools = {};
							ev = pBackpack.ChildAdded:Connect(function(c)
								table.insert(oTools, c)
								c.Parent = nil
							end)

							if oHumanoid then oHumanoid:UnequipTools() end
							for _, child in pBackpack:GetChildren() do
								table.insert(oTools, child)
								child.Parent = nil
							end
						end

						--// Handle respawn and repositioning
						local newChar, newHumanoid, newPrimary;
						task.delay(0.1, pcall, p.LoadCharacter, p)
						if ev then ev:Disconnect() end

						--// Reposition if possible
						if oPos then
							newChar = p.Character ~= oChar and p.Character or p.CharacterAdded:Wait()

							if newChar then
								wait(); -- Let it finish loading character contents

								newHumanoid = newChar:FindFirstChildOfClass("Humanoid");
								newPrimary = newChar.PrimaryPart or (newHumanoid and newHumanoid.RootPart) or oChar:FindFirstChild("HumanoidRootPart");

								local forcefield = newChar:FindFirstChildOfClass("ForceField")
								if forcefield then
									forcefield:Destroy()
								end

								if newPrimary then
									newPrimary.CFrame = oPos
								else
									newChar:MoveTo(oPos.Position)
								end
							end
						end

						--// Bring previous tools back
						local newBackpack = p:FindFirstChildOfClass("Backpack")
						if newBackpack and oTools then
							newBackpack:ClearAllChildren();
							for _, t in oTools do
								t.Parent = newBackpack
							end
						end
					end)
				end
			end
		};

		Kill = {
			Prefix = Settings.Prefix;
			Commands = {"kill"};
			Args = {"player"};
			Description = "Kills the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local hum = v.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							hum.Health = 0
						end
						v.Character:BreakJoints()
					end
				end
			end
		};

		Respawn = {
			Prefix = Settings.Prefix;
			Commands = {"respawn", "re", "reset", "res"};
			Args = {"player"};
			Description = "Respawns the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					task.defer(function()
						pcall(v.LoadCharacter, v)
						Remote.Send(v, "Function", "SetView", "reset")
					end)
				end
			end
		};

		Invisible = {
			Prefix = Settings.Prefix;
			Commands = {"invisible", "invis"};
			Args = {"player"};
			Description = "Makes the target player(s) invisible";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for a, obj in v.Character:GetChildren() do
							if obj:IsA("BasePart") then
								obj.Transparency = 1
								if obj:FindFirstChild("face") then
									obj.face.Transparency = 1
								end
							elseif obj:IsA("Accoutrement") and obj:FindFirstChild("Handle") then
								obj.Handle.Transparency = 1
							elseif obj:IsA("ForceField") then
								obj.Visible = false
							elseif obj.Name == "Head" then
								local face = obj:FindFirstChildOfClass("Decal")
								if face then
									face.Transparency = 1
								end
							end
						end
					end
				end
			end
		};

		Visible = {
			Prefix = Settings.Prefix;
			Commands = {"visible", "vis", "uninvisible"};
			Args = {"player"};
			Description = "Makes the target player(s) visible";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for a, obj in v.Character:GetChildren() do
							if obj:IsA("BasePart") and obj.Name~="HumanoidRootPart" then
								obj.Transparency = 0
								if obj:FindFirstChild("face") then
									obj.face.Transparency = 0
								end
							elseif obj:IsA("Accoutrement") and obj:FindFirstChild("Handle") then
								obj.Handle.Transparency = 0
							elseif obj:IsA("ForceField") and obj.Name ~="ADONIS_FULLGOD" then
								obj.Visible = true
							elseif obj.Name == "Head" then
								local face = obj:FindFirstChildOfClass("Decal")
								if face then
									face.Transparency = 0
								end
							end
						end
					end
				end
			end
		};

		Lock = {
			Prefix = Settings.Prefix;
			Commands = {"lock", "lockplr", "lockplayer"};
			Args = {"player"};
			Description = "Locks the target player(s), preventing the use of btools on the character";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for a, obj in v.Character:GetChildren() do
							if obj:IsA("BasePart") then
								obj.Locked = true
							elseif obj:IsA("Accoutrement") and obj:FindFirstChild("Handle") then
								obj.Handle.Locked = true
							end
						end
					end
				end
			end
		};

		UnLock = {
			Prefix = Settings.Prefix;
			Commands = {"unlock", "unlockplr", "unlockplayer"};
			Args = {"player"};
			Description = "UnLocks the the target player(s), makes it so you can use btools on them";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for a, obj in v.Character:GetChildren() do
							if obj:IsA("BasePart") then
								obj.Locked = false
							elseif obj:IsA("Accoutrement") and obj:FindFirstChild("Handle") then
								obj.Handle.Locked = false
							end
						end
					end
				end
			end
		};

		Time = {
			Prefix = Settings.Prefix;
			Commands = {"time", "timeofday"};
			Args = {"time", "optional player"};
			Description = "Change Time";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[2] then
					for _, v in service.GetPlayers(plr, args[2]) do
						Remote.SetLighting(v, "TimeOfDay", args[1])
					end
				else
					Functions.SetLighting("TimeOfDay", args[1])
				end
			end
		};

		Give = {
			Prefix = Settings.Prefix;
			Commands = {"give", "tool"};
			Args = {"player", "tool"};
			Description = "Gives the target player(s) the desired tool(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local found = {}
				local temp = service.New("Folder")
				for _, tool in if Settings.RecursiveTools then Settings.Storage:GetDescendants() else Settings.Storage:GetChildren() do
					if tool:IsA("BackpackItem") then
						if string.lower(args[2]) == "all" or string.sub(string.lower(tool.Name), 1, #args[2])==string.lower(args[2]) then
							tool.Archivable = true
							local parent = tool.Parent
							if not parent.Archivable then
								tool.Parent = temp
							end
							table.insert(found, tool:Clone())
							tool.Parent = parent
						end
					end
				end
				if #found > 0 then
					for _, v in service.GetPlayers(plr, args[1]) do
						for k, t in found do
							t:Clone().Parent = v.Backpack
						end
					end
				else
					error("Couldn't find anything to give")
				end
				if temp then
					temp:Destroy()
				end
			end
		};

		RemoveTools = {
			Prefix = Settings.Prefix;
			Commands = {"removetools", "notools", "rtools", "deltools"};
			Args = {"player"};
			Description = "Remove the target player(s)'s tools";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local hum = v.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:UnequipTools() end
						for _, tool in v.Character:GetChildren() do
							if tool:IsA("BackpackItem") then tool:Destroy() end
						end
					end
					local backpack = v:FindFirstChildOfClass("Backpack")
					if backpack then
						for _, tool in backpack:GetChildren() do
							if tool:IsA("BackpackItem") then tool:Destroy() end
						end
					end
				end
			end
		};

		RemoveTool = {
			Prefix = Settings.Prefix;
			Commands = {"removetool", "rtool", "deltool"};
			Args = {"player", "tool name"};
			Description = "Remove a specified tool from the target player(s)'s backpack";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for _, tool in v.Character:GetChildren() do
							if tool:IsA("BackpackItem") and string.sub(tool.Name:lower(), 1, #args[2])== args[2]:lower() then
								local hum = v.Character:FindFirstChildOfClass("Humanoid")
								if hum then hum:UnequipTools() end
								tool:Destroy()
							end
						end
					end
					local backpack = v:FindFirstChildOfClass("Backpack")
					if backpack then
						for _, tool in backpack:GetChildren() do
							if tool:IsA("BackpackItem") and string.sub(tool.Name:lower(), 1, #args[2])== args[2]:lower() then
								tool:Destroy()
							end
						end
					end
				end
			end
		};

		Damage = {
			Prefix = Settings.Prefix;
			Commands = {"damage", "hurt"};
			Args = {"player", "number"};
			Description = "Removes <number> HP from the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum:TakeDamage(args[2])
					end
				end
			end
		};

		SetHealth = {
			Prefix = Settings.Prefix;
			Commands = {"health", "sethealth"};
			Args = {"player", "number"};
			Description = "Set the target player(s)'s health and max health to <number>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.MaxHealth = args[2]
						hum.Health = hum.MaxHealth
					end
				end
			end
		};

		Speed = {
			Prefix = Settings.Prefix;
			Commands = {"speed", "setspeed", "walkspeed", "ws"};
			Args = {"player", "number"};
			Description = "Set the target player(s)'s WalkSpeed to <number>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(not args[2] or args[2]:lower() ~= "inf", "Speed cannot be infinite")
				local speed = tonumber(args[2]) or 16
				assert(speed >= 0, "Speed cannot be negative")
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.WalkSpeed = speed
						if Settings.CommandFeedback then
							Remote.MakeGui(v, "Notification", {
								Title = "Notification";
								Message = `Character walk speed has been set to {speed}`;
								Time = 15;
							})
						end
					end
				end
			end
		};

		SetTeam = {
			Prefix = Settings.Prefix;
			Commands = {"team", "setteam", "changeteam"};
			Args = {"player", "team"};
			Description = "Set the target player(s)'s team to <team>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing team name")
				for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
					for a, tm in service.Teams:GetChildren() do
						if string.sub(string.lower(tm.Name), 1, #args[2]) == string.lower(args[2]) then
							v.Team = tm
							if Settings.CommandFeedback then
								Functions.Notification("Team", `You are now on the '{tm.Name}' team.`, {v}, 15, "Info") -- Functions.Notification(title,message,player,time,icon)
							end
						end
					end
				end
			end
		};

		Unteam = {
			Prefix = Settings.Prefix;
			Commands = {"unteam", "removefromteam", "neutral"};
			Args = {"player"};
			Description = "Takes the target player(s) off of a team and sets them to 'Neutral' ";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, player in Functions.GetPlayers(plr, args[1]) do
					player.Neutral = true
					player.Team = nil
					player.TeamColor = BrickColor.new(194) -- Neutral Team
					if Settings.CommandFeedback then
						Functions.Notification("Team", "Your team has been reset and you are now on the Neutral team.", {player}, 15, "Info") -- Functions.Notification(title,message,player,time,icon)
					end
				end
			end
		};

		TeamList = {
			Prefix = Settings.Prefix;
			Commands = {"teams", "teamlist", "manageteams"};
			Args = {};
			Description = "Opens the teams manager GUI";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				Remote.MakeGui(plr, "Teams", {
					CmdPrefix = Settings.Prefix; CmdPlayerPrefix = Settings.PlayerPrefix; CmdSpecialPrefix = Settings.SpecialPrefix; CmdSplitKey = Settings.SplitKey;
				})
			end
		};

		Teleport = {
			Prefix = Settings.Prefix;
			Commands = {"tp", "teleport", "transport"};
			Args = {"player1", "player2"};
			Description = "Teleport player1(s) to player2, a waypoint, or specific coords, use :tp player1 waypoint-WAYPOINTNAME to use waypoints, x,y,z for coords";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[2] and (string.match(args[2], "^waypoint%-(.*)") or string.match(args[2], "wp%-(.*)")) then
					local m = string.match(args[2], "^waypoint%-(.*)") or string.match(args[2], "wp%-(.*)")
					local point

					for i, v in Variables.Waypoints do
						if string.sub(string.lower(i), 1, #m)==string.lower(m) then
							point=v
						end
					end

					for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
						if point then
							if not v.Character then
								continue
							end
							if workspace.StreamingEnabled == true then
								v:RequestStreamAroundAsync(point)
							end
							local Humanoid = v.Character:FindFirstChildOfClass("Humanoid")
							local root = (Humanoid and Humanoid.RootPart or v.Character.PrimaryPart or v.Character:FindFirstChild("HumanoidRootPart"))
							local FlightPos = root:FindFirstChild("ADONIS_FLIGHT_POSITION")
							local FlightGyro = root:FindFirstChild("ADONIS_FLIGHT_GYRO")
							if Humanoid then
								if Humanoid.SeatPart~=nil then
									Functions.RemoveSeatWelds(Humanoid.SeatPart)
								end
								if Humanoid.Sit then
									Humanoid.Sit = false
									Humanoid.Jump = true
								end
							end
							if FlightPos and FlightGyro then
								FlightPos.Position = root.Position
								FlightGyro.CFrame = root.CFrame
							end

							wait()
							if root then
								root.CFrame = CFrame.new(point)
								if FlightPos and FlightGyro then
									FlightPos.Position = root.Position
									FlightGyro.CFrame = root.CFrame
								end
							end
						end
					end

					if not point then Functions.Hint("Waypoint "..m.." was not found.", {plr}) end
				elseif args[2] and string.find(args[2], ",") then
					local x, y, z = string.match(args[2], "(.*),(.*),(.*)")
					for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
						if not v.Character or not v.Character:FindFirstChild("HumanoidRootPart") then continue end

						if workspace.StreamingEnabled == true then
							v:RequestStreamAroundAsync(Vector3.new(x,y,z))
						end
						local Humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						local root = v.Character:FindFirstChild('HumanoidRootPart')
						local FlightPos = root:FindFirstChild("ADONIS_FLIGHT_POSITION")
						local FlightGyro = root:FindFirstChild("ADONIS_FLIGHT_GYRO")
						if Humanoid then
							if Humanoid.SeatPart~=nil then
								Functions.RemoveSeatWelds(Humanoid.SeatPart)
							end
							if Humanoid.Sit then
								Humanoid.Sit = false
								Humanoid.Jump = true
							end
						end
						if FlightPos and FlightGyro then
							FlightPos.Position = root.Position
							FlightGyro.CFrame = root.CFrame
						end
						wait()
						root.CFrame = CFrame.new(Vector3.new(tonumber(x), tonumber(y), tonumber(z)))
						if FlightPos and FlightGyro then
							FlightPos.Position = root.Position
							FlightGyro.CFrame = root.CFrame
						end
					end
				else
					local target = service.GetPlayers(plr, args[2], { NoFakePlayer = true })[1]
					local players = service.GetPlayers(plr, args[1], { NoFakePlayer = true })
					if #players == 1 and players[1] == target then
						local n = players[1]
						if n.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("HumanoidRootPart") then
							local Humanoid = n.Character:FindFirstChildOfClass("Humanoid")
							local root = n.Character:FindFirstChild('HumanoidRootPart')
							local FlightPos = root:FindFirstChild("ADONIS_FLIGHT_POSITION")
							local FlightGyro = root:FindFirstChild("ADONIS_FLIGHT_GYRO")

							if workspace.StreamingEnabled == true then
								n:RequestStreamAroundAsync((target.Character.HumanoidRootPart.CFrame*CFrame.Angles(0, math.rad(90/#players*1), 0)*CFrame.new(5+.2*#players, 0, 0))*CFrame.Angles(0, math.rad(90), 0).Position)
							end

							if Humanoid then
								if Humanoid.SeatPart~=nil then
									Functions.RemoveSeatWelds(Humanoid.SeatPart)
								end
								if Humanoid.Sit then
									Humanoid.Sit = false
									Humanoid.Jump = true
								end
							end
							if FlightPos and FlightGyro then
								FlightPos.Position = root.Position
								FlightGyro.CFrame = root.CFrame
							end
							wait()
							root.CFrame = (target.Character.HumanoidRootPart.CFrame*CFrame.Angles(0, math.rad(90/#players*1), 0)*CFrame.new(5+.2*#players, 0, 0))*CFrame.Angles(0, math.rad(90), 0)
							if FlightPos and FlightGyro then
								FlightPos.Position = root.Position
								FlightGyro.CFrame = root.CFrame
							end
						end
					else
						local targ_root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
						if targ_root then
							for k, n in players do
								if n ~= target then
									local Character = n.Character
									if not Character or not Character:FindFirstChild("HumanoidRootPart") then
										continue
									end

									if workspace.StreamingEnabled == true then
										n:RequestStreamAroundAsync((targ_root.CFrame*CFrame.Angles(0, math.rad(90/#players*k), 0)*CFrame.new(5+.2*#players, 0, 0))*CFrame.Angles(0, math.rad(90), 0).Position)
									end

									local Humanoid = Character:FindFirstChildOfClass("Humanoid")
									local root = Character:FindFirstChild('HumanoidRootPart')
									local FlightPos = root:FindFirstChild("ADONIS_FLIGHT_POSITION")
									local FlightGyro = root:FindFirstChild("ADONIS_FLIGHT_GYRO")
									if Humanoid then
										if Humanoid.SeatPart ~= nil then
											Functions.RemoveSeatWelds(Humanoid.SeatPart)
										end
										if Humanoid.Sit then
											Humanoid.Sit = false
											Humanoid.Jump = true
										end
									end
									if FlightPos and FlightGyro then
										FlightPos.Position = root.Position
										FlightGyro.CFrame = root.CFrame
									end
									wait()
									if root and targ_root then
										root.CFrame = (targ_root.CFrame*CFrame.Angles(0, math.rad(90/#players*k), 0)*CFrame.new(5+.2*#players, 0, 0))*CFrame.Angles(0, math.rad(90), 0)
										if FlightPos and FlightGyro then
											FlightPos.Position = root.Position
											FlightGyro.CFrame = root.CFrame
										end
									end
								end
							end
						end
					end
				end
			end
		};

		Bring = {
			Prefix = Settings.Prefix;
			Commands = {"bring"};
			Args = {"player"};
			Description = "Teleports the target player(s) to your position";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local players = service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)"))
				if #players < 10 or not Commands.MassBring or Remote.GetGui(plr, "YesNoPrompt", {
					Title = "Suggestion";
					Icon = server.MatIcons.Feedback;
					Question = `Would you like to use {Settings.Prefix}massbring instead? (Arranges the {#players} players in rows.)`;
					}) ~= "Yes"
				then
					Commands.Teleport.Function(plr, {args[1], `@{plr.Name}`})
				else
					Process.Command(plr, `{Settings.Prefix}massbring{Settings.SplitKey}{args[1]}`)
				end
			end
		};

		To = {
			Prefix = Settings.Prefix;
			Commands = {"to", "goto"};
			Args = {"destination  ('<player>'/'waypoint-<name>'/'<x>,<y>,<z>')"};
			Description = "Teleports you to the target player, waypoint or coordinates";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				Commands.Teleport.Function(plr, {`@{plr.Name}`, if args[1] then args[1] else "me"})
			end
		};

		Change = {
			Prefix = Settings.Prefix;
			Commands = {"change", "leaderstat", "stat", "changestat"};
			Args = {"player", "stat", "value"};
			Filter = true;
			Description = "Change the target player(s)'s leaderstat <stat> value to <value>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local statName = assert(args[2], "Missing stat name (argument #2)")
				for _, v in service.GetPlayers(plr, args[1], { NoFakePlayer = true }) do
					local leaderstats = v:FindFirstChild("leaderstats")
					if leaderstats then
						local absoluteMatch = leaderstats:FindFirstChild(statName)
						if absoluteMatch and absoluteMatch:IsA("ValueBase") then
							absoluteMatch.Value = args[3]
						else
							for _, st in leaderstats:GetChildren() do
								if st:IsA("ValueBase") and string.match(st.Name:lower(), `^{statName:lower()}`) then
									st.Value = args[3]
								end
							end
						end
					else
						Functions.Hint(`{service.FormatPlayer(v)} doesn't have a leaderstats folder`, {plr})
					end
				end
			end
		};

		AddToStat = {
			Prefix = Settings.Prefix;
			Commands = {"add", "addtostat", "addstat"};
			Args = {"player", "stat", "value"};
			Description = "Add <value> to <stat>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local statName = assert(args[2], "Missing stat name (argument #2)")
				local valueToAdd = assert(tonumber(args[3]), "Missing/invalid numerical value to add (argument #3)")
				for _, v in service.GetPlayers(plr, args[1]) do
					local leaderstats = v:FindFirstChild("leaderstats")
					if leaderstats then
						local absoluteMatch = leaderstats:FindFirstChild(statName)
						if absoluteMatch and (absoluteMatch:IsA("IntValue") or absoluteMatch:IsA("NumberValue")) then
							absoluteMatch.Value += valueToAdd
						else
							for _, st in leaderstats:GetChildren() do
								if (st:IsA("IntValue") or st:IsA("NumberValue")) and string.match(st.Name:lower(), `^{statName:lower()}`) then
									st.Value += valueToAdd
								end
							end
						end
					else
						Functions.Hint(`{service.FormatPlayer(v)} doesn't have a leaderstats folder`, {plr})
					end
				end
			end
		};

		SubtractFromStat = {
			Prefix = Settings.Prefix;
			Commands = {"subtract", "minusfromstat", "minusstat", "subtractstat"};
			Args = {"player", "stat", "value"};
			Description = "Subtract <value> from <stat>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local statName = assert(args[2], "Missing stat name (argument #2)")
				local valueToSubtract = assert(tonumber(args[3]), "Missing/invalid numerical value to subtract (argument #3)")
				for _, v in service.GetPlayers(plr, args[1]) do
					local leaderstats = v:FindFirstChild("leaderstats")
					if leaderstats then
						local absoluteMatch = leaderstats:FindFirstChild(statName)
						if absoluteMatch and (absoluteMatch:IsA("IntValue") or absoluteMatch:IsA("NumberValue")) then
							absoluteMatch.Value -= valueToSubtract
						else
							for _, st in leaderstats:GetChildren() do
								if (st:IsA("IntValue") or st:IsA("NumberValue")) and string.match(st.Name:lower(), `^{statName:lower()}`) then
									st.Value -= valueToSubtract
								end
							end
						end
					else
						Functions.Hint(`{service.FormatPlayer(v)} doesn't have a leaderstats folder`, {plr})
					end
				end
			end
		};
		
		Name = {
			Prefix = Settings.Prefix;
			Commands = {"name", "rename"};
			Args = {"player", "name/hide"};
			Filter = true;
			Description = "Name the target player(s) <name> or say hide to hide their character name";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("Head") then
						for a, mod in v.Character:GetChildren() do
							if mod:FindFirstChild("NameTag") then
								v.Character.Head.Transparency = 0
								mod:Destroy()
							end
						end

						local char = v.Character
						local head = char:FindFirstChild("Head")
						local mod = service.New("Model", char)
						local cl = char.Head:Clone()
						local hum = service.New("Humanoid", mod)
						mod.Name = args[2] or ""
						cl.Parent = mod
						hum.Name = "NameTag"
						hum.MaxHealth=v.Character.Humanoid.MaxHealth
						wait()
						hum.Health=v.Character.Humanoid.Health

						if string.lower(args[2])=="hide" then
							mod.Name = ""
							hum.MaxHealth = 0
							hum.Health = 0
						else
							v.Character.Humanoid.Changed:Connect(function(c)
								hum.MaxHealth = v.Character.Humanoid.MaxHealth
								wait()
								hum.Health = v.Character.Humanoid.Health
							end)
						end

						cl.CanCollide = false
						local weld = service.New("Weld", cl) weld.Part0 = cl weld.Part1 = char.Head
						char.Head.Transparency = 1
					end
				end
			end
		};

		UnName = {
			Prefix = Settings.Prefix;
			Commands = {"unname", "fixname"};
			Args = {"player"};
			Description = "Put the target player(s)'s back to normal";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("Head") then
						for a, mod in v.Character:GetChildren() do
							if mod:FindFirstChild("NameTag") then
								v.Character.Head.Transparency = 0
								mod:Destroy()
							end
						end
					end
				end
			end
		};

		LoopHeal = {
			Prefix = Settings.Prefix;
			Commands = {"loopheal"};
			Args = {"player"};
			Description = "Continuously heals the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					task.defer(function()
						service.StartLoop(`{v.UserId}LOOPHEAL`, 0.1, function()
							if not v or v.Parent ~= service.Players then
								service.StopLoop(`{v.UserId}LOOPHEAL`)
							end

							local Character = v.Character
							if Character then
								local Humanoid = Character:FindFirstChildOfClass("Humanoid")
								if Humanoid then
									Humanoid.Health = Humanoid.MaxHealth
								end
							end
						end)
					end)
				end
			end
		};

		UnLoopHeal = {
			Prefix = Settings.Prefix;
			Commands = {"unloopheal"};
			Args = {"player"};
			Description = `Undoes {Settings.Prefix}loopheal`;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.StopLoop(`{v.UserId}LOOPHEAL`)
				end
			end
		};

		ServerLog = {
			Prefix = Settings.Prefix;
			Commands = {"serverlog", "serverlogs", "serveroutput"};
			Args = {"autoupdate? (default: false)"};
			Description = "View server log";
			AdminLevel = "Moderators";
			NoFilter = true;
			ListUpdater = function(plr: Player)
				local MESSAGE_TYPE_COLORS = {
					[Enum.MessageType.MessageWarning] = Color3.fromRGB(221, 187, 13),
					[Enum.MessageType.MessageError] = Color3.fromRGB(255, 50, 14),
					[Enum.MessageType.MessageInfo] = Color3.fromRGB(14, 78, 255)
				}
				local logHistory: {{message: string, messageType: Enum.MessageType, timestamp: number}} = service.LogService:GetLogHistory()
				local tab = table.create(#logHistory)
				for i = #logHistory, 1, -1 do
					local log = logHistory[i]
					for i, v in service.ExtractLines(log.message) do
						table.insert(tab, {
							Text = v;
							Time = if i == 1 then log.timestamp else nil;
							Desc = log.messageType.Name:match("^Message(.+)$");
							Color = MESSAGE_TYPE_COLORS[log.messageType];
						})
					end
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Server Log";
					Table = Logs.ListUpdaters.ServerLog(plr);
					Update = "ServerLog";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Stacking = true;
					Sanitize = true;
					TextSelectable = true;
				})
			end
		};

		LocalLog = {
			Prefix = Settings.Prefix;
			Commands = {"locallog", "clientlog", "locallogs", "localoutput", "clientlogs"};
			Args = {"player", "autoupdate? (default: false)"};
			Description = "View local log";
			AdminLevel = "Moderators";
			NoFilter = true;
			ListUpdater = function(plr: Player, target: Player)
				return if target and target.Parent then Remote.Get(target, "ClientLog") else {"Player is currently unreachable"}
			end;
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(plr, "List", {
						Title = `{service.FormatPlayer(v)}'s Local Log`;
						Table = Logs.ListUpdaters.LocalLog(plr, v);
						Update = "LocalLog";
						UpdateArg = v;
						AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
						Stacking = true;
						Sanitize = true;
						TextSelectable = true;
					})
				end
			end
		};

		ErrorLogs = {
			Prefix = Settings.Prefix;
			Commands = {"errorlogs", "debuglogs", "errorlog", "errors", "debuglog", "scripterrors", "adminerrors"};
			Args = {"autoupdate? (default: false)"};
			Description = "View script error log";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local tab = table.create(#Logs.Errors)
				for i, v in Logs.Errors do
					table.insert(tab, i, {
						Time = v.Time;
						Text = `{v.Text}: {v.Desc}`;
						Desc = tostring(v.Desc);
					})
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Errors";
					Table = Logs.ListUpdaters.ErrorLogs(plr);
					Dots = true;
					Update = "ErrorLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Sanitize = true;
					Stacking = true;
					TextSelectable = true;
				})
			end
		};

		ExploitLogs = {
			Prefix = Settings.Prefix;
			Commands = {"exploitlogs", "exploitlog"};
			Args = {"autoupdate? (default: false)"};
			Description = "View the exploit logs for the server OR a specific player";
			AdminLevel = "Moderators";
			ListUpdater = "Exploit";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Exploit Logs";
					Tab = Logs.ListUpdaters.ExploitLogs(plr);
					Dots = true;
					Update = "ExploitLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		JoinLogs = {
			Prefix = Settings.Prefix;
			Commands = {"joinlogs", "joins", "joinhistory"};
			Args = {"autoupdate? (default: false)"};
			Description = "Displays the current join logs for the server";
			AdminLevel = "Moderators";
			ListUpdater = "Joins";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Join Logs";
					Tab = Logs.ListUpdaters.JoinLogs(plr);
					Dots = true;
					Update = "JoinLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
				})
			end
		};

		LeaveLogs = {
			Prefix = Settings.Prefix;
			Commands = {"leavelogs", "leaves", "leavehistory"};
			Args = {"autoupdate? (default: false)"};
			Description = "Displays the current leave logs for the server";
			AdminLevel = "Moderators";
			ListUpdater = "Leaves";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Leave Logs";
					Tab = Logs.ListUpdaters.LeaveLogs(plr);
					Dots = true;
					Update = "LeaveLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
				})
			end
		};

		ChatLogs = {
			Prefix = Settings.Prefix;
			Commands = {"chatlogs", "chats", "chathistory"};
			Args = {"autoupdate? (default: false)"};
			Description = "Displays the current chat logs for the server";
			AdminLevel = "Moderators";
			ListUpdater = "Chats";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Chat Logs";
					Tab = Logs.ListUpdaters.ChatLogs(plr);
					Dots = true;
					Update = "ChatLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		RemoteLogs = {
			Prefix = Settings.Prefix;
			Commands = {"remotelogs", "remotelog", "rlogs", "remotefires", "remoterequests"};
			Args = {"autoupdate? (default: false)"};
			Description = "View the remote logs for the server";
			AdminLevel = "Moderators";
			ListUpdater = "RemoteFires";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Remote Logs";
					Table = Logs.ListUpdaters.RemoteLogs(plr);
					Dots = true;
					Update = "RemoteLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		ScriptLogs = {
			Prefix = Settings.Prefix;
			Commands = {"scriptlogs", "scriptlog", "adminlogs", "adminlog", "scriptlogs"};
			Args = {"autoupdate? (default: false)"};
			Description = "View the admin logs for the server";
			AdminLevel = "Moderators";
			ListUpdater = "Script";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Script Logs";
					Table = Logs.ListUpdaters.ScriptLogs(plr);
					Dots = true;
					Update = "ScriptLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		Logs = {
			Prefix = Settings.Prefix;
			Commands = {"logs", "log", "commandlogs"};
			Args = {"autoupdate? (default: false)"};
			Description = "View the command logs for the server";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local tab = table.create(#Logs.Commands)
				for i, v in Logs.Commands do
					table.insert(tab, i, {
						Time = v.Time;
						Text = `{v.Text}: {v.Desc}`;
						Desc = v.Desc;
					})
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Command Logs";
					Table = Logs.ListUpdaters.Logs(plr);
					Dots = true;
					Update = "Logs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		OldLogs = {
			Prefix = Settings.Prefix;
			Commands = {"oldlogs", "oldserverlogs", "oldcommandlogs"};
			Args = {"autoupdate? (default: false)"};
			Description = "View the command logs for previous servers ordered by time";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				if Core.DataStore then
					local tab = table.create(1000)
					local data = Core.GetData("OldCommandLogs")
					if data then
						for i, v in data do
							table.insert(tab, i, {
								Time = v.Time,
								Text = `{v.Text}: {v.Desc}`,
								Desc = v.Desc
							})
						end
					end
					return tab
				end
				return {"DataStore is not available in game"}
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Old Server Logs";
					Table = Logs.ListUpdaters.OldLogs(plr);
					Dots = true;
					Update = "OldLogs";
					AutoUpdate = if args[1] and (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil;
					Sanitize = true;
					Stacking = true;
					TimeOptions = {
						WithDate = true;
					};
				})
			end
		};

		ShowLogs = {
			Prefix = Settings.Prefix;
			Commands = {"showlogs", "showcommandlogs"};
			Args = {"player", "autoupdate? (default: false)"};
			Description = "Shows the target player(s) the command logs.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local str = `{Settings.Prefix}logs{args[2] or ""}`
				for _, v in service.GetPlayers(plr, args[1]) do
					Admin.RunCommandAsPlayer(str, v)
				end
			end
		};

		Mute = {
			Prefix = Settings.Prefix;
			Commands = {"mute", "silence"};
			Args = {"player"};
			Description = "Makes it so the target player(s) can't talk";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				for _, v in service.GetPlayers(plr, args[1]) do
					if Admin.CheckAuthority(plr, v, "mute", false) then
						--Remote.LoadCode(v,[[service.StarterGui:SetCoreGuiEnabled("Chat", false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
						local check = true
						for _, m in Settings.Muted do
							if Admin.DoCheck(v, m) then
								check = false
							end
						end

						if check then
							table.insert(Settings.Muted, `{v.Name}:{v.UserId}`)
						end
					end
				end
			end
		};

		UnMute = {
			Prefix = Settings.Prefix;
			Commands = {"unmute", "unsilence"};
			Args = {"player"};
			Description = "Makes it so the target player(s) can talk again. No effect if on Trello mute list.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					for k, m in Settings.Muted do
						if Admin.DoCheck(v, m) then
							table.remove(Settings.Muted, k)
							--Remote.LoadCode(v,[[if not client.Variables.CustomChat then service.StarterGui:SetCoreGuiEnabled("Chat", true) client.Variables.ChatEnabled = false end client.Variables.Muted = true]])
						end
					end
				end
			end
		};

		MuteList = {
			Prefix = Settings.Prefix;
			Commands = {"mutelist", "mutes", "muted"};
			Args = {};
			Description = "Shows a list of currently muted players";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local list = table.clone(Settings.Muted)
				for _, v in HTTP.Trello.Mutes do
					table.insert(list, `[Trello] {v}`)
				end

				Remote.MakeGui(plr, "List", {Title = "Mute List", Table = list})
			end
		};

		ServerPerfStats = {
			Prefix = Settings.Prefix;
			Commands = {"perfstats", "performancestats", "serverstats"};
			Args = {"autoupdate? (default: true)"};
			Description = "Shows you technical server performance statistics";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local perfStats = {
					{"ContactsCount"; "How many parts are currently in contact with one another"},
					{"DataReceiveKbps"; "Roughly how many kB/s of data are being received by the server"},
					{"DataSendKbps"; "Roughly how many kB/s of data are being sent by the server"},
					{"HeartbeatTimeMs"; "The total amount of time in ms it takes long it takes to update all Task Scheduler jobs"},
					{"InstanceCount"; "How many Instances are currently in memory"},
					{"MovingPrimitivesCount"; "How many physically simulated components are currently moving in the game world"},
					{"PhysicsReceiveKbps"; "Roughly how many kB/s of physics data are being received by the server"},
					{"PhysicsSendKbps"; "Roughly how many kB/s of physics data are being sent by the server"},
					{"PhysicsStepTimeMs"; "How long it takes for the physics engine to update its current state, in milliseconds"},
					{"PrimitivesCount"; "How many physically simulated components currently exist in the game world"},
				};
				local tab = table.create(#perfStats)
				for _, v in perfStats do
					table.insert(tab, {Text = `{v[1]}: {tostring(service.Stats[v[1]]):sub(1, 7)}`; Desc = v[2];})
				end
				return tab
			end;
			Function = function(plr: Player, args: {[number]:string})
				Remote.RemoveGui(plr, "ServerPerfStats")
				Remote.MakeGui(plr, "List", {
					Name = "ServerPerfStats";
					Title = "Server Stats";
					Icon = server.MatIcons.Leaderboard;
					Tab = Logs.ListUpdaters.ServerPerfStats(plr);
					AutoUpdate = if not args[1] or args[1]:lower() == "true" or args[1]:lower() == "yes" then 1 else nil;
					Update = "ServerPerfStats";
				})
			end
		};

		SelectPlayers = {
			Prefix = Settings.Prefix;
			Commands = {"select", "selectplayers", "count",  "countplayers", "getplayers"};
			Args = {"player(s)", "autoupdate? (default: false)"};
			Description = `Shows you a list and count of players selected in the supplied argument, ex: '{Settings.Prefix}select %raiders true' to monitor people in the 'raiders' team`;
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, selection: string?)
				local players = service.GetPlayers(plr, selection, {DontError = true; NoFakePlayer = true;})
				local tab = {
					`Specified: "{selection or `{Settings.SpecialPrefix}me`}"`,
					`# Players: {#players}`,
					"―――――――――――――――――――――――",
				}
				for _, v: Player in players do
					table.insert(tab, {
						Text = service.FormatPlayer(v);
						Desc = `ID: {v.UserId}`;
					})
				end
				return tab
			end;
			Function = function(plr: Player, args: {[number]:string})
				Remote.MakeGui(plr, "List", {
					Title = "Selected Players";
					Icon = server.MatIcons.People;
					Tab = Logs.ListUpdaters.SelectPlayers(plr, args[1]);
					Update = "SelectPlayers";
					UpdateArg = args[1];
					AutoUpdate = if args[2] and (args[2]:lower() == "true" or args[2]:lower() == "yes") then 1 else nil;
				})
			end
		};

		HealthList = {
			Prefix = Settings.Prefix;
			Commands = {"healthlist", "healthlogs", "healths", "hlist","hlogs"};
			Args = {"autoupdate? (default: true)"};
			Description = "Shows a list of all players' current and max healths.";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, args: {string})
				local rawTable = {}
				for _, v in Functions.GetPlayers(plr, "all") do
					if v.Character and v.Character:FindFirstChildOfClass("Humanoid") then
						table.insert(rawTable, {service.FormatPlayer(v), v.Character:FindFirstChildOfClass("Humanoid").Health, v.Character:FindFirstChildOfClass("Humanoid").MaxHealth})
					else
						table.insert(rawTable, {service.FormatPlayer(v), 0, 0})
					end
				end

				table.sort(rawTable, function(a,b)
					if a[3] == b[3] then
						if a[2] == b[2] then
							return(a[1] < b[1])
						else
							return(a[2] > b[2])
						end
					else
						return(a[3] > b[3])
					end
				end)

				local goddedCheck = false
				local normalCheck = false
				local godTable = {}
				local zeroTable = {}
				local normalTable = {}

				for _, v in rawTable do
					if tostring(v[3]) == "inf" then
						table.insert(godTable, v)
						goddedCheck = true
					else
						if v[3] <= 0 then
							table.insert(zeroTable, v)
							normalCheck = true
						else
							table.insert(normalTable, v)
							normalCheck = true
						end
					end
				end

				local logTable = {}

				if goddedCheck == true then
					table.insert(logTable, "<b><u>Godded Players: </u></b>")
				end

				for _, v in godTable do
					local color = "255,0,0"
					table.insert(logTable, `{v[1]} :: <font color = "rgb({color})">[{math.round(v[2])}/{math.round(v[3])}]</font>`)
				end

				if normalCheck == true then
					table.insert(logTable, "<b><u>Normal Players: </u></b>")
				end

				for _, v in normalTable do
					local color
					if v[2]/v[3] >= .5 then
						color =  `{math.round(100 + 155 * (v[2]/v[3] * -2 + 2))}, 255, 100`
					else
						color =  `255, {math.round(100 + 155 * v[2]/v[3] * 2)}, 100`
					end
					table.insert(logTable, `{v[1]} :: <font color = "rgb({color})">[{math.round(v[2])}/{math.round(v[3])}]</font>`)
				end

				for _, v in zeroTable do
					local color = "255, 100, 100"
					table.insert(logTable, `{v[1]} :: <font color = "rgb({color})">[N/A]</font>`)
				end

				return logTable
			end;

			Function = function(plr: Player, args: {string})
				Functions.Hint("Fetching player healths.", {plr})
				Remote.MakeGui(plr, "List", {
					Title = "Player Healths";
					Tab = Logs.ListUpdaters.HealthList(plr);
					Dots = true;
					Update = "HealthList";
					AutoUpdate = if args[1] and (args[1]:lower() == "false" or args[1]:lower() == "no") then nil else 1;
					Sanitize = false;
					Stacking = true;
					RichText = true;
				})
			end
		};
	}
end
