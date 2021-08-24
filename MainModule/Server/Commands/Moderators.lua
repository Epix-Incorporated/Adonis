return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		AudioPlayer = {
			Prefix = Settings.Prefix;
			Commands = {"audioplayer", "mediaplayer", "musicplayer", "soundplayer", "player", "ap"};
			Args = {"time";};
			Description = "Opens an audio player window";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _,v in ipairs(service.GetPlayers(plr, args[1], {
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
			Commands = {"kick";};
			Args = {"player";"optional reason";};
			Filter = true;
			Description = "Disconnects the target player from the server";
			AdminLevel = "Moderators";
			Function = function(plr, args, data)
				local plrLevel = data.PlayerData.Level
				for _,v in ipairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
				})) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel > targLevel then
						if not service.Players:FindFirstChild(v.Name) then
							Remote.Send(v, "Function", "Kill")
						else
							v:Kick(args[2])
						end
						Functions.Hint("Kicked "..tostring(v), {plr})
					end
				end
			end
		};

		ESP = {
			Prefix = Settings.Prefix;
			Commands = {"esp";};
			Args = {"target (optional)", "brickcolor (optional)"};
			Filter = true;
			Description = "Allows you to see <target> (or all humanoids if no target is supplied) through walls";
			AdminLevel = "Moderators";
			Function = function(plr, args, data)
				Remote.Send(plr, "Function", "CharacterESP", false)

				if args[1] then
					for _2,v2 in ipairs(service.GetPlayers(plr, args[1])) do
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
			Commands = {"unesp";};
			Args = {};
			Filter = true;
			Description = "Removes ESP";
			AdminLevel = "Moderators";
			Function = function(plr, args, data)
				Remote.Send(plr, "Function", "CharacterESP", false)
			end
		};

		Thru = {
			Prefix = Settings.Prefix;
			Commands = {"thru";"pass";"through"};
			Hidden = false;
			Args = {};
			Description = "Lets you pass through an object or a wall";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				Admin.RunCommand(Settings.Prefix.."tp", plr.Name, plr.Name)
			end
		};

		TimeDate = {
			Prefix = Settings.Prefix;
			Commands = {"timedate";"date";"datetime";};
			Args = {};
			Hidden = false;
			Description = "Shows you the current time and date.";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr, args)
				local ostime = os.time()
				local tab = {}
				table.insert(tab, {Text = "―――――――――――――――――――――――"})

				table.insert(tab, {Text = "Date: "..os.date("%x", ostime)})
				table.insert(tab, {Text = "Time: "..os.date("%H:%M | %I:%M %p", ostime)})
				table.insert(tab, {Text = "Timezone: "..os.date("%Z", ostime)})

				table.insert(tab, {Text = "―――――――――――――――――――――――"})


				table.insert(tab, {Text = "Minute: "..os.date("%M", ostime)})
				table.insert(tab, {Text = "Hour: "..os.date("%H | %I %p" ,ostime)})
				table.insert(tab, {Text = "Day: "..os.date("%d %A", ostime)})
				table.insert(tab, {Text = "Week (First sunday): "..os.date("%U", ostime)})
				table.insert(tab, {Text = "Week (First monday): "..os.date("%W", ostime)})
				table.insert(tab, {Text = "Month: "..os.date("%m %B", ostime)})
				table.insert(tab, {Text = "Year: "..os.date("%Y", ostime)})

				table.insert(tab, {Text = "―――――――――――――――――――――――"})

				table.insert(tab, {Text = "Day of the year: "..os.date("%j", ostime)})
				table.insert(tab, {Text = "Day of the month: "..os.date("%d", ostime)})

				table.insert(tab,{Text = "―――――――――――――――――――――――"})
				Remote.MakeGui(plr, "List", {
					Title = "Date",
					Table = tab,
					Update = 'DateTime',
					AutoUpdate = 59,
					Size = {270, 390};
				})
			end
		};

		TimeBanList = {
			Prefix = Settings.Prefix;
			Commands = {"timebanlist";"timebanned";"timebans";};
			Args = {};
			Description = "Shows you the list of time banned users";
			AdminLevel = "Moderators";
			Function = function(plr,args)
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

				Remote.MakeGui(plr, "List", {Title = 'Time Bans', Tab = tab})
			end
		};

		Notification = {
			Prefix = Settings.Prefix;
			Commands = {"notify","notification"};
			Args = {"player","message"};
			Description = "Sends the player a notification";
			Filter = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1] and args[2], "Argument missing or nil")

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(v ,"Notification", {
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
			Function = function(plr, args)
				local num = args[1] and tonumber(args[1]) --math.min(tonumber(args[1]),120)

				if num then
					Admin.SlowMode = num;
					Functions.Hint("Chat slow mode enabled (".. num .."s)", service.GetPlayers())
				else
					Admin.SlowMode = nil;
					Admin.SlowCache = {};
				end
			end
		};

		Countdown = {
			Prefix = Settings.Prefix;
			Commands = {"countdown", "timer", "cd"};
			Args = {"time";};
			Description = "Countdown";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local num = assert(tonumber(args[1]), "Argument 1 missing or not number")

				for _, v in ipairs(service.GetPlayers()) do
					Remote.MakeGui(v, "Countdown", {
						Time = num;
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
			Args = {"player";"time";};
			Description = "Countdown on a target player(s) screen.";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1] and args[2], "Argument missing or nil")
				local num = assert(tonumber(args[2]), "Argument 1 missing or not number")

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(v, "Countdown", {
						Time = num;
					})
				end
			end
		};

		HintCountdown = {
			Prefix = Settings.Prefix;
			Commands = {"hcountdown";"hc";};
			Args = {"time";};
			Description = "Hint Countdown";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local num = math.min(assert(tonumber(args[1]), "Argument 1 missing or not number"), 120)
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
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveGui(v, "Countdown")
				end
				service.StopLoop("HintCountdown")
			end
		};

		TimeMessage = {
			Prefix = Settings.Prefix;
			Commands = {"tm";"timem";"timedmessage";};
			Args = {"time";"message";};
			Filter = true;
			Description = "Make a message and makes it stay for the amount of time (in seconds) you supply";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1] and args[2] and tonumber(args[1]), "Argument missing or invalid")
				for _, v in ipairs(service.GetPlayers()) do
					Remote.RemoveGui(v, "Message")
					Remote.MakeGui(v, "Message", {
						Title = "Message from " .. plr.Name;
						Message = args[2];
						Time = tonumber(args[1]);
					})
				end
			end
		};

		Message = {
			Prefix = Settings.Prefix;
			Commands = {"m";"message";};
			Args = {"message";};
			Filter = true;
			Description = "Makes a message";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				for _, v in ipairs(service.GetPlayers()) do
					Remote.RemoveGui(v, "Message")
					Remote.MakeGui(v, "Message", {
						Title = "Message from " .. plr.Name;
						Message = args[1];--service.Filter(args[1],plr,v);
						Scroll = true;
						Time = (#tostring(args[1]) / 19) + 2.5;
					})
				end
			end
		};

		MessagePM = {
			Prefix = Settings.Prefix;
			Commands = {"mpm";"messagepm";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Makes a message on the target player(s) screen.";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1] and args[2], "Argument missing or nil")
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Functions.Message("Message from "..plr.Name, service.Filter(args[2], plr, v), {v})
				end
			end
		};

		Notify = {
			Prefix = Settings.Prefix;
			Commands = {"n","smallmessage","nmessage","nmsg","smsg","smessage"};
			Args = {"message";};
			Filter = true;
			Description = "Makes a small message";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				for _, v in ipairs(service.GetPlayers()) do
					Remote.RemoveGui(v, "Notify")
					Remote.MakeGui(v, "Notify", {
						Title = "Message from " .. plr.Name;
						Message = service.Filter(args[1], plr, v);
					})
				end
			end
		};


		SystemNotify = {
			Prefix = Settings.Prefix;
			Commands = {"sn","systemsmallmessage","snmessage","snmsg","ssmsg","ssmessage"};
			Args = {"message";};
			Filter = true;
			Description = "Makes a system small message,";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				for _, v in ipairs(service.GetPlayers()) do
					Remote.RemoveGui(v, "Notify")
					Remote.MakeGui(v, "Notify", {
						Title = Settings.SystemTitle;
						Message = service.Filter(args[1], plr, v);
					})
				end
			end
		};

		NotifyPM = {
			Prefix = Settings.Prefix;
			Commands = {"npm","smallmessagepm","nmessagepm","nmsgpm","npmmsg","smsgpm","spmmsg", "smessagepm"};
			Args = {"player";"message";};
			Filter = true;
			Description = "Makes a small message on the target player(s) screen.";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1] and args[2], "Argument missing or nil")
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveGui(v, "Notify")
					Remote.MakeGui(v, "Notify", {
						Title = "Message from " .. plr.Name;
						Message = service.Filter(args[2], plr, v);
					})
				end
			end
		};

		Hint = {
			Prefix = Settings.Prefix;
			Commands = {"h";"hint";};
			Args = {"message";};
			Filter = true;
			Description = "Makes a hint";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				for _, v in ipairs(service.GetPlayers()) do
					Remote.MakeGui(v, "Hint", {
						Message = tostring(plr or "")..": "..service.Filter(args[1], plr, v);
					})
				end
			end
		};

		Warn = {
			Prefix = Settings.Prefix;
			Commands = {"warn","warning"};
			Args = {"player","message";};
			Filter = true;
			Description = "Warns players";
			AdminLevel = "Moderators";
			Function = function(plr, args, data)
				assert(args[1] and args[2], "Argument missing or nil")
				local plrLevel = data.PlayerData.Level
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel > targLevel then
						local data = Core.GetPlayer(v)
						table.insert(data.Warnings, {From = tostring(plr), Message = args[2], Time = os.time()})
						Remote.RemoveGui(v, "Notify")
						Remote.MakeGui(v, "Notify", {
							Title = "Warning from "..tostring(plr);
							Message = args[2];
						})

						if plr and type(plr) == "userdata" then
							Remote.MakeGui(plr, "Hint", {
								Message = "Warned "..tostring(v);
							})
						end
					end
				end
			end
		};

		KickWarn = {
			Prefix = Settings.Prefix;
			Commands = {"kickwarn","kwarn","kickwarning"};
			Args = {"player","message";};
			Filter = true;
			Description = "Warns & kicks a player";
			AdminLevel = "Moderators";
			Function = function(plr, args, data)
				assert(args[1] and args[2], "Argument missing or nil")
				local plrLevel = data.PlayerData.Level
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel>targLevel then
						local data = Core.GetPlayer(v)

						table.insert(data.Warnings, {From = tostring(plr), Message = args[2], Time = os.time()})
						v:Kick(tostring("\n[Warning from "..tostring(plr).."]\n"..args[2]))

						if plr and type(plr) == "userdata" then
							Remote.MakeGui(plr, "Hint", {
								Message = "Warned "..tostring(v);
							})
						end
					end
				end
			end
		};

		ShowWarnings = {
			Prefix = Settings.Prefix;
			Commands = {"warnings","showwarnings"};
			Args = {"player"};
			Description = "Shows warnings a player has";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local data = Core.GetPlayer(v)
					local tab = {}

					if data.Warnings then
						for k, m in pairs(data.Warnings) do
							table.insert(tab,{Text = "["..k.."] "..m.Message,Desc = "[".. service.FormatTime(m.Time,true) .."] Given by: "..m.From.."; "..m.Message})
						end
					end

					Remote.MakeGui(plr, "List", {
						Title = v.Name;
						Table = tab;
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
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local data = Core.GetPlayer(v)
					data.Warnings = {}
					if plr and type(plr) == "userdata" then
						Remote.MakeGui(plr, "Hint", {
							Message = "Cleared warnings for "..tostring(v);
						})
					end
				end
			end
		};

		MakeTalk = {
			Prefix = Settings.Prefix;
			Commands = {"talk";"maketalk";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Makes a dialog bubble appear over the target player(s) head with the desired message";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local message = args[2]
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					service.ChatService:Chat(v.Character.Head, message, Enum.ChatColor.Blue)
				end
			end
		};

		ChatNotify = {
			Prefix = Settings.Prefix;
			Commands = {"chatnotify";"chatmsg";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Makes a message in the target player(s)'s chat window";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.Send(v, "Function", "ChatMessage", service.Filter(args[2], plr, v),Color3.new(1, 64/255, 77/255))
				end
			end
		};

		ForceField = {
			Prefix = Settings.Prefix;
			Commands = {"ff";"forcefield";};
			Args = {"player";};
			Description = "Gives a force field to the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then service.New("ForceField", v.Character) end
				end
			end
		};

		UnForcefield = {
			Prefix = Settings.Prefix;
			Commands = {"unff";"unforcefield";};
			Args = {"player";};
			Description = "Removes force fields on the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						if v.Character then
							for z, cl in ipairs(v.Character:GetChildren()) do if cl:IsA("ForceField") then cl:Destroy() end end
						end
					end)
				end
			end
		};

		Punish = {
			Prefix = Settings.Prefix;
			Commands = {"punish";};
			Args = {"player";};
			Description = "Removes the target player(s)'s character";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						v.Character.Parent = service.UnWrap(Settings.Storage);
					end
				end
			end
		};

		UnPunish = {
			Prefix = Settings.Prefix;
			Commands = {"unpunish";};
			Args = {"player";};
			Description = "UnPunishes the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					v.Character.Parent = service.Workspace
					v.Character:MakeJoints()
				end
			end
		};

		IceFreeze = {
			Prefix = Settings.Prefix;
			Commands = {"ice";"iceage","icefreeze","funfreeze"};
			Args = {"player";};
			Description = "Freezes the target player(s) in a block of ice";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							for _, obj in ipairs(v.Character:GetChildren()) do
								if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then obj.Anchored = true end
							end
							local ice = service.New("Part", v.Character)
							ice.BrickColor = BrickColor.new("Steel blue")
							ice.Material = "Ice"
							ice.Name = "Adonis_Ice"
							ice.Anchored = true
							--ice.CanCollide=false
							ice.TopSurface = "Smooth"
							ice.BottomSurface = "Smooth"
							ice.FormFactor = "Custom"
							ice.Size = Vector3.new(5, 6, 5)
							ice.Transparency = 0.3
							ice.CFrame = v.Character.HumanoidRootPart.CFrame
						end
					end)
				end
			end
		};

		Freeze = {
			Prefix = Settings.Prefix;
			Commands = {"freeze"};
			Args = {"player";};
			Description = "Freezes the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr, args)
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
			Commands = {"thaw";"unfreeze";"unice"};
			Args = {"player";};
			Description = "UnFreezes the target players, thaws them out";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							local ice = v.Character:FindFirstChild("Adonis_Ice")
							local plate
							if ice then
								plate = service.New("Part", v.Character)
								local mesh = service.New("CylinderMesh", plate)
								plate.FormFactor = "Custom"
								plate.TopSurface = "Smooth"
								plate.BottomSurface = "Smooth"
								plate.Size = Vector3.new(0.2, 0.2, 0.2)
								plate.BrickColor = BrickColor.new("Steel blue")
								plate.Name = "[EISS] Water"
								plate.Anchored = true
								plate.CanCollide = false
								plate.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0)
								plate.Transparency = ice.Transparency

								for i = 0.2, 3, 0.2 do
									ice.Size = Vector3.new(5, ice.Size.Y - i, 5)
									ice.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, -i, 0)
									plate.Size = Vector3.new(i + 5, 0.2, i + 5)
									wait()
								end
								ice:Destroy()
							end

							for a, obj in ipairs(v.Character:GetChildren()) do
								if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" and obj ~= plate then obj.Anchored = false end
							end
							wait(3)
							pcall(function() plate:Destroy() end)
						end
					end)
				end
			end
		};

		Fire = {
			Prefix = Settings.Prefix;
			Commands = {"fire";"makefire";"givefire";};
			Args = {"player";"color";};
			Description = "Sets the target player(s) on fire, coloring the fire based on what you server";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local color = Color3.new(1, 1, 1)
				local secondary = Color3.new(1, 0, 0)

				if args[2] then
					local str = BrickColor.new("Bright orange").Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
					secondary = str
				end

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso, "Fire", {
							Name = "FIRE";
							Color = color;
							SecondaryColor = secondary;
						})
						Functions.NewParticle(torso, "PointLight", {
							Name = "FIRE_LIGHT";
							Color = color;
							Range = 15;
							Brightness = 5;
						})
					end
				end
			end
		};

		UnFire = {
			Prefix = Settings.Prefix;
			Commands = {"unfire";"removefire";"extinguish";};
			Args = {"player";};
			Description = "Puts out the flames on the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "FIRE")
						Functions.RemoveParticle(torso, "FIRE_LIGHT")
					end
				end
			end
		};

		Smoke = {
			Prefix = Settings.Prefix;
			Commands = {"smoke";"givesmoke";};
			Args = {"player";"color";};
			Description = "Makes smoke come from the target player(s) with the desired color";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local color = Color3.new(1, 1, 1)

				if args[2] then
					local str = BrickColor.new("White").Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
				end

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso, "Smoke", {
							Name = "SMOKE";
							Color = color;
						})
					end
				end
			end
		};

		UnSmoke = {
			Prefix = Settings.Prefix;
			Commands = {"unsmoke";};
			Args = {"player";};
			Description = "Removes smoke from the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "SMOKE")
					end
				end
			end
		};

		Sparkles = {
			Prefix = Settings.Prefix;
			Commands = {"sparkles";};
			Args = {"player";"color";};
			Description = "Puts sparkles on the target player(s) with the desired color";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local color = Color3.new(1, 1, 1)

				if args[2] then
					local str = BrickColor.new('Cyan').Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
				end

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso, "Sparkles", {
							Name = "SPARKLES";
							SparkleColor = color;
						})
						Functions.NewParticle(torso, "PointLight", {
							Name = "SPARKLES_LIGHT";
							Color = color;
							Range = 15;
							Brightness = 5;
						})
					end
				end
			end
		};

		UnSparkles = {
			Prefix = Settings.Prefix;
			Commands = {"unsparkles";};
			Args = {"player";};
			Description = "Removes sparkles from the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "SPARKLES")
						Functions.RemoveParticle(torso, "SPARKLES_LIGHT")
					end
				end
			end
		};

		Animation = {
			Prefix = Settings.Prefix;
			Commands = {"animation";"loadanim";"animate";};
			Args = {"player";"animationID";};
			Description = "Load the animation onto the target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				if args[1] and not args[2] then args[2] = args[1] args[1] = nil end

				assert(tonumber(args[2]), tostring(args[2]).." is not a valid ID")

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Functions.PlayAnimation(v ,args[2])
				end
			end
		};

		AFK = {
			Prefix = Settings.Prefix;
			Commands = {"afk";};
			Args = {"player";};
			Description = "FFs, Gods, Names, Freezes, and removes the target player's tools until they jump.";
			AdminLevel = "Moderators";
			Function = function(plr, args)
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
							Admin.RunCommand(Settings.Prefix.."unname",v.Name)
							event:Disconnect()
						end)
						repeat torso.CFrame = pos wait() until not v or not v.Character or not torso or not running or not torso.Parent
					end)
				end
			end
		};

		Heal = {
			Prefix = Settings.Prefix;
			Commands = {"heal";};
			Args = {"player";};
			Hidden = false;
			Description = "Heals the target player(s) (Regens their health)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.Health = v.Character.Humanoid.MaxHealth
					end
				end
			end
		};

		God = {
			Prefix = Settings.Prefix;
			Commands = {"god";"immortal";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) immortal, makes their health so high that normal non-explosive weapons can't kill them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.MaxHealth = math.huge
						v.Character.Humanoid.Health = 9e9
					end
				end
			end
		};

		UnGod = {
			Prefix = Settings.Prefix;
			Commands = {"ungod";"mortal";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) mortal again";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.MaxHealth = 100
						v.Character.Humanoid.Health = v.Character.Humanoid.MaxHealth
					end
				end
			end
		};

		RemoveHats = {
			Prefix = Settings.Prefix;
			Commands = {"removehats";"nohats";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes any hats the target is currently wearing";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, p in ipairs(service.GetPlayers(plr, args[1])) do
					for _, v in ipairs(p.Character:GetChildren()) do
						if v:IsA("Accoutrement") then
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
			Function = function(plr, args)
				assert(args[1], "Argument missing")

				local sessionName = Functions.GetRandom(); --// Used by the private chat windows
				local newSession = Remote.NewSession("PrivateChat");
				local history = {};

				newSession.Data.History = history;

				local function getPeerList()
					local peers = {};

					for peer in next,newSession.Users do
						table.insert(peers, {
							Name = peer.Name;
							DisplayName = peer.DisplayName;
							UserId = peer.UserId;
							--Instance = service.UnWrap(peer);
						})
					end

					return peers;
				end

				local function systemMessage(msg)
					local data
					data = {
						Name = "*SYSTEM*";
						UserId = 0;
						Icon = 0;
					};

					table.insert(history, {
						Sender = data;
						Message = msg;
					});

					newSession:SendToUsers("PlayerSentMessage", data, msg);
				end;

				newSession:ConnectEvent(function(p, cmd, ...)
					local args = {...};

					if not p then -- System event(s)
						if cmd == "LastUserRemoved" then
							newSession:End();
						end
					else	-- Player event(s)
						if cmd == "SendMessage" then
							local gotIcon, status = service.Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
							local data, msg = {
								Name = p.Name;
								DisplayName = p.DisplayName;
								UserId = p.UserId;
								Icon = (status and gotIcon) or "rbxasset://textures/ui/GuiImagePlaceholder.png";
							}, service.LaxFilter(string.sub(args[1], 1, 140), p);

							table.insert(history, {
								Sender = data;
								Message = msg;
							})

							if #history > 200 then
								table.remove(history, 1)
							end

							newSession:SendToUsers("PlayerSentMessage", data, msg);
						elseif cmd == "LeaveSession" or cmd == "RemovedFromSession" then
							newSession:RemoveUser(p);

							systemMessage(string.format("<i>%s has left the session</i>", p.Name))
							newSession:SendToUsers("UpdatePeerList", getPeerList());

							if p == plr then
								systemMessage("<i>Session ended: Session owner left</i>");
								newSession:End();
							end
						elseif cmd == "EndSession" and p == plr then
							systemMessage("<i>Session ended</i>");

							newSession:End();
						elseif cmd == "AddPlayerToSession" and (p == plr or Admin.CheckAdmin(p)) then
							local player = args[1];

							if player then
								newSession:AddUser(player);
								newSession:SendToUser(player, "AddedToSession");

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
								for pr in next,newSession.Users do
									if peer.UserId and peer.UserId == pr.UserId then
										newSession:SendToUser(pr, "RemovedFromSession");
										newSession:RemoveUser(pr)
										systemMessage(string.format("<i>%s removed %s from the session</i>", p.Name, pr.Name))
									end
								end
							end

							newSession:SendToUsers("UpdatePeerList", getPeerList());
						elseif cmd == "GetPeerList" then
							newSession:SendToUser(p, "UpdatePeerList", getPeerList());
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
						Icon = (status and gotIcon) or "rbxasset://textures/ui/GuiImagePlaceholder.png";
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

				for i,v in ipairs(service.GetPlayers(plr, args[1])) do
					if v ~= plr then
						newSession:AddUser(v);

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
			Commands = {"pm";"privatemessage";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Send a private message to a player";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1] and args[2], "Argument missing")
				if Admin.CheckAdmin(plr) then
					for _, v in ipairs(service.GetPlayers(plr, args[1])) do
						Variables.AuthorizedToReply[v] = true;
						Remote.MakeGui(v, "PrivateMessage", {
							Title = "Message from "..plr.Name;
							Player = plr;
							Message = service.Filter(args[2], plr, v);
						})
					end
				end
			end
		};--]]

		ShowChat = {
			Prefix = Settings.Prefix;
			Commands = {"chat","customchat"};
			Args = {"player"};
			Description = "Opens the custom chat GUI";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(v, "Chat");
				end
			end
		};

		RemoveChat = {
			Prefix = Settings.Prefix;
			Commands = {"unchat","uncustomchat"};
			Args = {"player"};
			Description = "Opens the custom chat GUI";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveGui(v, "Chat")
				end
			end
		};

		BlurEffect = {
			Prefix = Settings.Prefix;
			Commands = {"blur";"screenblur";"blureffect"};
			Args = {"player";"blur size";};
			Description = "Blur the target player's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local moder = tonumber(args[2]) or 0.5
				if moder > 5 then moder = 5 end
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(v, "BlurEffect", {
						Name = "WINDOW_BLUR",
						Size = tonumber(args[2]) or 24,
						Enabled = true,
					}, "Camera")
				end
			end
		};

		BloomEffect = {
			Prefix = Settings.Prefix;
			Commands = {"bloom";"screenbloom";"bloomeffect"};
			Args = {"player";"intensity";"size";"threshold"};
			Description = "Give the player's screen the bloom lighting effect";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(v, "BloomEffect", {
						Name = "WINDOW_BLOOM",
						Intensity = tonumber(args[2]) or 0.4,
						Size = tonumber(args[3]) or 24,
						Threshold = tonumber(args[4]) or 0.95,
						Enabled = true,
					}, "Camera")
				end
			end
		};

		SunRaysEffect = {
			Prefix = Settings.Prefix;
			Commands = {"sunrays";"screensunrays";"sunrayseffect"};
			Args = {"player";"intensity";"spread"};
			Description = "Give the player's screen the sunrays lighting effect";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(v, "SunRaysEffect", {
						Name = "WINDOW_SUNRAYS",
						Intensity = tonumber(args[2]) or 0.25,
						Spread = tonumber(args[3]) or 1,
						Enabled = true,
					}, "Camera")
				end
			end
		};

		ColorCorrectionEffect = {
			Prefix = Settings.Prefix;
			Commands = {"colorcorrect";"colorcorrection";"correctioneffect";"correction";"cce"};
			Args = {"player";"brightness","contrast","saturation","tint"};
			Description = "Give the player's screen the sunrays lighting effect";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local r,g,b = 1,1,1
				if args[5] and args[5]:match("(.*),(.*),(.*)") then
					r,g,b = args[5]:match("(.*),(.*),(.*)")
				end
				r,g,b = tonumber(r),tonumber(g),tonumber(b)
				if not r or not g or not b then error("Invalid Input") end
				for _, p in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(p,"ColorCorrectionEffect",{
						Name = "WINDOW_COLORCORRECTION",
						Brightness = tonumber(args[2]) or 0,
						Contrast = tonumber(args[3]) or 0,
						Saturation = tonumber(args[4]) or 0,
						TintColor = Color3.new(r,g,b),
						Enabled = true,
					},"Camera")
				end
			end
		};

		UnColorCorrection = {
			Prefix = Settings.Prefix;
			Commands = {"uncolorcorrection";"uncorrection";"uncolorcorrectioneffect"};
			Args = {"player";};
			Hidden = false;
			Description = "UnColorCorrection the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(p, "WINDOW_COLORCORRECTION", "Camera")
				end
			end
		};

		UnSunRays = {
			Prefix = Settings.Prefix;
			Commands = {"unsunrays"};
			Args = {"player";};
			Hidden = false;
			Description = "UnSunrays the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_SUNRAYS", "Camera")
				end
			end
		};

		UnBloom = {
			Prefix = Settings.Prefix;
			Commands = {"unbloom";"unscreenbloom";};
			Args = {"player";};
			Hidden = false;
			Description = "UnBloom the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_BLOOM", "Camera")
				end
			end
		};

		UnBlur = {
			Prefix = Settings.Prefix;
			Commands = {"unblur";"unscreenblur";};
			Args = {"player";};
			Hidden = false;
			Description = "UnBlur the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_BLUR", "Camera")
				end
			end
		};

		UnLightingEffect = {
			Prefix = Settings.Prefix;
			Commands = {"unlightingeffect";"unscreeneffect";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove admin made lighting effects from the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_BLUR", "Camera")
					Remote.RemoveLocal(v, "WINDOW_BLOOM", "Camera")
					Remote.RemoveLocal(v, "WINDOW_THERMAL", "Camera")
					Remote.RemoveLocal(v, "WINDOW_SUNRAYS", "Camera")
					Remote.RemoveLocal(v, "WINDOW_COLORCORRECTION", "Camera")
				end
			end
		};

		ThermalVision = {
			Prefix = Settings.Prefix;
			Commands = {"thermal","thermalvision","heatvision"};
			Args = {"player"};
			Hidden = false;
			Description = "Looks like heat vision";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(v, "ColorCorrectionEffect", {
						Name = "WINDOW_THERMAL",
						Brightness = 1,
						Contrast = 20,
						Saturation = 20,
						TintColor = Color3.new(0.5, 0.2, 1);
						Enabled = true,
					}, "Camera")
					Remote.NewLocal(v, "BlurEffect", {
						Name = "WINDOW_THERMAL",
						Size = 24,
						Enabled = true,
					}, "Camera")
				end
			end
		};

		UnThermalVision = {
			Prefix = Settings.Prefix;
			Commands = {"unthermal";"unthermalvision";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the thermal effect from the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_THERMAL", "Camera")
				end
			end
		};

		ShowSBL = {
			Prefix = Settings.Prefix;
			Commands = {"sbl";"syncedbanlist";"globalbanlist";"trellobans";"trellobanlist";};
			Args = {};
			Hidden = false;
			Description = "Shows Trello bans";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				Remote.MakeGui(plr ,"List", {
					Title = "Synced Ban List";
					Tab = HTTP.Trello.Bans;
				})
			end
		};

		HandTo = {
			Prefix = Settings.Prefix;
			Commands = {"handto";};
			Args = {"player";};
			Hidden = false;
			Description = "Hands an item to a player";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
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
			Commands = {"showtools";"viewtools";"seebackpack";"viewbackpack";"showbackpack";"displaybackpack";"displaytools";};
			Args = {"player";};
			Hidden = false;
			Description = "Shows you a list of items currently in the target player(s) backpack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						local tools = {}
						table.insert(tools,{Text="==== "..v.Name.."'s Tools ====",Desc=v.Name:lower()})
						for k,t in pairs(v.Backpack:GetChildren()) do
							if t:IsA("Tool") then
								table.insert(tools,{Text=t.Name,Desc="Class: "..t.ClassName.." | ToolTip: "..t.ToolTip.." | Name: "..t.Name})
							elseif t:IsA("HopperBin") then
								table.insert(tools,{Text=t.Name,Desc="Class: "..t.ClassName.." | BinType: "..tostring(t.BinType).." | Name: "..t.Name})
							else
								table.insert(tools,{Text=t.Name,Desc="Class: "..t.ClassName.." | Name: "..t.Name})
							end
						end
						Remote.MakeGui(plr,"List",{Title = v.Name,Tab = tools})
					end)
				end
			end
		};

		PlayerList = {
			Prefix = Settings.Prefix;
			Commands = {"players","playerlist"};
			Args = {"autoupdate"};
			Hidden = false;
			Description = "Shows you all players currently in-game, including nil ones";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local plrs = {}
				local playz = Functions.GrabNilPlayers('all')
				local update = (args[1] ~= "false")

				Functions.Hint('Pinging players. Please wait. No ping = Ping > 5sec.',{plr})

				for i,v in pairs(playz) do
					if type(v) == "string" and v == "NoPlayer" then
						table.insert(plrs,{Text="PLAYERLESS CLIENT",Desc="PLAYERLESS SERVERREPLICATOR. COULD BE LOADING/LAG/EXPLOITER. CHECK AGAIN IN A MINUTE!"})
					else
						local ping = "..."

						if v and service.Players:FindFirstChild(v.Name) then
							local h = ""
							local mh = ""
							local ws = ""
							local jp = ""
							local hn = ""
							local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")

							if v.Character and hum then
								h = hum.Health
								mh = hum.MaxHealth
								ws = hum.WalkSpeed
								jp = hum.JumpPower
								hn = hum.Name
							else
								h = "NO CHARACTER/HUMANOID"
							end

							table.insert(plrs,{Text = "["..ping.."] "..v.Name.. " (".. v.DisplayName ..")", Desc = 'Lower: '..v.Name:lower()..' - Health: '..h..((not hum and "") or " - MaxHealth: "..mh.." - WalkSpeed: "..ws.." - JumpPower: "..jp.." - Humanoid Name: "..hum.Name)})
						else
							table.insert(plrs,{Text = '[LOADING] '..v.Name, Desc = 'Lower: '..v.Name:lower()..' - Ping: '..ping})
						end
					end
				end

				Remote.MakeGui(plr,'List',{
					Title = 'Players',
					Tab = plrs,
					AutoUpdate = update and 1;
					Update = "PlayerList";
					UpdateArgs = {};
				})
			end
		};

		Waypoint = {
			Prefix = Settings.Prefix;
			Commands = {"waypoint";"wp";"checkpoint";};
			Args = {"name";};
			Filter = true;
			Description = "Makes a new waypoint/sets an exiting one to your current position with the name <name> that you can teleport to using :tp me waypoint-<name>";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local name=args[1] or tostring(#Variables.Waypoints+1)
				if plr.Character:FindFirstChild('HumanoidRootPart') then
					Variables.Waypoints[name] = plr.Character.HumanoidRootPart.Position
					Functions.Hint('Made waypoint '..name..' | '..tostring(Variables.Waypoints[name]),{plr})
				end
			end
		};

		DeleteWaypoint = {
			Prefix = Settings.Prefix;
			Commands = {"delwaypoint";"delwp";"delcheckpoint";"deletewaypoint";"deletewp";"deletecheckpoint";};
			Args = {"name";};
			Hidden = false;
			Description = "Deletes the waypoint named <name> if it exist";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(Variables.Waypoints) do
					if i:lower():sub(1,#args[1])==args[1]:lower() or args[1]:lower()=='all' then
						Variables.Waypoints[i]=nil
						Functions.Hint('Deleted waypoint '..i,{plr})
					end
				end
			end
		};

		Waypoints = {
			Prefix = Settings.Prefix;
			Commands = {"waypoints";};
			Args = {};
			Hidden = false;
			Description = "Shows available waypoints, mouse over their names to view their coordinates";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temp={}
				for i,v in pairs(Variables.Waypoints) do
					local x,y,z=tostring(v):match('(.*),(.*),(.*)')
					table.insert(temp,{Text=i,Desc='X:'..x..' Y:'..y..' Z:'..z})
				end
				Remote.MakeGui(plr,"List",{Title = 'Waypoints', Tab = temp})
			end
		};

		Cameras = {
			Prefix = Settings.Prefix;
			Commands = {"cameras";"cams";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of admin cameras";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local tab = {}
				for i,v in pairs(Variables.Cameras) do
					table.insert(tab,{Text = v.Name,Desc = "Pos: "..tostring(v.Brick.Position)})
				end
				Remote.MakeGui(plr,"List",{Title = "Cameras", Tab = tab})
			end
		};

		MakeCamera = {
			Prefix = Settings.Prefix;
			Commands = {"makecam";"makecamera";"camera";};
			Args = {"name";};
			Filter = true;
			Description = "Makes a camera named whatever you pick";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if plr and plr.Character and plr.Character:FindFirstChild('Head') then
					if service.Workspace:FindFirstChild('Camera: '..args[1]) then
						Functions.Hint(args[1].." Already Exists!",{plr})
					else
						local cam = service.New('Part',service.Workspace)
						cam.Position = plr.Character.Head.Position
						cam.Anchored = true
						cam.BrickColor = BrickColor.new('Really black')
						cam.CanCollide = false
						cam.Locked = true
						cam.FormFactor = 'Custom'
						cam.Size = Vector3.new(1,1,1)
						cam.TopSurface = 'Smooth'
						cam.BottomSurface = 'Smooth'
						cam.Name='Camera: '..args[1]
						--service.New('PointLight',cam)
						cam.Transparency=1--.9
						local mesh=service.New('SpecialMesh',cam)
						mesh.Scale=Vector3.new(1,1,1)
						mesh.MeshType='Sphere'
						table.insert(Variables.Cameras,{Brick = cam, Name = args[1]})
					end
				end
			end
		};

		ViewCamera = {
			Prefix = Settings.Prefix;
			Commands = {"viewcam","viewc","camview","watchcam","cam"};
			Args = {"camera";};
			Description = "Makes you view the target player";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(Variables.Cameras) do
					if v.Name:sub(1,#args[1]) == args[1] then
						Remote.Send(plr,'Function','SetView',v.Brick)
					end
				end
			end
		};

		ForceView = {
			Prefix = Settings.Prefix;
			Commands = {"fview";"forceview";"forceviewplayer";"fv";};
			Args = {"player1";"player2";};
			Description = "Forces one player to view another";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for k,p in pairs(service.GetPlayers(plr, args[1])) do
					for i,v in pairs(service.GetPlayers(plr, args[2])) do
						if v and v.Character:FindFirstChild('Humanoid') then
							Remote.Send(p,'Function','SetView',v.Character.Humanoid)
						end
					end
				end
			end
		};

		View = {
			Prefix = Settings.Prefix;
			Commands = {"view";"watch";"nsa";"viewplayer";};
			Args = {"player";};
			Description = "Makes you view the target player";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character:FindFirstChild('Humanoid') then
						Remote.Send(plr,'Function','SetView',v.Character.Humanoid)
					end
				end
			end
		};

		--[[Viewport = {
			Prefix = Settings.Prefix;
			Commands = {"viewport", "cctv"};
			Args = {"player";};
			Description = "Makes a viewport of the target player<s>";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character:FindFirstChild('Humanoid') then
						Remote.MakeGui(plr, "Viewport", {Subject = v.Character.HumanoidRootPart});
					end
				end
			end
		};--]]

		ResetView = {
			Prefix = Settings.Prefix;
			Commands = {"resetview";"rv";"fixview";"fixcam";"unwatch";"unview"};
			Args = {"optional player"};
			Description = "Resets your view";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1] then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						Remote.Send(v,'Function','SetView','reset')
					end
				else
					Remote.Send(plr,'Function','SetView','reset')
				end
			end
		};

		GuiView = {
			Prefix = Settings.Prefix;
			Commands = {"guiview";"showguis";"viewguis"};
			Args = {"player"};
			Description = "Shows you the player's character and any guis in their PlayerGui folder [May take a minute]";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local p
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					p = v
				end
				if p then
					Functions.Hint("Loading GUIs",{plr})
					local guis,rlocked = Remote.Get(p,"Function","GetGuiData")
					if rlocked then
						Functions.Hint("ROBLOXLOCKED GUI FOUND! CANNOT DISPLAY!",{plr})
					end
					if guis then
						Remote.Send(plr,"Function","LoadGuiData",guis)
					end
				end
			end;
		};

		UnGuiView = {
			Prefix = Settings.Prefix;
			Commands = {"unguiview","unshowguis","unviewguis"};
			Args = {};
			Description = "Removes the viewed player's GUIs";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				Remote.Send(plr,"Function","UnLoadGuiData")
			end;
		};

		ServerDetails = {
			Prefix = Settings.Prefix;
			Commands = {"serverinfo";"serverdetails";"gameinfo";"gamedetails";};
			Args = {};
			Description = "Opens the server information window";
			Hidden = false;
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local adminDictionary = {}
				for i,v in pairs(service.GetPlayers()) do
					local level, rank = Admin.GetLevel(v);
					if level > 0 then
						adminDictionary[v.Name] = rank or "Uknown"
					end
				end

				local donorList = {}
				for i,v in pairs(service.GetPlayers()) do
					if service.MarketPlace:UserOwnsGamePassAsync(v.UserId, Variables.DonorPass[1]) then
						table.insert(donorList, v.Name)
					end
				end

				local nilPlayers = 0
				for i,v in pairs(service.NetworkServer:GetChildren()) do
					if v and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
						nilPlayers = nilPlayers + 1
					end
				end

				local s, r = pcall(service.HttpService.GetAsync, service.HttpService, "http://ip-api.com/json")
				if s then
					r = service.HttpService:JSONDecode(r)
				end

				local serverInfo = s and {
					country = r.country,
					city = r.city,
					region = r.region,
					zipcode = r.zip,
					timezone = r.timezone,
					query = r.query,
					coords = r.lat .. " LAT ".. r.lon .. " LON"
				} or nil

				Remote.MakeGui(plr,"ServerDetails",{
					CreatorId = game.CreatorId;
					PrivateServerId = game.PrivateServerId;
					PrivateServerOwnerId = game.PrivateServerOwnerId;
					ServerStartTime = service.FormatTime(server.ServerStartTime);
					ServerAge = service.FormatTime(os.time()-server.ServerStartTime);
					HttpEnabled = HTTP.CheckHttp();
					ServerInternetInfo = serverInfo;
					LoadstringEnabled = HTTP.LoadstringEnabled;
					Admins = adminDictionary;
					Donors = donorList;
					ObjectCount = #Variables.Objects;
					CameraCount = #Variables.Cameras;
					NilPlayerCount = nilPlayers;
				})
			end
		};

		Clean = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"clean";};
			Args = {};
			Hidden = false;
			Description = "Cleans some useless junk out of service.Workspace";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				Functions.CleanWorkspace()
			end
		};

		Repeat = {
			Prefix = Settings.Prefix;
			Commands = {"repeat";"loop";};
			Args = {"amount";"interval";"command";};
			Description = "Repeats <command> for <amount> of times every <interval> seconds; Amount cannot exceed 50";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local amount = tonumber(args[1])
				local timer = tonumber(args[2])
				if timer<=0 then timer=0.1 end
				if amount>50 then amount=50 end
				local command = args[3]
				local name = plr.Name:lower()
				assert(command, "Argument #1 needs to be supplied")
				if command:sub(1,#Settings.Prefix+string.len("repeat")):lower() == string.lower(Settings.Prefix.."repeat") or command:sub(1,#Settings.Prefix+string.len("loop")) == string.lower(Settings.Prefix.."loop") or command:find("^"..Settings.Prefix.."loop") or command:find("^"..Settings.Prefix.."repeat") then
					error("Cannot repeat the loop command in a loop command")
					return
				end

				Variables.CommandLoops[name..command] = true
				Functions.Hint("Running "..command.." "..amount.." times every "..timer.." seconds.",{plr})
				for i = 1,amount do
					if not Variables.CommandLoops[name..command] then break end
					Process.Command(plr,command,{Check = false;})
					wait(timer)
				end
				Variables.CommandLoops[name..command] = nil
			end
		};

		Abort = {
			Prefix = Settings.Prefix;
			Commands = {"abort";"stoploop";"unloop";"unrepeat";};
			Args = {"username";"command";};
			Description = "Aborts a looped command. Must supply name of player who started the loop or \"me\" if it was you, or \"all\" for all loops. :abort sceleratis :kill bob or :abort all";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local name = args[1]:lower()
				if name=="me" then
					Variables.CommandLoops[plr.Name:lower()..args[2]] = nil
				elseif name=="all" then
					for i,v in pairs(Variables.CommandLoops) do
						Variables.CommandLoops[i] = nil
					end
				elseif args[2] then
					Variables.CommandLoops[name..args[2]] = nil
				end
			end
		};

		AbortAll = {
			Prefix = Settings.Prefix;
			Commands = {"abortall";"stoploops";};
			Args = {"username (optional)";};
			Description = "Aborts all existing command loops";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local name = args[1] and args[1]:lower()

				if name and name=="me" then
					for i,v in ipairs(Variables.CommandLoops) do
						if i:sub(1,plr.Name):lower() == plr.Name:lower() then
							Variables.CommandLoops[plr.Name:lower()..args[2]] = nil
						end
					end
				elseif name and name=="all" then
					for i,v in ipairs(Variables.CommandLoops) do
						Variables.CommandLoops[plr.Name:lower()..args[2]] = nil
					end
				elseif args[2] then
					if Variables.CommandLoops[name..args[2]] then
						Variables.CommandLoops[name..args[2]] = nil
					else
						Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = 'No loops relating to your search'})
					end
				else
					for i,v in ipairs(Variables.CommandLoops) do
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
			Function = function(plr,args)
				Remote.MakeGui(plr, "Window", {
					Title = "Command Box";
					Name = "CommandBox";
					Size  = {300,250};
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

		Tasks = {
			Hidden = true;
			Prefix = ":";
			Commands = {"tasks"};
			Args = {"player"};
			Description = "Displays running tasks";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1] then
					for i,v in next,Functions.GetPlayers(plr, args[1]) do
						local temp = {}
						local cTasks = Remote.Get(v, "TaskManager", "GetTasks") or {}

						table.insert(temp,{
							Text = "Client Tasks",
							Desc = "Tasks their client is performing"
						})

						for k,t in next,cTasks do
							table.insert(temp, {
								Text = tostring(v.Name or v.Function).. "- Status: "..v.Status.." - Elapsed: ".. v.CurrentTime - v.Created,
								Desc = tostring(v.Function);
							})
						end

						Remote.MakeGui(plr,"List",{
							Title = v.Name.."'s Tasks",
							Table = temp,
							Font = "Code",
							Update = "ShowTasks",
							UpdateArgs = {v},
							AutoUpdate = 1,
							Size = {500,400},
						})
					end
				else
					local temp = {}
					local tasks = service.GetTasks()
					local cTasks = Remote.Get(plr,"TaskManager","GetTasks") or {}

					table.insert(temp,{Text = "Server Tasks",Desc = "Tasks the server is performing"})

					for i,v in next,tasks do
						table.insert(temp,{
							Text = tostring(v.Name or v.Function).." - Status: "..v.Status.." - Elapsed: "..(os.time()-v.Created),
							Desc = tostring(v.Function)
						})
					end

					table.insert(temp," ")
					table.insert(temp,{
						Text = "Client Tasks",
						Desc = "Tasks your client is performing"
					})

					for i,v in pairs(cTasks) do
						table.insert(temp,{
							Text = tostring(v.Name or v.Function).." - Status: "..v.Status.." - Elapsed: "..(v.CurrentTime-v.Created),
							Desc = tostring(v.Function);
						})
					end

					Remote.MakeGui(plr,"List",{
						Title = "Tasks",
						Table = temp,
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
			Commands = {"toserver", "joinserver"};
			Args = {"player", "jobid"};
			Hidden = false;
			Description = "Send player(s) to a server using the server's JobId";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local jobId = args[2];
				assert(args[1] and jobId, "Argument missing or nil")
				if service.RunService:IsStudio() then
					error("Command cannot be used in studio.",0)
				else
					for i, v in pairs(service.GetPlayers(plr,args[1])) do
						Functions.Message("Adonis", "Teleporting please wait.", {v}, false, 10)
						service.TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, v)
					end
				end
			end
		};

		AdminList = {
			Prefix = Settings.Prefix;
			Commands = {"admins";"adminlist";"HeadAdmins";"owners";"moderators";};
			Args = {};
			Hidden = false;
			Description = "Shows you the list of admins, also shows admins that are currently in the server";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temptable = {};
				local unsorted = {};
				local levelListCache = {}

				table.insert(temptable,'<b><font color="rgb(60, 180, 0)">==== Admins In-Game ====</font></b>')

				for i,v in pairs(service.GetPlayers()) do
					local data = Core.GetPlayer(v);
					local level, rankName = Admin.GetLevel(v);
					if level > 0 then
						table.insert(unsorted, {
							Text = v.Name .. " [".. (rankName or ("Level: ".. level)) .."]";
							Desc = "Rank: ".. (rankName or (level >= 1000 and "Place Owner") or "Unknown") .."; Permission Level: ".. level;
							SortLevel = level;
						})
					end
				end

				table.sort(unsorted, function(one, two)
					return one.SortLevel > two.SortLevel;
				end)

				for i,v in ipairs(unsorted) do
					v.SortLevel = nil;
					table.insert(temptable, v)
				end

				unsorted = {};

				table.insert(temptable,"")
				table.insert(temptable,'<b><font color="rgb(180, 60, 0)">==== All Admins ====</font></b>')

				for rank,data in next,Settings.Ranks do
					if not data.Hidden then
						table.insert(unsorted, {
							Text = "<b><font color='rgb(77,77,255)'>".. rank .." (Level: ".. data.Level ..")</font></b>";
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

				for i,v in ipairs(unsorted) do
					local Users = v.Users or {};
					local Level = v.Level or 0;
					local Rank = v.Rank or "Unknown";

					v.Users = nil;
					v.Level = nil;
					v.Rank = nil;

					table.insert(temptable, v)

					for i,user in ipairs(Users) do
						table.insert(temptable, {
							Text = "  ".. user;
							Desc = "Rank: ".. Rank .."; Level: ".. Level;
							--SortLevel = data.Level;
						});
					end
				end

				Remote.MakeGui(plr, "List", {
					Title = 'Admin List';
					Table = temptable;
					RichText = true;
				})
			end
		};

		BanList = {
			Prefix = Settings.Prefix;
			Commands = {"banlist";"banned";"bans";};
			Args = {};
			Hidden = false;
			Description = "Shows you the normal ban list";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local tab = {}
				for i,v in pairs(Settings.Banned) do
					local entry = type(v) == "string" and v;
					local reason = "No reason provided";

					if type(v) == "table" then
						if v.Name and v.UserId then
							entry = v.Name .. ":" .. v.UserId;
						elseif v.UserId then
							entry = "ID: ".. v.UserId;
						elseif v.Name then
							entry = v.Name;
						end

						if v.Reason then
							reason = v.Reason;
						end
					end

					table.insert(tab,{Text = tostring(entry), Desc = reason})
				end

				Remote.MakeGui(plr,"List",{Title = 'Ban List', Tab = tab})
			end
		};

		Vote = {
			Prefix = Settings.Prefix;
			Commands = {"vote";"makevote";"startvote";"question";"survey";};
			Args = {"player";"anwser1,answer2,etc (NO SPACES)";"question";};
			Filter = true;
			Description = "Lets you ask players a question with a list of answers and get the results";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local question = args[3]
				if not question then error("You forgot to supply a question!") end
				local answers = args[2]
				local anstab = {}
				local responses = {}
				local voteKey = "ADONISVOTE".. math.random();
				local players = service.GetPlayers(plr,args[1])
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

					for i,v in pairs(responses) do
						if not results[v] then results[v] = 0 end
						results[v] = results[v]+1
					end

					for i,v in pairs(anstab) do
						local ans = v
						local num = results[v]
						local percent
						if not num then
							num = 0
							percent = 0
						else
							percent = math.floor((num/total)*100)
						end

						table.insert(tab,{Text=ans.." | "..percent.."% - "..num.."/"..total,Desc="Number: "..num.."/"..total.." | Percent: "..percent})
					end

					return tab;
				end

				Logs.TempUpdaters[voteKey] = voteUpdate;

				if not answers then
					anstab = {"Yes","No"}
				else
					for ans in answers:gmatch("([^,]+)") do
						table.insert(anstab,ans)
					end
				end

				for i,v in pairs(players) do
					Routine(function()
						local response = Remote.GetGui(v,"Vote",{Question = question,Answers = anstab})
						if response then
							table.insert(responses, response)
						end
					end)
				end

				Remote.MakeGui(plr,"List",{
					Title = 'Results',
					Tab = voteUpdate(),
					Update = "TempUpdate",
					UpdateArgs = {{UpdateKey = voteKey}},
					AutoUpdate = 1,
				})

				delay(120, function() Logs.TempUpdaters[voteKey] = nil;end)
				--[[
				if not answers then
					anstab = {"Yes","No"}
				else
					for ans in answers:gmatch("([^,]+)") do
						table.insert(anstab,ans)
					end
				end

				local responses = {}
				local players = service.GetPlayers(plr,args[1])

				for i,v in pairs(players) do
					Routine(function()
						local response = Remote.GetGui(v,"Vote",{Question = question,Answers = anstab})
						if response then
							table.insert(responses,response)
						end
					end)
				end

				local t = 0
				repeat wait(0.1) t=t+0.1 until t>=60 or #responses>=#players

				local results = {}

				for i,v in pairs(responses) do
					if not results[v] then results[v] = 0 end
					results[v] = results[v]+1
				end

				local total = #responses
				local tab = {
					"Question: "..question;
					"Total Responses: "..total;
					"Didn't Vote: "..#players-total;
				}
				for i,v in pairs(anstab) do
					local ans = v
					local num = results[v]
					local percent
					if not num then
						num = 0
						percent = 0
					else
						percent = math.floor((num/total)*100)
					end

					table.insert(tab,{Text=ans.." | "..percent.."% - "..num.."/"..total,Desc="Number: "..num.."/"..total.." | Percent: "..percent})
				end
				Remote.MakeGui(plr,"List",{Title = 'Results', Tab = tab})--]]
			end
		};

		ToolList = {
			Prefix = Settings.Prefix;
			Commands = {"tools";"toollist";};
			Args = {};
			Hidden = false;
			Description = "Shows you a list of tools that can be obtains via the give command";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local prefix = Settings.Prefix
				local split = Settings.SplitKey
				local specialPrefix = Settings.SpecialPrefix
				local num = 0
				local children = {
					Core.Bytecode([[Object:ResizeCanvas(false, true, false, false, 5, 5)]]);
				}

				for i, v in next,Settings.Storage:GetChildren() do
					if v:IsA("Tool") or v:IsA("HopperBin") then
						table.insert(children, {
							Class = "TextLabel";
							Size = UDim2.new(1, -10, 0, 30);
							Position = UDim2.new(0, 5, 0, 30*num);
							BackgroundTransparency = 1;
							TextXAlignment = "Left";
							Text = "  "..v.Name;
							ToolTip = v:GetFullName();
							Children = {
								{
									Class = "TextButton";
									Size = UDim2.new(0, 80, 1, -4);
									Position = UDim2.new(1, -82, 0, 2);
									Text = "Spawn";
									OnClick = Core.Bytecode([[
										client.Remote.Send("ProcessCommand", "]]..prefix..[[give]]..split..specialPrefix..[[me]]..split..v.Name..[[");
									]]);
								}
							};
						})

						num = num+1;
					end
				end

				Remote.MakeGui(plr, "Window", {
					Name = "ToolList";
					Title = "Tools";
					Size  = {300, 300};
					MinSize = {150, 100};
					Content = children;
					Ready = true;
				})
			end
		};

		Piano = {
			Prefix = Settings.Prefix;
			Commands = {"piano";};
			Args = {"player"};
			Hidden = false;
			Description = "Gives you a playable keyboard piano. Credit to NickPatella.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,service.GetPlayers(plr, args[1]) do
					local piano = Deps.Assets.Piano:clone()
					piano.Parent = v:FindFirstChild("PlayerGui") or v.Backpack
					piano.Disabled = false
				end
			end
		};

		InsertList = {
			Prefix = Settings.Prefix;
			Commands = {"insertlist";"inserts";"inslist";"modellist";"models";};
			Args = {};
			Hidden = false;
			Description = "Shows you the script's available insert list";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local listforclient={}
				for i, v in pairs(Variables.InsertList) do
					table.insert(listforclient,{Text=v.Name,Desc=v.ID})
				end
				for i, v in pairs(HTTP.Trello.InsertList) do
					table.insert(listforclient,{Text=v.Name,Desc=v.ID})
				end
				Remote.MakeGui(plr,"List",{Title = "Insert List", Table = listforclient})
			end
		};

		InsertClear = {
			Prefix = Settings.Prefix;
			Commands = {"insclear";"clearinserted";"clrins";"insclr";};
			Args = {};
			Hidden = false;
			Description = "Removes inserted objects";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(Variables.InsertedObjects) do
					v:Destroy()
					table.remove(Variables.InsertedObjects,i)
				end
			end
		};

		Clear = {
			Prefix = Settings.Prefix;
			Commands = {"clear";"cleargame";"clr";};
			Args = {};
			Hidden = false;
			Description = "Remove admin objects";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				service.StopLoop("ChickenSpam")
				for i,v in pairs(Variables.Objects) do
					if v:IsA("Script") or v:IsA("LocalScript") then
						v.Disabled = true
					end
					v:Destroy()
				end

				for i,v in pairs(Variables.Cameras) do
					if v then
						table.remove(Variables.Cameras,i)
						v:Destroy()
					end
				end

				for i,v in pairs(Variables.Jails) do
					if not v.Player or not v.Player.Parent then
						local ind = v.Index
						service.StopLoop(ind.."JAIL")
						Pcall(function() v.Jail:Destroy() end)
						Variables.Jails[ind] = nil
					end
				end

				for i,v in pairs(service.Workspace:GetChildren()) do
					if v:IsA('Message') or v:IsA('Hint') then
						v:Destroy()
					end

					if v.Name:match('A_Probe (.*)') then
						v:Destroy()
					end
				end

				Variables.Objects = {}
				--RemoveMessage()
			end
		};

		ShowServerInstances = {
			Prefix = Settings.Prefix;
			Commands = {"serverinstances";};
			Args = {};
			Description = "Shows all instances created server-side by Adonis";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local objects = service.GetAdonisObjects()
				local temp = {}

				for i,v in next,objects do
					table.insert(temp, {
						Text = v:GetFullName();
						Desc = v.ClassName;
					})
				end

				Remote.MakeGui(plr, "List", {
					Title = "Adonis Instances";
					Table = temp;
					Stacking = false;
					Update = "Instances";
				})
			end
		};

		ShowClientInstances = {
			Prefix = Settings.Prefix;
			Commands = {"clientinstances";};
			Args = {"player"};
			Description = "Shows all instances created client-side by Adonis";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local instList = Remote.Get(v, "InstanceList")
					if instList then
						Remote.MakeGui(plr, "List", {
							Title = v.Name .." Instances";
							Table = instList;
							Stacking = false;
							Update = "Instances";
							UpdateArg = v;
						})
					end
				end
			end
		};

		ClearGUIs = {
			Prefix = Settings.Prefix;
			Commands = {"clearguis";"clearmessages";"clearhints";"clrguis";"clrgui";"clearscriptguis";"removescriptguis"};
			Args = {"player","deleteAll?"};
			Hidden = false;
			Description = "Remove script GUIs such as :m and :hint";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1] or "all")) do
					if tostring(args[2]):lower() == "yes" or tostring(args[2]):lower() == "true" then
						Remote.RemoveGui(v,true)
					else
						Remote.RemoveGui(v,"Message")
						Remote.RemoveGui(v,"Hint")
						Remote.RemoveGui(v,"Notification")
						Remote.RemoveGui(v,"PM")
						Remote.RemoveGui(v,"Output")
						Remote.RemoveGui(v,"Effect")
						Remote.RemoveGui(v,"Alert")
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
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1] or "all")) do
					Remote.RemoveGui(v,"Effect")
				end
			end
		};

		ResetLighting = {
			Prefix = Settings.Prefix;
			Commands = {"fix";"resetlighting";"undisco";"unflash";"fixlighting";};
			Args = {};
			Hidden = false;
			Description = "Reset lighting back to the setting it had on server start";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				service.StopLoop("LightingTask")
				for i,v in pairs(Variables.OriginalLightingSettings) do
					if i~="Sky" and service.Lighting[i]~=nil then
						Functions.SetLighting(i,v)
					end
				end
				for i,v in pairs(service.Lighting:GetChildren()) do
					if v:IsA("Sky") then
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
			Commands = {"fixplayerlighting","rplighting","clearlighting","serverlighting"};
			Args = {"player"};
			Hidden = false;
			Description = "Sets the player's lighting to match the server's";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for prop,val in pairs(Variables.LightingSettings) do
						Remote.SetLighting(v,prop,val)
					end
				end
			end
		};

		Freaky = {
			Prefix = Settings.Prefix;
			Commands = {"freaky";};
			Args = {"0-600,0-600,0-600";"optional player"};
			Hidden = false;
			Description = "Does freaky stuff to lighting. Like a messed up ambient.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local r,g,b = 100,100,100
				if args[1] and args[1]:match("(.*),(.*),(.*)") then
					r,g,b = args[1]:match("(.*),(.*),(.*)")
				end
				r,g,b = tonumber(r),tonumber(g),tonumber(b)
				if not r or not g or not b then error("Invalid Input") end
				local num1,num2,num3 = r,g,b
				num1="-"..num1.."00000"
				num2="-"..num2.."00000"
				num3="-"..num3.."00000"
				if args[2] then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						Remote.SetLighting(v,"FogColor", Color3.new(tonumber(num1),tonumber(num2),tonumber(num3)))
						Remote.SetLighting(v,"FogEnd", 9e9)
					end
				else
					Functions.SetLighting("FogColor", Color3.new(tonumber(num1),tonumber(num2),tonumber(num3)))
					Functions.SetLighting("FogEnd", 9e9) --Thanks go to Janthran for another neat glitch
				end
			end
		};

		ResetStats = {
			Prefix = Settings.Prefix;
			Commands = {"resetstats","rs"};
			Args = {"player";};
			Hidden = false;
			Description = "Sets target player(s)'s leader stats to 0";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr, args[1]:lower())) do
					cPcall(function()
						if v and v:FindFirstChild("leaderstats") then
							for a,q in pairs(v.leaderstats:GetChildren()) do
								if q:IsA("IntValue") then q.Value = 0 end
							end
						end
					end)
				end
			end
		};

		Gear = {
			Prefix = Settings.Prefix;
			Commands = {"gear";"givegear";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Gives the target player(s) a gear from the catalog based on the ID you supply";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local gearID = assert(tonumber(args[2]), "Invalid ID (not Number?)")
				local AssetIdType = service.MarketPlace:GetProductInfo(gearID).AssetTypeId

				if AssetIdType == 19 then
					local gear = service.Insert(gearID)

					if gear:IsA("Tool") or gear:IsA("HopperBin") then
						service.New("StringValue",gear).Name = Variables.CodeName..gear.Name
						for i, v in pairs(service.GetPlayers(plr,args[1])) do
							if v:FindFirstChild("Backpack") then
								gear:Clone().Parent = v.Backpack
							end
						end
					end
				else
					error("Invalid ID provided, Not AssetType Gear.",0)
				end
			end
		};

		Sell = {
			Prefix = Settings.Prefix;
			Commands = {"sell";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Prompts the player(s) to buy the product belonging to the ID you supply";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					service.MarketPlace:PromptPurchase(v,tonumber(args[2]),false)
				end
			end
		};

		Hat = {
			Prefix = Settings.Prefix;
			Commands = {"hat";"givehat";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Gives the target player(s) a hat based on the ID you supply";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if not args[2] then error("Argument missing or nil") end

				local id = args[2]

				if not tonumber(id) then
					local built = {
						teapot = 1055299;
					}

					if built[string.lower(args[2])] then
						id = built[string.lower(args[2])]
					end
				end

				if not tonumber(id) then error("Invalid ID") end

				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						Commands.DonorHat.Function(v, {id})
					end
				end
			end
		};

		Capes = {
			Prefix = Settings.Prefix;
			Commands = {"capes";"capelist";};
			Args = {};
			Hidden = false;
			Description = "Shows you the list of capes for the cape command";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local list={}
				for i,v in pairs(Variables.Capes) do
					table.insert(list,v.Name)
				end
				Remote.MakeGui(plr,'List',{Title = 'Cape List',Tab = list})
			end
		};

		Cape = {
			Prefix = Settings.Prefix;
			Commands = {"cape";"givecape";};
			Args = {"player";"name/color";"material";"reflectance";"id";};
			Hidden = false;
			Description = "Gives the target player(s) the cape specified, do Settings.Prefixcapes to view a list of available capes ";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local color="White"
				if pcall(function() return BrickColor.new(args[2]) end) then color = args[2] end
				local mat = args[3] or "Fabric"
				local ref = args[4]
				local id = args[5]
				if args[2] and not args[3] then
					for k,cape in pairs(Variables.Capes) do
						if args[2]:lower()==cape.Name:lower() then
							color = cape.Color
							mat = cape.Material
							ref = cape.Reflectance
							id = cape.ID
						end
					end
				end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.Cape(v,false,mat,color,id,ref)
				end
			end
		};

		UnCape = {
			Prefix = Settings.Prefix;
			Commands = {"uncape";"removecape";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target player(s)'s cape";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					Functions.UnCape(v)
				end
			end
		};

		Slippery = {
			Prefix = Settings.Prefix;
			Commands = {"slippery";"iceskate";"icewalk";"slide";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) slide when they walk";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local vel = service.New('BodyVelocity')
				vel.Name = 'ADONIS_IceVelocity'
				vel.maxForce = Vector3.new(5000,0,5000)
				local scr = Deps.Assets.Slippery:Clone()

				scr.Name = "ADONIS_IceSkates"

				for i, v in pairs(service.GetPlayers(plr, args[1]:lower())) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local vel = vel:Clone()
						vel.Parent = v.Character.HumanoidRootPart
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end

				scr:Destroy()
			end
		};

		UnSlippery = {
			Prefix = Settings.Prefix;
			Commands = {"unslippery","uniceskate","unslide"};
			Args = {"player";};
			Hidden = false;
			Description = "Get sum friction all up in yo step";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr, args[1]:lower())) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local scr = v.Character.HumanoidRootPart:FindFirstChild("ADONIS_IceSkates")
						local vel = v.Character.HumanoidRootPart:FindFirstChild("ADONIS_IceVelocity")
						if vel then vel:Destroy() end
						if scr then scr.Disabled = true scr:Destroy() end
					end
				end
			end
		};

		NoClip = {
			Prefix = Settings.Prefix;
			Commands = {"noclip";};
			Args = {"player";};
			Hidden = false;
			Description = "NoClips the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local clipper = Deps.Assets.Clipper:Clone()
				clipper.Name = "ADONIS_NoClip"

				for i,p in pairs(service.GetPlayers(plr,args[1])) do
					Admin.RunCommand(Settings.Prefix.."clip",p.Name)
					local new = clipper:Clone()
					new.Parent = p.Character.Humanoid
					new.Disabled = false
				end
			end
		};

		FlyNoClip = {
			Prefix = Settings.Prefix;
			Commands = {"flynoclip";};
			Args = {"player";"speed";};
			Hidden = false;
			Description = "Flying noclip";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr,args[1])) do
					Commands.Fly.Function(p, args, true)
				end
			end
		};

		Clip = {
			Prefix = Settings.Prefix;
			Commands = {"clip";"unnoclip";};
			Args = {"player";};
			Hidden = false;
			Description = "Un-NoClips the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr,args[1])) do
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
					end
				end
			end
		};

		Jail = {
			Prefix = Settings.Prefix;
			Commands = {"jail";"imprison";};
			Args = {"player";};
			Hidden = false;
			Description = "Jails the target player(s), removing their tools until they are un-jailed";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local cf = CFrame.new(v.Character.HumanoidRootPart.CFrame.p + Vector3.new(0,1,0))
						local origpos = v.Character.HumanoidRootPart.Position

						local mod = service.New("Model", service.Workspace)
						mod.Name = v.Name .. "_ADONISJAIL"
						local top = service.New("Part", mod)
						top.Locked = true
						--top.formFactor = "Symmetric"
						top.Size = Vector3.new(6,1,6)
						top.TopSurface = 0
						top.BottomSurface = 0
						top.Anchored = true
						top.CanCollide = true;
						top.BrickColor = BrickColor.new("Really black")
						top.Transparency = 1
						top.CFrame = cf * CFrame.new(0,3.5,0)
						local bottom = top:Clone()
						bottom.Transparency = 0
						bottom.Parent = mod
						bottom.CanCollide = true
						bottom.CFrame = cf * CFrame.new(0,-3.5,0)
						local front = top:Clone()
						front.Transparency = 1
						front.Reflectance = 0
						front.Parent = mod
						front.Size = Vector3.new(6,6,1)
						front.CFrame = cf * CFrame.new(0,0,-3)
						local back = front:Clone()
						back.Transparency = 1
						back.Parent = mod
						back.CFrame = cf * CFrame.new(0,0,3)
						local right = front:Clone()
						right.Transparency = 1
						right.Parent = mod
						right.Size = Vector3.new(1,6,6)
						right.CFrame = cf * CFrame.new(3,0,0)
						local left = right:Clone()
						left.Transparency = 1
						left.Parent = mod
						left.CFrame = cf * CFrame.new(-3,0,0)
						local msh = service.New("BlockMesh", front)
						msh.Scale = Vector3.new(1,1,0)
						local msh2 = msh:Clone()
						msh2.Parent = back
						local msh3 = msh:Clone()
						msh3.Parent = right
						msh3.Scale = Vector3.new(0,1,1)
						local msh4 = msh3:Clone()
						msh4.Parent = left
						local brick = service.New('Part',mod)
						local box = service.New('SelectionBox',brick)
						box.Adornee = brick
						box.Color = BrickColor.new('White')
						brick.Anchored = true
						brick.CanCollide = false
						brick.Transparency = 1
						brick.Size = Vector3.new(5,7,5)
						brick.CFrame = cf
						--table.insert(Variables.Objects, mod)

						local value = service.New('StringValue',mod)
						value.Name = 'Player'
						value.Value = v.Name

						v.Character.HumanoidRootPart.CFrame = cf

						local ind = tostring(v.userId)
						local jail = {
							Player = v;
							Name = v.Name;
							Index = ind;
							Jail = mod;
							Tools = {};
						}

						Variables.Jails[ind] = jail

						for l,k in pairs(v.Backpack:GetChildren()) do
							if k:IsA("Tool") or k:IsA("HopperBin") then
								table.insert(jail.Tools,k)
								k.Parent = nil
							end
						end

						service.TrackTask("Thread: JailLoop"..tostring(ind), function()
							while wait() and Variables.Jails[ind] == jail and mod.Parent == service.Workspace do
								if Variables.Jails[ind] == jail and v.Parent == service.Players then
									if v.Character then
										local torso = v.Character:FindFirstChild('HumanoidRootPart')
										if torso then
											for l,k in pairs(v.Backpack:GetChildren()) do
												if k:IsA("Tool") or k:IsA("HopperBin") then
													table.insert(jail.Tools,k)
													k.Parent = nil
												end
											end
											if (torso.Position-origpos).Magnitude>3.3 then
												torso.CFrame = cf
											end
										end
									end
								elseif Variables.Jails[ind] ~= jail then
									mod:Destroy()
									break;
								end
							end

							mod:Destroy()
						end)
					end
				end
			end
		};

		UnJail = {
			Prefix = Settings.Prefix;
			Commands = {"unjail";"free";"release";};
			Args = {"player";};
			Hidden = false;
			Description = "UnJails the target player(s) and returns any tools that were taken from them while jailed";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local found = false

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local ind = tostring(v.userId)
					local jail = Variables.Jails[ind]
					if jail then
						--service.StopLoop(ind.."JAIL")
						Pcall(function()
							for i,tool in pairs(jail.Tools) do
								tool.Parent = v.Backpack
							end
						end)
						Pcall(function() jail.Jail:Destroy() end)
						Variables.Jails[ind] = nil
						found = true
					end
				end

				if not found then
					for i,v in next,Variables.Jails do
						if v.Name:lower():sub(1,#args[1]) == args[1]:lower() then
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
			Commands = {"bchat";"dchat";"bubblechat";"dialogchat";};
			Args = {"player";"color(red/green/blue/off)";};
			Description = "Gives the target player(s) a little chat gui, when used will let them chat using dialog bubbles";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local color = Enum.ChatColor.Red
				if not args[2] then
					color = Enum.ChatColor.Red
				elseif args[2]:lower()=='red' then
					color = Enum.ChatColor.Red
				elseif args[2]:lower()=='green' then
					color = Enum.ChatColor.Green
				elseif args[2]:lower()=='blue' then
					color = Enum.ChatColor.Blue
				elseif args[2]:lower()=='off' then
					color = "off"
				end
				for i,v in next,service.GetPlayers(plr,(args[1] or plr.Name)) do
					Remote.MakeGui(v,"BubbleChat",{Color = color})
				end
			end
		};

		Track = {
			Prefix = Settings.Prefix;
			Commands = {"track";"trace";"find";};
			Args = {"player";};
			Hidden = false;
			Description = "Shows you where the target player(s) is/are";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					coroutine.wrap(function()
						local bb = service.New('BillboardGui')
						local la = service.New('SelectionPartLasso',bb)
						local Humanoid = plr.Character:FindFirstChild("Humanoid")
						local Part = v.Character:FindFirstChild("HumanoidRootPart")
						if Part and Humanoid then
							la.Part = Part
							la.Humanoid = Humanoid
							bb.Name = v.Name..'Tracker'
							bb.Adornee = v.Character.Head
							bb.AlwaysOnTop = true
							bb.StudsOffset = Vector3.new(0,2,0)
							bb.Size = UDim2.new(0,100,0,40)
							local f = service.New('Frame',bb)
							f.BackgroundTransparency = 1
							f.Size = UDim2.new(1,0,1,0)
							local name = service.New('TextLabel',f)
							name.Text = v.DisplayName.."\n(@"..v.Name..")"
							name.BackgroundTransparency = 1
							name.Font = "Arial"
							name.TextColor3 = Color3.new(1,1,1)
							name.TextStrokeColor3 = Color3.new(0,0,0)
							name.TextStrokeTransparency = 0
							name.Size = UDim2.new(1,0,0,20)
							name.TextScaled = true
							name.TextWrapped = true
							local arrow = name:clone()
							arrow.Parent = f
							arrow.Position = UDim2.new(0,0,0,20)
							arrow.Text = 'v'
							Remote.MakeLocal(plr,bb,false,true)
							local event;event = v.CharacterRemoving:Connect(function() Remote.RemoveLocal(plr,v.Name..'Tracker') event:Disconnect() end)
							local event2;event2 = plr.CharacterRemoving:Connect(function() Remote.RemoveLocal(plr,v.Name..'Tracker') event2:Disconnect() end)
						end
					end)()
				end
			end
		};

		UnTrack = {
			Prefix = Settings.Prefix;
			Commands = {"untrack";"untrace";"unfind";};
			Args = {"player";};
			Hidden = false;
			Description = "Stops tracking the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1]:lower() == Settings.SpecialPrefix.."all" then
					Remote.RemoveLocal(plr,'Tracker',false,true)
				else
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						Remote.RemoveLocal(plr,v.Name..'Tracker')
					end
				end
			end
		};

		Phase = {
			Prefix = Settings.Prefix;
			Commands = {"phase";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the player(s) character completely local";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeLocal(v,v.Character)
				end
			end
		};

		UnPhase = {
			Prefix = Settings.Prefix;
			Commands = {"unphase";};
			Args = {"player";};
			Hidden = false;
			Description = "UnPhases the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MoveLocal(v,v.Character.Name,false,service.Workspace)
					v.Character.Parent = service.Workspace
				end
			end
		};

		GiveStarterPack = {
			Prefix = Settings.Prefix;
			Commands = {"startertools";"starttools";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives the target player(s) tools that are in the game's StarterPack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					if v and v:FindFirstChild("Backpack") then
						for a,q in pairs(service.StarterPack:GetChildren()) do
							local q = q:Clone()
							if not q:FindFirstChild(Variables.CodeName) then
								service.New("StringValue", q).Name = Variables.CodeName
							end
							q.Parent = v.Backpack
						end
					end
				end
			end
		};

		Sword = {
			Prefix = Settings.Prefix;
			Commands = {"sword";"givesword";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives the target player(s) a sword";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v:FindFirstChild("Backpack") then
						local sword = service.Insert(125013769)
						local config = sword:FindFirstChild("Configurations")
						if config then
							config.CanTeamkill.Value = true
						end
						sword.Parent = v.Backpack
					end
				end
			end
		};

		Clone = {
			Prefix = Settings.Prefix;
			Commands = {"clone";"cloneplayer";};
			Args = {"player";};
			Hidden = false;
			Description = "Clones the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v and v.Character and v.Character:FindFirstChild("Humanoid") then
							v.Character.Archivable = true
							local cl = v.Character:Clone()
							table.insert(Variables.Objects,cl)
							local anim = cl:FindFirstChild("Animate")
							if anim then
								local Animate = v.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 and Deps.Assets.R15Animate:Clone() or Deps.Assets.R6Animate:Clone()
								Animate:ClearAllChildren()
								for _,v in ipairs(anim:GetChildren()) do
									v.Parent = Animate
								end
								Animate.Parent = cl
								Animate.Disabled = false
								anim:Destroy()
							end
							cl.Parent = workspace
							cl:MoveTo(v.Character:GetModelCFrame().p)
							cl:MakeJoints()
							cl:WaitForChild("Humanoid")
							v.Character.Archivable = false
							repeat wait(0.5) until not cl:FindFirstChild("Humanoid") or cl.Humanoid.Health <= 0
							wait(5)
							if cl then cl:Destroy() end
						end
					end)
				end
			end
		};

		CopyCharacter = {
			Prefix = Settings.Prefix;
			Commands = {"copychar";"copycharacter";"copyplayercharacter"};
			Args = {"player";"target";};
			Hidden = false;
			Description = "Changes specific players' character to the target's character. (i.g. To copy Player1's character, do ':copychar me Player1')";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1], "Argument #1 must be supplied.")
				assert(args[2], "Argument #2 must be supplied. What player would you want to copy?")

				local target = service.GetPlayers(plr,args[2])[1]
				local target_character = target.Character
				if target_character then
					target_character.Archivable = true
					target_character = target_character:Clone()
				end

				assert(target_character, "Targeted player doesn't have a character or has a locked character")

				local target_humandescrip = target and target.Character:FindFirstChildOfClass("Humanoid") and target.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass"HumanoidDescription"

				assert(target_humandescrip, "Targeted player doesn't have a HumanoidDescription or has a locked HumanoidDescription [Cannot copy target's character]")

				target_humandescrip.Archivable = true
				target_humandescrip = target_humandescrip:Clone()

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if (v and v.Character and v.Character:FindFirstChildOfClass("Humanoid")) and (target and target.Character and target.Character:FindFirstChildOfClass"Humanoid") then
							v.Character.Archivable = true

							for d,e in pairs(v.Character:GetChildren()) do
								if e:IsA"Accessory" then
									e:Destroy()
								end
							end

							local cl = target_humandescrip:Clone()
							cl.Parent = v.Character:FindFirstChildOfClass("Humanoid")
							pcall(function() v.Character:FindFirstChildOfClass("Humanoid"):ApplyDescription(cl) end)

							for d,e in pairs(target_character:GetChildren()) do
								if e:IsA"Accessory" then
									e:Clone().Parent = v.Character
								end
							end
						end
					end)
				end
			end
		};

		ClickTeleport = {
			Prefix = Settings.Prefix;
			Commands = {"clickteleport";"teleporttoclick";"ct";"clicktp";"forceteleport";"ctp";"ctt";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives you a tool that lets you click where you want the target player to stand, hold r to rotate them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local scr = Deps.Assets.ClickTeleport:Clone()
					scr.Mode.Value = "Teleport"
					scr.Target.Value = v.Name
					local tool = service.New('Tool')
					tool.CanBeDropped = false
					tool.RequiresHandle = false
					service.New("StringValue",tool).Name = Variables.CodeName
					scr.Parent = tool
					scr.Disabled = false
					tool.Parent = plr.Backpack
				end
			end
		};

		ClickWalk = {
			Prefix = Settings.Prefix;
			Commands = {"clickwalk";"cw";"ctw";"forcewalk";"walktool";"walktoclick";"clickcontrol";"forcewalk";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives you a tool that lets you click where you want the target player to walk, hold r to rotate them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local scr = Deps.Assets.ClickTeleport:Clone()
					scr.Mode.Value = "Walk"
					scr.Target.Value = v.Name
					local tool = service.New('Tool')
					tool.CanBeDropped = false
					tool.RequiresHandle = false
					service.New("StringValue",tool).Name = Variables.CodeName
					scr.Parent = tool
					scr.Disabled = false
					tool.Parent = plr.Backpack
				end
			end
		};



		BodySwap = {
			Prefix = Settings.Prefix;
			Commands = {"bodyswap";"bodysteal";"bswap";};
			Args = {"player1";"player2";};
			Hidden = false;
			Description = "Swaps player1's and player2's bodies and tools";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for i2,v2 in pairs(service.GetPlayers(plr,args[2])) do
						local temptools=service.New('Model')
						local tempcloths=service.New('Model')
						local vpos=v.Character.HumanoidRootPart.CFrame
						local v2pos=v2.Character.HumanoidRootPart.CFrame
						local vface=v.Character.Head.face
						local v2face=v2.Character.Head.face
						vface.Parent=v2.Character.Head
						v2face.Parent=v.Character.Head
						for k,p in pairs(v.Character:GetChildren()) do
							if p:IsA('BodyColors') or p:IsA('CharacterMesh') or p:IsA('Pants') or p:IsA('Shirt') or p:IsA('Accessory') then
								p.Parent=tempcloths
							elseif p:IsA('Tool') then
								p.Parent=temptools
							end
						end
						for k,p in pairs(v.Backpack:GetChildren()) do
							p.Parent=temptools
						end
						for k,p in pairs(v2.Character:GetChildren()) do
							if p:IsA('BodyColors') or p:IsA('CharacterMesh') or p:IsA('Pants') or p:IsA('Shirt') or p:IsA('Accessory') then
								p.Parent=v.Character
							elseif p:IsA('Tool') then
								p.Parent=v.Backpack
							end
						end
						for k,p in pairs(tempcloths:GetChildren()) do
							p.Parent=v2.Character
						end
						for k,p in pairs(v2.Backpack:GetChildren()) do
							p.Parent=v.Backpack
						end
						for k,p in pairs(temptools:GetChildren()) do
							p.Parent=v2.Backpack
						end
						v2.Character.HumanoidRootPart.CFrame=vpos
						v.Character.HumanoidRootPart.CFrame=v2pos
					end
				end
			end
		};

		Control = {
			Prefix = Settings.Prefix;
			Commands = {"control";"takeover";};
			Args = {"player";};
			Hidden = false;
			Description = "Lets you take control of the target player";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
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
						for i, p in pairs(v.Character:GetChildren()) do
							if p:IsA("BasePart") then
								p.CanCollide = false
							end
						end
						for i, p in pairs(plr.Character:GetChildren()) do
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
			Commands = {"refresh"};
			Args = {"player";};
			Hidden = false;
			Description = "Refreshes the target player(s)'s character";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in next,service.GetPlayers(plr, args[1]) do
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

					if pBackpack then
						oTools = {};

						if oHumanoid then
							oHumanoid:UnequipTools()
						end

						pBackpack.ChildAdded:Connect(function(c)
							table.insert(oTools, c);
							c.Parent = nil;
						end)

						for i,c in next,pBackpack:GetChildren() do
							table.insert(oTools, c);
							c.Parent = nil;
						end
					end

					--// Handle respawn and repositioning
					local newChar, newHumanoid, newPrimary;

					delay(0.1, function() p:LoadCharacter() end);

					--// Reposition if possible
					if oPos then
						if not p.Character or p.Character == oChar then
							newChar = p.CharacterAdded:Wait();
						else
							newChar = p.Character;
						end

						if newChar then
							wait(); -- Let it finish loading character contents

							newHumanoid = newChar:FindFirstChildOfClass("Humanoid");
							newPrimary = newChar.PrimaryPart or (Humanoid and Humanoid.RootPart) or oChar:FindFirstChild("HumanoidRootPart");

							local forcefield = newChar:FindFirstChildOfClass("ForceField");
							if forcefield then
								forcefield:Destroy()
							end

							if newPrimary then
								newPrimary.CFrame = oPos;
							else
								newChar:MoveTo(oPos.Position)
							end
						end
					end

					--// Bring previous tools back
					local newBackpack = p:FindFirstChildOfClass("Backpack")
					if newBackpack and oTools then
						newBackpack:ClearAllChildren();
						for i,t in next,oTools do
							t.Parent = newBackpack;
						end
					end
				end
			end
		};

		Kill = {
			Prefix = Settings.Prefix;
			Commands = {"kill";};
			Args = {"player";};
			Hidden = false;
			Description = "Kills the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local hum = v.Character:FindFirstChildWhichIsA("Humanoid")
					if hum then
						hum.Health = 0
					end
					v.Character:BreakJoints()
				end
			end
		};

		Respawn = {
			Prefix = Settings.Prefix;
			Commands = {"respawn";"re";"reset"};
			Args = {"player";};
			Hidden = false;
			Description = "Respawns the target player(s)"; -- typo fixed
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					v:LoadCharacter()
					Remote.Send(v,'Function','SetView','reset')
				end
			end
		};

		R6 = {
			Prefix = Settings.Prefix;
			Commands = {"r6","classicrig"};
			Args = {"player";};
			Hidden = false;
			Description = "Converts players' character to R6";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.ConvertPlayerCharacterToRig(v, "R6")
				end
			end
		};

		R15 = {
			Prefix = Settings.Prefix;
			Commands = {"r15","rthro"};
			Args = {"player";};
			Hidden = false;
			Description = "Converts players' character to R15";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.ConvertPlayerCharacterToRig(v, "R15")
				end
			end
		};

		Trip = {
			Prefix = Settings.Prefix;
			Commands = {"trip";};
			Args = {"player";"angle";};
			Hidden = false;
			Description = "Rotates the target player(s) by 180 degrees or a custom angle";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local angle = 130 or args[2]
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.Angles(0,0,math.rad(angle))
					end
				end
			end
		};

		Stun = {
			Prefix = Settings.Prefix;
			Commands = {"stun";};
			Args = {"player";};
			Hidden = false;
			Description = "Stuns the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.PlatformStand = true
					end
				end
			end
		};

		UnStun = {
			Prefix = Settings.Prefix;
			Commands = {"unstun";};
			Args = {"player";};
			Hidden = false;
			Description = "UnStuns the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.PlatformStand = false
					end
				end
			end
		};

		Jump = {
			Prefix = Settings.Prefix;
			Commands = {"jump";};
			Args = {"player";};
			Hidden = false;
			Description = "Forces the target player(s) to jump";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.Jump = true
					end
				end
			end
		};

		Sit = {
			Prefix = Settings.Prefix;
			Commands = {"sit";"seat";};
			Args = {"player";};
			Hidden = false;
			Description = "Forces the target player(s) to sit";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.Sit = true
					end
				end
			end
		};

		Invisible = {
			Prefix = Settings.Prefix;
			Commands = {"invisible";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) invisible";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in next,service.GetPlayers(plr,args[1]) do
					if v.Character then
						for a, obj in next,v.Character:GetChildren() do
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
			Commands = {"visible";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) visible";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in next,service.GetPlayers(plr,args[1]) do
					if v.Character then
						for a, obj in next,v.Character:GetChildren() do
							if obj:IsA("BasePart") and obj.Name~='HumanoidRootPart' then
								obj.Transparency = 0
								if obj:FindFirstChild("face") then
									obj.face.Transparency = 0
								end
							elseif obj:IsA("Accoutrement") and obj:FindFirstChild("Handle") then
								obj.Handle.Transparency = 0
							elseif obj:IsA("ForceField") then
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
			Commands = {"lock";};
			Args = {"player";};
			Hidden = false;
			Description = "Locks the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
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
			Commands = {"unlock";};
			Args = {"player";};
			Hidden = false;
			Description = "UnLocks the the target player(s), makes it so you can use btools on them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
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

		Explode = {
			Prefix = Settings.Prefix;
			Commands = {"explode";"boom";"boomboom";};
			Args = {"player";"radius"};
			Hidden = false;
			Description = "Explodes the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character.PrimaryPart then
						local Explosion = service.New("Explosion")
						Explosion.Position = v.Character.PrimaryPart.Position
						Explosion.BlastRadius = args[2] or 20
						Explosion.Archivable = false
						Explosion.Parent = workspace.Terrain
					end
				end
			end
		};

		Light = {
			Prefix = Settings.Prefix;
			Commands = {"light";};
			Args = {"player";"color";};
			Hidden = false;
			Description = "Makes a PointLight on the target player(s) with the color specified";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local str = BrickColor.new('Bright blue').Color

				if args[2] then
					local teststr = args[2]
					if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr).Color end
				end

				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						Functions.NewParticle(v.Character.HumanoidRootPart,"PointLight",{
							Name = "ADONIS_LIGHT";
							Color = str;
							Brightness = 5;
							Range = 15;
						})
					end
				end
			end
		};

		UnLight = {
			Prefix = Settings.Prefix;
			Commands = {"unlight";};
			Args = {"player";};
			Hidden = false;
			Description = "UnLights the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						Functions.RemoveParticle(v.Character.HumanoidRootPart,"ADONIS_LIGHT")
					end
				end
			end
		};

		Paint = {
			Prefix = Settings.Prefix;
			Commands = {"paint";};
			Args = {"player";"brickcolor"};
			Hidden = false;
			Description = "Paints the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local brickColor = (args[2] and BrickColor.new(args[2])) or BrickColor.Random()

				if not args[2] then
					Functions.Hint("Brickcolor wasn't supplied. Default was supplied: Random", {plr})
				elseif not brickColor then
					Functions.Hint("Brickcolor was invalid. Default was supplied: Pearl", {plr})
					brickColor = BrickColor.new("Pearl")
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChildOfClass"BodyColors" then
						local bc = v.Character:FindFirstChildOfClass"BodyColors"

						for i,v in pairs{"HeadColor", "LeftArmColor", "RightArmColor", "RightLegColor", "LeftLegColor", "TorsoColor"} do
							bc[v] = brickColor
						end
					end
				end
			end
		};

		Oddliest = {
			Prefix = Settings.Prefix;
			Commands = {"oddliest";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns you into the one and only Oddliest";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Admin.RunCommand(Settings.Prefix.."char",v.Name,"51310503")
				end
			end
		};

		Sceleratis = {
			Prefix = Settings.Prefix;
			Commands = {"sceleratis";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns you into me <3";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Admin.RunCommand(Settings.Prefix.."char",v.Name,"userid-1237666")
				end
			end
		};

		Ambient = {
			Prefix = Settings.Prefix;
			Commands = {"ambient";};
			Args = {"num,num,num";"optional player"};
			Hidden = false;
			Description = "Change Ambient";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local r,g,b = 1,1,1
				if args[1] and args[1]:match("(.*),(.*),(.*)") then
					r,g,b = args[1]:match("(.*),(.*),(.*)")
				end
				r,g,b = tonumber(r),tonumber(g),tonumber(b)
				if not r or not g or not b then error("Invalid Input") end
				if args[2] then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						Remote.SetLighting(v,"Ambient",Color3.new(r,g,b))
					end
				else
					Functions.SetLighting("Ambient",Color3.new(r,g,b))
				end
			end
		};

		OutdoorAmbient = {
			Prefix = Settings.Prefix;
			Commands = {"oambient";"outdoorambient";};
			Args = {"num,num,num";"optional player"};
			Hidden = false;
			Description = "Change OutdoorAmbient";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local r,g,b = 1,1,1
				if args[1] and args[1]:match("(.*),(.*),(.*)") then
					r,g,b = args[1]:match("(.*),(.*),(.*)")
				end
				r,g,b = tonumber(r),tonumber(g),tonumber(b)
				if not r or not g or not b then error("Invalid Input") end
				if args[2] then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						Remote.SetLighting(v,"OutdoorAmbient",Color3.new(r,g,g))
					end
				else
					Functions.SetLighting("OutdoorAmbient",Color3.new(r,g,b))
				end
			end
		};

		RemoveFog = {
			Prefix = Settings.Prefix;
			Commands = {"nofog";"fogoff";};
			Args = {"optional player"};
			Hidden = false;
			Description = "Fog Off";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1] then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						Remote.SetLighting(v,"FogEnd",1000000000000)
					end
				else
					Functions.SetLighting("FogEnd",1000000000000)
				end
			end
		};

		Shadows = {
			Prefix = Settings.Prefix;
			Commands = {"shadows";};
			Args = {"on/off";"optional player"};
			Hidden = false;
			Description = "Determines if shadows are on or off";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1]:lower()=='on' or args[1]:lower()=="true" then
					if args[2] then
						for i,v in pairs(service.GetPlayers(plr,args[2])) do
							Remote.SetLighting(v,"GlobalShadows",true)
						end
					else
						Functions.SetLighting("GlobalShadows",true)
					end
				elseif args[1]:lower()=='off' or args[1]:lower()=="false" then
					if args[2] then
						for i,v in pairs(service.GetPlayers(plr,args[2])) do
							Remote.SetLighting(v,"GlobalShadows",false)
						end
					else
						Functions.SetLighting("GlobalShadows",false)
					end
				end
			end
		};

		Outlines = {
			Prefix = Settings.Prefix;
			Commands = {"outlines";};
			Args = {"on/off";"optional player"};
			Hidden = false;
			Description = "Determines if outlines are on or off";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1]:lower()=='on' or args[1]:lower()=="true" then
					if args[2] then
						for i,v in pairs(service.GetPlayers(plr,args[2])) do
							Remote.SetLighting(v,"Outlines",true)
						end
					else
						Functions.SetLighting("Outlines",true)
					end
				elseif args[1]:lower()=='off' or args[1]:lower()=="false" then
					if args[2] then
						for i,v in pairs(service.GetPlayers(plr,args[2])) do
							Remote.SetLighting(v,"Outlines",false)
						end
					else
						Functions.SetLighting("Outlines",false)
					end
				end
			end
		};

		Brightness = {
			Prefix = Settings.Prefix;
			Commands = {"brightness";};
			Args = {"number";"optional player"};
			Hidden = false;
			Description = "Change Brightness";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[2] then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						Remote.SetLighting(v,"Brightness",args[1])
					end
				else
					Functions.SetLighting("Brightness",args[1])
				end
			end
		};

		Time = {
			Prefix = Settings.Prefix;
			Commands = {"time";"timeofday";};
			Args = {"time";"optional player"};
			Hidden = false;
			Description = "Change Time";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[2] then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						Remote.SetLighting(v,"TimeOfDay",args[1])
					end
				else
					Functions.SetLighting("TimeOfDay",args[1])
				end
			end
		};


		FogColor = {
			Prefix = Settings.Prefix;
			Commands = {"fogcolor";};
			Args = {"num";"num";"num";"optional player"};
			Hidden = false;
			Description = "Fog Color";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[4] then
					for i,v in pairs(service.GetPlayers(plr,args[4])) do
						Remote.SetLighting(v,"FogColor",Color3.new(args[1],args[2],args[3]))
					end
				else
					Functions.SetLighting("FogColor",Color3.new(args[1],args[2],args[3]))
				end
			end
		};

		FogStartEnd = {
			Prefix = Settings.Prefix;
			Commands = {"fog";};
			Args = {"start";"end";"optional player"};
			Hidden = false;
			Description = "Fog Start/End";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[3] then
					for i,v in pairs(service.GetPlayers(plr,args[3])) do
						Remote.SetLighting(v,"FogEnd",args[2])
						Remote.SetLighting(v,"FogStart",args[1])
					end
				else
					Functions.SetLighting("FogEnd",args[2])
					Functions.SetLighting("FogStart",args[1])
				end
			end
		};



		StarterGive = {
			Prefix = Settings.Prefix;
			Commands = {"startergive";};
			Args = {"player";"toolname";};
			Hidden = false;
			Description = "Places the desired tool into the target player(s)'s StarterPack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local found = {}
				local temp = service.New("Folder")
				for a, tool in pairs(Settings.Storage:GetChildren()) do
					if tool:IsA("Tool") or tool:IsA("HopperBin") then
						if args[2]:lower() == "all" or tool.Name:lower():sub(1,#args[2])==args[2]:lower() then
							tool.Archivable = true
							local parent = tool.Parent
							if not parent.Archivable then
								tool.Parent = temp
							end
							table.insert(found,tool:Clone())
							tool.Parent = parent
						end
					end
				end
				if #found>0 then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						for k,t in pairs(found) do
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
			Commands = {"starterremove";};
			Args = {"player";"toolname";};
			Hidden = false;
			Description = "Removes the desired tool from the target player(s)'s StarterPack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr, args[1]:lower())) do
					if v:FindFirstChild("StarterGear") then
						for a,tool in pairs(v.StarterGear:GetChildren()) do
							if tool:IsA("Tool") or tool:IsA("HopperBin") then
								if args[2]:lower() == "all" or tool.Name:lower():find(args[2]:lower()) == 1 then
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
			Commands = {"give";"tool";};
			Args = {"player";"tool";};
			Hidden = false;
			Description = "Gives the target player(s) the desired tool(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local found = {}
				local temp = service.New("Folder")
				for a, tool in pairs(Settings.Storage:GetChildren()) do
					if tool:IsA("Tool") or tool:IsA("HopperBin") then
						if args[2]:lower() == "all" or tool.Name:lower():sub(1,#args[2])==args[2]:lower() then
							tool.Archivable = true
							local parent = tool.Parent
							if not parent.Archivable then
								tool.Parent = temp
							end
							table.insert(found,tool:Clone())
							tool.Parent = parent
						end
					end
				end
				if #found>0 then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						for k,t in pairs(found) do
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
			Commands = {"steal";"stealtools";};
			Args = {"player1";"player2";};
			Hidden = false;
			Description = "Steals player1's tools and gives them to player2";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local p1 = service.GetPlayers(plr, args[1])
				local p2 = service.GetPlayers(plr, args[2])
				for i,v in pairs(p1) do
					for k,m in pairs(p2) do
						for j,n in pairs(v.Backpack:GetChildren()) do
							local b = n:clone()
							n.Parent = m.Backpack
						end
					end
					v.Backpack:ClearAllChildren()
				end
			end
		};

		CopyTools = {
			Prefix = Settings.Prefix;
			Commands = {"copytools";};
			Args = {"player1";"player2";};
			Hidden = false;
			Description = "Copies player1's tools and gives them to player2";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local p1 = service.GetPlayers(plr, args[1])
				local p2 = service.GetPlayers(plr, args[2])
				for i,v in pairs(p1) do
					for k,m in pairs(p2) do
						for j,n in pairs(v.Backpack:GetChildren()) do
							n:Clone().Parent = m.Backpack
						end
					end
				end
			end
		};

		RemoveGuis = {
			Prefix = Settings.Prefix;
			Commands = {"removeguis";"noguis";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove the target player(s)'s screen guis";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.LoadCode(v,[[for i,v in pairs(service.PlayerGui:GetChildren()) do if not client.Core.GetGui(v) then v:Destroy() end end]])
				end
			end
		};

		RemoveTools = {
			Prefix = Settings.Prefix;
			Commands = {"removetools";"notools";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove the target player(s)'s tools";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v:FindFirstChild("Backpack") then
						for a, tool in pairs(v.Character:GetChildren()) do if tool:IsA("Tool") or tool:IsA("HopperBin") then tool:Destroy() end end
						for a, tool in pairs(v.Backpack:GetChildren()) do if tool:IsA("Tool") or tool:IsA("HopperBin") then tool:Destroy() end end
					end
				end
			end
		};

		Rank = {
			Prefix = Settings.Prefix;
			Commands = {"rank";"getrank";};
			Args = {"player";"groupID";};
			Hidden = false;
			Description = "Shows you what rank the target player(s) are in the group specified by groupID";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if  v:IsInGroup(args[2]) then
						Functions.Hint("[" .. v:GetRankInGroup(args[2]) .. "] " .. v:GetRoleInGroup(args[2]), {plr})
					elseif not v:IsInGroup(args[2])then
						Functions.Hint(v.Name .. " is not in the group " .. args[2], {plr})
					end
				end
			end
		};

		Damage = {
			Prefix = Settings.Prefix;
			Commands = {"damage";"hurt";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Removes <number> HP from the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid:TakeDamage(args[2])
					end
				end
			end
		};


		SetHealth = {
			Prefix = Settings.Prefix;
			Commands = {"health";"sethealth";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Set the target player(s)'s health to <number>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v and v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.MaxHealth = args[2]
						v.Character.Humanoid.Health = v.Character.Humanoid.MaxHealth
					end
				end
			end
		};

		JumpPower = {
			Prefix = Settings.Prefix;
			Commands = {"jpower";"jpow";"jumppower";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Set the target player(s)'s jump power to <number>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						local humanoid = v.Character.Humanoid
						humanoid.JumpPower = args[2] or 50
						humanoid.JumpHeight = (args[2] or 50) / (50/7.2)
					end
				end
			end
		};

		JumpHeight = {
			Prefix = Settings.Prefix;
			Commands = {"jheight";"jumpheight";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Set the target player(s)'s jump height to <number>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						local humanoid = v.Character.Humanoid
						humanoid.JumpHeight = args[2] or 7.2
						humanoid.JumpPower = (args[2] or 7.2) * (50/7.2)
					end
				end
			end
		};

		Speed = {
			Prefix = Settings.Prefix;
			Commands = {"speed";"setspeed";"walkspeed";"ws"};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Set the target player(s)'s WalkSpeed to <number>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") then
						v.Character.Humanoid.WalkSpeed = args[2] or 16
					end
				end
			end
		};

		SetTeam = {
			Prefix = Settings.Prefix;
			Commands = {"team";"setteam";"changeteam";};
			Args = {"player";"team";};
			Hidden = false;
			Description = "Set the target player(s)'s team to <team>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for a, tm in pairs(service.Teams:GetChildren()) do
						if tm.Name:lower():sub(1,#args[2]) == args[2]:lower() then
							v.Team = tm
						end
					end
				end
			end
		};

		RandomTeam = {
			Prefix = Settings.Prefix;
			Commands = {"rteams","rteam","randomizeteams","randomteams","randomteam"};
			Args = {"players","teams"};
			Hidden = false;
			Description = "Randomize teams; :rteams or :rteams all or :rteams nonadmins team1,team2,etc";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local tArgs = {}
				local teams = {}
				local players = service.GetPlayers(plr,args[1] or "all")
				local cTeam = 1

				local function assign()
					local pIndex = math.random(1,#players)
					local player = players[pIndex]
					local team = teams[cTeam]

					cTeam = cTeam+1
					if cTeam > #teams then
						cTeam = 1
					end

					if player and player.Parent then
						player.Team = team
					end

					table.remove(players,pIndex)
					if #players > 0 then
						assign()
					end
				end

				if args[2] then
					for s in args[2]:gmatch("(%w+)") do
						table.insert(tArgs,s)
					end
				end


				for i,team in pairs(service.Teams:GetChildren()) do
					if #tArgs > 0 then
						for ind,check in pairs(tArgs) do
							if team.Name:lower():sub(1,#check) == check:lower() then
								table.insert(teams,team)
							end
						end
					else
						table.insert(teams,team)
					end
				end

				cTeam = math.random(1,#teams)
				assign()
			end
		};



		Unteam = {
			Prefix = Settings.Prefix;
			Commands = {"unteam","removefromteam", "neutral"};
			Args = {"player"};
			Description = "Takes the target player(s) off of a team and sets them to 'Neutral' ";
			Hidden = false;
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _,player in ipairs(Functions.GetPlayers(plr, args[1])) do
					player.Neutral = true
					player.Team = nil
					player.TeamColor = BrickColor.new(194) -- Neutral Team
				end
			end
		};

		SetFOV = {
			Prefix = Settings.Prefix;
			Commands = {"fov";"fieldofview";"setfov"};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Set the target player(s)'s field of view to <number> (min 1, max 120)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2] and tonumber(args[2]), "Argument missing or invalid")
				for i,v in next,service.GetPlayers(plr, args[1]) do
					Remote.LoadCode(v,[[workspace.CurrentCamera.FieldOfView=]].. math.clamp(tonumber(args[2]), 1, 120))
				end
			end
		};

		Place = {
			Prefix = Settings.Prefix;
			Commands = {"place";};
			Args = {"player";"placeID/serverName";};
			Hidden = false;
			Description = "Teleport the target player(s) to the place belonging to <placeID> or a reserved server";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = tonumber(args[2])
				local players = service.GetPlayers(plr,args[1])
				local servers = Core.GetData("PrivateServers") or {}
				local code = servers[args[2]]
				if code then
					for i,v in pairs(players) do
						Routine(function()
							local tp = Remote.MakeGuiGet(v,"Notification",{
								Title = "Teleport",
								Text = "Click to teleport to server "..args[2]..".",
								Time = 30,
								OnClick = Core.Bytecode("return true")
							})
							if tp then
								service.TeleportService:TeleportToPrivateServer(code.ID,code.Code,{v})
							end
						end)
					end
				elseif id then
					for i,v in pairs(players) do
						Remote.MakeGui(v,"Notification",{
							Title = "Teleport",
							Text = "Click to teleport to place "..args[2]..".",
							Time = 30,
							OnClick = Core.Bytecode("service.TeleportService:Teleport("..args[2]..")")
						})
					end
				else
					Functions.Hint("Invalid place ID/server name",{plr})
				end
			end
		};

		MakeServer = {
			Prefix = Settings.Prefix;
			Commands = {"makeserver";"reserveserver";"privateserver";};
			Args = {"serverName";"(optional) placeId";};
			Filter = true;
			Description = "Makes a private server that you can teleport yourself and friends to using :place player(s) serverName; Will overwrite servers with the same name; Caps specific";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local place = tonumber(args[2]) or game.PlaceId
				local code = service.TeleportService:ReserveServer(place)
				local servers = Core.GetData("PrivateServers") or {}
				servers[args[1]] = {Code = code,ID = place}
				Core.SetData("PrivateServers",servers)
				Functions.Hint("Made server "..args[1].." | Place: "..place,{plr})
			end
		};

		DeleteServer = {
			Prefix = Settings.Prefix;
			Commands = {"delserver";"deleteserver"};
			Args = {"serverName";};
			Hidden = false;
			Description = "Deletes a private server from the list.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local servers = Core.GetData("PrivateServers") or {}
				if servers[args[1]] then
					servers[args[1]] = nil
					Core.SetData("PrivateServers",servers)
					Functions.Hint("Removed server "..args[1],{plr})
				else
					Functions.Hint("Server "..args[1].." was not found!",{plr})
				end
			end
		};

		ListServers = {
			Prefix = Settings.Prefix;
			Commands = {"servers";"privateservers";};
			Args = {};
			Hidden = false;
			Description = "Shows you a list of private servers that were created with :makeserver";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local servers = Core.GetData("PrivateServers") or {}
				local tab = {}
				for i,v in pairs(servers) do
					table.insert(tab,{Text = i,Desc = "Place: "..v.ID.." | Code: "..v.Code})
				end
				Remote.MakeGui(plr,"List",{Title = "Servers",Table = tab})
			end
		};

		GRPlaza = {
			Prefix = Settings.Prefix;
			Commands = {"grplaza";"grouprecruitingplaza";"groupplaza";};
			Args = {"player";};
			Hidden = false;
			Description = "Teleports the target player(s) to the Group Recruiting Plaza to look for potential group members";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Notification",{
						Title = "Teleport",
						Text = "Click to teleport to GRP",
						Time = 30,
						OnClick = Core.Bytecode("service.TeleportService:Teleport(6194809)")
					})
				end
			end
		};

		Teleport = {
			Prefix = Settings.Prefix;
			Commands = {"tp";"teleport";"transport";};
			Args = {"player1";"player2";};
			Hidden = false;
			Description = "Teleport player1(s) to player2, a waypoint, or specific coords, use :tp player1 waypoint-WAYPOINTNAME to use waypoints, x,y,z for coords";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[2]:match('^waypoint%-(.*)') or args[2]:match('wp%-(.*)') then
					local m = args[2]:match('^waypoint%-(.*)') or args[2]:match('wp%-(.*)')
					local point

					for i,v in pairs(Variables.Waypoints) do
						if i:lower():sub(1,#m)==m:lower() then
							point=v
						end
					end

					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						if point then
							if v.Character.Humanoid.SeatPart~=nil then
								Functions.RemoveSeatWelds(v.Character.Humanoid.SeatPart)
							end
							if v.Character.Humanoid.Sit then
								v.Character.Humanoid.Sit = false
								v.Character.Humanoid.Jump = true
							end
							wait()
							v.Character.HumanoidRootPart.CFrame = CFrame.new(point)
						end
					end

					if not point then Functions.Hint('Waypoint '..m..' was not found.',{plr}) end
				elseif args[2]:find(',') then
					local x,y,z = args[2]:match('(.*),(.*),(.*)')
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						if v.Character.Humanoid.SeatPart~=nil then
							Functions.RemoveSeatWelds(v.Character.Humanoid.SeatPart)
						end
						if v.Character.Humanoid.Sit then
							v.Character.Humanoid.Sit = false
							v.Character.Humanoid.Jump = true
						end
						wait()
						v.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(tonumber(x),tonumber(y),tonumber(z)))
					end
				else
					local target = service.GetPlayers(plr,args[2])[1]
					local players = service.GetPlayers(plr,args[1])
					if #players == 1 and players[1] == target then
						local n = players[1]
						if n.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("HumanoidRootPart") then
							if n.Character.Humanoid.SeatPart~=nil then
								Functions.RemoveSeatWelds(n.Character.Humanoid.SeatPart)
							end
							if n.Character.Humanoid.Sit then
								n.Character.Humanoid.Sit = false
								n.Character.Humanoid.Jump = true
							end
							wait()
							n.Character.HumanoidRootPart.CFrame = (target.Character.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(90/#players*1),0)*CFrame.new(5+.2*#players,0,0))*CFrame.Angles(0,math.rad(90),0)
						end
					else
						for k,n in pairs(players) do
							if n~=target then
								if n.Character.Humanoid.SeatPart~=nil then
									Functions.RemoveSeatWelds(n.Character.Humanoid.SeatPart)
								end
								if n.Character.Humanoid.Sit then
									n.Character.Humanoid.Sit = false
									n.Character.Humanoid.Jump = true
								end
								wait()
								if n.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("HumanoidRootPart") then
									n.Character.HumanoidRootPart.CFrame = (target.Character.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(90/#players*k),0)*CFrame.new(5+.2*#players,0,0))*CFrame.Angles(0,math.rad(90),0)
								end
							end
						end
					end
				end
			end
		};

		Bring = {
			Prefix = Settings.Prefix;
			Commands = {"bring";"tptome";};
			Args = {"player";};
			Hidden = false;
			Description = "Teleport the target(s) to you";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Admin.RunCommand(Settings.Prefix.."tp",v.Name,plr.Name)
				end
			end
		};

		To = {
			Prefix = Settings.Prefix;
			Commands = {"to";"tpmeto";};
			Args = {"player";};
			Hidden = false;
			Description = "Teleport you to the target";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Admin.RunCommand(Settings.Prefix.."tp",plr.Name,v.Name)
				end
			end
		};

		Change = {
			Prefix = Settings.Prefix;
			Commands = {"change";"leaderstat";"stat";};
			Args = {"player";"stat";"value";};
			Filter = true;
			Description = "Change the target player(s)'s leader stat <stat> value to <value>";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v:FindFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:GetChildren()) do
							if st.Name:lower():find(args[2]:lower()) == 1 then
								st.Value = args[3]
							end
						end
					end
				end
			end
		};

		AddToStat = {
			Prefix = Settings.Prefix;
			Commands = {"add";"addtostat";"addstat";};
			Args = {"player";"stat";"value";};
			Hidden = false;
			Description = "Add <value> to <stat>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v:FindFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:GetChildren()) do
							if st.Name:lower():find(args[2]:lower()) == 1 and tonumber(st.Value) then
								st.Value = tonumber(st.Value)+tonumber(args[3])
							end
						end
					end
				end
			end
		};

		SubtractFromStat = {
			Prefix = Settings.Prefix;
			Commands = {"subtract";"minusfromstat";"minusstat";"subtractstat";};
			Args = {"player";"stat";"value";};
			Hidden = false;
			Description = "Subtract <value> from <stat>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v:FindFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:GetChildren()) do
							if st.Name:lower():find(args[2]:lower()) == 1 and tonumber(st.Value) then
								st.Value = tonumber(st.Value)-tonumber(args[3])
							end
						end
					end
				end
			end
		};

		Shirt = {
			Prefix = Settings.Prefix;
			Commands = {"shirt";"giveshirt";};
			Args = {"player";"ID";};
			Hidden = false;
			Description = "Give the target player(s) the shirt that belongs to <ID>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local ClothingId = tonumber(args[2])
				local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
				local Shirt = AssetIdType == 11 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Shirt", ClothingId) or error("Item ID passed has invalid item type")
				if Shirt then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						if v.Character then
							for g,k in pairs(v.Character:GetChildren()) do
								if k:IsA("Shirt") then k:Destroy() end
							end
							Shirt:Clone().Parent = v.Character
						end
					end
				else
					error("Unexpected error occured. Clothing is missing")
				end
			end
		};

		Pants = {
			Prefix = Settings.Prefix;
			Commands = {"pants";"givepants";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Give the target player(s) the pants that belongs to <id>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local ClothingId = tonumber(args[2])
				local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
				local Pants = AssetIdType == 12 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Pants", ClothingId) or error("Item ID passed has invalid item type")
				if Pants then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						if v.Character then
							for g,k in pairs(v.Character:GetChildren()) do
								if k:IsA("Pants") then k:Destroy() end
							end
							Pants:Clone().Parent = v.Character
						end
					end
				else
					error("Unexpected error occured. Clothing is missing")
				end
			end
		};

		Face = {
			Prefix = Settings.Prefix;
			Commands = {"face";"giveface";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Give the target player(s) the face that belongs to <id>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
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
					error("Invalid face(Image/robloxFace)",0)
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
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


		TargetAudio = {
			Prefix = Settings.Prefix;
			Commands = {"taudio";"localsound";"localaudio";"lsound";"laudio";};
			Args = {"player", "audioId", "noLoop", "pitch", "volume";};
			Description = "Lets you play an audio on the player's client";
			AdminLevel = "Moderators";
			Function = function(plr,args,data)

				assert(args[1] and args[2],"Argument missing or nil")

				local id = args[2]
				local volume = 1 --tonumber(args[5]) or 1
				local pitch = 1 --tonumber(args[4]) or 1
				local loop = true

				for i,v in pairs(Variables.MusicList) do
					if id==v.Name:lower() then
						id = v.ID
						if v.Pitch then
							pitch = v.Pitch
						end
						if v.Volume then
							volume=v.Volume
						end
					end
				end

				for i,v in pairs(HTTP.Trello.Music) do
					if id==v.Name:lower() then
						id = v.ID
						if v.Pitch then
							pitch = v.Pitch
						end
						if v.Volume then
							volume = v.Volume
						end
					end
				end

				if args[3] and args[3] == "true" then loop = false end
				volume = tonumber(args[5]) or volume
				pitch = tonumber(args[4]) or pitch


				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","PlayAudio",id,volume,pitch,loop)

				end
				Functions.Hint("Playing Audio on Player's Client",{plr})
			end
		};

		UnTargetAudio = {
			Prefix = Settings.Prefix;
			Commands = {"untaudio";"unlocalsound";"unlocalaudio";"unlsound";"unlaudio";};
			Args = {"player";};
			Description = "Lets you stop audio playing on the player's client";
			AdminLevel = "Moderators";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","StopAudio","all")

				end
			end
		};

		CharacterAudio = {
			Prefix = Settings.Prefix;
			Commands = {"charaudio", "charactermusic", "charmusic"};
			Args = {"player", "audioId"};
			Description = "Lets you place an audio in the target's character";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1] and args[2] and tonumber(args[2]), "Argument missing or invalid")
				local audio = service.New("Sound", {
					Looped = true;
					Name = "ADONIS_AUDIO";
					SoundId = "rbxassetid://"..args[2];
				})

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					local rootPart = char and char:FindFirstChild("HumanoidRootPart")
					if rootPart then
						local new = audio:Clone()
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
			Description = "Removes audio placed into character via :charaudio command";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for i,v in next,Functions.GetPlayers(plr, args[1]) do
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
			Commands = {"pause","pausemusic","psound","pausesound";};
			Args = {};
			Description = "Pauses the current playing song";
			AdminLevel = "Moderators";
			Function = function(plr,args,data)
				for i,v in pairs(service.Workspace:GetChildren()) do
					if v.Name=="ADONIS_SOUND" then
						if v.IsPaused == false then
							v:Pause()
							Functions.Hint("Music is now paused | Run "..Settings.Prefix.."resume to resume playback",{plr})
						else
							Functions.Hint("Music is already paused | Run "..Settings.Prefix.."resume to resume",{plr})
						end

					end
				end
			end
		};

		Resume = {
			Prefix = Settings.Prefix;
			Commands = {"resume","resumemusic","rsound","resumesound";};
			Args = {};
			Description = "Resumes the current playing song";
			AdminLevel = "Moderators";
			Function = function(plr,args,data)
				for i,v in pairs(service.Workspace:GetChildren()) do
					if v.Name=="ADONIS_SOUND" then
						if v.IsPaused == true then
							v:Resume()
							Functions.Hint("Resuming Playback...",{plr})
						else
							Functions.Hint("Music is not paused",{plr})
						end

					end
				end
			end
		};

		Pitch = {
			Prefix = Settings.Prefix;
			Commands = {"pitch";};
			Args = {"number";};
			Description = "Change the pitch of the currently playing song";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local pitch = args[1]
				for i,v in pairs(service.Workspace:GetChildren()) do
					if v.Name=="ADONIS_SOUND" then
						if args[1]:sub(1,1) == "+" then
							v.Pitch=v.Pitch+tonumber(args[1]:sub(2))
						elseif args[1]:sub(1,1) == "-" then
							v.Pitch=v.Pitch-tonumber(args[1]:sub(2))
						else
							v.Pitch = pitch
						end

					end
				end
			end
		};

		Volume = {
			Prefix = Settings.Prefix;
			Commands = {"volume"};
			Args = {"number"};
			Description = "Change the volume of the currently playing song";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local volume = tonumber(args[1])
				assert(volume, "Volume must be a valid number")
				for i,v in pairs(service.Workspace:GetChildren()) do
					if v.Name=="ADONIS_SOUND" then
						if args[1]:sub(1,1) == "+" then
							v.Volume=v.Volume+tonumber(args[1]:sub(2))
						elseif args[1]:sub(1,1) == "-" then
							v.Volume=v.Volume-tonumber(args[1]:sub(2))
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
			Function = function(plr,args)
				service.StopLoop("MusicShuffle")
				Admin.RunCommand(Settings.Prefix.."stopmusic")
				if not args[1] then error("Missing argument") end
				if args[1]:lower()~="off" then
					local idList = {}

					for ent in args[1]:gmatch("[^%s,]+") do
						local id,pitch = ent:match("(.*):(.*)")
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

						table.insert(idList,{ID = id,Pitch = pitch})
					end

					local s = service.New("Sound")
					s.Name = "ADONIS_SOUND"
					s.Parent = service.Workspace
					s.Looped = false
					s.Archivable = false

					service.StartLoop("MusicShuffle",1,function()
						local ind = idList[math.random(1,#idList)]
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
			Commands = {"music";"song";"playsong","sound";};
			Args = {"id";"noloop(true/false)";"pitch";"volume"};
			Hidden = false;
			Description = "Start playing a song";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args,data)
				local id = args[1]:lower()
				local looped = args[2]
				local pitch = tonumber(args[3]) or 1
				local mp = service.MarketPlace
				local volume = tonumber(args[4]) or 1
				local name = '#Invalid ID'

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

					for i,v in pairs(Variables.MusicList) do
						if id == v.Name:lower() then
							id = v.ID

							if v.Pitch then
								pitch = v.Pitch
							end
							if v.Volume then
								volume = v.Volume
							end
						end
					end

					for i,v in pairs(HTTP.Trello.Music) do
						if id == v.Name:lower() then
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
							name = 'Now playing '..mp:GetProductInfo(id).Name
						end
					end)

					if name == '#Invalid ID' then
						Functions.Hint("Invalid audio Name/ID",{plr})
						return
					elseif Settings.SongHint then
						Functions.Hint(name, service.GetPlayers())
					end

					for i, v in pairs(service.Workspace:GetChildren()) do
						if v:IsA("Sound") and v.Name == "ADONIS_SOUND" then
							if v.IsPaused == true then
								local ans,event = Remote.GetGui(plr,"YesNoPrompt",{
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
					s.Parent = service.Workspace
					wait(0.5)
					s:Play()
				elseif id == "off" or id == "0" then
					for i, v in pairs(service.Workspace:GetChildren()) do
						if v:IsA("Sound") and v.Name == "ADONIS_SOUND" then
							v:Destroy()
						end
					end
				end
			end
		};

		StopMusic = {
			Prefix = Settings.Prefix;
			Commands = {"stopmusic";"musicoff";};
			Args = {};
			Hidden = false;
			Description = "Stop the currently playing song";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.Workspace:GetChildren()) do
					if v.Name=="ADONIS_SOUND" then
						v:Destroy()
					end
				end
			end
		};

		MusicList = {
			Prefix = Settings.Prefix;
			Commands = {"musiclist";"listmusic";"songs";};
			Args = {};
			Hidden = false;
			Description = "Shows you the script's available music list";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local listforclient={}
				for i, v in pairs(Variables.MusicList) do
					table.insert(listforclient,{Text=v.Name,Desc=v.ID})
				end
				for i, v in pairs(HTTP.Trello.Music) do
					table.insert(listforclient,{Text=v.Name,Desc=v.ID})
				end
				Remote.MakeGui(plr,"List",{Title = "Music List", Table = listforclient})
			end
		};

		Fly = {
			Prefix = Settings.Prefix;
			Commands = {"fly";"flight";};
			Args = {"player", "speed"};
			Hidden = false;
			Description = "Lets the target player(s) fly";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args,noclip)
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

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
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
						Remote.MakeGui(v, "Notification",{
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
			Commands = {"flyspeed";"flightspeed";};
			Args = {"player", "speed"};
			Hidden = false;
			Description = "Change the target player(s) flight speed";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args,noclip)
				local speed = tonumber(args[2])

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local part = v.Character:FindFirstChild("HumanoidRootPart")
					if part then
						local scr = part:FindFirstChild("ADONIS_FLIGHT")
						if scr then
							local sVal = scr:FindFirstChild("Speed")
							if sVal then
								sVal.Value = speed
							end
						end
					end
				end
			end
		};

		UnFly = {
			Prefix = Settings.Prefix;
			Commands = {"unfly";"ground";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target player(s)'s ability to fly";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
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
			Commands = {"fling";};
			Args = {"player";};
			Hidden = false;
			Description = "Fling the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") then
							local xran local zran
							repeat xran = math.random(-9999,9999) until math.abs(xran) >= 5555
							repeat zran = math.random(-9999,9999) until math.abs(zran) >= 5555
							v.Character.Humanoid.Sit = true
							v.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
							local frc = service.New("BodyForce", v.Character.HumanoidRootPart)
							frc.Name = "BFRC"
							frc.force = Vector3.new(xran*4,9999*5,zran*4)
							service.Debris:AddItem(frc,.1)
						end
					end)
				end
			end
		};

		SuperFling = {
			Prefix = Settings.Prefix;
			Commands = {"sfling";"tothemoon";"superfling";};
			Args = {"player";"optional strength";};
			Hidden = false;
			Description = "Super fling the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local strength = tonumber(args[2]) or 5e6
				local scr = Deps.Assets.Sfling:Clone()
				scr.Strength.Value = strength
				scr.Name = "SUPER_FLING"
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local new = scr:Clone()
					new.Parent = v.Character.HumanoidRootPart
					new.Disabled = false
				end
			end
		};

		DisplayName = {
			Prefix = Settings.Prefix;
			Commands = {"displayname";"dname";};
			Args = {"player";"name/hide";};
			Filter = true;
			Description = "Name the target player(s) <name> or say hide to hide their character name";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					local char = v.Character;
					local human = char and char:FindFirstChildOfClass("Humanoid");
					if human then
						if args[2]:lower() == 'hide' then
							human.DisplayName = ''
							Remote.MakeGui(v,"Notification",{
								Title = "Notification";
								Message = "Your character name has been hidden";
								Time = 10;
							})
						else
							human.DisplayName = args[2]
							Remote.MakeGui(v,"Notification",{
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
			Commands = {"undisplayname";"undname";};
			Args = {"player";};
			Hidden = false;
			Description = "Put the target player(s)'s back to normal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local char = v.Character;
					local human = char and char:FindFirstChildOfClass("Humanoid");
					if human then
						human.DisplayName = v.DisplayName
						Remote.MakeGui(v,"Notification",{
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
			Commands = {"name";"rename";};
			Args = {"player";"name/hide";};
			Filter = true;
			Description = "Name the target player(s) <name> or say hide to hide their character name";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("Head") then
						for a, mod in pairs(v.Character:GetChildren()) do
							if mod:FindFirstChild("NameTag") then
								v.Character.Head.Transparency = 0
								mod:Destroy()
							end
						end

						local char = v.Character
						local head = char:FindFirstChild('Head')
						local mod = service.New("Model", char)
						local cl = char.Head:Clone()
						local hum = service.New("Humanoid", mod)
						mod.Name = args[2] or ''
						cl.Parent = mod
						hum.Name = "NameTag"
						hum.MaxHealth=v.Character.Humanoid.MaxHealth
						wait()
						hum.Health=v.Character.Humanoid.Health

						if args[2]:lower()=='hide' then
							mod.Name = ''
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
			Commands = {"unname";"fixname";};
			Args = {"player";};
			Hidden = false;
			Description = "Put the target player(s)'s back to normal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
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
			Commands = {"removepackage";"nopackage";"rpackage"};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target player(s)'s Package";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local rigType = humanoid.RigType
							if rigType == Enum.HumanoidRigType.R6 then
								for _,x in pairs(v.Character:GetChildren()) do
									if x:IsA("CharacterMesh") then
										x:Destroy()
									end
								end
							elseif rigType == Enum.HumanoidRigType.R15 then
								local rig = Deps.Assets.RigR15
								local rigHumanoid = rig.Humanoid
								local validParts = {}
								for _,x in pairs(Enum.BodyPartR15:GetEnumItems()) do
									validParts[x.Name] = x.Value
								end
								for _,x in pairs(rig:GetChildren()) do
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
			Function = function(plr,args)
				assert(args[1] and args[2] and tonumber(args[2]), "Argument 1 or 2 is not supplied properly")

				local items = {}
				local id = tonumber(args[2])
				local assetHD = Variables.BundleCache[id]

				if assetHD == false then
					Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = "Package "..id.." is not supported."})
					return
				end

				if not assetHD then
					local suc,ers = pcall(function() return service.AssetService:GetBundleDetailsAsync(id) end)

					if suc then
						for _, item in next, ers.Items do
							if item.Type == "UserOutfit" then
								local s,r = pcall(function() return service.Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
								Variables.BundleCache[id] = r
								assetHD = r
								break
							end
						end
					end

					if not suc or not assetHD then
						Variables.BundleCache[id] = false

						Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = "Package "..id.." is not supported."})
						return
					end
				end

				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local char = v.Character

					if char then
						local humanoid = char:FindFirstChildOfClass"Humanoid"

						if not humanoid then
							Functions.Hint("Could not transfer bundle to "..v.Name, {plr})
						else
							local newDescription = humanoid:GetAppliedDescription()
							local defaultDescription = Instance.new("HumanoidDescription")
							for _, property in next, {"BackAccessory", "BodyTypeScale", "ClimbAnimation", "DepthScale", "Face", "FaceAccessory", "FallAnimation", "FrontAccessory", "GraphicTShirt", "HairAccessory", "HatAccessory", "Head", "HeadColor", "HeadScale", "HeightScale", "IdleAnimation", "JumpAnimation", "LeftArm", "LeftArmColor", "LeftLeg", "LeftLegColor", "NeckAccessory", "Pants", "ProportionScale", "RightArm", "RightArmColor", "RightLeg", "RightLegColor", "RunAnimation", "Shirt", "ShouldersAccessory", "SwimAnimation", "Torso", "TorsoColor", "WaistAccessory", "WalkAnimation", "WidthScale"} do
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
			Commands = {"char";"character";"appearance";};
			Args = {"player";"username";};
			Hidden = false;
			Description = "Changes the target player(s)'s character appearence to <ID/Name>. If you want to supply a UserId, supply with 'userid-', followed by a number after 'userid'.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1], "Argument #1 must be filled")
				assert(args[2], "Argument #2 must be filled")

				local target = tonumber(args[2]:match("^userid%-(%d*)"))
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
						for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Commands = {"unchar";"uncharacter";"fixappearance";};
			Args = {"player";};
			Hidden = false;
			Description = "Put the target player(s)'s character appearence back to normal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						v.CharacterAppearanceId = v.UserId

						if v.Character and v.Character:FindFirstChild("Humanoid") then
							local success, desc = pcall(service.Players.GetHumanoidDescriptionFromUserId, service.Players, v.UserId)

							if success then
								v.Character.Humanoid:ApplyDescription(desc)
							end
						end
					end)
				end
			end
		};



		LoopHeal = {
			Prefix = Settings.Prefix;
			Commands = {"loopheal";};
			Args = {"player";};
			Hidden = false;
			Description = "Loop heals the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StartLoop(v.userId.."LOOPHEAL",1,function()
						Admin.RunCommand(Settings.Prefix.."heal",v.Name)
					end)
				end
			end
		};

		UnLoopHeal = {
			Prefix = Settings.Prefix;
			Commands = {"unloopheal";};
			Args = {"player";};
			Hidden = false;
			Description = "UnLoop Heal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StopLoop(v.userId.."LOOPHEAL")
				end
			end
		};

		ServerLog = {
			Prefix = ":";
			Commands = {"serverlog";"serverlogs";"serveroutput";};
			Args = {"autoupdate"};
			Description = "View server log";
			AdminLevel = "Moderators";
			NoFilter = true;
			Function = function(plr,args)
				local temp = {}
				local auto

				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end

				local function toTab(str, desc, color)
					for i,v in next,service.ExtractLines(str) do
						table.insert(temp,{Text = v,Desc = desc..v, Color = color})
					end
				end

				for i,v in next,service.LogService:GetLogHistory() do
					local mType = v.messageType
					toTab(v.message, (mType  == Enum.MessageType.MessageWarning and "Warning" or mType  == Enum.MessageType.MessageInfo and "Info" or mType  == Enum.MessageType.MessageError and "Error" or "Output").." - ", mType  == Enum.MessageType.MessageWarning and Color3.new(0.866667, 0.733333, 0.0509804) or mType  == Enum.MessageType.MessageInfo and Color3.new(0.054902, 0.305882, 1) or mType  == Enum.MessageType.MessageError and Color3.new(1, 0.196078, 0.054902))
				end

				Remote.MakeGui(plr,'List',{
					Title = 'Server Log',
					Table = temp,
					Update = 'ServerLog',
					AutoUpdate = auto;
					Stacking = true;
					Sanitize = true;
				})
			end
		};

		LocalLog = {
			Prefix = ":";
			Commands = {"locallog";"clientlog";"locallogs";"localoutput";"clientlogs";};
			Args = {"player","autoupdate"};
			Description = "View local log";
			AdminLevel = "Moderators";
			NoFilter = true;
			Function = function(plr,args)
				local auto
				if args[2] and type(args[2]) == "string" and (args[2]:lower() == "yes" or args[2]:lower() == "true") then
					auto = 1
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local temp = Remote.Get(v,"ClientLog") or {}
					Remote.MakeGui(plr,'List',{
						Title = v.Name..' Local Log',
						Table = temp,
						Update = "ClientLog";
						UpdateArg = v;
						AutoUpdate = auto;
						Stacking = true;
						Sanitize = true;
					})
				end
			end
		};

		ErrorLogs = {
			Prefix = ":";
			Commands = {"errorlogs";"debuglogs";"errorlog";"errors";"debuglog";"scripterrors";"adminerrors";};
			Args = {"autoupdate"};
			Hidden = false;
			Description = "View script error log";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local tab = {}
				local auto
				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end
				for i,v in pairs(Logs.Errors) do
					table.insert(tab,{Time=v.Time;Text=v.Text..": "..tostring(v.Desc),Desc = tostring(v.Desc)})
				end
				Remote.MakeGui(plr,"List",{
					Title = "Errors",
					Table = tab,
					Dots = true,
					Update = "Errors",
					AutoUpdate = auto,
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		ExploitLogs = {
			Prefix = Settings.Prefix;
			Commands = {"exploitlogs"};
			Args = {"autoupdate"};
			Hidden = false;
			Description = "View the exploit logs for the server OR a specific player";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local auto
				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end
				Remote.MakeGui(plr,'List',{
					Title = 'Exploit Logs',
					Tab = Logs.Exploit,
					Dots = true;
					Update = "ExploitLogs",
					AutoUpdate = auto,
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		JoinLogs = {
			Prefix = Settings.Prefix;
			Commands = {"joinlogs","joins","joinhistory"};
			Args = {"autoupdate"};
			Hidden = false;
			Description = "Displays the current join logs for the server";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local auto
				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end
				Remote.MakeGui(plr,'List',{
					Title = 'Join Logs';
					Tab = Logs.Joins;
					Dots = true;
					Update = "JoinLogs";
					AutoUpdate = auto;
				})
			end
		};

		ChatLogs = {
			Prefix = Settings.Prefix;
			Commands = {"chatlogs","chats","chathistory"};
			Args = {"autoupdate"};
			Description = "Displays the current chat logs for the server";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local auto

				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end

				Remote.MakeGui(plr,'List',{
					Title = 'Chat Logs';
					Tab = Logs.Chats;
					Dots = true;
					Update = "ChatLogs";
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		RemoteLogs = {
			Prefix = Settings.Prefix;
			Commands = {"remotelogs","rlogs","remotefires","remoterequests"};
			Args = {"autoupdate"};
			Description = "View the admin logs for the server";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local auto
				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end
				Remote.MakeGui(plr,"List",{
					Title = "Remote Logs";
					Table = Logs.RemoteFires;
					Dots = true;
					Update = "RemoteLogs";
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		ScriptLogs = {
			Prefix = Settings.Prefix;
			Commands = {"scriptlogs","scriptlog","adminlogs";"adminlog";"scriptlogs";};
			Args = {"autoupdate"};
			Description = "View the admin logs for the server";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local auto
				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end
				Remote.MakeGui(plr,"List",{
					Title = "Script Logs";
					Table = Logs.Script;
					Dots = true;
					Update = "ScriptLogs";
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		Logs = {
			Prefix = Settings.Prefix;
			Commands = {"logs";"log";"commandlogs";};
			Args = {"autoupdate"};
			Description = "View the command logs for the server";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local auto
				local temp = {}

				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end

				for i,m in pairs(Logs.Commands) do
					table.insert(temp,{Time = m.Time;Text = m.Text..": "..m.Desc;Desc = m.Desc})
				end

				Remote.MakeGui(plr,"List",{
					Title = "Admin Logs";
					Table = temp;
					Dots = true;
					Update = "CommandLogs";
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		OldLogs = {
			Prefix = Settings.Prefix;
			Commands = {"oldlogs";"oldserverlogs";"oldcommandlogs";};
			Args = {"autoupdate"};
			Description = "View the command logs for previous servers ordered by time";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local auto
				local temp = {}

				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end

				Remote.MakeGui(plr,"List",{
					Title = "Old Server Logs";
					Table = Logs.ListUpdaters.OldCommandLogs();
					Dots = true;
					Update = "OldCommandLogs";
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		ShowLogs = {
			Prefix = Settings.Prefix;
			Commands = {"showlogs";"showcommandlogs";};
			Args = {"player","autoupdate"};
			Description = "Shows the target player(s) the command logs.";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local str = Settings.Prefix.."logs"..(args[2] or "")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Admin.RunCommandAsPlayer(str, v)
				end
			end
		};

		Mute = {
			Prefix = Settings.Prefix;
			Commands = {"mute";"silence";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes it so the target player(s) can't talk";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args,data)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						--Remote.LoadCode(v,[[service.StarterGui:SetCoreGuiEnabled("Chat",false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
						local check = true
						for k,m in pairs(Settings.Muted) do
							if Admin.DoCheck(v,m) then
								check = false
							end
						end

						if check then
							table.insert(Settings.Muted, v.Name..':'..v.userId)
						end
					end
				end
			end
		};

		UnMute = {
			Prefix = Settings.Prefix;
			Commands = {"unmute";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes it so the target player(s) can talk again. No effect if on Trello mute list.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(Settings.Muted) do
						if Admin.DoCheck(v,m) then
							table.remove(Settings.Muted, k)
							--Remote.LoadCode(v,[[if not client.Variables.CustomChat then service.StarterGui:SetCoreGuiEnabled("Chat",true) client.Variables.ChatEnabled = false end client.Variables.Muted = true]])
						end
					end
				end
			end
		};

		MuteList = {
			Prefix = Settings.Prefix;
			Commands = {"mutelist";"mutes";"muted";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of currently muted players";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local list = {}
				for i,v in pairs(Settings.Muted) do
					table.insert(list,v)
				end
				Remote.MakeGui(plr,"List",{Title = "Mute List",Table = list})
			end
		};

		Freecam = {
			Prefix = Settings.Prefix;
			Commands = {"freecam";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes it so the target player(s)'s cam can move around freely (Press Space or Shift+P to toggle freecam)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local plrgui = v:FindFirstChildOfClass"PlayerGui"

					if not plrgui or plrgui:FindFirstChild"Freecam" then
						continue
					end

					local freecam = Deps.Assets.Freecam:Clone()
					freecam.Enabled = true
					freecam.ResetOnSpawn = false
					freecam.Freecam.Disabled = false
					freecam.Parent = plrgui
				end
			end
		};

		UnFreecam = {
			Prefix = Settings.Prefix;
			Commands = {"unfreecam";};
			Args = {"player";};
			Hidden = false;
			Description = "UnFreecam";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local plrgui = v:FindFirstChildOfClass"PlayerGui"

					if plrgui and plrgui:FindFirstChild"Freecam" then
						local freecam = plrgui:FindFirstChild"Freecam"

						if freecam:FindFirstChildOfClass"RemoteFunction" then
							freecam:FindFirstChildOfClass"RemoteFunction":InvokeClient(v, "End")
						end

						Remote.Send(v,'Function','SetView','reset')
						service.Debris:AddItem(freecam, 2)
					end
				end
			end
		};

		ToggleFreecam = {
			Prefix = Settings.Prefix;
			Commands = {"togglefreecam";};
			Args = {"player";};
			Hidden = false;
			Description = "Toggles Freecam";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local plrgui = v:FindFirstChildOfClass"PlayerGui"

					if plrgui:FindFirstChild"Freecam" then
						local freecam = plrgui:FindFirstChild"Freecam"

						if freecam:FindFirstChildOfClass"RemoteFunction" then
							freecam:FindFirstChildOfClass"RemoteFunction":InvokeClient(v, "Toggle")
						end
					end
				end
			end
		};

		Bots = {
			Prefix = Settings.Prefix;
			Commands = {"bot";"trainingbot"};
			Args = {"player";"num";"walk";"attack","friendly","health","speed","damage"};
			Hidden = false;
			Description = "AI bots made for training; ':bot scel 5 true true'";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local key = math.random()
				local num = tonumber(args[2]) or 1
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
					local torso = player.Character:FindFirstChild("HumanoidRootPart")
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
						local isR15 = (hum.RigType == "R15")
						local anim = (isR15 and Deps.Assets.R15Animate:Clone()) or Deps.Assets.R6Animate:Clone()

						new.Parent = service.Workspace
						new.Name = player.Name
						new.HumanoidRootPart.CFrame = pos*CFrame.Angles(0,math.rad((360/num)*i),0)*CFrame.new((num*0.2)+5,0,0)

						hum.WalkSpeed = speed
						hum.MaxHealth = health
						hum.Health = health

						if oldAnim then
							oldAnim:Destroy()
						end

						anim.Parent = new
						anim.Disabled = false

						brain.Parent = new
						brain.Disabled = false

						wait()

						event:Fire("SetSetting",{
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

						table.insert(Variables.Objects,new)
					end
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					makeBot(v)
				end
			end
		};

		TextToSpeech = {
			Prefix = Settings.Prefix;
			Commands = {"tell";"tts";"texttospeech"};
			Args = {"player";"message";};
			Filter = true;
			Description = "[WIP] Says the text you give it";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","TextToSpeech",args[2])
				end
			end
		};

		Reverb = {
			Prefix = Settings.Prefix;
			Commands = {"reverb","ambientreverb";};
			Args = {"reverbType","optional player";};
			Description = "Lets you change the reverb type with an optional player argument (CASE SENSITTIVE)";
			AdminLevel = "Moderators";
			Function = function(plr,args,data)
				local rev = args[1]

				local reverbs = {"NoReverb","GenericReverb","PaddedCell","Room","Bathroom","LivingRoom",
					"StoneRoom","Auditorium","ConcertHall","Cave","Arena","Hangar","CarpettedHallway",
					"Hallway","StoneCorridor","Alley","Forest","City","Mountains","Quarry","Plain",
					"ParkingLot","SewerPipe","UnderWater"}

				if not rev or not Enum.ReverbType[rev] then

					Functions.Hint("Argument 1 missing or nil. Opening Reverb List",{plr})

					local tab = {}

					table.insert(tab,{Text = "Note: Argument is CASE SENSITIVE"})

					for _,v in pairs(reverbs) do
						table.insert(tab,{Text = v})
					end

					Remote.MakeGui(plr,"List",{Title = "Reverbs";Table = tab})

					return
				end

				if args[2] then

					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						Remote.LoadCode(v,"game:GetService(\"SoundService\").AmbientReverb = Enum.ReverbType["..rev.."]")

					end

					Functions.Hint("Changed Ambient Reverb of specified player(s)",{plr})

				else

					service.SoundService.AmbientReverb = Enum.ReverbType[rev]
					Functions.Hint("Successfully changed the Ambient Reverb to "..rev,{plr})

				end
			end
		};

		Inspect = {
			Prefix = Settings.Prefix;
			Commands = {"inspect";"playerinfo"};
			Args = {"player"};
			Description = "Shows comphrehensive information about a player";
			Hidden = false;
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local hasSafeChat
					local isMuted = table.find(Settings.Muted, v.Name..":"..v.UserId) and true or false
					local isBanned = table.find(Settings.Banned, v.Name..":"..v.UserId) and true or false
					local level, rank = Admin.GetLevel(v);

					do
						local policyResult, policyInfo = pcall(service.PolicyService.GetPolicyInfoForPlayerAsync, service.PolicyService, v)
						hasSafeChat = policyResult and table.find(policyInfo.AllowedExternalLinkReferences, "Discord") and "No" or "Yes" or not policyResult and "Unable to be fetched"
					end

					Remote.MakeGui(plr, "Inspect", {
						Target = v;
						SafeChat = hasSafeChat;
						CanChat = service.Chat:CanUserChatAsync(v.UserId) or "[Error]";
						AdminLevel = "[".. level .."] ".. (rank or "Unknown");
						IsDonor = service.MarketPlace:UserOwnsGamePassAsync(v.UserId, Variables.DonorPass[1]);
						IsMuted = isMuted;
						IsBanned = isBanned;
						Code = service.LocalizationService:GetCountryRegionForPlayerAsync(v) or "[Error]";
						SourcePlace = v:GetJoinData().SourcePlaceId or "N/A";
						Groups = service.GroupService:GetGroupsAsync(v.UserId);
					})
				end
			end
		};

		ResetButtonEnabled = {
			Prefix = Settings.Prefix;
			Commands = {"resetbuttonenabled";"canreset"};
			Args = {"player","can reset? (true/false)"};
			Description = "Sets whether the target player(s) can reset their character";
			Hidden = false;
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2], "Argument missing or nil")
				assert(args[2]:lower() == "true" or args[2]:lower() == "false", "Invalid argument #2 (boolean expected)")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.LoadCode(v,"service.StarterGui:SetCore('ResetButtonCallback',"..args[2]:lower()..")")
				end
			end
		};

	}
end
