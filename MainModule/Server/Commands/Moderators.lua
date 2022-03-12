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
		AudioPlayer = {
			Prefix = Settings.Prefix;
			Commands = {"audioplayer", "mediaplayer", "musicplayer", "soundplayer", "player", "ap"};
			Args = {"player"};
			Description = "Opens an audio player window";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
					Remote.MakeGui(v, "Music")
				end
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
				local plrLevel = data.PlayerData.Level
				for _, v in ipairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel > targLevel then
						local PlayerName = v.Name
						if not service.Players:FindFirstChild(v.Name) then
							Remote.Send(v, "Function", "Kill")
						else
							v:Kick(args[2])
						end

						Functions.Hint("Kicked ".. PlayerName, {plr})
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
					for _2, v2 in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Args = {};
			Description = "Lets you pass through an object or a wall";
			Fun = false;
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
				local tab = {}
				local variables = Core.Variables
				local timeBans = Core.Variables.TimeBans or {}

				for ind, v in pairs(timeBans) do
					local timeLeft = v.EndTime - os.time()
					local minutes = Functions.RoundToPlace(timeLeft / 60, 2)

					if timeLeft <= 0 then
						table.remove(Core.Variables.TimeBans, ind)
					else
						table.insert(tab, {Text = tostring(v.Name)..":"..tostring(v.UserId), Desc = "Minutes Left: "..tostring(minutes)})
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
					Admin.SlowCache = {};
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
				for _, v in ipairs(service.GetPlayers()) do
					Remote.MakeGui(v, "Countdown", {
						Time = math.round(num);
					})
				end
				--for i = num, 1, -1 do
				--Functions.Message("Countdown", tostring(i), service.Players:GetPlayers(), false, 1.1)
				--Functions.Message(" ", i, false, service.Players:GetPlayers(), 0.8)
				--wait(1)
				--end
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				assert(args[1], "Missing or invalid time amount")
				assert(args[2], "Missing message")
				for _, v in ipairs(service.GetPlayers()) do
					Remote.RemoveGui(v, "Message")
					Remote.MakeGui(v, "Message", {
						Title = "Message from "..service.FormatPlayer(plr);
						Message = args[2];
						Time = tonumber(args[1]);
					})
				end
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
				for _, v in ipairs(service.GetPlayers()) do
					Remote.RemoveGui(v, "Message")
					Remote.MakeGui(v, "Message", {
						Title = "Message from "..service.FormatPlayer(plr);
						Message = args[1]; --service.Filter(args[1], plr, v);
						Time = (#tostring(args[1]) / 19) + 2.5;
						Scroll = true;
					})
				end
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Functions.Message("Message from "..service.FormatPlayer(plr), service.Filter(args[2], plr, v), {v}, true, (#tostring(args[1]) / 19) + 2.5)
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
				for _, v in ipairs(service.GetPlayers()) do
					Remote.RemoveGui(v, "Notify")
					Remote.MakeGui(v, "Notify", {
						Title = "Message from "..service.FormatPlayer(plr);
						Message = service.Filter(args[1], plr, v);
					})
				end
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				local hintFormat = string.format("%s: %s", service.FormatPlayer(plr), args[1])
				for _, v in ipairs(service.GetPlayers()) do
					Remote.MakeGui(v, "Hint", {
						Message = hintFormat; --service.Filter(args[1], plr, v)
						Time = (#tostring(args[1]) / 19) + 2.5;
					})
				end
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
				assert(args[2], "Missing message")
				assert(args[1], "Missing time amount (in seconds)")
				local hintFormat = string.format("%s: %s", service.FormatPlayer(plr), args[1])
				for _, v in ipairs(service.GetPlayers()) do
					Remote.MakeGui(v, "Hint", {
						Message = hintFormat; --service.Filter(args[1], plr, v)
						Time = tonumber(args[1]);
					})
				end
			end
		};

		Warn = {
			Prefix = Settings.Prefix;
			Commands = {"warn", "warning"};
			Args = {"player", "reason"};
			Filter = true;
			Description = "Warns players";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing player name")
				assert(args[2], "You forgot to supply a reason")
				local plrLevel = data.PlayerData.Level
				for _, v in ipairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = false;
					UseFakePlayer = true;
					})) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel > targLevel then
						local data = Core.GetPlayer(v)
						table.insert(data.Warnings, {From = tostring(plr), Message = args[2], Time = os.time()})

						Remote.RemoveGui(v, "Notify")
						Remote.MakeGui(v, "Notify", {
							Title = "Warning from "..tostring(plr);
							Message = args[2];
						})

						Remote.MakeGui(plr, "Notification", {
							Title = "Notification";
							Icon = server.MatIcons.Shield;
							Message = "Warned ".. v.Name;
							Time = 5;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."warnings "..v.Name.."')")
						})
					end
				end
			end
		};

		RemoveWarning = {
			Prefix = Settings.Prefix;
			Commands = {"removewarning"};
			Args = {"player", "warning"};
			Filter = false;
			Description = "Removes the specified warning from the target player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1] and args[2], "Argument missing or incorrect")

				local plrLevel = data.PlayerData.Level
				local warning = args[2]

				for _, v in ipairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = false;
					UseFakePlayer = true;
					})) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel > targLevel then
						local data = Core.GetPlayer(v)

						for i, w in ipairs(data.Warnings) do
							if w.Message:lower():sub(1, #warning) == warning:lower() then
								table.remove(data.Warnings, i)
							end
						end

						Remote.MakeGui(plr, "Notification", {
							Title = "Notification";
							Icon = server.MatIcons.Shield;
							Message = "Removed warning from ".. v.Name;
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
			Args = {"player", "reason"};
			Filter = true;
			Description = "Warns & kicks a player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing player name")
				assert(args[2], "A reason is required for this command")
				local plrLevel = data.PlayerData.Level
				for _, v in ipairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = false;
					})) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel > targLevel then
						local data = Core.GetPlayer(v)

						table.insert(data.Warnings, {From = tostring(plr), Message = args[2], Time = os.time()})
						v:Kick(tostring("\n[Warning from "..tostring(plr).."]\n"..args[2]))

						Remote.MakeGui(plr, "Notification", {
							Title = "Notification";
							Icon = server.MatIcons.Shield;
							Message = "Warned ".. v.Name;
							Time = 5;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."warnings "..v.Name.."')")
						})
					end
				end
			end
		};

		ShowWarnings = {
			Prefix = Settings.Prefix;
			Commands = {"warnings", "showwarnings"};
			Args = {"player"};
			Description = "Shows warnings a player has";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				for _, v in ipairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = false;
					UseFakePlayer = true;
					})) do
					local data = Core.GetPlayer(v)
					local tab = {}

					if data.Warnings then
						for k, m in pairs(data.Warnings) do
							table.insert(tab, {
								Text = "["..k.."] "..m.Message;
								Desc = "Given by: "..m.From.."; "..m.Message;
								Time = m.Time;
							})
						end
					end

					Remote.MakeGui(plr, "List", {
						Title = v.Name;
						Table = tab;
						TimeOptions = {
							WithDate = true;
						}
					})
				end
			end
		};

		ClearWarnings = {
			Prefix = Settings.Prefix;
			Commands = {"clearwarnings"};
			Args = {"player"};
			Description = "Clears any warnings on a player";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local data = Core.GetPlayer(v)
					data.Warnings = {}
					Remote.MakeGui(plr, "Notification", {
						Title = "Notification";
						Icon = server.MatIcons.Shield;
						Message = "Cleared warnings for ".. v.Name;
						Time = 5;
						OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."warnings "..v.Name.."')")
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.Send(v, "Function", "ChatMessage", service.Filter(args[2], plr, v), Color3.new(1, 64/255, 77/255))
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						Routine(function()
							for _, c in ipairs(v.Character:GetChildren()) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1]))  do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						if v.Character then
							for a, obj in ipairs(v.Character:GetChildren()) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
									FormFactor = "Custom";
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

							for _, obj in ipairs(v.Character:GetChildren()) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						local ff = service.New("ForceField", v.Character)
						local hum = v.Character.Humanoid
						local orig = hum.MaxHealth
						local tools = service.New("Model")
						hum.MaxHealth = math.huge
						wait()
						hum.Health = hum.MaxHealth
						for k, t in pairs(v.Backpack:GetChildren()) do
							t.Parent = tools
						end
						Admin.RunCommand(Settings.Prefix.."name", v.Name, "-AFK-_"..v.Name.."_-AFK-")
						local torso = v.Character.HumanoidRootPart
						local pos = torso.CFrame
						local running=true
						local event
						event = v.Character.Humanoid.Jumping:Connect(function()
							running = false
							ff:Destroy()
							hum.Health = orig
							hum.MaxHealth = orig
							for k, t in ipairs(tools:GetChildren()) do
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
			Hidden = false;
			Description = "Heals the target player(s) (Regens their health)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Makes the target player(s) immortal, makes their health so high that normal non-explosive weapons can't kill them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Makes the target player(s) mortal again";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Same as "..server.Settings.Prefix.."god, but also provides blast protection";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Removes any hats the target is currently wearing and from their HumanoidDescription.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, p in ipairs(service.GetPlayers(plr, args[1])) do
					local humanoid: Humanoid? = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
						local DescsToRemove = {"HatAccessory","HairAccessory","FaceAccessory","NeckAccessory","ShouldersAccessory","FrontAccessory","BackAccessory","WaistAccessory"}
						for _, prop in ipairs(DescsToRemove) do
							humanoidDesc[prop] = ""
						end
						humanoid:ApplyDescription(humanoidDesc)
					end
				end
			end
		};

		RemoveHat = {
			Prefix = Settings.Prefix;
			Commands = {"removehat", "rhat"};
			Args = {"player", "accessory name"};
			Hidden = false;
			Description = "Removes specific hat(s) the target is currently wearing";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				-- TODO: HumanoidDescription
				assert(args[2], "Argument(s) missing or nil")
				for _, p in ipairs(service.GetPlayers(plr, args[1])) do
					if not p.Character then continue end
					for _, v in pairs(p.Character:GetChildren()) do
						if v:IsA("Accessory") and v.Name:lower() == args[2]:lower() then
							v:Destroy()
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
			Hidden = false;
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
					for peer in pairs(newSession.Users) do
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
								for pr in pairs(newSession.Users) do
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

				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveGui(v, "Chat")
				end
			end
		};

		UnColorCorrection = {
			Prefix = Settings.Prefix;
			Commands = {"uncolorcorrection", "uncorrection", "uncolorcorrectioneffect"};
			Args = {"player"};
			Hidden = false;
			Description = "UnColorCorrection the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, p in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(p, "WINDOW_COLORCORRECTION", "Camera")
				end
			end
		};

		UnSunRays = {
			Prefix = Settings.Prefix;
			Commands = {"unsunrays"};
			Args = {"player"};
			Hidden = false;
			Description = "UnSunrays the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_SUNRAYS", "Camera")
				end
			end
		};

		UnBloom = {
			Prefix = Settings.Prefix;
			Commands = {"unbloom", "unscreenbloom"};
			Args = {"player"};
			Hidden = false;
			Description = "UnBloom the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_BLOOM", "Camera")
				end
			end
		};

		UnBlur = {
			Prefix = Settings.Prefix;
			Commands = {"unblur", "unscreenblur"};
			Args = {"player"};
			Hidden = false;
			Description = "UnBlur the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_BLUR", "Camera")
				end
			end
		};

		UnLightingEffect = {
			Prefix = Settings.Prefix;
			Commands = {"unlightingeffect", "unscreeneffect"};
			Args = {"player"};
			Hidden = false;
			Description = "Remove admin made lighting effects from the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					for _, e in ipairs({"BLUR", "BLOOM", "THERMAL", "SUNRAYS", "COLORCORRECTION"}) do
						Remote.RemoveLocal(v, "WINDOW_"..e, "Camera")
					end
				end
			end
		};

		ShowSBL = {
			Prefix = Settings.Prefix;
			Commands = {"sbl", "syncedbanlist", "globalbanlist", "trellobans", "trellobanlist"};
			Args = {};
			Hidden = false;
			Description = "Shows Trello bans";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local tab = {}
				for _, banData in ipairs(HTTP.Trello.Bans) do
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
			Hidden = false;
			Description = "Hands an item to a player";
			Fun = false;
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
			Hidden = false;
			Description = "Shows you a list of items currently in the target player(s) backpack";
			Fun = false;
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
					for _, t in ipairs(backpack:GetChildren()) do
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						Remote.MakeGui(plr, "List", {
							Title = v.Name.."'s tools";
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
			Hidden = false;
			Description = "Shows you all players currently in-game, including nil ones";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local players = Functions.GrabNilPlayers("all")
				local tab = {
					"# Players: " .. #players,
					"―――――――――――――――――――――――",
				}
				for _, v in pairs(players) do
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
									Text = "[LOADING] "..v.Name;
									Desc = "Lower: "..string.lower(v.Name).." - Ping: "..ping;
								})
							end
						end
					end)
				end
				for i = 0.1, 5, 0.1 do
					if Functions.CountTable(tab) - 2 >= Functions.CountTable(players) then break end
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
			Hidden = false;
			Description = "Deletes the waypoint named <name> if it exist";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(Variables.Waypoints) do
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
			Hidden = false;
			Description = "Shows available waypoints, mouse over their names to view their coordinates";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local temp={}
				for i, v in pairs(Variables.Waypoints) do
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
			Hidden = false;
			Description = "Shows a list of admin cameras";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local tab = {}
				for i, v in pairs(Variables.Cameras) do
					table.insert(tab, {Text = v.Name, Desc = "Pos: "..tostring(v.Brick.Position)})
				end
				Remote.MakeGui(plr, "List", {Title = "Cameras", Tab = tab})
			end
		};

		MakeCamera = {
			Prefix = Settings.Prefix;
			Commands = {"makecam", "makecamera", "camera"};
			Args = {"name"};
			Filter = true;
			Description = "Makes a camera named whatever you pick";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if plr and plr.Character and plr.Character:FindFirstChild("Head") then
					if workspace:FindFirstChild("Camera: "..args[1]) then
						Functions.Hint(args[1].." Already Exists!", {plr})
					else
						local cam = service.New("Part", workspace)
						cam.Position = plr.Character.Head.Position
						cam.Anchored = true
						cam.BrickColor = BrickColor.new("Really black")
						cam.CanCollide = false
						cam.Locked = true
						cam.FormFactor = "Custom"
						cam.Size = Vector3.new(1, 1, 1)
						cam.TopSurface = "Smooth"
						cam.BottomSurface = "Smooth"
						cam.Name="Camera: "..args[1]
						--service.New("PointLight", cam)
						cam.Transparency=1--.9
						local mesh=service.New("SpecialMesh", cam)
						mesh.Scale=Vector3.new(1, 1, 1)
						mesh.MeshType="Sphere"
						table.insert(Variables.Cameras, {Brick = cam, Name = args[1]})
					end
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
				for i, v in pairs(Variables.Cameras) do
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
				for k, p in pairs(service.GetPlayers(plr, args[1])) do
					for _, v in pairs(service.GetPlayers(plr, args[2])) do
						if v and v.Character:FindFirstChild("Humanoid") then
							plr.ReplicationFocus = v.Character.PrimaryPart
							Remote.Send(p, "Function", "SetView", v.Character.Humanoid)
						end
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character:FindFirstChild("Humanoid") then
						plr.ReplicationFocus = v.Character.PrimaryPart
						Remote.Send(plr, "Function", "SetView", v.Character.Humanoid)
					end
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character:FindFirstChild("Humanoid") then
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
				if args[1] then
					for _, v in pairs(service.GetPlayers(plr, args[1])) do
						plr.ReplicationFocus = nil
						Remote.Send(v, "Function", "SetView", "reset")
					end
				else
					Remote.Send(plr, "Function", "SetView", "reset")
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Prefix = Settings.PlayerPrefix;
			Commands = {"clean"};
			Args = {};
			Hidden = false;
			Description = "Cleans some useless junk out of workspace";
			Fun = false;
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
					for i, v in pairs(Variables.CommandLoops) do
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
					for i, v in ipairs(Variables.CommandLoops) do
						if string.lower(string.sub(i, 1, plr.Name)) == string.lower(plr.Name) then
							Variables.CommandLoops[string.lower(plr.Name)..args[2]] = nil
						end
					end
				elseif name and name=="all" then
					for i, v in ipairs(Variables.CommandLoops) do
						Variables.CommandLoops[string.lower(plr.Name)..args[2]] = nil
					end
				elseif args[2] then
					if Variables.CommandLoops[name..args[2]] then
						Variables.CommandLoops[name..args[2]] = nil
					else
						Remote.MakeGui(plr, "Output", {Title = "Output"; Message = "No loops relating to your search"})
					end
				else
					for i, v in ipairs(Variables.CommandLoops) do
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
			Hidden = false;
			Description = "Shows the target player's ping";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Functions.Hint(v.Name.."'s Ping is "..Remote.Get(v, "Ping").."ms", {plr})
				end
			end
		};
		ShowTasks = {
			Prefix = "";
			Commands = {":tasks", ":tasklist", Settings.Prefix.."tasks", Settings.Prefix.."tasklist"};
			Args = {"player"};
			Hidden = false;
			Description = "Displays running tasks";
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player, target)
				if target then
					for _, v in pairs(Functions.GetPlayers(plr, target)) do
						local temp = {}
						local cTasks = Remote.Get(v, "TaskManager", "GetTasks") or {}

						table.insert(temp, {
							Text = "Client Tasks",
							Desc = "Tasks their client is performing"})

						for _, t in pairs(cTasks) do
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

					for _, v in pairs(tasks) do
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

					for _, v in pairs(cTasks) do
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
					for i, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Send player(s) to a server using the server's JobId";
			Fun = false;
			NoStudio = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local jobId = args[2];
				assert(args[1], "Missing player name")
				assert(jobId, "Missing server JobId")
				if service.RunService:IsStudio() then
					error("Command cannot be used in studio.", 0)
				else
					for _, v in pairs(service.GetPlayers(plr, args[1])) do
						Functions.Message("Adonis", "Teleporting to server \""..jobId.."\"\nPlease wait", {v}, false, 10)
						service.TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, v)
					end
				end
			end
		};

		AdminList = {
			Prefix = Settings.Prefix;
			Commands = {"admins", "adminlist", "headadmins", "owners", "moderators", "ranks"};
			Args = {};
			Hidden = false;
			Description = "Shows you the list of admins, also shows admins that are currently in the server";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local RANK_DESCRIPTION_FORMAT = "Rank: %s; Level: %d"
				local RANK_RICHTEXT = "<b><font color='rgb(77, 77, 255)'>%s (Level: %d)</font></b>"
				local RANK_TEXT_FORMAT = "%s [%s]"

				local temptable = {};
				local unsorted = {};

				table.insert(temptable, "<b><font color='rgb(60, 180, 0)'>==== Admins In-Game ====</font></b>")

				for i, v in ipairs(service.GetPlayers()) do
					local level, rankName = Admin.GetLevel(v);
					if level > 0 then
						table.insert(unsorted, {
							Text = string.format(RANK_TEXT_FORMAT, v.Name, (rankName or ("Level: ".. level)));
							Desc = string.format(RANK_DESCRIPTION_FORMAT, rankName or (level >= 1000 and "Place Owner") or "Unknown", level);
							SortLevel = level;
						})
					end
				end

				table.sort(unsorted, function(one, two)
					return one.SortLevel > two.SortLevel;
				end)

				for i, v in ipairs(unsorted) do
					v.SortLevel = nil;
					table.insert(temptable, v)
				end

				table.clear(unsorted)

				table.insert(temptable, "")
				table.insert(temptable, "<b><font color='rgb(180, 60, 0)'>==== All Admins ====</font></b>")

				for rank, data in pairs(Settings.Ranks) do
					if not data.Hidden then
						table.insert(unsorted, {
							Text = string.format(RANK_RICHTEXT, rank, data.Level);
							Desc = "";
							Level = data.Level;
							Users = data.Users;
							Rank = rank;
						});
					end
				end;

				table.sort(unsorted, function(one, two)
					return one.Level > two.Level;
				end)

				for _, v in ipairs(unsorted) do
					local Users = v.Users or {};
					local Level = v.Level or 0;
					local Rank = v.Rank or "Unknown";

					v.Users = nil;
					v.Level = nil;
					v.Rank = nil;

					table.insert(temptable, v)

					for _, user in ipairs(Users) do
						table.insert(temptable, {
							Text = "  ".. user;
							Desc = string.format(RANK_DESCRIPTION_FORMAT, Rank, Level);
							--SortLevel = data.Level;
						});
					end
				end

				return temptable
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Admin List";
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
			Hidden = false;
			Description = "Shows you the normal ban list";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local tab = {}
				local count = 0
				for _, v in pairs(Settings.Banned) do
					local entry = type(v) == "string" and v
					local reason = "No reason provided"
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
					end
					table.insert(tab, {Text = tostring(entry), Desc = reason})
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
				local startTime = os.time();

				local function voteUpdate()
					local results = {}
					local total = #responses
					local tab = {
						"Question: "..question;
						"Total Responses: "..total;
						"Didn't Vote: "..#players-total;
						"Time Left: ".. math.max(0, 120 - (os.time()-startTime));
					}

					for i, v in pairs(responses) do
						if not results[v] then results[v] = 0 end
						results[v] += 1
					end

					for i, v in pairs(anstab) do
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

				for i, v in pairs(players) do
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
				--[[
				if not answers then
					anstab = {"Yes", "No"}
				else
					for ans in answers:gmatch("([^,]+)") do
						table.insert(anstab, ans)
					end
				end

				local responses = {}
				local players = service.GetPlayers(plr, args[1])

				for i, v in pairs(players) do
					Routine(function()
						local response = Remote.GetGui(v, "Vote", {Question = question; Answers = anstab;})
						if response then
							table.insert(responses, response)
						end
					end)
				end

				local t = 0
				repeat wait(0.1) t=t+0.1 until t>=60 or #responses>=#players

				local results = {}

				for i, v in pairs(responses) do
					if not results[v] then results[v] = 0 end
					results[v] = results[v]+1
				end

				local total = #responses
				local tab = {
					"Question: "..question;
					"Total Responses: "..total;
					"Didn't Vote: "..#players-total;
				}
				for i, v in pairs(anstab) do
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
				Remote.MakeGui(plr, "List", {Title = "Results"; Tab = tab;})--]]
			end
		};

		ToolList = {
			Prefix = Settings.Prefix;
			Commands = {"tools", "toollist", "toolcenter", "savedtools", "addedtools"};
			Args = {};
			Hidden = false;
			Description = "Shows you a list of tools that can be obtained via the "..Settings.Prefix.."give command";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local data = {
					Tools = {};
					SavedTools = {};
					Prefix = Settings.Prefix;
					SplitKey = Settings.SplitKey;
					SpecialPrefix = Settings.SpecialPrefix;
				}
				for _, tool in ipairs(if Settings.RecursiveTools then Settings.Storage:GetDescendants() else Settings.Storage:GetChildren()) do
					if tool:IsA("BackpackItem") and not Variables.SavedTools[tool] then
						table.insert(data.Tools, tool.Name)
					end
				end
				for tool, pName in pairs(Variables.SavedTools) do
					table.insert(data.SavedTools, {ToolName = tool.Name, AddedBy = pName})
				end
				return data
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "ToolCenter", Logs.ListUpdaters.ToolList(plr))
			end
		};

		Piano = {
			Prefix = Settings.Prefix;
			Commands = {"piano"};
			Args = {"player"};
			Hidden = false;
			Description = "Gives you a playable keyboard piano. Credit to NickPatella.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
					local Dropper = v:FindFirstChildOfClass("PlayerGui") or v:FindFirstChildOfClass("Backpack")
					if Dropper then
						local piano = Deps.Assets.Piano:clone()
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
			Hidden = false;
			Description = "Shows you the script's available insert list";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local tab = {}
				for _, v in pairs(Variables.InsertList) do table.insert(tab, v) end
				for _, v in pairs(HTTP.Trello.InsertList) do table.insert(tab, v) end
				for i, v in pairs(tab) do
					tab[i] = {Text = v.Name; Desc = v.ID;}
				end
				Remote.MakeGui(plr, "List", {Title = "Insert List", Table = tab;})
			end
		};

		InsertClear = {
			Prefix = Settings.Prefix;
			Commands = {"insclear", "clearinserted", "clrins", "insclr"};
			Args = {};
			Hidden = false;
			Description = "Removes inserted objects";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(Variables.InsertedObjects) do
					v:Destroy()
					table.remove(Variables.InsertedObjects, i)
				end
			end
		};

		Clear = {
			Prefix = Settings.Prefix;
			Commands = {"clear", "cleargame", "clr"};
			Args = {};
			Hidden = false;
			Description = "Remove admin objects";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				service.StopLoop("ChickenSpam")
				for _, v in pairs(Variables.Objects) do
					if v.ClassName == "Script" or v.ClassName == "LocalScript" then
						v.Disabled = true
					end
					v:Destroy()
				end

				for i, v in pairs(Variables.Cameras) do
					if v then
						table.remove(Variables.Cameras, i)
						v:Destroy()
					end
				end

				for _, v in pairs(Variables.Jails) do
					if not v.Player or not v.Player.Parent then
						local ind = v.Index
						service.StopLoop(ind.."JAIL")
						Pcall(function() v.Jail:Destroy() end)
						Variables.Jails[ind] = nil
					end
				end

				for _, v in ipairs(workspace:GetChildren()) do
					if v.ClassName == "Message" or v.ClassName == "Hint" then
						v:Destroy()
					end

					if string.match(v.Name, "A_Probe (.*)") then
						v:Destroy()
					end
				end

				Variables.Objects = {}
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
				local tab = {}
				for _, v in pairs(objects) do
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
					local temp = {}
					for _, v in pairs(objects) do
						table.insert(temp, {
							Text = v:GetFullName();
							Desc = v.ClassName;
						})
					end
					return temp
				end
			end;
			Function = function(plr: Player, args: {string})
				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(plr, "List", {
						Title = v.Name .." Instances";
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
			Commands = {"clearguis", "clearmessages", "clearhints", "clrguis", "clrgui", "clearscriptguis", "removescriptguis"};
			Args = {"player", "deleteAll?"};
			Hidden = false;
			Description = "Remove script GUIs such as :m and :hint";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1] or "all")) do
					if string.lower(tostring(args[2])) == "yes" or string.lower(tostring(args[2])) == "true" then
						Routine(Remote.RemoveGui, v, true)
					else
						Routine(function()
							for _, gui in ipairs({"Message", "Hint", "Notification", "PM", "Output", "Effect", "Alert"}) do
								Remote.RemoveGui(v, gui)
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
			Hidden = false;
			Description = "Removes all screen UI effects such as Spooky, Clown, ScreenImage, ScreenVideo, etc.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1] or "all")) do
					Remote.RemoveGui(v, "Effect")
				end
			end
		};

		ResetLighting = {
			Prefix = Settings.Prefix;
			Commands = {"fix", "resetlighting", "undisco", "unflash", "fixlighting"};
			Args = {};
			Hidden = false;
			Description = "Reset lighting back to the setting it had on server start";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				service.StopLoop("LightingTask")
				for i, v in pairs(Variables.OriginalLightingSettings) do
					if i ~= "Sky" and service.Lighting[i] ~= nil then
						Functions.SetLighting(i, v)
					end
				end
				for i, v in ipairs(service.Lighting:GetChildren()) do
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
			Hidden = false;
			Description = "Sets the player's lighting to match the server's";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					for prop, val in pairs(Variables.LightingSettings) do
						Remote.SetLighting(v, prop, val)
					end
				end
			end
		};

		ResetStats = {
			Prefix = Settings.Prefix;
			Commands = {"resetstats", "rs"};
			Args = {"player"};
			Hidden = false;
			Description = "Sets target player(s)'s leader stats to 0";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, string.lower(args[1]))) do
					cPcall(function()
						if v and v:FindFirstChild("leaderstats") then
							for a, q in pairs(v.leaderstats:GetChildren()) do
								if q:IsA("IntValue") then q.Value = 0 end
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
			Hidden = false;
			Description = "Prompts the player(s) to buy the product belonging to the ID you supply";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					service.MarketPlace:PromptPurchase(v, tonumber(args[2]), false)
				end
			end
		};

		Capes = {
			Prefix = Settings.Prefix;
			Commands = {"capes", "capelist"};
			Args = {};
			Hidden = false;
			Description = "Shows you the list of capes for the cape command";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local list={}
				for i, v in pairs(Variables.Capes) do
					table.insert(list, v.Name)
				end
				Remote.MakeGui(plr, "List", {Title = "Cape List", Tab = list;})
			end
		};

		Cape = {
			Prefix = Settings.Prefix;
			Commands = {"cape", "givecape"};
			Args = {"player", "name/color", "material", "reflectance", "id"};
			Hidden = false;
			Description = "Gives the target player(s) the cape specified, do Settings.Prefixcapes to view a list of available capes ";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local color="White"
				if pcall(function() return BrickColor.new(args[2]) end) then color = args[2] end
				local mat = args[3] or "Fabric"
				local ref = args[4]
				local id = args[5]
				if args[2] and not args[3] then
					for k, cape in pairs(Variables.Capes) do
						if string.lower(args[2])==string.lower(cape.Name) then
							color = cape.Color
							mat = cape.Material
							ref = cape.Reflectance
							id = cape.ID
						end
					end
				end
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Functions.Cape(v, false, mat, color, id, ref)
				end
			end
		};

		UnCape = {
			Prefix = Settings.Prefix;
			Commands = {"uncape", "removecape"};
			Args = {"player"};
			Hidden = false;
			Description = "Removes the target player(s)'s cape";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Functions.UnCape(v)
				end
			end
		};

		NoClip = {
			Prefix = Settings.Prefix;
			Commands = {"noclip"};
			Args = {"player"};
			Hidden = false;
			Description = "NoClips the target player(s); allowing them to walk through walls";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local clipper = Deps.Assets.Clipper:Clone()
				clipper.Name = "ADONIS_NoClip"

				for i, p in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Flying noclip";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, p in pairs(service.GetPlayers(plr, args[1])) do
					Commands.Fly.Function(p, args, true)
				end
			end
		};

		Clip = {
			Prefix = Settings.Prefix;
			Commands = {"clip", "unnoclip"};
			Args = {"player"};
			Hidden = false;
			Description = "Un-NoClips the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, p in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Jails the target player(s), removing their tools until they are un-jailed; Specify a BrickColor to change the color of the jail bars";
			Fun = false;
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

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
							for _, k in ipairs(Backpack:GetChildren()) do
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
												for _, k in ipairs(Backpack:GetChildren()) do
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
			Hidden = false;
			Description = "UnJails the target player(s) and returns any tools that were taken from them while jailed";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local found = false

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local ind = tostring(v.UserId)
					local jail = Variables.Jails[ind]
					if jail then
						--service.StopLoop(ind.."JAIL")
						Pcall(function()
							for _, tool in pairs(jail.Tools) do
								tool.Parent = v.Backpack
							end
						end)
						Pcall(function() jail.Jail:Destroy() end)
						Variables.Jails[ind] = nil
						found = true
					end
				end

				if not found then
					for i, v in pairs(Variables.Jails) do
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
			Args = {"player", "color(red/green/blue/off)"};
			Description = "Gives the target player(s) a little chat gui, when used will let them chat using dialog bubbles";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local color = Enum.ChatColor.Red
				if string.lower(args[2])=="red" or not args[2] then
					color = Enum.ChatColor.Red
				elseif string.lower(args[2])=="green" then
					color = Enum.ChatColor.Green
				elseif string.lower(args[2])=="blue" then
					color = Enum.ChatColor.Blue
				elseif string.lower(args[2])=="off" then
					color = "off"
				end
				for i, v in ipairs(service.GetPlayers(plr,(args[1] or plr.Name))) do
					Remote.MakeGui(v, "BubbleChat", {Color = color;})
				end
			end
		};

		Track = {
			Prefix = Settings.Prefix;
			Commands = {"track", "trace", "find", "locate"};
			Args = {"player", "persistent? (default: false)"};
			Hidden = false;
			Description = "Shows you where the target player(s) is/are";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local persistent = args[2] and (args[2]:lower() == "true" or args[2]:lower() == "yes")
				if persistent and not Variables.TrackingTable[plr.Name] then
					Variables.TrackingTable[plr.Name] = {}
				end
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if persistent then
						Variables.TrackingTable[plr.Name][v] = true
					end
					local char = v.Character
					if char and plr.Character then
						task.defer(function()
							local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
							local part = char:FindFirstChild("HumanoidRootPart")
							local head = char:FindFirstChild("Head")
							if part and head and humanoid then
								local gui = service.New("BillboardGui", {
									Name = v.Name.."Tracker",
									Adornee = head,
									AlwaysOnTop = true,
									StudsOffset = Vector3.new(0, 2, 0),
									Size = UDim2.new(0, 100, 0, 40)
								})
								local beam = service.New("SelectionPartLasso", {
									Parent = gui,
									Part = part,
									Humanoid = humanoid,
									Color3 = v.TeamColor.Color,
								})
								local f = service.New("Frame", {
									Parent = gui;
									BackgroundTransparency = 1;
									Size = UDim2.new(1, 0, 1, 0);
								})
								local name = service.New("TextLabel", {
									Parent = f,
									Text = if v.Name == v.DisplayName then "@"..v.Name else v.DisplayName.."\n(@"..v.Name..")",
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
								arrow.Position = UDim2.new(0, 0, 0, 20)
								arrow.Text = "v"
								arrow.Parent = f

								Remote.MakeLocal(plr, gui, false)

								local teamChangeConn = v:GetPropertyChangedSignal("TeamColor"):Connect(function()
									if beam then beam.Color3 = v.TeamColor.Color end
								end)
								local event; event = v.CharacterRemoving:Connect(function()
									Remote.RemoveLocal(plr, v.Name.."Tracker")
									event:Disconnect()
									if teamChangeConn then teamChangeConn:Disconnect() end
								end)
							end
						end)
					end
				end
			end
		};

		UnTrack = {
			Prefix = Settings.Prefix;
			Commands = {"untrack", "untrace", "unfind", "unlocate", "notrack"};
			Args = {"player"};
			Hidden = false;
			Description = "Stops tracking the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[1] and args[1]:lower() == Settings.SpecialPrefix.."all" then
					Remote.RemoveLocal(plr, "Tracker", false, true)
					Variables.TrackingTable[plr.Name] = nil
				else
					for _, v in pairs(service.GetPlayers(plr, args[1])) do
						Remote.RemoveLocal(plr, v.Name.."Tracker")
						if Variables.TrackingTable[plr.Name] then
							Variables.TrackingTable[plr.Name][v] = nil
						end
					end
				end
			end
		};

		Phase = {
			Prefix = Settings.Prefix;
			Commands = {"phase"};
			Args = {"player"};
			Hidden = false;
			Description = "Makes the player(s) character completely local";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeLocal(v, v.Character)
				end
			end
		};

		UnPhase = {
			Prefix = Settings.Prefix;
			Commands = {"unphase"};
			Args = {"player"};
			Hidden = false;
			Description = "UnPhases the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MoveLocal(v, v.Character.Name, false, workspace)
					v.Character.Parent = workspace
				end
			end
		};

		GiveStarterPack = {
			Prefix = Settings.Prefix;
			Commands = {"startertools", "starttools"};
			Args = {"player"};
			Hidden = false;
			Description = "Gives the target player(s) tools that are in the game's StarterPack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local Backpack = v:FindFirstChildOfClass("Backpack")
					if Backpack then
						for a, q in ipairs(service.StarterPack:GetChildren()) do
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
			Hidden = false;
			Description = "Gives the target player(s) a sword";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local sword = service.Insert(125013769)
				local config = sword:FindFirstChild("Configurations")
				if config then
					config.CanTeamkill.Value = if args[2] and args[2]:lower() == "false" then false else true
				end
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local Backpack = v:FindFirstChildOfClass("Backpack")
					if Backpack then
						sword:Clone().Parent = Backpack
					end
				end
			end
		};

		Clone = {
			Prefix = Settings.Prefix;
			Commands = {"clone", "cloneplayer", "clonecharacter"};
			Args = {"player", "copies (max: 50)"};
			Hidden = false;
			Description = "Clones the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if tonumber(args[2]) and tonumber(args[2]) > 50 then
					error("Cannot make more than 50 clones.")
				end
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						local Character = v.Character
						local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

						if Humanoid then
							Character.Archivable = true
							for _ = 1, tonumber(args[2]) or 1 do
								local cl = Character:Clone()
								table.insert(Variables.Objects, cl)

								local animate
								local anim = cl:FindFirstChild("Animate")
								if anim then
									animate = Humanoid.RigType == Enum.HumanoidRigType.R15 and Deps.Assets.R15Animate:Clone() or Deps.Assets.R6Animate:Clone()
									animate:ClearAllChildren()
									for _, v in ipairs(anim:GetChildren()) do
										v.Parent = animate
									end
									anim:Destroy()

									animate.Parent = cl
								end

								if Character.PrimaryPart then
									cl:SetPrimaryPartCFrame(Character.PrimaryPart.CFrame)
								end
								if animate then
									animate.Disabled = false
								end
								cl:FindFirstChild("Humanoid").Died:Connect(function()
									cl:Destroy()
								end)

								cl.Archivable = false
								cl.Parent = workspace
							end
						end
					end)
				end
			end
		};

		CopyCharacter = {
			Prefix = Settings.Prefix;
			Commands = {"copychar", "copycharacter", "copyplayercharacter"};
			Args = {"player", "target"};
			Hidden = false;
			Description = "Changes specific players' character to the target's character. (i.g. To copy Player1's character, do ':copychar me Player1')";
			Fun = false;
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

				local target_humandescrip = target and target.Character:FindFirstChildOfClass("Humanoid") and target.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass"HumanoidDescription"

				assert(target_humandescrip, "Target player doesn't have a HumanoidDescription or has a locked HumanoidDescription [Cannot copy target's character]")

				target_humandescrip.Archivable = true
				target_humandescrip = target_humandescrip:Clone()

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						if (v and v.Character and v.Character:FindFirstChildOfClass("Humanoid")) and (target and target.Character and target.Character:FindFirstChildOfClass"Humanoid") then
							v.Character.Archivable = true

							for _, a in pairs(v.Character:GetChildren()) do
								if a:IsA("Accessory") then
									a:Destroy()
								end
							end

							local cl = target_humandescrip:Clone()
							cl.Parent = v.Character:FindFirstChildOfClass("Humanoid")
							pcall(function() v.Character:FindFirstChildOfClass("Humanoid"):ApplyDescription(cl) end)

							for _, a in pairs(target_character:GetChildren()) do
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
			Hidden = false;
			Description = "Gives you a tool that lets you click where you want the target player to stand, hold r to rotate them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local scr = Deps.Assets.ClickTeleport:Clone()
					scr.Mode.Value = "Teleport"
					scr.Target.Value = v.Name
					local tool = service.New("Tool")
					tool.CanBeDropped = false
					tool.RequiresHandle = false
					service.New("StringValue", tool).Name = Variables.CodeName
					scr.Parent = tool
					scr.Disabled = false
					tool.Parent = plr.Backpack
				end
			end
		};

		ClickWalk = {
			Prefix = Settings.Prefix;
			Commands = {"clickwalk", "cw", "ctw", "forcewalk", "walktool", "walktoclick", "clickcontrol", "forcewalk"};
			Args = {"player"};
			Hidden = false;
			Description = "Gives you a tool that lets you click where you want the target player to walk, hold r to rotate them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local scr = Deps.Assets.ClickTeleport:Clone()
					scr.Mode.Value = "Walk"
					scr.Target.Value = v.Name
					local tool = service.New("Tool")
					tool.CanBeDropped = false
					tool.RequiresHandle = false
					service.New("StringValue", tool).Name = Variables.CodeName
					scr.Parent = tool
					scr.Disabled = false
					tool.Parent = plr.Backpack
				end
			end
		};

		Control = {
			Prefix = Settings.Prefix;
			Commands = {"control", "takeover"};
			Args = {"player"};
			Hidden = false;
			Description = "Lets you take control of the target player";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
						for _, p in pairs(v.Character:GetChildren()) do
							if p:IsA("BasePart") then
								p.CanCollide = false
							end
						end
						for _, p in pairs(plr.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Refreshes the target player(s)'s character";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, p in ipairs(service.GetPlayers(plr, args[1])) do
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
							for _, child in ipairs(pBackpack:GetChildren()) do
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
							for _, t in ipairs(oTools) do
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
			Hidden = false;
			Description = "Kills the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Respawns the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Converts players' character to R6";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					task.defer(Functions.ConvertPlayerCharacterToRig, v, "R6")
				end
			end
		};

		R15 = {
			Prefix = Settings.Prefix;
			Commands = {"r15", "rthro"};
			Args = {"player"};
			Hidden = false;
			Description = "Converts players' character to R15";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Functions.ConvertPlayerCharacterToRig(v, "R15")
				end
			end
		};

		Stun = {
			Prefix = Settings.Prefix;
			Commands = {"stun"};
			Args = {"player"};
			Hidden = false;
			Description = "Stuns the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "UnStuns the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Forces the target player(s) to jump";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Forces the target player(s) to sit";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local Humanoid = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if Humanoid then
						Humanoid.Sit = true
					end
				end
			end
		};

		Invisible = {
			Prefix = Settings.Prefix;
			Commands = {"invisible", "invis"};
			Args = {"player"};
			Hidden = false;
			Description = "Makes the target player(s) invisible";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for a, obj in ipairs(v.Character:GetChildren()) do
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
			Commands = {"visible", "vis"};
			Args = {"player"};
			Hidden = false;
			Description = "Makes the target player(s) visible";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for a, obj in ipairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Locks the target player(s), preventing the use of btools on the character";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for a, obj in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "UnLocks the the target player(s), makes it so you can use btools on them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for a, obj in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Makes a PointLight on the target player(s) with the color specified";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local color = Functions.ParseColor3(args[2]) or BrickColor.new("Bright blue").Color

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "UnLights the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Change Ambient";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Argument 1 missing")

				local color = Functions.ParseColor3(args[1])
				assert(color, "Invalid color provided")

				if args[2] then
					for _, v in pairs(service.GetPlayers(plr, args[2])) do
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
			Hidden = false;
			Description = "Change OutdoorAmbient";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Argument 1 missing")
				
				local color = Functions.ParseColor3(args[1])
				assert(color, "Invalid color provided")

				if args[2] then
					for _, v in pairs(service.GetPlayers(plr, args[2])) do
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
			Hidden = false;
			Description = "Fog Off";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[1] then
					for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Determines if shadows are on or off";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if string.lower(args[1])=="on" or string.lower(args[1])=="true" then
					if args[2] then
						for _, v in pairs(service.GetPlayers(plr, args[2])) do
							Remote.SetLighting(v, "GlobalShadows", true)
						end
					else
						Functions.SetLighting("GlobalShadows", true)
					end
				elseif string.lower(args[1])=="off" or string.lower(args[1])=="false" then
					if args[2] then
						for _, v in pairs(service.GetPlayers(plr, args[2])) do
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
			Hidden = false;
			Description = "Change Brightness";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[2] then
					for _, v in pairs(service.GetPlayers(plr, args[2])) do
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
			Hidden = false;
			Description = "Change Time";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[2] then
					for _, v in pairs(service.GetPlayers(plr, args[2])) do
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
			Hidden = false;
			Description = "Fog Color";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Argument 1 missing")

				local color = Functions.ParseColor3(args[1])
				assert(color, "Invalid color provided")

				if args[2] then
					for _, v in pairs(service.GetPlayers(plr, args[2])) do
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
			Hidden = false;
			Description = "Fog Start/End";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if args[3] then
					for _, v in pairs(service.GetPlayers(plr, args[3])) do
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
			Hidden = false;
			Description = "Places the desired tool into the target player(s)'s StarterPack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local found = {}
				local temp = service.New("Folder")
				for _, tool in pairs(if Settings.RecursiveTools then Settings.Storage:GetDescendants() else Settings.Storage:GetChildren()) do
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
					for _, v in pairs(service.GetPlayers(plr, args[1])) do
						for k, t in pairs(found) do
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
			Hidden = false;
			Description = "Removes the desired tool from the target player(s)'s StarterPack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, string.lower(args[1]))) do
					local StarterGear = v:FindFirstChildOfClass("StarterGear")
					if StarterGear then
						for _, tool in ipairs(StarterGear:GetChildren()) do
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
			Hidden = false;
			Description = "Gives the target player(s) the desired tool(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local found = {}
				local temp = service.New("Folder")
				for _, tool in pairs(if Settings.RecursiveTools then Settings.Storage:GetDescendants() else Settings.Storage:GetChildren()) do
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
					for _, v in pairs(service.GetPlayers(plr, args[1])) do
						for k, t in pairs(found) do
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
			Hidden = false;
			Description = "Steals player1's tools and gives them to player2";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local victims = service.GetPlayers(plr, args[1])
				local stealers = service.GetPlayers(plr, args[2])
				for _, victim in pairs(victims) do
					local backpack = victim:FindFirstChildOfClass("Backpack")
					if not backpack then continue end
					task.defer(function()
						local hum = victim.Character and victim.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:UnequipTools() end
						for _, p in pairs(stealers) do
							local destination = p:FindFirstChildOfClass("Backpack")
							if not destination then continue end
							for _, tool in pairs(backpack:GetChildren()) do
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
			Hidden = false;
			Description = "Copies player1's tools and gives them to player2";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local p1 = service.GetPlayers(plr, args[1])
				local p2 = service.GetPlayers(plr, args[2])
				for _, v in pairs(p1) do
					local backpack = v:FindFirstChildOfClass("Backpack")
					if not backpack then continue end
					for _, m in pairs(p2) do
						for _, n in pairs(backpack:GetChildren()) do
							n:Clone().Parent = m:FindFirstChildOfClass("Backpack")
						end
					end
				end
			end
		};

		RemoveGuis = {
			Prefix = Settings.Prefix;
			Commands = {"removeguis", "noguis"};
			Args = {"player"};
			Hidden = false;
			Description = "Remove the target player(s)'s screen guis";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.LoadCode(v, [[for i, v in pairs(service.PlayerGui:GetChildren()) do if not client.Core.GetGui(v) then v:Destroy() end end]])
				end
			end
		};

		RemoveTools = {
			Prefix = Settings.Prefix;
			Commands = {"removetools", "notools", "rtools", "deltools"};
			Args = {"player"};
			Hidden = false;
			Description = "Remove the target player(s)'s tools";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local hum = v.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:UnequipTools() end
						for _, tool in pairs(v.Character:GetChildren()) do
							if tool:IsA("BackpackItem") then tool:Destroy() end
						end
					end
					local backpack = v:FindFirstChildOfClass("Backpack")
					if backpack then
						for _, tool in pairs(backpack:GetChildren()) do
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
			Hidden = false;
			Description = "Remove a specified tool from the target player(s)'s backpack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for _, tool in pairs(v.Character:GetChildren()) do
							if tool:IsA("BackpackItem") and string.sub(tool.Name:lower(), 1, #args[2])== args[2]:lower() then
								local hum = v.Character:FindFirstChildOfClass("Humanoid")
								if hum then hum:UnequipTools() end
								tool:Destroy()
							end
						end
					end
					local backpack = v:FindFirstChildOfClass("Backpack")
					if backpack then
						for _, tool in pairs(backpack:GetChildren()) do
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
			Hidden = false;
			Description = "Shows you what rank the target player(s) are in the specified group";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[2], "Argument #2 missing or nil")
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Removes <number> HP from the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Set the target player(s)'s health to <number>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Set the target player(s)'s jump power to <number>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Set the target player(s)'s jump height to <number>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Set the target player(s)'s WalkSpeed to <number>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.WalkSpeed = args[2] or 16
						if Settings.CommandFeedback then
							Remote.MakeGui(v, "Notification", {
								Title = "Notification";
								Message = "Character walk speed has been set to ".. (args[2] or 16);
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
			Hidden = false;
			Description = "Set the target player(s)'s team to <team>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing team name")
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					for a, tm in ipairs(service.Teams:GetChildren()) do
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
			Hidden = false;
			Description = "Randomize teams; :rteams or :rteams all or :rteams nonadmins team1,team2,etc";
			Fun = false;
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


				for i, team in ipairs(service.Teams:GetChildren()) do
					if #tArgs > 0 then
						for ind, check in pairs(tArgs) do
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
			Hidden = false;
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, player in ipairs(Functions.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Opens the teams manager GUI";
			Fun = false;
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
			Hidden = false;
			Description = "Set the target player(s)'s field of view to <number> (min 1, max 120)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2] and tonumber(args[2]), "Missing or invalid FOV number")
				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.LoadCode(v,[[workspace.CurrentCamera.FieldOfView=]].. math.clamp(tonumber(args[2]), 1, 120))
				end
			end
		};

		Place = {
			Prefix = Settings.Prefix;
			Commands = {"place"};
			Args = {"player", "placeID/serverName"};
			Hidden = false;
			NoStudio = true;
			Description = "Teleport the target player(s) to the place belonging to <placeID> or a reserved server";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local id = tonumber(args[2])
				local players = service.GetPlayers(plr, args[1])
				local servers = Core.GetData("PrivateServers") or {}
				local code = servers[args[2]]
				if code then
					for i, v in pairs(players) do
						Routine(function()
							local tp = Remote.MakeGuiGet(v, "Notification", {
								Title = "Teleport";
								Text = "Click to teleport to server "..args[2]..".";
								Time = 30;
								OnClick = Core.Bytecode("return true");
							})
							if tp then
								service.TeleportService:TeleportToPrivateServer(code.ID, code.Code, {v})
							end
						end)
					end
				elseif id then
					for i, v in pairs(players) do
						Remote.MakeGui(v, "Notification", {
							Title = "Teleport";
							Text = "Click to teleport to place "..args[2]..".";
							Time = 30;
							OnClick = Core.Bytecode("service.TeleportService:Teleport("..args[2]..")");
						})
					end
				else
					Functions.Hint("Invalid place ID/server name", {plr})
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
				local code = service.TeleportService:ReserveServer(place)
				local servers = Core.GetData("PrivateServers") or {}
				servers[args[1]] = {Code = code, ID = place}
				Core.SetData("PrivateServers", servers)
				Functions.Hint("Made server "..args[1].." | Place: "..place, {plr})
			end
		};

		DeleteServer = {
			Prefix = Settings.Prefix;
			Commands = {"delserver", "deleteserver", "removeserver", "rmserver"};
			Args = {"serverName"};
			Hidden = false;
			Description = "Deletes a private server from the list.";
			Fun = false;
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
			Hidden = false;
			Description = "Shows you a list of private servers that were created with :makeserver";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local servers = Core.GetData("PrivateServers") or {}
				local tab = {}
				for i, v in pairs(servers) do
					table.insert(tab, {Text = i, Desc = "Place: "..v.ID.." | Code: "..v.Code})
				end
				Remote.MakeGui(plr, "List", {Title = "Servers"; Table = tab;})
			end
		};

		GRPlaza = {
			Prefix = Settings.Prefix;
			Commands = {"grplaza", "grouprecruitingplaza", "groupplaza"};
			Args = {"player"};
			Hidden = false;
			Description = "Teleports the target player(s) to the Group Recruiting Plaza to look for potential group members";
			Fun = false;
			NoStudio = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Args = {"player1", "player2"};
			Hidden = false;
			Description = "Teleport player1(s) to player2, a waypoint, or specific coords, use :tp player1 waypoint-WAYPOINTNAME to use waypoints, x,y,z for coords";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if string.match(args[2], "^waypoint%-(.*)") or string.match(args[2], "wp%-(.*)") then
					local m = string.match(args[2], "^waypoint%-(.*)") or string.match(args[2], "wp%-(.*)")
					local point

					for i, v in pairs(Variables.Waypoints) do
						if string.sub(string.lower(i), 1, #m)==string.lower(m) then
							point=v
						end
					end

					for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
				elseif string.find(args[2], ",") then
					local x, y, z = string.match(args[2], "(.*),(.*),(.*)")
					for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
					local target = service.GetPlayers(plr, args[2])[1]
					local players = service.GetPlayers(plr, args[1])
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
							for k, n in pairs(players) do
								if n ~= target then
									local Character = n.Character
									if not Character then continue end
									if workspace.StreamingEnabled == true then
										n:RequestStreamAroundAsync((targ_root.CFrame*CFrame.Angles(0, math.rad(90/#players*k), 0)*CFrame.new(5+.2*#players, 0, 0))*CFrame.Angles(0, math.rad(90), 0).Position)
									end

									local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
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
			Commands = {"bring", "tptome"};
			Args = {"player"};
			Hidden = false;
			Description = "Teleport the target(s) to you";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					task.defer(Commands.Teleport.Function, plr, {v.Name, plr.Name})
				end
			end
		};

		To = {
			Prefix = Settings.Prefix;
			Commands = {"to", "tpmeto"};
			Args = {"player"};
			Hidden = false;
			Description = "Teleport you to the target";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					task.defer(Commands.Teleport.Function, plr, {plr.Name, v.Name})
				end
			end
		};

		MassBring = {
			Prefix = Settings.Prefix;
			Commands = {"massbring", "bringrows", "bringlines"};
			Args = {"player(s)", "lines (default: 3)"};
			Description = "Brings the target players and positions them evenly in specified lines";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(plr.Character, "Your character is missing.")
				local players = service.GetPlayers(plr, args[1])
				local lines = tonumber(args[2]) and math.clamp(tonumber(args[2]), 1, #players) or 3
				for l = 1, lines do
					local offsetX = 0
					if l == 1 then
						offsetX = 0
					elseif l % 2 == 1 then
						offsetX = -(math.ceil((l - 2)/2)*4)
					else
						offsetX = (math.ceil(l / 2))*4
					end
					for i = (l-1)*math.floor(#players/lines)+1, l*math.floor(#players/lines) do
						local player = players[i]
						if not player.Character then continue end
						player.Character:FindFirstChildOfClass("Humanoid").Jump = true
						task.wait()
						if player.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("HumanoidRootPart") then
							local offsetZ = ((i-1) - (l-1)*math.floor(#players/lines))*2
							player.Character.HumanoidRootPart.CFrame = (plr.Character.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(90),0)*CFrame.new(5+offsetZ,0,offsetX))*CFrame.Angles(0,math.rad(90),0)
						end
					end
				end
				if #players%lines ~= 0 then
					for i = lines*math.floor(#players/lines)+1, lines*math.floor(#players/lines) + #players%lines do
						local player = players[i]
						if not player.Character then continue end
						local r = i % (lines*math.floor(#players/lines))
						local offsetX = 0
						if r == 1 then
							offsetX = 0
						elseif r % 2 == 1 then
							offsetX = -(math.ceil((r - 2)/2)*4)
						else
							offsetX = (math.ceil(r / 2))*4
						end
						--[[if n.Character.Humanoid.Sit then
							n.Character.Humanoid.Sit = false
							wait(0.5)
						end]]
						player.Character:FindFirstChildOfClass("Humanoid").Jump = true
						task.wait()
						if player.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("HumanoidRootPart") then
							local offsetZ = (math.floor(#players/lines))*2
							player.Character.HumanoidRootPart.CFrame = (plr.Character.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(90),0)*CFrame.new(5+offsetZ,0,offsetX))*CFrame.Angles(0,math.rad(90),0)
						end
					end
				end
			end
		};

		Change = {
			Prefix = Settings.Prefix;
			Commands = {"change", "leaderstat", "stat"};
			Args = {"player", "stat", "value"};
			Filter = true;
			Description = "Change the target player(s)'s leader stat <stat> value to <value>";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v:FindFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:GetChildren()) do
							if string.find(string.lower(st.Name), string.lower(args[2])) == 1 then
								st.Value = args[3]
							end
						end
					end
				end
			end
		};

		AddToStat = {
			Prefix = Settings.Prefix;
			Commands = {"add", "addtostat", "addstat"};
			Args = {"player", "stat", "value"};
			Hidden = false;
			Description = "Add <value> to <stat>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v:FindFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:GetChildren()) do
							if string.find(string.lower(st.Name), string.lower(args[2])) == 1 and tonumber(st.Value) then
								st.Value = tonumber(st.Value)+tonumber(args[3])
							end
						end
					end
				end
			end
		};

		SubtractFromStat = {
			Prefix = Settings.Prefix;
			Commands = {"subtract", "minusfromstat", "minusstat", "subtractstat"};
			Args = {"player", "stat", "value"};
			Hidden = false;
			Description = "Subtract <value> from <stat>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v:FindFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:GetChildren()) do
							if string.find(string.lower(st.Name), string.lower(args[2])) == 1 and tonumber(st.Value) then
								st.Value = tonumber(st.Value)-tonumber(args[3])
							end
						end
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
				
				for _, v: Player in pairs(service.GetPlayers(plr, args[1])) do
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
						
						task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc)
					end
				end
			end
		};

		RemoveTShirt = {
			Prefix = Settings.Prefix;
			Commands = {"removetshirt", "untshirt", "notshirt"};
			Args = {"player"};
			Hidden = false;
			Description = "Remove any t-shirt(s) worn by the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
							humanoidDesc.GraphicTShirt = 0
							task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc)
						end
					end
				end
			end
		};

		RemoveShirt = {
			Prefix = Settings.Prefix;
			Commands = {"removeshirt", "unshirt", "noshirt"};
			Args = {"player"};
			Hidden = false;
			Description = "Remove any shirt(s) worn by the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				for _, v: Player in pairs(service.GetPlayers(plr, args[1])) do
					local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
						humanoidDesc.Shirt = 0
						task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc)
					end
				end
			end
		};
		
		RemovePants = {
			Prefix = Settings.Prefix;
			Commands = {"removepants"};
			Args = {"player"};
			Hidden = false;
			Description = "Remove any pants(s) worn by the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {[number]:string})
				for _, v: Player in pairs(service.GetPlayers(plr, args[1])) do
					local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()
						humanoidDesc.Pants = 0
						task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc)
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

				for i, v in pairs(Variables.MusicList) do
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
					for i, v in pairs(HTTP.Trello.Music) do
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


				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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

				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for i, v in ipairs(workspace:GetChildren()) do
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
				for i, v in ipairs(workspace:GetChildren()) do
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
				for i, v in ipairs(workspace:GetChildren()) do
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
				for i, v in ipairs(workspace:GetChildren()) do
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
			Hidden = false;
			Description = "Play a list of songs automatically; Stop with :shuffle off";
			Fun = false;
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
					s.Parent = workspace
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
			Hidden = false;
			Description = "Start playing a song";
			Fun = false;
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

					for i, v in pairs(Variables.MusicList) do
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

					for i, v in pairs(HTTP.Trello.Music) do
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

					for i, v in ipairs(workspace:GetChildren()) do
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
					s.Parent = workspace
					wait(0.5)
					s:Play()
				elseif id == "off" or id == "0" then
					for i, v in ipairs(workspace:GetChildren()) do
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
			Hidden = false;
			Description = "Stop the currently playing song";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in ipairs(workspace:GetChildren()) do
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
			Hidden = false;
			Description = "Shows you the script's available music list";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local listforclient={}
				for i, v in pairs(Variables.MusicList) do
					table.insert(listforclient, {Text=v.Name, Desc=v.ID})
				end
				for i, v in pairs(HTTP.Trello.Music) do
					table.insert(listforclient, {Text=v.Name, Desc=v.ID})
				end
				Remote.MakeGui(plr, "List", {Title = "Music List", Table = listforclient})
			end
		};

		Fly = {
			Prefix = Settings.Prefix;
			Commands = {"fly", "flight"};
			Args = {"player", "speed"};
			Hidden = false;
			Description = "Lets the target player(s) fly";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, noclip: boolean?)
				local speed = tonumber(args[2]) or 2
				local scr = Deps.Assets.Fly:Clone()
				local sVal = service.New("NumberValue", {
					Name = "Speed";
					Value = speed;
					Parent = scr;
				})
				local NoclipVal = service.New("BoolValue", {
					Name = "Noclip";
					Value = noclip or false;
					Parent = scr;
				})

				scr.Name = "ADONIS_FLIGHT"

				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
					local part = v.Character:FindFirstChild("HumanoidRootPart")
					if part then
						local oldp = part:FindFirstChild("ADONIS_FLIGHT_POSITION")
						local oldg = part:FindFirstChild("ADONIS_FLIGHT_GYRO")
						local olds = part:FindFirstChild("ADONIS_FLIGHT")
						if oldp then oldp:Destroy() end
						if oldg then oldg:Destroy() end
						if olds then olds:Destroy() end

						local new = scr:Clone()
						local flightPosition = service.New("BodyPosition")
						local flightGyro = service.New("BodyGyro")

						flightPosition.Name = "ADONIS_FLIGHT_POSITION"
						flightPosition.MaxForce = Vector3.new(0, 0, 0)
						flightPosition.Position = part.Position
						flightPosition.Parent = part

						flightGyro.Name = "ADONIS_FLIGHT_GYRO"
						flightGyro.MaxTorque = Vector3.new(0, 0, 0)
						flightGyro.CFrame = part.CFrame
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
			Hidden = false;
			Description = "Change the target player(s) flight speed";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local speed = tonumber(args[2])

				for i, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Removes the target player(s)'s ability to fly";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local part = v.Character:FindFirstChild("HumanoidRootPart")
					if part then
						local oldp = part:FindFirstChild("ADONIS_FLIGHT_POSITION")
						local oldg = part:FindFirstChild("ADONIS_FLIGHT_GYRO")
						local olds = part:FindFirstChild("ADONIS_FLIGHT")
						if oldp then oldp:Destroy() end
						if oldg then oldg:Destroy() end
						if olds then olds:Destroy() end
					end
				end
			end
		};

		Fling = {
			Prefix = Settings.Prefix;
			Commands = {"fling"};
			Args = {"player"};
			Hidden = false;
			Description = "Fling the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") then
							local xran local zran
							repeat xran = math.random(-9999, 9999) until math.abs(xran) >= 5555
							repeat zran = math.random(-9999, 9999) until math.abs(zran) >= 5555
							v.Character.Humanoid.Sit = true
							v.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
							local frc = service.New("BodyForce", v.Character.HumanoidRootPart)
							frc.Name = "BFRC"
							frc.force = Vector3.new(xran*4, 9999*5, zran*4)
							service.Debris:AddItem(frc,.1)
						end
					end)
				end
			end
		};

		SuperFling = {
			Prefix = Settings.Prefix;
			Commands = {"sfling", "tothemoon", "superfling"};
			Args = {"player", "optional strength"};
			Hidden = false;
			Description = "Super fling the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local strength = tonumber(args[2]) or 5e6
				local scr = Deps.Assets.Sfling:Clone()
				scr.Strength.Value = strength
				scr.Name = "SUPER_FLING"
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Filter = false;
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Put the target player(s)'s back to normal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("Head") then
						for a, mod in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Put the target player(s)'s back to normal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("Head") then
						for a, mod in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Removes the target player(s)'s Package";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local rigType = humanoid.RigType
							if rigType == Enum.HumanoidRigType.R6 then
								for _, x in pairs(v.Character:GetChildren()) do
									if x:IsA("CharacterMesh") then
										x:Destroy()
									end
								end
							elseif rigType == Enum.HumanoidRigType.R15 then
								local rig = Deps.Assets.RigR15
								local rigHumanoid = rig.Humanoid
								local validParts = {}
								for _, x in pairs(Enum.BodyPartR15:GetEnumItems()) do
									validParts[x.Name] = x.Value
								end
								for _, x in pairs(rig:GetChildren()) do
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
			Hidden = false;
			Description = "Gives the target player(s) the desired package (ID MUST BE A NUMBER)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1] and args[2] and tonumber(args[2]), "Missing player name")
				assert(args[1] and args[2] and tonumber(args[2]), "Missing or invalid package ID")

				local items = {}
				local id = tonumber(args[2])
				local assetHD = Variables.BundleCache[id]

				if assetHD == false then
					Remote.MakeGui(plr, "Output", {Title = "Output"; Message = "Package "..id.." is not supported."})
					return
				end

				if not assetHD then
					local suc,ers = pcall(function() return service.AssetService:GetBundleDetailsAsync(id) end)

					if suc then
						for _, item in pairs(ers.Items) do
							if item.Type == "UserOutfit" then
								local s, r = pcall(function() return service.Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
								Variables.BundleCache[id] = r
								assetHD = r
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

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local char = v.Character

					if char then
						local humanoid = char:FindFirstChildOfClass"Humanoid"

						if not humanoid then
							Functions.Hint("Could not transfer bundle to "..v.Name, {plr})
						else
							local newDescription = humanoid:GetAppliedDescription()
							local defaultDescription = Instance.new("HumanoidDescription")
							for _, property in ipairs({"BackAccessory", "BodyTypeScale", "ClimbAnimation", "DepthScale", "Face", "FaceAccessory", "FallAnimation", "FrontAccessory", "GraphicTShirt", "HairAccessory", "HatAccessory", "Head", "HeadColor", "HeadScale", "HeightScale", "IdleAnimation", "JumpAnimation", "LeftArm", "LeftArmColor", "LeftLeg", "LeftLegColor", "NeckAccessory", "Pants", "ProportionScale", "RightArm", "RightArmColor", "RightLeg", "RightLegColor", "RunAnimation", "Shirt", "ShouldersAccessory", "SwimAnimation", "Torso", "TorsoColor", "WaistAccessory", "WalkAnimation", "WidthScale"}) do
								if assetHD[property] ~= defaultDescription[property] then
									newDescription[property] = assetHD[property]
								end
							end

							humanoid:ApplyDescription(newDescription)
						end
					end
				end
			end
		};

		Char = {
			Prefix = Settings.Prefix;
			Commands = {"char", "character", "appearance"};
			Args = {"player", "username"};
			Hidden = false;
			Description = "Changes the target player(s)'s character appearence to <ID/Name>. If you want to supply a UserId, supply with 'userid-', followed by a number after 'userid'.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing username or UserId")

				local target = tonumber(string.match(args[2], "^userid%-(%d*)"))
				if not target then
					-- Grab id from name
					local success, id = pcall(service.Players.GetUserIdFromNameAsync, service.Players, args[2])
					if success then
						target = id
					else
						error("Unable to find target user")
					end
				end

				if target then
					local success, desc = pcall(service.Players.GetHumanoidDescriptionFromUserId, service.Players, target)

					if success then
						for _, v in pairs(service.GetPlayers(plr, args[1])) do
							v.CharacterAppearanceId = target

							if v.Character and v.Character:FindFirstChildOfClass("Humanoid") then
								v.Character.Humanoid:ApplyDescription(desc)
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
			Hidden = false;
			Description = "Put the target player(s)'s character appearence back to normal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						v.CharacterAppearanceId = v.UserId

						local Humanoid = v.Character and v.Character:FindFirstChildOfClass("Humanoid")

						if Humanoid then
							local success, desc = pcall(service.Players.GetHumanoidDescriptionFromUserId, service.Players, v.UserId)

							if success then
								Humanoid:ApplyDescription(desc)
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
			Hidden = false;
			Description = "Loop heals the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "UnLoop Heal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
				local temp = {}
				local function toTab(str, desc, color)
					for _, v in pairs(service.ExtractLines(str)) do
						table.insert(temp, {Text = v; Desc = desc..v; Color = color})
					end
				end
				for _, v in pairs(service.LogService:GetLogHistory()) do
					local mType = v.messageType
					toTab(v.message, (mType  == Enum.MessageType.MessageWarning and "Warning" or mType  == Enum.MessageType.MessageInfo and "Info" or mType  == Enum.MessageType.MessageError and "Error" or "Output").." - ", mType  == Enum.MessageType.MessageWarning and Color3.new(0.866667, 0.733333, 0.0509804) or mType == Enum.MessageType.MessageInfo and Color3.new(0.054902, 0.305882, 1) or mType == Enum.MessageType.MessageError and Color3.new(1, 0.196078, 0.054902))
				end
				return temp
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
				local temp = {"Player is currently unreachable"}
				if target and target.Parent then
					temp = Remote.Get(target, "ClientLog")
				end
				return temp
			end;
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(plr, "List", {
						Title = v.Name.." Local Log";
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
			Hidden = false;
			Description = "View script error log";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = function(plr: Player)
				local tab = {}
				for _, v in pairs(Logs.Errors) do
					table.insert(tab, {
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
			Hidden = false;
			Description = "View the exploit logs for the server OR a specific player";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = "Exploit";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Exploit Logs";
					Tab = Logs.Exploit;
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
			Hidden = false;
			Description = "Displays the current join logs for the server";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = "Joins";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Join Logs";
					Tab = Logs.Joins;
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
			Hidden = false;
			Description = "Displays the current leave logs for the server";
			Fun = false;
			AdminLevel = "Moderators";
			ListUpdater = "LeaveLogs";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Leave Logs";
					Tab = Logs.Leaves;
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
					Tab = Logs.Chats;
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
			Commands = {"remotelogs", "rlogs", "remotefires", "remoterequests"};
			Args = {"autoupdate? (default: false)"};
			Description = "View the remote logs for the server";
			AdminLevel = "Moderators";
			ListUpdater = "RemoteFires";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Remote Logs";
					Table = Logs.RemoteFires;
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
					Table = Logs.Script;
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
				local temp = {}
				for _, m in pairs(Logs.Commands) do
					table.insert(temp, {Time = m.Time; Text = m.Text..": "..m.Desc; Desc = m.Desc;})
				end
				return temp
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Admin Logs";
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
				local temp = {}
				if Core.DataStore then
					local data = Core.GetData("OldCommandLogs")
					if data then
						for i, m in pairs(data) do
							table.insert(temp, {Time = m.Time; Text = m.Text..": "..m.Desc; Desc = m.Desc;})
						end
					end
				end
				return temp
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Admin.RunCommandAsPlayer(str, v)
				end
			end
		};

		Mute = {
			Prefix = Settings.Prefix;
			Commands = {"mute", "silence"};
			Args = {"player"};
			Hidden = false;
			Description = "Makes it so the target player(s) can't talk";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string}, data: {})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if data.PlayerData.Level > Admin.GetLevel(v) then
						--Remote.LoadCode(v,[[service.StarterGui:SetCoreGuiEnabled("Chat", false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
						local check = true
						for _, m in pairs(Settings.Muted) do
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
			Hidden = false;
			Description = "Makes it so the target player(s) can talk again. No effect if on Trello mute list.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					for k, m in pairs(Settings.Muted) do
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
			Hidden = false;
			Description = "Shows a list of currently muted players";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local list = {}
				for _, v in pairs(Settings.Muted) do
					table.insert(list, v)
				end
				Remote.MakeGui(plr, "List", {Title = "Mute List"; Table = list;})
			end
		};

		Freecam = {
			Prefix = Settings.Prefix;
			Commands = {"freecam"};
			Args = {"player"};
			Hidden = false;
			Description = "Makes it so the target player(s)'s cam can move around freely (Press Space or Shift+P to toggle freecam)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "UnFreecam";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Toggles Freecam";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local plrgui = v:FindFirstChildOfClass("PlayerGui")
					local freecam = plrgui and plrgui:FindFirstChild("Freecam")
					if freecam then
						if freecam:FindFirstChildOfClass("RemoteFunction") then
							freecam:FindFirstChildOfClass("RemoteFunction"):InvokeClient(v, "Toggle")
						end
					end
				end
			end
		};

		Bots = {
			Prefix = Settings.Prefix;
			Commands = {"bot", "trainingbot"};
			Args = {"player", "num", "walk", "attack", "friendly", "health", "speed", "damage"};
			Hidden = false;
			Description = "AI bots made for training; ':bot scel 5 true true'";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local key = math.random()
				local num = tonumber(args[2]) or 1
				assert(num <= 50, "Cannot spawn more than 50 bots!")
				local health = tonumber(args[6]) or 100
				local speed = tonumber(args[7]) or 16
				local damage = tonumber(args[8]) or 5
				local walk = true
				local attack = false
				local friendly = false

				if args[3] == "false" then
					walk = true
				end

				if args[4] == "true" then
					attack = true
				end

				if args[5] == "true" then
					friendly = true
				end

				if num > 50 then
					num = 50
				end

				local function makeBot(player)
					local char = player.Character
					local torso = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
					local pos = torso.CFrame

					local clone
					char.Archivable = true
					clone = char:Clone()
					char.Archivable = false

					for i = 1, num do
						local new = clone:Clone()
						local hum = new:FindFirstChildOfClass("Humanoid")

						local brain = Deps.Assets.BotBrain:Clone()
						local event = brain.Event

						local oldAnim = new:FindFirstChild("Animate")
						local isR15 = hum.RigType == "R15"
						local anim = isR15 and Deps.Assets.R15Animate:Clone() or Deps.Assets.R6Animate:Clone()

						new.Name = player.Name
						new.HumanoidRootPart.CFrame = pos*CFrame.Angles(0, math.rad((360/num)*i), 0) * CFrame.new((num*0.2)+5, 0, 0)

						hum.WalkSpeed = speed
						hum.MaxHealth = health
						hum.Health = health

						if oldAnim then
							oldAnim:Destroy()
						end

						anim.Parent = new
						brain.Parent = new

						anim.Disabled = false
						brain.Disabled = false
						new.Parent = workspace

						wait()

						event:Fire("SetSetting", {
							Creator = player;
							Friendly = friendly;
							TeamColor = player.TeamColor;
							Attack = attack;
							Swarm = attack;
							Walk = walk;
							Damage = damage;
							Health = health;
							WalkSpeed = speed;
							SpecialKey = key;
						})

						if walk then
							event:Fire("Init")
						end

						table.insert(Variables.Objects, new)
					end
				end

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					makeBot(v)
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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

					Functions.Hint("Argument 1 missing or nil. Opening Reverb List", {plr})

					local tab = {}
					table.insert(tab, {Text = "Note: Argument is CASE SENSITIVE"})
					for _, v in pairs(reverbs) do
						table.insert(tab, {Text = v})
					end
					Remote.MakeGui(plr, "List", {Title = "Reverbs"; Table = tab;})

					return
				end

				if args[2] then
					for _, v in pairs(service.GetPlayers(plr, args[2])) do
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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
				local tab = {}
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
				for _, v in ipairs(perfStats) do
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
				local players = service.GetPlayers(plr, selection, {DontError = true; UseFakePlayer = false;})
				local tab = {
					"Specified: \""..(selection or (Settings.SpecialPrefix.."me")).."\"",
					"# Players: "..#players,
					"―――――――――――――――――――――――",
				}
				for _, v: Player in pairs(players) do
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

	}
end
