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
						Functions.Hint("Kicked "..playerName, {plr})
					end
				end
			end
		};

		ESP = {
			Prefix = Settings.Prefix;
			Commands = {"esp"};
			Args = {"target (optional)", "brickcolor (optional)"};
			Filter = true;
			Description = "Allows you to see <target> (or all humanoids if no target is supplied) through walls";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				Remote.Send(plr, "Function", "CharacterESP", false)

				if args[1] then
					for _2, v2 in service.GetPlayers(plr, args[1]) do
						if not v2.Character then
							continue
						end

						Remote.Send(plr, "Function", "CharacterESP", true, v2.Character, args[2] and BrickColor.new(args[2]).Color)
					end
				else
					Remote.Send(plr, "Function", "CharacterESP", true)
				end
			end
		};

		UnESP = {
			Prefix = Settings.Prefix;
			Commands = {"unesp"};
			Args = {};
			Filter = true;
			Description = "Removes ESP";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				Remote.Send(plr, "Function", "CharacterESP", false)
			end
		};

		Thru = {
			Prefix = Settings.Prefix;
			Commands = {"thru", "pass", "through"};
			Args = {};
			Description = "Lets you pass through an object or a wall";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if plr.Character:FindFirstChild("HumanoidRootPart") then
					if plr.Character.Humanoid.SeatPart~=nil then
						Functions.RemoveSeatWelds(plr.Character.Humanoid.SeatPart)
					end
					if plr.Character.Humanoid.Sit then
						plr.Character.Humanoid.Sit = false
						plr.Character.Humanoid.Jump = true
					end
					wait()
					plr.Character.HumanoidRootPart.CFrame = (plr.Character.HumanoidRootPart.CFrame*CFrame.Angles(0, math.rad(90), 0)*CFrame.new(5+.2, 0, 0))*CFrame.Angles(0, math.rad(90), 0)
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
							Text = tostring(v.Name)..":"..tostring(v.UserId),
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

		SlowMode = {
			Prefix = Settings.Prefix;
			Commands = {"slowmode"};
			Args = {"seconds or \"disable\""};
			Description = "Chat Slow Mode";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = args[1] and tonumber(args[1]) --math.min(tonumber(args[1]), 120)

				if num then
					Admin.SlowMode = num;
					Functions.Hint("Chat slow mode enabled (".. num .."s)", service.GetPlayers())
				else
					Admin.SlowMode = nil;
					table.clear(Admin.SlowCache)
					Functions.Hint("Chat slow mode disabled", {plr})
				end
			end
		};

		Countdown = {
			Prefix = Settings.Prefix;
			Commands = {"countdown", "timer", "cd"};
			Args = {"time (in seconds)"};
			Description = "Countdown";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = assert(tonumber(args[1]), "Missing or invalid time value (must be a number)")
				assert(num <= 1000, "Countdown cannot be longer than 1000 seconds.")
				assert(num >= 0, "Countdown cannot be negative.")
				for _, v in service.GetPlayers() do
					Remote.MakeGui(v, "Countdown", {
						Time = math.round(num);
					})
				end
			end
		};

		CountdownPM = {
			Prefix = Settings.Prefix;
			Commands = {"countdownpm", "timerpm", "cdpm"};
			Args = {"player", "time (in seconds)"};
			Description = "Countdown on a target player(s) screen.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing target player and time value!")
				local num = assert(tonumber(args[2]), "Missing or invalid time value (must be a number)")
				assert(num <= 1000, "Countdown cannot be longer than 1000 seconds.")
				assert(num >= 0, "Countdown cannot be negative.")
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Countdown", {
						Time = math.round(num);
					})
				end
			end
		};

		HintCountdown = {
			Prefix = Settings.Prefix;
			Commands = {"hcountdown", "hc"};
			Args = {"time"};
			Description = "Hint Countdown";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = math.min(assert(tonumber(args[1]), "Time must be a number"), 120)
				local loop
				loop = service.StartLoop("HintCountdown", 1, function()
					if num < 1 then
						loop.Running = false
					else
						Functions.Hint(num, service.GetPlayers(), 2.5)
						num -= 1
					end
				end)
			end
		};

		StopCountdown = {
			Prefix = Settings.Prefix;
			Commands = {"stopcountdown", "stopcd"};
			Args = {};
			Description = "Stops all currently running countdowns";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.RemoveGui(v, "Countdown")
				end
				service.StopLoop("HintCountdown")
			end
		};

		TimeMessage = {
			Prefix = Settings.Prefix;
			Commands = {"tm", "timem", "timedmessage", "timemessage"};
			Args = {"time", "message"};
			Filter = true;
			Description = "Make a message and makes it stay for the amount of time (in seconds) you supply";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(tonumber(args[1]), "Invalid time amount (must be number)")
				assert(args[2], "Missing message")

				Functions.Message("Message from ".. service.FormatPlayer(plr), service.BroadcastFilter(args[2], plr), service.GetPlayers(), true, args[1])
			end
		};

		Message = {
			Prefix = Settings.Prefix;
			Commands = {"m", "message"};
			Args = {"message"};
			Filter = true;
			Description = "Makes a message";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing message")

				Functions.Message("Message from ".. service.FormatPlayer(plr), service.BroadcastFilter(args[1], plr), service.GetPlayers(), true)
			end
		};

		MessagePM = {
			Prefix = Settings.Prefix;
			Commands = {"mpm", "messagepm"};
			Args = {"player", "message"};
			Filter = true;
			Description = "Makes a message on the target player(s) screen.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing message")

				local Sender = string.format("Message from %s", service.FormatPlayer(plr))
				for _, v in service.GetPlayers(plr, args[1]) do
					Functions.Message(Sender, service.Filter(args[2], plr, v), {v}, true)
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

				Functions.Notify("Message from ".. service.FormatPlayer(plr), service.BroadcastFilter(args[1], plr), service.GetPlayers())
			end
		};

		NotifyPM = {
			Prefix = Settings.Prefix;
			Commands = {"npm", "smallmessagepm", "nmessagepm", "nmsgpm", "npmmsg", "smsgpm", "spmmsg", "smessagepm"};
			Args = {"player", "message"};
			Filter = true;
			Description = "Makes a small message on the target player(s) screen.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing message")
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.RemoveGui(v, "Notify")
					Remote.MakeGui(v, "Notify", {
						Title = "Message from "..service.FormatPlayer(plr);
						Message = service.Filter(args[2], plr, v);
					})
				end
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

				Functions.Hint(string.format("%s: %s", service.FormatPlayer(plr), service.BroadcastFilter(args[1], plr)), service.GetPlayers())
			end
		};

		TimeHint = {
			Prefix = Settings.Prefix;
			Commands = {"th", "timehint", "thint"};
			Args = {"time", "message"};
			Filter = true;
			Description = "Makes a hint and make it stay on the screen for the specified amount of time";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(tonumber(args[1]), "Invalid time amount (must be a number)")
				assert(args[2], "Missing message")

				Functions.Hint(string.format("%s: %s", service.FormatPlayer(plr), service.BroadcastFilter(args[2], plr)), service.GetPlayers(), tonumber(args[1]))
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
							Title = "Warning from "..service.FormatPlayer(plr);
							Message = reason;
						})

						Remote.MakeGui(plr, "Notification", {
							Title = "Notification";
							Icon = server.MatIcons.Shield;
							Message = "Warned ".. service.FormatPlayer(v);
							Time = 5;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."warnings "..v.Name.."')")
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
							Core.CrossServer("RemovePlayer", v.Name, "Warning from "..service.FormatPlayer(plr), reason)
						end

						Remote.MakeGui(plr, "Notification", {
							Title = "Notification";
							Icon = server.MatIcons.Shield;
							Message = "Kick-warned ".. service.FormatPlayer(v);
							Time = 5;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."warnings "..v.Name.."')")
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
								if string.match(string.lower(playerWarning.Message), "^"..reason) then
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
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."warnings "..v.Name.."')")
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
						Message = "Cleared warning(s) for ".. service.FormatPlayer(v);
						Time = 5;
						OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."warnings "..v.Name.."')")
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
						Text = "["..k.."] "..m.Message;
						Desc = "Issued by: "..m.From.."; "..m.Message;
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
						Title = "Warnings - "..service.FormatPlayer(v);
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

		ChatNotify = {
			Prefix = Settings.Prefix;
			Commands = {"chatnotify", "chatmsg"};
			Args = {"player", "message"};
			Filter = true;
			Description = "Makes a message in the target player(s)'s chat window";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "ChatMessage", service.Filter(args[2], plr, v), Color3.fromRGB(255, 64, 77))
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

		Punish = {
			Prefix = Settings.Prefix;
			Commands = {"punish"};
			Args = {"player"};
			Description = "Removes the target player(s)'s character";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character
					if char then
						Remote.LoadCode(v, [[service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)]])
						char.Parent = service.UnWrap(Settings.Storage)
					end
				end
			end
		};

		UnPunish = {
			Prefix = Settings.Prefix;
			Commands = {"unpunish"};
			Args = {"player"};
			Description = "UnPunishes the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1])  do
					local char = v.Character
					if char then
						char.Parent = workspace
						char:MakeJoints()
						Remote.LoadCode(v, [[service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)]])
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
						Admin.RunCommand(Settings.Prefix.."name", v.Name, "-AFK-_"..service.FormatPlayer(v).."_-AFK-")
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
							Admin.RunCommand(Settings.Prefix.."unname", v.Name)
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
			Description = "Same as "..server.Settings.Prefix.."god, but also provides blast protection";
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

		RemoveHats = {
			Prefix = Settings.Prefix;
			Commands = {"removehats", "nohats", "clearhats", "rhats"};
			Args = {"player"};
			Description = "Removes any hats the target is currently wearing and from their HumanoidDescription.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, p in service.GetPlayers(plr, args[1]) do
					local humanoid: Humanoid? = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
						local DescsToRemove = {"HatAccessory","HairAccessory","FaceAccessory","NeckAccessory","ShouldersAccessory","FrontAccessory","BackAccessory","WaistAccessory"}
						for _, prop in DescsToRemove do
							humanoidDesc[prop] = ""
						end
						humanoid:ApplyDescription(humanoidDesc, Enum.AssetTypeVerification.Always)
					end
				end
			end
		};

		RemoveHat = {
			Prefix = Settings.Prefix;
			Commands = {"removehat", "rhat"};
			Args = {"player", "accessory name"};
			Description = "Removes specific hat(s) the target is currently wearing";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				-- TODO: HumanoidDescription
				assert(args[2], "Argument(s) missing or nil")
				for _, p in service.GetPlayers(plr, args[1]) do
					if not p.Character then continue end
					for _, v in p.Character:GetChildren() do
						if v:IsA("Accessory") and v.Name:lower() == args[2]:lower() then
							v:Destroy()
						end
					end
				end
			end
		};
		
		RemoveLayeredClothings = {
			Prefix = Settings.Prefix;
			Commands = {"removelayeredclothings"};
			Args = {"player"};
			Description = "Remvoes layered clothings from their HumanoidDescription.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, p in service.GetPlayers(plr, args[1]) do
					local humanoid: Humanoid? = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
						local accessoryBlob = humanoidDesc:GetAccessories(false)
						
						for i=#accessoryBlob, 1, -1 do -- backwards loop due to table.remove
							local blobItem = accessoryBlob[i]
							
							if (blobItem.IsLayered) then
								table.remove(accessoryBlob, i)
							end
						end
						
						humanoidDesc:SetAccessories(accessoryBlob, false)
						humanoid:ApplyDescription(humanoidDesc, Enum.AssetTypeVerification.Always)
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
						Title = "Message from "..service.FormatPlayer(plr);
						Player = plr;
						Message = service.Filter(args[2], plr, v);
						replyTicket = replyTicket;
					})
				end
			end
		};

		ShowChat = {
			Prefix = Settings.Prefix;
			Commands = {"chat", "customchat"};
			Args = {"player"};
			Description = "Opens the custom chat GUI";
			AdminLevel = "Moderators";
			Hidden = not Settings.CustomChat;
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Chat")
				end
			end
		};

		RemoveChat = {
			Prefix = Settings.Prefix;
			Commands = {"unchat", "uncustomchat"};
			Args = {"player"};
			Description = "Closes the custom chat GUI";
			AdminLevel = "Moderators";
			Hidden = not Settings.CustomChat;
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.RemoveGui(v, "Chat")
				end
			end
		};

		UnColorCorrection = {
			Prefix = Settings.Prefix;
			Commands = {"uncolorcorrection", "uncorrection", "uncolorcorrectioneffect"};
			Args = {"player"};
			Description = "UnColorCorrection the target player's screen";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, p in service.GetPlayers(plr, args[1]) do
					Remote.RemoveLocal(p, "WINDOW_COLORCORRECTION", "Camera")
				end
			end
		};

		UnSunRays = {
			Prefix = Settings.Prefix;
			Commands = {"unsunrays"};
			Args = {"player"};
			Description = "UnSunrays the target player's screen";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.RemoveLocal(v, "WINDOW_SUNRAYS", "Camera")
				end
			end
		};

		UnBloom = {
			Prefix = Settings.Prefix;
			Commands = {"unbloom", "unscreenbloom"};
			Args = {"player"};
			Description = "UnBloom the target player's screen";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.RemoveLocal(v, "WINDOW_BLOOM", "Camera")
				end
			end
		};

		UnBlur = {
			Prefix = Settings.Prefix;
			Commands = {"unblur", "unscreenblur"};
			Args = {"player"};
			Description = "UnBlur the target player's screen";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.RemoveLocal(v, "WINDOW_BLUR", "Camera")
				end
			end
		};

		UnLightingEffect = {
			Prefix = Settings.Prefix;
			Commands = {"unlightingeffect", "unscreeneffect"};
			Args = {"player"};
			Description = "Remove admin made lighting effects from the target player's screen";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					for _, e in {"BLUR", "BLOOM", "THERMAL", "SUNRAYS", "COLORCORRECTION"} do
						Remote.RemoveLocal(v, "WINDOW_"..e, "Camera")
					end
				end
			end
		};

		ShowSBL = {
			Prefix = Settings.Prefix;
			Commands = {"sbl", "syncedbanlist", "globalbanlist", "trellobans", "trellobanlist"};
			Args = {};
			Description = "Shows Trello bans";
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
				table.insert(tab, 1, "# Banned Users: "..#HTTP.Trello.Bans)
				table.insert(tab, 2, "―――――――――――――――――――――――")
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Synced Ban List";
					Icon = server.MatIcons.Gavel;
					Tab = Logs.ListUpdaters.ShowSBL(plr);
					Update = "ShowSBL";
				})
			end;
		};

		HandTo = {
			Prefix = Settings.Prefix;
			Commands = {"handto"};
			Args = {"player"};
			Description = "Hands an item to a player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local target = service.GetPlayers(plr, args[1])[1]

				if target ~= plr then
					local targetchar = target.Character

					if not targetchar then
						Functions.Hint("[HANDTO]: Unable to hand item to "..target.Name, {plr})
						return
					end

					local plrChar = plr.Character

					if not plrChar then
						Functions.Hint("[HANDTO]: Unable to hand item to "..target.Name, {plr})
						return
					end

					local tool = plrChar:FindFirstChildOfClass"Tool"

					if not tool then
						Functions.Hint("[HANDTO]: You must be holding an item", {plr})
						return
					else
						tool.Parent = targetchar
						Functions.Hint("[HANDTO]: Successfully given the item to "..target.Name, {plr})
					end
				else
					Functions.Hint("[HANDTO]: Cannot give item to yourself", {plr})
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
						Text = "[EQUIPPED] "..equippedTool.Name;
						Desc = string.format("Class: %s | %s", equippedTool.ClassName, if equippedTool:IsA("Tool") then "ToolTip: "..equippedTool.ToolTip else "BinType: "..equippedTool.BinType);
					})
				end
				local backpack = target:FindFirstChildOfClass("Backpack")
				if backpack then
					for _, t in backpack:GetChildren() do
						table.insert(tab, {
							Text = t.Name;
							Desc = if t:IsA("BackpackItem") then
								string.format("Class: %s | %s", t.ClassName, if t:IsA("Tool") then "ToolTip: "..t.ToolTip else "BinType: "..t.BinType)
								else "Class: "..t.ClassName;
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
							Title = service.FormatPlayer(v).."'s tools";
							Icon = server.MatIcons["Inventory 2"];
							Table = Logs.ListUpdaters.ShowBackpack(plr, v);
							AutoUpdate = if args[2] and (args[2]:lower() == "true" or args[2]:lower() == "yes") then 1 else nil;
							Update = "ShowBackpack";
							UpdateArg = v;
							Size = {280, 225};
							TitleButtons = {
								{
									Text = "";
									OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."tools')");
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
					"# Players: " .. #players,
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
								ping = Remote.Ping(v).."ms"
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
									Text = "[LOADING] "..service.FormatPlayer(v, true);
									Desc = "Lower: "..string.lower(v.Name).." | Ping: "..ping;
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

		Waypoint = {
			Prefix = Settings.Prefix;
			Commands = {"waypoint", "wp", "checkpoint"};
			Args = {"name"};
			Filter = true;
			Description = "Makes a new waypoint/sets an exiting one to your current position with the name <name> that you can teleport to using :tp me waypoint-<name>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local name = args[1] or tostring(#Variables.Waypoints + 1)
				if plr.Character:FindFirstChild("HumanoidRootPart") then
					Variables.Waypoints[name] = plr.Character.HumanoidRootPart.Position
					Functions.Hint("Made waypoint "..name.." | "..tostring(Variables.Waypoints[name]), {plr})
				end
			end
		};

		DeleteWaypoint = {
			Prefix = Settings.Prefix;
			Commands = {"delwaypoint", "delwp", "delcheckpoint", "deletewaypoint", "deletewp", "deletecheckpoint"};
			Args = {"name"};
			Description = "Deletes the waypoint named <name> if it exist";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in Variables.Waypoints do
					if string.sub(string.lower(i), 1, #args[1])==string.lower(args[1]) or string.lower(args[1])=="all" then
						Variables.Waypoints[i]=nil
						Functions.Hint("Deleted waypoint "..i, {plr})
					end
				end
			end
		};

		Waypoints = {
			Prefix = Settings.Prefix;
			Commands = {"waypoints"};
			Args = {};
			Description = "Shows available waypoints, mouse over their names to view their coordinates";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local temp={}
				for i, v in Variables.Waypoints do
					local x, y, z=tostring(v):match("(.*),(.*),(.*)")
					table.insert(temp, {Text=i, Desc="X:"..x.." Y:"..y.." Z:"..z})
				end
				Remote.MakeGui(plr, "List", {
					Title = 'Waypoints';
					Icon = server.MatIcons.People;
					Tab = temp;
				})
			end
		};

		Cameras = {
			Prefix = Settings.Prefix;
			Commands = {"cameras", "cams"};
			Args = {};
			Description = "Shows a list of admin cameras";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local tab = table.create(#Variables.Cameras)
				for _, v in Variables.Cameras do
					table.insert(tab, {Text = v.Name, Desc = "Pos: "..tostring(v.Brick.Position)})
				end
				Remote.MakeGui(plr, "List", {Title = "Cameras", Tab = tab})
			end
		};

		MakeCamera = {
			Prefix = Settings.Prefix;
			Commands = {"makecam", "makecamera", "camera", "newcamera", "newcam"};
			Args = {"name"};
			Filter = true;
			Description = "Makes a camera named whatever you pick";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local head = plr.Character and (plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart"))
				assert(head and head:IsA("BasePart"), "You don't have a character head or root part")
				if workspace:FindFirstChild("Camera: "..args[1]) then
					Functions.Hint(args[1].." Already Exists!", {plr})
				else
					local cam = service.New("Part", {
						Parent = workspace;
						Name = "Camera: "..args[1];
						Position = head.Position;
						Anchored = true;
						BrickColor = BrickColor.new("Really black");
						CanCollide = false;
						Locked = true;
						Size = Vector3.new(1, 1, 1);
						TopSurface = "Smooth";
						BottomSurface = "Smooth";
						Transparency = 1;--.9
					})
					--service.New("PointLight", cam)
					local mesh = service.New("SpecialMesh", {
						Parent = cam;
						Scale = Vector3.new(1, 1, 1);
						MeshType = "Sphere";
					})
					table.insert(Variables.Cameras, {Brick = cam, Name = args[1]})
				end
			end
		};

		ViewCamera = {
			Prefix = Settings.Prefix;
			Commands = {"viewcam", "viewc", "camview", "watchcam", "cam"};
			Args = {"camera"};
			Description = "Makes you view the target player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in Variables.Cameras do
					if string.sub(v.Name, 1, #args[1]) == args[1] then
						Remote.Send(plr, "Function", "SetView", v.Brick)
					end
				end
			end
		};

		ForceView = {
			Prefix = Settings.Prefix;
			Commands = {"fview", "forceview", "forceviewplayer", "fv"};
			Args = {"player1", "player2"};
			Description = "Forces one player to view another";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local targets = service.GetPlayers(plr, args[2])
				for _, viewer in service.GetPlayers(plr, args[1]) do
					for _, target in targets do
						local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
						if not targetHum then continue end
						local rootPart = target.Character.PrimaryPart
						if not rootPart then continue end
						Functions.ResetReplicationFocus(viewer)
						viewer.ReplicationFocus = rootPart
						Remote.Send(viewer, "Function", "SetView", targetHum)
						Functions.Hint(service.FormatPlayer(viewer).." is now viewing "..service.FormatPlayer(target), {plr})
					end
				end
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
						Functions.Hint(service.FormatPlayer(v).." doesn't have a character humanoid", {plr})
						continue
					end
					local rootPart = v.Character.PrimaryPart
					if not rootPart then
						Functions.Hint(service.FormatPlayer(v).." doesn't have a HumanoidRootPart", {plr})
						continue
					end
					Functions.ResetReplicationFocus(plr)
					plr.ReplicationFocus = rootPart
					Remote.Send(plr, "Function", "SetView", hum)
				end
			end
		};

		--[[Viewport = {
			Prefix = Settings.Prefix;
			Commands = {"viewport", "cctv"};
			Args = {"player"};
			Description = "Makes a viewport of the target player<s>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v and v.Character:FindFirstChildOfClass("Humanoid") then
						Remote.MakeGui(plr, "Viewport", {Subject = v.Character.HumanoidRootPart});
					end
				end
			end
		};--]]

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
						Functions.Hint(service.FormatPlayer(v).." doesn't have a character and/or HumanoidRootPart", {plr})
					end
					Remote.Send(v, "Function", "SetView", "reset")
				end
			end
		};

		GuiView = {
			Prefix = Settings.Prefix;
			Commands = {"guiview", "showguis", "viewguis"};
			Args = {"player"};
			Description = "Shows you the player's character and any guis in their PlayerGui folder [May take a minute]";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local p
				for _, v in service.GetPlayers(plr, args[1]) do
					p = v
				end
				if p then
					Functions.Hint("Loading GUIs", {plr})
					local guis = Remote.Get(p, "Function", "GetGuiData")
					if guis then
						Remote.Send(plr, "Function", "LoadGuiData", guis)
					end
				end
			end;
		};

		UnGuiView = {
			Prefix = Settings.Prefix;
			Commands = {"unguiview", "unshowguis", "unviewguis"};
			Args = {};
			Description = "Removes the viewed player's GUIs";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				Remote.Send(plr, "Function", "UnLoadGuiData")
			end;
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

		Repeat = {
			Prefix = Settings.Prefix;
			Commands = {"repeat", "loop"};
			Args = {"amount", "interval", "command"};
			Description = "Repeats <command> for <amount> of times every <interval> seconds; Amount cannot exceed 50";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local amount = tonumber(args[1])
				local timer = tonumber(args[2])
				if timer<=0 then timer=0.1 end
				if amount>50 then amount=50 end
				local command = args[3]
				local name = string.lower(plr.Name)
				assert(command, "Missing command name to repeat")
				if string.lower(string.sub(command, 1, #Settings.Prefix+string.len("repeat"))) == string.lower(Settings.Prefix.."repeat") or string.sub(command, 1, #Settings.Prefix+string.len("loop")) == string.lower(Settings.Prefix.."loop") or string.find(command, "^"..Settings.Prefix.."loop") or string.find(command, "^"..Settings.Prefix.."repeat") then
					error("Cannot repeat the loop command in a loop command")
					return
				end

				Variables.CommandLoops[name..command] = true
				Functions.Hint("Running "..command.." "..amount.." times every "..timer.." seconds.", {plr})
				for i = 1, amount do
					if not Variables.CommandLoops[name..command] then break end
					Process.Command(plr, command, {Check = false;})
					wait(timer)
				end
				Variables.CommandLoops[name..command] = nil
			end
		};

		Abort = {
			Prefix = Settings.Prefix;
			Commands = {"abort", "stoploop", "unloop", "unrepeat"};
			Args = {"username", "command"};
			Description = "Aborts a looped command. Must supply name of player who started the loop or \"me\" if it was you, or \"all\" for all loops. :abort sceleratis :kill bob or :abort all";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local name = string.lower(args[1])
				if name=="me" then
					Variables.CommandLoops[string.lower(plr.Name)..args[2]] = nil
				elseif name=="all" then
					for i, v in Variables.CommandLoops do
						Variables.CommandLoops[i] = nil
					end
				elseif args[2] then
					Variables.CommandLoops[name..args[2]] = nil
				end
			end
		};

		AbortAll = {
			Prefix = Settings.Prefix;
			Commands = {"abortall", "stoploops"};
			Args = {"username (optional)"};
			Description = "Aborts all existing command loops";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local name = args[1] and string.lower(args[1])

				if name and name=="me" then
					for i, v in Variables.CommandLoops do
						if string.lower(string.sub(i, 1, plr.Name)) == string.lower(plr.Name) then
							Variables.CommandLoops[string.lower(plr.Name)..args[2]] = nil
						end
					end
				elseif name and name=="all" then
					for i, v in Variables.CommandLoops do
						Variables.CommandLoops[string.lower(plr.Name)..args[2]] = nil
					end
				elseif args[2] then
					if Variables.CommandLoops[name..args[2]] then
						Variables.CommandLoops[name..args[2]] = nil
					else
						Remote.MakeGui(plr, "Output", {Title = "Output"; Message = "No loops relating to your search"})
					end
				else
					for i, v in Variables.CommandLoops do
						Variables.CommandLoops[i] = nil
					end
				end
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

		GetPing = {
			Prefix = Settings.Prefix;
			Commands = {"getping"};
			Args = {"player"};
			Description = "Shows the target player's ping";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Functions.Hint(service.FormatPlayer(v).."'s Ping is "..Remote.Get(v, "Ping").."ms", {plr})
				end
			end
		};

		ShowTasks = {
			Prefix = "";
			Commands = {":tasks", ":tasklist", Settings.Prefix.."tasks", Settings.Prefix.."tasklist"};
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
								Text = tostring(t.Name or t.Function).. "- Status: "..t.Status.." - Elapsed: ".. t.CurrentTime - t.Created;
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
							Text = tostring(v.Name or v.Function).." - Status: "..v.Status.." - Elapsed: "..(os.time()-v.Created);
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
							Text = tostring(v.Name or v.Function).." - Status: "..v.Status.." - Elapsed: "..(v.CurrentTime-v.Created);
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
							Title = v.Name.."'s Tasks";
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

		JoinServer = {
			Prefix = Settings.Prefix;
			Commands = {"toserver", "joinserver", "jserver", "jplace"};
			Args = {"player", "JobId"};
			Description = "Send player(s) to a specific server using the server's JobId";
			NoStudio = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local players = service.GetPlayers(plr, assert(args[1], "Missing argument #1 (players)"))
				local teleportOptions = service.New("TeleportOptions", {
					ServerInstanceId = assert(args[2], "Missing argument #2 (server JobId)")
				})

				service.TeleportService:TeleportAsync(game.PlaceId, players, teleportOptions)
				Functions.Message("Adonis", "Teleporting to server \""..args[2].."\"\nPlease wait...", players, false, 10)
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
							Text = string.format(RANK_TEXT_FORMAT, service.FormatPlayer(v), (rankName or ("Level: ".. level)));
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
							Text = "  ".. user;
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
							entry = v.Name .. ":" .. v.UserId
						elseif v.UserId then
							entry = "ID: ".. v.UserId
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
				table.insert(tab, 1, "# Banned Users: "..count)
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

		Vote = {
			Prefix = Settings.Prefix;
			Commands = {"vote", "makevote", "startvote", "question", "survey"};
			Args = {"player", "answer1,answer2,etc (NO SPACES)", "question"};
			Filter = true;
			Description = "Lets you ask players a question with a list of answers and get the results";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local question = args[3]
				if not question then error("You forgot to supply a question!") end
				local answers = args[2]
				local anstab = {}
				local responses = {}
				local voteKey = "ADONISVOTE".. math.random();
				local players = service.GetPlayers(plr, args[1])
				local startTime = os.clock();

				local function voteUpdate()
					local total = #responses
					local results = table.create(total)

					local tab = {
						"Question: "..question;
						"Total Responses: "..total;
						"Didn't Vote: "..#players-total;
						"Time Left: ".. math.max(0, 120 - (os.clock()-startTime));
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

						table.insert(tab, {Text=ans.." | "..percent.."% - "..num.."/"..total, Desc="Number: "..num.."/"..total.." | Percent: "..percent})
					end

					return tab;
				end

				Logs.TempUpdaters[voteKey] = voteUpdate;

				if not answers then
					anstab = {"Yes", "No"}
				else
					for ans in string.gmatch(answers, "([^,]+)") do
						table.insert(anstab, ans)
					end
				end

				for i, v in players do
					Routine(function()
						local response = Remote.GetGui(v, "Vote", {Question = question; Answers = anstab;})
						if response then
							table.insert(responses, response)
						end
					end)
				end

				Remote.MakeGui(plr, "List", {
					Title = "Results";
					Tab = voteUpdate();
					Update = "TempUpdate";
					UpdateArgs = {{UpdateKey = voteKey}};
					AutoUpdate = 1;
				})

				delay(120, function() Logs.TempUpdaters[voteKey] = nil end)
			end
		};

		ToolList = {
			Prefix = Settings.Prefix;
			Commands = {"tools", "toollist", "toolcenter", "savedtools", "addedtools", "toolpanel", "toolspanel"};
			Args = {};
			Description = "Shows you a list of tools that can be obtained via the "..Settings.Prefix.."give command, and other useful utilities";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local data = {
					Tools = {};
					SavedTools = {};
					Prefix = Settings.Prefix;
					SplitKey = Settings.SplitKey;
					SpecialPrefix = Settings.SpecialPrefix;
				}
				for _, tool in if Settings.RecursiveTools then Settings.Storage:GetDescendants() else Settings.Storage:GetChildren() do
					if tool:IsA("BackpackItem") and not Variables.SavedTools[tool] then
						table.insert(data.Tools, tool.Name)
					end
				end
				for tool, pName in Variables.SavedTools do
					table.insert(data.SavedTools, {ToolName = tool.Name, AddedBy = pName})
				end
				return data
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "ToolPanel", Logs.ListUpdaters.ToolList(plr))
			end
		};

		Piano = {
			Prefix = Settings.Prefix;
			Commands = {"piano"};
			Args = {"player"};
			Description = "Gives you a playable keyboard piano. Credit to NickPatella.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					local Dropper = v:FindFirstChildOfClass("PlayerGui") or v:FindFirstChildOfClass("Backpack")
					if Dropper then
						local piano = Deps.Assets.Piano:Clone()
						piano.Parent = Dropper
						piano.Disabled = false
					end
				end
			end
		};

		InsertList = {
			Prefix = Settings.Prefix;
			Commands = {"insertlist", "inserts", "inslist", "modellist", "models"};
			Args = {};
			Description = "Shows you the script's available insert list";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local tab = table.create(#Variables.InsertList + #HTTP.Trello.InsertList)
				for _, v in Variables.InsertList do table.insert(tab, v) end
				for _, v in HTTP.Trello.InsertList do table.insert(tab, v) end
				for i, v in tab do
					tab[i] = {Text = v.Name .." - "..v.ID; Desc = v.ID;}
				end
				Remote.MakeGui(plr, "List", {Title = "Insert List", Table = tab; TextSelectable = true})
			end
		};

		InsertClear = {
			Prefix = Settings.Prefix;
			Commands = {"insclear", "clearinserted", "clrins", "insclr"};
			Args = {};
			Description = "Removes inserted objects";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in Variables.InsertedObjects do
					v:Destroy()
					table.remove(Variables.InsertedObjects, i)
				end
			end
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
						service.StopLoop(ind.."JAIL")
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
						Desc = "Class: "..v.ClassName;
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
						Title = service.FormatPlayer(v).."'s Client Instances";
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
			Description = "Removes Adonis on-screen GUIs for the target player(s); if <delete all> is false, wil, only clear "..Settings.Prefix.."m, "..Settings.Prefix.."n, "..Settings.Prefix.."h, "..Settings.Prefix.."alert and screen effect GUIs";
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

		ClearEffects = {
			Prefix = Settings.Prefix;
			Commands = {"cleareffects"};
			Args = {"player"};
			Description = "Removes all screen UI effects such as Spooky, Clown, ScreenImage, ScreenVideo, etc.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1] or "all") do
					Remote.RemoveGui(v, "Effect")
				end
			end
		};

		ResetLighting = {
			Prefix = Settings.Prefix;
			Commands = {"fix", "resetlighting", "undisco", "unflash", "fixlighting"};
			Args = {};
			Description = "Reset lighting back to the setting it had on server start";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				service.StopLoop("LightingTask")
				for i, v in Variables.OriginalLightingSettings do
					if i ~= "Sky" and service.Lighting[i] ~= nil then
						Functions.SetLighting(i, v)
					end
				end
				for i, v in service.Lighting:GetChildren() do
					if v.ClassName == "Sky" then
						service.Delete(v)
					end
				end
				if Variables.OriginalLightingSettings.Sky then
					Variables.OriginalLightingSettings.Sky:Clone().Parent = service.Lighting
				end
			end
		};

		ClearLighting = {
			Prefix = Settings.Prefix;
			Commands = {"fixplayerlighting", "rplighting", "clearlighting", "serverlighting"};
			Args = {"player"};
			Description = "Sets the player's lighting to match the server's";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					for prop, val in Variables.LightingSettings do
						Remote.SetLighting(v, prop, val)
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

		Sell = {
			Prefix = Settings.Prefix;
			Commands = {"sell", "promptpurchase"};
			Args = {"player", "id"};
			Description = "Prompts the player(s) to buy the product belonging to the ID you supply";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.MarketPlace:PromptPurchase(v, tonumber(args[2]), false)
				end
			end
		};

		Capes = {
			Prefix = Settings.Prefix;
			Commands = {"capes", "capelist"};
			Args = {};
			Description = "Shows you the list of capes for the cape command";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local list = table.create(#Variables.Capes)
				for _, v in Variables.Capes do
					table.insert(list, v.Name)
				end
				Remote.MakeGui(plr, "List", {Title = "Cape List", Tab = list;})
			end
		};

		Cape = {
			Prefix = Settings.Prefix;
			Commands = {"cape", "givecape"};
			Args = {"player", "name/color", "material", "reflectance", "id"};
			Description = "Gives the target player(s) the cape specified, do Settings.Prefixcapes to view a list of available capes ";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local color="White"
				if pcall(function() return BrickColor.new(args[2]) end) then color = args[2] end
				local mat = args[3] or "Fabric"
				local ref = args[4]
				local id = args[5]
				if args[2] and not args[3] then
					for k, cape in Variables.Capes do
						if string.lower(args[2])==string.lower(cape.Name) then
							color = cape.Color
							mat = cape.Material
							ref = cape.Reflectance
							id = cape.ID
						end
					end
				end
				for _, v in service.GetPlayers(plr, args[1]) do
					Functions.Cape(v, false, mat, color, id, ref)
				end
			end
		};

		UnCape = {
			Prefix = Settings.Prefix;
			Commands = {"uncape", "removecape"};
			Args = {"player"};
			Description = "Removes the target player(s)'s cape";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Functions.UnCape(v)
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
					Admin.RunCommand(Settings.Prefix.."clip", p.Name)
					local new = clipper:Clone()
					new.Parent = p.Character.Humanoid
					new.Disabled = false
					if Settings.CommandFeedback then
						Functions.Notification("Noclip", "Character noclip has been enabled. You will now be able to walk though walls.", {p}, 15, "Info") -- Functions.Notification(title,message,player,time,icon)
					end
				end
			end
		};

		FlyNoClip = {
			Prefix = Settings.Prefix;
			Commands = {"flynoclip"};
			Args = {"player", "speed"};
			Description = "Flying noclip";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local newArgs = { "me", args[2] or "2", "true" }

				for i, p in service.GetPlayers(plr, args[1]) do
					Commands.Fly.Function(p, newArgs)
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
							Name = v.Name .. "_ADONISJAIL",
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
						service.TrackTask("Thread: JailLoop"..tostring(ind), function()
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
						--service.StopLoop(ind.."JAIL")
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
							service.StopLoop(ind.."JAIL")
							Pcall(function() v.Jail:Destroy() end)
							Variables.Jails[ind] = nil
						end
					end
				end
			end
		};

		BubbleChat = {
			Prefix = Settings.Prefix;
			Commands = {"bchat", "dchat", "bubblechat", "dialogchat"};
			Args = {"player", "color(red/green/blue/white/off)"};
			Description = "Gives the target player(s) a little chat gui, when used will let them chat using dialog bubbles";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local CHAT_COLORS = {
					red = Enum.ChatColor.Red,
					green = Enum.ChatColor.Green,
					blue = Enum.ChatColor.Blue,
					white = Enum.ChatColor.White,
					off = "off"
				}
				local chatColor = args[2] and CHAT_COLORS[args[2]:lower()] or CHAT_COLORS.red
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "BubbleChat", {Color = chatColor;})
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
						Functions.Hint(service.FormatPlayer(v) .. " doesn't currently have a character", { plr })
						continue
					end

					local rootPart = char:FindFirstChild("HumanoidRootPart")
					local head = char:FindFirstChild("Head")

					if not (rootPart and head) then
						Functions.Hint(service.FormatPlayer(v) .. " doesn't currently have a HumanoidRootPart/Head", { plr })
						continue
					end

					task.defer(function()
						local gui = service.New("BillboardGui", {
							Name = v.Name .. "_Tracker",
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
							Remote.RemoveLocal(plr, v.Name .. "Tracker")
							teamChangeConn:Disconnect()
							if charRemovingConn then
								charRemovingConn:Disconnect()
							end
						end)
						charRemovingConn = v.CharacterRemoving:Once(function()
							Remote.RemoveLocal(plr, v.Name .. "Tracker")
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
				if args[1] and args[1]:lower() == Settings.SpecialPrefix.."all" then
					Variables.TrackingTable[plr.Name] = nil
					Remote.RemoveLocal(plr, "Tracker", false, true)
				else
					local trackTargets = Variables.TrackingTable[plr.Name]
					for _, v in service.GetPlayers(plr, args[1]) do
						Remote.RemoveLocal(plr, v.Name.."Tracker")
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

		GiveStarterPack = {
			Prefix = Settings.Prefix;
			Commands = {"startertools", "starttools"};
			Args = {"player"};
			Description = "Gives the target player(s) tools that are in the game's StarterPack";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local Backpack = v:FindFirstChildOfClass("Backpack")
					if Backpack then
						for a, q in service.StarterPack:GetChildren() do
							local q = q:Clone()
							if not q:FindFirstChild(Variables.CodeName) then
								service.New("StringValue", q).Name = Variables.CodeName
							end
							q.Parent = Backpack
						end
					end
				end
			end
		};

		Sword = {
			Prefix = Settings.Prefix;
			Commands = {"sword", "givesword"};
			Args = {"player", "allow teamkill (default: true)"};
			Description = "Gives the target player(s) a sword";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local sword = service.Insert(125013769)
				local config = sword:FindFirstChild("Configurations")
				if config then
					config.CanTeamkill.Value = if args[2] and args[2]:lower() == "false" then false else true
				end
				for _, v in service.GetPlayers(plr, args[1]) do
					local Backpack = v:FindFirstChildOfClass("Backpack")
					if Backpack then
						sword:Clone().Parent = Backpack
					end
				end
			end
		};

		Clone = {
			Prefix = Settings.Prefix;
			Commands = {"clone", "cloneplayer", "duplicate"};
			Args = {"player", "copies (max: 50 | default: 1)"};
			Description = "Clones the character of the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tonumber(args[2] or 1)
				assert(num <= 50, "Cannot make more than 50 clones")

				for _, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if not hum then
						continue
					end
					Routine(function()
						char.Archivable = true
						local charPivot = char:GetPivot()
						for _ = 1, num do
							local clone = char:Clone()
							table.insert(Variables.Objects, clone)

							local animate
							local anim = clone:FindFirstChild("Animate")
							if anim then
								animate = hum.RigType == Enum.HumanoidRigType.R15 and Deps.Assets.R15Animate:Clone() or Deps.Assets.R6Animate:Clone()
								animate:ClearAllChildren()
								for _, v in anim:GetChildren() do
									v.Parent = animate
								end
								anim:Destroy()
								animate.Parent = clone
							end

							clone:PivotTo(charPivot)

							if animate then
								animate.Disabled = false
							end
							clone:FindFirstChildOfClass("Humanoid").Died:Once(function()
								service.Debris:AddItem(clone, service.Players.RespawnTime)
							end)

							clone.Archivable = false
							clone.Parent = workspace
						end
					end)
				end
			end
		};

		CopyCharacter = {
			Prefix = Settings.Prefix;
			Commands = {"copychar", "copycharacter", "copyplayercharacter"};
			Args = {"player", "target"};
			Description = "Changes specific players' character to the target's character. (i.g. To copy Player1's character, do ':copychar me Player1')";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing player name. What player would you want to copy?")

				local target = service.GetPlayers(plr, args[2])[1]
				local target_character = target.Character
				if target_character then
					target_character.Archivable = true
					target_character = target_character:Clone()
				end

				assert(target_character, "Target player doesn't have a character or has a locked character")

				local target_humandescrip = target and target.Character:FindFirstChildOfClass("Humanoid") and target.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("HumanoidDescription")

				assert(target_humandescrip, "Target player doesn't have a HumanoidDescription or has a locked HumanoidDescription [Cannot copy target's character]")

				target_humandescrip.Archivable = true
				target_humandescrip = target_humandescrip:Clone()

				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						if (v and v.Character and v.Character:FindFirstChildOfClass("Humanoid")) and (target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")) then
							v.Character.Archivable = true

							for _, a in v.Character:GetChildren() do
								if a:IsA("Accessory") then
									a:Destroy()
								end
							end

							local cl = target_humandescrip:Clone()
							cl.Parent = v.Character:FindFirstChildOfClass("Humanoid")
							pcall(function() v.Character:FindFirstChildOfClass("Humanoid"):ApplyDescription(cl, Enum.AssetTypeVerification.Always) end)

							for _, a in target_character:GetChildren() do
								if a:IsA("Accessory") then
									a:Clone().Parent = v.Character
								end
							end
						end
					end)
				end
			end
		};

		ClickTeleport = {
			Prefix = Settings.Prefix;
			Commands = {"clickteleport", "teleporttoclick", "ct", "clicktp", "forceteleport", "ctp", "ctt"};
			Args = {"player"};
			Description = "Gives you a tool that lets you click where you want the target player to stand, hold r to rotate them";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local plrBackpack = assert(plr:FindFirstChildOfClass("Backpack"), "You have no backpack")
				for _, v in service.GetPlayers(plr, args[1]) do
					local scr = Deps.Assets.ClickTeleport:Clone()
					scr.Mode.Value = "Teleport"
					scr.Target.Value = v.Name
					local tool = service.New("Tool", {
						ToolTip = "ClickTP - "..service.FormatPlayer(v);
						CanBeDropped = false;
						RequiresHandle = false;
					})
					service.New("StringValue", tool).Name = Variables.CodeName
					scr.Parent = tool
					scr.Disabled = false
					tool.Parent = plrBackpack
				end
			end
		};

		ClickWalk = {
			Prefix = Settings.Prefix;
			Commands = {"clickwalk", "cw", "ctw", "forcewalk", "walktool", "walktoclick", "clickcontrol", "forcewalk"};
			Args = {"player"};
			Description = "Gives you a tool that lets you click where you want the target player to walk, hold r to rotate them";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local plrBackpack = assert(plr:FindFirstChildOfClass("Backpack"), "You have no backpack")
				for _, v in service.GetPlayers(plr, args[1]) do
					local scr = Deps.Assets.ClickTeleport:Clone()
					scr.Mode.Value = "Walk"
					scr.Target.Value = v.Name
					local tool = service.New("Tool", {
						ToolTip = "ClickWalk - "..service.FormatPlayer(v);
						CanBeDropped = false;
						RequiresHandle = false;
					})
					service.New("StringValue", tool).Name = Variables.CodeName
					scr.Parent = tool
					scr.Disabled = false
					tool.Parent = plrBackpack
				end
			end
		};

		Control = {
			Prefix = Settings.Prefix;
			Commands = {"control", "takeover"};
			Args = {"player"};
			Description = "Lets you take control of the target player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						v.Character.Humanoid.PlatformStand = true
						local w = service.New("Weld", plr.Character.HumanoidRootPart )
						w.Part0 = plr.Character.HumanoidRootPart
						w.Part1 = v.Character.HumanoidRootPart
						local w2 = service.New("Weld", plr.Character.Head)
						w2.Part0 = plr.Character.Head
						w2.Part1 = v.Character.Head
						local w3 = service.New("Weld", plr.Character:FindFirstChild("Right Arm"))
						w3.Part0 = plr.Character:FindFirstChild("Right Arm")
						w3.Part1 = v.Character:FindFirstChild("Right Arm")
						local w4 = service.New("Weld", plr.Character:FindFirstChild("Left Arm"))
						w4.Part0 = plr.Character:FindFirstChild("Left Arm")
						w4.Part1 = v.Character:FindFirstChild("Left Arm")
						local w5 = service.New("Weld", plr.Character:FindFirstChild("Right Leg"))
						w5.Part0 = plr.Character:FindFirstChild("Right Leg")
						w5.Part1 = v.Character:FindFirstChild("Right Leg")
						local w6 = service.New("Weld", plr.Character:FindFirstChild("Left Leg"))
						w6.Part0 = plr.Character:FindFirstChild("Left Leg")
						w6.Part1 = v.Character:FindFirstChild("Left Leg")
						plr.Character.Head.face:Destroy()
						for _, p in v.Character:GetChildren() do
							if p:IsA("BasePart") then
								p.CanCollide = false
							end
						end
						for _, p in plr.Character:GetChildren() do
							if p:IsA("BasePart") then
								p.Transparency = 1
							elseif p:IsA("Accoutrement") then
								p:Destroy()
							end
						end
						v.Character.Parent = plr.Character
						--v.Character.Humanoid.Changed:Connect(function() v.Character.Humanoid.PlatformStand = true end)
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

		R6 = {
			Prefix = Settings.Prefix;
			Commands = {"r6", "classicrig"};
			Args = {"player"};
			Description = "Converts players' character to R6";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					task.defer(Functions.ConvertPlayerCharacterToRig, v, "R6")
				end
			end
		};

		R15 = {
			Prefix = Settings.Prefix;
			Commands = {"r15", "rthro"};
			Args = {"player"};
			Description = "Converts players' character to R15";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Functions.ConvertPlayerCharacterToRig(v, "R15")
				end
			end
		};

		Stun = {
			Prefix = Settings.Prefix;
			Commands = {"stun"};
			Args = {"player"};
			Description = "Stuns the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local Humanoid = v.Character and v.Character:FindFirstChildOfClass("Humanoid")

					if Humanoid then
						Humanoid.PlatformStand = true
					end
				end
			end
		};

		UnStun = {
			Prefix = Settings.Prefix;
			Commands = {"unstun"};
			Args = {"player"};
			Description = "UnStuns the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local Humanoid = v.Character and v.Character:FindFirstChildOfClass("Humanoid")

					if Humanoid then
						Humanoid.PlatformStand = false
					end
				end
			end
		};

		Jump = {
			Prefix = Settings.Prefix;
			Commands = {"jump"};
			Args = {"player"};
			Description = "Forces the target player(s) to jump";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local Humanoid = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if Humanoid then
						Humanoid.Jump = true
					end
				end
			end
		};

		Sit = {
			Prefix = Settings.Prefix;
			Commands = {"sit", "seat"};
			Args = {"player"};
			Description = "Forces the target player(s) to sit";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local Humanoid = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if Humanoid then
						Humanoid.Sit = true
					end
				end
			end
		};

		Transparency = {
			Prefix = Settings.Prefix;
			Commands = {"transparency", "trans"};
			Args = {"player", "% value (0-1)"};
			Description = "Set the transparency of the target's character";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for k, p in v.Character:GetChildren() do
							if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
								p.Transparency = args[2]
								if p.Name == "Head" then
									for _, v2 in p:GetChildren() do
										if v2:IsA("Decal") then
											v2.Transparency = args[2]
										end
									end
								end
							elseif p:IsA("Accessory") and #p:GetChildren() ~= 0 then
								for _, v2 in p:GetChildren() do
									if v2:IsA("BasePart") then
										v2.Transparency = args[2]
									end
								end
							end
						end
					end
				end
			end
		};

		TransparentPart = {
			Prefix = Settings.Prefix;
			Commands = {"transparentpart"};
			Args = {"player", "part names", "% value (0-1)"};
			Description = "Set the transparency of the target's character's parts, including accessories; supports a comma-separated list of part names";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, player in service.GetPlayers(plr, args[1]) do
					if player.Character then
						local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local rigType =  humanoid.RigType
							local GroupPartInputs = {"LeftArm", "RightArm", "RightLeg", "LeftLeg", "Torso"}
							local PartInputs = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}

							local usageText = {
								"Possible inputs are:",
								"R6: Head, LeftArm, RightArm, RightLeg, LeftLeg, Torso",
								"R15: Head, UpperTorso, LowerTorso, LeftUpperArm, LeftLowerArm, LeftHand, RightUpperArm, RightLowerArm, RightHand, LeftUpperLeg, LeftLowerLeg, LeftFoot, RightUpperLeg, RightLowerLeg, RightFoot",
								"",
								"If the input is 'LeftArm' on a R15 rig, it will select the entire Left Arm for R15.",
								"Special Inputs: all, accessories",
								"all: All limbs including accessories. If this is specified it will ignore all other specified parts.",
								"limbs: Changes the transparency of all limbs",
								"face: Changes the transparency of the face",
								"accessories: Changes transparency of accessories"
							}

							if not (args[2]) then
								--assert(args[2], "No parts specified. See developer console for possible inputs.")
								local tab = table.create(#usageText)
								for _,v in usageText do
									table.insert(tab, {
										Text = v;
										Desc = v;
									})
								end
								--// Generate the UI for this player
								server.Remote.MakeGui(plr, "List", {
									Tab = tab;
									Title = "Command Usage";
								})
								return
							end

							local partInput = {}
							local inputs = string.split(args[2], ",")

							for _, v in inputs do
								if v ~= "" then
									if v == "all" then
										partInput = "all"
										break -- break if "all" is found.
									end

									-- Validate inputs
									if v == "limbs" or v == "face" or v == "accessories" then
										table.insert(partInput, v)
									else
										local found = false
										while found ~= true do
											for _,v2 in GroupPartInputs do
												if v == v2 then
													table.insert(partInput, v)
													found = true
													break
												end
											end

											for _,v2 in PartInputs do
												if v == v2 then
													table.insert(partInput, v)
													found = true
													break
												end
											end

											if not (found) then
												assert(nil, "'"..v.."'".." is not a valid input. Run command with no arguments to see possible inputs.")
											end
										end
									end
								else
									assert(nil, "Part argument contains empty value.")
								end
							end


							-- Check if partInput is a table
							if type(partInput) == "table" then
								local hash = {}

								-- Check for duplicates
								for i,v in partInput do
									if not (hash[v]) then
										hash[v] = i -- Store into table to check for duplicates.
									else
										assert(nil, "Duplicate '"..v.."'".." found in input. Specify each input once only.")
									end
								end


								-- Clean up the parts we don't need, depending on rigType, to allow this command to be more dynamic

								if rigType == Enum.HumanoidRigType.R15 then
									for i = #partInput, 1, -1 do
										if partInput[i] == "RightArm" then
											local foundKeys = {}
											for k2, v2 in partInput do
												if v2 == "RightUpperArm" or v2 == "RightLowerArm" or v2 == "RightHand" then
													table.insert(foundKeys, k2)
												end
											end
											-- If not all keys were found just remove all keys and add them manually
											if #foundKeys ~= 3 then
												for _, foundKey in foundKeys do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "RightUpperArm")
												table.insert(partInput, "RightLowerArm")
												table.insert(partInput, "RightHand")
											end
											table.remove(partInput, i) -- Remove the group part input

										elseif partInput[i] == "LeftArm" then
											local foundKeys = {}
											for k2, v2 in partInput do
												if v2 == "LeftUpperArm" or v2 == "LeftLowerArm" or v2 == "LeftHand" then
													table.insert(foundKeys, k2)
												end
											end

											if #foundKeys ~= 3 then
												for _, foundKey in foundKeys do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "LeftUpperArm")
												table.insert(partInput, "LeftLowerArm")
												table.insert(partInput, "LeftHand")
											end
											table.remove(partInput, i)
										elseif partInput[i] == "RightLeg" then
											local foundKeys = {}
											for i = #partInput, 1, -1 do
												if partInput[i] == "RightUpperLeg" or partInput[i] == "RightLowerLeg" or partInput[i] == "RightFoot" then
													table.insert(foundKeys, partInput[i])
												end
											end
											if #foundKeys ~= 3 then
												for _, foundKey in foundKeys do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "RightUpperLeg")
												table.insert(partInput, "RightLowerLeg")
												table.insert(partInput, "RightFoot")
											end
											table.remove(partInput, i)
										elseif partInput[i] == "LeftLeg" then
											local foundKeys = {}
											for k2, v2 in partInput do
												if v2 == "LeftUpperLeg" or v2 == "LeftLowerLeg" or v2 == "LeftFoot" then
													table.insert(foundKeys, k2)
												end
											end

											if #foundKeys ~= 3 then
												for _, foundKey in foundKeys do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "LeftUpperLeg")
												table.insert(partInput, "LeftLowerLeg")
												table.insert(partInput, "LeftFoot")
											end
											table.remove(partInput, i)
										elseif partInput[i] == "Torso" then
											local foundKeys = {}
											for k2, v2 in partInput do
												if v2 == "UpperTorso" or v2 == "LowerTorso" then
													table.insert(foundKeys, k2)
												end
											end
											if #foundKeys ~= 2 then
												for _, foundKey in foundKeys do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "UpperTorso")
												table.insert(partInput, "LowerTorso")
											end
											table.remove(partInput, i)
										end
									end
								end

								if rigType == Enum.HumanoidRigType.R6 then
									for i = #partInput, 1, -1 do
										if partInput[i] == "RightUpperArm" or partInput[i] == "RightLowerArm" or partInput[i] == "RightHand" then
											table.remove(partInput, i)
										elseif partInput[i] == "LeftUpperArm" or partInput[i] == "LeftLowerArm" or partInput[i] == "LeftHand" then
											table.remove(partInput, i)
										elseif partInput[i] == "RightUpperLeg" or partInput[i] == "RightLowerLeg" or partInput[i] == "RightFoot" then
											table.remove(partInput, i)
										elseif partInput[i] == "LeftUpperLeg" or partInput[i] == "LeftLowerLeg" or partInput[i] == "LeftFoot" then
											table.remove(partInput, i)
										elseif partInput[i] == "UpperTorso" or partInput[i] == "LowerTorso" then
											table.remove(partInput, i)
										end
									end
								end


								-- Make chosen parts transparent
								for k, v in partInput do
									if not (v == "limbs" or v == "face" or v == "accessories") then
										local part = player.Character:FindFirstChild(v)
										if part ~= nil and part:IsA("BasePart") then
											part.Transparency = args[3]
										end

									elseif v == "limbs" then
										for key, part in player.Character:GetChildren() do
											if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
												part.Transparency = args[3]
											end
										end

									elseif v == "face" then
										local headPart = player.Character:FindFirstChild("Head")
										for _, v2 in headPart:GetChildren() do
											if v2:IsA("Decal") then
												v2.Transparency = args[3]
											end
										end

									elseif v == "accessories" then
										for key, part in player.Character:GetChildren() do
											if part:IsA("Accessory") then
												for _, v2 in part:GetChildren() do
													if v2:IsA("BasePart") then
														v2.Transparency = args[3]
													end
												end
											end
										end
									end
								end

							elseif partInput == "all" then
								for k, p in player.Character:GetChildren() do
									if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
										p.Transparency = args[3]
										if p.Name == "Head" then
											for _, v2 in p:GetChildren() do
												if v2:IsA("Decal") then
													v2.Transparency = args[3]
												end
											end
										end
									elseif p:IsA("Accessory") and #p:GetChildren() ~= 0 then
										for _, v2 in p:GetChildren() do
											if v2:IsA("BasePart") then
												v2.Transparency = args[3]
											end
										end
									end
								end
							end
						end
					end
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

		PlayerColor = {
			Prefix = Settings.Prefix;
			Commands = {"color", "playercolor", "bodycolor"};
			Args = {"player", "brickcolor or RGB"};
			Description = "Recolors the target character(s) with the given color, or random if none is given";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local color

				local BodyColorProperties = {"HeadColor", "LeftArmColor", "RightArmColor", "RightLegColor", "LeftLegColor", "TorsoColor"}

				if not args[2] then
					color = BrickColor.random().Color
					Functions.Hint("A color wasn't supplied. A random color will be used instead.", {plr})
				else
					color = Functions.ParseColor3(args[2])
					assert(color, "Invalid color provided")
				end

				for _, v: Player in service.GetPlayers(plr, args[1]) do
					local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()

						for _, property in BodyColorProperties do
							humanoidDesc[property] = color
						end

						task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc, Enum.AssetTypeVerification.Always)
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

		Light = {
			Prefix = Settings.Prefix;
			Commands = {"light"};
			Args = {"player", "color"};
			Description = "Makes a PointLight on the target player(s) with the color specified";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local color = Functions.ParseColor3(args[2]) or BrickColor.new("Bright blue").Color

				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						Functions.NewParticle(v.Character.HumanoidRootPart, "PointLight", {
							Name = "ADONIS_LIGHT";
							Color = color;
							Brightness = 5;
							Range = 15;
						})
					end
				end
			end
		};

		UnLight = {
			Prefix = Settings.Prefix;
			Commands = {"unlight"};
			Args = {"player"};
			Description = "UnLights the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						Functions.RemoveParticle(v.Character.HumanoidRootPart, "ADONIS_LIGHT")
					end
				end
			end
		};

		Ambient = {
			Prefix = Settings.Prefix;
			Commands = {"ambient"};
			Args = {"num,num,num", "optional player"};
			Description = "Change Ambient";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Argument 1 missing")

				local color = Functions.ParseColor3(args[1])
				assert(color, "Invalid color provided")

				if args[2] then
					for _, v in service.GetPlayers(plr, args[2]) do
						Remote.SetLighting(v, "Ambient", color)
					end
				else
					Functions.SetLighting("Ambient", color)
				end
			end
		};

		OutdoorAmbient = {
			Prefix = Settings.Prefix;
			Commands = {"oambient", "outdoorambient"};
			Args = {"num,num,num", "optional player"};
			Description = "Change OutdoorAmbient";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Argument 1 missing")

				local color = Functions.ParseColor3(args[1])
				assert(color, "Invalid color provided")

				if args[2] then
					for _, v in service.GetPlayers(plr, args[2]) do
						Remote.SetLighting(v, "OutdoorAmbient", color)
					end
				else
					Functions.SetLighting("OutdoorAmbient", color)
				end
			end
		};

		RemoveFog = {
			Prefix = Settings.Prefix;
			Commands = {"nofog", "fogoff", "unfog"};
			Args = {"optional player"};
			Description = "Fog Off";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[1] then
					for _, v in service.GetPlayers(plr, args[1]) do
						Remote.SetLighting(v, "FogEnd", 1000000000000)
					end
				else
					Functions.SetLighting("FogEnd", 1000000000000)
				end
			end
		};

		Shadows = {
			Prefix = Settings.Prefix;
			Commands = {"shadows"};
			Args = {"on/off", "optional player"};
			Description = "Determines if shadows are on or off";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if string.lower(args[1])=="on" or string.lower(args[1])=="true" then
					if args[2] then
						for _, v in service.GetPlayers(plr, args[2]) do
							Remote.SetLighting(v, "GlobalShadows", true)
						end
					else
						Functions.SetLighting("GlobalShadows", true)
					end
				elseif string.lower(args[1])=="off" or string.lower(args[1])=="false" then
					if args[2] then
						for _, v in service.GetPlayers(plr, args[2]) do
							Remote.SetLighting(v, "GlobalShadows", false)
						end
					else
						Functions.SetLighting("GlobalShadows", false)
					end
				end
			end
		};

		Brightness = {
			Prefix = Settings.Prefix;
			Commands = {"brightness"};
			Args = {"number", "optional player"};
			Description = "Change Brightness";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[2] then
					for _, v in service.GetPlayers(plr, args[2]) do
						Remote.SetLighting(v, "Brightness", args[1])
					end
				else
					Functions.SetLighting("Brightness", args[1])
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


		FogColor = {
			Prefix = Settings.Prefix;
			Commands = {"fogcolor"};
			Args = {"num,num,num", "optional player"};
			Description = "Fog Color";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Argument 1 missing")

				local color = Functions.ParseColor3(args[1])
				assert(color, "Invalid color provided")

				if args[2] then
					for _, v in service.GetPlayers(plr, args[2]) do
						Remote.SetLighting(v, "FogColor", color)
					end
				else
					Functions.SetLighting("FogColor", color)
				end
			end
		};

		FogStartEnd = {
			Prefix = Settings.Prefix;
			Commands = {"fog"};
			Args = {"start", "end", "optional player"};
			Description = "Fog Start/End";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[3] then
					for _, v in service.GetPlayers(plr, args[3]) do
						Remote.SetLighting(v, "FogEnd", args[2])
						Remote.SetLighting(v, "FogStart", args[1])
					end
				else
					Functions.SetLighting("FogEnd", args[2])
					Functions.SetLighting("FogStart", args[1])
				end
			end
		};



		StarterGive = {
			Prefix = Settings.Prefix;
			Commands = {"startergive"};
			Args = {"player", "toolname"};
			Description = "Places the desired tool into the target player(s)'s StarterPack";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local found = {}
				local temp = service.New("Folder")
				for _, tool in if Settings.RecursiveTools then Settings.Storage:GetDescendants() else Settings.Storage:GetChildren() do
					if tool:IsA("BackpackItem") then
						if string.lower(args[2]) == "all" or string.sub(string.lower(tool.Name),1, #args[2])==string.lower(args[2]) then
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
							t:Clone().Parent = v.StarterGear
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

		StarterRemove = {
			Prefix = Settings.Prefix;
			Commands = {"starterremove"};
			Args = {"player", "toolname"};
			Description = "Removes the desired tool from the target player(s)'s StarterPack";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, string.lower(args[1])) do
					local StarterGear = v:FindFirstChildOfClass("StarterGear")
					if StarterGear then
						for _, tool in StarterGear:GetChildren() do
							if tool:IsA("BackpackItem") then
								if string.lower(args[2]) == "all" or string.find(string.lower(tool.Name), string.lower(args[2])) == 1 then
									tool:Destroy()
								end
							end
						end
					end
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

		Steal = {
			Prefix = Settings.Prefix;
			Commands = {"steal", "stealtools"};
			Args = {"player1", "player2"};
			Description = "Steals player1's tools and gives them to player2";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local victims = service.GetPlayers(plr, args[1])
				local stealers = service.GetPlayers(plr, args[2])
				for _, victim in victims do
					local backpack = victim:FindFirstChildOfClass("Backpack")
					if not backpack then continue end
					task.defer(function()
						local hum = victim.Character and victim.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:UnequipTools() end
						for _, p in stealers do
							local destination = p:FindFirstChildOfClass("Backpack")
							if not destination then continue end
							for _, tool in backpack:GetChildren() do
								if #stealers > 1 then
									tool:Clone().Parent = destination
								else
									tool.Parent = destination
								end
							end
						end
						backpack:ClearAllChildren()
					end)
				end
			end
		};

		CopyTools = {
			Prefix = Settings.Prefix;
			Commands = {"copytools"};
			Args = {"player1", "player2"};
			Description = "Copies player1's tools and gives them to player2";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local p1 = service.GetPlayers(plr, args[1])
				local p2 = service.GetPlayers(plr, args[2])
				for _, v in p1 do
					local backpack = v:FindFirstChildOfClass("Backpack")
					if not backpack then continue end
					for _, m in p2 do
						for _, n in backpack:GetChildren() do
							n:Clone().Parent = m:FindFirstChildOfClass("Backpack")
						end
					end
				end
			end
		};

		RemoveGuis = {
			Prefix = Settings.Prefix;
			Commands = {"clearscreenguis", "clrscreenguis", "removeguis", "noguis"};
			Args = {"player"};
			Description = "Removes all of the target player(s)'s on-screen GUIs except Adonis GUIs";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.LoadCode(v, [[for i, v in ipairs(service.PlayerGui:GetChildren()) do if not client.Core.GetGui(v) then pcall(v.Destroy, v) end end]])
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

		GetGroupRank = {
			Prefix = Settings.Prefix;
			Commands = {"rank", "getrank", "grouprank"};
			Args = {"player", "group name"};
			Description = "Shows you what rank the target player(s) are in the specified group";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[2], "Missing group name (argument #2)")
				for _, v in service.GetPlayers(plr, args[1]) do
					local groupInfo = Admin.GetPlayerGroup(v, args[2])
					if groupInfo then
						Functions.Hint(string.format("%s has rank [%d] %s in %s", service.FormatPlayer(v), groupInfo.Rank, groupInfo.Role, groupInfo.Name), {plr})
					else
						Functions.Hint(service.FormatPlayer(v) .. " is not in the group " .. args[2], {plr})
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

		JumpPower = {
			Prefix = Settings.Prefix;
			Commands = {"jpower", "jpow", "jumppower"};
			Args = {"player", "number"};
			Description = "Set the target player(s)'s jump power to <number>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.JumpPower = args[2] or 50
						hum.JumpHeight = (args[2] or 50) / (50/7.2)
					end
				end
			end
		};

		JumpHeight = {
			Prefix = Settings.Prefix;
			Commands = {"jheight", "jumpheight"};
			Args = {"player", "number"};
			Description = "Set the target player(s)'s jump height to <number>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.JumpHeight = args[2] or 7.2
						hum.JumpPower = (args[2] or 7.2) * (50/7.2)
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
								Message = "Character walk speed has been set to ".. speed;
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
				for _, v in service.GetPlayers(plr, args[1]) do
					for a, tm in service.Teams:GetChildren() do
						if string.sub(string.lower(tm.Name), 1, #args[2]) == string.lower(args[2]) then
							v.Team = tm
							if Settings.CommandFeedback then
								Functions.Notification("Team", "You are now on the '"..tm.Name.."' team.", {v}, 15, "Info") -- Functions.Notification(title,message,player,time,icon)
							end
						end
					end
				end
			end
		};

		RandomTeam = {
			Prefix = Settings.Prefix;
			Commands = {"rteams", "rteam", "randomizeteams", "randomteams", "randomteam"};
			Args = {"players", "teams"};
			Description = "Randomize teams; :rteams or :rteams all or :rteams nonadmins team1,team2,etc";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local tArgs = {}
				local teams = {}
				local players = service.GetPlayers(plr, args[1] or "all")
				local cTeam = 1

				local function assign()
					local pIndex = math.random(1, #players)
					local player = players[pIndex]
					local team = teams[cTeam]

					cTeam += 1
					if cTeam > #teams then
						cTeam = 1
					end

					if player and player.Parent then
						player.Team = team
					end

					table.remove(players, pIndex)
					if #players > 0 then
						assign()
					end
				end

				if args[2] then
					for s in string.gmatch(args[2], "(%w+)") do
						table.insert(tArgs, s)
					end
				end


				for i, team in service.Teams:GetChildren() do
					if #tArgs > 0 then
						for ind, check in tArgs do
							if string.sub(string.lower(team.Name), 1, #check) == string.lower(check) then
								table.insert(teams, team)
							end
						end
					else
						table.insert(teams, team)
					end
				end

				cTeam = math.random(1, #teams)
				assign()
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

		SetFOV = {
			Prefix = Settings.Prefix;
			Commands = {"fov", "fieldofview", "setfov"};
			Args = {"player", "number"};
			Description = "Set the target player(s)'s field of view to <number> (min 1, max 120)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2] and tonumber(args[2]), "Missing or invalid FOV number")
				for i, v in service.GetPlayers(plr, args[1]) do
					Remote.LoadCode(v,[[workspace.CurrentCamera.FieldOfView=]].. math.clamp(tonumber(args[2]), 1, 120))
				end
			end
		};

		Place = {
			Prefix = Settings.Prefix;
			Commands = {"place"};
			Args = {"player", "placeID/serverName"};
			NoStudio = true;
			Description = "Teleport the target player(s) to the place belonging to <placeID> or a reserved server";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local reservedServerInfo = (Core.GetData("PrivateServers") or {})[args[2]]
				local placeId = assert(if reservedServerInfo then reservedServerInfo.ID else tonumber(args[2]), "Invalid place ID or server name (argument #2)")
				local teleportOptions = if reservedServerInfo then service.New("TeleportOptions", {
					ReservedServerAccessCode = reservedServerInfo.Code
				}) else nil
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						if
							Remote.MakeGuiGet(v, "Notification", {
								Title = "Teleport";
								Text = if reservedServerInfo then string.format("Click to teleport to server %s.", args[2]) else string.format("Click to teleport to place %d.", placeId);
								Time = 30;
								OnClick = Core.Bytecode("return true");
							})
						then
							service.TeleportService:TeleportAsync(placeId, {v}, teleportOptions)
						else
							Functions.Hint(service.FormatPlayer(v).." declined to teleport", {plr})
						end
					end)
				end
			end
		};

		MakeServer = {
			Prefix = Settings.Prefix;
			Commands = {"makeserver", "reserveserver", "privateserver"};
			Args = {"serverName", "(optional) placeId"};
			Filter = true;
			NoStudio = true; -- TeleportService does not work in Studio
			Description = "Makes a private server that you can teleport yourself and friends to using :place player(s) serverName; Will overwrite servers with the same name; Caps specific";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local place = tonumber(args[2]) or game.PlaceId
				local code, serverId = service.TeleportService:ReserveServer(place)
				local servers = Core.GetData("PrivateServers") or {}
				servers[args[1]] = {Code = code, ID = place, PrivateServerID = serverId}
				Core.SetData("PrivateServers", servers)
				Functions.Hint("Made server "..args[1].." | Place: "..place, {plr})
			end
		};

		DeleteServer = {
			Prefix = Settings.Prefix;
			Commands = {"delserver", "deleteserver", "removeserver", "rmserver"};
			Args = {"serverName"};
			Description = "Deletes a private server from the list.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local servers = Core.GetData("PrivateServers") or {}
				if servers[args[1]] then
					servers[args[1]] = nil
					Core.SetData("PrivateServers", servers)
					Functions.Hint("Removed server "..args[1], {plr})
				else
					Functions.Hint("Server "..args[1].." was not found!", {plr})
				end
			end
		};

		ListServers = {
			Prefix = Settings.Prefix;
			Commands = {"privateservers", "createdservers"};
			Args = {};
			Description = "Shows you a list of private servers that were created with :makeserver";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local servers = Core.GetData("PrivateServers") or {}
				local tab = table.create(#servers)
				for i, v in servers do
					table.insert(tab, {Text = i, Desc = "Place: "..v.ID.." | Code: "..v.Code})
				end
				Remote.MakeGui(plr, "List", {Title = "Servers"; Table = tab;})
			end
		};

		GRPlaza = {
			Prefix = Settings.Prefix;
			Commands = {"grplaza", "grouprecruitingplaza", "groupplaza"};
			Args = {"player"};
			Description = "Teleports the target player(s) to the Group Recruiting Plaza to look for potential group members";
			NoStudio = true;
			Hidden = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Notification", {
						Title = "Teleport";
						Text = "Click to teleport to GRP";
						Time = 30;
						OnClick = Core.Bytecode("service.TeleportService:Teleport(6194809)");
					})
				end
			end
		};

		Teleport = {
			Prefix = Settings.Prefix;
			Commands = {"tp", "teleport", "transport"};
			Args = {"player", "destination ('<player>'/'waypoint-<name>'/'<x>,<y>,<z>')"};
			Description = "Teleports the target player(s) to the specified player, waypoint or coordinates";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player (argument #1)")
				assert(args[2], "Missing destination (argument #2)")

				local function teleportPlayers(destination: Vector3)
					for _, v in service.GetPlayers(plr, args[1]) do
						local rootPart = v.Character and (v.Character.PrimaryPart or v.Character:FindFirstChild("HumanoidRootPart"))
						if not (rootPart and rootPart:IsA("BasePart")) then
							continue
						end

						if workspace.StreamingEnabled then
							v:RequestStreamAroundAsync(destination)
						end

						local hum = v.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							if hum.SeatPart then
								Functions.RemoveSeatWelds(hum.SeatPart)
							end
							if hum.Sit then
								hum.Sit = false
								hum.Jump = true
							end
						end

						local flightPosObject = rootPart:FindFirstChild("ADONIS_FLIGHT_POSITION")
						local flightGyroObject = rootPart:FindFirstChild("ADONIS_FLIGHT_GYRO")
						if flightPosObject and (flightPosObject:IsA("AlignPosition")) then
							flightPosObject.Position = rootPart.Position
						end
						if flightGyroObject and flightGyroObject:IsA("AlignOrientation") then
							flightGyroObject.CFrame = rootPart.CFrame
						end

						wait()
						--rootPart.Position = destination
						v.Character:MoveTo(destination)

						if flightPosObject and flightPosObject:IsA("AlignPosition") then
							flightPosObject.Position = rootPart.Position
						end
						if flightGyroObject and flightGyroObject:IsA("AlignOrientation") then
							flightGyroObject.CFrame = rootPart.CFrame
						end
					end
				end

				local waypointName = args[2]:lower():match("^waypoint%-(.*)")
				if waypointName then
					for name, pos in Variables.Waypoints do
						if name:lower() == waypointName:lower() then
							teleportPlayers(pos)
							return
						end
					end
					error("No waypoint named '"..waypointName.."' exists", 2)
				else
					local x, y, z = args[2]:match("^(%d+),(%d+),(%d+)$")
					if x then
						teleportPlayers(Vector3.new(x, y, z))
					else
						local target = service.GetPlayers(plr, args[2])[1]
						if target then
							assert(target.Character, "Destination player has no character")
							teleportPlayers(Vector3.new(target.Character:GetPivot()))
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
					Question = "Would you like to use "..Settings.Prefix.."massbring instead? (Arranges the "..#players.." players in rows.)";
					}) ~= "Yes"
				then
					Commands.Teleport.Function(plr, {args[1], "@"..plr.Name})
				else
					Process.Command(plr, Settings.Prefix.."massbring"..Settings.SplitKey..args[1])
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
				Commands.Teleport.Function(plr, {"@"..plr.Name, assert(args[1], "Missing destination (argument #1)")})
			end
		};

		MassBring = {
			Prefix = Settings.Prefix;
			Commands = {"massbring", "bringrows", "bringlines"};
			Args = {"player(s)", "lines (default: 3)"};
			Description = "Teleports the target player(s) to you; positioning them evenly in specified lines";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local plrRootPart = assert(
					assert(plr.Character,"Your character is missing"):FindFirstChild("HumanoidRootPart"),
					"Your HumanoidRootPart is missing"
				)
				local players = service.GetPlayers(plr, assert(args[1], "Missing target players (argument #1)"))
				local numPlayers = #players
				local lines = math.clamp(tonumber(args[2]) or 3, 1, numPlayers)

				for l = 1, lines do
					local offsetX = if l == 1 then 0
						elseif l % 2 == 1 then -(math.ceil((l - 2) / 2) * 4)
						else math.ceil(l / 2) * 4

					for i = (l-1) * math.floor(numPlayers/lines) + 1, l * math.floor(numPlayers/lines) do
						local char = players[i].Character
						if not char then continue end
						
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then
							if hum.SeatPart then
								Functions.RemoveSeatWelds(hum.SeatPart)
							end
							if hum.Sit then
								hum.Sit = false
								hum.Jump = true
							end
						end
						
						task.wait()

						local rootPart = char:FindFirstChild("HumanoidRootPart")
						if rootPart then
							rootPart.CFrame = (
								plrRootPart.CFrame
									* CFrame.Angles(0, math.rad(90), 0)
									* CFrame.new(5 + ((i-1) - (l-1) * math.floor(numPlayers/lines)) * 2, 0, offsetX)
							) * CFrame.Angles(0, math.rad(90), 0)
						end
					end
				end
				if numPlayers%lines ~= 0 then
					for i = lines*math.floor(numPlayers/lines)+1, lines*math.floor(numPlayers/lines) + numPlayers%lines do
						local char = players[i].Character
						if not char then continue end

						local r = i % (lines*math.floor(numPlayers/lines))
						local offsetX = if r == 1 then 0
							elseif r % 2 == 1 then -(math.ceil((r - 2) / 2) * 4)
							else math.ceil(r / 2) * 4

						--[[if n.Character.Humanoid.Sit then
							n.Character.Humanoid.Sit = false
							wait(0.5)
						end]]

						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then
							hum.Jump = true
						end
						task.wait()

						local rootPart = char:FindFirstChild("HumanoidRootPart")
						if rootPart then
							rootPart.CFrame = (
								plrRootPart.CFrame
									* CFrame.Angles(0, math.rad(90), 0)
									* CFrame.new(5 + (math.floor(numPlayers/lines)) * 2, 0, offsetX)
							) * CFrame.Angles(0, math.rad(90), 0)
						end
					end
				end
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
				for _, v in service.GetPlayers(plr, args[1]) do
					local leaderstats = v:FindFirstChild("leaderstats")
					if leaderstats then
						local absoluteMatch = leaderstats:FindFirstChild(statName)
						if absoluteMatch and absoluteMatch:IsA("ValueBase") then
							absoluteMatch.Value = args[3]
						else
							for _, st in leaderstats:GetChildren() do
								if st:IsA("ValueBase") and string.match(st.Name:lower(), "^"..statName:lower()) then
									st.Value = args[3]
								end
							end
						end
					else
						Functions.Hint(service.FormatPlayer(v).." doesn't have a leaderstats folder", {plr})
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
								if (st:IsA("IntValue") or st:IsA("NumberValue")) and string.match(st.Name:lower(), "^"..statName:lower()) then
									st.Value += valueToAdd
								end
							end
						end
					else
						Functions.Hint(service.FormatPlayer(v).." doesn't have a leaderstats folder", {plr})
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
								if (st:IsA("IntValue") or st:IsA("NumberValue")) and string.match(st.Name:lower(), "^"..statName:lower()) then
									st.Value -= valueToSubtract
								end
							end
						end
					else
						Functions.Hint(service.FormatPlayer(v).." doesn't have a leaderstats folder", {plr})
					end
				end
			end
		};

		CustomTShirt = {
			Prefix = Settings.Prefix;
			Commands = {"customtshirt"};
			Args = {"player", "ID"};
			Description = "Give the target player(s) the t-shirt that belongs to <ID>. Supports images and catalog items.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				local ClothingId = tonumber(args[2])
				local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
				local TShirt = ((AssetIdType == 11 or AssetIdType == 2) and service.Insert(ClothingId)) or (AssetIdType == 1 and Functions.CreateClothingFromImageId("ShirtGraphic", ClothingId)) or error("Item ID passed has invalid item type")
				assert(TShirt, "Could not retrieve t-shirt asset for the supplied ID")

				local clothingTemplate = "rbxassetid://"..ClothingId

				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						local bCreateNewDefaultClothing = false

						if humanoid then
							local humanoidAppliedDesc = humanoid:GetAppliedDescription()
							if humanoidAppliedDesc then
								-- Check if the player already has a specified clothing instance.
								local prePlayerShirtGraphic = v.Character:FindFirstChildOfClass("ShirtGraphic")

								-- If the character has the specified clothing.
								if prePlayerShirtGraphic then
									-- Check the humanoid description for clothing ID.
									if humanoidAppliedDesc.GraphicTShirt == 0 then
										-- Remove all the specified clothings, assuming it was manually created.
										for _, v in v.Character:GetChildren() do
											if v:IsA("ShirtGraphic") then
												v:Destroy()
											end
										end

										bCreateNewDefaultClothing = true
									end
								else -- If the specified clothing was not found.
									if humanoidAppliedDesc.GraphicTShirt == 0 then
										bCreateNewDefaultClothing = true
									else
										-- If there was ment to be a specified clothing, but it doesn't exist anymore,
										-- then just create a default clothing as well.
										bCreateNewDefaultClothing = true
									end
								end


								if bCreateNewDefaultClothing then
									-- Set a new specified clothing.
									local humDescClone = humanoidAppliedDesc:Clone()

									humDescClone.GraphicTShirt = 6901238398 -- Some template shirt graphic
									v.Character.Humanoid:ApplyDescription(humDescClone, Enum.AssetTypeVerification.Always)
									humDescClone:Destroy()
								end

								-- Set the specified clothing.
								local playerShirtGraphicInstance = v.Character:FindFirstChildOfClass("ShirtGraphic")

								if playerShirtGraphicInstance then
									playerShirtGraphicInstance.Graphic = clothingTemplate
								else
									-- Incase something went wrong
									TShirt:Clone().Parent = v.Character
								end
							else
								-- If no HumanoidDescription
								TShirt:Clone().Parent = v.Character
							end
						end
					end
				end
			end
		};

		CustomShirt = {
			Prefix = Settings.Prefix;
			Commands = {"customshirt"};
			Args = {"player", "ID"};
			Description = "Give the target player(s) the shirt that belongs to <ID>. Supports images and catalog items.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local ClothingId = tonumber(args[2])
				local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
				local Shirt = AssetIdType == 11 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Shirt", ClothingId) or error("Item ID passed has invalid item type")
				assert(Shirt, "Unexpected error occured; clothing is missing")

				local clothingTemplate = "rbxassetid://"..ClothingId

				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						local bCreateNewDefaultClothing = false

						if humanoid then
							local humanoidAppliedDesc = humanoid:GetAppliedDescription()
							if humanoidAppliedDesc then
								-- Check if the player already has a specified clothing instance.
								local prePlayerShirt = v.Character:FindFirstChildOfClass("Shirt")

								-- If the character has the specified clothing.
								if prePlayerShirt then
									-- Check the humanoid description for clothing ID.
									if humanoidAppliedDesc.Shirt == 0 then
										-- Remove all the specified clothings, assuming it was manually created.
										for _, v in v.Character:GetChildren() do
											if v:IsA("Shirt") then
												v:Destroy()
											end
										end

										bCreateNewDefaultClothing = true
									end
								else -- If the specified clothing was not found.
									if humanoidAppliedDesc.Shirt == 0 then
										bCreateNewDefaultClothing = true
									else
										-- If there was ment to be a specified clothing, but it doesn't exist anymore,
										-- then just create a default clothing as well.
										bCreateNewDefaultClothing = true
									end
								end


								if bCreateNewDefaultClothing then
									-- Set a new specified clothing.
									local humDescClone = humanoidAppliedDesc:Clone()

									-- Default Shirt ID 855777286, given when no valid shirt was set with HumanoidDescription
									humDescClone.Shirt = 855777286 -- Default shirt TODO: You want to change this because the ID put here can't be given with the command if already ran.
									v.Character.Humanoid:ApplyDescription(humDescClone, Enum.AssetTypeVerification.Always)
									humDescClone:Destroy()
								end

								-- Set the specified clothing.
								local playerShirtInstance = v.Character:FindFirstChildOfClass("Shirt")

								if playerShirtInstance then
									playerShirtInstance.ShirtTemplate = clothingTemplate
								else
									-- Incase something went wrong
									Shirt:Clone().Parent = v.Character
								end
							else
								-- If no HumanoidDescription
								Shirt:Clone().Parent = v.Character
							end
						end
					end
				end
			end
		};

		CustomPants = {
			Prefix = Settings.Prefix;
			Commands = {"custompants"};
			Args = {"player", "id"};
			Description = "Give the target player(s) the pants that belongs to <ID>. Supports images and catalog items.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local ClothingId = tonumber(args[2])
				local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
				local Pants = AssetIdType == 12 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Pants", ClothingId) or error("Item ID passed has invalid item type")
				assert(Pants, "Unexpected error occured; clothing is missing")

				local clothingTemplate = "rbxassetid://"..ClothingId

				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						local bCreateNewDefaultClothing = false

						if humanoid then
							local humanoidAppliedDesc = humanoid:GetAppliedDescription()
							if humanoidAppliedDesc then
								-- Check if the player already has a specified clothing instance.
								local prePlayerPants = v.Character:FindFirstChildOfClass("Pants")

								-- If the character has the specified clothing.
								if prePlayerPants then
									-- Check the humanoid description for clothing ID.
									if humanoidAppliedDesc.Pants == 0 then
										-- Remove all the specified clothings, assuming it was manually created.
										for _, v in v.Character:GetChildren() do
											if v:IsA("Pants") then
												v:Destroy()
											end
										end

										bCreateNewDefaultClothing = true
									end
								else -- If the specified clothing was not found.
									if humanoidAppliedDesc.Pants == 0 then
										bCreateNewDefaultClothing = true
									else
										-- If there was ment to be a specified clothing, but it doesn't exist anymore,
										-- then just create a default clothing as well.
										bCreateNewDefaultClothing = true
									end
								end


								if bCreateNewDefaultClothing then
									-- Set a new specified clothing.
									local humDescClone = humanoidAppliedDesc:Clone()

									-- Default Pants ID 855782781, given when no valid pants was set with HumanoidDescription
									humDescClone.Pants = 855782781 -- Default pants
									v.Character.Humanoid:ApplyDescription(humDescClone, Enum.AssetTypeVerification.Always)
									humDescClone:Destroy()
								end

								-- Set the specified clothing.
								local playerPantsInstance = v.Character:FindFirstChildOfClass("Pants")

								if playerPantsInstance then
									playerPantsInstance.PantsTemplate = clothingTemplate
								else
									-- Incase something went wrong
									Pants:Clone().Parent = v.Character
								end
							else
								-- If no HumanoidDescription
								Pants:Clone().Parent = v.Character
							end
						end
					end
				end
			end
		};

		CustomFace = {
			Prefix = Settings.Prefix;
			Commands = {"customface"};
			Args = {"player", "id"};
			Description = "Give the target player(s) the face that belongs to <ID>. Supports images and catalog items.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local faceId = assert(tonumber(args[2]), "Invalid asset ID provided")
				local faceAssetTypeId = service.MarketPlace:GetProductInfo(tonumber(args[2])).AssetTypeId
				local asset;

				if faceAssetTypeId == 1 then
					asset = service.New("Decal", {
						Name = "face";
						Face = "Front";
						Texture = "rbxassetid://" .. args[2];
					});
				elseif faceAssetTypeId == 13 and Functions.GetTexture(faceId) ~= 6825455804 then -- just incase GetTexture actually works?
					asset = service.New("Decal", {
						Name = "face";
						Face = "Front";
						Texture = "rbxassetid://" .. tostring(Functions.GetTexture(faceId));
					});
				elseif faceAssetTypeId == 18 then
					asset = service.Insert(faceId)
				else
					error("Invalid face(Image/robloxFace)", 0)
				end

				for i, v in service.GetPlayers(plr, args[1]) do
					local Head = v.Character and v.Character:FindFirstChild("Head")
					local face = Head and Head:FindFirstChild("face")

					if Head then
						if face then
							face:Destroy()--.Texture = "http://www.roblox.com/asset/?id=" .. args[2]
						end

						local clone = asset:Clone();
						clone.Parent = v.Character:FindFirstChild("Head")
					end
				end
			end
		};

		AvatarItem = {
			Prefix = Settings.Prefix;
			Commands = {"avataritem", "giveavtaritem", "catalogitem", "accessory", "hat", "tshirt", "givetshirt", "shirt", "giveshirt", "pants", "givepants", "face", "anim",
				"torso", "larm", "leftarm", "rarm", "rightarm", "lleg", "leftleg", "rleg", "rightleg", "head"}; -- Legacy aliases from old commands
			Args = {"player", "ID"};
			Description = "Give the target player(s) the avatar/catalog item matching <ID> and adds it to their HumanoidDescription.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				local itemId = assert(tonumber(args[2]), "Argument 2 missing or invalid")

				local success, productInfo = pcall(service.MarketplaceService.GetProductInfo, service.MarketplaceService, itemId)
				assert(success and productInfo, "Invalid item ID")

				local typeId = productInfo.AssetTypeId

				--// Roblox doesn't expose a good way to insert into a HumanoidDescription from the Enum.AssetType, so we're mapping them out instead.
				local SingleAssetIds = {
					[2] = "GraphicTShirt",
					[11] = "Shirt",
					[12] = "Pants",
					[17] = "Head",
					[18] = "Face",
					[27] = "Torso",
					[28] = "RightArm",
					[29] = "LeftArm",
					[30] = "LeftLeg",
					[31] = "RightLeg",
					[48] = "ClimbAnimation",
					[49] = "DeathAnimation",
					[50] = "FallAnimation",
					[51] = "IdleAnimation",
					[52] = "JumpAnimation",
					[53] = "RunAnimation",
					[54] = "SwimAnimation",
					[55] = "WalkAnimation",
				}
				local AccessoryAssetIds = { -- AssetTypes that are comma-seperated (accessories)
					[8] = "HatAccessory",
					[41] = "HairAccessory",
					[42] = "FaceAccessory",
					[43] = "NeckAccessory",
					[44] = "ShouldersAccessory",
					[45] = "FrontAccessory",
					[46] = "BackAccessory",
					[47] = "WaistAccessory",
				}
				local LayeredAccessoryAssetIds = {
					[64] = Enum.AccessoryType.TShirt,
					[65] = Enum.AccessoryType.Shirt,
					[66] = Enum.AccessoryType.Pants,
					[67] = Enum.AccessoryType.Jacket,
					[68] = Enum.AccessoryType.Sweater,
					[69] = Enum.AccessoryType.Shorts,
					[70] = Enum.AccessoryType.LeftShoe,
					[71] = Enum.AccessoryType.RightShoe,
					[72] = Enum.AccessoryType.DressSkirt,
				}

				for _, v: Player in service.GetPlayers(plr, args[1]) do
					local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()

						if SingleAssetIds[typeId] then
							humanoidDesc[SingleAssetIds[typeId]] = itemId
						elseif AccessoryAssetIds[typeId] then
							if string.find(humanoidDesc[AccessoryAssetIds[typeId]], tostring(itemId)) then continue end
							humanoidDesc[AccessoryAssetIds[typeId]] ..= ","..itemId
						elseif LayeredAccessoryAssetIds[typeId] then
							local accessories = humanoidDesc:GetAccessories(true)
							table.insert(accessories, {
								Order = #accessories,
								AssetId = itemId,
								AccessoryType = LayeredAccessoryAssetIds[typeId]
							})
							humanoidDesc:SetAccessories(accessories, true)
						elseif typeId == 61 then
							humanoidDesc:AddEmote(productInfo.Name, itemId)
						else
							error("Item not supported")
						end

						task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc, Enum.AssetTypeVerification.Always)
					end
				end
			end
		};

		RemoveTShirt = {
			Prefix = Settings.Prefix;
			Commands = {"removetshirt", "untshirt", "notshirt"};
			Args = {"player"};
			Description = "Remove any t-shirt(s) worn by the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
							humanoidDesc.GraphicTShirt = 0
							task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc, Enum.AssetTypeVerification.Always)
						end
					end
				end
			end
		};

		RemoveShirt = {
			Prefix = Settings.Prefix;
			Commands = {"removeshirt", "unshirt", "noshirt"};
			Args = {"player"};
			Description = "Remove any shirt(s) worn by the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				for _, v: Player in service.GetPlayers(plr, args[1]) do
					local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
						humanoidDesc.Shirt = 0
						task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc, Enum.AssetTypeVerification.Always)
					end
				end
			end
		};

		RemovePants = {
			Prefix = Settings.Prefix;
			Commands = {"removepants"};
			Args = {"player"};
			Description = "Remove any pants(s) worn by the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				for _, v: Player in service.GetPlayers(plr, args[1]) do
					local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
						humanoidDesc.Pants = 0
						task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc, Enum.AssetTypeVerification.Always)
					end
				end
			end
		};

		TargetAudio = {
			Prefix = Settings.Prefix;
			Commands = {"taudio", "localsound", "localaudio", "lsound", "laudio"};
			Args = {"player", "audioId", "noLoop", "pitch", "volume"};
			Description = "Plays an audio on the specified player's client";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})

				assert(args[1], "Missing player name")
				assert(args[2] and tonumber(args[2]), "Missing or invalid AudioId")

				local id = args[2]
				local volume = 1 --tonumber(args[5]) or 1
				local pitch = 1 --tonumber(args[4]) or 1
				local loop = true

				for i, v in Variables.MusicList do
					if id==string.lower(v.Name) then
						id = v.ID
						if v.Pitch then
							pitch = v.Pitch
						end
						if v.Volume then
							volume=v.Volume
						end
					end
				end

				if #HTTP.Trello.Music ~= 0 then
					for i, v in HTTP.Trello.Music do
						if id==string.lower(v.Name) then
							id = v.ID
							if v.Pitch then
								pitch = v.Pitch
							end
							if v.Volume then
								volume = v.Volume
							end
						end
					end
				end

				if args[3] and args[3] == "true" then loop = false end
				volume = tonumber(args[5]) or volume
				pitch = tonumber(args[4]) or pitch


				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "PlayAudio", id, volume, pitch, loop)

				end
				Functions.Hint("Playing Audio on Player's Client", {plr})
			end
		};

		UnTargetAudio = {
			Prefix = Settings.Prefix;
			Commands = {"untaudio", "unlocalsound", "unlocalaudio", "unlsound", "unlaudio"};
			Args = {"player"};
			Description = "Stops audio playing on the specified player's client";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "StopAudio", "all")

				end
			end
		};

		CharacterAudio = {
			Prefix = Settings.Prefix;
			Commands = {"charaudio", "charactermusic", "charmusic"};
			Args = {"player", "audioId", "volume", "loop(true/false)", "pitch"};
			Description = "Plays an audio from the target player's character";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2] and tonumber(args[2]), "Missing or invalid AudioId")

				local volume = tonumber(args[3]) or 1
				local looped = args[4]
				local pitch = tonumber(args[5]) or 1

				if looped then
					if looped == "true" or looped == "1" then
						looped = true
					else
						looped = false
					end
				else
					looped = true -- should be on by default
				end

				local audio = service.New("Sound", {
					Volume = volume;
					Looped = looped;
					Pitch = pitch;
					Name = "ADONIS_AUDIO";
					SoundId = "rbxassetid://"..args[2];
				})

				for i, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character
					local rootPart = char and char:FindFirstChild("HumanoidRootPart")
					if rootPart then
						local new = audio:Clone()

						if looped == false then
							new.Ended:Connect(function()
								new:Destroy() -- Destroy character audio after sound is finished if loop is off.
							end)
						end

						new.Parent = rootPart
						new:Play()
					end
				end
			end;
		};

		UnCharacterAudio = {
			Prefix = Settings.Prefix;
			Commands = {"uncharaudio", "uncharactermusic", "uncharmusic"};
			Args = {"player"};
			Description = "Removes audio placed into character via "..Settings.Prefix.."charaudio command";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character
					local rootPart = char and char:FindFirstChild("HumanoidRootPart")
					if rootPart then
						local found = rootPart:FindFirstChild("ADONIS_AUDIO")
						if found then
							found:Stop()
							found:Destroy()
						end
					end
				end
			end;
		};

		Pause = {
			Prefix = Settings.Prefix;
			Commands = {"pause", "pausemusic", "psound", "pausesound"};
			Args = {};
			Description = "Pauses the current playing song";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				for i, v in service.SoundService:GetChildren() do
					if v.Name=="ADONIS_SOUND" then
						if v.IsPaused == false then
							v:Pause()
							Functions.Hint("Music is now paused | Run "..Settings.Prefix.."resume to resume playback", {plr})
						else
							Functions.Hint("Music is already paused | Run "..Settings.Prefix.."resume to resume", {plr})
						end

					end
				end
			end
		};

		Resume = {
			Prefix = Settings.Prefix;
			Commands = {"resume", "resumemusic", "rsound", "resumesound"};
			Args = {};
			Description = "Resumes the current playing song";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				for i, v in service.SoundService:GetChildren() do
					if v.Name=="ADONIS_SOUND" then
						if v.IsPaused == true then
							v:Resume()
							Functions.Hint("Resuming Playback...", {plr})
						else
							Functions.Hint("Music is not paused", {plr})
						end

					end
				end
			end
		};

		Pitch = {
			Prefix = Settings.Prefix;
			Commands = {"pitch"};
			Args = {"number"};
			Description = "Change the pitch of the currently playing song";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local pitch = args[1]
				for i, v in service.SoundService:GetChildren() do
					if v.Name=="ADONIS_SOUND" then
						if string.sub(args[1], 1, 1) == "+" then
							v.Pitch=v.Pitch+tonumber(string.sub(args[1], 2))
						elseif string.sub(args[1], 1, 1) == "-" then
							v.Pitch=v.Pitch-tonumber(string.sub(args[1], 2))
						else
							v.Pitch = pitch
						end

					end
				end
			end
		};

		Volume = {
			Prefix = Settings.Prefix;
			Commands = {"volume", "vol"};
			Args = {"number"};
			Description = "Change the volume of the currently playing song";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local volume = tonumber(args[1])
				assert(volume, "Volume must be a valid number")
				for i, v in service.SoundService:GetChildren() do
					if v.Name=="ADONIS_SOUND" then
						if string.sub(args[1], 1, 1) == "+" then
							v.Volume=v.Volume+tonumber(string.sub(args[1], 2))
						elseif string.sub(args[1], 1, 1) == "-" then
							v.Volume=v.Volume-tonumber(string.sub(args[1], 2))
						else
							v.Volume = volume
						end
					end
				end
			end
		};

		Shuffle = {
			Prefix = Settings.Prefix;
			Commands = {"shuffle"};
			Args = {"songID1,songID2,songID3,etc"};
			Description = "Play a list of songs automatically; Stop with :shuffle off";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				service.StopLoop("MusicShuffle")
				task.spawn(Commands.StopMusic.Function)
				if not args[1] then error("Missing argument") end
				if string.lower(args[1])~="off" then
					local idList = {}

					for ent in string.gmatch(args[1], "[^%s,]+") do
						local id, pitch = string.match(ent, "(.*):(.*)")
						if id then
							id = tonumber(id)
						else
							id = tonumber(ent)
						end

						if pitch then
							pitch = tonumber(pitch)
						else
							pitch = 1
						end

						if not id then error("Invalid ID: "..tostring(id)) end

						table.insert(idList, {ID = id; Pitch = pitch})
					end

					local s = service.New("Sound")
					s.Name = "ADONIS_SOUND"
					s.Parent = service.SoundService
					s.Looped = false
					s.Archivable = false

					service.StartLoop("MusicShuffle", 1, function()
						local ind = idList[math.random(1, #idList)]
						s.SoundId = "http://www.roblox.com/asset/?id=" .. ind.ID
						s.Pitch = ind.Pitch
						s:Play()
						wait(0.5)
						wait(s.TimeLength+1)
						wait(1)
					end)

					s:Stop()
					s:Destroy()
				end
			end
		};



		Music = {
			Prefix = Settings.Prefix;
			Commands = {"music", "song", "playsong", "sound"};
			Args = {"id", "noloop(true/false)", "pitch", "volume"};
			Description = "Start playing a song";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				local id = string.lower(args[1])
				local looped = args[2]
				local pitch = tonumber(args[3]) or 1
				local mp = service.MarketPlace
				local volume = tonumber(args[4]) or 1
				local name = "#Invalid ID"

				if id ~= "0" and id ~= "off" then
					if looped then
						if looped == "true" then
							looped = false
						else
							looped = true
						end
					else
						looped = true
					end

					for i, v in Variables.MusicList do
						if id == string.lower(v.Name) then
							id = v.ID

							if v.Pitch then
								pitch = v.Pitch
							end
							if v.Volume then
								volume = v.Volume
							end
						end
					end

					for i, v in HTTP.Trello.Music do
						if id == string.lower(v.Name) then
							id = v.ID

							if v.Pitch then
								pitch = v.Pitch
							end
							if v.Volume then
								volume = v.Volume
							end
						end
					end

					pcall(function()
						if tonumber(id) and mp:GetProductInfo(id).AssetTypeId == 3 then
							name = "Now playing "..mp:GetProductInfo(id).Name
						end
					end)

					if name == "#Invalid ID" then
						Functions.Hint("Invalid audio Name/ID", {plr})
						return
					elseif Settings.SongHint then
						Functions.Hint(name, service.GetPlayers())
					end

					for i, v in service.SoundService:GetChildren() do
						if v.ClassName == "Sound" and v.Name == "ADONIS_SOUND" then
							if v.IsPaused == true then
								local ans,event = Remote.GetGui(plr, "YesNoPrompt", {
									Title = "Override paused track?";
									Question = "There is currently a track paused, do you wish to override it?";
								})

								if ans == "No" then
									return
								end
							end

							v:Destroy()
						end
					end

					local s = service.New("Sound")
					s.Name = "ADONIS_SOUND"
					s.SoundId = "http://www.roblox.com/asset/?id=" .. id
					s.Volume = volume
					s.Pitch = pitch
					s.Looped = looped
					s.Archivable = false
					s.Parent = service.SoundService
					wait(0.5)
					s:Play()
				elseif id == "off" or id == "0" then
					for i, v in service.SoundService:GetChildren() do
						if v.ClassName == "Sound" and v.Name == "ADONIS_SOUND" then
							v:Destroy()
						end
					end
				end
			end
		};

		StopMusic = {
			Prefix = Settings.Prefix;
			Commands = {"stopmusic", "musicoff", "unmusic"};
			Args = {};
			Description = "Stop the currently playing song";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.SoundService:GetChildren() do
					if v.Name=="ADONIS_SOUND" then
						v:Destroy()
					end
				end
			end
		};

		MusicList = {
			Prefix = Settings.Prefix;
			Commands = {"musiclist", "listmusic", "songs"};
			Args = {};
			Description = "Shows you the script's available music list";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local tab = table.create(#Variables.MusicList + #HTTP.Trello.Music)
				for _, v in Variables.MusicList do table.insert(tab, v) end
				for _, v in HTTP.Trello.Music do table.insert(tab, v) end
				for i, v in tab do
					tab[i] = {Text = v.Name .." - "..v.ID; Desc = v.ID;}
				end
				Remote.MakeGui(plr, "List", {Title = "Music List", Table = tab, TextSelectable = true})
			end
		};

		Fly = {
			Prefix = Settings.Prefix;
			Commands = {"fly", "flight"};
			Args = {"player", "speed", "noclip? (default: true)"};
			Description = "Lets the target player(s) fly";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local speed = tonumber(args[2]) or 2
				local scr = Deps.Assets.Fly:Clone()
				local sVal = service.New("NumberValue", {
					Name = "Speed";
					Value = speed;
					Parent = scr;
				})
				local NoclipVal = service.New("BoolValue", {
					Name = "Noclip";
					Value = args[3] and (string.lower(args[3]) == "true" or string.lower(args[3]) == "yes");
					Parent = scr;
				})
				
				scr.Name = "ADONIS_FLIGHT"
				
				for i, v in service.GetPlayers(plr, args[1]) do
					local part = v.Character:FindFirstChild("HumanoidRootPart")
					if part then
						local oldp = part:FindFirstChild("ADONIS_FLIGHT_POSITION")
						local oldpa = part:FindFirstChild("ADONIS_FLIGHT_POSITION_ATTACHMENT")
						local oldg = part:FindFirstChild("ADONIS_FLIGHT_GYRO")
						local oldga = part:FindFirstChild("ADONIS_FLIGHT_GYRO_ATTACHMENT")
						local olds = part:FindFirstChild("ADONIS_FLIGHT")
						if oldp then oldp:Destroy() end
						if oldpa then oldpa:Destroy() end
						if oldg then oldg:Destroy() end
						if oldga then oldga:Destroy() end
						if olds then olds:Destroy() end
						
						local new = scr:Clone()
						local flightPositionAttachment: Attachment = service.New("Attachment")
						local flightGyroAttachment: Attachment = service.New("Attachment")
						local flightPosition: AlignPosition = service.New("AlignPosition")
						local flightGyro: AlignOrientation = service.New("AlignOrientation")
						
						flightPositionAttachment.Name = "ADONIS_FLIGHT_POSITION_ATTACHMENT"
						flightPositionAttachment.Parent = part
						
						flightGyroAttachment.Name = "ADONIS_FLIGHT_GYRO_ATTACHMENT"
						flightGyroAttachment.Parent = part
						
						flightPosition.Name = "ADONIS_FLIGHT_POSITION"
						flightPosition.MaxForce = 0
						flightPosition.Position = part.Position
						flightPosition.Attachment0 = flightPositionAttachment
						flightPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
						flightPosition.Parent = part
						
						flightGyro.Name = "ADONIS_FLIGHT_GYRO"
						flightGyro.MaxTorque = 0
						flightGyro.CFrame = part.CFrame
						flightGyro.Attachment0 = flightGyroAttachment
						flightGyro.Mode = Enum.OrientationAlignmentMode.OneAttachment
						flightGyro.Parent = part
						
						new.Parent = part
						new.Disabled = false
						Remote.MakeGui(v, "Notification", {
							Title = "Flight";
							Message = "You are now flying. Press E to toggle flight.";
							Time = 10;
						})
					end
				end
			end
		};
		
		FlySpeed = {
			Prefix = Settings.Prefix;
			Commands = {"flyspeed", "flightspeed"};
			Args = {"player", "speed"};
			Description = "Change the target player(s) flight speed";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local speed = tonumber(args[2])
				
				for i, v in service.GetPlayers(plr, args[1]) do
					local part = v.Character:FindFirstChild("HumanoidRootPart")
					if part then
						local scr = part:FindFirstChild("ADONIS_FLIGHT")
						if scr then
							local sVal = scr:FindFirstChild("Speed")
							if sVal then
								sVal.Value = speed
								if Settings.CommandFeedback then
									Remote.MakeGui(v, "Notification", {
										Title = "Notification";
										Message = "Character fly speed has been set to "..speed;
										Time = 15;
									})
								end
							end
						end
					end
				end
			end
		};
		
		UnFly = {
			Prefix = Settings.Prefix;
			Commands = {"unfly", "ground"};
			Args = {"player"};
			Description = "Removes the target player(s)'s ability to fly";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local part = v.Character:FindFirstChild("HumanoidRootPart")
					if part then
						local oldp = part:FindFirstChild("ADONIS_FLIGHT_POSITION")
						local oldpa = part:FindFirstChild("ADONIS_FLIGHT_POSITION_ATTACHMENT")
						local oldg = part:FindFirstChild("ADONIS_FLIGHT_GYRO")
						local oldga = part:FindFirstChild("ADONIS_FLIGHT_GYRO_ATTACHMENT")
						local olds = part:FindFirstChild("ADONIS_FLIGHT")
						if oldp then oldp:Destroy() end
						if oldpa then oldpa:Destroy() end
						if oldg then oldg:Destroy() end
						if oldga then oldga:Destroy() end
						if olds then olds:Destroy() end
					end
				end
			end
		};
		
		Fling = {
			Prefix = Settings.Prefix;
			Commands = {"fling"};
			Args = {"player"};
			Description = "Fling the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") then
							local xran local zran
							repeat xran = math.random(-9999, 9999) until math.abs(xran) >= 5555
							repeat zran = math.random(-9999, 9999) until math.abs(zran) >= 5555
							v.Character.Humanoid.Sit = true
							v.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
							local Attachment = service.New("Attachment", v.Character.HumanoidRootPart)
							local frc = service.New("VectorForce", v.Character.HumanoidRootPart)
							frc.Name = "BFRC"
							frc.Attachment0 = Attachment
							frc.Force = Vector3.new(xran*4, 9999*5, zran*4)
							service.Debris:AddItem(frc,.1)
							service.Debris:AddItem(Attachment,.1)
						end
					end)
				end
			end
		};

		SuperFling = {
			Prefix = Settings.Prefix;
			Commands = {"sfling", "tothemoon", "superfling"};
			Args = {"player", "optional strength"};
			Description = "Super fling the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local strength = tonumber(args[2]) or 5e6
				local scr = Deps.Assets.Sfling:Clone()
				scr.Strength.Value = strength
				scr.Name = "SUPER_FLING"
				for _, v in service.GetPlayers(plr, args[1]) do
					local new = scr:Clone()
					new.Parent = v.Character.HumanoidRootPart
					new.Disabled = false
				end
			end
		};

		TestFilter = {
			Prefix = Settings.Prefix;
			Commands = {"testfilter", "filtertest", "tfilter"};
			Args = {"player", "text"};
			NoFilter = true;
			Description = "Test out Roblox's text filtering on a player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing text to filter")
				local temp = {{Text="Original: "..args[2], Desc = args[2]}}
				if service.RunService:IsStudio() then
					table.insert(temp, {Text="!! The string has not been filtered !!", Desc="Text filtering does not work in studio"})
				end
				for _, v in service.GetPlayers(plr, args[1]) do
					table.insert(temp, {Text = "-- "..v.DisplayName.." --", Desc = v.UserId.." ("..v.Name..")"})
					table.insert(temp, {Text = "ChatForUser: "..service.TextService:FilterStringAsync(args[2], v.UserId):GetChatForUserAsync(v.UserId)})
					table.insert(temp, {Text = "NonChatForBroadcast: "..service.TextService:FilterStringAsync(args[2], v.UserId):GetNonChatStringForBroadcastAsync()})
					table.insert(temp, {Text = "NonChatForUser: "..service.TextService:FilterStringAsync(args[2], v.UserId):GetNonChatStringForUserAsync(v.UserId)})

				end
				Remote.MakeGui(plr, "List", {Title = "Filtering Results", Tab = temp})
			end
		};

		DisplayName = {
			Prefix = Settings.Prefix;
			Commands = {"displayname", "dname"};
			Args = {"player", "name/hide"};
			Filter = true;
			Description = "Name the target player(s) <name> or say hide to hide their character name";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character;
					local human = char and char:FindFirstChildOfClass("Humanoid");
					if human then
						if string.lower(args[2]) == "hide" then
							human.DisplayName = ""
							Remote.MakeGui(v, "Notification", {
								Title = "Notification";
								Message = "Your character name has been hidden";
								Time = 10;
							})
						else
							human.DisplayName = args[2]
							Remote.MakeGui(v, "Notification", {
								Title = "Notification";
								Message = "Your character name is now \"".. args[2].."\"";
								Time = 10;
							})
						end
					end
				end
			end
		};

		UnDisplayName = {
			Prefix = Settings.Prefix;
			Commands = {"undisplayname", "undname"};
			Args = {"player"};
			Description = "Put the target player(s)'s back to normal";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character;
					local human = char and char:FindFirstChildOfClass("Humanoid");
					if human then
						human.DisplayName = v.DisplayName
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "Your character name has been restored";
							Time = 10;
						})
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

		RemovePackage = {
			Prefix = Settings.Prefix;
			Commands = {"removepackage", "nopackage", "rpackage"};
			Args = {"player"};
			Description = "Removes the target player(s)'s Package";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local rigType = humanoid.RigType
							if rigType == Enum.HumanoidRigType.R6 then
								for _, x in v.Character:GetChildren() do
									if x:IsA("CharacterMesh") then
										x:Destroy()
									end
								end
							elseif rigType == Enum.HumanoidRigType.R15 then
								local rig = Deps.Assets.RigR15
								local rigHumanoid = rig.Humanoid
								local validParts = table.create(#Enum.BodyPartR15:GetEnumItems())
								for _, x in Enum.BodyPartR15:GetEnumItems() do
									validParts[x.Name] = x.Value
								end
								for _, x in rig:GetChildren() do
									if x:IsA("BasePart") and validParts[x.Name] then
										humanoid:ReplaceBodyPartR15(validParts[x.Name], x:Clone())
									end
								end
							end
						end
					end
				end
			end
		};

		GivePackage = {
			Prefix = Settings.Prefix;
			Commands = {"package", "givepackage", "setpackage", "bundle"};
			Args = {"player", "id"};
			Description = "Gives the target player(s) the desired package (ID MUST BE A NUMBER)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1] and args[2] and tonumber(args[2]), "Missing player name")
				assert(args[1] and args[2] and tonumber(args[2]), "Missing or invalid package ID")

				local id = tonumber(args[2])
				local assetHD = Variables.BundleCache[id]

				if assetHD == false then
					Remote.MakeGui(plr, "Output", {Title = "Output"; Message = "Package "..id.." is not supported."})
					return
				end

				if not assetHD then
					local suc,ers = pcall(function() return service.AssetService:GetBundleDetailsAsync(id) end)

					if suc then
						for _, item in ers.Items do
							if item.Type == "UserOutfit" then
								local _, Outfit = pcall(function() return service.Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
								Variables.BundleCache[id] = Outfit
								assetHD = Outfit
								break
							end
						end
					end

					if not suc or not assetHD then
						Variables.BundleCache[id] = false

						Remote.MakeGui(plr, "Output", {Title = "Output"; Message = "Package "..id.." is not supported."})
						return
					end
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character

					if char then
						local humanoid = char:FindFirstChildOfClass"Humanoid"

						if not humanoid then
							Functions.Hint("Could not transfer bundle to "..v.Name, {plr})
						else
							local newDescription = humanoid:GetAppliedDescription()
							local defaultDescription = Instance.new("HumanoidDescription")
							for _, property in {"BackAccessory", "BodyTypeScale", "ClimbAnimation", "DepthScale", "Face", "FaceAccessory", "FallAnimation", "FrontAccessory", "GraphicTShirt", "HairAccessory", "HatAccessory", "Head", "HeadColor", "HeadScale", "HeightScale", "IdleAnimation", "JumpAnimation", "LeftArm", "LeftArmColor", "LeftLeg", "LeftLegColor", "NeckAccessory", "Pants", "ProportionScale", "RightArm", "RightArmColor", "RightLeg", "RightLegColor", "RunAnimation", "Shirt", "ShouldersAccessory", "SwimAnimation", "Torso", "TorsoColor", "WaistAccessory", "WalkAnimation", "WidthScale"} do
								if assetHD[property] ~= defaultDescription[property] then
									newDescription[property] = assetHD[property]
								end
							end

							humanoid:ApplyDescription(newDescription, Enum.AssetTypeVerification.Always)
						end
					end
				end
			end
		};

		Char = {
			Prefix = Settings.Prefix;
			Commands = {"char", "character", "appearance"};
			Args = {"player", "username"};
			Description = "Changes the target player(s)'s character appearence to <ID/Name>. If you want to supply a UserId, supply with 'userid-', followed by a number after 'userid'.";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing username or UserId")

				local target = tonumber(string.match(args[2], "^userid%-(%d*)")) or assert(Functions.GetUserIdFromNameAsync(args[2]), "Unable to fetch user.")
				if target then
					local success, desc = pcall(service.Players.GetHumanoidDescriptionFromUserId, service.Players, target)

					if success then
						for _, v in service.GetPlayers(plr, args[1]) do
							v.CharacterAppearanceId = target

							if v.Character and v.Character:FindFirstChildOfClass("Humanoid") then
								v.Character.Humanoid:ApplyDescription(desc, Enum.AssetTypeVerification.Always)
							end
						end
					else
						error("Unable to get avatar for target user")
					end
				end
			end
		};

		UnChar = {
			Prefix = Settings.Prefix;
			Commands = {"unchar", "uncharacter", "fixappearance"};
			Args = {"player"};
			Description = "Put the target player(s)'s character appearence back to normal";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						v.CharacterAppearanceId = v.UserId

						local Humanoid = v.Character and v.Character:FindFirstChildOfClass("Humanoid")

						if Humanoid then
							local success, desc = pcall(service.Players.GetHumanoidDescriptionFromUserId, service.Players, v.UserId)

							if success then
								Humanoid:ApplyDescription(desc, Enum.AssetTypeVerification.Always)
							end
						end
					end)
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
						service.StartLoop(v.UserId .. "LOOPHEAL", 0.1, function()
							if not v or v.Parent ~= service.Players then
								service.StopLoop(v.UserId .. "LOOPHEAL")
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
			Description = "Undoes "..Settings.Prefix.."loopheal";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.StopLoop(v.UserId.."LOOPHEAL")
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
						Title = service.FormatPlayer(v).."'s Local Log";
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
						Text = v.Text..": "..tostring(v.Desc);
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
						Text = v.Text..": "..v.Desc;
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
								Text = v.Text.. ": ".. v.Desc,
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
				local str = Settings.Prefix.."logs"..(args[2] or "")
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
							table.insert(Settings.Muted, v.Name..":"..v.UserId)
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
					table.insert(list, "[Trello] ".. v)
				end

				Remote.MakeGui(plr, "List", {Title = "Mute List", Table = list})
			end
		};

		Freecam = {
			Prefix = Settings.Prefix;
			Commands = {"freecam"};
			Args = {"player"};
			Description = "Makes it so the target player(s)'s cam can move around freely (Press Space or Shift+P to toggle freecam)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local plrgui = v:FindFirstChildOfClass("PlayerGui")

					if not plrgui or plrgui:FindFirstChild("Freecam") then
						continue
					end

					local freecam = Deps.Assets.Freecam:Clone()
					freecam.Enabled = true
					freecam.ResetOnSpawn = false
					freecam.Freecam.Disabled = false
					freecam.Parent = plrgui

					if Settings.CommandFeedback then
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "Freecam has been enabled. Press Shift+P to toggle freecam on or off.";
							Time = 15;
						})
					end
				end
			end
		};

		UnFreecam = {
			Prefix = Settings.Prefix;
			Commands = {"unfreecam"};
			Args = {"player"};
			Description = "UnFreecam";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local plrgui = v:FindFirstChildOfClass("PlayerGui")
					local freecam = plrgui and plrgui:FindFirstChild("Freecam")
					if freecam then
						if freecam:FindFirstChildOfClass("RemoteFunction") then
							freecam:FindFirstChildOfClass("RemoteFunction"):InvokeClient(v, "End")
						end

						Remote.Send(v, "Function", "SetView", "reset")
						service.Debris:AddItem(freecam, 2)

						if Settings.CommandFeedback then
							Remote.MakeGui(v, "Notification", {
								Title = "Notification";
								Message = "Freecam has been disabled.";
								Time = 15;
							})
						end
					end
				end
			end
		};

		ToggleFreecam = {
			Prefix = Settings.Prefix;
			Commands = {"togglefreecam"};
			Args = {"player"};
			Description = "Toggles Freecam";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local plrgui = v:FindFirstChildOfClass("PlayerGui")
					local freecam = plrgui and plrgui:FindFirstChild("Freecam")
					local remote = freecam and freecam:FindFirstChildOfClass("RemoteFunction")

					if remote then
						remote:InvokeClient(v, "Toggle")
					end
				end
			end
		};

		Bots = {
			Prefix = Settings.Prefix;
			Commands = {"bot", "trainingbot"};
			Args = {"player", "num (max: 50)", "walk", "attack", "friendly", "health", "speed", "damage"};
			Description = "AI bots made for training; ':bot scel 5 true true'";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tonumber(args[2]) and math.clamp(tonumber(args[2]), 1, 50) or 1
				local health = tonumber(args[6]) or 100
				local speed = tonumber(args[7]) or 16
				local damage = tonumber(args[8]) or 5
				local attack = args[4] == "true" and true or false
				local friendly = args[5] == "true" and true or false
				local walk
				
				if args[3] == "false" then
					walk = false
				else
					walk = true
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					Functions.makeRobot(v, num, health, speed, damage, walk, attack, friendly)
				end
			end
		};

		TextToSpeech = {
			Prefix = Settings.Prefix;
			Commands = {"tell", "tts", "texttospeech"};
			Args = {"player", "message"};
			Filter = true;
			Description = "[Experimental] Says aloud the supplied text";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "TextToSpeech", args[2])
				end
			end
		};

		Reverb = {
			Prefix = Settings.Prefix;
			Commands = {"reverb", "ambientreverb"};
			Args = {"reverbType", "optional player"};
			Description = "Lets you change the reverb type with an optional player argument (CASE SENSITTIVE)";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				local rev = args[1]

				local ReverbType = Enum.ReverbType
				local reverbs = ReverbType:GetEnumItems()
				if not rev or not ReverbType[rev] then

					Functions.Hint("Reverb type was not specified or is invalid. Opening list of valid reverb types", {plr})

					local tab = table.create(#reverbs)
					table.insert(tab, {Text = "Note: Argument is CASE SENSITIVE"})
					for _, v in reverbs do
						table.insert(tab, {Text = v.Name})
					end
					Remote.MakeGui(plr, "List", {Title = "Reverbs"; Table = tab;})

					return
				end

				if args[2] then
					for _, v in service.GetPlayers(plr, args[2]) do
						Remote.LoadCode(v, "game:GetService(\"SoundService\").AmbientReverb = Enum.ReverbType["..rev.."]")
					end

					Functions.Hint("Changed Ambient Reverb of specified player(s)", {plr})
				else
					service.SoundService.AmbientReverb = ReverbType[rev]
					Functions.Hint("Successfully changed the Ambient Reverb to "..rev, {plr})
				end
			end
		};

		ResetButtonEnabled = {
			Prefix = Settings.Prefix;
			Commands = {"resetbuttonenabled", "resetenabled", "canreset", "allowreset"};
			Args = {"player", "can reset? (true/false)"};
			Description = "Sets whether the target player(s) can reset their character";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing target player")
				args[2] = string.lower(assert(args[2], "Missing argument #2 (boolean expected)"))
				assert(args[2] == "true" or args[2] == "false", "Invalid argument #2 (boolean expected)")
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "SetCore", "ResetButtonCallback", if args[2] == "true" then true else false)
				end
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
					table.insert(tab, {Text = v[1]..": "..tostring(service.Stats[v[1]]):sub(1, 7); Desc = v[2];})
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
			Description = "Shows you a list and count of players selected in the supplied argument, ex: '"..Settings.Prefix.."select %raiders true' to monitor people in the 'raiders' team";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, selection: string?)
				local players = service.GetPlayers(plr, selection, {DontError = true; NoFakePlayer = true;})
				local tab = {
					"Specified: \""..(selection or (Settings.SpecialPrefix.."me")).."\"",
					"# Players: "..#players,
					"―――――――――――――――――――――――",
				}
				for _, v: Player in players do
					table.insert(tab, {
						Text = service.FormatPlayer(v);
						Desc = "ID: "..v.UserId;
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
					local color = "100, 175, 255"
					table.insert(logTable, v[1] .. ' :: <font color = "rgb(' .. color .. ')">[' .. math.round(v[2]) .. '/' .. math.round(v[3]) .. ']</font>')
				end

				if normalCheck == true then
					table.insert(logTable, "<b><u>Normal Players: </u></b>")
				end

				for _, v in normalTable do
					local color
					if v[2]/v[3] >= .5 then
						color =  math.round(100 + 155 * (v[2]/v[3] * -2 + 2)) .. ", 255, 100"
					else
						color =  "255, " .. math.round(100 + 155 * v[2]/v[3] * 2) ..  ", 100"
					end
					table.insert(logTable, v[1] .. ' :: <font color = "rgb(' .. color .. ')">[' .. math.round(v[2]) .. '/' .. math.round(v[3]) .. ']</font>')
				end

				for _, v in zeroTable do
					local color = "255, 100, 100"
					table.insert(logTable, v[1] .. ' :: <font color = "rgb(' .. color .. ')">[N/A]</font>')
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
