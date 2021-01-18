server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil
sortedPairs = nil

--// Commands
--// Highly recommended you disable Intellesense before editing this...
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps
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
		Commands = server.Commands;
		Deps = server.Deps;

		--// Automatic New Command Caching and Ability to do server.Commands[":ff"]
		setmetatable(Commands, {
			__index = function(self, ind)
				local targInd = Admin.CommandCache[ind:lower()]
				if targInd then
					return rawget(Commands, targInd)
				end
			end;

			__newindex = function(self, ind, val)
				rawset(Commands, ind, val)
				if val and type(val) == "table" and val.Commands and val.Prefix then
					for i,cmd in next,val.Commands do
						Admin.CommandCache[(val.Prefix..cmd):lower()] = ind
					end
				end
			end;
		})

		Logs:AddLog("Script", "Commands Module Initialized")
	end;

	server.Commands = {
		Init = Init;
		Sudo = {
			Prefix = Settings.Prefix;
			Commands = {"sudo"};
			Arguments = {"player", "command"};
			Description = "Runs a command as the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr, args)
				assert(args[1] and args[2], "Argument missing or nil");
				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					Process.Command(v, args[2], {isSystem = true});
				end
			end;
		};

		ClearPlayerData = {
			Prefix = Settings.Prefix;
			Commands = {"clearplayerdata"};
			Arguments = {"userId"};
			Description = "Clears player data for target";
			AdminLevel = "Creators";
			Function = function(plr, args)
				local id = tonumber(args[1]) or plr.UserId
				Remote.PlayerData[id] = Core.DefaultData()
				Remote.MakeGui(plr,"Notification",{
					Title = "Notification";
					Message = "Cleared data";
					Time = 10;
				})
			end;
		};
		Davey = {
			Prefix = Settings.Prefix;
			Commands = {"Davey_Bones";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns you into me <3";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Admin.RunCommand(Settings.Prefix.."char",v.Name,"698712377")
				end
			end
		};--//hello Dr. Sceleratii ~Ender was here
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
				local lists = trello.getLists(board)
				local list = trello.getListObj(lists,{"Banlist","Ban List","Bans"})

				local level = data.PlayerData.Level
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > Admin.GetLevel(v) then
						trello.makeCard(list.id,tostring(v)..":".. tostring(v.UserId),
							"Administrator: " .. tostring(plr) ..
								"\nReason: ".. args[2] or "N/A")
						HTTP.Trello.Update()
						Functions.Hint("Trello banned ".. tostring(v),{plr})
					end
				end
			end;
		};
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
		Terminal = {
			Prefix = ":";
			Commands = {"terminal";"console";};
			Args = {};
			Hidden = true;
			Description = "Opens the the terminal";
			AdminLevel = "Creators";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Terminal")
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
		--[[
		TaskManager = { --// Unfinished
			Prefix = Settings.Prefix;
			Commands = {"taskmgr","taskmanager"};
			Args = {};
			Description = "Task manager";
			Hidden = true;
			AdminLevel = "Creators";
			Function = function(plr,args)
				Remote.MakeGui(plr,"TaskManager",{})
			end
		};
		--]]
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

		ViewCommands = {
			Prefix = Settings.Prefix;
			Commands = {"cmds","commands","cmdlist"};
			Args = {};
			Description = "Shows you a list of commands";
			AdminLevel = "Players";
			Function = function(plr,args)
				local commands = Admin.SearchCommands(plr,"all")
				local tab = {}
				local cStr

				for i,v in next,commands do
					if not v.Hidden then
						if type(v.AdminLevel) == "table" then
							cStr = ""
							for k,m in ipairs(v.AdminLevel) do
								cStr = cStr..m..", "
							end
						else
							cStr = tostring(v.AdminLevel)
						end

						table.insert(tab, {
							Text = Admin.FormatCommand(v),
							Desc = "["..cStr.."] "..v.Description,
							Filter = v.AdminLevel
						})
					end
				end

				Remote.MakeGui(plr,"List",
					{
						Title = "Commands";
						Table = tab;
					}
				)
			end
		};

		Prefix = {
			Prefix = "!";
			Commands = {"example";};
			Args = {};
			Description = "Shows you the command prefix using the :cmds command";
			AdminLevel = "Players";
			Function = function(plr,args)
				Functions.Hint('"'..Settings.Prefix..'cmds"',{plr})
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

		Admin = {
			Prefix = Settings.Prefix;
			Commands = {"permadmin","pa","padmin","fulladmin","realadmin"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) an admin; Saves";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr, args, data)
				local sendLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v,2)
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now an admin',{plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};

		Owner = {
			Prefix = Settings.Prefix;
			Commands = {"owner","oa","headadmin"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) an owner; Saves";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr, args, data)
				local sendLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v,3)
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now an owner',{plr})
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
							local ans = Remote.GetGui(plr,"YesNoPrompt",{
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

		CustomRank = {
			Prefix = Settings.Prefix;
			Commands = {"customrank","ca","crank"};
			Args = {"player";"rankName"};
			Hidden = false;
			Description = "Adds the player to a custom rank set in settings.CustomRanks; Does not save";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")

				local rank = args[2]
				local customRank = Settings.CustomRanks[rank]

				assert(customRank,"Rank not found!")

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.Hint("Added "..v.Name.." to "..rank,{plr})
					table.insert(customRank,v.Name..":"..v.userId)
				end
			end
		};

		UnCustomRank = {
			Prefix = Settings.Prefix;
			Commands = {"uncustomrank","unca","uncrank"};
			Args = {"player";"rankName"};
			Hidden = false;
			Description = "Removes the player from a custom rank set in settings.CustomRanks; Does not save";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")

				local rank = args[2]
				local customRank = Settings.CustomRanks[rank]

				assert(customRank,"Rank not found!")

				service.Iterate(customRank,function(i,v)
					if v:lower():sub(1,#args[1]) == args[1]:lower() then
						table.remove(customRank,i)
						Functions.Hint("Removed "..v.Name.." from "..rank,{plr})
					end
				end)
			end
		};

		CustomRanks = {
			Prefix = Settings.Prefix;
			Commands = {"customranks","cranks"};
			Args = {};
			Hidden = false;
			Description = "Shows custom ranks";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				local tab = {}
				service.Iterate(Settings.CustomRanks,function(rank,tab)
					table.insert(tab,{Text = rank, Desc = rank})
				end)
				Remote.MakeGui(plr,"List",{Title = "Custom Ranks";Table = tab})
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
		--[[
		DataBan = {
			Prefix = Settings.Prefix;
			Commands = {"databan";"permban";"gameban"};
			Args = {"player";};
			Hidden = false;
			Description = "Data persistent ban the target player(s); Undone using :undataban";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if not Admin.CheckAdmin(v) then
						local ans = Remote.GetGui(plr,"YesNoPrompt",{
							Question = "Are you sure you want to ban "..v.Name
						})

						if ans == "Yes" then
							local PlayerData = Core.GetPlayer(v)
							PlayerData.Banned = true
							v:Kick("You have been banned")
							Functions.Hint("Data Banned "..tostring(v),{plr})
						end
					else
						error(v.Name.." is currently an admin. Unadmin them before trying to perm ban them (this is so you don't accidentally ban an admin)")
					end
				end
			end
		};
		--]]
		--[[
		UnDataBan = {
			Prefix = Settings.Prefix;
			Commands = {"undataban";"undban";"untban";"unpermban";};
			Args = {"userid";};
			Hidden = false;
			Description = "Removes any data persistence bans (timeban or permban)";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")

				local userId = tonumber(args[1])
				assert(userId,tostring(userId).." is not a valid user ID")
				local PlayerData = Core.GetData(tostring(userId))
				assert(PlayerData,"No saved data found for "..userId)
				PlayerData.TimeBan = false
				PlayerData.Banned = false
				Core.SaveData(tostring(userId),PlayerData)
				Functions.Hint("Removed data ban for "..userId,{plr})
			end
		};
		--]]
		TimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"tban";"timedban";"timeban";};
			Args = {"player";"number<s/m/h/d>";};
			Hidden = false;
			Description = "Bans the target player(s) for the supplied amount of time; Data Persistent; Undone using :undataban";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args,data)
				local time = args[2] or '60'
				assert(args[1] and args[2], "Argument missing or nil")
				if time:lower():sub(#time)=='s' then
					time = time:sub(1,#time-1)
					time = tonumber(time)
				elseif time:lower():sub(#time)=='m' then
					time = time:sub(1,#time-1)
					time = tonumber(time)*60
				elseif time:lower():sub(#time)=='h' then
					time = time:sub(1,#time-1)
					time = (tonumber(time)*60)*60
				elseif time:lower():sub(#time)=='d' then
					time = time:sub(1,#time-1)
					time = ((tonumber(time)*60)*60)*24
				end

				local level = data.PlayerData.Level;
				for i,v in next,service.GetPlayers(plr, args[1], false, false, true) do
					if level > Admin.GetLevel(v) then
						local endTime = tonumber(os.time())+tonumber(time)
						local timebans = Core.Variables.TimeBans
						local data = {
							Name = v.Name;
							UserId = v.UserId;
							EndTime = endTime;
						}

						table.insert(timebans, data)
						Core.DoSave({
							Type = "TableAdd";
							Table = "TimeBans";
							Parent = "Variables";
							Value = data;
						})

						v:Kick("Banned until "..endTime)
						Functions.Hint("Banned "..v.Name.." for "..time,{plr})
					end
				end
			end
		};

		UnTimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"untimeban";};
			Args = {"player";};
			Hidden = false;
			Description = "UnBan";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1], "Argument missing or nil")
				local timebans = Core.Variables.TimeBans or {}
				for i, data in next, timebans do
					if data.Name:lower():sub(1,#args[1]) == args[1]:lower() then
						table.remove(timebans, i)
						Core.DoSave({
							Type = "TableRemove";
							Table = "TimeBans";
							Parent = "Variables";
							Value = data;
						})
						Functions.Hint(tostring(data.Name)..' has been Unbanned',{plr})
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
				local variables = Core.Variables
				local timeBans = Core.Variables.TimeBans or {}
				for i,v in next,timeBans do
					local timeLeft = v.EndTime-os.time()
					local minutes = Functions.RoundToPlace(timeLeft/60, 2)
					if timeLeft <= 0 then
						table.remove(Core.Variables.TimeBans, i)
					else
						table.insert(tab,{Text = tostring(v.Name)..":"..tostring(v.UserId),Desc = "Minutes Left: "..tostring(minutes)})
					end
				end
				Remote.MakeGui(plr,"List",{Title = 'Time Bans', Tab = tab})
			end
		};

		Ban = {
			Prefix = Settings.Prefix;
			Commands = {"ban";};
			Args = {"player";};
			Description = "Bans the player from the server";
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				local level = data.PlayerData.Level
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > Admin.GetLevel(v) then
						Admin.AddBan(v)
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

		GameBan = {
			Prefix = Settings.Prefix;
			Commands = {"gameban", "saveban", "databan"};
			Args = {"player";};
			Description = "Bans the player from the game (Saves)";
			AdminLevel = "Owners";
			Function = function(plr,args,data)
				local level = data.PlayerData.Level
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > Admin.GetLevel(v) then
						Admin.AddBan(v, true)
						Functions.Hint("Game banned "..tostring(v),{plr})
					end
				end
			end
		};

		UnGameBan = {
			Prefix = Settings.Prefix;
			Commands = {"ungameban", "saveunban", "undataban"};
			Args = {"player";};
			Description = "UnBans the player from game (Saves)";
			AdminLevel = "Owners";
			Function = function(plr,args)
				local ret = Admin.RemoveBan(args[1], true)
				if ret then
					Functions.Hint(tostring(ret)..' has been Unbanned',{plr})
				end
			end
		};

		DirectBan = {
			Prefix = Settings.Prefix;
			Commands = {"directban"};
			Args = {"player";};
			Description = "DirectBans the player (Saves)";
			AdminLevel = "Creators";
			Function = function(plr,args,data)
				for i in string.gmatch(args[1], "[^,]+") do
					local userid = service.Players:GetUserIdFromNameAsync(i)

					if userid == plr.UserId then
						error("You cannot ban yourself or the creator of the game", 2)
						return
					end

					if userid then
						Core.DoSave({
							Type = "TableAdd";
							Table = "Banned";
							Value = i..':'..userid;
						})

						Core.CrossServer("Loadstring", "server.Remote.Send(service.Players."..i..", 'Kill')")
						Functions.Hint("System-Banned "..i..":"..userid, {plr})
					end
				end
			end
		};
		
		UnDirectBan = {
			Prefix = Settings.Prefix;
			Commands = {"undirectban"};
			Args = {"player";};
			Description = "UnDirectBans the player (Saves)";
			AdminLevel = "Creators";
			Function = function(plr,args,data)
				for i in string.gmatch(args[1], "[^,]+") do
					local userid = service.Players:GetUserIdFromNameAsync(i)

					if userid then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Banned";
							Value = i..':'..userid;
						})
						
						Functions.Hint("System-UnBanned "..i..":"..userid, {plr})
					end
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

		--[[FullShutdown = {
			Prefix = Settings.Prefix;
			Commands = {"fullshutdown"};
			Args = {"reason"};
			Description = "Initiates a shutdown for every running game server";
			PanicMode = true;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not Core.PanicMode then
					local logs = Core.GetData("ShutdownLogs") or {}
					if plr then
						table.insert(logs,1,{User=plr.Name,Time=service.GetTime(),Reason=args[2] or "N/A"})
					else
						table.insert(logs,1,{User="Server/Trello",Time=service.GetTime(),Reason=args[2] or "N/A"})
					end
					if #logs>1000 then
						table.remove(logs,#logs)
					end
					Core.SaveData("ShutdownLogs",logs)
				end

				Core.SaveData("FullShutdown", {ID = game.PlaceId; User = tostring(plr or "Server"); Reason = args[2]})
			end
		};--]]

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
					Variables.ServerLock = true
					Functions.Hint("Server Locked",{plr})
				elseif args[1]:lower() == "off" or args[1]:lower() == "false" then
					Variables.ServerLock = false
					Functions.Hint("Server Unlocked",{plr})
				end
			end
		};

		Whitelist = {
			Prefix = Settings.Prefix;
			Commands = {"wl","enablewhitelist","whitelist"};
			Args = {"on/off or add/remove","optional player"};
			Hidden = false;
			Description = "Enables/disables the whitelist; :wl username to add them to the whitelist";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if args[1]:lower()=='on' or args[1]:lower()=='enable' then
					Variables.Whitelist.Enabled = true
					Functions.Hint("Server Whitelisted", service.Players:GetPlayers())
				elseif args[1]:lower()=='off' or args[1]:lower()=='disable' then
					Variables.Whitelist.Enabled = false
					Functions.Hint("Server Unwhitelisted", service.Players:GetPlayers())
				elseif args[1]:lower()=="add" then
					if args[2] then
						local plrs = service.GetPlayers(plr,args[2],true)
						if #plrs>0 then
							for i,v in pairs(plrs) do
								table.insert(Variables.Whitelist.List,v.Name..":"..v.userId)
								Functions.Hint("Whitelisted "..v.Name,{plr})
							end
						else
							table.insert(Variables.Whitelist.List,args[2])
						end
					else
						error('Missing name to whitelist')
					end
				elseif args[1]:lower()=="remove" then
					if args[2] then
						for i,v in pairs(Variables.Whitelist.List) do
							if v:lower():sub(1,#args[2]) == args[2]:lower() then
								table.remove(Variables.Whitelist.List,i)
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

		SetBanMessage = {
			Prefix = Settings.Prefix;
			Commands = {"setbanmessage";"setbmsg"};
			Args = {"message";};
			Filter = true;
			Description = "Sets the ban message banned players see";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				Variables.BanMessage = args[1]
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

		Notepad = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notepad","stickynote"};
			Args = {};
			Description = "Opens a textbox window for you to type into";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Window",{
					Name = "Notepad";
					Title = "Notepad";
					CanvasSize = UDim2.new(0,0,10,0);
					Ready = true;
					--Menu = {
					--	{
					--		Class = "TextButton";
					--		Size = UDim2.new(0,50,1,0);
					--		Text = "File";
					--	};
					--};

					Content = {

						{
							Class = "TextBox";
							Size = UDim2.new(1,-5,1,0);
							Position = UDim2.new(0,0,0,0);
							BackgroundColor3 = Color3.new(1,1,1);
							TextColor3 = Color3.new(0,0,0);
							Font = "Code";
							FontSize = "Size18";
							TextXAlignment = "Left";
							TextYAlignment = "Top";
							TextWrapped = true;
							TextScaled = false;
							ClearTextOnFocus = false;
							MultiLine = true;
							Text = "";
						};
					}
				})
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
					})
				end
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
						Message = args[1]; --service.Filter(args[1],plr,v);
					})
				end
			end
		};

		GlobalMessage = {
			Prefix = Settings.Prefix;
			Commands = {"globalmessage","gm","globalannounce"};
			Args = {"message"};
			Description = "Sends a global message to all servers";
			AdminLevel = "Owners";
			Filter = true;
			CrossServerDenied = true;
			Function = function(plr,args)
				assert(args[1], "Argument #1 must be supplied")
				
				if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, Settings.Prefix.."m "..args[1]) then
					error("CrossServer Handler Not Ready");
				end
			end;	
		};

		GlobalPlace = {
			Prefix = Settings.Prefix;
			Commands = {"globalplace","gplace"};
			Args = {"placeid"};
			Description = "Sends a global message to all servers";
			AdminLevel = "Creators";
			CrossServerDenied = true;
			Function = function(plr,args)
				assert(args[1], "Argument #1 must be supplied")
				assert(tonumber(args[1]), "Argument #1 must be a number")
				
				if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, Settings.Prefix.."forceplace all "..args[1]) then
					error("CrossServer Handler Not Ready");
				end
			end;
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

		ClientTab = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"client";"clientsettings","playersettings"};
			Args = {};
			Hidden = false;
			Description = "Opens the client settings panel";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Client"})
			end
		};

		Donate = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"donate";"change";"changecape";"donorperks";};
			Args = {};
			Hidden = false;
			Description = "Opens the donation panel";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Donate"})
			end
		};

		DonorUncape = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"uncape";"removedonorcape";};
			Args = {};
			Hidden = false;
			Description = "Remove donor cape";
			Fun = false;
			AllowDonors = true;
			AdminLevel = "Donors";
			Function = function(plr,args)
				Functions.UnCape(plr)
			end
		};

		DonorCape = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"cape";"donorcape";};
			Args = {};
			Hidden = false;
			Description = "Get donor cape";
			Fun = false;
			AllowDonors = true;
			AdminLevel = "Donors";
			Function = function(plr,args)
				Functions.Donor(plr)
			end
		};

		DonorShirt = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"shirt";"giveshirt";};
			Args = {"ID";};
			Hidden = false;
			Description = "Give you the shirt that belongs to <ID>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				if plr.Character then
					local ClothingId = tonumber(args[1])
					local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
					local Shirt = AssetIdType == 11 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Shirt", ClothingId) or error("Item ID passed has invalid item type")
					if Shirt then
						for g,k in pairs(plr.Character:GetChildren()) do
							if k:IsA("Shirt") then k:Destroy() end
						end
						local humanoid = plr.Character:FindFirstChildOfClass'Humanoid'
						local humandescrip = humanoid and humanoid:FindFirstChildOfClass"HumanoidDescription"

						if humandescrip then
							humandescrip.Shirt = ClothingId
						end
						Shirt:Clone().Parent = plr.Character
					else
						error("Unexpected error occured. Clothing is missing")
					end
				end
			end
		};

		DonorPants = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pants";"givepants";};
			Args = {"id";};
			Hidden = false;
			Description = "Give you the pants that belongs to <id>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				if plr.Character then
					local ClothingId = tonumber(args[1])
					local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
					local Pants = AssetIdType == 12 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Pants", ClothingId) or error("Item ID passed has invalid item type")
					if Pants then
						for g,k in pairs(plr.Character:GetChildren()) do
							if k:IsA("Pants") then k:Destroy() end
						end

						local humanoid = plr.Character:FindFirstChildOfClass'Humanoid'
						local humandescrip = humanoid and humanoid:FindFirstChildOfClass"HumanoidDescription"

						if humandescrip then
							humandescrip.Pants = ClothingId
						end

						Pants:Clone().Parent = plr.Character
					else
						error("Unexpected error occured. Clothing is missing")
					end
				end
			end
		};

		DonorFace = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"face";"giveface";};
			Args = {"id";};
			Hidden = false;
			Description = "Gives you the face that belongs to <id>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				if plr.Character and plr.Character:findFirstChild("Head") and plr.Character.Head:findFirstChild("face") then
					plr.Character.Head:findFirstChild("face"):Destroy()
				end

				local id = tonumber(args[1])
				local market = service.MarketPlace
				local info = market:GetProductInfo(id)
				
				local humanoid = plr.Character:FindFirstChildOfClass'Humanoid'
				local humandescrip = humanoid and humanoid:FindFirstChildOfClass"HumanoidDescription"

				if humandescrip then
					humandescrip.Face = id
				end
				
				if info.AssetTypeId == 18 or info.AssetTypeId == 9 then
					service.Insert(args[1]).Parent = plr.Character:FindFirstChild("Head")
				else
					error("Invalid face ID")
				end
			end
		};

		DonorNeon = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"neon";};
			Args = {"color";};
			Hidden = false;
			Description = "Changes your body material to neon and makes you the (optional) color of your choosing.";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				if plr.Character then
					for k,p in pairs(plr.Character:children()) do
						if p:IsA("Part") then
							if args[1] then
								local str = BrickColor.new('Institutional white').Color
								local teststr = args[1]
								if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
								p.BrickColor = str
							end
							p.Material = "Neon"
						end
					end
				end
			end
		};

		DonorFire = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"fire";"donorfire";};
			Args = {"color (optional)";};
			Hidden = false;
			Description = "Gives you fire with the specified color (if you specify one)";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					local secondary = Color3.new(1,0,0)
					if args[1] then
						local str = BrickColor.new('Cyan').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
						secondary = str
					end

					Functions.RemoveParticle(torso,"DONOR_FIRE")
					Functions.NewParticle(torso,"Fire",{
						Name = "DONOR_FIRE";
						Color = color;
						SecondaryColor = secondary;
					})
					Functions.RemoveParticle(torso,"DONOR_FIRE_LIGHT")
					Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_FIRE_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorSparkles = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"sparkles";"donorsparkles";};
			Args = {"color (optional)";};
			Hidden = false;
			Description = "Gives you sparkles with the specified color (if you specify one)";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					if args[1] then
						local str = BrickColor.new('Bright orange').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
					end

					Functions.RemoveParticle(torso,"DONOR_SPARKLES")
					Functions.RemoveParticle(torso,"DONOR_SPARKLES_LIGHT")
					Functions.NewParticle(torso,"Sparkles",{
						Name = "DONOR_SPARKLES";
						SparkleColor = color;
					})

					Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_SPARKLES_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorLight = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"light";"donorlight";};
			Args = {"color (optional)";};
			Hidden = false;
			Description = "Gives you a PointLight with the specified color (if you specify one)";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					if args[1] then
						local str = BrickColor.new('Cyan').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
					end

					Functions.RemoveParticle(torso,"DONOR_LIGHT")
					Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorParticle = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"particle";};
			Args = {"textureid";"startColor3";"endColor3";};
			Hidden = false;
			Description = "Put a custom particle emitter on your character";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")

				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local startColor = {}
					local endColor = {}

					if args[2] then
						for s in args[2]:gmatch("[%d]+")do
							table.insert(startColor,tonumber(s))
						end
					end
					if args[3] then--276138620 :)
						for s in args[3]:gmatch("[%d]+")do
							table.insert(endColor,tonumber(s))
						end
					end

					local startc = Color3.new(1,1,1)
					local endc = Color3.new(1,1,1)
					if #startColor==3 then
						startc = Color3.new(startColor[1],startColor[2],startColor[3])
					end
					if #endColor==3 then
						endc = Color3.new(endColor[1],endColor[2],endColor[3])
					end

					Functions.RemoveParticle(torso,"DONOR_PARTICLE")
					Functions.NewParticle(torso,"ParticleEmitter",{
						Name = "DONOR_PARTICLE";
						Texture = 'rbxassetid://'..args[1]; --Functions.GetTexture(args[1]);
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
		};

		DonorUnparticle = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unparticle";"removeparticles";};
			Args = {};
			Hidden = false;
			Description = "Removes donor particles on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso,"DONOR_PARTICLE")
			end
		};

		DonorUnfire = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unfire";"undonorfire";};
			Args = {};
			Hidden = false;
			Description = "Removes donor fire on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso,"DONOR_FIRE")
				Functions.RemoveParticle(torso,"DONOR_FIRE_LIGHT")
			end
		};

		DonorUnsparkles = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unsparkles";"undonorsparkles";};
			Args = {};
			Hidden = false;
			Description = "Removes donor sparkles on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso,"DONOR_SPARKLES")
				Functions.RemoveParticle(torso,"DONOR_SPARKLES_LIGHT")
			end
		};

		DonorUnlight = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unlight";"undonorlight";};
			Args = {};
			Hidden = false;
			Description = "Removes donor light on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso,"DONOR_LIGHT")
			end
		};

		DonorHat = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"hat";"gethat";};
			Args = {"ID";};
			Hidden = false;
			Description = "Gives you the hat specified by <ID>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local id = tonumber(args[1])
				local hats = 0
				for i,v in pairs(plr.Character:GetChildren()) do if v:IsA("Accoutrement") then hats = hats+1 end end
				if id and hats<15 then
					local market = service.MarketPlace
					local info = market:GetProductInfo(id)
					if info.AssetTypeId == 8 or (info.AssetTypeId >= 41 and info.AssetTypeId <= 47) then
						local hat = service.Insert(id)
						assert(hat,"Invalid ID")
						local banned = {
							Script = true;
							LocalScript = true;
							Tool = true;
							HopperBin = true;
							ModuleScript = true;
							RemoteFunction = true;
							RemoteEvent = true;
							BindableEvent = true;
							Folder = true;
							RocketPropulsion = true;
							Explosion = true;
						}

						local removeScripts; removeScripts = function(obj)
							for i,v in pairs(obj:GetChildren()) do
								pcall(function()
									removeScripts(v)
									if banned[v.ClassName] then
										v:Destroy()
									end
								end)
							end
						end

						removeScripts(hat)
						hat.Parent = plr.Character
						hat.Changed:connect(function()
							if hat.Parent ~= plr.Character then
								hat:Destroy()
							end
						end)
					end
				end
			end
		};

		DonorRemoveHats = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"removehats";"nohats";};
			Args = {};
			Hidden = false;
			Description = "Removes any hats you are currently wearing";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				for i,v in pairs(plr.Character:children()) do
					if v:IsA("Accoutrement") then
						v:Destroy()
					end
				end
			end
		};

		Keybinds = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"keybinds";"binds";"bind";"keybind";"clearbinds";"removebind";};
			Args = {};
			Hidden = false;
			Description = "Opens the keybind manager";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "KeyBinds"})
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
					service.ChatService:Chat(p.Character.Head,message,Enum.ChatColor.Blue)
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
							ice.BrickColor=BrickColor.new("Steel blue")
							ice.Material="Ice"
							ice.Name="Adonis_Ice"
							ice.Anchored=true
							--ice.CanCollide=false
							ice.TopSurface="Smooth"
							ice.BottomSurface="Smooth"
							ice.FormFactor="Custom"
							ice.Size=Vector3.new(5, 6, 5)
							ice.Transparency=0.3
							ice.CFrame=v.Character.HumanoidRootPart.CFrame
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
								plate.Name = "[EISS] Water"
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

		wat = { --// wat??
			Prefix = "!";
			Commands = {"wat";};
			Args = {};
			Hidden = true;
			Description = "???";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local wot = {227499602,153622804,196917825,217714490,130872377,142633540,130936426,130783238,151758509,259702986}
				Remote.Send(plr,"Function","PlayAudio",wot[math.random(1,#wot)])
			end
		};

		ScriptInfo = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"info";"about";"userpanel";};
			Args = {};
			Hidden = false;
			Description = "Shows info about the script";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Info"})
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

		ShowSBL = {
			Prefix = Settings.Prefix;
			Commands = {"sbl";"syncedbanlist";"globalbanlist";"trellobans";"trellobanlist";};
			Args = {};
			Hidden = false;
			Description = "Shows Trello bans";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				Remote.MakeGui(plr,"List",{
					Title = "Synced Ban List";
					Tab = HTTP.Trello.Bans;
				})
			end
		};

		MakeList = {
			Prefix = Settings.Prefix;
			Commands = {"makelist";"newlist";"newtrellolist";"maketrellolist";};
			Args = {"name";};
			Hidden = false;
			Description = "Adds a list to the Trello board set in Settings. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not args[1] then error("Missing argument") end
				local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
				local list = trello.makeList(Settings.Trello_Primary,args[1])
				Functions.Hint("Made list "..list.name,{plr})
			end
		};

		ViewList = {
			Prefix = Settings.Prefix;
			Commands = {"viewlist";"viewtrellolist";};
			Args = {"name";};
			Hidden = false;
			Description = "Views the specified Trello list from the board set in Settings.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not args[1] then error("Missing argument") end
				local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
				local list = trello.getList(Settings.Trello_Primary,args[1])
				if not list then error("List not found.") end
				local cards = trello.getCards(list.id)
				local temp = {}
				for i,v in pairs(cards) do
					table.insert(temp,{Text=v.name,Desc=v.desc})
				end
				Remote.MakeGui(plr,"List",{Title = list.name; Tab = temp})
			end
		};

		MakeCard = {
			Prefix = Settings.Prefix;
			Commands = {"makecard", "maketrellocard", "createcard"};
			Args = {};
			Hidden = false;
			Description = "Opens a gui to make new Trello cards. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				Remote.MakeGui(plr,"CreateCard")
			end
		};

		GetScript = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"getscript";"getadonis"};
			Args = {};
			Hidden = false;
			Description = "Get this script.";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				service.MarketPlace:PromptPurchase(plr, Core.LoaderID)
			end
		};

		Ping = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"ping";};
			Args = {};
			Hidden = false;
			Description = "Shows you your current ping (in seconds)";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,'Ping')
			end
		};

		GetPing = {
			Prefix = Settings.Prefix;
			Commands = {"getping";};
			Args = {"player";};
			Hidden = false;
			Description = "Shows the target player's ping (in seconds)";
			Fun = false;
			AdminLevel = "Helpers";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.Hint(v.Name.."'s Ping is "..Remote.Get(v,"Ping").."ms",{plr})
				end
			end
		};

		Donors = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"donors";"donorlist";"donatorlist";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of donators who are currently in the server";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local temptable = {}
				for i,v in pairs(service.Players:children()) do
					if Admin.CheckDonor(v) then
						table.insert(temptable,v.Name)
					end
				end
				Remote.MakeGui(plr,'List',{Title = 'Donors In-Game'; Tab = temptable; Update = 'DonorList'})
			end
		};

		RequestHelp = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"help";"requesthelp";"gethelp";"lifealert";};
			Args = {};
			Hidden = false;
			Description = "Calls admins for help";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				if Settings.HelpSystem == true then
					local num = 0
					local answered = false
					local pending = Variables.HelpRequests[plr.Name];

					if pending and os.time() - pending.Time < 30 then
						error("You can only send a help request once every 30 seconds.");
					elseif pending and pending.Pending then
						error("You already have a pending request")
					else
						service.TrackTask("Thread: ".. tostring(plr).. " Help Request Handler", function()
							Functions.Hint("Request sent",{plr})

							pending = {
								Time = os.time();
								Pending = true;
							}

							Variables.HelpRequests[plr.Name] = pending;

							for ind,p in pairs(service.Players:GetPlayers()) do
								if Admin.CheckAdmin(p) then
									local ret = Remote.MakeGuiGet(p,"Notification",{
										Title = "Help Request";
										Message = plr.Name.." needs help!";
										Time = 30;
										OnClick = Core.Bytecode("return true");
										OnClose = Core.Bytecode("return false");
										OnIgnore = Core.Bytecode("return false");
									})

									num = num+1
									if ret then
										if not answered then
											answered = true
											Admin.RunCommand(Settings.Prefix.."tp",p.Name,plr.Name)
										end
									end
								end
							end

							local w = tick()
							repeat wait(0.5) until tick()-w>30 or answered

							pending.Pending = false;

							if not answered then
								Functions.Message("Help System","Sorry but no one is available to help you right now",{plr})
							end
						end)
					end
				else
					Functions.Message("Help System","Help System Disabled by Place Owner",{plr})
				end
			end
		};

		Rejoin = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"rejoin";};
			Args = {};
			Hidden = false;
			Description = "Makes you rejoin the server";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local succeeded, errorMsg, placeId, instanceId = service.TeleportService:GetPlayerPlaceInstanceAsync(plr.userId)
				if succeeded then
					service.TeleportService:TeleportToPlaceInstance(placeId, instanceId, plr)
				else
					Functions.Hint("Could not rejoin.")
				end
			end
		};

		Join = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"join";"follow";"followplayer";};
			Args = {"username";};
			Hidden = false;
			Description = "Makes you follow the player you gave the username of to the server they are in";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local player = service.Players:GetUserIdFromNameAsync(args[1])
				if player then
					local succeeded, errorMsg, placeId, instanceId = service.TeleportService:GetPlayerPlaceInstanceAsync(player)
					if succeeded then
						service.TeleportService:TeleportToPlaceInstance(placeId, instanceId, plr)
					else
						Functions.Hint("Could not follow "..args[1]..". "..errorMsg,{plr})
					end
				else
					Functions.Hint(args[1].." is not a valid Roblox user",{plr})
				end
			end
		};

		GlobalJoin = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"joinfriend";};
			Args = {"username";};
			Hidden = false;
			Description = "Joins your friend outside/inside of the game (must be online)";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args) -- uses Player:GetFriendsOnline()
				--// NOTE: MAY NOT WORK IF "ALLOW THIRD-PARTY GAME TELEPORTS" (GAME SECURITY PERMISSION) IS DISABLED

				local player = service.Players:GetUserIdFromNameAsync(args[1])
				
				if player then
					for i,v in next, plr:GetFriendsOnline() do
						if v.VisitorId == player and v.IsOnline and v.PlaceId and v.GameId then
							local new = Core.NewScript('LocalScript',"service.TeleportService:TeleportToPlaceInstance("..v.PlaceId..", "..v.GameId..", "..plr:GetFullName()..")")
							new.Disabled = false
							new.Parent = plr:FindFirstChildOfClass"Backpack"
						end
					end
				else
					Functions.Hint(args[1].." is not a valid Roblox user",{plr})
				end
			end
		};

		HandTo = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"handto";};
			Args = {"player";};
			Hidden = false;
			Description = "Hands an item to a player";
			Fun = false;
			AdminLevel = "Players";
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

		Agents = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"agents";"trelloagents";"showagents";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of Trello agents pulled from the configured boards";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local temp={}
				for i,v in pairs(HTTP.Trello.Agents) do
					table.insert(temp,{Text = v,Desc = "A Trello agent"})
				end
				Remote.MakeGui(plr,"List",{Title = "Agents", Tab = temp})
			end
		};

		Credits = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"credit";"credits";};
			Args = {};
			Hidden = false;
			Description = "Credits";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"List",{
					Title = 'Credits',
					Tab = server.Credits
				})
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

		Usage = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"usage";};
			Args = {};
			Hidden = false;
			Description = "Shows you how to use some syntax related things";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local usage={
					'Mouse over things in lists to expand them';
					'Special Functions: ';
					'Ex: '..Settings.Prefix..'kill FUNCTION, so like '..Settings.Prefix..'kill '..Settings.SpecialPrefix..'all';
					'Put /e in front to make it silent (/e '..Settings.Prefix..'kill scel)';
					Settings.SpecialPrefix..'me - Runs a command on you';
					Settings.SpecialPrefix..'all - Runs a command on everyone';
					Settings.SpecialPrefix..'admins - Runs a command on all admins in the game';
					Settings.SpecialPrefix..'nonadmins - Same as !admins but for people who are not an admin';
					Settings.SpecialPrefix..'others - Runs command on everyone BUT you';
					Settings.SpecialPrefix..'random - Runs command on a random person';
					Settings.SpecialPrefix..'friends - Runs command on anyone on your friends list';
					Settings.SpecialPrefix..'besties - Runs command on anyone on your best friends list';
					'%TEAMNAME - Runs command on everyone in the team TEAMNAME Ex: '..Settings.Prefix..'kill %raiders';
					'$GROUPID - Run a command on everyone in the group GROUPID, Will default to the GroupId setting if no id is given';
					'-PLAYERNAME - Will remove PLAYERNAME from list of players to run command on. '..Settings.Prefix..'kill all,-scel will kill everyone except scel';
					'#NUMBER - Will run command on NUMBER of random players. '..Settings.Prefix..'ff #5 will ff 5 random players.';
					'radius-NUMBER -- Lets you run a command on anyone within a NUMBER stud radius of you. '..Settings.Prefix..'ff radius-5 will ff anyone within a 5 stud radius of you.';
					'Certain commands can be used by anyone, these commands have '..Settings.PlayerPrefix..' infront, such as '..Settings.PlayerPrefix..'clean and '..Settings.PlayerPrefix..'rejoin';
					''..Settings.Prefix..'kill me,noob1,noob2,'..Settings.SpecialPrefix..'random,%raiders,$123456,!nonadmins,-scel';
					'Multiple Commands at a time - '..Settings.Prefix..'ff me '..Settings.BatchKey..' '..Settings.Prefix..'sparkles me '..Settings.BatchKey..' '..Settings.Prefix..'rocket jim';
					'You can add a wait if you want; '..Settings.Prefix..'ff me '..Settings.BatchKey..' !wait 10 '..Settings.BatchKey..' '..Settings.Prefix..'m hi we waited 10 seconds';
					''..Settings.Prefix..'repeat 10(how many times to run the cmd) 1(how long in between runs) '..Settings.Prefix..'respawn jim';
					'Place owners can edit some settings in-game via the '..Settings.Prefix..'settings command';
					'Please refer to the Tips and Tricks section under the settings in the script for more detailed explanations'
				}
				Remote.MakeGui(plr,"List",{Title = 'Usage', Tab = usage})
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
		
		--[[Viewport = {
			Prefix = Settings.Prefix;
			Commands = {"viewport", "cctv"};
			Args = {"player";};
			Description = "Makes a viewport of the target player<s>";
			Agents = true;
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

		ChangeLog = {
			Prefix = Settings.Prefix;
			Commands = {"changelog";"changes";};
			Args = {};
			Description = "Shows you the script's changelog";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"List",{
					Title = 'Change Log',
					Table = server.Changelog,
					Size = {500,400}
				})
			end
		};

		AdminList = {
			Prefix = Settings.Prefix;
			Commands = {"admins";"adminlist";"owners";"Moderators";};
			Args = {};
			Hidden = false;
			Description = "Shows you the list of admins, also shows admins that are currently in the server";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temptable = {}

				for i,v in pairs(Settings.Creators) do
					table.insert(temptable,v .. " - Creator")
				end

				for i,v in pairs(Settings.Owners) do
					table.insert(temptable,v .. " - Owner")
				end

				for i,v in pairs(Settings.Admins) do
					table.insert(temptable,v .. " - Admin")
				end

				for i,v in pairs(Settings.Moderators) do
					table.insert(temptable,v .. " - Mod")
				end

				for i,v in pairs(HTTP.Trello.Creators) do
					table.insert(temptable,v .. " - Creator [Trello]")
				end

				for i,v in pairs(HTTP.Trello.Moderators) do
					table.insert(temptable,v .. " - Mod [Trello]")
				end

				for i,v in pairs(HTTP.Trello.Admins) do
					table.insert(temptable,v .. " - Admin [Trello]")
				end

				for i,v in pairs(HTTP.Trello.Owners) do
					table.insert(temptable,v .. " - Owner [Trello]")
				end

				for i,v in pairs(server.HTTP.WebPanel.Creators) do
					table.insert(temptable,v .. " - Creator [WebPanel]")
				end

				for i,v in pairs(server.HTTP.WebPanel.Moderators) do
					table.insert(temptable,v .. " - Mod [WebPanel]")
				end

				for i,v in pairs(server.HTTP.WebPanel.Admins) do
					table.insert(temptable,v .. " - Admin [WebPanel]")
				end

				for i,v in pairs(server.HTTP.WebPanel.Owners) do
					table.insert(temptable,v .. " - Owner [WebPanel]")
				end

				service.Iterate(Settings.CustomRanks,function(rank,tab)
					service.Iterate(tab,function(ind,admin)
						table.insert(temptable,admin.." - "..rank)
					end)
				end)

				table.insert(temptable,'==== Admins In-Game ====')
				for i,v in pairs(service.GetPlayers()) do
					local level = Admin.GetLevel(v)
					if level>=4 then
						table.insert(temptable,v.Name..' - Creator')
					elseif level>=3 then
						table.insert(temptable,v.Name..' - Owner')
					elseif level>=2 then
						table.insert(temptable,v.Name..' - Admin')
					elseif level>=1 then
						table.insert(temptable,v.Name..' - Mod')
					end

					service.Iterate(Settings.CustomRanks,function(rank,tab)
						if Admin.CheckTable(v,tab) then
							table.insert(temptable,v.Name.." - "..rank)
						end
					end)
				end

				Remote.MakeGui(plr,"List",{Title = 'Admin List',Table = temptable})
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

		Clean = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"clean";};
			Args = {};
			Hidden = false;
			Description = "Cleans some useless junk out of service.Workspace";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Functions.CleanWorkspace()
			end
		};

		Chik3n = {
			Prefix = Settings.Prefix;
			Commands = {"chik3n","zelith","z3lith"};
			Args = {};
			Hidden = false;
			Description = "Call on the KFC dark prophet powers of chicken";
			Fun = true;
			AdminLevel = "Owners";
			Function = function(plr, args)
				local hats = {}
				local tempHats = {}
				local run = true
				local hat = service.Insert(24112667):children()[1]
				--
				local scr = Deps.Assets.Quacker:Clone()
				scr.Name = "Quacker"
				scr.Parent = hat
				--]]
				hat.Anchored = true
				hat.CanCollide = false
				hat.ChickenSounds.Disabled = true
				table.insert(hats,hat)
				table.insert(Variables.Objects,hat)
				hat.Parent = workspace
				hat.CFrame = plr.Character.Head.CFrame
				service.StopLoop("ChickenSpam")
				service.StartLoop("ChickenSpam",5,function()
					tempHats = {}
					for i,v in pairs(hats) do
						wait(0.5)
						if not hat or not hat.Parent or not scr or not scr.Parent then
							break
						end
						local nhat = hat:Clone()
						table.insert(tempHats, v)
						table.insert(tempHats,nhat)
						table.insert(Variables.Objects,nhat)
						nhat.Parent = workspace
						nhat.Quacker.Disabled = false
						nhat.CFrame = v.CFrame*CFrame.new(math.random(-100,100),math.random(-100,100),math.random(-100,100))*CFrame.Angles(math.random(-360,360),math.random(-360,360),math.random(-360,360))
					end
					hats = tempHats
				end)
				for i,v in pairs(tempHats) do
					pcall(function() v:Destroy() end)
					table.remove(tempHats,i)
				end
				for i,v in pairs(hats) do
					pcall(function() v:Destroy() end)
					table.remove(hats,i)
				end
			end;
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

		FullClear = {
			Prefix = Settings.Prefix;
			Commands = {"fullclear";"clearinstances";"fullclr";};
			Args = {};
			Description = "Removes any instance created server-side by Adonis; May break things";
			AdminLevel = "Owners";
			Function = function(plr,args)
				local objects = service.GetAdonisObjects()

				for i,v in next,objects do
					v:Destroy()
					table.remove(objects, i)
				end

				--for i,v in next,Functions.GetPlayers() do
				--	Remote.Send(v, "Function", "ClearAllInstances")
				--end
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
				for i,v in next,service.GetPlayers(plr,args[1]) do
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
						name.Text = v.Name
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
						local event;event = v.CharacterRemoving:connect(function() Remote.RemoveLocal(plr,v.Name..'Tracker') event:Disconnect() end)
						local event2;event2 = plr.CharacterRemoving:connect(function() Remote.RemoveLocal(plr,v.Name..'Tracker') event2:Disconnect() end)
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
				if args[1]:lower() == Settings.SpecialPrefix.."all" then
					Remote.RemoveLocal(plr,'Tracker',false,true)
				else
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						Remote.RemoveLocal(plr,v.Name..'Tracker')
					end
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
					Admin.RunCommand(Settings.Prefix.."char",v.Name,"1237666")
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

		Pets = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pets";};
			Args = {"follow/float/swarm/attack";"player";};
			Hidden = false;
			Description = "Makes your hat pets do the specified command (follow/float/swarm/attack)";
			Fun = true;
			AdminLevel = "Players";
			Function = function(plr,args)
				local hats = plr.Character:FindFirstChild('ADONIS_HAT_PETS')
				if hats then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						if v.Character:FindFirstChild('HumanoidRootPart') and v.Character.HumanoidRootPart:IsA('Part') then
							if args[1]:lower()=='follow' then
								hats.Mode.Value='Follow'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='float' then
								hats.Mode.Value='Float'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='swarm' then
								hats.Mode.Value='Swarm'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='attack' then
								hats.Mode.Value='Attack'
								hats.Target.Value=v.Character.HumanoidRootPart
							end
						end
					end
				else
					Functions.Hint("You don't have any hat pets! If you are an admin use the :hatpets command to get some",{plr})
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
					--Send.Remote(v,"Function","setEffectVal","AntiDeleteTool",false)
					if v:findFirstChild("Backpack") then
						f3x:Clone().Parent = v.Backpack
					end
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
			Prefix = Settings.Prefix;
			Commands = {"removetools";"notools";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove the target player(s)'s tools";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v:findFirstChild("Backpack") then
						for a, tool in pairs(v.Character:children()) do if tool:IsA("Tool") or tool:IsA("HopperBin") then tool:Destroy() end end
						for a, tool in pairs(v.Backpack:children()) do if tool:IsA("Tool") or tool:IsA("HopperBin") then tool:Destroy() end end
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

		NewTeam = {
			Prefix = Settings.Prefix;
			Commands = {"newteam","createteam","maketeam"};
			Args = {"name";"BrickColor";};
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

		ForcePlace = {
			Prefix = Settings.Prefix;
			Commands = {"forceplace";};
			Args = {"player";"placeid/serverName";};
			Hidden = false;
			Description = "Force the target player(s) to teleport to the desired place";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				local id = tonumber(args[2])
				local players = service.GetPlayers(plr,args[1])
				local servers = Core.GetData("PrivateServers") or {}
				local code = servers[args[2]]
				if code then
					for i,v in pairs(players) do
						service.TeleportService:TeleportToPrivateServer(code.ID,code.Code,{v})
					end
				elseif id then
					for i,v in pairs(players) do
						service.TeleportService:Teleport(args[2], v)
					end
				else
					error("Invalid place ID/server name")
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

		--[[PlayerPoints = {
			Prefix = Settings.Prefix;
			Commands = {"ppoints";"playerpoints";"getpoints";};
			Args = {};
			Hidden = false;
			Description = "Shows you the number of player points left in the game";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				Functions.Hint('Available Player Points: '..service.PointsService:GetAwardablePoints(),{plr})
			end
		};]]

		GivePlayerPoints = {
			Prefix = Settings.Prefix;
			Commands = {"giveppoints";"giveplayerpoints";"sendplayerpoints";};
			Args = {"player";"amount";};
			Hidden = false;
			Description = "Lets you give <player> <amount> player points";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local ran,failed = pcall(function() service.PointsService:AwardPoints(v.userId,tonumber(args[2])) end)
					if ran and service.PointsService:GetAwardablePoints()>=tonumber(args[2]) then
						Functions.Hint('Gave '..args[2]..' points to '..v.Name,{plr})
					elseif service.PointsService:GetAwardablePoints()<tonumber(args[2]) then
						Functions.Hint("You don't have "..args[2]..' points to give to '..v.Name,{plr})
					else
						Functions.Hint("(Unknown Error) Failed to give "..args[2]..' points to '..v.Name,{plr})
					end
					Functions.Hint('Available Player Points: '..service.PointsService:GetAwardablePoints(),{plr})
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
					local human = v.Character:FindFirstChildOfClass("Humanoid")
					if human then
						human.PlatformStand = true
					end
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
						local ret = Remote.MakeGuiGet(v,"Notification",{
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
					local human = v.Character:FindFirstChildOfClass("Humanoid")
					if human then
						human.PlatformStand = false
					end
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

		Flatten = {
			Prefix = Settings.Prefix;
			Commands = {"flatten";"2d";"flat";};
			Args = {"player";"optional num";};
			Hidden = false;
			Description = "Flatten.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tonumber(args[2]) or 0.1

				local function sizePlayer(p)
					local char = p.Character
					local human = char:FindFirstChildOfClass("Humanoid")

					if human and human.RigType == Enum.HumanoidRigType.R15 then
						if human:FindFirstChild("BodyDepthScale") then 
							human.BodyDepthScale.Value = 0.1
						end
					elseif human and human.RigType == Enum.HumanoidRigType.R6 then
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
					end
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					sizePlayer(v)
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
				local sizeLimit = Settings.SizeLimit or 20
				local num = math.clamp(tonumber(args[2]) or 1, 0.001, sizeLimit) -- Size limit exceeding over 20 would be unnecessary and may potientially create massive lag !!

				if not args[2] or not tonumber(args[2]) then
					num = 1
					Functions.Hint("Size changed to 1 [Argument #2 wasn't supplied correctly.]", {plr})
				elseif tonumber(args[2]) and tonumber(args[2]) > sizeLimit then
					Functions.Hint("Size changed to the maximum "..tostring(num).." [Argument #2 went over the size limit]", {plr})
				end
				
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local char = v.Character;
					local human = char and char:FindFirstChildOfClass("Humanoid");

					if not human then
						Functions.Hint("Cannot resize "..v.Name.."'s character. Humanoid doesn't exist!",{plr})
						continue
					end
					
					if not Variables.SizedCharacters[char] then
						Variables.SizedCharacters[char] = num
					elseif Variables.SizedCharacters[char] and Variables.SizedCharacters[char]*num < sizeLimit then
						Variables.SizedCharacters[char] = Variables.SizedCharacters[char]*num
					else
						Functions.Hint("Cannot resize "..v.Name.."'s character by "..tostring(num*100).."%. Size limit exceeded.",{plr})
						continue
					end
					
					if human and human.RigType == Enum.HumanoidRigType.R15 then
						for k,val in next,human:GetChildren() do
							if val:IsA("NumberValue") and val.Name:match(".*Scale") then
								val.Value = val.Value * num;
							end
						end
					elseif human and human.RigType == Enum.HumanoidRigType.R6 then
						local Motors = {}
						local Percent = num

						table.insert(Motors, char.HumanoidRootPart.RootJoint)
						for i,Motor in pairs(char.Torso:GetChildren()) do
							if Motor:IsA("Motor6D") == false then continue end
							table.insert(Motors, Motor)
						end
						for i,v in pairs(Motors) do
							v.C0 = CFrame.new((v.C0.Position * Percent)) * (v.C0 - v.C0.Position)
							v.C1 = CFrame.new((v.C1.Position * Percent)) * (v.C1 - v.C1.Position)
						end


						for i,Part in pairs(char:GetChildren()) do
							if Part:IsA("BasePart") == false then continue end
							Part.Size = Part.Size * Percent
						end


						for i,Accessory in pairs(char:GetChildren()) do
							if Accessory:IsA("Accessory") == false then continue end

							Accessory.Handle.AccessoryWeld.C0 = CFrame.new((Accessory.Handle.AccessoryWeld.C0.Position * Percent)) * (Accessory.Handle.AccessoryWeld.C0 - Accessory.Handle.AccessoryWeld.C0.Position)
							Accessory.Handle.AccessoryWeld.C1 = CFrame.new((Accessory.Handle.AccessoryWeld.C1.Position * Percent)) * (Accessory.Handle.AccessoryWeld.C1 - Accessory.Handle.AccessoryWeld.C1.Position)

							if Accessory.Handle:FindFirstChildOfClass("SpecialMesh") then
								Accessory.Handle:FindFirstChildOfClass("SpecialMesh").Scale *= Percent
							end
						end
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
			Commands = {"package", "givepackage", "setpackage"};
			Args = {"player", "id"};
			Hidden = false;
			Description = "Gives the target player(s) the desired package";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2] and tonumber(args[2]), "Argument missing or invalid ID")

				local details = game.AssetService:GetBundleDetailsAsync(tonumber(args[2]))
				local parts = {}
				local validIds = {27,28,29,30,31,17,18,8,41,42,43,44,45,46,47,57,58}

				for i,v in next,details.Items do
					if table.find(validIds, service.MarketPlace:GetProductInfo(v.Id).AssetTypeId) then
						table.insert(parts,service.Insert(v.Id, true))
					end
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						Routine(function()
							for _,part in pairs(parts) do
								if part:FindFirstChild("R6") or part:FindFirstChild("R15") or part:FindFirstChild("R15Fixed") then
									Functions.ApplyBodyPart(v.Character, part)
								else
									for _,x in pairs(part:GetChildren()) do
										if x:IsA("Accoutrement") then 
											x:Clone().Parent = v.Character
										elseif x:IsA("Decal") or x:IsA("DataModelMesh") then 
											local CheckClass = x:IsA("Decal") and "Decal" or "DataModelMesh"

											if v.Character:FindFirstChild("Head") then 
												for _,z in pairs(v.Character.Head:GetChildren()) do
													if z:IsA(CheckClass) then 
														z:Destroy()
													end 
												end 
												x:Clone().Parent = v.Character.Head
											end
										end
									end
								end
							end 
						end)
					end
				end

				for i,v in pairs(parts) do 
					v:Destroy()
				end
			end
		};

		Char = {
			Prefix = Settings.Prefix;
			Commands = {"char";"character";"appearance";};
			Args = {"player";"ID or player";};
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
							if p:IsA("Part") then
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
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
							if p:IsA("Shirt") or p:IsA("Pants") or p:IsA("ShirtGraphic") or p:IsA("CharacterMesh") or p:IsA("Accoutrement") then
								p:Destroy()
							elseif p:IsA("Part") then
								p.Material = args[2]
								if args[3] then
									local str = BrickColor.new('Institutional white').Color
									local teststr = args[3]
									if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
									p.BrickColor = str
								end
								if p.Name=="Head" then
									local mesh=p:FindFirstChild("Mesh")
									if mesh then mesh:Destroy() end
								end
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
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
							if p:IsA("Shirt") or p:IsA("Pants") or p:IsA("ShirtGraphic") or p:IsA("CharacterMesh") or p:IsA("Accoutrement") then
								p:Destroy()
							elseif p:IsA("Part") then
								if args[2] then
									local str = BrickColor.new('Institutional white').Color
									local teststr = args[2]
									if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
									p.BrickColor = str
								end
								p.Material = "Neon"
								if p.Name=="Head" then
									local mesh=p:FindFirstChild("Mesh")
									if mesh then mesh:Destroy() end
								end
							end
						end
					end
				end
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

		iloveyou = {
			Prefix = "?";
			Commands = {"iloveyou";"alwaysnear";"alwayswatching";};
			Args = {};
			Fun = true;
			Hidden = true;
			Description = "I love you. You are mine. Do not fear; I will always be near.";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Effect",{Mode = "lifeoftheparty"})
			end
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

		Settings = {
			Prefix = ":";
			Commands = {"settings";"scriptsettings";"eisssettings";};
			Args = {};
			Hidden = false;
			Description = "Opens the settings manager";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Settings"})
			end
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

		BackupMap = {
			Prefix = Settings.Prefix;
			Commands = {"backupmap";"mapbackup";"bmap";};
			Args = {};
			Hidden = false;
			Description = "Changes the backup for the restore map command to the map's current state";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if plr then
					Functions.Hint('Updating Map Backup...',{plr})
				end
				
				if server.Variables.BackingupMap then
					error("Backup Map is in progress. Please try again later!")
					return
				end
				if server.Variables.RestoringMap then
					error("Cannot backup map while map is being restored!")
					return
				end
				
				server.Variables.BackingupMap = true
				
				local tempmodel = service.New('Model')

				for i,v in pairs(service.Workspace:GetChildren()) do
					if v and not v:IsA('Terrain') then
						wait()
						pcall(function()
							local archive = v.Archivable
							v.Archivable = true
							v:Clone(true).Parent = tempmodel
							v.Archivable = archive
						end)
					end
				end

				Variables.MapBackup = tempmodel:Clone()
				tempmodel:Destroy()
				Variables.TerrainMapBackup = service.Workspace.Terrain:CopyRegion(service.Workspace.Terrain.MaxExtents)

				if plr then
					Functions.Hint('Backup Complete',{plr})
				end
				
				server.Variables.BackingupMap = false
				
				Logs.AddLog(Logs.Script,{
					Text = "Backup Complete";
					Desc = "Map was successfully backed up";
				})
			end
		};

		Explore = {
			Prefix = Settings.Prefix;
			Commands = {"explore";"explorer";};
			Args = {};
			Hidden = false;
			Description = "Lets you explore the game, kinda like a file browser";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Explorer")
			end
		};

		DexExplore = {
			Prefix = Settings.Prefix;
			Commands = {"dex";"dexexplorer";"dexexplorer"};
			Args = {};
			Description = "Lets you explore the game using Dex [Credit to Raspberry Pi/Raspy_Pi/raspymgx/OpenOffset(?)][Useless buttons disabled]";
			AdminLevel = "Owners";
			Function = function(plr,args)
				Remote.MakeLocal(plr,Deps.Assets.Dex_Explorer:Clone(),"PlayerGui")
			end
		};

		Tornado = {
			Prefix = Settings.Prefix;
			Commands = {"tornado";"twister";};
			Args = {"player";"optional time";};
			Description = "Makes a tornado on the target player(s)";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local p=service.New('Part',service.Workspace)
					table.insert(Variables.Objects,p)
					p.Transparency=1
					p.CFrame=v.Character.HumanoidRootPart.CFrame+Vector3.new(0,-3,0)
					p.Size=Vector3.new(0.2,0.2,0.2)
					p.Anchored=true
					p.CanCollide=false
					p.Archivable=false
					--local tornado=deps.Tornado:clone()
					--tornado.Parent=p
					--tornado.Disabled=false
					local cl=Core.NewScript('Script',[[
						local Pcall=function(func,...) local function cour(...) coroutine.resume(coroutine.create(func),...) end local ran,error=pcall(cour,...) if error then print('Error: '..error) end end
						local parts = {}
						local main=script.Parent
						main.Anchored=true
						main.CanCollide=false
						main.Transparency=1
						local smoke=Instance.new("Smoke",main)
						local sound=Instance.new("Sound",main)
						smoke.RiseVelocity=25
						smoke.Size=25
						smoke.Color=Color3.new(170/255,85/255,0)
						smoke.Opacity=1
						sound.SoundId="rbxassetid://142840797"
						sound.Looped=true
						sound:Play()
						sound.Volume=1
						sound.Pitch=0.8
						local light=Instance

						function fling(part)
							part:BreakJoints()
							part.Anchored=false
							local pos=Instance.new("BodyPosition",part)
							pos.maxForce = Vector3.new(math.huge,math.huge,math.huge)--10000, 10000, 10000)
							pos.position = part.Position
							local i=1
							local run=true
							while main and wait() and run do
								if part.Position.Y>=main.Position.Y+50 then
									run=false
								end
								pos.position=Vector3.new(50*math.cos(i),part.Position.Y+5,50*math.sin(i))+main.Position
								i=i+1
							end
							pos.maxForce = Vector3.new(500, 500, 500)
							pos.position=Vector3.new(main.Position.X+math.random(-100,100),main.Position.Y+100,main.Position.Z+math.random(-100,100))
							pos:Destroy()
						end

						function get(obj)
							if obj ~= main and obj:IsA("Part") then
								table.insert(parts, 1, obj)
							elseif obj:IsA("Model") or obj:IsA("Accoutrement") or obj:IsA("Tool") or obj == workspace then
								for i,v in pairs(obj:children()) do
									Pcall(get,v)
								end
								obj.ChildAdded:connect(function(p)Pcall(get,p)end)
							end
						end

						get(workspace)

						repeat
							for i,v in pairs(parts) do
								if (((main.Position - v.Position).magnitude * 250 * 20) < (5000 * 40)) and v and v:IsDescendantOf(workspace) then
									coroutine.wrap(fling,v)
								elseif not v or not v:IsDescendantOf(workspace) then
									table.remove(parts,i)
								end
							end
							main.CFrame = main.CFrame + Vector3.new(math.random(-3,3), 0, math.random(-3,3))
							wait()
					until main.Parent~=workspace or not main]])
					cl.Parent=p
					cl.Disabled=false
					if args[2] and tonumber(args[2]) then
						for i=1,tonumber(args[2]) do
							if not p or not p.Parent then
								return
							end
							wait(1)
						end
						if p then p:Destroy() end
					end
				end
			end
		};

		Nuke = {
			Prefix = Settings.Prefix;
			Commands = {"nuke";};
			Args = {"player";};
			Description = "Nuke the target player(s)";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				local nukes = {}
				local partsHit = {}

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChild("HumanoidRootPart")
					if human then
						local p = service.New("Part", {
							Name = "ADONIS_NUKE";
							Anchored = true;
							CanCollide = false;
							formFactor = "Symmetric";
							Shape = "Ball";
							Size = Vector3.new(1,1,1);
							Position = human.Position;
							BrickColor = BrickColor.new("New Yeller");
							Transparency = .5;
							Reflectance = .2;
							TopSurface = 0;
							BottomSurface = 0;
							Parent = service.Workspace;
						})

						p.Touched:Connect(function(hit)
							if not partsHit[hit] then
								partsHit[hit] = true
								hit:BreakJoints()
								service.New("Explosion", {
									Position = hit.Position;
									BlastRadius = 10000;
									BlastPressure = math.huge;
									Parent = service.Workspace;
								})

							end
						end)

						table.insert(Variables.Objects, p)
						table.insert(nukes, p)
					end
				end

				for i = 1, 333 do
					for i,v in next,nukes do
						local curPos = v.CFrame
						v.Size = v.Size + Vector3.new(3, 3, 3)
						v.CFrame = curPos
					end
					wait(1/44)
				end

				for i,v in next,nukes do
					v:Destroy()
				end

				nukes = nil
				partsHit = nil
			end
		};

		UnWildFire = {
			Prefix = Settings.Prefix;
			Commands = {"stopwildfire", "removewildfire", "unwildfire";};
			Args = {};
			Description = "Stops :wildfire from spreading further";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				Variables.WildFire = nil
			end
		};

		WildFire = {
			Prefix = Settings.Prefix;
			Commands = {"wildfire";};
			Args = {"player";};
			Description = "Starts a fire at the target player(s); Ignores locked parts and parts named 'BasePlate' or 'Baseplate'";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				local finished = false
				local partsHit = {}
				local objs = {}

				Variables.WildFire = partsHit

				function fire(part)
					if finished or not partsHit or not objs then
						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and Variables.WildFire ~= partsHit then
						for i,v in next,objs do
							v:Destroy()
						end

						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and part:IsA("BasePart") and (not part.Locked or (part.Parent:IsA("Model") and service.Players:GetPlayerFromCharacter(part.Parent))) and part.Name ~= "BasePlate" and part.Name ~= "Baseplate" and not partsHit[part] then
						partsHit[part] = true

						local oColor = part.Color
						local fSize = (part.Size.X + part.Size.Y + part.Size.Z)
						local f = service.New("Fire", {
							Name = "WILD_FIRE";
							Size = fSize;
							Parent = part;
						})

						local l = service.New("PointLight", {
							Name = "WILD_FIRE";
							Range = fSize;
							Color = f.Color;
							Parent = part;
						})

						table.insert(objs, f)
						table.insert(objs, l)

						part.Touched:connect(fire)

						for i = 0.1, 1, 0.1 do
							part.Color = oColor:lerp(Color3.new(0, 0, 0), i)
							wait(math.random(5))
						end

						local ex = service.New("Explosion", {
							Position = part.Position;
							BlastRadius = fSize*2;
							BlastPressure = 0;
						})

						ex.Hit:connect(fire)
						ex.Parent = service.Workspace;
						part.Anchored = false
						part:BreakJoints()
						f:Destroy()
						l:Destroy()
					end
				end

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChild("HumanoidRootPart")
					if human then
						fire(human)
					end
				end

				partsHit = nil
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
			Description = "Lets you run code on the server";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				assert(Settings.CodeExecution, "CodeExecution must be enabled for this command to work")
				local cl = Core.NewScript('Script',args[1])
				cl.Parent = service.ServerScriptService
				cl.Disabled = false
				Functions.Hint("Ran Script",{plr})
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

		--[[FunBox = { -- Never forget :(((
			Prefix = Settings.Prefix;
			Commands = {"funbox";"trollbox";"trololo";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends players to The Fun Box. Please don't use this on people with epilepsy.";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				local funid={
					241559484,
					266815338,
				}--168920853 RIP
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						service.TeleportService:Teleport(funid[math.random(1,#funid)],v)
					end
				end
			end
		};--]]

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

		Bots = {
			Prefix = Settings.Prefix;
			Commands = {"bot";"trainingbot"};
			Args = {"plr";"num";"walk";"attack","friendly","health","speed","damage"};
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

		--[[
		Bots = {
			Prefix = Settings.Prefix;
			Commands = {"bot";"tbot";"trainingbot";"bots";"robot";"robots";"dummy";"dummys";"testdummy";"testdummys";"dolls";"doll";};
			Args = {"plr";"num";"walk";"attk";"swarm";"speed";"dmg";"hp";"dist";};
			Hidden = false;
			Description = "Configurable AIs made for training";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local walk=false
				if args[3] then if args[3]:lower()=='true' or args[3]:lower()=='yes' then walk=true end end
				local attack=false
				if args[4] then if args[4]:lower()=='true' or args[4]:lower()=='yes' then attack=true end end
				local health=args[8] or 100
				local damage=args[7] or 10
				local walkspeed=args[6] or 20
				local dist=args[9] or 100
				local swarm=false
				if args[5] then if args[5]:lower()=='true' or args[5]:lower()=='yes' then swarm=true end end
				local function makedolls(player)
					local num=args[2] or 1
					local pos=player.Character.HumanoidRootPart.CFrame
					num=tonumber(num)
					if num>50 then num=50 end
					for i=1,num do
						player.Character.Archivable = true
						local cl = player.Character:Clone()
						player.Character.Archivable = false
						table.insert(Variables.Objects,cl)
						local anim = Deps.Assets.Animate:Clone()
						local brain = Deps.Assets.BotBrain:Clone()
						anim.Parent = cl
						brain.Parent = cl
						brain.Damage.Value = damage
						brain.Walk.Value = walk
						brain.Attack.Value = attack
						brain.Swarm.Value = swarm
						brain.Distance.Value = dist
						brain.Commander.Value = plr.Name
						cl.Parent = game.Workspace
						cl.Name = player.Name.." Bot"
						if cl:FindFirstChild('Animate') then cl.Animate:Destroy() end
						cl.Humanoid.MaxHealth = health
						wait()
						cl.Humanoid.Health = health
						cl.HumanoidRootPart.CFrame = pos*CFrame.Angles(0,math.rad(360/num*i),0)*CFrame.new(5+.2*num,0,0)
						cl:MakeJoints()
						cl.Humanoid.WalkSpeed = walkspeed
						cl.Archivable = false
						for k,f in pairs(cl:children()) do if f.ClassName == 'ForceField' then f:Destroy() end end
						anim.Disabled = false
						brain.Disabled = false
					end
				end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					makedolls(v)
				end
			end
		};
		--]]

		Quote = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"quote";"inspiration";"randomquote";};
			Args = {};
			Description = "Shows you a random quote";
			AdminLevel = "Players";
			Function = function(plr,args)
				local quotes = require(Deps.Assets.Quotes)
				Functions.Message('Random Quote',quotes[math.random(1,#quotes)],{plr})
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

		Headlian = {
			Prefix = Settings.Prefix;
			Commands = {"headlian","beautiful"};
			Args = {"player"};
			Description = "hot";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				--{Left,Right}--
				local faces = {
					477737479;
					477737542;
					477737607;
					477737705;
					477737766;
					477737856;
					477737394;
					477737230;
					477737111;
					477737019;
					476913612;
					476913523;
					476762259;
					476762307;
					476596314;
					476596271;
					476596231;
					476596193;
					476596141;
					476596110;
					476596484;
					475197261;
					475098996;
					475098974;
					475098946;
					475098926;
					475098906;
					475098892;
					475098877;
					475098826;
					475098809;
					475099023;
					475099039;
					475127779;
					475127982;
					466322174;
					466322170;
					466322165;
					466322160;
					466322149;
					466322155;
					466322109;
					466322115;
					466322127;
					466322139;
					466322137;
					466322143;
					466322107;
					466322100;
					466322094;
					464898017;
					464897989;
					464897899;
					464897871;
					464897826;
					464897791;
					464897735;
					464850359;
					464850241;
					464836234;
					464836592;
					464836707;
					464836958;
					459665424;
					459654933;
					459654870;
					459654346;
					459654157;
					455731264;
					436570797;
					455519408;
					455519497;
					455451293;
					455433153;
					455433334;
					451621075;
					441642820;
					441642684;
					441621737;
					441621370;
					437671929;
					437672060;
					436611230;
					436666773;
					436662014;
				}
				local arms = {
					{27493648,27493629}; -- Alien
					{86500054,86500036}; -- Man
					{86499716,86499698}; -- Woman
					{36781447,36781407}; -- Skeleton
					{32336182,32336117}; -- Superhero
					{137715036,137715073}; -- Polar bear
					{53980922,53980889}; -- Gentleman robot
					{132896993,132897065}; -- Witch
				}
				local legs = {
					{86499753,86499793}; -- Woman
					{132897097,132897160}; -- Witch
					{54116394,54116432}; -- Mr Robot
					{232519786,232519950}; -- Sir Kitty McPawnington
					{32357631,32357663}; -- Slinger
					{293226935,293227110}; -- Lillian
					{32336243,32336306}; -- Superhero
					{27493683,27493718}; -- Alien
					{28279894,28279938}; -- Cool kid
					{136801087,136801165}; -- Bludroid: Ev1LR0b0t
					{53980959,53980996}; -- Gentleman robot
					{139607673,139607718}; -- Korblox
					{143624963,143625109}; -- Team ROBLOX Parka
					{77517631,77517683}; -- Empyrean Armor
					{128157317,128157361}; -- Telamon's Business Casual
					{86500078,86500064}; -- Man
					{27112056,27112068}; -- Roblox 2.0
				}

				local function clear(char)
					for i,v in pairs(char:GetChildren()) do
						if v:IsA("CharacterMesh") or v:IsA("Accoutrement") or v:IsA("ShirtGraphic") or v:IsA("Pants") or v:IsA("Shirt") then
							v:Destroy()
						end
					end
				end

				local function apply(char)
					local color = BrickColor.new(Color3.new(math.random(),math.random(),math.random()))
					local face = faces[math.random(1,#faces)]
					local arms = arms[math.random(1,#arms)]
					local legs = legs[math.random(1,#legs)]
					local la,ra = arms[1],arms[2]
					local ll,rl = legs[1],legs[2]
					local head = char:FindFirstChild("Head")
					local bodyColors = char:FindFirstChild("Body Colors")
					if head then
						local old = head:FindFirstChild("Mesh")
						if old then old:Destroy() end
						local mesh = service.New("SpecialMesh",head)
						mesh.MeshType = "FileMesh"
						mesh.MeshId = "http://www.roblox.com/asset/?id=134079402"
						mesh.TextureId = "http://www.roblox.com/asset/?id=133940918"
					end
					if bodyColors then
						bodyColors.HeadColor = color
						bodyColors.LeftArmColor = color
						bodyColors.LeftLegColor = color
						bodyColors.RightArmColor = color
						bodyColors.RightLegColor = color
						bodyColors.TorsoColor = color
					end
					service.Insert(la).Parent = char
					service.Insert(ra).Parent = char
					service.Insert(ll).Parent = char
					service.Insert(rl).Parent = char
					service.Insert(face).Parent = char
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						clear(v.Character)
						apply(v.Character)
					end
				end
			end
		};


		--[[

		Perms = {
			Prefix = Settings.Prefix;
			Commands = {"perms";"permissions";"comperms";};
			Args = {"Settings.Prefixcmd";"all/donor/temp/admin/owner/creator";};
			Hidden = false;
			Description = "Change command permissions";
			Fun = false;
			AdminLevel = "Creator";
			Function = function(plr,args)
				local level=nil
				if args[2]:lower()=='all' or args[2]:lower()=='0' or args[2]:lower()=="players" then
					level="Players"
				elseif args[2]:lower()=='donor' or args[2]:lower()=='1' or args[2]:lower()=="donors" then
					level="Donors"
				elseif args[2]:lower()=='temp' or args[2]:lower()=='2' or args[2]:lower()=="mod" or args[2]:lower()=="mods" then
					level="Moderators"
				elseif args[2]:lower()=='admin' or args[2]:lower()=='3' or args[2]:lower()=="admins" then
					level="Admins"
				elseif args[2]:lower()=='owner' or args[2]:lower()=='4' or args[2]:lower()=="owners" then
					level="Owners"
				elseif args[2]:lower()=='creator' or args[2]:lower()=='5' then
					level="Creator"
				elseif args[2]:lower()=='funtemp' or args[2]:lower()=='-1' or args[2]:lower()=="Moderators" then
					level="Moderators"
				elseif args[2]:lower()=='funadmin' or args[2]:lower()=='-2' then
					level="FunAdmin"
				elseif args[2]:lower()=='funowner' or args[2]:lower()=='-3' then
					level="FunOwner"
				end
				if level~=nil then
					for i=1,#Commands do
						if args[1]:lower()==Commands[i].Prefix..Commands[i].Cmds[1]:lower() then
							Commands[i].AdminLevel=level
							Functions.Hint("server "..Commands[i].Prefix..Commands[i].Cmds[1].." permission level to "..level,{plr})
						end
					end
				else
					OutputGui(plr,'Command Error:','Invalid Permission')
				end
			end
		};

		sh = {
			Prefix = Settings.Prefix;
			Commands = {"sh";"systemhint";};
			Args = {"message";};
			Hidden = false;
			Description = "Same as hint but says SYSTEM MESSAGE instead of your name, or whatever system message title is server to...";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				Functions.Hint(args[1],service.Players:children())
			end
		};

		flock = {
			Prefix = Settings.Prefix;
			Commands = {"flock";"flocklock";};
			Args = {"on/off";};
			Hidden = false;
			Description = "Makes it so only the place owner's friends can join";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if args[1]:lower()=='on' then
					flock=true
					Functions.Hint("Server is now friends only", service.Players:children())
				elseif args[1]:lower()=='off' then
					flock = false
					Functions.Hint("Server is no longer friends only", service.Players:children())
				end
			end
		};

		glock = {
			Prefix = Settings.Prefix;
			Commands = {"glock";"grouplock";"grouponlyjoin";};
			Args = {"on/off";};
			Hidden = false;
			Description = "Locks the server, makes it so only people in the group that is server in the group settings can join";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if args[1]:lower()=='on' then
					server['GroupOnlyJoin'] = true
					Functions.Hint("Server is now Group Only.", service.Players:children())
				elseif args[1]:lower()=='off' then
					server['GroupOnlyJoin'] = false
					Functions.Hint("Server is no longer Group Only", service.Players:children())
				end
			end
		};

		points = {
			Prefix = Settings.Prefix;
			Commands = {"points";"viewpoints";};
			Args = {"player";};
			Hidden = false;
			Description = "Tells you how many points the player has. Not PlayerPoints.";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = DataStore:GetAsync(tostring(v.userId))
					local points=PlayerData.AdminPoints
					if not points then
						Functions.Hint(v.Name..' has 0 points.',{plr})
					else
						Functions.Hint(v.Name..' has '..points..' points.',{plr})
					end
				end
			end
		};

		givepoints = {
			Prefix = Settings.Prefix;
			Commands = {"givepoints";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Gives the player <number> points. Not PlayerPoints.";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not tonumber(args[2]) then Functions.Hint(args[2]..' is not a valid number.',{plr}) return end
				local num=tonumber(args[2])
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = DataStore:GetAsync(tostring(v.userId))
					if not PlayerData.AdminPoints then
						PlayerData.AdminPoints=num
					else
						PlayerData.AdminPoints=PlayerData.AdminPoints+num
					end
					DataStore:SetAsync(tostring(v.userId),PlayerData)
					Functions.Hint('Gave '..v.Name..' '..num..' points.',{plr})
				end
			end
		};

		takepoints = {
			Prefix = Settings.Prefix;
			Commands = {"takepoints";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Takes away <number> points from the player. Not PlayerPoints.";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not tonumber(args[2]) then Functions.Hint(args[2]..' is not a valid number.',{plr}) return end
				local num=tonumber(args[2])
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = DataStore:GetAsync(tostring(v.userId))
					if not PlayerData.AdminPoints then
						PlayerData.AdminPoints=-num
					else
						PlayerData.AdminPoints=PlayerData.AdminPoints-num
					end
					DataStore:SetAsync(tostring(v.userId),PlayerData)
					Functions.Hint('Took '..num..' points from '..v.Name..'.',{plr})
				end
			end
		};

		notalk = {
			Prefix = Settings.Prefix;
			Commands = {"notalk";};
			Args = {"player";};
			Hidden = false;
			Description = "Tells the target player(s) they are not allowed to talk if they do and eventually kicks them";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
			for i,v in pairs(service.GetPlayers(plr,args[1])) do
			cPcall(function()
			if not v:FindFirstChild('NoTalk') and not Admin.CheckAdmin(v,false) then
				local talky=service.New('IntValue',v)
				talky.Name='NoTalk'
				talky.Value=0
			end
			end)
			end
			end
		};

		unnotalk = {
			Prefix = Settings.Prefix;
			Commands = {"unnotalk";};
			Args = {"player";};
			Hidden = false;
			Description = "Un-NoTalk";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						if v and v:FindFirstChild('NoTalk') then
							v.NoTalk:Destroy()
						end
					end)
				end
			end
		};

		normal = {
			Prefix = Settings.Prefix;
			Commands = {"normal";"normalify";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) look normal";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
			for i,v in pairs(service.GetPlayers(plr,args[1])) do
			cPcall(function()
			if v and v.Character and v.Character:findFirstChild("HumanoidRootPart") then
			if v.Character:findFirstChild("Head") then v.Character.Head.Mesh.Scale = Vector3.new(1.25,1.25,1.25) end
			if v.Character.HumanoidRootPart:findFirstChild("Shirt") then v.Character.HumanoidRootPart.Shirt.Parent = v.Character end
			if v.Character.HumanoidRootPart:findFirstChild("Pants") then v.Character.HumanoidRootPart.Pants.Parent = v.Character end
			v.Character.HumanoidRootPart.Transparency = 0
			v.Character.HumanoidRootPart.Neck.C0 = CFrame.new(0,1,0) * CFrame.Angles(math.rad(90),math.rad(180),0)
			v.Character.HumanoidRootPart["Right Shoulder"].C0 = CFrame.new(1,.5,0) * CFrame.Angles(0,math.rad(90),0)
			v.Character.HumanoidRootPart["Left Shoulder"].C0 = CFrame.new(-1,.5,0) * CFrame.Angles(0,math.rad(-90),0)
			v.Character.HumanoidRootPart["Right Hip"].C0 = CFrame.new(1,-1,0) * CFrame.Angles(0,math.rad(90),0)
			v.Character.HumanoidRootPart["Left Hip"].C0 = CFrame.new(-1,-1,0) * CFrame.Angles(0,math.rad(-90),0)
			local parent=v:FindFirstChild('PlayerGui') or v:FindFirstChild('Backpack')
			for a, sc in pairs(parent:children()) do if sc.Name == CodeName.."ify" or sc.Name==CodeName..'Glitch' or sc.Name == CodeName.."EpixPoison" then sc:Destroy() end end
			for a, prt in pairs(v.Character:children()) do
			if prt:IsA("BasePart") and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
			prt.Transparency = 0 prt.Reflectance = 0 prt.BrickColor = BrickColor.new("White")
			if prt.Name == "FAKETORSO" then prt:Destroy() end
			if prt.Name == 'HumanoidRootPart' then prt.Transparency=1 end
			elseif prt:findFirstChild("NameTag") then
				prt.Head.Transparency = 0 prt.Head.Reflectance = 0 prt.Head.BrickColor = BrickColor.new("White")
			elseif prt.Name=='Epix Puke' or prt.Name=='Epix Bleed' then
				prt:Destroy()
			elseif prt.Name==v.Name..'epixcrusify' then
				Admin.RunCommand(Settings.Prefix..'refresh',v.Name)
			end
			end
			end
			end)
			end
			end
		};

		ko = {
			Prefix = Settings.Prefix;
			Commands = {"ko";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Kills the target player(s) <number> times giving you <number> KOs";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
			local num = 500 if num > tonumber(args[2]) then num = tonumber(args[2]) end
			for i, v in pairs(service.GetPlayers(plr,args[1])) do
			if CheckTrueOwner(plr) or not Admin.CheckAdmin(v, false) then
			local cl=LoadScript("Script",[=[
			v=service.Players:FindFirstChild(']=]..v.Name..[=[')
			for n = 1, ]=]..num..[=[]=] do
			wait()
			pcall(function()
			if v and v.Character and v.Character:findFirstChild("Humanoid") then
			local val = service.New("ObjectValue", v.Character.Humanoid) val.Value = service.Players:FindFirstChild("]=]..plr.Name..[=[") val.Name = "creator"
			v.Character:BreakJoints()
			wait()
			v:LoadCharacter()
			end
			end)
			end]=],AssignName(),true,service.ServerScriptService)
			cl.Name=AssignName()
			cl.Parent=service.ServerScriptService
			cl.Disabled=false
			end
			end
			end
		};

		Flashify = {
			Prefix = Settings.Prefix;
			Commands = {"flashify";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character flash";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local parent = v:FindFirstChild('PlayerGui') or v:FindFirstChild('Backpack')
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
					if v.Character:findFirstChild("Shirt") then v.Character.Shirt.Parent = v.Character.HumanoidRootPart end
					if v.Character:findFirstChild("Pants") then v.Character.Pants.Parent = v.Character.HumanoidRootPart end
					for a, sc in pairs(v.Character:children()) do if sc.Name == "ify" then sc:Destroy() end end
						Remote.Send(v,'Function','Effect','flashify')
					end
				end
			end
		};

		uncreeper = {
			Prefix = Settings.Prefix;
			Commands = {"uncreeper";"uncreeperify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) back to normal";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						if v and v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						if v.Character.HumanoidRootPart:findFirstChild("Shirt") then v.Character.HumanoidRootPart.Shirt.Parent = v.Character end
						if v.Character.HumanoidRootPart:findFirstChild("Pants") then v.Character.HumanoidRootPart.Pants.Parent = v.Character end
						v.Character.HumanoidRootPart.Transparency = 0
						v.Character.HumanoidRootPart.Neck.C0 = CFrame.new(0,1,0) * CFrame.Angles(math.rad(90),math.rad(180),0)
						v.Character.HumanoidRootPart["Right Shoulder"].C0 = CFrame.new(1,.5,0) * CFrame.Angles(0,math.rad(90),0)
						v.Character.HumanoidRootPart["Left Shoulder"].C0 = CFrame.new(-1,.5,0) * CFrame.Angles(0,math.rad(-90),0)
						v.Character.HumanoidRootPart["Right Hip"].C0 = CFrame.new(1,-1,0) * CFrame.Angles(0,math.rad(90),0)
						v.Character.HumanoidRootPart["Left Hip"].C0 = CFrame.new(-1,-1,0) * CFrame.Angles(0,math.rad(-90),0)
						for a, part in pairs(v.Character:children()) do if part:IsA("BasePart") then part.BrickColor = BrickColor.new("White") if part.Name == "FAKETORSO" then part:Destroy() end elseif part:findFirstChild("NameTag") then part.Head.BrickColor = BrickColor.new("White") end end
						end
					end)
				end
			end
		};

		undog = {
			Prefix = Settings.Prefix;
			Commands = {"undog";"undogify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn them back to normal";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						if v and v.Character and v.Character:findFirstChild("HumanoidRootPart") then
							if v.Character.HumanoidRootPart:findFirstChild("Shirt") then v.Character.HumanoidRootPart.Shirt.Parent = v.Character end
							if v.Character.HumanoidRootPart:findFirstChild("Pants") then v.Character.HumanoidRootPart.Pants.Parent = v.Character end
							v.Character.HumanoidRootPart.Transparency = 0
							v.Character.HumanoidRootPart.Neck.C0 = CFrame.new(0,1,0) * CFrame.Angles(math.rad(90),math.rad(180),0)
							v.Character.HumanoidRootPart["Right Shoulder"].C0 = CFrame.new(1,.5,0) * CFrame.Angles(0,math.rad(90),0)
							v.Character.HumanoidRootPart["Left Shoulder"].C0 = CFrame.new(-1,.5,0) * CFrame.Angles(0,math.rad(-90),0)
							v.Character.HumanoidRootPart["Right Hip"].C0 = CFrame.new(1,-1,0) * CFrame.Angles(0,math.rad(90),0)
							v.Character.HumanoidRootPart["Left Hip"].C0 = CFrame.new(-1,-1,0) * CFrame.Angles(0,math.rad(-90),0)
							for a, part in pairs(v.Character:children()) do if part:IsA("BasePart") then part.BrickColor = BrickColor.new("White") if part.Name == "FAKETORSO" then part:Destroy() end elseif part:findFirstChild("NameTag") then part.Head.BrickColor = BrickColor.new("White") end end
						end
					end)
				end
			end
		};


		motd = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"motd";"messageoftheday";"daymessage";};
			Args = {};
			Hidden = false;
			Description = "Shows you the current message of the day";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				PM('Message of the Day',plr,service.MarketPlace:GetProductInfo(Functions.MessageOfTheDayID).Description)
			end
		};

		version = {
			Prefix = Settings.Prefix;
			Commands = {"version";"ver";};
			Args = {};
			Hidden = false;
			Description = "Shows you the admin script's version number";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				Functions.Message("Epix Inc. Server Suite", tostring(version), true, {plr})
			end
		};

		ranks = {
			Prefix = Settings.Prefix;
			Commands = {"ranks";"adminranks";};
			Args = {};
			Hidden = false;
			Description = "Shows you group ranks that have admin";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temptable={}
				for i,v in pairs(Ranks) do
					table.insert(temptable,{Text=v.Group..":"..v.Rank.." - "..v.Type,Desc='Rank: '..v.Rank..' - Type: '..v.Type..' - Group: '..v.Group})
				end
				Remote.Send(plr,'Function','ListGui','Ranks',temptable)
			end
		};

		votekick = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"votekick";"kick";};
			Args = {"player";};
			Hidden = false;
			Description = "Vote to kick a player";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				if VoteKick then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						if Admin.CheckAdmin(v,false) then return end
						if not VoteKickVotes[v.Name] then
							VoteKickVotes[v.Name]={}
							VoteKickVotes[v.Name].Votes=0
							VoteKickVotes[v.Name].Players={}
						end
						for k,m in pairs(VoteKickVotes[v.Name].Players) do if m==plr.userId then return end end
						VoteKickVotes[v.Name].Votes=VoteKickVotes[v.Name].Votes+1
						table.insert(VoteKickVotes[v.Name].Players,plr.userId)
						if VoteKickVotes[v.Name].Votes>=((#service.Players:children()*VoteKickPercentage)/100) then
							v:Kick("Players voted to kick you from the game. You have been disconnected by the ")
							VoteKickVotes[v.Name]=nil
						end
					end
				else
					Functions.Message("SYSTEM","VoteKick is disabled.",false,{plr})
				end
			end
		};

		votekicks = {
			Prefix = Settings.Prefix;
			Commands = {"votekicks";};
			Args = {};
			Hidden = false;
			Description = "Shows how many kick votes each player in-game has.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temp={}
				for i,v in pairs(VoteKickVotes) do
					if not service.Players:FindFirstChild(i) then VoteKickVotes[i]=nil return end
					if Admin.CheckAdmin(service.Players:FindFirstChild(i),false) then VoteKickVotes[i]=nil return end
					table.insert(temp,{Text=i..' - '..VoteKickVotes[v.Name].Votes,Desc='Player: '..i..' has '..VoteKickVotes[v.Name].Votes..' kick vote(s)'})
				end
				Remote.Send(plr,'Function','ListGui','Vote Kicks',temp)
			end
		};
	--]]
	};
end
