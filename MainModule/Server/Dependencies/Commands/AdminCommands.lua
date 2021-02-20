server = nil
service = nil
Routine = nil

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

	local Commands = {
		CustomMessage = {
			Prefix = Settings.Prefix;
			Commands = {"cm";"custommessage";};
			Args = {"Upper message","message";};
			Filter = true;
			Description = "Same as message but says whatever you want upper message to be instead of your name.";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				assert(args[2],"Argument missing or nil")
				for i,v in pairs(service.Players:GetChildren()) do
					Remote.RemoveGui(v,"Message")
					Remote.MakeGui(v,"Message",{
						Title = args[1];
						Message = args[2];
						--service.Filter(args[1],plr,v);
					})
				end
			end
		};
		
		TrelloBan = {
			Prefix = Settings.Prefix;
			Commands = {"trelloban";};
			Args = {"player","reason"};
			Description = "Adds a user to the Trello ban list (Trello needs to be configured)";
			Hidden = false;
			Fun = false;
			CrossServerDenied = true;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				local board = Settings.Trello_Primary
				local appkey = Settings.Trello_AppKey
				local token = Settings.Trello_Token

				if not Settings.Trello_Enabled or board == "" or appkey == "" or token == "" then server.Functions.Hint('Trello is not configured inside Adonis config, please configure Trello to be able to use this command.', {plr}) return end

				local trello = HTTP.Trello.API(appkey,token)
				local lists = trello.Boards.GetLists(board)
				local list = trello.GetListObject(lists,{"Banlist","Ban List","Bans"})

				local level = data.PlayerData.Level
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > Admin.GetLevel(v) then
						trello.Lists.MakeCard(list.id,tostring(v)..":".. tostring(v.UserId),
							"Administrator: " .. tostring(plr) ..
								"\nReason: ".. args[2] or "N/A")
						HTTP.Trello.Update()
						Functions.Hint("Trello banned ".. tostring(v),{plr})
					end
				end
			end;
		};
		
		TempModerator = {
			Prefix = Settings.Prefix;
			Commands = {"admin","tempadmin","ta","temp","helper";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) a temporary moderator; Does not save";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				local sendLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v,1,true)
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now a temp moderator',{plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};

		Moderator = {
			Prefix = Settings.Prefix;
			Commands = {"mod";"moderator"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) a moderator; Saves";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				local sendLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v,1)
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now a moderator',{plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};

		UnAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"unadmin";"unmod","unowner","unhelper","unpadmin","unpa";"unoa";"unta";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target players' admin powers; Saves";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				assert(args[1],"Argument missing or nil")

				local sendLevel = data.PlayerData.Level
				local plrs = service.GetPlayers(plr, args[1], true)
				if plrs and #plrs>0 then
					for i,v in next,plrs do
						local targLevel = Admin.GetLevel(v)
						if targLevel>0 then
							if sendLevel>targLevel then
								Admin.RemoveAdmin(v,false,true)
								Functions.Hint("Removed "..v.Name.."'s admin powers",{plr})
							else
								Functions.Hint("You do not have permission to remove "..v.Name.."'s admin powers",{plr})
							end
						else
							Functions.Hint(v.Name..' is not an admin',{plr})
						end
					end
				else
					local targLevel = Admin.GetUpdatedLevel(args[1])
					if targLevel then
						if sendLevel > targLevel then
							local ans = Remote.MakeGuiGet(plr,"YesNoPrompt",{
								Question = "Unadmin all saved admins matching '"..tostring(args[1]).."'?";
							})
							if ans == "Yes" then
								Admin.RemoveAdmin(args[1])
								Functions.Hint("Removed "..args[1].."'s admin powers",{plr})
							end
						else
							Functions.Hint("You do not have permission to remove "..args[1].."'s admin powers",{plr})
						end
					else
						Functions.Hint("No level returned for "..args[1])
					end
				end
			end
		};

		TempUnAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"tempunadmin","untempadmin","tunadmin","untadmin"};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target players' admin powers for this server; Does not save";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				assert(args[1],"Argument missing or nil")

				local sendLevel = data.PlayerData.Level
				local plrs = service.GetPlayers(plr, args[1], true)
				if plrs and #plrs>0 then
					for i,v in pairs(plrs) do
						local targLevel = Admin.GetLevel(v)
						if targLevel>0 then
							if sendLevel>targLevel then
								Admin.RemoveAdmin(v,true)
								Functions.Hint("Removed "..v.Name.."'s admin powers",{plr})
							else
								Functions.Hint("You do not have permission to remove "..v.Name.."'s admin powers",{plr})
							end
						else
							Functions.Hint(v.Name..' is not an admin',{plr})
						end
					end
				end
			end
		};
		
		Ban = {
			Prefix = Settings.Prefix;
			Commands = {"ban";};
			Args = {"player"; "reason";};
			Description = "Bans the player from the server";
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				local level = data.PlayerData.Level
				local reason = args[2] or "No Reason Provided"
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > Admin.GetLevel(v) then
						Admin.AddBan(v, "BAN", plr, os.time(), reason, "Server Ban")
						Functions.Hint("Server banned "..tostring(v),{plr})
					end
				end
			end
		};

		UnBan = {
			Prefix = Settings.Prefix;
			Commands = {"unban";};
			Args = {"player";};
			Description = "UnBan";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local ret = Admin.RemoveBan(args[1])
				if ret then
					Functions.Hint(tostring(ret)..' has been Unbanned',{plr})
				end
			end
		};

		Dizzy = {
			Prefix = Settings.Prefix;
			Commands = {"dizzy";};
			Args = {"player","speed"};
			Description = "Causes motion sickness";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local speed = args[2] or 50
				if not speed or not tonumber(speed) then
					speed = 1000
				end
				for i,v in next,service.GetPlayers(plr,args[1]) do
					Remote.Send(v,"Function","Dizzy",tonumber(speed))
				end
			end
		};

		UnDizzy = {
			Prefix = Settings.Prefix;
			Commands = {"undizzy";};
			Args = {"player"};
			Description = "UnDizzy";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","Dizzy",false)
				end
			end
		};

		SetFPS = {
			Prefix = Settings.Prefix;
			Commands = {"setfps";};
			Args = {"player";"fps";};
			Hidden = false;
			Description = "Sets the target players's FPS";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				assert(tonumber(args[2]),tostring(args[2]).." is not a valid number")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","SetFPS",tonumber(args[2]))
				end
			end
		};

		RestoreFPS = {
			Prefix = Settings.Prefix;
			Commands = {"restorefps";"revertfps";"unsetfps";};
			Args = {"player";};
			Hidden = false;
			Description = "Restores the target players's FPS";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","RestoreFPS")
				end
			end
		};

		Crash = {
			Prefix = Settings.Prefix;
			Commands = {"crash";};
			Args = {"player";};
			Hidden = false;
			Description = "Crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						Remote.Send(v,'Function','Crash')
					end
				end
			end
		};

		HardCrash = {
			Prefix = Settings.Prefix;
			Commands = {"hardcrash";};
			Args = {"player";};
			Hidden = false;
			Description = "Hard crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						Remote.Send(v,'Function','HardCrash')
					end
				end
			end
		};

		RAMCrash = {
			Prefix = Settings.Prefix;
			Commands = {"ramcrash";"memcrash"};
			Args = {"player";};
			Hidden = false;
			Description = "Crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						Remote.Send(v,'Function','RAMCrash')
					end
				end
			end
		};

		GPUCrash = {
			Prefix = Settings.Prefix;
			Commands = {"gpucrash";};
			Args = {"player";};
			Hidden = false;
			Description = "Crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						Remote.Send(v,'Function','GPUCrash')
					end
				end
			end
		};

		Shutdown = {
			Prefix = Settings.Prefix;
			Commands = {"shutdown"};
			Args = {"reason"};
			Description = "Shuts the server down";
			PanicMode = true;
			Filter = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not Core.PanicMode then
					local logs = Core.GetData("ShutdownLogs") or {}
					if plr then
						table.insert(logs,1,{User = plr.Name, Time = service.GetTime(), Reason = args[1] or "N/A"})
					else
						table.insert(logs,1,{User = "Server/Trello", Time = service.GetTime(), Reason = args[1] or "N/A"})
					end
					if #logs>1000 then
						table.remove(logs,#logs)
					end
					Core.SaveData("ShutdownLogs",logs)
				end
				Functions.Shutdown(args[1])
			end
		};

		ShutdownLogs = {
			Prefix = Settings.Prefix;
			Commands = {"shutdownlogs";"shutdownlog";"slogs";"shutdowns";};
			Args = {};
			Hidden = false;
			Description = "Shows who shutdown a server and when";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local logs = Core.GetData("ShutdownLogs") or {}
				local tab={}
				for i,v in pairs(logs) do
					table.insert(tab,1,{Text=v.Time..": "..v.User,Desc="Reason: "..v.Reason})
				end
				Remote.MakeGui(plr,"List",{Title = "Shutdown Logs",Table = tab,Update = "shutdownlogs"})
			end
		};

		ServerLock = {
			Prefix = Settings.Prefix;
			Commands = {"slock","serverlock"};
			Args = {"on/off"};
			Hidden = false;
			Description = "Enables/disables server lock";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not args[1] or (args[1] and (args[1]:lower() == "on" or args[1]:lower() == "true")) then
					Variables.SlockData.Enabled = true
					Variables.SlockData.TimeEnabled = os.time()
					Variables.SlockData.Moderator = plr
					Functions.Hint("Server Locked",{plr})
				elseif args[1]:lower() == "off" or args[1]:lower() == "false" then
					Variables.SlockData.Enabled = false
					Functions.Hint("Server Unlocked",{plr})
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
			AdminLevel = "Admins";
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

		Notif = {
			Prefix = Settings.Prefix;
			Commands = {"setmessage";"notif";"setmsg";};
			Args = {"message OR off";};
			Filter = true;
			Description = "Set message";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")

				if args[1] == "off" or args[1] == "false" then
					Variables.NotifMessage = nil
					for i,v in pairs(service.GetPlayers()) do
						Remote.RemoveGui(v,"Notif")
					end
				else
					Variables.NotifMessage = args[1] --service.LaxFilter(args[1],plr) --// Command processor handles arg filtering
					for i,v in pairs(service.GetPlayers()) do
						Remote.MakeGui(v,"Notif",{
							Message = Variables.NotifMessage;
						})
					end
				end
			end
		};

		SetLockMessage = {
			Prefix = Settings.Prefix;
			Commands = {"setlockmessage";"setlmsg"};
			Args = {"message";};
			Filter = true;
			Description = "Sets the lock message unwhitelisted players see if :whitelist or :slock is on";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				Variables.LockMessage = args[1]
			end
		};
		
		SystemMessage = {
			Prefix = Settings.Prefix;
			Commands = {"sm";"systemmessage";};
			Args = {"message";};
			Filter = true;
			Description = "Same as message but says SYSTEM MESSAGE instead of your name, or whatever system message title is server to...";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.Players:GetPlayers()) do
					Remote.RemoveGui(v,"Message")
					Remote.MakeGui(v,"Message",{
						Title = Settings.SystemTitle;
						Image = Settings.SystemImage;
						Message = args[1]; --service.Filter(args[1],plr,v);
					})
				end
			end
		};
		
		SetCoreGuiEnabled = {
			Prefix = Settings.Prefix;
			Commands = {"setcoreguienabled";"setcoreenabled";"showcoregui";"setcoregui";"setcge";"setcore"};
			Args = {"player";"element";"true/false";};
			Hidden = false;
			Description = "SetCoreGuiEnabled. Enables/Disables CoreGui elements. ";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if args[3]:lower()=='on' or args[3]:lower()=='true' then
						Remote.Send(v,'Function','SetCoreGuiEnabled',args[2],true)
					elseif args[3]:lower()=='off' or args[3]:lower()=='false' then
						Remote.Send(v,'Function','SetCoreGuiEnabled',args[2],false)
					end
				end
			end
		};
		
		Alert = {
			Prefix = Settings.Prefix;
			Commands = {"alert";"alarm";"annoy";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Get someone's attention";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1]:lower())) do
					Remote.MakeGui(v,"Alert",{Message = args[2] and service.Filter(args[2],plr,v) or "Wake up"})
				end
			end
		};
		
		ZaWarudo = {
			Prefix = Settings.Prefix;
			Commands = {"zawarudo","stoptime"};
			Args = {};
			Fun = true;
			Description = "Freezes everything but the player running the command";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local doPause; doPause = function(obj)
					if obj:IsA("BasePart") and not obj.Anchored and not obj:IsDescendantOf(plr.Character) then
						obj.Anchored = true
						table.insert(Variables.FrozenObjects, obj)
					end

					for i,v in next,obj:GetChildren() do
						doPause(v)
					end
				end

				if not Variables.ZaWarudoDebounce then
					Variables.ZaWarudoDebounce = true
					delay(10, function() Variables.ZaWarudoDebounce = false end)
					if Variables.ZaWarudo then
						local audio = service.New("Sound",workspace)
						audio.SoundId = "rbxassetid://676242549"
						audio.Volume = 0.5
						audio:Play()
						wait(2)
						for i,part in next,Variables.FrozenObjects do
							part.Anchored = false
						end

						local old = service.Lighting:FindFirstChild("ADONIS_ZAWARUDO")
						if old then
							for i = -2,0,0.1 do
								old.Saturation = i
								wait(0.01)
							end
							old:Destroy()
						end

						local audio = workspace:FindFirstChild("ADONIS_CLOCK_AUDIO")
						if audio then
							audio:Stop()
							audio:Destroy()
						end

						Variables.ZaWarudo:Disconnect()
						Variables.FrozenObjects = {}
						Variables.ZaWarudo = false
						audio:Destroy()
					else
						local audio = service.New("Sound",workspace)
						audio.SoundId = "rbxassetid://274698941"
						audio.Volume = 10
						audio:Play()
						wait(2.25)
						doPause(workspace)
						Variables.ZaWarudo = game.DescendantAdded:connect(function(c)
							if c:IsA("BasePart") and not c.Anchored and c.Name ~= "HumanoidRootPart" then
								c.Anchored = true
								table.insert(Variables.FrozenObjects,c)
							end
						end)

						local cc = service.New("ColorCorrectionEffect",service.Lighting)
						cc.Name = "ADONIS_ZAWARUDO"
						for i = 0,-2,-0.1 do
							cc.Saturation = i
							wait(0.01)
						end

						audio:Destroy()
						local clock = service.New("Sound",workspace)
						clock.Name = "ADONIS_CLOCK_AUDIO"
						clock.SoundId = "rbxassetid://160189066"
						clock.Looped = true
						clock.Volume = 1
						clock:Play()
					end
					Variables.ZaWarudoDebounce = false
				end
			end
		};
		
		LockMap = {
			Prefix = Settings.Prefix;
			Commands = {"lockmap";};
			Args = {};
			Hidden = false;
			Description = "Locks the map";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in next, workspace:GetDescendants() do
					if v and v.Parent and v:IsA"BasePart" then
						v.Locked = true
					end
				end
			end
		};

		UnlockMap = {
			Prefix = Settings.Prefix;
			Commands = {"unlockmap";};
			Args = {};
			Hidden = false;
			Description = "Unlocks the map";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in next, workspace:GetDescendants() do
					if v and v.Parent and v:IsA"BasePart" then
						v.Locked = false
					end
				end
			end
		};
		
		BuildingTools = {
			Prefix = Settings.Prefix;
			Commands = {"btools";"buildtools";"buildingtools";"buildertools";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives the target player(s) basic building tools and the F3X tool";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local f3x = service.New("Tool")
				f3x.CanBeDropped = false
				f3x.ManualActivationOnly = false
				f3x.ToolTip = "Building Tools by F3X"
				for k,m in pairs(Deps.Assets['F3X Deps']:GetChildren()) do
					m:Clone().Parent = f3x
				end
				f3x.Name='Building Tools'
				service.New("StringValue",f3x).Name = Variables.CodeName

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v:findFirstChild("Backpack") then
						f3x:Clone().Parent = v.Backpack
					end
				end
			end
		};
		
		NewTeam = {
			Prefix = Settings.Prefix;
			Commands = {"newteam","createteam","maketeam"};
			Args = {"name";"BrickColor";};
			Filter = true;
			Hidden = false;
			Description = "Make a new team with the specified name and color";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local color = BrickColor.new(math.random(1,227))
				if BrickColor.new(args[2])~=nil then color=BrickColor.new(args[2]) end
				local team = service.New("Team", service.Teams)
				team.Name = args[1]
				team.AutoAssignable = false
				team.TeamColor = color
			end
		};

		RemoveTeam = {
			Prefix = Settings.Prefix;
			Commands = {"removeteam";};
			Args = {"name";};
			Hidden = false;
			Description = "Remove the specified team";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.Teams:children()) do
					if v:IsA("Team") and v.Name:lower():sub(1,#args[1])==args[1]:lower() then
						v:Destroy()
					end
				end
			end
		};
		
		CreateSoundPart = {
			Prefix = server.Settings.Prefix;	-- Prefix to use for command
			Commands = {"createsoundpart","createspart"};	-- Commands
			Args = {"soundid", "soundrange (default: 10) (max: 100)", "pitch (default: 1)", "disco (default: false)", "showhint (default: false)", "noloop (default: false)", "volume (default: 1)", "changeable (default: false)", "clicktotoggle (default: false)" ,"rangetotoggle (default: 10) (required: clicktotoggle)","share type (default: everyone)"};	-- Command arguments
			Description = "Creates a sound part";	-- Command Description
			Hidden = false; -- Is it hidden from the command list?
			Fun = true;	-- Is it fun?
			AdminLevel = "Admins";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
			Function = function(plr,args)    -- Function to run for command
				assert(plr.Character ~= nil, "Character not found")
				assert(typeof(plr.Character) == "Instance", "Character found fake")
				assert(plr.Character:IsA("Model"), "Character isn't a model.")

				local char = plr.Character
				assert(char:FindFirstChild("Head"), "Head isn't found in your character. How is it going to spawn?")

				local soundid = (args[1] and tonumber(args[1])) or select(1, function()
					if args[1] then
						local nam = args[1]

						for i,v in next, server.Variables.MusicList do
							if v.Name:lower() == nam:lower() then
								return v.ID
							end
						end
					end
				end)() or error("SoundId wasn't provided or wasn't a valid number")

				local soundrange = (args[2] and tonumber(args[2])) or 10
				local pitch = (args[3] and tonumber(args[3])) or 1
				local disco = (args[4] and args[4]:lower() == 'true') or false
				local showhint = (args[5] and args[5]:lower() == 'true') or false
				local noloop = (args[6] and args[6]:lower() == 'true') or false
				local volume = (args[7] and tonumber(args[7])) or 1
				local changeable = (args[8] and args[8]:lower() == 'true') or false
				local toggable = (args[9] and args[9]:lower() == 'true') or false
				local rangetotoggle = (args[10] and tonumber(args[10])) or 10
				local sharetype = (args[11] and args[11]:lower() == 'all' and 'all') or (args[11] and args[11]:lower() == 'self' and 'self') or (args[11] and args[11]:lower() == 'friends' and 'friends') or (args[11] and args[11]:lower() == 'admins' and 'admins') or 'all'

				if rangetotoggle == 0 then
					rangetotoggle = 32
				elseif rangetotoggle < 0 then
					rangetotoggle = math.abs(rangetotoggle)
				end

				pitch = math.abs(pitch)
				soundrange = math.abs(soundrange)

				if soundrange > 100 then
					soundrange = 100
				end

				local did,soundinfo = pcall(function()
					return service.MarketplaceService:GetProductInfo(soundid)
				end)

				assert(did == true, "Sound Id isn't a sound or doesn't exist.")
				if did then
					assert(soundinfo.AssetTypeId == 3, "Sound Id isn't a sound. Please check the right id.")

					local sound = service.New("Sound")
					sound.Name = "Part_Sound"
					sound.Looped = not noloop
					sound.SoundId = "rbxassetid://"..soundid
					sound.Volume = volume
					sound.EmitterSize = soundrange
					sound.PlaybackSpeed = pitch
					sound.Archivable = false

					local spart = service.New("Part")
					spart.Anchored = true
					spart.Name = "SoundPart"
					spart.Position = char:FindFirstChild("Head").Position
					spart.Size = Vector3.new(2, 1, 2)
					table.insert(Variables.InsertedObjects, spart)

					local curTag
					local function createTag(txt, secs)
						if showhint == false then return end
						if curTag then pcall(function() curTag:Destroy() end) end
						local tag = script.Tag:Clone()
						tag.Name = "\0"
						tag.Enabled = true
						tag.Frame.Tag.Text = tostring(txt)
						tag.Parent = spart
						curTag = tag


						if secs then
							game:GetService("Debris"):AddItem(tag, secs)
						else
							game:GetService("Debris"):AddItem(tag, 5)
						end
					end

					sound.Changed:Connect(function(prot)
						if prot == "SoundId" then
							if sound.IsPlaying then
								sound:Stop()
							end

							sound.TimePosition = 0
						end
					end)

					sound.Ended:Connect(function()
						createTag("Sound "..tostring(sound.SoundId).." ended", 5)
					end)

					local discoscript
					if disco == true then
						discoscript = script.DiscoPart:Clone()
						discoscript.Disabled = false
						discoscript.Archivable = false
						server.SyncAPI.TrustScript(discoscript)
						discoscript.Parent = spart
					end

					if changeable == true then
						spart.Name = tostring(soundid)
					end

					if toggable == true then
						local clickd = service.New("ClickDetector")
						clickd.Name = "ClickToPlay"
						clickd.Archivable = false
						clickd.MaxActivationDistance = rangetotoggle
						local clicks = 0

						local ownerid = plr.UserId
						clickd.MouseClick:Connect(function(clicker)
							if sharetype == "self" and clicker.UserId ~= ownerid then return end
							if sharetype == "friends" then
								if clicker.UserId ~= ownerid and not clicker:IsFriendsWith(ownerid) then
									return
								end
							end

							clicks = clicks + 1
							delay(0.4, function()
								clicks = clicks - 1
							end)

							if clicks == 1 then
								if sound.IsPlaying then
									sound:Pause()
									createTag("Music paused by "..clicker.Name, 5)
								else
									sound:Resume()
									createTag("Music resumed by "..clicker.Name, 5)								
								end
							elseif clicks == 2 then
								if sound.IsPlaying then
									sound:Stop()
									createTag("Music stopped by "..clicker.Name, 5)
								else
									sound:Play()
									createTag("Music replaying by "..clicker.Name, 5)								
								end
							elseif clicks == 3 then
								if discoscript and discoscript.Parent ~= nil then
									if discoscript.Disabled then
										discoscript.Disabled = false
									else
										discoscript.Disabled = true
									end
								end
							end
						end)

						clickd.Parent = spart
					end

					local prevname = spart.Name
					spart.Changed:Connect(function(prot)
						if prot == "Name" and changeable then
							if prevname == spart.Name then return end
							local suc,prodinfo = pcall(function()
								return service.MarketplaceService:GetProductInfo(tonumber(spart.Name or 0))
							end)

							if suc and prodinfo then
								if prodinfo.AssetTypeId ~= 3 then
									spart.Name = prevname
									createTag("Sound "..spart.Name.." is not valid.")
									sound:Pause()
									return end

								soundinfo = prodinfo
								prevname = spart.Name
								sound.SoundId = "rbxassetid://"..spart.Name
								createTag("Sound "..sound.SoundId.." inserted")
								wait(2)
								createTag("Sound Name: "..tostring(prodinfo.Name))
							elseif not suc then
								createTag("Sound "..tostring(spart.Name).." is not valid.")
								spart.Name = prevname
							end

							if not toggable then
								sound:Play()
							end
						end
					end)

					if not toggable then
						sound:Play()
						createTag("Now playing " ..soundinfo.Name)
						wait(2)
						createTag("SoundId "..soundinfo.AssetId)
					else

					end

					createTag("Sound Name: "..tostring(soundinfo.Name))
					sound.Parent = spart
					spart.Parent = workspace
					spart.Archivable = false
				end
			end
		};
		
		LowRes = {
			Prefix = Settings.Prefix;
			Commands = {"lowres","pixelrender","pixel","pixelize"};
			Args = {"player","pixelSize","renderDist"};
			Hidden = false;
			Description = "Pixelizes the player's view";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local size = tonumber(args[2]) or 19
				local dist = tonumber(args[3]) or 100
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{
						Mode = "Pixelize";
						Resolution = size;
						Distance = dist;
					})
				end
			end
		};
		
		Thanos = {
			Prefix = server.Settings.Prefix;
			Commands = {"thanos", "thanossnap","balancetheserver", "snap"};
			Args = {"(opt)player"};
			Description = "\"Fun isn't something one considers when balancing the universe. But this... does put a smile on my face.\"";
			Fun = true;
			Hidden = false;
			AdminLevel = "Admins";
			Function = function(plr,args, data)
				local players = {}
				local deliverUs = {}
				local playerList = service.GetPlayers(args[1] and plr, args[1])
				local plrLevel = data.PlayerData.Level

				local audio = Instance.new("Sound")
				audio.Name = "Adonis_Snap"
				audio.SoundId = "rbxassetid://".. 2231214507
				audio.Looped = false
				audio.Volume = 1
				audio.PlayOnRemove = true

				--[[local thanos = audio:Clone()
				thanos.Name = "Adonis_Thanos"
				thanos.SoundId = "rbxassetid://".. 2231229572

				thanos.Parent = service.SoundService
				audio.Parent = service.SoundService

				wait()
				thanos:Destroy()--]]
				wait()
				audio:Destroy()

				for i = 1, #playerList*10 do
					if #players < math.max((#playerList/2), 1) then
						local index = math.random(1, #playerList)
						local targPlayer = playerList[index]
						if not deliverUs[targPlayer] then
							local targLevel = server.Admin.GetLevel(targPlayer)
							if targLevel < plrLevel then
								deliverUs[targPlayer] = true
								table.insert(players, targPlayer)
							else
								table.remove(playerList, index)
							end
							wait()
						end
					else
						break
					end
				end

				for i,p in next,players do
					service.TrackTask("Thread: Thanos", function()
						for t = 0.1,1.1,0.05 do
							if p.Character then
								local human = p.Character:FindFirstChildOfClass("Humanoid")
								if human then
									human.HealthDisplayDistance = 1
									human.NameDisplayDistance = 1
									human.HealthDisplayType = "AlwaysOff"
									human.NameOcclusion = "OccludeAll"
								end

								for k,v in ipairs(p.Character:GetChildren()) do
									if v:IsA("BasePart") then
										local decal = v:FindFirstChildOfClass("Decal")
										local foundDust = v:FindFirstChild("Thanos_Emitter")
										local trans = (t/k)+t

										if decal then
											decal.Transparency = trans
										end

										v.Transparency = trans

										if v.Color ~= Color3.fromRGB(106, 57, 9) then
											v.Color = v.Color:lerp(Color3.fromRGB(106, 57, 9), 0.05)
										end

										if not foundDust and t < 0.3 then
											local em = Instance.new("ParticleEmitter")
											em.Color = ColorSequence.new(Color3.fromRGB(199, 132, 65))
											em.LightEmission = 0.5
											em.LightInfluence = 0
											em.Size = NumberSequence.new(2, 3, 1)
											em.Texture = "rbxassetid://173642823"
											em.Transparency = NumberSequence.new(0,1,0,0.051532,0,0,0.927577,0,0,1,1,0)
											em.Acceleration = Vector3.new(1, 0.1, 0)
											em.VelocityInheritance = 0
											em.EmissionDirection = "Top"
											em.Lifetime = NumberRange.new(3, 8)
											em.Rate = 10
											em.Rotation = NumberRange.new(0, 135)
											em.RotSpeed = NumberRange.new(10, 20)
											em.Speed = NumberRange.new(0, 0)
											em.SpreadAngle = Vector2.new(0, 0)
											em.Name = "Thanos_Emitter"
											em.Parent = v
										elseif t > 0.5 then
											foundDust.Enabled = false
										end
									end
								end
							end

							--[[local root = p.Character:FindFirstChild("HumanoidRootPart")
							if root then
								local part = Instance.new("Part")
								part.Anchored = false
								part.CanCollide = true
								part.BrickColor = BrickColor.new("Burnt Sienna")
								part.Size = Vector3.new(0.1,0.1,0.1)
								part.CFrame = root.CFrame*CFrame.new(math.random(-3,3), math.random(-3,3), math.random(-3,3))
								part.Parent = workspace
								service.Debris:AddItem(part, 5)
							end--]]
							wait(0.2)
						end

						wait(1)
						p:Kick("\"I don't feel so good\"")
					end)
				end
			end;
		};

		ifoundyou = {
			Prefix = server.Settings.Prefix;
			Commands = {"ufo","abduct","space","fromanotherworld","newmexico","area51","rockwell"};
			Args = {"player"};
			Description = "A world unlike our own.";
			Fun = true;
			Hidden = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local data = server.Core.GetPlayer(plr)
				local forYou = {
					'"Who are you?"';
					'"I am Death," said the creature. "I thought that was obvious."';
					'"But you\'re so small!"';
					'"Only because you are small."';
					'"You are young and far from your Death, September, ..."';
					'"... so I seem as anything would seem if you saw it from a long way off ..."';
					'"... very small, very harmless."';
					'"But I am always closer than I appear."';
					'"As you grow, I shall grow with you ..."';
					'"... until at the end, I shall loom huge and dark over your bed ..."';
					'"... and you will shut your eyes so as not to see me."';

					'Find me.';
					'Fear me.';
					'Love me.';
				}

				if not args[1] then
					local ind = data.SleepInParadise or 1
					data.SleepInParadise = ind+1

					if ind == 14 then
						data.SleepInParadise = 12
					end

					error(forYou[ind])
				end

				for i,p in next,service.GetPlayers(plr,args[1]) do
					service.TrackTask("Thread: UFO", function()
						local char = p.Character
						local torso = p.Character:FindFirstChild("HumanoidRootPart")
						local humanoid = p.Character:FindFirstChild("Humanoid")

						if torso and humanoid and not char:FindFirstChild("ADONIS_UFO") then
							local ufo = server.Deps.Assets.UFO:Clone()
							if ufo then
								local function check()
									if not ufo.Parent or p.Parent ~= service.Players or not torso.Parent or not humanoid.Parent or not char.Parent then
										return false
									else
										return true
									end
								end

								local light = ufo.Light
								local rotScript = ufo.Rotator
								local beam = ufo.BeamPart
								local spotLight = light.SpotLight
								local particles = light.ParticleEmitter
								local primary = ufo.Primary
								local bay = ufo.Bay

								local hum = light.Humming
								local leaving = light.Leaving
								local idle = light.Idle
								local beamSound = light.Beam

								local tPos = torso.CFrame
								local info = TweenInfo.new(5, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out, -1, true, 0)

								humanoid.Name = "NoResetForYou"
								humanoid.WalkSpeed = 0
								ufo.Name = "ADONIS_UFO"
								ufo.PrimaryPart = primary
								ufo:SetPrimaryPartCFrame(tPos*CFrame.new(0, 500, 0))

								spotLight.Enabled = false
								particles.Enabled = false
								beam.Transparency = 1

								ufo.Parent = p.Character

								wait()
								rotScript.Disabled = false

								for i = 1,200 do
									if not check() then
										break
									else
										ufo:SetPrimaryPartCFrame(tPos*CFrame.new(0, 200-i, 0))
										wait(0.001*(i/5))
									end
								end

								if check() then
									wait(1)
									spotLight.Enabled = true
									particles.Enabled = true
									beam.Transparency = 0.5
									beamSound:Play()

									local tween = service.TweenService:Create(torso, info, {
										CFrame = bay.CFrame*CFrame.new(0, 0, 0)
									})

									torso.Anchored = true
									tween:Play()

									for i,v in next,p.Character:GetChildren() do
										if v:IsA("BasePart") then
											service.TweenService:Create(v, TweenInfo.new(1), {
												Transparency = 1
											}):Play()
											--v:ClearAllChildren()
										end
									end

									wait(5)

									spotLight.Enabled = false
									particles.Enabled = false
									beam.Transparency = 1
									beamSound:Stop()

									--idle:Stop()
									--leaving:Play()

									Remote.LoadCode(p,[[
										local cam = workspace.CurrentCamera
										local player = service.Players.LocalPlayer
										local ufo = player.Character:FindFirstChild("ADONIS_UFO")
										if ufo then
											local part = ufo:FindFirstChild("Bay")
											if part then
												--cam.CameraType = "Track"
												cam.CameraSubject = part
											end
										end
									]])

									for i,v in next,p.Character:GetChildren() do
										if v:IsA("BasePart") then
											v.Anchored = true
											v.Transparency = 1
											pcall(function() v:FindFirstChildOfClass("Decale"):Destroy() end)
										elseif v:IsA("Accoutrement") then
											v:Destroy()
										end
									end

									wait(1)

									server.Remote.MakeGui(p,"Effect",{
										Mode = "FadeOut";
									})

									for i = 1,260 do
										if not check() then
											break
										else
											ufo:SetPrimaryPartCFrame(tPos*CFrame.new(0, i, 0))
											--torso.CFrame = bay.CFrame*CFrame.new(0, 2, 0)
											wait(0.001*(i/5))
										end
									end

									if check() then
										p.CameraMaxZoomDistance = 0.5

										local gui = Instance.new("ScreenGui", service.ReplicatedStorage)
										local bg = Instance.new("Frame", gui)
										bg.BackgroundTransparency = 0
										bg.BackgroundColor3 = Color3.new(0,0,0)
										bg.Size = UDim2.new(2,0,2,0)
										bg.Position = UDim2.new(-0.5,0,-0.5,0)
										if p and p.Parent == service.Players then service.TeleportService:Teleport(527443962,p,nil,bg) end
										wait(0.5)
										pcall(function() gui:Destroy() end)
									end
								end

								pcall(function() ufo:Destroy() end)
							end
						end
					end)
				end
			end;
		};
		
		RestoreMap = {
			Prefix = Settings.Prefix;
			Commands = {"restoremap";"maprestore";"rmap";};
			Args = {};
			Hidden = false;
			Description = "Restore the map to the the way it was the last time it was backed up";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not server.Variables.MapBackup or not Variables.TerrainMapBackup then
					error("Cannot restore when there are no backup maps!!")
					return
				end
				if server.Variables.RestoringMap then
					error("Map has not been backed up")
					return
				end
				if server.Variables.BackingupMap then
					error("Cannot restore map while backing up map is in process!")
					return
				end

				server.Variables.RestoringMap = true
				Functions.Hint('Restoring Map...',service.Players:children())

				for i,v in pairs(service.Workspace:children()) do
					if v~=script and v.Archivable==true and not v:IsA('Terrain') then
						pcall(function() v:Destroy() end)
						service.RunService.Heartbeat:Wait()
					end
				end

				local new = Variables.MapBackup:Clone()
				new:MakeJoints()
				new.Parent = service.Workspace
				new:MakeJoints()

				for i,v in pairs(new:GetChildren()) do
					v.Parent = service.Workspace
					pcall(function() v:MakeJoints() end)
				end

				new:Destroy()

				service.Workspace.Terrain:Clear()
				service.Workspace.Terrain:PasteRegion(Variables.TerrainMapBackup, service.Workspace.Terrain.MaxExtents.Min, true)

				Admin.RunCommand(Settings.Prefix.."respawn","@everyone")
				server.Variables.RestoringMap = false
				Functions.Hint('Map Restore Complete.',service.Players:GetPlayers())
			end
		};
		
		ScriptBuilder = {
			Prefix = Settings.Prefix;
			Commands = {"sb"};
			Args = {"create/remove/edit/close/clear/append/run/stop/list","localscript/script","scriptName","data"};
			Description = "Script Builder; make a script, then edit it and chat it's code or use :sb append <codeHere>";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				assert(Settings.CodeExecution, "CodeExecution must be enabled for this command to work")
				local sb = Variables.ScriptBuilder[tostring(plr.userId)]
				if not sb then
					sb = {
						Script = {};
						LocalScript = {};
						Events = {};
					}
					Variables.ScriptBuilder[tostring(plr.userId)] = sb
				end

				local action = args[1]:lower()
				local class = args[2] or "LocalScript"
				local name = args[3]

				if class:lower() == "script" or class:lower() == "s" then
					class = "Script"
				elseif class:lower() == "localscript" or class:lower() == "ls" then
					class = "LocalScript"
				else
					class = "LocalScript"
				end

				if action == "create" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					local code = args[4] or " "

					if sb[class][name] then
						pcall(function()
							sb[class][name].Script.Disabled = true
							sb[class][name].Script:Destroy()
						end)
						if sb.ChatEvent then
							sb.ChatEvent:disconnect()
						end
					end

					local wrapped,scr = Core.NewScript(class,code,false,true)

					sb[class][name] = {
						Wrapped = wrapped;
						Script = scr;
					}

					if args[4] then
						Functions.Hint("Created "..class.." "..name.." and appended text",{plr})
					else
						Functions.Hint("Created "..class.." "..name,{plr})
					end
				elseif action == "edit" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					if sb[class][name] then
						local scr = sb[class][name].Script
						local tab = Core.GetScript(scr)
						if scr and tab then
							sb[class][name].Event = plr.Chatted:connect(function(msg)
								if msg:sub(1,#(Settings.Prefix.."sb")) == Settings.Prefix.."sb" then

								else
									tab.Source = tab.Source.."\n"..msg
									Functions.Hint("Appended message to "..class.." "..name,{plr})
								end
							end)
							Functions.Hint("Now editing "..class.." "..name.."; Chats will be appended",{plr})
						end
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "close" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					local scr = sb[class][name].Script
					local tab = Core.GetScript(scr)
					if sb[class][name] then
						if sb[class][name].Event then
							sb[class][name].Event:disconnect()
							Functions.Hint("No longer editing "..class.." "..name,{plr})
						end
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "clear" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					local scr = sb[class][name].Script
					local tab = Core.GetScript(scr)
					if scr and tab then
						tab.Source = " "
						Functions.Hint("Cleared "..class.." "..name,{plr})
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "remove" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					if sb[class][name] then
						pcall(function()
							sb[class][name].Script.Disabled = true
							sb[class][name].Script:Destroy()
						end)
						if sb.ChatEvent then
							sb.ChatEvent:disconnect()
						end
						sb[class][name] = nil
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "append" then
					assert(args[1] and args[2] and args[3] and args[4],"Argument missing or nil")
					if sb[class][name] then
						local scr = sb[class][name].Script
						local tab = Core.GetScript(scr)
						if scr and tab then
							tab.Source = tab.Source.."\n"..args[4]
							Functions.Hint("Appended message to "..class.." "..name,{plr})
						end
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "run" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					if sb[class][name] then
						if class == "LocalScript" then
							sb[class][name].Script.Parent = plr.Backpack
						else
							sb[class][name].Script.Parent = service.ServerScriptService
						end
						sb[class][name].Script.Disabled = true
						wait()
						sb[class][name].Script.Disabled = false
						Functions.Hint("Running "..class.." "..name,{plr})
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "stop" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					if sb[class][name] then
						sb[class][name].Script.Disabled = true
						Functions.Hint("Stopped "..class.." "..name,{plr})
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "list" then
					local tab = {}
					for i,v in pairs(sb.Script) do
						table.insert(tab,{Text = "Script: "..tostring(i),Desc = "Running: "..tostring(v.Script.Disabled)})
					end

					for i,v in pairs(sb.LocalScript) do
						table.insert(tab,{Text = "LocalScript: "..tostring(i),Desc = "Running: "..tostring(v.Script.Disabled)})
					end

					Remote.MakeGui(plr,"List",{Title = "SB Scripts",Table = tab})
				end
			end
		};

		MakeScript = {
			Prefix = Settings.Prefix;
			Commands = {"s";"scr";"script";"makescript"};
			Args = {"code";};
			Description = "Opens the Script Builder UI";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				assert(Settings.CodeExecution, "CodeExecution must be enabled for this command to work")
				Remote.MakeGui(plr, "ScriptBuilder", {Code = args[1] or nil})
			end
		};

		MakeLocalScript = {
			Prefix = Settings.Prefix;
			Commands = {"ls";"lscr";"localscript";};
			Args = {"code";};
			Description = "Lets you run code as a local script";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				local cl = Core.NewScript('LocalScript',"script.Parent = game:GetService('Players').LocalPlayer.PlayerScripts; "..args[1])
				cl.Parent = plr.Backpack
				cl.Disabled = false
				Functions.Hint("Ran LocalScript",{plr})
			end
		};

		LoadLocalScript = {
			Prefix = Settings.Prefix;
			Commands = {"cs";"cscr";"clientscript";};
			Args = {"player";"code";};
			Description = "Lets you run a localscript on the target player(s)";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				local new = Core.NewScript('LocalScript',"script.Parent = game:GetService('Players').LocalPlayer.PlayerScripts; "..args[2])
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local cl = new:Clone()
					cl.Parent = v.Backpack
					cl.Disabled = false
					Functions.Hint("Ran LocalScript on "..v.Name,{plr})
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
			AdminLevel = "Admins";
			Function = function(plr,args)
				local list = {}
				for i,v in pairs(Settings.Muted) do
					table.insert(list,v)
				end
				Remote.MakeGui(plr,"List",{Title = "Mute List",Table = list})
			end
		};

		Note = {
			Prefix = Settings.Prefix;
			Commands = {"note";"writenote";"makenote";};
			Args = {"player";"note";};
			Filter = true;
			Description = "Makes a note on the target player(s) that says <note>";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = Core.GetPlayer(v)
					if not PlayerData.AdminNotes then PlayerData.AdminNotes={} end
					table.insert(PlayerData.AdminNotes,args[2])
					Functions.Hint('Added '..v.Name..' Note '..args[2],{plr})
					Core.SavePlayer(v,PlayerData)
				end
			end
		};

		DeleteNote = {
			Prefix = Settings.Prefix;
			Commands = {"removenote";"remnote","deletenote"};
			Args = {"player";"note";};
			Description = "Removes a note on the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = Core.GetPlayer(v)
					if PlayerData.AdminNotes then
						if args[2]:lower() == "all" then
							PlayerData.AdminNotes={}
						else
							for k,m in pairs(PlayerData.AdminNotes) do
								if m:lower():sub(1,#args[2]) == args[2]:lower() then
									Functions.Hint('Removed '..v.Name..' Note '..m,{plr})
									table.remove(PlayerData.AdminNotes,k)
								end
							end
						end
						Core.SavePlayer(v,PlayerData)--v:SaveInstance("Admin Notes", notes)
					end
				end
			end
		};

		ShowNotes = {
			Prefix = Settings.Prefix;
			Commands = {"notes";"viewnotes";};
			Args = {"player";};
			Description = "Views notes on the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = Core.GetPlayer(v)
					local notes = PlayerData.AdminNotes
					if not notes then
						Functions.Hint('No notes on '..v.Name,{plr})
						return
					end
					Remote.MakeGui(plr,'List',{Title = v.Name,Table = notes})
				end
			end
		};

		LoopKill = {
			Prefix = Settings.Prefix;
			Commands = {"loopkill";};
			Args = {"player";"num(optional)";};
			Description = "Loop kills the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local num = tonumber(args[2]) or 9999

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StopLoop(v.userId.."LOOPKILL")
					Routine(service.StartLoop,v.userId.."LOOPKILL",3,function()
						v.Character:BreakJoints()
					end)
				end
			end
		};

		UnLoopKill = {
			Prefix = Settings.Prefix;
			Commands = {"unloopkill";};
			Args = {"player";};
			Hidden = false;
			Description = "Un-Loop Kill";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StopLoop(v.userId.."LOOPKILL")
				end
			end
		};

		Lag = {
			Prefix = Settings.Prefix;
			Commands = {"lag";"fpslag";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s)'s FPS drop";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						Remote.Send(v,"Function","SetFPS",5)
					end
				end
			end
		};

		UnLag = {
			Prefix = Settings.Prefix;
			Commands = {"unlag";"unfpslag";};
			Args = {"player";};
			Hidden = false;
			Description = "Un-Lag";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","RestoreFPS")
				end
			end
		};
		
		Forest = {
			Prefix = Settings.Prefix;
			Commands = {"forest";"sendtotheforest";"intothewoods";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends player to The Forest for a time out";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						service.TeleportService:Teleport(209424751,v)
					end
				end
			end
		};

		Maze = {
			Prefix = Settings.Prefix;
			Commands = {"maze";"sendtothemaze";"mazerunner";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends player to The Maze for a time out";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						service.TeleportService:Teleport(280846668,v)
					end
				end
			end
		};
		
		Nil = {
			Prefix = Settings.Prefix;
			Commands = {"nil";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends the target player(s) to the nil, where they can still run admin commands etc and just not show up on the player list";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					v.Character = nil
					v.Parent = nil
				end
			end
		};

		GameGravity = {
			Prefix = Settings.Prefix;
			Commands = {"ggrav","gamegrav","workspacegrav"};
			Args = {"number or fix"};
			Hidden = false;
			Description = "Sets Workspace.Gravity";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local num = tonumber(args[1])
				if num then
					service.Workspace.Gravity = num
				else
					service.Workspace.Gravity = 196.2
				end
			end
		};
		
		ClownYoink = {
			Prefix = server.Settings.Prefix; 					-- Someone's always watching me
			Commands = {"clown","yoink","youloveme","van"};   	-- Someone's always there
			Args = {"player"}; 									-- When I'm sleeping he just waits
			Description = "Clowns."; 							-- And he stares
			Fun = true; 										-- Someone's always standing in the
			Hidden = true; 										-- Darkest corner of my room
			AdminLevel = "Admins"; 								-- He's tall and wears a suit of black,
			Function = function(plr,args) 						-- Dressed like the perfect groom
				local data = server.Core.GetPlayer(plr)
				local forYou = {
					'"Who are you?"';
					'"I am Death," said the creature. "I thought that was obvious."';
					'"But you\'re so small!"';
					'"Only because you are small."';
					'"You are young and far from your Death, September, ..."';
					'"... so I seem as anything would seem if you saw it from a long way off ..."';
					'"... very small, very harmless."';
					'"But I am always closer than I appear."';
					'"As you grow, I shall grow with you ..."';
					'"... until at the end, I shall loom huge and dark over your bed ..."';
					'"... and you will shut your eyes so as not to see me."';

					'Find me.';
					'Fear me.';
					'Love me.';
				}

				if not args[1] then
					local ind = data.SleepInParadise or 1
					data.SleepInParadise = ind+1

					if ind == 14 then
						data.SleepInParadise = 12
					end

					error(forYou[ind])
				end

				for i,p in next,service.GetPlayers(plr,args[1]) do
					spawn(function()
						local char = p.Character
						local torso = p.Character:FindFirstChild("HumanoidRootPart")
						local humanoid = p.Character:FindFirstChild("Humanoid")
						if torso and humanoid and not char:FindFirstChild("ADONIS_VAN") then
							local van = server.Deps.Assets.Van:Clone()
							if van then
								local function check()
									if not van or not van.Parent or not p or p.Parent ~= service.Players or not torso or not humanoid or not torso.Parent or not humanoid.Parent or not char or not char.Parent then
										return false
									else
										return true
									end
								end

								local driver = van.Driver
								local grabber = van.Clown
								local primary = van.Primary
								local door = van.Door
								local tPos = torso.CFrame

								local sound = Instance.new("Sound",primary)
								sound.SoundId = "rbxassetid://258529216"
								sound.Looped = true
								sound:Play()

								local chuckle = Instance.new("Sound",primary)
								chuckle.SoundId = "rbxassetid://164516281"
								chuckle.Looped = true
								chuckle.Volume = 0.25
								chuckle:Play()

								van.PrimaryPart = van.Primary
								van.Name = "ADONIS_VAN"
								van.Parent = workspace
								humanoid.Name = "NoResetForYou"
								humanoid.WalkSpeed = 0
								sound.Pitch = 1.3

								server.Remote.PlayAudio(p,421358540,0.2,1,true)

								for i = 1,200 do
									if not check() then
										break
									else
										van:SetPrimaryPartCFrame(tPos*(CFrame.new(-200+i,-1,-7)*CFrame.Angles(0,math.rad(270),0)))
										wait(0.001*(i/5))
									end
								end

								sound.Pitch = 0.9

								wait(0.5)
								if check() then
									door.Transparency = 1
								end
								wait(0.5)

								if check() then
									torso.CFrame = primary.CFrame*(CFrame.new(0,2.3,0)*CFrame.Angles(0,math.rad(90),0))
								end

								wait(0.5)
								if check() then
									door.Transparency = 0
								end
								wait(0.5)

								sound.Pitch = 1.3
								server.Remote.MakeGui(p,"Effect",{
									Mode = "FadeOut";
								})

								p.CameraMaxZoomDistance = 0.5

								for i = 1,400 do
									if not check() then
										break
									else
										van:SetPrimaryPartCFrame(tPos*(CFrame.new(0+i,-1,-7)*CFrame.Angles(0,math.rad(270),0)))
										torso.CFrame = primary.CFrame*(CFrame.new(0,2.3,0)*CFrame.Angles(0,math.rad(90),0))
										wait(0.1/(i*5))

										if i == 270 then
											server.Remote.FadeAudio(p,421358540,nil,nil,0.5)
										end
									end
								end

								local gui = Instance.new("ScreenGui",service.ReplicatedStorage)
								local bg = Instance.new("Frame", gui)
								bg.BackgroundTransparency = 0
								bg.BackgroundColor3 = Color3.new(0,0,0)
								bg.Size = UDim2.new(2,0,2,0)
								bg.Position = UDim2.new(-0.5,0,-0.5,0)
								if p and p.Parent == service.Players then service.TeleportService:Teleport(527443962,p,nil,bg) end
								wait(0.5)
								pcall(function() van:Destroy() end)
								pcall(function() gui:Destroy() end)
							end
						end
					end)
				end
			end;
		};
	}

	for ind, com in pairs(Commands) do
		server.Commands[ind] = com
	end
end