server = nil
service = nil
Routine = nil
Pcall = nil
cPcall = nil

return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Admin = server.Admin
	local Remote = server.Remote
	local Functions = server.Functions
	local Core = server.Core
	local Variables = server.Variables
	local HTTP = server.HTTP
	local Deps = server.Deps
	local Process = server.Process
	local Logs = server.Logs

	local Commands = {
		Boombox = {
			Prefix = Settings.Prefix;
			Commands = {"boombox"};
			Args = {"player";};
			Hidden = false;
			Description = "Gives the target player(s) a boombox";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local gear = service.Insert(tonumber(212641536))
				if gear:IsA("Tool") or gear:IsA("HopperBin") then
					service.New("StringValue",gear).Name = Variables.CodeName..gear.Name
					for i, v in pairs(service.GetPlayers(plr,args[1])) do
						if v:findFirstChild("Backpack") then
							gear:Clone().Parent = v.Backpack
						end
					end
				end
			end
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
							Desc = "Tasks their client is performing"})

						for k,t in next,cTasks do
							table.insert(temp, {
								Text = tostring(v.Function).. "- Status: "..v.Status.." - Elapsed: ".. v.CurrentTime - v.Created,
								Desc = v.Name;
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
							Text = tostring(v.Function).." - Status: "..v.Status.." - Elapsed: "..(os.time()-v.Created),
							Desc = v.Name
						})
					end

					table.insert(temp," ")
					table.insert(temp,{
						Text = "Client Tasks",
						Desc = "Tasks your client is performing"
					})

					for i,v in pairs(cTasks) do
						table.insert(temp,{
							Text = tostring(v.Function).." - Status: "..v.Status.." - Elapsed: "..(v.CurrentTime-v.Created),
							Desc = v.Name
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

		Kick = {
			Prefix = Settings.Prefix;
			Commands = {"kick";};
			Args = {"player";"optional reason";};
			Filter = true;
			Description = "Disconnects the target player from the server";
			AdminLevel = "Moderators";
			Function = function(plr,args,data)
				local plrLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel>targLevel then
						if not service.Players:FindFirstChild(v.Name) then
							Remote.Send(v,'Function','Kill')
						else
							v:Kick(args[2])
						end
						Functions.Hint("Kicked "..tostring(v),{plr})
					end
				end
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
				local timeBans = Admin.TimeBans or {}
				for i,v in next,timeBans do
					local timeLeft = v.EndTime-os.time()
					local minutes = Functions.RoundToPlace(timeLeft/60, 2)
					if timeLeft <= 0 then
						table.remove(Admin.TimeBans, i)
					else
						table.insert(tab,{Text = tostring(v.Name)..":"..tostring(v.UserId),Desc = "Minutes Left: "..tostring(minutes)})
					end
				end
				Remote.MakeGui(plr,"List",{Title = 'Time Bans', Tab = tab})
			end
		};

		Notification = {
			Prefix = Settings.Prefix;
			Commands = {"notify","notification"};
			Args = {"player","message"};
			Description = "Sends the player a notification";
			Filter = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Notification",{
						Title = "Notification";
						Message = service.Filter(args[2],plr,v);
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
			Function = function(plr,args)
				local num = tonumber(args[1]) --math.min(tonumber(args[1]),120)
				if not args[1] then error("Argument 1 missing") end

				if num then
					Admin.SlowMode = num;
					Functions.Hint("Chat slow mode enabled (".. num .."s)", service.Players:children())
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
			Function = function(plr,args)
				local num = tonumber(args[1]) --math.min(tonumber(args[1]),120)
				if not args[1] then error("Argument 1 missing") end
				for i,v in next,service.GetPlayers() do
					Remote.MakeGui(v, "Countdown", {
						Time = num;
					})
				end
				--for i = num, 1, -1 do
				--Functions.Message("Countdown", tostring(i), service.Players:children(), false, 1.1)
				--Functions.Message(" ", i, false, service.Players:children(), 0.8)
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
			Function = function(plr,args)
				local num = tonumber(args[2]) --math.min(tonumber(args[1]),120)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
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
			Function = function(plr,args)
				local num = math.min(tonumber(args[1]),120)
				local loop
				loop = service.StartLoop("HintCountdown", 1, function()
					if num < 1 then
						loop.Running = false
					else
						server.Functions.Hint(num, service.Players:children(), 2.5)
						num -= 1
					end
				end)
			end
		};

		StopCountdown = {
			Prefix = server.Settings.Prefix;
			Commands = {"stopcountdown", "stopcd"};
			Args = {};
			Description = "Stops all currently running countdowns";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.RemoveGui(v, "Countdown")
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
			Function = function(plr,args)
				assert(args[1] and args[2] and tonumber(args[1]),"Argument missing or invalid")
				for i,v in pairs(service.Players:GetPlayers()) do
					Remote.RemoveGui(v,"Message")
					Remote.MakeGui(v,"Message",{
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
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in next,service.Players:GetPlayers() do
					Remote.RemoveGui(v,"Message")
					Remote.MakeGui(v,"Message",{
						Title = "Message from " .. plr.Name;
						Message = args[1];--service.Filter(args[1],plr,v);
						Scroll = true;
						Time = (#tostring(args[1])/19)+2.5;
						Image = "http://www.roblox.com/Thumbs/Avatar.ashx?x=150&y=150&Format=Png&username="..plr.Name;
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
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.Message("Message from "..plr.Name,service.Filter(args[2],plr,v),{v})
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
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.Players:GetPlayers()) do
					Remote.RemoveGui(v,"Notify")
					Remote.MakeGui(v,"Notify",{
						Title = "Message from " .. plr.Name;
						Message = service.Filter(args[1],plr,v);
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
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.Players:GetPlayers()) do
					Remote.RemoveGui(v,"Notify")
					Remote.MakeGui(v,"Notify",{
						Title = Settings.SystemTitle;
						Message = service.Filter(args[1],plr,v);
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
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveGui(v,"Notify")
					Remote.MakeGui(v,"Notify",{
						Title = "Message from " .. plr.Name;
						Message = service.Filter(args[2],plr,v);
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
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.Players:GetPlayers()) do
					Remote.MakeGui(v,"Hint",{
						Message = tostring(plr or "")..": "..service.Filter(args[1],plr,v);
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
			Function = function(plr,args,data)
				assert(args[1] and args[2],"Argument missing or nil")
				local plrLevel = data.PlayerData.Level
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel>targLevel then
						local data = Core.GetPlayer(v)
						table.insert(data.Warnings, {From = tostring(plr), Message = args[2], Time = os.time()})
						Remote.RemoveGui(v,"Notify")
						Remote.MakeGui(v,"Notify",{
							Title = "Warning from "..tostring(plr);
							Message = args[2];
						})

						if plr and type(plr) == "userdata" then
							Remote.MakeGui(plr,"Hint",{
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
			Function = function(plr,args,data)
				assert(args[1] and args[2],"Argument missing or nil")
				local plrLevel = data.PlayerData.Level
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local targLevel = Admin.GetLevel(v)
					if plrLevel>targLevel then
						local data = Core.GetPlayer(v)
						table.insert(data.Warnings, {From = tostring(plr), Message = args[2], Time = os.time()})
						v:Kick(tostring("[Warning from "..tostring(plr).."]\n"..args[2]))
						Remote.RemoveGui(v,"Notify")
						Remote.MakeGui(v,"Notify",{
							Title = "Warning from "..tostring(plr);
							Message = args[2];
						})

						if plr and type(plr) == "userdata" then
							Remote.MakeGui(plr,"Hint",{
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
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local data = Core.GetPlayer(v)
					local tab = {}

					if data.Warnings then
						for k,m in next,data.Warnings do
							table.insert(tab,{Text = "["..k.."] "..m.Message,Desc = "Given by: "..m.From.."; "..m.Message})
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
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local data = Core.GetPlayer(v)
					data.Warnings = {}
					if plr and type(plr) == "userdata" then
						Remote.MakeGui(plr,"Hint",{
							Message = "Cleared warnings for "..tostring(v);
						})
					end
				end
			end
		};

		NumPlayers = {
			Prefix = Settings.Prefix;
			Commands = {"pnum","numplayers","howmanyplayers"};
			Args = {};
			Description = "Tells you how many players are in the server";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = 0
				local nilNum = 0
				for i,v in pairs(service.GetPlayers()) do
					if v.Parent ~= service.Players then
						nilNum = nilNum+1
					end

					num = num+1
				end

				if nilNum > 0 then
					Functions.Hint("There are currently "..tostring(num).." players; "..tostring(nilNum).." are nil or loading",{plr})
				else
					Functions.Hint("There are "..tostring(num).." players",{plr})
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
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					service.ChatService:Chat(p.Character.Head,message,Enum.ChatColor.White)
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
			Function = function(plr,args)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					Remote.Send(v,"Function","ChatMessage",service.Filter(args[2],plr,v),Color3.new(1,64/255,77/255))
				end
			end
		};

		ForceField = {
			Prefix = Settings.Prefix;
			Commands = {"ff";"forcefield";};
			Args = {"player";};
			Description = "Gives a force field to the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and not v.Character:FindFirstChild("Adonis_Forcefield") then 
						local ff = service.New("ForceField", v.Character) 
						ff.Name = "Adonis_Forcefield"
					end
				end
			end
		};

		UnForcefield = {
			Prefix = Settings.Prefix;
			Commands = {"unff";"unforcefield";};
			Args = {"player";};
			Description = "Removes force fields on the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v.Character then
							for z, cl in pairs(v.Character:children()) do if cl:IsA("ForceField") then cl:Destroy() end end
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
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
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
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
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
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v.Character and v.Character:findFirstChild("HumanoidRootPart") then 
							for a, obj in pairs(v.Character:children()) do 
								if obj:IsA("BasePart") and obj.Name~="HumanoidRootPart" then obj.Anchored = true end
							end
							local ice=service.New("Part",v.Character)
							ice.Color=Color3.fromRGB(205, 238, 255)
							ice.Material="Glass"
							ice.Name="Adonis_Ice"
							ice.Anchored=true
							--ice.CanCollide=false
							ice.TopSurface="Smooth"
							ice.BottomSurface="Smooth"
							ice.FormFactor="Custom"
							ice.Size=Vector3.new(5, 6, 5)
							ice.Reflectance=1
							ice.Transparency=0.5
							ice.CFrame=v.Character.HumanoidRootPart.CFrame
						end
					end)
				end
			end
		};
		
		MultiMusic = {
			Prefix = server.Settings.Prefix;
			Commands = {"multimusic";"multisong";"mmusic";"msong";};
			Args = {"id";"position";"noloop(true/false)";"pitch";"volume"};
			Hidden = false;
			Description = "Start playing a song at a specified position";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and tonumber(args[2]), "Argument missing or nil")
				for i, v in pairs(service.Workspace:GetChildren()) do 
					if v:IsA("Sound") and v.Name == "ADONIS_SOUND_"..args[2] then 
						v:Destroy() 
					end 
				end

				local id = args[1]:lower()
				local looped = args[3]
				local pitch = tonumber(args[4]) or 1
				local mp = service.MarketPlace
				local volume = tonumber(args[5]) or 1
				local name = 'Invalid ID '

				if id ~= "0" and id ~= "off" then
					if looped then
						if looped=="true" then
							looped = false
						else
							looped = true
						end
					else
						looped = true
					end

					for i,v in pairs(server.Variables.MusicList) do 
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

					for i,v in pairs(server.HTTP.Trello.Music) do 
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

					pcall(function() 
						if mp:GetProductInfo(id).AssetTypeId == 3 then 
							name = 'Now playing '..mp:GetProductInfo(id).Name 
						end 
					end)

					local s = service.New("Sound") 
					s.Name = "ADONIS_SOUND_"..args[1]
					s.Parent = service.Workspace
					s.SoundId = "http://www.roblox.com/asset/?id=" .. id 
					s.Volume = volume 
					s.Pitch = pitch 
					s.Looped = looped
					s.Archivable = false
					wait(0.5)
					s:Play()
				--[[if server.Settings.SongHint then
					server.Functions.Hint(name..' ('..id..')',service.Players:GetChildren())
				end]]
				end
			end
		};

		Freeze = {
			Prefix = Settings.Prefix;
			Commands = {"freeze"};
			Args = {"player";};
			Description = "Freezes the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v.Character then
							for a, obj in pairs(v.Character:children()) do
								if obj:IsA("BasePart") and obj.Name~="HumanoidRootPart" then obj.Anchored = true end
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
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
							local ice = v.Character:FindFirstChild("Adonis_Ice")
							local plate
							if ice then
								plate = service.New("Part",v.Character)
								local mesh = service.New("CylinderMesh",plate)
								plate.FormFactor = "Custom"
								plate.TopSurface = "Smooth"
								plate.BottomSurface = "Smooth"
								plate.Size = Vector3.new(0.2,0.2,0.2)
								plate.BrickColor = BrickColor.new("Steel blue")
								plate.Name = "ADONIS_Water"
								plate.Anchored = true
								plate.CanCollide = false
								plate.CFrame = v.Character.HumanoidRootPart.CFrame*CFrame.new(0,-3,0)
								plate.Transparency = ice.Transparency

								for i = 0.2,3,0.2 do
									ice.Size = Vector3.new(5,ice.Size.Y-i,5)
									ice.CFrame = v.Character.HumanoidRootPart.CFrame*CFrame.new(0,-i,0)
									plate.Size = Vector3.new(i+5,0.2,i+5)
									wait()
								end
								ice:Destroy()
							end

							for a, obj in pairs(v.Character:children()) do
								if obj:IsA("BasePart") and obj.Name~="HumanoidRootPart" and obj~=plate then obj.Anchored = false end
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
			Function = function(plr,args)
				local color = Color3.new(1,1,1)
				local secondary = Color3.new(1,0,0)

				if args[2] then
					local str = BrickColor.new('Bright orange').Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
					secondary = str
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso,"Fire",{
							Name = "FIRE";
							Color = color;
							SecondaryColor = secondary;
						})
						Functions.NewParticle(torso,"PointLight",{
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
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso,"FIRE")
						Functions.RemoveParticle(torso,"FIRE_LIGHT")
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
			Function = function(plr,args)
				local color = Color3.new(1,1,1)

				if args[2] then
					local str = BrickColor.new('White').Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso,"Smoke",{
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
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso,"SMOKE")
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
			Function = function(plr,args)
				local color = Color3.new(1,1,1)

				if args[2] then
					local str = BrickColor.new('Cyan').Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso,"Sparkles",{
							Name = "SPARKLES";
							SparkleColor = color;
						})
						Functions.NewParticle(torso,"PointLight",{
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
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso,"SPARKLES")
						Functions.RemoveParticle(torso,"SPARKLES_LIGHT")
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
			Function = function(plr,args)
				if args[1] and not args[2] then args[2] = args[1] args[1] = nil end

				assert(tonumber(args[2]),tostring(args[2]).." is not a valid ID")

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.PlayAnimation(v,args[2])
				end
			end
		};

		AFK = {
			Prefix = Settings.Prefix;
			Commands = {"afk";};
			Args = {"player";};
			Description = "FFs, Gods, Names, Freezes, and removes the target player's tools until they jump.";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						local ff=service.New("ForceField",v.Character)
						local hum=v.Character.Humanoid
						local orig=hum.MaxHealth
						local tools=service.New("Model")
						hum.MaxHealth=math.huge
						wait()
						hum.Health=hum.MaxHealth
						for k,t in pairs(v.Backpack:children()) do
							t.Parent=tools
						end
						Admin.RunCommand(Settings.Prefix.."name",v.Name,"-AFK-_"..v.Name.."_-AFK-")
						local torso=v.Character.HumanoidRootPart
						local pos=torso.CFrame
						local running=true
						local event
						event = v.Character.Humanoid.Jumping:connect(function()
							running = false
							ff:Destroy()
							hum.Health = orig
							hum.MaxHealth = orig
							for k,t in pairs(tools:children()) do
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
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v and v.Character and v.Character:findFirstChild("Humanoid") then
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
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("Humanoid") then
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
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v and v.Character and v.Character:findFirstChild("Humanoid") then
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
			Function = function(plr,args)
				for k,p in pairs(service.GetPlayers(plr,args[1])) do
					for i,v in pairs(p.Character:children()) do
						if v:IsA("Accoutrement") then
							v:Destroy()
						end
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
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing")
				if Admin.CheckAdmin(plr) then
					for i,p in pairs(service.GetPlayers(plr, args[1])) do
						Remote.MakeGui(p,"PrivateMessage",{
							Title = "Message from "..plr.Name;
							Player = plr;
							Message = service.Filter(args[2],plr,p);
						})
					end
				end
			end
		};

		ShowChat = {
			Prefix = Settings.Prefix;
			Commands = {"chat","customchat"};
			Args = {"player"};
			Description = "Opens the custom chat GUI";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Chat",{KeepChat = true})
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
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.RemoveGui(v,"Chat")
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
				if moder>5 then moder=5 end
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(p,"BlurEffect",{
						Name = "WINDOW_BLUR",
						Size = tonumber(args[2]) or 24,
						Enabled = true,
					},"Camera")
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(p,"BloomEffect",{
						Name = "WINDOW_BLOOM",
						Intensity = tonumber(args[2]) or 0.4,
						Size = tonumber(args[3]) or 24,
						Threshold = tonumber(args[4]) or 0.95,
						Enabled = true,
					},"Camera")
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(p,"SunRaysEffect",{
						Name = "WINDOW_SUNRAYS",
						Intensity = tonumber(args[2]) or 0.25,
						Spread = tonumber(args[3]) or 1,
						Enabled = true,
					},"Camera")
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
			Function = function(plr,args)
				local r,g,b = 1,1,1
				if args[5] and args[5]:match("(.*),(.*),(.*)") then
					r,g,b = args[5]:match("(.*),(.*),(.*)")
				end
				r,g,b = tonumber(r),tonumber(g),tonumber(b)
				if not r or not g or not b then error("Invalid Input") end
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(p,"WINDOW_COLORCORRECTION","Camera")
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(p,"WINDOW_SUNRAYS","Camera")
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(p,"WINDOW_BLOOM","Camera")
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(p,"WINDOW_BLUR","Camera")
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(p,"WINDOW_BLUR","Camera")
					Remote.RemoveLocal(p,"WINDOW_BLOOM","Camera")
					Remote.RemoveLocal(p,"WINDOW_THERMAL","Camera")
					Remote.RemoveLocal(p,"WINDOW_SUNRAYS","Camera")
					Remote.RemoveLocal(p,"WINDOW_COLORCORRECTION","Camera")
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.NewLocal(p,"ColorCorrectionEffect",{
						Name = "WINDOW_THERMAL",
						Brightness = 1,
						Contrast = 20,
						Saturation = 20,
						TintColor = Color3.new(0.5,0.2,1);
						Enabled = true,
					},"Camera")
					Remote.NewLocal(p,"BlurEffect",{
						Name = "WINDOW_THERMAL",
						Size = 24,
						Enabled = true,
					},"Camera")
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
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(p,"WINDOW_THERMAL","Camera")
				end
			end
		};

		ShowSBL = {
			Prefix = server.Settings.Prefix;
			Commands = {"sbl";"syncedbanlist";"globalbanlist";"trellobans";"trellobanlist";};
			Args = {};
			Hidden = false;
			Description = "Shows Trello bans";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local blist = {}
				for _,b in ipairs(server.HTTP.Trello.Bans) do
					table.insert(blist, b.ID)
				end
				server.Remote.MakeGui(plr,"List",{
					Title = "Synced Ban List";
					Tab = blist;
				})
			end
		};

		GetPing = {
			Prefix = Settings.Prefix;
			Commands = {"getping";};
			Args = {"player";};
			Hidden = false;
			Description = "Shows the target player's ping (in seconds)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.Hint(v.Name.."'s Ping is "..Remote.Get(v,"Ping").."ms",{plr})
				end
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
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						local tools = {}
						table.insert(tools,{Text="==== "..v.Name.."'s Tools ====",Desc=v.Name:lower()})
						for k,t in pairs(v.Backpack:children()) do
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
			Args = {};
			Hidden = false;
			Description = "Shows you all players currently in-game, including nil ones";
			Fun = false;
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local plrs = {}
				local playz = Functions.GrabNilPlayers('all')
				Functions.Hint('Pinging players. Please wait. No ping = Ping > 5sec.',{plr})
				for i,v in pairs(playz) do
					Routine(function()
						if type(v)=="string" and v=="NoPlayer" then
							table.insert(plrs,{Text="PLAYERLESS CLIENT",Desc="PLAYERLESS SERVERREPLICATOR. COULD BE LOADING/LAG/EXPLOITER. CHECK AGAIN IN A MINUTE!"})
						else
							local ping
							Routine(function()
								ping = Remote.Ping(v).."ms"
							end)
							for i=0.1,5,0.1 do
								if ping then break end
								wait(0.1)
							end
							if v and service.Players:FindFirstChild(v.Name) then
								local h = ""
								local mh = ""
								local ws = ""
								local jp = ""
								local hn = ""
								local hum = (function() return service.Iterate(v.Character,function(v) if v:IsA("Humanoid") then return v end end) end)()
								if v.Character and hum then
									h=hum.Health
									mh=hum.MaxHealth
									ws=hum.WalkSpeed
									jp=hum.JumpPower
									hn=hum.Name
								else
									h="NO CHARACTER/HUMANOID"
								end

								table.insert(plrs,{Text=v.Name.." - "..ping..'s',Desc='Lower: '..v.Name:lower()..' - Health: '..h.." - MaxHealth: "..mh.." - WalkSpeed: "..ws.." - JumpPower: "..jp.." - Humanoid Name: "..hum.Name})
							else
								table.insert(plrs,{Text='[NIL] '..v.Name,Desc='Lower: '..v.Name:lower()..' - Ping: '..ping})
							end
						end
					end)
				end

				for i=0.1,5,0.1 do
					if Functions.CountTable(plrs)>=Functions.CountTable(playz) then break end
					wait(0.1)
				end
				Remote.MakeGui(plr,'List',{Title = 'Players', Tab = plrs, Update = "PlayerList"})
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
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character:FindFirstChild('Humanoid') then
						Remote.Send(plr,'Function','SetView',v.Character.Humanoid)
					end
				end
			end
		};
		
		ResetView = {
			Prefix = Settings.Prefix;
			Commands = {"resetview";"rv";"fixview";"fixcam";"unwatch";"unview"};
			Args = {"optional player"};
			Description = "Resets your view";
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1] then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
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
			Commands = {"details";"meters";"gameinfo";"serverinfo";};
			Args = {};
			Hidden = false;
			Description = "Shows you information about the current server";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local det={}
				local nilplayers=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
						nilplayers=nilplayers+1
					end
				end
				if HTTP.CheckHttp() then
					det.Http='Enabled'
				else
					det.Http='Disabled'
				end
				if pcall(function() loadstring("local hi = 'test'") end) then
					det.Loadstring='Enabled'
				else
					det.Loadstring='Disabled'
				end
				if service.Workspace.FilteringEnabled then
					det.Filtering="Enabled"
				else
					det.Filtering="Disabled"
				end
				if service.Workspace.StreamingEnabled then
					det.Streaming="Enabled"
				else
					det.Streaming="Disabled"
				end
				det.NilPlayers = nilplayers
				det.PlaceName = service.MarketPlace:GetProductInfo(game.PlaceId).Name
				det.PlaceOwner = service.MarketPlace:GetProductInfo(game.PlaceId).Creator.Name
				det.ServerSpeed = service.Round(service.Workspace:GetRealPhysicsFPS())
				--det.AdminVersion = version
				det.ServerStartTime = service.GetTime(server.ServerStartTime)
				local nonnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not Admin.CheckAdmin(v:GetPlayer(),false) then
						nonnumber=nonnumber+1
					end
				end
				det.NonAdmins=nonnumber
				local adminnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and Admin.CheckAdmin(v:GetPlayer(),false) then
						adminnumber=adminnumber+1
					end
				end
				det.CurrentTime=service.GetTime()
				det.ServerAge=service.GetTime(os.time()-server.ServerStartTime)
				det.Admins=adminnumber
				det.Objects=#Variables.Objects
				det.Cameras=#Variables.Cameras

				local tab = {}
				for i,v in pairs(det) do
					table.insert(tab,{Text = i..": "..tostring(v),Desc = tostring(v)})
				end
				Remote.MakeGui(plr,"List",{Title = "Server Details", Tab = tab, Update = "ServerDetails"})
				--Remote.Send(plr,'Function','ServerDetails',det)
			end
		};

		AdminList = {
			Prefix = server.Settings.Prefix;
			Commands = {"admins";"adminlist";"owners";"Moderators";};
			Args = {};
			Hidden = false;
			Description = "Shows you the list of admins, also shows admins that are currently in the server";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local data = {
					Moderators = {};
					Admins = {};
					Owners = {};
					Creators = {};
					InGame = {}
				}

				for i,v in pairs(server.Settings.Creators) do 
					table.insert(data.Creators,v) 
				end

				for i,v in pairs(server.Settings.Owners) do 
					table.insert(data.Owners,v) 
				end

				for i,v in pairs(server.Settings.Admins) do 
					table.insert(data.Admins,v) 
				end

				for i,v in pairs(server.Settings.Moderators) do 
					table.insert(data.Moderators,v) 
				end 

				for i,v in pairs(server.HTTP.Trello.Creators) do 
					table.insert(data.Creators,v .. " [Trello]") 
				end 

				for i,v in pairs(server.HTTP.Trello.Moderators) do 
					table.insert(data.Moderators,v .. " [Trello]") 
				end 

				for i,v in pairs(server.HTTP.Trello.Admins) do 
					table.insert(data.Admins,v .. " [Trello]") 
				end 

				for i,v in pairs(server.HTTP.Trello.Owners) do 
					table.insert(data.Owners,v .. " [Trello]") 
				end

				service.Iterate(server.Settings.CustomRanks,function(rank,tab)
					service.Iterate(tab,function(ind,admin)
						table.insert(data.InGame,admin.." - "..rank) 
					end)
				end)

				for i,v in pairs(service.GetPlayers()) do 
					local level = server.Admin.GetLevel(v)
					if level>=4 then
						table.insert(data.InGame,v.Name..' [Creator]')
					elseif level>=3 then 
						table.insert(data.InGame,v.Name..' [Owner]')
					elseif level>=2 then
						table.insert(data.InGame,v.Name..' [Admin]')
					elseif level>=1 then
						table.insert(data.InGame,v.Name..' [Mod]')
					end
				end

				server.Remote.MakeGui(plr,"AdminLists",data)
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
					table.insert(tab,{Text = tostring(v),Desc = tostring(v)})
				end
				Remote.MakeGui(plr,"List",{Title = 'Ban List', Tab = tab})
			end
		};
		
		FullGod = {
			Prefix = server.Settings.Prefix;
			Commands = {"fullgod"};
			Args = {"player"};
			Filter = true;
			Description = "Completely prevents the player(s) from dying";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				server.Commands.God.Function(plr, args[1] or "me")
				for _,player in ipairs(service.GetPlayers(args[1] or "me")) do
					if player.Character then
						local ff = service.new("ForceField")
						ff.Name = "Adonis_FullGod"
						ff.Visible = false
						ff.Parent = player.Character
					end
				end
			end
		};
		
		UnFullGod = {
			Prefix = server.Settings.Prefix;
			Commands = {"unfullgod"};
			Args = {"player"};
			Filter = true;
			Description = "Reverses a ;fullgod";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				server.Commands.UnGod.Function(plr, args[1] or "me")
				for _,player in ipairs(service.GetPlayers(args[1] or "me")) do
					if player.Character then
						for _,ff in ipairs(player.Character:GetChildren()) do
							if ff.Name == "Adonis_FullGod" then
								ff:Destroy()
							end
						end
					end
				end
			end
		};

		Vote = {
			Prefix = Settings.Prefix;
			Commands = {"vote";"makevote";"startvote";"question";"survey";};
			Args = {"player";"anwser1,answer2,etc (NO SPACES)";"timeout";"question";};
			Filter = true;
			Description = "Lets you ask players a question with a list of answers and get the results";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local timeout = tonumber(args[3]) or 60
				local question = args[4]
				if not question then error("You forgot to supply a question!") end		
				local answers = args[2]
				local anstab = {}
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
					service.Routine(function()
						local response = server.Remote.MakeGuiGet(v,"Vote",{Question = question,Answers = anstab})
						if response then
							table.insert(responses,response)
						end
					end)
				end

				local t = 0
				repeat wait(0.1) t=t+0.1 until t>=timeout or #responses>=#players
				print("done")
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
				print("making")
				server.Remote.MakeGui(plr,"List",{Title = 'Results', Tab = tab})
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

		Insert = {
			Prefix = Settings.Prefix;
			Commands = {"insert";"ins";};
			Args = {"id";};
			Hidden = false;
			Description = "Inserts whatever object belongs to the ID you supply, the object must be in the place owner's or ROBLOX's inventory";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = args[1]:lower()
				for i,v in pairs(Variables.InsertList) do
					if id==v.Name:lower() then
						id = v.ID
						break
					end
				end
				local obj = service.Insert(tonumber(id), true)
				if obj and plr.Character then
					table.insert(Variables.InsertedObjects, obj)
					obj.Parent = service.Workspace
					pcall(function() obj:MakeJoints() end)
					obj:MoveTo(plr.Character:GetModelCFrame().p)
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
				for i,v in pairs(server.Variables.OriginalLightingSettings) do
					if i~="Sky" and service.Lighting[i]~=nil then
						server.Functions.SetLighting(i,v)
					end
				end
				if server.Variables.OriginalLightingSettings.Sky then
					service.Lighting:FindFirstChildWhichIsA("Sky"):Destroy()
					server.Variables.OriginalLightingSettings.Sky:Clone().Parent = service.Lighting
				end
			end
		};
		
		MakePSA = {
			Prefix = server.Settings.Prefix;
			Commands = {"psa";"makepsa";};
			Args = {"message"};
			Description = "Makes a PSA using a chatspeaker";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1], "Argument missing or nil")
				local ChatService = require(game.ServerScriptService.ChatServiceRunner.ChatService)
				local PSA = ChatService:GetSpeaker("PSA")
				if not PSA then
					PSA = ChatService:AddSpeaker("PSA")
					PSA:JoinChannel("All")
				end
				PSA:SayMessage(game:GetService("Chat"):FilterStringForBroadcast(args[1], plr), "All")
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

		Info = {
			Prefix = Settings.Prefix;
			Commands = {"info";"age";};
			Args = {"player";"groupid";};
			Hidden = false;
			Description = "Shows you information about the target player";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local plz = service.GetPlayers(plr, (args[1] and args[1]:lower()) or plr.Name:lower())
				for i,v in pairs(plz) do
					if args[2] and tonumber(args[2]) then
						local role = v:GetRoleInGroup(tonumber(args[2]))
						local hasSafeChat = (not service.Chat:CanUserChatAsync(v.userId) and true) or (service.Chat:FilterStringAsync("C7RN", v, v) == "####") or false
						Functions.Hint("Lower: "..v.Name:lower().." - ID: "..v.userId.." - Age: "..v.AccountAge.." - Safechat: "..tostring(hasSafeChat).." Rank: "..tostring(role),{plr})
					else
						local hasSafeChat = (not service.Chat:CanUserChatAsync(v.userId) and true) or (service.Chat:FilterStringAsync("C7RN", v, v) == "####") or false
						Functions.Hint("Lower: "..v.Name:lower().." - ID: "..v.userId.." - Age: "..v.AccountAge.." - Safechat: "..tostring(hasSafeChat),{plr})
					end
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
						if v and v:findFirstChild("leaderstats") then
							for a,q in pairs(v.leaderstats:children()) do
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
				local gear = service.Insert(tonumber(args[2]))
				if gear:IsA("Tool") or gear:IsA("HopperBin") then
					service.New("StringValue",gear).Name = Variables.CodeName..gear.Name
					for i, v in pairs(service.GetPlayers(plr,args[1])) do
						if v:findFirstChild("Backpack") then
							gear:Clone().Parent = v.Backpack
						end
					end
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
					if built[args[2]:lower()] then
						id = built[args[2]:lower()]
					end
				end
				if not tonumber(id) then error("Invalid ID") end
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local obj = service.Insert(id)
						if obj:IsA("Accoutrement") then
							obj.Parent = v.Character
						end
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
					server.Commands.Fly.Function(p, args, true)
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
											if (torso.Position-origpos).magnitude>3.3 then
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
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _,player in ipairs(service.GetPlayers(plr,args[1] or "me")) do
					if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						coroutine.wrap(function()
							local billboard = server.Deps.Assets.TrackingGUI:Clone()
							billboard.Name = player.Name.."_Tracker"
							billboard.Adornee = player.Character.HumanoidRootPart
							billboard.Username.Text = player.Name
							if not plr.Character.HumanoidRootPart:FindFirstChild("AdonisTrackingAtt") then
								local att = service.New('Attachment')
								att.Name = "AdonisTrackingAtt"
								att.Parent = plr.Character.HumanoidRootPart
							end
							if not player.Character.HumanoidRootPart:FindFirstChild("AdonisTrackingAtt") then
								local att = service.New('Attachment')
								att.Name = "AdonisTrackingAtt"
								att.Parent = player.Character.HumanoidRootPart
							end
							local beam = server.Deps.Assets.TrackBeam:Clone()
							beam.Name = "TrackingBeam"
							beam.Color = ColorSequence.new(player.TeamColor.Color)
							beam.Attachment0 = plr.Character.HumanoidRootPart:FindFirstChild("AdonisTrackingAtt")
							beam.Attachment1 = player.Character.HumanoidRootPart:FindFirstChild("AdonisTrackingAtt")
							beam.Parent = billboard
							server.Remote.RemoveLocal(plr, player.Name.."_Tracker")
							server.Remote.MakeLocal(plr,billboard,false,true)
							server.Variables.TrackTable[plr.UserId][player.UserId] = player
							local event;event = player.CharacterRemoving:connect(function() server.Remote.RemoveLocal(plr,player.Name.."_Tracker") event:Disconnect() server.Variables.TrackTable[plr.UserId][player.UserId] = nil end)
						end)()
					end
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
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _,player in ipairs(service.GetPlayers(plr,args[1] or "me")) do
					coroutine.wrap(function()
						server.Remote.RemoveLocal(plr,player.Name.."_Tracker")
						server.Variables.TrackTable[plr.UserId][player.UserId] = nil
					end)()
				end
			end
		};

		Glitch = {
			Prefix = Settings.Prefix;
			Commands = {"glitch";"glitchdisorient";"glitch1";"glitchy";"gd";};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "Makes the target player(s)'s character teleport back and forth rapidly, quite trippy, makes bricks appear to move as the player turns their character";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 15)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "trippy"
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local new = scr:Clone()
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							new.Parent = torso
							new.Name = "Glitchify"
							new.Disabled = false
						end
					end
				end
			end
		};

		Glitch2 = {
			Prefix = Settings.Prefix;
			Commands = {"ghostglitch";"glitch2";"glitchghost";"gg";};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "The same as gd but less trippy, teleports the target player(s) back and forth in the same direction, making two ghost like images of the game";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 150)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "ghost"
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local new = scr:Clone()
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							new.Parent = torso
							new.Name = "Glitchify"
							new.Disabled = false
						end
					end
				end
			end
		};

		Vibrate = {
			Prefix = Settings.Prefix;
			Commands = {"vibrate";"glitchvibrate";"gv";};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "Kinda like gd, but teleports the player to four points instead of two";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 0.1)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "vibrate"
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local new = scr:Clone()
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							local scr = torso:FindFirstChild("Glitchify")
							if scr then scr:Destroy() end
							new.Parent = torso
							new.Name = "Glitchify"
							new.Disabled = false
						end
					end
				end
			end
		};

		UnGlitch = {
			Prefix = Settings.Prefix;
			Commands = {"unglitch";"unglitchghost";"ungd";"ungg";"ungv";"unvibrate";};
			Args = {"player";};
			Hidden = false;
			Description = "UnGlitchs the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						local scr = torso:FindFirstChild("Glitchify")
						if scr then
							scr:Destroy()
						end
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
					if v and v:findFirstChild("Backpack") then
						for a,q in pairs(game.StarterPack:children()) do
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
							cl.Parent = game.Workspace
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

							for d,e in pairs(v.Character:children()) do
								if e:IsA"Accessory" then
									e:Destroy()
								end
							end

							local cl = target_humandescrip:Clone()
							cl.Parent = v.Character:FindFirstChildOfClass("Humanoid")
							pcall(function() v.Character:FindFirstChildOfClass("Humanoid"):ApplyDescription(cl) end)

							for d,e in pairs(target_character:children()) do
								if e:IsA"Accessory" then
									e:Clone().Parent = v.Character
								end
							end
						end
					end)
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
						for k,p in pairs(v.Character:children()) do
							if p:IsA('BodyColors') or p:IsA('CharacterMesh') or p:IsA('Pants') or p:IsA('Shirt') or p:IsA('Accessory') then
								p.Parent=tempcloths
							elseif p:IsA('Tool') then
								p.Parent=temptools
							end
						end
						for k,p in pairs(v.Backpack:children()) do
							p.Parent=temptools
						end
						for k,p in pairs(v2.Character:children()) do
							if p:IsA('BodyColors') or p:IsA('CharacterMesh') or p:IsA('Pants') or p:IsA('Shirt') or p:IsA('Accessory') then
								p.Parent=v.Character
							elseif p:IsA('Tool') then
								p.Parent=v.Backpack
							end
						end
						for k,p in pairs(tempcloths:children()) do
							p.Parent=v2.Character
						end
						for k,p in pairs(v2.Backpack:children()) do
							p.Parent=v.Backpack
						end
						for k,p in pairs(temptools:children()) do
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
						local w3 = service.New("Weld", plr.Character:findFirstChild("Right Arm"))
						w3.Part0 = plr.Character:findFirstChild("Right Arm")
						w3.Part1 = v.Character:findFirstChild("Right Arm")
						local w4 = service.New("Weld", plr.Character:findFirstChild("Left Arm"))
						w4.Part0 = plr.Character:findFirstChild("Left Arm")
						w4.Part1 = v.Character:findFirstChild("Left Arm")
						local w5 = service.New("Weld", plr.Character:findFirstChild("Right Leg"))
						w5.Part0 = plr.Character:findFirstChild("Right Leg")
						w5.Part1 = v.Character:findFirstChild("Right Leg")
						local w6 = service.New("Weld", plr.Character:findFirstChild("Left Leg"))
						w6.Part0 = plr.Character:findFirstChild("Left Leg")
						w6.Part1 = v.Character:findFirstChild("Left Leg")
						plr.Character.Head.face:Destroy()
						for i, p in pairs(v.Character:children()) do
							if p:IsA("BasePart") then
								p.CanCollide = false
							end
						end
						for i, p in pairs(plr.Character:children()) do
							if p:IsA("BasePart") then
								p.Transparency = 1
							elseif p:IsA("Accoutrement") then
								p:Destroy()
							end
						end
						v.Character.Parent = plr.Character
						--v.Character.Humanoid.Changed:connect(function() v.Character.Humanoid.PlatformStand = true end)
					end
				end
			end
		};

		Refresh = {
			Prefix = Settings.Prefix;
			Commands = {"refresh";"reset";};
			Args = {"player";};
			Hidden = false;
			Description = "Refreshes the target player(s)'s character";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local pos = v.Character.HumanoidRootPart.CFrame
					local temptools = {}

					pcall(function() v.Character.Humanoid:UnequipTools() end)
					for k,t in pairs(v.Backpack:children()) do
						if t:IsA('Tool') or t:IsA('HopperBin') then
							table.insert(temptools,t)
							t.Parent = nil;
						end
					end

					v:LoadCharacter()
					wait(0.1)
					v.Character.HumanoidRootPart.CFrame = pos

					for d,f in pairs(v.Character:children()) do
						if f:IsA('ForceField') then f:Destroy() end
					end

					v:WaitForChild("Backpack")
					v.Backpack:ClearAllChildren()

					for l,m in pairs(temptools) do
						m.Parent = v.Backpack
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
					v.Character:BreakJoints()
				end
			end
		};

		Respawn = {
			Prefix = Settings.Prefix;
			Commands = {"respawn";"re"};
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
			Description = "Rotates the target player(s) by 180 degrees or the angle you server";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local angle = 130 or args[2]
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
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
					if v.Character and v.Character:findFirstChild("Humanoid") then
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
					if v.Character and v.Character:findFirstChild("Humanoid") then
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
								if obj:findFirstChild("face") then
									obj.face.Transparency = 1
								end
							elseif obj:IsA("Accoutrement") and obj:findFirstChild("Handle") then
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
								if obj:findFirstChild("face") then
									obj.face.Transparency = 0
								end
							elseif obj:IsA("Accoutrement") and obj:findFirstChild("Handle") then
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
						for a, obj in pairs(v.Character:children()) do
							if obj:IsA("BasePart") then
								obj.Locked = true
							elseif obj:IsA("Accoutrement") and obj:findFirstChild("Handle") then
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
						for a, obj in pairs(v.Character:children()) do
							if obj:IsA("BasePart") then
								obj.Locked = false
							elseif obj:IsA("Accoutrement") and obj:findFirstChild("Handle") then
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
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then 
						local ex = service.New("Explosion", game.Workspace)
						ex.ExplosionType = "NoCraters" 
						ex.Position = v.Character.HumanoidRootPart.Position
						ex.BlastRadius = args[2] or 20
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

		HatPets = {
			Prefix = Settings.Prefix;
			Commands = {"hatpets";};
			Args = {"player";"number[50 MAX]/destroy";};
			Hidden = false;
			Description = "Gives the target player(s) hat pets, controled using the !pets command.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if args[2] and args[2]:lower()=='destroy' then
						local hats = v.Character:FindFirstChild('ADONIS_HAT_PETS')
						if hats then hats:Destroy() end
					else
						local num = tonumber(args[2]) or 5
						if num>50 then num = 50 end
						if v.Character:FindFirstChild('HumanoidRootPart') then
							local m = v.Character:FindFirstChild('ADONIS_HAT_PETS')
							local mode
							local obj
							local hat
							if not m then
								m = service.New('Model',v.Character)
								m.Name = 'ADONIS_HAT_PETS'
								table.insert(Variables.Objects,m)
								mode = service.New('StringValue',m)
								mode.Name = 'Mode'
								mode.Value = 'Follow'
								obj = service.New('ObjectValue',m)
								obj.Name = 'Target'
								obj.Value = v.Character.HumanoidRootPart

								local scr = Deps.Assets.HatPets:Clone()
								scr.Parent = m
								scr.Disabled = false
							else
								mode = m.Mode
								obj = m.Target
							end

							for l,h in pairs(v.Character:children()) do
								if h:IsA('Accessory') then
									hat = h
									break
								end
							end

							if hat then
								for k = 1,num do
									local cl = hat.Handle:clone()
									cl.Name = k
									cl.CanCollide = false
									cl.Anchored = false
									cl.Parent = m
									cl:BreakJoints()
									local att = cl:FindFirstChild("HatAttachment")
									if att then att:Destroy() end
									local bpos = service.New("BodyPosition",cl)
									bpos.Name = 'bpos'
									bpos.position = obj.Value.Position
									bpos.maxForce = bpos.maxForce * 10
								end
							end
						end
					end
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
					if v:findFirstChild("StarterGear") then
						for a,tool in pairs(v.StarterGear:children()) do
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
		
		StarterGear = {
			Prefix = server.Settings.Prefix;
			Commands = {"startergear";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Places the desired gear into the target player(s)'s StarterPack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local gear = service.Insert(tonumber(args[2]))
				if gear:IsA("Tool") or gear:IsA("HopperBin") then 
					service.New("StringValue",gear).Name = server.Variables.CodeName..gear.Name 
					for i, v in pairs(service.GetPlayers(plr,args[1])) do
						if v:findFirstChild("StarterGear") then
							gear:Clone().Parent = v.StarterGear 
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
						for j,n in pairs(v.Backpack:children()) do
							local b = n:clone()
							n.Parent = m.Backpack
						end
					end
					v.Backpack:ClearAllChildren()
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
			Prefix = server.Settings.Prefix;
			Commands = {"removetools";"notools";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove the target player(s)'s tools";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v:findFirstChild("Backpack") then 
						local Arms = {v.Character:FindFirstChild("Left Arm"), v.Character:FindFirstChild("Right Arm")}
						local Torso = v.Character:FindFirstChild("Torso")
						for a, tool in pairs(v.Character:children()) do if tool:IsA("Tool") or tool:IsA("HopperBin") then tool:Destroy() end end
						for a, tool in pairs(v.Backpack:children()) do if tool:IsA("Tool") or tool:IsA("HopperBin") then tool:Destroy() end end
						if v.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
							if Arms[1] ~= nil and Arms[2] ~= nil and Torso ~= nil then
								local Shoulders = {Torso:FindFirstChild("Left Shoulder"), Torso:FindFirstChild("Right Shoulder")}
								if Shoulders[1] ~= nil and Shoulders[2] ~= nil then
									local Yes = true
									if Yes then
										Yes = false
										Shoulders[1].Part1 = Arms[1]
										Shoulders[2].Part1 = Arms[2]
										for _,wd in ipairs(v.Character.Torso:GetChildren()) do
											if wd:IsA("Weld") then
												wd:Destroy()
											end
										end
									end
								else
									error("Shoulders for RigType: R6 are missing")
								end
							else
								error("Arms for RigType: R6 are missing")
							end
						end
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

		RestoreGravity = {
			Prefix = Settings.Prefix;
			Commands = {"grav";"bringtoearth";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s)'s gravity normal";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a, frc in pairs(v.Character.HumanoidRootPart:children()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy() end
						end
					end
				end
			end
		};

		SetGravity = {
			Prefix = Settings.Prefix;
			Commands = {"setgrav";"gravity";"setgravity";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Set the target player(s)'s gravity";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a, frc in pairs(v.Character.HumanoidRootPart:children()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy()
							end
						end

						local frc = service.New("BodyForce", v.Character.HumanoidRootPart)
						frc.Name = "ADONIS_GRAVITY"
						frc.force = Vector3.new(0,0,0)
						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") then
								frc.force = frc.force - Vector3.new(0,prt:GetMass()*tonumber(args[2]),0)
							elseif prt:IsA("Accoutrement") then
								frc.force = frc.force - Vector3.new(0,prt.Handle:GetMass()*tonumber(args[2]),0)
							end
						end
					end
				end
			end
		};

		NoGravity = {
			Prefix = Settings.Prefix;
			Commands = {"nograv";"nogravity";"superjump";};
			Args = {"player";};
			Hidden = false;
			Description = "NoGrav the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v and v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a, frc in pairs(v.Character.HumanoidRootPart:children()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy()
							end
						end

						local frc = service.New("BodyForce", v.Character.HumanoidRootPart)
						frc.Name = "ADONIS_GRAVITY"
						frc.force = Vector3.new(0,0,0)
						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") then
								frc.force = frc.force + Vector3.new(0,prt:GetMass()*196.25,0)
							elseif prt:IsA("Accoutrement") then
								frc.force = frc.force + Vector3.new(0,prt.Handle:GetMass()*196.25,0)
							end
						end
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
					if v and v.Character and v.Character:findFirstChild("Humanoid") then
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
			Description = "Set the target player(s)'s JumpPower to <number>";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("Humanoid") then
						v.Character.Humanoid.JumpPower = args[2] or 60
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
					if v.Character and v.Character:findFirstChild("Humanoid") then
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
					for a, tm in pairs(service.Teams:children()) do
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
			Prefix = server.Settings.Prefix;
			Commands = {"unteam","removefromteam", "neutral"};
			Args = {"player"};
			Description = "Takes the target player(s) off of a team and sets them to 'Neutral' ";
			Hidden = false;
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _,player in ipairs(server.Functions.GetPlayers(plr, args[1])) do
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
			Fun = true;
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
				local servers = server.Core.GetData("PrivateServers") or {}
				local code = servers[args[2]]	
				if code then
					for i,v in pairs(players) do
						Routine(function()
							local tp = server.Remote.MakeGuiGet(v,"Notification",{
								Title = "Teleport",
								Text = "Click to teleport to server "..args[2]..".",
								Time = 30,
								OnClick = server.Core.Bytecode("return true")
							})	
							if tp then 
								service.TeleportService:TeleportToPrivateServer(code.ID,code.Code,{v})
							end
						end)
					end
				elseif id then		
					for i,v in pairs(players) do
						server.Remote.MakeGui(v,"Notification",{
							Title = "Teleport",
							Text = "Click to teleport to place "..game:GetService("MarketplaceService"):GetProductInfo(args[2]).Name..".",
							Time = 30,
							OnClick = server.Core.Bytecode("service.TeleportService:Teleport("..args[2]..")")
						})		
					end
				else
					server.Functions.Hint("Invalid place ID/server name",{plr})
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

		BunnyHop = {
			Prefix = Settings.Prefix;
			Commands = {"bunnyhop";"bhop"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the player jump, and jump... and jump. Just like the rabbit noobs you find in sf games ;)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local bunnyScript = Deps.Assets.BunnyHop
				bunnyScript.Name = "HippityHopitus"
				local hat = service.Insert(110891941)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					hat:Clone().Parent = v.Character
					local clone = bunnyScript:Clone()
					clone.Parent = v.Character
					clone.Disabled = false
				end
			end
		};

		UnBunnyHop = {
			Prefix = Settings.Prefix;
			Commands = {"unbunnyhop";};
			Args = {"player";};
			Hidden = false;
			Description = "Stops the forced hippity hoppening";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local scrapt = v.Character:FindFirstChild("HippityHopitus")
					if scrapt then
						scrapt.Disabled = true
						scrapt:Destroy()
					end
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
							v.Character:MoveTo(point)
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
						v.Character:MoveTo(Vector3.new(tonumber(x),tonumber(y),tonumber(z)))
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

		FreeFall = {
			Prefix = Settings.Prefix;
			Commands = {"freefall";"skydive";};
			Args = {"player";"height";};
			Hidden = false;
			Description = "Teleport the target player(s) up by <height> studs";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character:FindFirstChild('HumanoidRootPart') then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame+Vector3.new(0,tonumber(args[2]),0)
					end
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
					if v:findFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:children()) do
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
					if v:findFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:children()) do
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
					if v:findFirstChild("leaderstats") then
						for a, st in pairs(v.leaderstats:children()) do
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
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					--local image=GetTexture(args[2])
					if not v.Character:FindFirstChild("Head") then
						return
					end

					if v.Character and v.Character:findFirstChild("Head") and v.Character.Head:findFirstChild("face") then
						v.Character.Head:findFirstChild("face"):Destroy()--.Texture = "http://www.roblox.com/asset/?id=" .. args[2]
					end

					service.Insert(tonumber(args[2])).Parent = v.Character:FindFirstChild("Head")
				end
			end
		};

		Swagify = {
			Prefix = Settings.Prefix;
			Commands = {"swagify";"swagger";};
			Args = {"player";};
			Hidden = false;
			Description = "Swag the target player(s) up";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for i,v in pairs(v.Character:children()) do
							if v.Name == "Shirt" then local cl = v:Clone() cl.Parent = v.Parent cl.ShirtTemplate = "http://www.roblox.com/asset/?id=109163376" v:Destroy() end
							if v.Name == "Pants" then local cl = v:Clone() cl.Parent = v.Parent cl.PantsTemplate = "http://www.roblox.com/asset/?id=109163376" v:Destroy() end
						end
						Functions.Cape(v,false,'Fabric','Pink',109301474)
					end
				end
			end
		};

		Shrek = {
			Prefix = Settings.Prefix;
			Commands = {"shrek";"shrekify";"shrekislife";"swamp";};
			Args = {"player";};
			Hidden = false;
			Description = "Shrekify the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							Admin.RunCommand(Settings.Prefix.."pants",v.Name,"233373970")
							Admin.RunCommand(Settings.Prefix.."shirt",v.Name,"133078195")

							for i,v in pairs(v.Character:children()) do
								if v:IsA("Accoutrement") or v:IsA("CharacterMesh") then
									v:Destroy()
								end
							end

							Admin.RunCommand(Settings.Prefix.."hat",v.Name,"20011951")

							local sound = service.New("Sound",v.Character.HumanoidRootPart)
							sound.SoundId = "http://www.roblox.com/asset/?id="..130767645
							wait(0.5)
							sound:Play()
						end
					end)
				end
			end
		};

		Rocket = {
			Prefix = Settings.Prefix;
			Commands = {"rocket";"firework";};
			Args = {"player";};
			Hidden = false;
			Description = "Send the target player(s) to the moon!";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							local knownchar = v.Character
							local speed = 10
							local Part = service.New("Part")
							Part.Parent = v.Character
							local SpecialMesh = service.New("SpecialMesh")
							SpecialMesh.Parent = Part
							SpecialMesh.MeshId = "http://www.roblox.com/asset/?id=2251534"
							SpecialMesh.MeshType = "FileMesh"
							SpecialMesh.TextureId = "43abb6d081e0fbc8666fc92f6ff378c1"
							SpecialMesh.Scale = Vector3.new(0.5,0.5,0.5)
							local Weld = service.New("Weld")
							Weld.Parent = Part
							Weld.Part0 = Part
							Weld.Part1 = v.Character.HumanoidRootPart
							Weld.C0 = CFrame.new(0,-1,0)*CFrame.Angles(-1.5,0,0)
							local BodyVelocity = service.New("BodyVelocity")
							BodyVelocity.Parent = Part
							BodyVelocity.maxForce = Vector3.new(math.huge,math.huge,math.huge)
							BodyVelocity.velocity = Vector3.new(0,100*speed,0)
									--[[
									cPcall(function()
										for i = 1,math.huge do
											local Explosion = service.New("Explosion")
											Explosion.Parent = Part
											Explosion.BlastRadius = 0
											Explosion.Position = Part.Position + Vector3.new(0,0,0)
											wait()
										end
									end)
									--]]
							wait(5)
							BodyVelocity:remove()
							if knownchar.Parent then
								service.New("Explosion",service.Workspace).Position = knownchar.HumanoidRootPart.Position
								knownchar:BreakJoints()
							end
						end
					end)
				end
			end
		};

		Dance = {
			Prefix = Settings.Prefix;
			Commands = {"dance";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.PlayAnimation(v,27789359)
				end
			end
		};

		BreakDance = {
			Prefix = Settings.Prefix;
			Commands = {"breakdance";"fundance";"lolwut";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) break dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						local color
						local num=math.random(1,7)
						if num==1 then
							color='Really blue'
						elseif num==2 then
							color='Really red'
						elseif num==3 then
							color='Magenta'
						elseif num==4 then
							color='Lime green'
						elseif num==5 then
							color='Hot pink'
						elseif num==6 then
							color='New Yeller'
						elseif num==7 then
							color='White'
						end
						local hum=v.Character:FindFirstChild('Humanoid')
						if not hum then return end
						--Remote.Send(v,'Function','Effect','dance')
						Admin.RunCommand(Settings.Prefix.."sparkles",v.Name,color)
						Admin.RunCommand(Settings.Prefix.."fire",v.Name,color)
						Admin.RunCommand(Settings.Prefix.."nograv",v.Name)
						Admin.RunCommand(Settings.Prefix.."smoke",v.Name,color)
						Admin.RunCommand(Settings.Prefix.."spin",v.Name)
						repeat hum.PlatformStand=true wait() until not hum or hum==nil or hum.Parent==nil
					end)
				end
			end
		};

		Puke = {
			Prefix = Settings.Prefix;
			Commands = {"puke";"barf";"throwup";"vomit";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) puke";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					cPcall(function()
						if (not v:IsA('Player')) or (not v) or (not v.Character) or (not v.Character:FindFirstChild('Head')) or v.Character:FindFirstChild('Epix Puke') then return end
						local run=true
						local k=service.New('StringValue',v.Character)
						k.Name='Epix Puke'
						Routine(function()
							repeat
								wait(0.15)
								local p = service.New("Part",v.Character)
								p.CanCollide = false
								local color = math.random(1, 3)
								local bcolor
								if color == 1 then
									bcolor = BrickColor.new(192)
								elseif color == 2 then
									bcolor = BrickColor.new(28)
								elseif color == 3 then
									bcolor = BrickColor.new(105)
								end
								p.BrickColor = bcolor
								local m = service.New('BlockMesh',p)
								p.Size = Vector3.new(0.1,0.1,0.1)
								m.Scale = Vector3.new(math.random()*0.9, math.random()*0.9, math.random()*0.9)
								p.Locked = true
								p.TopSurface = "Smooth"
								p.BottomSurface = "Smooth"
								p.CFrame = v.Character.Head.CFrame * CFrame.new(Vector3.new(0, 0, -1))
								p.Velocity = v.Character.Head.CFrame.lookVector * 20 + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
								p.Anchored = false
								m.Name = 'Puke Peice'
								p.Name = 'Puke Peice'
								p.Touched:connect(function(o)
									if o and p and (not service.Players:FindFirstChild(o.Parent.Name)) and o.Name~='Puke Peice' and o.Name~='Blood Peice' and o.Name~='Blood Plate' and o.Name~='Puke Plate' and (o.Parent.Name=='Workspace' or o.Parent:IsA('Model')) and (o.Parent~=p.Parent) and o:IsA('Part') and (o.Parent.Name~=v.Character.Name) and (not o.Parent:IsA('Accessory')) and (not o.Parent:IsA('Tool')) then
										local cf = CFrame.new(p.CFrame.X,o.CFrame.Y+o.Size.Y/2,p.CFrame.Z)
										p:Destroy()
										local g=service.New('Part',service.Workspace)
										g.Anchored=true
										g.CanCollide=false
										g.Size=Vector3.new(0.1,0.1,0.1)
										g.Name='Puke Plate'
										g.CFrame=cf
										g.BrickColor=BrickColor.new(119)
										local c=service.New('CylinderMesh',g)
										c.Scale=Vector3.new(1,0.2,1)
										c.Name='PukeMesh'
										wait(10)
										g:Destroy()
									elseif o and o.Name=='Puke Plate' and p then
										p:Destroy()
										o.PukeMesh.Scale=o.PukeMesh.Scale+Vector3.new(0.5,0,0.5)
									end
								end)
							until run==false or not k or not k.Parent or (not v) or (not v.Character) or (not v.Character:FindFirstChild('Head'))
						end)
						wait(10)
						run = false
						k:Destroy()
					end)
				end
			end
		};

		Cut = {
			Prefix = Settings.Prefix;
			Commands = {"cut";"stab";"shank";"bleed";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) bleed";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					cPcall(function()
						if (not v:IsA('Player')) or (not v) or (not v.Character) or (not v.Character:FindFirstChild('Head')) or v.Character:FindFirstChild('Epix Bleed') then return end
						local run=true
						local k=service.New('StringValue',v.Character)
						k.Name='ADONIS_BLEED'
						Routine(function()
							repeat
								wait(0.15)
								v.Character.Humanoid.Health=v.Character.Humanoid.Health-1
								local p = service.New("Part",v.Character)
								p.CanCollide = false
								local color = math.random(1, 3)
								local bcolor
								if color == 1 then
									bcolor = BrickColor.new(21)
								elseif color == 2 then
									bcolor = BrickColor.new(1004)
								elseif color == 3 then
									bcolor = BrickColor.new(21)
								end
								p.BrickColor = bcolor
								local m=service.New('BlockMesh',p)
								p.Size=Vector3.new(0.1,0.1,0.1)
								m.Scale = Vector3.new(math.random()*0.9, math.random()*0.9, math.random()*0.9)
								p.Locked = true
								p.TopSurface = "Smooth"
								p.BottomSurface = "Smooth"
								p.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(Vector3.new(2, 0, 0))
								p.Velocity = v.Character.Head.CFrame.lookVector * 1 + Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))
								p.Anchored = false
								m.Name='Blood Peice'
								p.Name='Blood Peice'
								p.Touched:connect(function(o)
									if not o or not o.Parent then return end
									if o and p and (not service.Players:FindFirstChild(o.Parent.Name)) and o.Name~='Blood Peice' and o.Name~='Puke Peice' and o.Name~='Puke Plate' and o.Name~='Blood Plate' and (o.Parent.Name=='Workspace' or o.Parent:IsA('Model')) and (o.Parent~=p.Parent) and o:IsA('Part') and (o.Parent.Name~=v.Character.Name) and (not o.Parent:IsA('Accessory')) and (not o.Parent:IsA('Tool')) then
										local cf=CFrame.new(p.CFrame.X,o.CFrame.Y+o.Size.Y/2,p.CFrame.Z)
										p:Destroy()
										local g=service.New('Part',service.Workspace)
										g.Anchored=true
										g.CanCollide=false
										g.Size=Vector3.new(0.1,0.1,0.1)
										g.Name='Blood Plate'
										g.CFrame=cf
										g.BrickColor=BrickColor.new(21)
										local c=service.New('CylinderMesh',g)
										c.Scale=Vector3.new(1,0.2,1)
										c.Name='BloodMesh'
										wait(10)
										g:Destroy()
									elseif o and o.Name=='Blood Plate' and p then
										p:Destroy()
										o.BloodMesh.Scale=o.BloodMesh.Scale+Vector3.new(0.5,0,0.5)
									end
								end)
							until run==false or not k or not k.Parent or (not v) or (not v.Character) or (not v.Character:FindFirstChild('Head'))
						end)
						wait(10)
						run=false
						k:Destroy()
					end)
				end
			end
		};

		Poison = {
			Prefix = Settings.Prefix;
			Commands = {"poison";};
			Args = {"player";};
			Hidden = false;
			Description = "Slowly kills the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						local torso=v.Character:FindFirstChild('HumanoidRootPart')
						local larm=v.Character:FindFirstChild('Left Arm')
						local rarm=v.Character:FindFirstChild('Right Arm')
						local lleg=v.Character:FindFirstChild('Left Leg')
						local rleg=v.Character:FindFirstChild('Right Leg')
						local head=v.Character:FindFirstChild('Head')
						local hum=v.Character:FindFirstChild('Humanoid')
						if torso and larm and rarm and lleg and rleg and head and hum and not v.Character:FindFirstChild('EpixPoisoned') then
							local poisoned=service.New('BoolValue',v.Character)
							poisoned.Name='EpixPoisoned'
							poisoned.Value=true
							local tor=torso.BrickColor
							local lar=larm.BrickColor
							local rar=rarm.BrickColor
							local lle=lleg.BrickColor
							local rle=rleg.BrickColor
							local hea=head.BrickColor
							torso.BrickColor=BrickColor.new('Br. yellowish green')
							larm.BrickColor=BrickColor.new('Br. yellowish green')
							rarm.BrickColor=BrickColor.new('Br. yellowish green')
							lleg.BrickColor=BrickColor.new('Br. yellowish green')
							rleg.BrickColor=BrickColor.new('Br. yellowish green')
							head.BrickColor=BrickColor.new('Br. yellowish green')
							local run=true
							coroutine.wrap(function() wait(10) run=false end)()
							repeat
								wait(1)
								hum.Health=hum.Health-5
							until (not poisoned) or (not poisoned.Parent) or (not run)
							if poisoned and poisoned.Parent then
								torso.BrickColor=tor
								larm.BrickColor=lar
								rarm.BrickColor=rar
								lleg.BrickColor=lle
								rleg.BrickColor=rle
								head.BrickColor=hea
							end
						end
					end)
				end
			end
		};

		TargetAudio = {
			Prefix = Settings.Prefix;
			Commands = {"taudio";"localsound";"localaudio";"lsound";"laudio";};
			Args = {"player";"audioId";};
			Description = "Lets you play an audio on the player's client";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if not tonumber(args[2]) then error(args[1].." is not a valid ID") return end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","PlayAudio",args[2])
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

		Pitch = {
			Prefix = Settings.Prefix;
			Commands = {"pitch";};
			Args = {"number";};
			Description = "Change the pitch of the currently playing song";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local pitch = args[1]
				for i,v in pairs(service.Workspace:children()) do 
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
				for i,v in pairs(service.Workspace:children()) do 
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
			Commands = {"music";"song";"playsong";};
			Args = {"id";"noloop(true/false)";"pitch";"volume"};
			Hidden = false;
			Description = "Start playing a song";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.Workspace:GetChildren()) do
					if v:IsA("Sound") and v.Name == "ADONIS_SOUND" then
						v:Destroy()
					end
				end

				local id = args[1]:lower()
				local looped = args[2]
				local pitch = tonumber(args[3]) or 1
				local mp = service.MarketPlace
				local volume = tonumber(args[4]) or 1
				local name = 'Invalid ID '

				if id ~= "0" and id ~= "off" then
					if looped then
						if looped=="true" then
							looped = false
						else
							looped = true
						end
					else
						looped = true
					end

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

					pcall(function()
						if mp:GetProductInfo(id).AssetTypeId == 3 then
							name = 'Now playing '..mp:GetProductInfo(id).Name
						end
					end)

					local s = service.New("Sound")
					s.Name = "ADONIS_SOUND"
					s.Parent = service.Workspace
					s.SoundId = "http://www.roblox.com/asset/?id=" .. id
					s.Volume = volume
					s.Pitch = pitch
					s.Looped = looped
					s.Archivable = false
					wait(0.5)
					s:Play()

					if name == "Invalid ID" then
						error("Invalid ID")
					elseif Settings.SongHint then
						Functions.Hint(name, service.Players:GetPlayers())
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
					if string.find(v.Name, "ADONIS_SOUND") then
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

		Stickify = {
			Prefix = Settings.Prefix;
			Commands = {"stickify";"stick";"stickman";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns the target player(s) into a stick figure";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for kay,player in pairs(service.GetPlayers(plr,args[1])) do
					local m = player.Character
					for i,v in pairs(m:GetChildren()) do
						if v:IsA("Part") then
							local s = service.New("SelectionPartLasso")
							s.Parent = m.HumanoidRootPart
							s.Part = v
							s.Humanoid = m.Humanoid
							s.Color = BrickColor.new(0,0,0)
							v.Transparency = 1
							m.Head.Transparency = 0
							m.Head.Mesh:Remove()
							local b = service.New("SpecialMesh")
							b.Parent = m.Head
							b.MeshType = "Sphere"
							b.Scale = Vector3.new(0.5,1,1)
							m.Head.BrickColor = BrickColor.new("Black")
						end
					end
				end
			end
		};

		Hole = {
			Prefix = Settings.Prefix;
			Commands = {"hole";"sparta";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends the target player(s) down a hole";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for kay, player in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						local torso = player.Character:FindFirstChild('HumanoidRootPart')
						if torso then
							local hole = service.New("Part",player.Character)
							hole.Anchored = true
							hole.CanCollide = false
							hole.formFactor = Enum.FormFactor.Custom
							hole.Size = Vector3.new(10,1,10)
							hole.CFrame = torso.CFrame * CFrame.new(0,-3.3,-3)
							hole.BrickColor = BrickColor.new("Really black")
							local holeM = service.New("CylinderMesh",hole)
							torso.Anchored = true
							local foot = torso.CFrame * CFrame.new(0,-3,0)
							for i=1,10 do
								torso.CFrame = foot * CFrame.fromEulerAnglesXYZ(-(math.pi/2)*i/10,0,0) * CFrame.new(0,3,0)
								wait(0.1)
							end
							for i=1,5,0.2 do
								torso.CFrame = foot * CFrame.new(0,-(i^2),0) * CFrame.fromEulerAnglesXYZ(-(math.pi/2),0,0) * CFrame.new(0,3,0)
								wait()
							end
							player.Character:BreakJoints()
						end
					end)
				end
			end
		};

		Lightning = {
			Prefix = Settings.Prefix;
			Commands = {"lightning";"smite";};
			Args = {"player";};
			Hidden = false;
			Description = "Zeus strikes down the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						Admin.RunCommand(Settings.Prefix.."freeze",v.Name)
						local char = v.Character
						local zeus = service.New("Model",char)
						local cloud = service.New("Part",zeus)
						cloud.Anchored = true
						cloud.CanCollide = false
						cloud.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0,25,0)
						local sound = service.New("Sound",cloud)
						sound.SoundId = "rbxassetid://133426162"
						local mesh = service.New("SpecialMesh",cloud)
						mesh.MeshId = "http://www.roblox.com/asset/?id=1095708"
						mesh.TextureId = "http://www.roblox.com/asset/?id=1095709"
						mesh.Scale = Vector3.new(30,30,40)
						mesh.VertexColor = Vector3.new(0.3,0.3,0.3)
						local light = service.New("PointLight",cloud)
						light.Color = Color3.new(0,85/255,1)
						light.Brightness = 10
						light.Range = 30
						light.Enabled = false
						wait(0.2)
						sound.Volume = 0.5
						sound.Pitch = 0.8
						sound:Play()
						light.Enabled = true
						wait(1/100)
						light.Enabled = false
						wait(0.2)
						light.Enabled = true
						light.Brightness = 1
						wait(0.05)
						light.Brightness = 3
						wait(0.02)
						light.Brightness = 1
						wait(0.07)
						light.Brightness = 10
						wait(0.09)
						light.Brightness = 0
						wait(0.01)
						light.Brightness = 7
						light.Enabled = false
						wait(1.5)
						local part1 = service.New("Part",zeus)
						part1.Anchored = true
						part1.CanCollide = false
						part1.Size = Vector3.new(2, 9.2, 1)
						part1.BrickColor = BrickColor.new("New Yeller")
						part1.Transparency = 0.6
						part1.BottomSurface = "Smooth"
						part1.TopSurface = "Smooth"
						part1.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0,15,0)
						part1.Rotation = Vector3.new(0.359, 1.4, -14.361)
						wait()
						local part2 = part1:clone()
						part2.Parent = zeus
						part2.Size = Vector3.new(1, 7.48, 2)
						part2.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0,7.5,0)
						part2.Rotation = Vector3.new(77.514, -75.232, 78.051)
						wait()
						local part3 = part1:clone()
						part3.Parent = zeus
						part3.Size = Vector3.new(1.86, 7.56, 1)
						part3.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0,1,0)
						part3.Rotation = Vector3.new(0, 0, -11.128)
						sound.SoundId = "rbxassetid://130818250"
						sound.Volume = 1
						sound.Pitch = 1
						sound:Play()
						wait()
						part1.Transparency = 1
						part2.Transparency = 1
						part3.Transparency = 1
						service.New("Smoke",char.HumanoidRootPart).Color = Color3.new(0,0,0)
						char:BreakJoints()
					end)
				end
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
						server.Functions.Hint("You are now flying. Press E - Toggle Flight, R - Increase Speed, F - Decrease Speed", {v}, 5)
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

		Disco = {
			Prefix = Settings.Prefix;
			Commands = {"disco";};
			Args = {};
			Hidden = false;
			Description = "Turns the place into a disco party";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				service.StopLoop("LightingTask")
				service.StartLoop("LightingTask",0.5,function()
					local color = Color3.new(math.random(255)/255,math.random(255)/255,math.random(255)/255)
					Functions.SetLighting("Ambient",color)
					Functions.SetLighting("OutdoorAmbient",color)
					Functions.SetLighting("FogColor",color)
				end)
			end
		};

		Spin = {
			Prefix = Settings.Prefix;
			Commands = {"spin";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) spin";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = Deps.Assets.Spinner:Clone()
				scr.Name = "SPINNER"
				local bg = Instance.new("BodyGyro")
				bg.Name = "SPINNER_GYRO"
				bg.maxTorque = Vector3.new(0,math.huge,0)
				bg.P = 11111
				bg.D = 0
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a,q in pairs(v.Character.HumanoidRootPart:children()) do
							if q.Name == "SPINNER" or q.Name == "SPINNER_GYRO" then
								q:Destroy()
							end
						end
						local gyro = bg:Clone()
						gyro.cframe = v.Character.HumanoidRootPart.CFrame
						gyro.Parent = v.Character.HumanoidRootPart
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end
			end
		};

		UnSpin = {
			Prefix = Settings.Prefix;
			Commands = {"unspin";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) stop spinning";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a,q in pairs(v.Character.HumanoidRootPart:children()) do
							if q.Name == "SPINNER" or q.Name == "SPINNER_GYRO" then
								q:Destroy()
							end
						end
					end
				end
			end
		};

		Dog = {
			Prefix = Settings.Prefix;
			Commands = {"dog";"dogify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a dog";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(p,args)
				for i,plr in pairs(service.GetPlayers(p,args[1])) do
					--Routine(function()
					if (plr and plr.Character and plr.Character:FindFirstChild"HumanoidRootPart") then
						local human = plr.Character:FindFirstChildOfClass"Humanoid"

						if not human then
							Remote.MakeGui(p,'Output',{Title = 'Output'; Message = plr.Name.." doesn't have a Humanoid [Transformation Error]"})
							return
						end

						if human.RigType == Enum.HumanoidRigType.R6 then
							if plr.Character:FindFirstChild"Shirt" then
								plr.Character.Shirt.Parent = plr.Character.HumanoidRootPart
							end
							if plr.Character:FindFirstChild"Pants" then
								plr.Character.Pants.Parent = plr.Character.HumanoidRootPart
							end
							local char, torso, ca1, ca2 = plr.Character, plr.Character:FindFirstChild"Torso" or plr.Character:FindFirstChild"UpperTorso", CFrame.Angles(0, math.rad(90), 0), CFrame.Angles(0, math.rad(-90), 0)
							local head = char:FindFirstChild"Head"

							torso.Transparency = 1

							for i,v in next,torso:GetChildren() do
								if v:IsA'Motor6D' then
									local lc0 = service.New('CFrameValue', {Name='LastC0';Value=v.C0;Parent=v})
								end
							end

							torso.Neck.C0 = CFrame.new(0, -.5, -2) * CFrame.Angles(math.rad(90), math.rad(180), 0)

							torso["Right Shoulder"].C0 = CFrame.new(.5, -1.5, -1.5) * ca1
							torso["Left Shoulder"].C0 = CFrame.new(-.5, -1.5, -1.5) * ca2
							torso["Right Hip"].C0 = CFrame.new(1.5, -1, 1.5) * ca1
							torso["Left Hip"].C0 = CFrame.new(-1.5, -1, 1.5) * ca2
							local st = service.New("Seat", {
								Name = "Adonis_Torso",
								FormFactor = 0,
								TopSurface = 0,
								BottomSurface = 0,
								Size = Vector3.new(3, 1, 4),
							})

							local bf = service.New("BodyForce", {Force = Vector3.new(0, 2e3, 0), Parent = st})

							st.CFrame = torso.CFrame
							st.Parent = char 	

							local weld = service.New("Weld", {Parent = st, Part0 = torso, Part1 = st, C1 = CFrame.new(0, .5, 0)})

							for d,e in next, char:GetDescendants() do
								if e:IsA"BasePart" then
									e.BrickColor = BrickColor.new("Brown")
								end
							end
						elseif human.RigType == Enum.HumanoidRigType.R15 then
							Remote.MakeGui(p,'Output',{Title = 'Output'; Message = "Cannot support R15 for "..plr.Name.." [Dog Transformation Error]"})
						end
					end
					--end)
				end
			end
		};

		Dogg = {
			Prefix = Settings.Prefix;
			Commands = {"dogg";"snoop";"snoopify";"dodoubleg";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns the target into the one and only D O Double G";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Dogg:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)
				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=131396137"
				decal1.Name = "Snoop"

				cl.Name = "Animator"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"
				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://137545053"
				sound.Looped = true

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Sp00ky = {
			Prefix = Settings.Prefix;
			Commands = {"sp00ky";"spooky";"spookyscaryskeleton";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends shivers down ur spine";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Sp00ks:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)
				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=183747890"
				decal1.Name = "Snoop"

				cl.Name = "Animator"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"
				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://174270407"
				sound.Looped = true

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		K1tty = {
			Prefix = Settings.Prefix;
			Commands = {"k1tty";"cut3";};
			Args = {"player";};
			Hidden = false;
			Description = "2 cute 4 u";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Kitty:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)
				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=280224764"
				decal1.Name = "Snoop"

				cl.Name = "Animator"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"
				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://179393562"
				sound.Looped = true

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Nyan = {
			Prefix = Settings.Prefix;
			Commands = {"nyan";"p0ptart"};
			Args = {"player";};
			Hidden = false;
			Description = "Poptart kitty";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Nyan1:Clone()
				local c2 = Deps.Assets.Nyan2:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(0.1,4.8,20)

				local decal1 = service.New("Decal")
				decal1.Face = "Left"
				decal1.Texture = "http://www.roblox.com/asset/?id=332277963"
				decal1.Name = "Nyan"
				local decal2=decal1:clone()
				decal2.Face = "Right"
				decal2.Texture = "http://www.roblox.com/asset/?id=332288373"

				cl.Name = "Animator"
				c2.Name = "Animator"

				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://265125691"
				sound.Looped = true

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

					cl:Clone().Parent = decal1
					c2:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Fr0g = {
			Prefix = Settings.Prefix;
			Commands = {"fr0g";"fr0ggy";"mlgfr0g";"mlgfrog";};
			Args = {"player";};
			Hidden = false;
			Description = "MLG fr0g";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Fr0g:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)
				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=185945467"
				decal1.Name = "Fr0g"

				cl.Name = "Animator"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"

				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://149690685"
				sound.Looped = true

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Sh1a = {
			Prefix = Settings.Prefix;
			Commands = {"sh1a";"lab00f";"sh1alab00f";"shia"};
			Args = {"player";};
			Hidden = false;
			Description = "Sh1a LaB00f";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Shia:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)

				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=286117283"
				decal1.Name = "Shia"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"

				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://259702986"
				sound.Looped = true

				cl.Name = "Animator"

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};
		
		NewTeam = {
			Prefix = server.Settings.Prefix;
			Commands = {"newteam","createteam","maketeam"};
			Args = {"name";"BrickColor";};
			Hidden = false;
			Description = "Make a new team with the specified name and color";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local color = BrickColor.new(math.random(1,227))
				if BrickColor.new(args[2])~=nil then color=BrickColor.new(args[2]) end
				local team = service.New("Team", service.Teams)
				team.Name = args[1]
				team.AutoAssignable = false
				team.TeamColor = color
				Variables.Variables.TeamBindings[team.Name] = {}
				if team.Name:lower() == "dead" or team.Name:lower() == "noncontestant" or team.Name:lower() == "non-contestant" or team.Name:lower() == "killed" then
					Variables.Variables.TeamBindings[team.Name][1] = game.Players.PlayerAdded:Connect(function(player)
						player.Team = team
					end)
					for _,player in ipairs(service.GetPlayers()) do
						if player.Team ~= team then
							Variables.Variables.TeamBindings[team.Name][player.UserId] = player.CharacterAdded:Connect(function()
								if player.Team ~= team then
									player.Team = team
								end
							end)
						end
					end
				elseif team.Name:lower() == "contestant" or team.Name:lower() == "contestants" or team.Name:lower() == "survivor" or team.Name:lower() == "survivors" then
					Variables.Variables.TeamBindings[team.Name][1] = team.PlayerAdded:Connect(function(player)
						if Variables.Variables.TeamBindings[team.Name][player.UserId] then return end
						Variables.Variables.TeamBindings[team.Name][player.UserId] = player.CharacterAdded:Connect(function()
							if player.Team == team then
								local deadTeam = false
								for _,t in ipairs(game:GetService("Teams"):GetChildren()) do
									if t.Name:lower() == "dead" or t.Name:lower() == "noncontestant" or t.Name:lower() == "non-contestant" or t.Name:lower() == "killed" then
										deadTeam = t
										break
									end
								end
								if deadTeam then
									player.Team = deadTeam
								else
									server.Commands.Unteam.Function(player, {"me"})
								end
							end
						end)
					end)
				end
			end
		};
		
		RemoveTeam = {
			Prefix = server.Settings.Prefix;
			Commands = {"removeteam";};
			Args = {"names";};
			Hidden = false;
			Description = "Remove the specified team(s) or all teams if none are specified";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1] ~= nil then
					for i,v in pairs(service.Teams:children()) do
						for rteam in string.gmatch(args[1], "[^,]+,?") do
							local team = rteam:match("[^,]+")
							if v:IsA("Team") and v.Name:lower():sub(1,#team)==team:lower() then
								v:Destroy()
								for _,bind in pairs(Variables.TeamBindings[v.Name]) do
									bind:Disconnect()
								end
								Variables.TeamBindings[v.Name] = nil
							end
						end
					end
				else
					for i,v in pairs(service.Teams:children()) do
						if v:IsA("Team") then
							v:Destroy()
							for _,bind in pairs(Variables.TeamBindings[v.Name]) do
								bind:Disconnect()
							end
							Variables.TeamBindings[v.Name] = nil
						end
					end
				end
			end
		};
		
		MassBring = {
			Prefix = server.Settings.Prefix;
			Commands = {"massbring";};
			Args = {"player","lines"};
			Hidden = false;
			Description = "Similar to ;bring, but it evenly positions players to prevent flinging";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local players = args[1] and service.GetPlayers(plr, args[1]) or service.GetPlayers(plr, "me")
				local lines = (tonumber(args[2]) and math.clamp(tonumber(args[2]), 1, #players)) or 1
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
						--if n.Character.Humanoid.Sit then
						--	n.Character.Humanoid.Sit = false
						--	wait(0.5)
						--end
						player.Character.Humanoid.Jump = true
						wait()
						if player.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("HumanoidRootPart") then
							local offsetZ = ((i-1) - (l-1)*math.floor(#players/lines))*2
							player.Character.HumanoidRootPart.CFrame = (plr.Character.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(90),0)*CFrame.new(5+offsetZ,0,offsetX))*CFrame.Angles(0,math.rad(90),0)
						end
					end
				end
				if #players%lines ~= 0 then
					for i = lines*math.floor(#players/lines)+1, lines*math.floor(#players/lines) + #players%lines do
						local r = i % (lines*math.floor(#players/lines))
						local offsetX = 0
						if r == 1 then
							offsetX = 0
						elseif r % 2 == 1 then
							offsetX = -(math.ceil((r - 2)/2)*4)
						else
							offsetX = (math.ceil(r / 2))*4
						end
						local player = players[i]
						--if n.Character.Humanoid.Sit then
						--	n.Character.Humanoid.Sit = false
						--	wait(0.5)
						--end
						player.Character.Humanoid.Jump = true
						wait()
						if player.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("HumanoidRootPart") then
							local offsetZ = (math.floor(#players/lines))*2
							player.Character.HumanoidRootPart.CFrame = (plr.Character.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(90),0)*CFrame.new(5+offsetZ,0,offsetX))*CFrame.Angles(0,math.rad(90),0)
						end
					end
				end
			end
		};
		
		Stretch = {
			Prefix = server.Settings.Prefix;
			Commands = {"stretch";"height"};
			Arguments = {"player";"optional num"};
			Description = "Modifies a player's height (R15)";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local num = tonumber(args[2]) or 0.1
				for _,p in ipairs(service.GetPlayers(plr, args[1])) do
					if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
						p.Character.Humanoid.BodyHeightScale.Value = num
					end
				end
			end
		};
		
		Widen = {
			Prefix = server.Settings.Prefix;
			Commands = {"widen";"width"};
			Arguments = {"player";"optional num"};
			Description = "Modifies a player's width (R15)";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local num = tonumber(args[2]) or 0.1
				for _,p in ipairs(service.GetPlayers(plr, args[1])) do
					if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
						p.Character.Humanoid.BodyWidthScale.Value = num
					end
				end
			end
		};
		
		--[[Trail = {
			Prefix = Settings.Prefix;
			Commands = {"trail", "trails"};
			Args = {"player", "textureid"};
			Description = "Adds trails to the target's character's parts";
			AdminLevel = "Moderators";
			Fun = true;
			Function = function(plr, args)
				assert(args[1], "Player argument missing")
				local newTrail = service.New("Trail", {
					Color = (args[2] and (args[2]:lower() == "truecolors" or args[2]:lower() == "rainbow") and ColorSequence.new(Color3.new(1, 0, 0), Color3.fromRGB(255, 136, 0), Color3.fromRGB(255, 228, 17), Color3.fromRGB(135, 255, 7), Color3.fromRGB(11, 255, 207), Color3.fromRGB(10, 46, 255), Color3.fromRGB(255, 55, 255), Color3.fromRGB(170, 0, 127)));
					Texture = args[2] and "rbxassetid://"..args[2];
					TextureMode = "Stretch";
					TextureLength = 2;
					Name = "ADONIS_TRAIL";
				})

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					for k,p in next,char:GetChildren() do
						if p:IsA("BasePart") then
							Functions.RemoveParticle(p,"ADONIS_CMD_TRAIL")
							Functions.NewParticle(p,"Trail",{
								Color = (args[2] and (args[2]:lower() == "truecolors" or args[2]:lower() == "rainbow") and ColorSequence.new(Color3.new(1, 0, 0), Color3.fromRGB(255, 136, 0), Color3.fromRGB(255, 228, 17), Color3.fromRGB(135, 255, 7), Color3.fromRGB(11, 255, 207), Color3.fromRGB(10, 46, 255), Color3.fromRGB(255, 55, 255), Color3.fromRGB(170, 0, 127)));
								Texture = tonumber(args[2]) and "rbxassetid://"..args[2];
								TextureMode = "Stretch";
								TextureLength = 2;
								Name = "ADONIS_CMD_TRAIL";
							})
						end
					end
				end
			end;
		};--]]

		UnParticle = {
			Prefix = Settings.Prefix;
			Commands = {"unparticle";"removeparticles";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes particle emitters from target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "PARTICLE")
					end
				end
			end
		};

		Particle = {
			Prefix = Settings.Prefix;
			Commands = {"particle";};
			Args = {"player";"textureid";"startColor3";"endColor3";};
			Hidden = false;
			Description = "Put custom particle emitter on target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if not args[2] then error("Missing texture") end
				local startColor = {}
				local endColor = {}
				local startc = Color3.new(1,1,1)
				local endc = Color3.new(1,1,1)

				if args[3] then
					for s in args[3]:gmatch("[%d]+")do
						table.insert(startColor,tonumber(s))
					end
				end

				if args[4] then--276138620 :)
					for s in args[4]:gmatch("[%d]+")do
						table.insert(endColor,tonumber(s))
					end
				end

				if #startColor==3 then
					startc = Color3.new(startColor[1],startColor[2],startColor[3])
				end

				if #endColor==3 then
					endc = Color3.new(endColor[1],endColor[2],endColor[3])
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso,"ParticleEmitter",{
							Name = "PARTICLE";
							Texture = 'rbxassetid://'..args[2]; --Functions.GetTexture(args[1]);
							Size = NumberSequence.new({
								NumberSequenceKeypoint.new(0,0);
								NumberSequenceKeypoint.new(.1,.25,.25);
								NumberSequenceKeypoint.new(1,.5);
							});
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0,1);
								NumberSequenceKeypoint.new(.1,.25,.25);
								NumberSequenceKeypoint.new(.9,.5,.25);
								NumberSequenceKeypoint.new(1,1);
							});
							Lifetime = NumberRange.new(5);
							Speed = NumberRange.new(.5,1);
							Rotation = NumberRange.new(0,359);
							RotSpeed = NumberRange.new(-90,90);
							Rate = 11;
							VelocitySpread = 180;
							Color = ColorSequence.new(startc,endc);
						})
					end
				end
			end
		};

		OldFlatten = {
			Prefix = Settings.Prefix;
			Commands = {"oldflatten";"o2d";"oflat";};
			Args = {"player";"optional num";};
			Hidden = false;
			Description = "Old Flatten. Went lazy on this one.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						for k,p in pairs(v.Character:children()) do
							if p:IsA("Part") then
								if p:FindFirstChild("Mesh") then p.Mesh:Destroy() end
								service.New("BlockMesh",p).Scale=Vector3.new(1,1,args[2] or 0.1)
							elseif p:IsA("Accoutrement") and p:FindFirstChild("Handle") then
								if p.Handle:FindFirstChild("Mesh") then
									p.Handle.Mesh.Scale=Vector3.new(1,1,args[2] or 0.1)
								else
									service.New("BlockMesh",p.Handle).Scale=Vector3.new(1,1,args[2] or 0.1)
								end
							elseif p:IsA("CharacterMesh") then
								p:Destroy()
							end
						end
					end)
				end
			end
		};

		Sticky = {
			Prefix = Settings.Prefix;
			Commands = {"sticky";};
			Args = {"player";};
			Hidden = false;
			Description = "Sticky";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local event
					local torso = v.Character.HumanoidRootPart
					event = v.Character.HumanoidRootPart.Touched:connect(function(p)
						if torso and torso.Parent and not p:IsDescendantOf(v.Character) and not p.Locked then
							Functions.MakeWeld(torso,p)
						elseif not torso or not torso.Parent then
							event:disconnect()
						end
					end)
				end
			end
		};

		Break = {
			Prefix = Settings.Prefix;
			Commands = {"break";};
			Args = {"player";"optional num";};
			Hidden = false;
			Description = "Break the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						if v.Character then
							local head = v.Character.Head
							local torso = v.Character.HumanoidRootPart
							local larm = v.Character['Left Arm']
							local rarm = v.Character['Right Arm']
							local lleg = v.Character['Left Leg']
							local rleg = v.Character['Right Leg']
							for i,v in pairs(v.Character:children()) do if v:IsA("Part") then v.Anchored=true end end
							torso.FormFactor="Custom"
							torso.Size=Vector3.new(torso.Size.X,torso.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=v.Character.HumanoidRootPart
							weld.C0=v.Character.HumanoidRootPart.CFrame
							head.FormFactor="Custom"
							head.Size=Vector3.new(head.Size.X,head.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=head
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(0,1.5,0)
							larm.FormFactor="Custom"
							larm.Size=Vector3.new(larm.Size.X,larm.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=larm
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(-1,0,0)
							rarm.FormFactor="Custom"
							rarm.Size=Vector3.new(rarm.Size.X,rarm.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=rarm
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(1,0,0)
							lleg.FormFactor="Custom"
							lleg.Size=Vector3.new(larm.Size.X,larm.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=lleg
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(-1,-1.5,0)
							rleg.FormFactor="Custom"
							rleg.Size=Vector3.new(larm.Size.X,larm.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=rleg
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(1,-1.5,0)
							wait()
							for i,v in pairs(v.Character:children()) do if v:IsA("Part") then v.Anchored=false end end
						end
					end)
				end
			end
		};

		Skeleton = {
			Prefix = Settings.Prefix;
			Commands = {"skeleton";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a skeleton";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local hat = service.Insert(36883367)
				local players = service.GetPlayers(plr,args[1])
				for i,v in pairs(players) do
					for k,m in pairs(v.Character:children()) do
						if m:IsA("CharacterMesh") or m:IsA("Accoutrement") then
							m:Destroy()
						end
					end
					hat:Clone().Parent = v.Character
				end
				if #players > 0 then
					-- This is done outside of the for loop above as the Package command inserts all package items each time the command is run 
					-- By only running it once, it's only inserting the items once and therefore reducing overhead
					local t = {}
					for _,v in pairs(players) do 
						table.insert(t, v.Name) 
					end
					Admin.RunCommand(Settings.Prefix.."package "..table.concat(t,",").." 295")
				end
			end
		};

		Creeper = {
			Prefix = Settings.Prefix;
			Commands = {"creeper";"creeperify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a creeper";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
							local joints = Functions.GetJoints(v.Character)

							if v.Character:findFirstChild("Shirt") then v.Character.Shirt.Parent = v.Character.HumanoidRootPart end
							if v.Character:findFirstChild("Pants") then v.Character.Pants.Parent = v.Character.HumanoidRootPart end

							if joints["Neck"] then 
								joints["Neck"].C0 = isR15 and CFrame.new(0, 1, 0) or (CFrame.new(0,1,0) * CFrame.Angles(math.rad(90),math.rad(180),0))
							end

							local rarm = isR15 and joints["RightShoulder"] or joints["Right Shoulder"]
							if rarm then 
								rarm.C0 = isR15 and CFrame.new(-1, -1.5, -0.5) or (CFrame.new(0,-1.5,-.5) * CFrame.Angles(0,math.rad(90),0))
							end

							local larm = isR15 and joints["LeftShoulder"] or joints["Left Shoulder"]
							if larm then 
								larm.C0 = isR15 and CFrame.new(1, -1.5, -0.5) or (CFrame.new(0,-1.5,-.5) * CFrame.Angles(0,math.rad(-90),0))
							end 

							local rleg = isR15 and joints["RightHip"] or joints["Right Hip"]
							if rleg then 
								rleg.C0 = isR15 and (CFrame.new(-0.5,-0.5,0.5) * CFrame.Angles(0, math.rad(180), 0)) or (CFrame.new(0,-1,.5) * CFrame.Angles(0,math.rad(90),0))
							end 

							local lleg = isR15 and joints["LeftHip"] or joints["Left Hip"]
							if lleg then
								lleg.C0 = isR15 and (CFrame.new(0.5,-0.5,0.5) * CFrame.Angles(0, math.rad(180), 0)) or (CFrame.new(0,-1,.5) * CFrame.Angles(0,math.rad(-90),0))
							end 

							for a, part in pairs(v.Character:children()) do 
								if part:IsA("BasePart") then 
									part.BrickColor = BrickColor.new("Bright green") 
									if part.Name == "FAKETORSO" then 
										part:Destroy() 
									end 
								elseif part:findFirstChild("NameTag") then 
									part.Head.BrickColor = BrickColor.new("Bright green") 
								end
							end
						end
					end
				end
			end
		};

		BigHead = {
			Prefix = Settings.Prefix;
			Commands = {"bighead";};
			Args = {"player", "num"};
			Hidden = false;
			Description = "Give the target player(s) a larger ego";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						local char = v.Character;
						local human = char and char:FindFirstChildOfClass("Humanoid");

						if human then 
							if human.RigType == Enum.HumanoidRigType.R6 then 
								v.Character.Head.Mesh.Scale = Vector3.new(1.75,1.75,1.75)
								v.Character.Torso.Neck.C0 = CFrame.new(0,1.3,0) * CFrame.Angles(math.rad(90),math.rad(180),0)
							else 
								local scale = human and human:FindFirstChild("HeadScale");
								if scale then
									scale.Value = tonumber(args[2]) or 1.5;
								end
							end 
						end
					end
				end
			end
		};

		SmallHead = {
			Prefix = Settings.Prefix;
			Commands = {"smallhead";"minihead";};
			Args = {"player", "num"};
			Hidden = false;
			Description = "Give the target player(s) a small head";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						local char = v.Character;
						local human = char and char:FindFirstChildOfClass("Humanoid");

						if human then 
							if human.RigType == Enum.HumanoidRigType.R6 then 
								v.Character.Head.Mesh.Scale = Vector3.new(.75,.75,.75)
								v.Character.Torso.Neck.C0 = CFrame.new(0,.8,0) * CFrame.Angles(math.rad(90),math.rad(180),0)
							else 
								local scale = human and human:FindFirstChild("HeadScale");
								if scale then
									scale.Value = tonumber(args[2]) or 0.5;
								end
							end 
						end
					end
				end
			end
		};

		Resize = {
			Prefix = Settings.Prefix;
			Commands = {"resize";"size";};
			Args = {"player";"mult";};
			Hidden = false;
			Description = "Resize the target player(s)'s character by <mult>";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if tonumber(args[2])>50 then 
					args[2] = 50 
				end

				local num = tonumber(args[2])	

				local function sizePlayer(p)
					local char = p.Character
					if char.Humanoid.RigType == Enum.HumanoidRigType.R6 then
						local torso = char:FindFirstChild("Torso")
						local root = char:FindFirstChild("HumanoidRootPart")
						local welds = {}

						torso.Anchored = true
						torso.BottomSurface = 0
						torso.TopSurface = 0

						for i,v in pairs(char:GetChildren()) do
							if v:IsA("BasePart") then
								v.Anchored = true
							end
						end

						local function size(part)
							for i,v in pairs(part:GetChildren()) do
								if (v:IsA("Weld") or v:IsA("Motor") or v:IsA("Motor6D")) and v.Part1 and v.Part1:IsA("Part") then
									local p1 = v.Part1
									local c0 = {v.C0:components()}
									local c1 = {v.C1:components()}

									for i = 1,3 do
										c0[i] = c0[i]*num
										c1[i] = c1[i]*num
									end

									p1.Anchored = true
									v.Part1 = nil

									v.C0 = CFrame.new(unpack(c0)) 
									v.C1 = CFrame.new(unpack(c1))

									if p1.Name ~= 'Head' and p1.Name ~= 'Torso' then
										p1.formFactor = 3
										p1.Size = p1.Size*num
									elseif p1.Name ~= 'Torso' then
										p1.Anchored = true
										for k,m in pairs(p1:children()) do 
											if m:IsA('Weld') then 
												m.Part0 = nil 
												m.Part1.Anchored = true 
											end 
										end

										p1.formFactor = 3 
										p1.Size = p1.Size*num

										for k,m in pairs(p1:children()) do 
											if m:IsA('Weld') then 
												m.Part0 = p1 
												m.Part1.Anchored = false 
											end 
										end
									end

									if v.Parent == torso then 
										p1.BottomSurface = 0 
										p1.TopSurface = 0 
									end

									p1.Anchored = false
									v.Part1 = p1

									if v.Part0 == torso then 
										table.insert(welds,v) 
										p1.Anchored = true 
										v.Part0 = nil 
									end
								elseif v:IsA('CharacterMesh') then
									local bp = tostring(v.BodyPart):match('%w+.%w+.(%w+)')
									local msh = service.New('SpecialMesh')
								elseif v:IsA('SpecialMesh') and v.Parent ~= char.Head then 
									v.Scale = v.Scale*num
								end 
								size(v)
							end
						end

						size(char)

						torso.formFactor = 3
						torso.Size = torso.Size*num

						for i,v in pairs(welds) do 
							v.Part0 = torso 
							v.Part1.Anchored = false 
						end

						for i,v in pairs(char:GetChildren()) do 
							if v:IsA('BasePart') then 
								v.Anchored = false 
							end 
						end

						local weld = service.New('Weld',root) 
						weld.Part0 = root 
						weld.Part1 = torso

						local cape = char:findFirstChild("ADONIS_CAPE")
						if cape then
							cape.Size = cape.Size*num
						end
					else
						if char:FindFirstChild("Humanoid") then
							if char.Humanoid:FindFirstChild("BodyDepthScale") then
								char.Humanoid.BodyDepthScale.Value = num
							else
								local scl = service.New("NumberValue", char.Humanoid)
								scl.Name = "BodyDepthScale"
								scl.Value = num
							end
							if char.Humanoid:FindFirstChild("BodyHeightScale") then
								char.Humanoid.BodyHeightScale.Value = num
							else
								local scl = service.New("NumberValue", char.Humanoid)
								scl.Name = "BodyHeightScale"
								scl.Value = num
							end
							if char.Humanoid:FindFirstChild("BodyWidthScale") then
								char.Humanoid.BodyWidthScale.Value = num
							else
								local scl = service.New("NumberValue", char.Humanoid)
								scl.Name = "BodyWidthScale"
								scl.Value = num
							end
							if char.Humanoid:FindFirstChild("HeadScale") then
								char.Humanoid.HeadScale.Value = num
							else
								local scl = service.New("NumberValue", char.Humanoid)
								scl.Name = "HeadScale"
								scl.Value = num
							end
						end
					end
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					sizePlayer(v)
				end
			end
		};
		
		HeadScale = {
			Prefix = server.Settings.Prefix;
			Commands = {"headscale"};
			Arguments = {"player";"optional num"};
			Description = "Modifies a player's head size (R15)";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local num = tonumber(args[2]) or 0.1
				for _,p in ipairs(service.GetPlayers(plr, args[1])) do
					if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
						p.Character.Humanoid.HeadScale.Value = num
					end
				end
			end
		};
		
		Flatten = {
			Prefix = server.Settings.Prefix;
			Commands = {"flatten";"2d";"flat";"depth"};
			Args = {"player";"optional num";};
			Hidden = false;
			Description = "Flatten.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tonumber(args[2]) or 0.1	

				local function sizePlayer(p)
					local char = p.Character
					if char.Humanoid.RigType == Enum.HumanoidRigType.R6 then
						local torso = char:FindFirstChild("Torso")
						local root = char:FindFirstChild("HumanoidRootPart")
						local welds = {}

						torso.Anchored = true
						torso.BottomSurface = 0
						torso.TopSurface = 0

						for i,v in pairs(char:GetChildren()) do
							if v:IsA("BasePart") then
								v.Anchored = true
							end
						end

						local function size(part)
							for i,v in pairs(part:GetChildren()) do
								if (v:IsA("Weld") or v:IsA("Motor") or v:IsA("Motor6D")) and v.Part1 and v.Part1:IsA("Part") then
									local p1 = v.Part1
									local c0 = {v.C0:components()}
									local c1 = {v.C1:components()}

									c0[3] = c0[3]*num
									c1[3] = c1[3]*num

									p1.Anchored = true
									v.Part1 = nil

									v.C0 = CFrame.new(unpack(c0)) 
									v.C1 = CFrame.new(unpack(c1))

									if p1.Name ~= 'Head' and p1.Name ~= 'Torso' then
										p1.formFactor = 3
										p1.Size = Vector3.new(p1.Size.X,p1.Size.Y,num)
									elseif p1.Name ~= 'Torso' then
										p1.Anchored = true
										for k,m in pairs(p1:children()) do 
											if m:IsA('Weld') then 
												m.Part0 = nil 
												m.Part1.Anchored = true 
											end 
										end

										p1.formFactor = 3 
										p1.Size = Vector3.new(p1.Size.X,p1.Size.Y,num)

										for k,m in pairs(p1:children()) do 
											if m:IsA('Weld') then 
												m.Part0 = p1 
												m.Part1.Anchored = false 
											end 
										end
									end

									if v.Parent == torso then 
										p1.BottomSurface = 0 
										p1.TopSurface = 0 
									end

									p1.Anchored = false
									v.Part1 = p1

									if v.Part0 == torso then 
										table.insert(welds,v) 
										p1.Anchored = true 
										v.Part0 = nil 
									end
								elseif v:IsA('CharacterMesh') then
									local bp = tostring(v.BodyPart):match('%w+.%w+.(%w+)')
									local msh = service.New('SpecialMesh')
								elseif v:IsA('SpecialMesh') and v.Parent ~= char.Head then 
									v.Scale = Vector3.new(v.Scale.X,v.Scale.Y,num)
								end 
								size(v)
							end
						end

						size(char)

						torso.formFactor = 3
						torso.Size = Vector3.new(torso.Size.X,torso.Size.Y,num)

						for i,v in pairs(welds) do 
							v.Part0 = torso 
							v.Part1.Anchored = false 
						end

						for i,v in pairs(char:GetChildren()) do 
							if v:IsA('BasePart') then 
								v.Anchored = false 
							end 
						end

						local weld = service.New('Weld',root) 
						weld.Part0 = root 
						weld.Part1 = torso

						local cape = char:findFirstChild("ADONIS_CAPE")
						if cape then
							cape.Size = cape.Size*num
						end
					else
						char.Humanoid.BodyDepthScale.Value = num
					end
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					sizePlayer(v)
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
						if v.Character and v.Character:findFirstChild("HumanoidRootPart") and v.Character:findFirstChild("Humanoid") then
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

		Seizure = {
			Prefix = Settings.Prefix;
			Commands = {"seizure";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character spazz out on the floor";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = Deps.Assets.Seize
				scr.Name = "Seize"
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character:FindFirstChild('HumanoidRootPart') then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(90),0,0)
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end
			end
		};

		UnSeizure = {
			Prefix = Settings.Prefix;
			Commands = {"unseizure";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the effects of the seizure command";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") then
						local old = v.Character.HumanoidRootPart:FindFirstChild("Seize")
						if old then old:Destroy() end
						v.Character.Humanoid.PlatformStand = false
					end
				end
			end
		};

		RemoveLimbs = {
			Prefix = Settings.Prefix;
			Commands = {"removelimbs";"delimb";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove the target player(s)'s arms and legs";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for a, obj in pairs(v.Character:children()) do
							if obj:IsA("BasePart") and (obj.Name:find("Leg") or obj.Name:find("Arm")) then
								obj:Destroy()
							end
						end
					end
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
					if v.Character and v.Character:findFirstChild("Head") then
						for a, mod in pairs(v.Character:children()) do
							if mod:findFirstChild("NameTag") then
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
							v.Character.Humanoid.Changed:connect(function(c)
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
					if v.Character and v.Character:findFirstChild("Head") then
						for a, mod in pairs(v.Character:children()) do
							if mod:findFirstChild("NameTag") then
								v.Character.Head.Transparency = 0
								mod:Destroy()
							end
						end
					end
				end
			end
		};

		RightLeg = {
			Prefix = Settings.Prefix;
			Commands = {"rleg";"rightleg";"rightlegpackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Right Leg package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=31 then
					error('ID is not a right leg!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		LeftLeg = {
			Prefix = Settings.Prefix;
			Commands = {"lleg";"leftleg";"leftlegpackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Left Leg package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=30 then
					error('ID is not a left leg!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		RightArm = {
			Prefix = Settings.Prefix;
			Commands = {"rarm";"rightarm";"rightarmpackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Right Arm package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id=service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=28 then
					error('ID is not a right arm!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		LeftArm = {
			Prefix = Settings.Prefix;
			Commands = {"larm";"leftarm";"leftarmpackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Left Arm package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=29 then
					error('ID is not a left arm!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		Torso = {
			Prefix = Settings.Prefix;
			Commands = {"torso";"torsopackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Left Arm package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=27 then
					error('ID is not a torso!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
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
								local rig = server.Deps.Assets.RigR15
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

		Infect = {
			Prefix = Settings.Prefix;
			Commands = {"infect";"zombify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a suit zombie";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local infect; infect = function(v)
					local char = v.Character
					if char and char:findFirstChild("HumanoidRootPart") and not char:FindFirstChild("Infected") then
						local cl = service.New("StringValue", char)
						cl.Name = "Infected"
						cl.Parent = char

						for q, prt in pairs(char:children()) do
							if prt:IsA("BasePart") and prt.Name~='HumanoidRootPart' and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = 0
								prt.BrickColor = BrickColor.new("Dark green")
								if prt.Name:find("Leg") or prt.Name:find('Arm') then
									prt.BrickColor = BrickColor.new("Dark green")
								end
								local tconn; tconn = prt.Touched:connect(function(hit)
									if hit and hit.Parent and service.Players:findFirstChild(hit.Parent.Name) and cl.Parent == char then
										infect(hit.Parent)
									elseif cl.Parent ~= char then
										tconn:disconnect()
									end
								end)

								cl.Changed:connect(function()
									if cl.Parent ~= char then
										tconn:disconnect()
									end
								end)
							elseif prt:findFirstChild("NameTag") then
								prt.Head.Transparency = 0
								prt.Head.Reflectance = 0
								prt.Head.BrickColor = BrickColor.new("Dark green")
							end
						end
					end
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					infect(v)
				end
			end
		};

		Rainbowify = {
			Prefix = Settings.Prefix;
			Commands = {"rainbowify";"rainbow";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character flash random colors";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = Core.NewScript("LocalScript",[[
					repeat
						wait(0.1)
						local char = script.Parent.Parent
						local clr = BrickColor.random()
						for i,v in pairs(char:children()) do
							if v:IsA("BasePart") and v.Name~='HumanoidRootPart' and (v.Name ~= "Head" or not v.Parent:findFirstChild("NameTag", true)) then
								v.BrickColor = clr
								v.Reflectance = 0
								v.Transparency = 0
							elseif v:findFirstChild("NameTag") then
								v.Head.BrickColor = clr
								v.Head.Reflectance = 0
								v.Head.Transparency = 0
								v.Parent.Head.Transparency = 1
							end
						end
					until not char
				]])
				scr.Name = "Effectify"

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						if v.Character:FindFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end
						if v.Character:FindFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end
			end
		};

		Noobify = {
			Prefix = Settings.Prefix;
			Commands = {"noobify";"noob";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) look like a noob";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local bodyColors = service.New("BodyColors", {
					HeadColor = BrickColor.new("Bright yellow"),
					LeftArmColor = BrickColor.new("Bright yellow"),
					RightArmColor = BrickColor.new("Bright yellow"),
					LeftLegColor = BrickColor.new("Br. yellowish green"),
					RightLegColor = BrickColor.new("Br. yellowish green"),
					TorsoColor = BrickColor.new("Bright blue")
				})

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
							if p:IsA("Shirt") or p:IsA("Pants") or p:IsA("CharacterMesh") or p:IsA("Accoutrement") or p:IsA("BodyColors") then
								p:Destroy()
							end
						end
						bodyColors:Clone().Parent = v.Character
					end
				end

				bodyColors:Destroy()
			end
		};
		
		Whitelist = {
			Prefix = Settings.Prefix;
			Commands = {"wl","enablewhitelist","whitelist"};
			Args = {"on/off or add/remove","optional player"};
			Hidden = false;
			Description = "Enables/disables the whitelist; :wl username to add them to the whitelist";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1]:lower()=='on' or args[1]:lower()=='enable' then
					Variables.WhitelistData.Enabled = true
					Variables.WhitelistData.TimeEnabled = os.time()
					Variables.WhitelistData.Moderator = plr
					Functions.Hint("Server Whitelisted", service.Players:GetPlayers())
				elseif args[1]:lower()=='off' or args[1]:lower()=='disable' then
					Variables.WhitelistData.Enabled = false
					Functions.Hint("Server Unwhitelisted", service.Players:GetPlayers())
				elseif args[1]:lower()=="add" then
					if args[2] then
						local plrs = service.GetPlayers(plr,args[2],true)
						if #plrs>0 then
							for i,v in pairs(plrs) do
								table.insert(Variables.WhitelistData.List,v.Name..":"..v.userId)
								Functions.Hint("Whitelisted "..v.Name,{plr})
							end
						else
							table.insert(Variables.WhitelistData.List,args[2])
						end
					else
						error('Missing name to whitelist')
					end
				elseif args[1]:lower()=="remove" then
					if args[2] then
						for i,v in pairs(Variables.WhitelistData.List) do
							if v:lower():sub(1,#args[2]) == args[2]:lower() then
								table.remove(Variables.WhitelistData.List,i)
								Functions.Hint("Removed "..tostring(v).." from the whitelist",{plr})
							end
						end
					else
						error("Missing name to remove from whitelist")
					end
				else
					error("Invalid action; (on/off/add/remove)")
				end
			end
		};

		Color = {
			Prefix = Settings.Prefix;
			Commands = {"color";"bodycolor";};
			Args = {"player";"color";};
			Hidden = false;
			Description = "Make the target the color you choose";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
							if p:IsA("BasePart") then
								if args[2] then
									local str = BrickColor.new('Institutional white').Color
									local teststr = args[2]
									if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
									p.BrickColor = str
								end
							end
						end
					end
				end
			end
		};

		Material = {
			Prefix = Settings.Prefix;
			Commands = {"mat";"material";};
			Args = {"player";"material";};
			Hidden = false;
			Description = "Make the target the material you choose";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local mats = {
					Plastic = 256;
					Wood = 512;
					Slate = 800;
					Concrete = 816;
					CorrodedMetal = 1040;
					DiamondPlate = 1056;
					Foil = 1072;
					Grass = 1280;
					Ice = 1536;
					Marble = 784;
					Granite = 832;
					Brick = 848;
					Pebble = 864;
					Sand = 1296;
					Fabric = 1312;
					SmoothPlastic = 272;
					Metal = 1088;
					WoodPlanks = 528;
					Neon = 288;
				}
				local enumMats = Enum.Material:GetEnumItems()

				local chosenMat = args[2] or "Plastic"

				if not args[2] then
					Functions.Hint("Material wasn't supplied. Plastic was chosen instead")
				elseif tonumber(args[2]) then
					chosenMat = table.find(mats, tonumber(args[2]))
				end

				if not chosenMat then
					Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = "Invalid material choice"})
					return
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
							if p:IsA"BasePart" then
								p.Material = chosenMat
							end
						end
					end
				end
			end
		};

		Neon = {
			Prefix = Settings.Prefix;
			Commands = {"neon";"neonify";};
			Args = {"player";"(optional)color";};
			Hidden = false;
			Description = "Make the target neon";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				server.Commands.Material.Function(plr, {args[1], "Neon"})
				server.Commands.Color.Function(plr, {args[1], args[2]})
			end
		};

		Ghostify = {
			Prefix = Settings.Prefix;
			Commands = {"ghostify";"ghost";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a ghost";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						Admin.RunCommand(Settings.Prefix.."noclip",v.Name)

						if v.Character:findFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end

						if v.Character:findFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") and prt.Name~='HumanoidRootPart' and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
								prt.Transparency = .5
								prt.Reflectance = 0
								prt.BrickColor = BrickColor.new("Institutional white")
								if prt.Name:find("Leg") then
									prt.Transparency = 1
								end
							elseif prt:findFirstChild("NameTag") then
								prt.Head.Transparency = .5
								prt.Head.Reflectance = 0
								prt.Head.BrickColor = BrickColor.new("Institutional white")
							end
						end
					end
				end
			end
		};

		Goldify = {
			Prefix = Settings.Prefix;
			Commands = {"goldify";"gold";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) look like gold";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						if v.Character:findFirstChild("Shirt") then
							v.Character.Shirt.Parent = v.Character.HumanoidRootPart
						end

						if v.Character:findFirstChild("Pants") then
							v.Character.Pants.Parent = v.Character.HumanoidRootPart
						end

						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") and prt.Name~='HumanoidRootPart' and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = .4
								prt.BrickColor = BrickColor.new("Bright yellow")
							elseif prt:findFirstChild("NameTag") then
								prt.Head.Transparency = 0
								prt.Head.Reflectance = .4
								prt.Head.BrickColor = BrickColor.new("Bright yellow")
							end
						end
					end
				end
			end
		};

		Shiney = {
			Prefix = Settings.Prefix;
			Commands = {"shiney";"shineify";"shine";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character shiney";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						if v.Character:findFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end
						if v.Character:findFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") and prt.Name~='HumanoidRootPart' and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = 1
								prt.BrickColor = BrickColor.new("Institutional white")
							elseif prt:findFirstChild("NameTag") then
								prt.Head.Transparency = 0
								prt.Head.Reflectance = 1
								prt.Head.BrickColor = BrickColor.new("Institutional white")
							end
						end
					end
				end
			end
		};

		Spook = {
			Prefix = Settings.Prefix;
			Commands = {"spook";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s)'s screen 2spooky4them";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "Spooky"})
				end
			end
		};

		Blind = {
			Prefix = Settings.Prefix;
			Commands = {"blind";};
			Args = {"player";};
			Hidden = false;
			Description = "Blinds the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "Blind"})
				end
			end
		};

		ScreenImage = {
			Prefix = Settings.Prefix;
			Commands = {"screenimage";"scrimage";"image";};
			Args = {"player";"textureid";};
			Hidden = false;
			Description = "Places the desired image on the target's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local img = tostring(args[2])
				if not img then error(args[2].." is not a valid ID") end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "ScreenImage",Image = args[2]})
				end
			end
		};

		ScreenVideo = {
			Prefix = Settings.Prefix;
			Commands = {"screenvideo";"scrvid";"video";};
			Args = {"player";"videoid";};
			Hidden = false;
			Description = "Places the desired video on the target's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local img = tostring(args[2])
				if not img then error(args[2].." is not a valid ID") end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "ScreenVideo",Video = args[2]})
				end
			end
		};
		
		PushField = {
			Prefix = server.Settings.Prefix;
			Commands = {"pushfield";"pf"};
			Args = {"player";"optional radius"};
			Hidden = false;
			Description = "Sets a forcefield that pushes nearby players away";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for _,player in ipairs(service.GetPlayers(plr, args[1] or "me")) do
					if player.Character and not Variables.ForceField[player.UserId] then
						Variables.ForceField[player.UserId] = {}
						Variables.ForceField[player.UserId].Radius = tonumber(args[2]) or 15;
						Variables.ForceField[player.UserId].DeathConnect = player.Character.Humanoid.Died:Connect(function()
							Variables.ForceField[player.UserId].DeathConnect:Disconnect()
							Variables.ForceField[player.UserId].Push:Disconnect()
							Variables.ForceField[player.UserId] = {}
						end);
						local att0 = Instance.new("Attachment")
						att0.Name = "PushField0"
						att0.Parent = player.Character.HumanoidRootPart
						Variables.ForceField[player.UserId].Push = game:GetService("RunService").Stepped:Connect(function()
							if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
								for _,op in ipairs(service.GetPlayers(plr, "others", true)) do
									if op.Character and op.Character:FindFirstChild("HumanoidRootPart") then
										if not op.Character.HumanoidRootPart:FindFirstChild("PushField1") then
											local att1 = Instance.new("Attachment")
											att1.Name = "PushField1"
											att1.Parent = op.Character.HumanoidRootPart
										end
										if (op.Character.HumanoidRootPart.Position-player.Character.HumanoidRootPart.Position).magnitude <= Variables.ForceField[player.UserId].Radius then
											if not op.Character.HumanoidRootPart:FindFirstChild("AdonisPushField") then
												local ff = Instance.new("VectorForce")
												ff.Name = "AdonisPushField"
												ff.ApplyAtCenterOfMass = true
												ff.Attachment0 = op.Character.HumanoidRootPart.PushField1
												ff.Attachment1 = att0
												ff.RelativeTo = Enum.ActuatorRelativeTo.World
												ff.Parent = op.Character.HumanoidRootPart
											end
											op.Character.HumanoidRootPart.AdonisPushField.Force = ((player.Character.HumanoidRootPart.Position-op.Character.HumanoidRootPart.Position).unit * -1 * Functions.GetModelMass(op.Character) * 800)
										else
											if op.Character.HumanoidRootPart:FindFirstChild("AdonisPushField") then
												op.Character.HumanoidRootPart:FindFirstChild("AdonisPushField"):Destroy()
											end
										end
									end
								end
							end
						end)
					elseif Variables.ForceField[player.UserId] then
						Variables.ForceField[player.UserId].Radius = tonumber(args[2]) or 15
					end
				end
			end
		};
		
		ToServer = {
			Prefix = server.Settings.Prefix;
			Commands = {"toserver"};
			Args = {"serverid"};
			Hidden = false;
			Description = "Joins a specific server in a game";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1], "Argument missing or nil")
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, args[1], plr)
			end
		};

		UnEffect = {
			Prefix = Settings.Prefix;
			Commands = {"uneffect";"unimage";"uneffectgui";"unspook";"unblind";"unstrobe";"untrippy";"unpixelize","unlowres","unpixel","undance";"unflashify";"unrainbowify";"guifix";"fixgui";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes any effect GUIs on the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "Off"})
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

		LoopFling = {
			Prefix = Settings.Prefix;
			Commands = {"loopfling";};
			Args = {"player";};
			Hidden = false;
			Description = "Loop flings the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StartLoop(v.userId.."LOOPFLING",2,function()
						Admin.RunCommand(Settings.Prefix.."fling",v.Name)
					end)
				end
			end
		};

		UnLoopFling = {
			Prefix = Settings.Prefix;
			Commands = {"unloopfling";};
			Args = {"player";};
			Hidden = false;
			Description = "UnLoop Fling";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StopLoop(v.userId.."LOOPFLING")
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
			Agents = true;
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
					if v.messageType==Enum.MessageType.MessageOutput then
						toTab(v.message, "Output: ")
						--table.insert(temp,{Text=v.message,Desc='Output: '..v.message})
					elseif v.messageType==Enum.MessageType.MessageWarning then
						toTab(v.message, "Warning: ", Color3.new(1,1,0))
						--table.insert(temp,{Text=v.message,Desc='Warning: '..v.message,Color=Color3.new(1,1,0)})
					elseif v.messageType==Enum.MessageType.MessageInfo then
						toTab(v.message, "Info: ", Color3.new(0,0,1))
						--table.insert(temp,{Text=v.message,Desc='Info: '..v.message,Color=Color3.new(0,0,1)})
					elseif v.messageType==Enum.MessageType.MessageError then
						toTab(v.message, "Error: ", Color3.new(1,0,0))
						--table.insert(temp,{Text=v.message,Desc='Error: '..v.message,Color=Color3.new(1,0,0)})
					end
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
			Agents = true;
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

		ReplicationLogs = {
			Prefix = Settings.Prefix;
			Commands = {"replications";"replicators";"replicationlogs";};
			Args = {"autoupdate"};
			Hidden = false;
			Description = "Shows a list of what players are *believed* to have created/destroyed object; Does not always imply exploiting";
			Fun = false;
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(Settings.ReplicationLogs,"Replication logs are disabled; Enable them in Settings")
				assert(server.FilteringEnabled == false,"Filtering Enabled; Replication logs disabled (not usable)")

				local tab = {}
				local auto

				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end

				for i,v in pairs(Logs.Replications) do
					table.insert(tab,{Text = v.Player.." "..v.Action.." "..v.ClassName,Desc = v.Path})
				end

				Remote.MakeGui(plr,"List",{
					Title = "Replications";
					Tab = tab;
					Dots = true;
					Update = "ReplicationLogs";
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = true;
				})
			end
		};

		NetworkOwners = {
			Prefix = Settings.Prefix;
			Commands = {"createdparts","networkowners","playerparts"};
			Args = {"autoupdate"};
			Hidden = false;
			Description = "Shows what players created parts in workspace";
			Fun = false;
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(Settings.NetworkOwners,"NetworkOwner logging is disabled; Enable them in Settings")
				assert(server.FilteringEnabled == false,"Filtering Enabled; NetworkOwner logs disabled (not usable)")

				local tab = {}
				local auto

				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end

				for i,v in pairs(Logs.NetworkOwners) do
					table.insert(tab,{Text = tostring(v.Player).." made "..tostring(v.Part),Desc = v.Path})
				end

				Remote.MakeGui(plr,"List",{
					Title = "NetworkOwners",
					Tab = tab,
					Dots = true;
					Update = "NetworkOwners",
					AutoUpdate = auto,
					Sanitize = true;
					Stacking = true;
				})
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
			Agents = true;
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
			Agents = true;
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
			Agents = true;
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
			Agents = true;
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
					Santize = true;
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
				local adminlog = {}
				local serverlog = {}
				local errorlog = {}

				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end

				for i,m in pairs(server.Logs.Commands) do
					table.insert(adminlog,{Time = m.Time;Text = m.Text..": "..m.Desc;Desc = m.Desc})
				end

				local function toTab(str, desc, color)
					for i,v in next,service.ExtractLines(str) do
						table.insert(serverlog,{Text = v,Desc = desc..v, Color = color})
					end
				end

				for i,v in next,service.LogService:GetLogHistory() do
					if v.messageType==Enum.MessageType.MessageOutput then
						toTab(v.message, "Output: ")
						--table.insert(temp,{Text=v.message,Desc='Output: '..v.message})
					elseif v.messageType==Enum.MessageType.MessageWarning then
						toTab(v.message, "Warning: ", Color3.new(1,1,0))
						--table.insert(temp,{Text=v.message,Desc='Warning: '..v.message,Color=Color3.new(1,1,0)})
					elseif v.messageType==Enum.MessageType.MessageInfo then
						toTab(v.message, "Info: ", Color3.new(0,0,1))
						--table.insert(temp,{Text=v.message,Desc='Info: '..v.message,Color=Color3.new(0,0,1)})
					elseif v.messageType==Enum.MessageType.MessageError then
						toTab(v.message, "Error: ", Color3.new(1,0,0))
						--table.insert(temp,{Text=v.message,Desc='Error: '..v.message,Color=Color3.new(1,0,0)})
					end
				end

				for i,v in pairs(server.Logs.Errors) do
					table.insert(errorlog,{Time=v.Time;Text=v.Text..": "..tostring(v.Desc),Desc = tostring(v.Desc)})
				end

				server.Remote.MakeGui(plr,"Logs",{
					AdminLogs = adminlog;
					ServerLogs = serverlog;
					ClientLogs = server.Remote.Get(plr,"ClientLog") or {};
					ErrorLogs = errorlog;
					ExploitLogs = server.Logs.Exploit;
					ChatLogs = server.Logs.Chats;
					JoinLogs = server.Logs.Joins;
					ScriptLogs = server.Logs.Script;
					Dots = true;
					Update = true;
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = false;
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

		Deadlands = {
			Prefix = Settings.Prefix;
			Commands = {"deadlands","farlands","renderingcyanide"};
			Args = {"player","mult"};
			Description = "The edge of Roblox math; WARNING CAPES CAN CAUSE LAG";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local dist = 1000000 * (tonumber(args[2]) or 1.5)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							Functions.UnCape(v)
							torso.CFrame = CFrame.new(dist, dist+10, dist)
							Admin.RunCommand(Settings.Prefix.."noclip",v.Name)
						end
					end
				end
			end
		};

		UnDeadlands = {
			Prefix = Settings.Prefix;
			Commands = {"undeadlands","unfarlands","unrenderingcyanide"};
			Args = {"player"};
			Description = "Clips the player and teleports them to you";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						local pTorso = plr.Character:FindFirstChild("HumanoidRootPart")
						if torso and pTorso and plr ~= v then
							Admin.RunCommand(Settings.Prefix.."clip",v.Name)
							wait(0.3)
							torso.CFrame = pTorso.CFrame*CFrame.new(0,0,5)
						else
							plr:LoadCharacter()
						end
					end
				end
			end
		};

		RopeConstraint = {
			Prefix = Settings.Prefix;
			Commands = {"rope","chain"};
			Args = {"player1","player2","length"};
			Description = "Connects players using a rope constraint";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,player1 in pairs(service.GetPlayers(plr,args[1])) do
					for i2,player2 in pairs(service.GetPlayers(plr,args[2])) do
						local torso1 = player1.Character:FindFirstChild("HumanoidRootPart")
						local torso2 = player2.Character:FindFirstChild("HumanoidRootPart")
						if torso1 and torso2 then
							local att1 = service.New("Attachment",torso1)
							local att2 = service.New("Attachment",torso2)
							local rope = service.New("RopeConstraint",torso1)

							att1.Name = "Adonis_Rope_Attachment";
							att2.Name = "Adonis_Rope_Attachment";
							rope.Name = "Adonis_Rope_Constraint";

							rope.Visible = true
							rope.Attachment0 = att1
							rope.Attachment1 = att2
							rope.Length = tonumber(args[3]) or 20
						end
					end
				end
			end;
		};

		UnRopeConstraint = {
			Prefix = Settings.Prefix;
			Commands = {"unrope","unchain"};
			Args = {"player"};
			Description = "UnRope";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr,args[1])) do
					local torso = p.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						for i,v in pairs(torso:GetChildren()) do
							if v.Name == "Adonis_Rope_Attachment" or v.Name == "Adonis_Rope_Constraint" then
								v:Destroy()
							end
						end
					end
				end
			end;
		};
	}
	
	for ind, com in pairs(Commands) do
		server.Commands[ind] = com
	end
end