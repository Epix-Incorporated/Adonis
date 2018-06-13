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
return function() 
	server.Commands = {
		Sudo = {
			Prefix = server.Settings.Prefix;
			Commands = {"sudo"};
			Arguments = {"player", "command"};
			Description = "Runs a command as the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr, args)
				assert(args[1] and args[2], "Argument missing or nil");
				for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
					server.Process.Command(v, args[2], {isSystem = true});
				end
			end;
		};
		
		ClearPlayerData = {
			Prefix = server.Settings.Prefix;
			Commands = {"clearplayerdata"};
			Arguments = {"userId"};
			Description = "Clears player data for target";
			AdminLevel = "Creators";
			Function = function(plr, args)
				local id = tonumber(args[1]) or plr.UserId
				server.Remote.PlayerData[id] = server.Core.DefaultData()
				server.Remote.MakeGui(plr,"Notification",{
					Title = "Notification";
					Message = "Cleared data";
					Time = 10;
				})
			end;
		};
		
		TestError = {
			Hidden = true;
			Prefix = ":";
			Commands = {"testerror","debugtest"};
			Args = {"type","msg"};
			Description = "Test Error";
			AdminLevel = "Creators";
			Function = function(plr,args)
				--assert(args[1] and args[2],"Argument missing or nil")
				server.Remote.Send(plr, "TestError")
				Routine(function() plr.Bobobobobobobo.Hi = 1 end)
				if not args[1] then
					error("This is an intentional test error")
				elseif args[1]:lower() == "error" then
					error(args[2])
				elseif args[1]:lower() == "assert" then
					assert(false,args[2])
				end
			end;
		};
		
		TestGet = {
			Prefix = ":";
			Commands = {"testget"};
			Args = {};
			Description = "Test Error";
			Hidden = true;
			AdminLevel = "Creators";
			Function = function(plr,args)
				local tack = tick()
				print(tack)
				print(server.Remote.Get(plr,"Test"))
				local tab = {
					{
						Children = {
							{Class = "sdfhasdfjkasjdf"}
						};
						{{Something = "hi"}};
					}
				}
				
				local m, ret = server.Remote.Get(plr, "Test", tab)
				if ret then
					print(ret)
					for i,v in next, ret do
						print(i,v)
						for i,v in next,v do
							print(i,v)
							for i,v in next,v do
								print(i,v)
								for i,v in next,v do
									print(i,v)
								end
							end
						end
					end
				end
				
				print(tick()-tack)
				print("TESTING EVENT")
				server.Remote.MakeGui(plr,"Settings",{
					IsOwner = true
				})
				local testColor = server.Remote.GetGui(plr,"ColorPicker",{Color = Color3.new(1,1,1)})
				print(testColor)
				local ans,event = server.Remote.GetGui(plr,"YesNoPrompt",{
					Question = "Is this a test question?";
				}), server.Remote.NewPlayerEvent(plr,"TestEvent",function(...)
					print("EVENT WAS FIRED; WE GOT:")
					print(...)
					print("THAT'D BE ALL")
				end)
				print("PLAYER ANSWER: "..tostring(ans))
				wait(0.5)
				print("SENDING REMOTE EVENT TEST")
				server.Remote.Send(plr,"TestEvent","TestEvent","hi mom I went thru the interwebs")
				print("SENT")
			end;
		};
		
		DebugLoadstring = {
			Prefix = ":";
			Commands = {"debugloadstring";};
			Args = {"code";};
			Description = "DEBUG LOADSTRING";
			Hidden = true;
			NoFilter = true;
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				error("Disabled", 0)
				local func,err = server.Core.Loadstring(args[1],GetEnv())
				if func then 
					func()
				else
					logError("DEBUG",err)
					server.Functions.Hint(err,{plr})
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
				server.Remote.MakeGui(plr,"Terminal")
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
					for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
						local temp = {}
						local cTasks = server.Remote.Get(v, "TaskManager", "GetTasks") or {}
						
						table.insert(temp,{
							Text = "Client Tasks",
							Desc = "Tasks their client is performing"})
						
						for k,t in next,cTasks do 
							table.insert(temp, {
								Text = tostring(v.Function).. "- Status: "..v.Status.." - Elapsed: ".. v.CurrentTime - v.Created, 
								Desc = v.Name;
							})
						end
						
						server.Remote.MakeGui(plr,"List",{
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
					local cTasks = server.Remote.Get(plr,"TaskManager","GetTasks") or {}
					
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
					
					server.Remote.MakeGui(plr,"List",{
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
			Prefix = server.Settings.Prefix;
			Commands = {"taskmgr","taskmanager"};
			Args = {};
			Description = "Task manager";
			Hidden = true;
			AdminLevel = "Creators";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"TaskManager",{})
			end
		};
		--]]
		CommandBox = {
			Prefix = server.Settings.Prefix;
			Commands = {"cmdbox", "commandbox"};
			Args = {};
			Description = "Command Box";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				server.Remote.MakeGui(plr, "Window", {
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
							TextChanged = server.Core.Bytecode[[
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
							OnClick = server.Core.Bytecode[[
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
			Prefix = server.Settings.Prefix;
			Commands = {"cmds","commands","cmdlist"};
			Args = {};
			Description = "Shows you a list of commands";
			AdminLevel = "Players";
			Function = function(plr,args)
				local commands = server.Admin.SearchCommands(plr,"all")
				local tab = {}
				
				for i,v in next,commands do
					table.insert(tab, {
						Text = server.Admin.FormatCommand(v),
						Desc = "["..v.AdminLevel.."] "..v.Description,
						Filter = v.AdminLevel
					})
				end
				
				server.Remote.MakeGui(plr,"List",
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
				server.Functions.Hint('"'..server.Settings.Prefix..'cmds"',{plr})
			end
		};
		
		Repeat = {
			Prefix = server.Settings.Prefix;
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
				server.Variables.CommandLoops[name..command] = true
				server.Functions.Hint("Running "..command.." "..amount.." times every "..timer.." seconds.",{plr})
				for i = 1,amount do
					if not server.Variables.CommandLoops[name..command] then break end
					server.Process.Command(plr,command,{Check = false;})
					wait(timer)
				end
				server.Variables.CommandLoops[name..command] = nil
			end
		};
		
		Abort = {
			Prefix = server.Settings.Prefix;
			Commands = {"abort";"stoploop";"unloop";"unrepeat";};
			Args = {"username";"command";};
			Description = "Aborts a looped command. Must supply name of player who started the loop or \"me\" if it was you, or \"all\" for all loops. :abort sceleratis :kill bob or :abort all";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local name = args[1]:lower()
				if name=="me" then
					server.Variables.CommandLoops[plr.Name:lower()..args[2]] = nil
				elseif name=="all" then
					for i,v in pairs(server.CommandLoops) do
						server.Variables.CommandLoops[i] = nil
					end
				elseif args[2] then
					server.Variables.CommandLoops[name..args[2]] = nil
				end
			end
		};
		
		TempModerator = {
			Prefix = server.Settings.Prefix;
			Commands = {"admin","tempadmin","ta","temp","helper";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) a temporary moderator; Does not save";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local sendLevel = server.Admin.GetLevel(plr)	
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = server.Admin.GetLevel(v)
					if sendLevel>targLevel then
						server.Admin.AddAdmin(v,1,true)
						server.Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = server.Core.Bytecode("client.Remote.Send('ProcessCommand','"..server.Settings.Prefix.."cmds')");
						})
						server.Functions.Hint(v.Name..' is now a temp moderator',{plr})
					else
						server.Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};
				
		Moderator = {
			Prefix = server.Settings.Prefix;
			Commands = {"mod";"moderator"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) a moderator; Saves";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local sendLevel = server.Admin.GetLevel(plr)	
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = server.Admin.GetLevel(v)
					if sendLevel>targLevel then
						server.Admin.AddAdmin(v,1)
						server.Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = server.Core.Bytecode("client.Remote.Send('ProcessCommand','"..server.Settings.Prefix.."cmds')");
						})
						server.Functions.Hint(v.Name..' is now a moderator',{plr})
					else
						server.Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};
		
		Admin = {
			Prefix = server.Settings.Prefix;
			Commands = {"permadmin","pa","padmin","fulladmin","realadmin"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) an admin; Saves";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				local sendLevel = server.Admin.GetLevel(plr)	
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = server.Admin.GetLevel(v)
					if sendLevel>targLevel then
						server.Admin.AddAdmin(v,2)
						server.Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = server.Core.Bytecode("client.Remote.Send('ProcessCommand','"..server.Settings.Prefix.."cmds')");
						})
						server.Functions.Hint(v.Name..' is now an admin',{plr})
					else
						server.Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};
		
		Owner = {
			Prefix = server.Settings.Prefix;
			Commands = {"owner","oa","headadmin"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) an owner; Saves";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				local sendLevel = server.Admin.GetLevel(plr)	
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = server.Admin.GetLevel(v)
					if sendLevel>targLevel then
						server.Admin.AddAdmin(v,3)
						server.Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = server.Core.Bytecode("client.Remote.Send('ProcessCommand','"..server.Settings.Prefix.."cmds')");
						})
						server.Functions.Hint(v.Name..' is now an owner',{plr})
					else
						server.Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};
		
		UnAdmin = {
			Prefix = server.Settings.Prefix;
			Commands = {"unadmin";"unmod","unowner","unhelper","unpadmin","unpa";"unoa";"unta";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target players' admin powers; Saves";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				
				local sendLevel = server.Admin.GetLevel(plr)
				local plrs = service.GetPlayers(plr, args[1], true)
				if plrs and #plrs>0 then
					for i,v in next,plrs do
						local targLevel = server.Admin.GetLevel(v)
						if targLevel>0 then
							if sendLevel>targLevel then
								server.Admin.RemoveAdmin(v,false,true)
								server.Functions.Hint("Removed "..v.Name.."'s admin powers",{plr})
							else
								server.Functions.Hint("You do not have permission to remove "..v.Name.."'s admin powers",{plr})
							end
						else
							server.Functions.Hint(v.Name..' is not an admin',{plr})
						end
					end
				else
					local targLevel = server.Admin.GetUpdatedLevel(args[1])
					if targLevel then
						if sendLevel > targLevel then
							local ans = server.Remote.GetGui(plr,"YesNoPrompt",{
								Question = "Unadmin all saved admins matching '"..tostring(args[1]).."'?";
							})
							if ans == "Yes" then
								server.Admin.RemoveAdmin(args[1])
								server.Functions.Hint("Removed "..args[1].."'s admin powers",{plr})
							end
						else
							server.Functions.Hint("You do not have permission to remove "..args[1].."'s admin powers",{plr})
						end
					else
						server.Functions.Hint("No level returned for "..args[1])
					end
				end
			end
		};
		
		TempUnAdmin = {
			Prefix = server.Settings.Prefix;
			Commands = {"tempunadmin","untempadmin","tunadmin","untadmin"};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target players' admin powers for this server; Does not save";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				
				local sendLevel = server.Admin.GetLevel(plr)
				local plrs = service.GetPlayers(plr, args[1], true)
				if plrs and #plrs>0 then
					for i,v in pairs(plrs) do
						local targLevel = server.Admin.GetLevel(v)
						if targLevel>0 then
							if sendLevel>targLevel then
								server.Admin.RemoveAdmin(v,true)
								server.Functions.Hint("Removed "..v.Name.."'s admin powers",{plr})
							else
								server.Functions.Hint("You do not have permission to remove "..v.Name.."'s admin powers",{plr})
							end
						else
							server.Functions.Hint(v.Name..' is not an admin',{plr})
						end
					end
				end
			end
		};
		
		CustomRank = {
			Prefix = server.Settings.Prefix;
			Commands = {"customrank","ca","crank"};
			Args = {"player";"rankName"};
			Hidden = false;
			Description = "Adds the player to a custom rank set in settings.CustomRanks; Does not save";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				
				local rank = args[2]
				local customRank = server.Settings.CustomRanks[rank]
				
				assert(customRank,"Rank not found!")
				
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Functions.Hint("Added "..v.Name.." to "..rank,{plr})
					table.insert(customRank,v.Name..":"..v.userId)
				end
			end
		};
		
		UnCustomRank = {
			Prefix = server.Settings.Prefix;
			Commands = {"uncustomrank","unca","uncrank"};
			Args = {"player";"rankName"};
			Hidden = false;
			Description = "Removes the player from a custom rank set in settings.CustomRanks; Does not save";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				
				local rank = args[2]
				local customRank = server.Settings.CustomRanks[rank]
				
				assert(customRank,"Rank not found!")
				
				service.Iterate(customRank,function(i,v) 
					if v:lower():sub(1,#args[1]) == args[1]:lower() then
						table.remove(customRank,i)
						server.Functions.Hint("Removed "..v.Name.." from "..rank,{plr})
					end
				end)
			end
		};
		
		CustomRanks = {
			Prefix = server.Settings.Prefix;
			Commands = {"customranks","cranks"};
			Args = {};
			Hidden = false;
			Description = "Shows custom ranks";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				local tab = {}
				service.Iterate(server.Settings.CustomRanks,function(rank,tab)
					table.insert(tab,{Text = rank, Desc = rank})
				end)
				server.Remote.MakeGui(plr,"List",{Title = "Custom Ranks";Table = tab})
			end
		};
		
		Kick = {
			Prefix = server.Settings.Prefix;
			Commands = {"kick";};
			Args = {"player";"optional reason";};
			Filter = true;
			Description = "Disconnects the target player from the server";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local plrLevel = server.Admin.GetLevel(plr)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					local targLevel = server.Admin.GetLevel(v)
					if plrLevel>targLevel then 
						if not service.Players:FindFirstChild(v.Name) then
							server.Remote.Send(v,'Function','Kill')
						else
							v:Kick(args[2])
						end
						server.Functions.Hint("Kicked "..tostring(v),{plr})
					end
				end
			end
		};
		--[[
		DataBan = {
			Prefix = server.Settings.Prefix;
			Commands = {"databan";"permban";"gameban"};
			Args = {"player";};
			Hidden = false;
			Description = "Data persistent ban the target player(s); Undone using :undataban";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if not server.Admin.CheckAdmin(v) then
						local ans = server.Remote.GetGui(plr,"YesNoPrompt",{
							Question = "Are you sure you want to ban "..v.Name
						})
						
						if ans == "Yes" then
							local PlayerData = server.Core.GetPlayer(v)
							PlayerData.Banned = true
							v:Kick("You have been banned")
							server.Functions.Hint("Data Banned "..tostring(v),{plr})
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
			Prefix = server.Settings.Prefix;
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
				local PlayerData = server.Core.GetData(tostring(userId))
				assert(PlayerData,"No saved data found for "..userId)
				PlayerData.TimeBan = false
				PlayerData.Banned = false
				server.Core.SaveData(tostring(userId),PlayerData)
				server.Functions.Hint("Removed data ban for "..userId,{plr})
			end
		};
		--]]
		TimeBan = {
			Prefix = server.Settings.Prefix;
			Commands = {"tban";"timedban";"timeban";};
			Args = {"player";"number<s/m/h/d>";};
			Hidden = false;
			Description = "Bans the target player(s) for the supplied amount of time; Data Persistent; Undone using :undataban";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				local time = args[2] or '60'
				assert(args[1] and args[2], "Argument missing or nil")
				if time:lower():sub(#time)=='s' then
					time = time:sub(1,#time-1)
				elseif time:lower():sub(#time)=='m' then
					time = time:sub(1,#time-1)
					time = tonumber(time)*60
				elseif time:lower():sub(#time)=='h' then
					time = time:sub(1,#time-1)
					time = (tonumber(time)*60)*60
				elseif time:lower():sub(#time)=='d' then
					time = time:sub(1,#time-1)
					time = ((tonumber(time:sub(1,#time-1))*60)*60)*24
				end
				
				for i,v in next,service.GetPlayers(plr, args[1], false, false, true) do
					local endTime = tonumber(os.time())+tonumber(time)
					local timebans = server.Core.Variables.TimeBans
					local data = {
						Name = v.Name;
						UserId = v.UserId;
						EndTime = endTime;
					}
					
					table.insert(timebans, data)
					server.Core.DoSave({
						Type = "TableAdd";
						Table = "TimeBans";
						Parent = "Variables";
						Value = data;
					})
					
					v:Kick("Banned until "..endTime)
					server.Functions.Hint("Banned "..v.Name.." for "..time,{plr})
				end
			end
		};
		
		UnTimeBan = {
			Prefix = server.Settings.Prefix;
			Commands = {"untimeban";};
			Args = {"player";};
			Hidden = false;
			Description = "UnBan";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1], "Argument missing or nil")
				local timebans = server.Core.Variables.TimeBans or {}
				for i, data in next, timebans do
					if data.Name:lower():sub(1,#args[1]) == args[1]:lower() then
						table.remove(timebans, i)
						server.Core.DoSave({
							Type = "TableRemove";
							Table = "TimeBans";
							Parent = "Variables";
							Value = data;
						})
						server.Functions.Hint(tostring(data.Name)..' has been Unbanned',{plr})
					end
				end
			end
		};
		
		TimeBanList = {
			Prefix = server.Settings.Prefix;
			Commands = {"timebanlist";"timebanned";"timebans";};
			Args = {};
			Description = "Shows you the list of time banned users";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local tab = {}
				local variables = server.Core.Variables
				local timeBans = server.Core.Variables.TimeBans or {}
				for i,v in next,timeBans do
					local timeLeft = v.EndTime-os.time()
					local minutes = server.Functions.RoundToPlace(timeLeft/60, 2)
					if timeLeft <= 0 then
						table.remove(server.Core.Variables.TimeBans, i)
					else
						table.insert(tab,{Text = tostring(v.Name)..":"..tostring(v.UserId),Desc = "Minutes Left: "..tostring(minutes)})
					end
				end
				server.Remote.MakeGui(plr,"List",{Title = 'Time Bans', Tab = tab})
			end
		};
		
		Ban = {
			Prefix = server.Settings.Prefix;
			Commands = {"ban";};
			Args = {"player";};
			Description = "Bans the player from the server";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local level = server.Admin.GetLevel(plr)
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > server.Admin.GetLevel(v) then 
						server.Admin.AddBan(v)
						server.Functions.Hint("Server banned "..tostring(v),{plr})
					end
				end
			end
		};
		
		UnBan = {
			Prefix = server.Settings.Prefix;
			Commands = {"unban";};
			Args = {"player";};
			Description = "UnBan";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local ret = server.Admin.RemoveBan(args[1]) 
				if ret then
					server.Functions.Hint(tostring(ret)..' has been Unbanned',{plr})
				end
			end
		};
		
		GameBan = {
			Prefix = server.Settings.Prefix;
			Commands = {"gameban", "saveban", "databan"};
			Args = {"player";};
			Description = "Bans the player from the game (Saves)";
			AdminLevel = "Owners";
			Function = function(plr,args)
				local level = server.Admin.GetLevel(plr)
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > server.Admin.GetLevel(v) then 
						server.Admin.AddBan(v, true)
						server.Functions.Hint("Server banned "..tostring(v),{plr})
					end
				end
			end
		};
		
		UnGameBan = {
			Prefix = server.Settings.Prefix;
			Commands = {"ungameban", "saveunban", "undataban"};
			Args = {"player";};
			Description = "UnBans the player from game (Saves)";
			AdminLevel = "Owners";
			Function = function(plr,args)
				local ret = server.Admin.RemoveBan(args[1], true) 
				if ret then
					server.Functions.Hint(tostring(ret)..' has been Unbanned',{plr})
				end
			end
		};
		
		Dizzy = {
			Prefix = server.Settings.Prefix;
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
					server.Remote.Send(v,"Function","Dizzy",tonumber(speed))
				end
			end
		};
		
		UnDizzy = {
			Prefix = server.Settings.Prefix;
			Commands = {"undizzy";};
			Args = {"player"};
			Description = "UnDizzy";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.Send(v,"Function","Dizzy",false)
				end
			end
		};
		
		SetFPS = {
			Prefix = server.Settings.Prefix;
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
					server.Remote.Send(v,"Function","SetFPS",tonumber(args[2]))
				end
			end
		};
		
		RestoreFPS = {
			Prefix = server.Settings.Prefix;
			Commands = {"restorefps";"revertfps";"unsetfps";};
			Args = {"player";};
			Hidden = false;
			Description = "Restores the target players's FPS";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.Send(v,"Function","RestoreFPS")
				end
			end
		};
		
		Crash = {
			Prefix = server.Settings.Prefix;
			Commands = {"crash";};
			Args = {"player";};
			Hidden = false;
			Description = "Crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then
						server.Remote.Send(v,'Function','Crash')
					end
				end
			end
		};
		
		HardCrash = {
			Prefix = server.Settings.Prefix;
			Commands = {"hardcrash";};
			Args = {"player";};
			Hidden = false;
			Description = "Hard crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then
						server.Remote.Send(v,'Function','HardCrash')
					end
				end
			end
		};
		
		RAMCrash = {
			Prefix = server.Settings.Prefix;
			Commands = {"ramcrash";"memcrash"};
			Args = {"player";};
			Hidden = false;
			Description = "Crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then
						server.Remote.Send(v,'Function','RAMCrash')
					end
				end
			end
		};
		
		GPUCrash = {
			Prefix = server.Settings.Prefix;
			Commands = {"gpucrash";};
			Args = {"player";};
			Hidden = false;
			Description = "Crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then
						server.Remote.Send(v,'Function','GPUCrash')
					end
				end
			end
		};
		
		Shutdown = {
			Prefix = server.Settings.Prefix;
			Commands = {"shutdown"};
			Args = {"reason"};
			Description = "Shuts the server down";
			PanicMode = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not server.Core.PanicMode then
					local logs = server.Core.GetData("ShutdownLogs") or {}
					if plr then
						table.insert(logs,1,{User=plr.Name,Time=service.GetTime(),Reason=args[2] or "N/A"})
					else
						table.insert(logs,1,{User="Server/Trello",Time=service.GetTime(),Reason=args[2] or "N/A"})
					end
					if #logs>1000 then
						table.remove(logs,#logs)
					end
					server.Core.SaveData("ShutdownLogs",logs)
				end
				server.Functions.Shutdown(args[2])
			end
		};
		
		--[[FullShutdown = {
			Prefix = server.Settings.Prefix;
			Commands = {"fullshutdown"};
			Args = {"reason"};
			Description = "Initiates a shutdown for every running game server";
			PanicMode = true;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not server.Core.PanicMode then
					local logs = server.Core.GetData("ShutdownLogs") or {}
					if plr then
						table.insert(logs,1,{User=plr.Name,Time=service.GetTime(),Reason=args[2] or "N/A"})
					else
						table.insert(logs,1,{User="Server/Trello",Time=service.GetTime(),Reason=args[2] or "N/A"})
					end
					if #logs>1000 then
						table.remove(logs,#logs)
					end
					server.Core.SaveData("ShutdownLogs",logs)
				end
				
				server.Core.SaveData("FullShutdown", {ID = game.PlaceId; User = tostring(plr or "Server"); Reason = args[2]})
			end
		};--]]
		
		ShutdownLogs = {
			Prefix = server.Settings.Prefix;
			Commands = {"shutdownlogs";"shutdownlog";"slogs";"shutdowns";};
			Args = {};
			Hidden = false;
			Description = "Shows who shutdown a server and when";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local logs = server.Core.GetData("ShutdownLogs") or {}
				local tab={}
				for i,v in pairs(logs) do
					table.insert(tab,1,{Text=v.Time..": "..v.User,Desc="Reason: "..v.Reason})
				end
				server.Remote.MakeGui(plr,"List",{Title = "Shutdown Logs",Table = tab,Update = "shutdownlogs"})
			end
		};
		
		ServerLock = {
			Prefix = server.Settings.Prefix;
			Commands = {"slock","serverlock"};
			Args = {"on/off"};
			Hidden = false;
			Description = "Enables/disables server lock";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not args[1] or (args[1] and (args[1]:lower() == "on" or args[1]:lower() == "true")) then
					server.Variables.ServerLock = true
					server.Functions.Hint("Server Locked",{plr})
				elseif args[1]:lower() == "off" or args[1]:lower() == "false" then
					server.Variables.ServerLock = false
					server.Functions.Hint("Server Unlocked",{plr})
				end
			end
		};
		
		Whitelist = {
			Prefix = server.Settings.Prefix;
			Commands = {"wl","enablewhitelist","whitelist"};
			Args = {"on/off or add/remove","optional player"};
			Hidden = false;
			Description = "Enables/disables the whitelist; :wl username to add them to the whitelist";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if args[1]:lower()=='on' or args[1]:lower()=='enable' then
					server.Variables.Whitelist.Enabled = true
					server.Functions.Hint("Server Whitelisted", service.Players:GetChildren()) 
				elseif args[1]:lower()=='off' or args[1]:lower()=='disable' then
					server.Variables.Whitelist.Enabled = false
					server.Functions.Hint("Server Unwhitelisted", service.Players:GetChildren()) 
				elseif args[1]:lower()=="add" then
					if args[2] then
						local plrs = service.GetPlayers(plr,args[2],true)
						if #plrs>0 then
							for i,v in pairs(plrs) do
								table.insert(server.Variables.Whitelist.List,v.Name..":"..v.userId)
								server.Functions.Hint("Whitelisted "..v.Name,{plr})
							end
						else
							table.insert(server.Variables.Whitelist.List,args[2])
						end
					else
						error('Missing name to whitelist')
					end
				elseif args[1]:lower()=="remove" then
					if args[2] then
						for i,v in pairs(server.Variables.Whitelist.List) do
							if v:lower():sub(1,#args[2]) == args[2]:lower() then
								table.remove(server.Variables.Whitelist.List,i)
								server.Functions.Hint("Removed "..tostring(v).." from the whitelist",{plr})
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
			Prefix = server.Settings.Prefix;
			Commands = {"setmessage";"notif";"setmsg";};
			Args = {"message OR off";};
			Filter = true;
			Description = "Set message";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				
				if args[1] == "off" or args[1] == "false" then	
					server.Variables.NotifMessage = nil
					for i,v in pairs(service.GetPlayers()) do
						server.Remote.RemoveGui(v,"Notif")
					end
				else
					server.Variables.NotifMessage = args[1] --service.LaxFilter(args[1],plr) --// Command processor handles arg filtering
					for i,v in pairs(service.GetPlayers()) do
						server.Remote.MakeGui(v,"Notif",{
							Message = server.Variables.NotifMessage;
						})
					end
				end
			end
		};
		
		SetBanMessage = {
			Prefix = server.Settings.Prefix;
			Commands = {"setbanmessage";"setbmsg"};
			Args = {"message";};
			Filter = true;
			Description = "Sets the ban message banned players see";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				server.Variables.BanMessage = args[1]
			end
		};
		
		SetLockMessage = {
			Prefix = server.Settings.Prefix;
			Commands = {"setlockmessage";"setlmsg"};
			Args = {"message";};
			Filter = true;
			Description = "Sets the lock message unwhitelisted players see if :whitelist or :slock is on";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				server.Variables.LockMessage = args[1]
			end
		};
		
		Notepad = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"notepad","stickynote"};
			Args = {};
			Description = "Opens a textbox window for you to type into";
			AdminLevel = "Players";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"Window",{
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
			Prefix = server.Settings.Prefix;
			Commands = {"notify","notification"};
			Args = {"player","message"};
			Description = "Sends the player a notification";
			Filter = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.MakeGui(v,"Notification",{
						Title = "Notification";
						Message = service.Filter(args[2],plr,v);
					})
				end
			end
		};
		
		Countdown = {
			Prefix = server.Settings.Prefix;
			Commands = {"countdown", "timer"};
			Args = {"time";};
			Description = "Countdown";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tonumber(args[1]) --math.min(tonumber(args[1]),120)
				if not args[1] then error("Argument 1 missing") end
				for i,v in next,service.GetPlayers() do
					server.Remote.MakeGui(v, "Countdown", {
						Time = num;
					})
				end
				--for i = num, 1, -1 do
					--server.Functions.Message("Countdown", tostring(i), service.Players:children(), false, 1.1)
					--server.Functions.Message(" ", i, false, service.Players:children(), 0.8) 
					--wait(1)
				--end
			end
		};
		
		HintCountdown = {
			Prefix = server.Settings.Prefix;
			Commands = {"hcountdown";"hc";};
			Args = {"time";};
			Description = "Hint Countdown";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = math.min(tonumber(args[1]),120)
				for i = num, 1, -1 do
					server.Functions.Hint(i, service.Players:children(),2.5) 
					wait(1)
				end
			end
		};
		
		TimeMessage = {
			Prefix = server.Settings.Prefix;
			Commands = {"tm";"timem";"timedmessage";};
			Args = {"time";"message";};
			Filter = true;
			Description = "Make a message and makes it stay for the amount of time (in seconds) you supply";
			AdminLevel = "Moderators";
			Function = function(plr,args) 
				assert(args[1] and args[2] and tonumber(args[1]),"Argument missing or invalid")
				for i,v in pairs(service.Players:GetChildren()) do
					server.Remote.RemoveGui(v,"Message")
					server.Remote.MakeGui(v,"Message",{
						Title = "Message from " .. plr.Name;
						Message = args[2];
						Time = tonumber(args[1]);
					})
				end
			end
		};
		
		Message = {
			Prefix = server.Settings.Prefix;
			Commands = {"m";"message";};
			Args = {"message";};
			Filter = true;
			Description = "Makes a message";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in next,service.Players:GetChildren() do
					server.Remote.RemoveGui(v,"Message")
					server.Remote.MakeGui(v,"Message",{
						Title = "Message from " .. plr.Name;
						Message = args[1];--service.Filter(args[1],plr,v);
						Scroll = true;
						Time = (#tostring(args[1])/19)+2.5; 
					})
				end
			end
		};
		
		SystemMessage = {
			Prefix = server.Settings.Prefix;
			Commands = {"sm";"systemmessage";};
			Args = {"message";};
			Filter = true;
			Description = "Same as message but says SYSTEM MESSAGE instead of your name, or whatever system message title is server to...";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.Players:GetChildren()) do
					server.Remote.RemoveGui(v,"Message")
					server.Remote.MakeGui(v,"Message",{
						Title = server.Settings.SystemTitle;
						Message = args[1]; --service.Filter(args[1],plr,v);
					})
				end
			end
		};
		
		MessagePM = {
			Prefix = server.Settings.Prefix;
			Commands = {"mpm";"messagepm";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Makes a message on the target player(s) screen.";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Functions.Message("Message from "..plr.Name,service.Filter(args[2],plr,v),{v})
				end
			end
		};
		
		Notify = {
			Prefix = server.Settings.Prefix;
			Commands = {"n","smallmessage","nmessage","nmsg","smsg","smessage"};
			Args = {"message";};
			Filter = true;
			Description = "Makes a small message";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.Players:GetChildren()) do
					server.Remote.RemoveGui(v,"Notify")
					server.Remote.MakeGui(v,"Notify",{
						Title = "Message from " .. plr.Name;
						Message = service.Filter(args[1],plr,v);
					})
				end
			end
		};
		
		Hint = {
			Prefix = server.Settings.Prefix;
			Commands = {"h";"hint";};
			Args = {"message";};
			Filter = true;
			Description = "Makes a hint";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")
				for i,v in pairs(service.Players:GetChildren()) do
					server.Remote.MakeGui(v,"Hint",{
						Message = tostring(plr or "")..": "..service.Filter(args[1],plr,v);
					})
				end
			end
		};
		
		Warn = {
			Prefix = server.Settings.Prefix;
			Commands = {"warn","warning"};
			Args = {"player","message";};
			Filter = true;
			Description = "Warns players";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				local plrLevel = server.Admin.GetLevel(plr)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local targLevel = server.Admin.GetLevel(v)
					if plrLevel>targLevel then 
						local data = server.Core.GetPlayer(v)
						table.insert(data.Warnings, {From = tostring(plr), Message = args[2], Time = os.time()})
						server.Remote.RemoveGui(v,"Notify")
						server.Remote.MakeGui(v,"Notify",{
							Title = "Warning from "..tostring(plr);
							Message = args[2];
						})
						
						if plr and type(plr) == "userdata" then
							server.Remote.MakeGui(plr,"Hint",{
								Message = "Warned "..tostring(v);
							})
						end
					end
				end
			end
		};
		
		KickWarn = {
			Prefix = server.Settings.Prefix;
			Commands = {"kickwarn","kwarn","kickwarning"};
			Args = {"player","message";};
			Filter = true;
			Description = "Warns & kicks a player";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				local plrLevel = server.Admin.GetLevel(plr)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local targLevel = server.Admin.GetLevel(v)
					if plrLevel>targLevel then 
						local data = server.Core.GetPlayer(v)
						table.insert(data.Warnings, {From = tostring(plr), Message = args[2], Time = os.time()})
						v:Kick(tostring("[Warning from "..tostring(plr).."]\n"..args[2]))
						server.Remote.RemoveGui(v,"Notify")
						server.Remote.MakeGui(v,"Notify",{
							Title = "Warning from "..tostring(plr);
							Message = args[2];
						})
						
						if plr and type(plr) == "userdata" then
							server.Remote.MakeGui(plr,"Hint",{
								Message = "Warned "..tostring(v);
							})
						end
					end
				end
			end
		};
		
		ShowWarnings = {
			Prefix = server.Settings.Prefix;
			Commands = {"warnings","showwarnings"};
			Args = {"player"};
			Description = "Shows warnings a player has";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local data = server.Core.GetPlayer(v)
					local tab = {}
					
					if data.Warnings then
						for k,m in ipairs(data.Warnings) do 
							table.insert(tab,{Text = "["..k.."] "..m.Message,Desc = "Given by: "..m.From.."; "..m.Message})
						end
					end
					
					server.Remote.MakeGui(plr, "List", {
						Title = v.Name;
						Table = tab;
					})
				end
			end
		};
		
		ClearWarnings = {
			Prefix = server.Settings.Prefix;
			Commands = {"clearwarnings"};
			Args = {"player"};
			Description = "Clears any warnings on a player";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local data = server.Core.GetPlayer(v)
					data.Warnings = {}
					if plr and type(plr) == "userdata" then
						server.Remote.MakeGui(plr,"Hint",{
							Message = "Cleared warnings for "..tostring(v);
						})
					end
				end
			end
		};
		
		NumPlayers = {
			Prefix = server.Settings.Prefix;
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
					server.Functions.Hint("There are currently "..tostring(num).." players; "..tostring(nilNum).." are nil or loading",{plr})
				else
					server.Functions.Hint("There are "..tostring(num).." players",{plr})
				end
			end
		};
		
		ClientTab = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"client";"clientsettings","playersettings"};
			Args = {};
			Hidden = false;
			Description = "Opens the client settings panel";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"UserPanel",{Tab = "Client"})
			end
		};
			
		Donate = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"donate";"change";"changecape";"donorperks";};
			Args = {};
			Hidden = false;
			Description = "Opens the donation panel";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"UserPanel",{Tab = "Donate"})
			end
		};
		
		DonorUncape = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"uncape";"removedonorcape";};
			Args = {};
			Hidden = false;
			Description = "Remove donor cape";
			Fun = false;
			AllowDonors = true;
			AdminLevel = "Donors";
			Function = function(plr,args)
				server.Functions.UnCape(plr)
			end
		};
		
		DonorCape = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"cape";"donorcape";};
			Args = {};
			Hidden = false;
			Description = "Get donor cape";
			Fun = false;
			AllowDonors = true;
			AdminLevel = "Donors";
			Function = function(plr,args)
				server.Functions.Donor(plr)
			end
		};
		
		DonorShirt = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"shirt";"giveshirt";};
			Args = {"ID";};
			Hidden = false;
			Description = "Give you the shirt that belongs to <ID>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local image = server.Functions.GetTexture(args[1])
				if image then
					if plr.Character and image then
						for g,k in pairs(plr.Character:children()) do
							if k:IsA("Shirt") then k:Destroy() end
						end
						service.New('Shirt',plr.Character).ShirtTemplate="http://www.roblox.com/asset/?id="..image
					end
				else
					for g,k in pairs(plr.Character:children()) do
						if k:IsA("Shirt") then k:Destroy() end
					end
				end
			end
		};
		
		DonorPants = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"pants";"givepants";};
			Args = {"id";};
			Hidden = false;
			Description = "Give you the pants that belongs to <id>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local image = server.Functions.GetTexture(args[1])
				if image then
					if plr.Character and image then 
						for g,k in pairs(plr.Character:children()) do
							if k:IsA("Pants") then k:Destroy() end
						end
						service.New('Pants',plr.Character).PantsTemplate="http://www.roblox.com/asset/?id="..image
					end
				else
					for g,k in pairs(plr.Character:children()) do
						if k:IsA("Pants") then k:Destroy() end
					end
				end
			end
		};
		
		DonorFace = {
			Prefix = server.Settings.PlayerPrefix;
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
				if info.AssetTypeId == 18 or info.AssetTypeId == 9 then 
					service.Insert(args[1]).Parent = plr.Character:FindFirstChild("Head")
				else
					error("Invalid face ID")
				end
			end
		};
		
		DonorNeon = {
			Prefix = server.Settings.PlayerPrefix;
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
			Prefix = server.Settings.PlayerPrefix;
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
					
					server.Functions.RemoveParticle(torso,"DONOR_FIRE")
					server.Functions.NewParticle(torso,"Fire",{
						Name = "DONOR_FIRE";
						Color = color;
						SecondaryColor = secondary;
					})
					server.Functions.RemoveParticle(torso,"DONOR_FIRE_LIGHT")
					server.Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_FIRE_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};
		
		DonorSparkles = {
			Prefix = server.Settings.PlayerPrefix;
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
					
					server.Functions.RemoveParticle(torso,"DONOR_SPARKLES")
					server.Functions.RemoveParticle(torso,"DONOR_SPARKLES_LIGHT")
					server.Functions.NewParticle(torso,"Sparkles",{
						Name = "DONOR_SPARKLES";
						SparkleColor = color;
					})
					
					server.Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_SPARKLES_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};
		
		DonorLight = {
			Prefix = server.Settings.PlayerPrefix;
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
					
					server.Functions.RemoveParticle(torso,"DONOR_LIGHT")
					server.Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};
		
		DonorParticle = {
			Prefix = server.Settings.PlayerPrefix;
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
					
					server.Functions.RemoveParticle(torso,"DONOR_PARTICLE")
					server.Functions.NewParticle(torso,"ParticleEmitter",{
						Name = "DONOR_PARTICLE";
						Texture = 'rbxassetid://'..args[1]; --server.Functions.GetTexture(args[1]); 
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
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"unparticle";"removeparticles";};
			Args = {};
			Hidden = false;
			Description = "Removes donor particles on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				server.Functions.RemoveParticle(torso,"DONOR_PARTICLE")
			end
		};
		
		DonorUnfire = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"unfire";"undonorfire";};
			Args = {};
			Hidden = false;
			Description = "Removes donor fire on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				server.Functions.RemoveParticle(torso,"DONOR_FIRE")
				server.Functions.RemoveParticle(torso,"DONOR_FIRE_LIGHT")
			end
		};
		
		DonorUnsparkles = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"unsparkles";"undonorsparkles";};
			Args = {};
			Hidden = false;
			Description = "Removes donor sparkles on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				server.Functions.RemoveParticle(torso,"DONOR_SPARKLES")
				server.Functions.RemoveParticle(torso,"DONOR_SPARKLES_LIGHT")
			end
		};
		
		DonorUnlight = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"unlight";"undonorlight";};
			Args = {};
			Hidden = false;
			Description = "Removes donor light on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				server.Functions.RemoveParticle(torso,"DONOR_LIGHT")
			end
		};
		
		DonorHat = {
			Prefix = server.Settings.PlayerPrefix;
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
			Prefix = server.Settings.PlayerPrefix;
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
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"keybinds";"binds";"bind";"keybind";"clearbinds";"removebind";};
			Args = {};
			Hidden = false;
			Description = "Opens the keybind manager";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"UserPanel",{Tab = "KeyBinds"})
			end
		};
		
		MakeTalk = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"chatnotify";"chatmsg";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Makes a message in the target player(s)'s chat window";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					server.Remote.Send(v,"Function","ChatMessage",service.Filter(args[2],plr,v),Color3.new(1,64/255,77/255))
				end
			end
		};
		
		ForceField = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"punish";};
			Args = {"player";};
			Description = "Removes the target player(s)'s character";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						v.Character.Parent = server.Settings.Storage
					end
				end
			end
		};
		
		UnPunish = {
			Prefix = server.Settings.Prefix;
			Commands = {"unpunish";};
			Args = {"player";};
			Description = "UnPunishes the target player(s)";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					v.Character.Parent = service.Workspace v.Character:MakeJoints()
				end
			end
		};
		
		IceFreeze = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
							ypcall(function() plate:Destroy() end)
						end
					end)
				end
			end
		};
		
		Fire = {
			Prefix = server.Settings.Prefix;
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
						server.Functions.NewParticle(torso,"Fire",{
							Name = "FIRE";
							Color = color;
							SecondaryColor = secondary;
						})
						server.Functions.NewParticle(torso,"PointLight",{
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
			Prefix = server.Settings.Prefix;
			Commands = {"unfire";"removefire";"extinguish";};
			Args = {"player";};
			Description = "Puts out the flames on the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						server.Functions.RemoveParticle(torso,"FIRE")
						server.Functions.RemoveParticle(torso,"FIRE_LIGHT")
					end
				end
			end
		};
		
		Smoke = {
			Prefix = server.Settings.Prefix;
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
						server.Functions.NewParticle(torso,"Smoke",{
							Name = "SMOKE";
							Color = color;
						})
					end
				end
			end
		};
		
		UnSmoke = {
			Prefix = server.Settings.Prefix;
			Commands = {"unsmoke";};
			Args = {"player";};
			Description = "Removes smoke from the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						server.Functions.RemoveParticle(torso,"SMOKE")
					end
				end
			end
		};
		
		Sparkles = {
			Prefix = server.Settings.Prefix;
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
						server.Functions.NewParticle(torso,"Sparkles",{
							Name = "SPARKLES";
							SparkleColor = color;
						})
						server.Functions.NewParticle(torso,"PointLight",{
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
			Prefix = server.Settings.Prefix;
			Commands = {"unsparkles";};
			Args = {"player";};
			Description = "Removes sparkles from the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						server.Functions.RemoveParticle(torso,"SPARKLES")
						server.Functions.RemoveParticle(torso,"SPARKLES_LIGHT")
					end
				end
			end
		};
		
		Animation = {
			Prefix = server.Settings.Prefix;
			Commands = {"animation";"loadanim";"animate";};
			Args = {"player";"animationID";};
			Description = "Load the animation onto the target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1] and not args[2] then args[2] = args[1] args[1] = nil end
				
				assert(tonumber(args[2]),tostring(args[2]).." is not a valid ID")
				
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.Send(v,"Function","PlayAnimation",args[2])
				end
			end
		};
		
		AFK = {
			Prefix = server.Settings.Prefix;
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
						server.Admin.RunCommand(server.Settings.Prefix.."name",v.Name,"-AFK-_"..v.Name.."_-AFK-")
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
							server.Admin.RunCommand(server.Settings.Prefix.."unname",v.Name)
							event:Disconnect()
						end)
						repeat torso.CFrame = pos wait() until not v or not v.Character or not torso or not running or not torso.Parent
					end)
				end
			end
		};
		
		Heal = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
				server.Remote.Send(plr,"Function","PlayAudio",wot[math.random(1,#wot)])
			end
		};
		
		ScriptInfo = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"info";"about";"userpanel";};
			Args = {};
			Hidden = false;
			Description = "Shows info about the script";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"UserPanel",{Tab = "Info"})
			end
		};
		
		SetCoreGuiEnabled = {
			Prefix = server.Settings.Prefix;
			Commands = {"setcoreguienabled";"setcoreenabled";"showcoregui";"setcoregui";"setcge";"setcore"};
			Args = {"player";"element";"true/false";};
			Hidden = false;
			Description = "SetCoreGuiEnabled. Enables/Disables CoreGui elements. ";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if args[3]:lower()=='on' or args[3]:lower()=='true' then
						server.Remote.Send(v,'Function','SetCoreGuiEnabled',args[2],true)
					elseif args[3]:lower()=='off' or args[3]:lower()=='false' then
						server.Remote.Send(v,'Function','SetCoreGuiEnabled',args[2],false)
					end
				end
			end
		};
		
		PrivateMessage = {
			Prefix = server.Settings.Prefix;
			Commands = {"pm";"privatemessage";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Send a private message to a player";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing")
				if server.Admin.CheckAdmin(plr) then
					for i,p in pairs(service.GetPlayers(plr, args[1])) do
						server.Remote.MakeGui(p,"PrivateMessage",{
							Title = "Message from "..plr.Name;
							Player = plr;
							Message = service.Filter(args[2],plr,p);
						})
					end
				end
			end
		};
		
		ShowChat = {
			Prefix = server.Settings.Prefix;
			Commands = {"chat","customchat"};
			Args = {"player"};
			Description = "Opens the custom chat GUI";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.MakeGui(plr,"Chat",{KeepChat = true})
				end
			end
		};
		
		RemoveChat = {
			Prefix = server.Settings.Prefix;
			Commands = {"unchat","uncustomchat"};
			Args = {"player"};
			Description = "Opens the custom chat GUI";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.RemoveGui(plr,"Chat")
				end
			end
		};
		
		BlurEffect = {
			Prefix = server.Settings.Prefix;
			Commands = {"blur";"screenblur";"blureffect"};
			Args = {"player";"blur size";};
			Description = "Blur the target player's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local moder = tonumber(args[2]) or 0.5
				if moder>5 then moder=5 end
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.NewLocal(p,"BlurEffect",{
						Name = "WINDOW_BLUR", 
						Size = tonumber(args[2]) or 24, 
						Enabled = true,
					},"Camera")
				end
			end
		};
		
		BloomEffect = {
			Prefix = server.Settings.Prefix;
			Commands = {"bloom";"screenbloom";"bloomeffect"};
			Args = {"player";"intensity";"size";"threshold"};
			Description = "Give the player's screen the bloom lighting effect";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.NewLocal(p,"BloomEffect",{
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
			Prefix = server.Settings.Prefix;
			Commands = {"sunrays";"screensunrays";"sunrayseffect"};
			Args = {"player";"intensity";"spread"};
			Description = "Give the player's screen the sunrays lighting effect";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.NewLocal(p,"SunRaysEffect",{
						Name = "WINDOW_SUNRAYS",
						Intensity = tonumber(args[2]) or 0.25, 
						Spread = tonumber(args[3]) or 1, 
						Enabled = true,
					},"Camera")
				end
			end
		};
		
		ColorCorrectionEffect = {
			Prefix = server.Settings.Prefix;
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
					server.Remote.NewLocal(p,"ColorCorrectionEffect",{
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
			Prefix = server.Settings.Prefix;
			Commands = {"uncolorcorrection";"uncorrection";"uncolorcorrectioneffect"};
			Args = {"player";};
			Hidden = false;
			Description = "UnColorCorrection the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.RemoveLocal(p,"WINDOW_COLORCORRECTION","Camera")
				end
			end
		};
		
		UnSunRays = {
			Prefix = server.Settings.Prefix;
			Commands = {"unsunrays"};
			Args = {"player";};
			Hidden = false;
			Description = "UnSunrays the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.RemoveLocal(p,"WINDOW_SUNRAYS","Camera")
				end
			end
		};
		
		UnBloom = {
			Prefix = server.Settings.Prefix;
			Commands = {"unbloom";"unscreenbloom";};
			Args = {"player";};
			Hidden = false;
			Description = "UnBloom the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.RemoveLocal(p,"WINDOW_BLOOM","Camera")
				end
			end
		};
		
		UnBlur = {
			Prefix = server.Settings.Prefix;
			Commands = {"unblur";"unscreenblur";};
			Args = {"player";};
			Hidden = false;
			Description = "UnBlur the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.RemoveLocal(p,"WINDOW_BLUR","Camera")
				end
			end
		};
		
		UnLightingEffect = {
			Prefix = server.Settings.Prefix;
			Commands = {"unlightingeffect";"unscreeneffect";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove admin made lighting effects from the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.RemoveLocal(p,"WINDOW_BLUR","Camera")
					server.Remote.RemoveLocal(p,"WINDOW_BLOOM","Camera")
					server.Remote.RemoveLocal(p,"WINDOW_THERMAL","Camera")
					server.Remote.RemoveLocal(p,"WINDOW_SUNRAYS","Camera")
					server.Remote.RemoveLocal(p,"WINDOW_COLORCORRECTION","Camera")
				end
			end
		};
		
		ThermalVision = {
			Prefix = server.Settings.Prefix;
			Commands = {"thermal","thermalvision","heatvision"};
			Args = {"player"};
			Hidden = false;
			Description = "Looks like heat vision";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.NewLocal(p,"ColorCorrectionEffect",{
						Name = "WINDOW_THERMAL",
						Brightness = 1,
						Contrast = 20,
						Saturation = 20,
						TintColor = Color3.new(0.5,0.2,1);
						Enabled = true,
					},"Camera")
					server.Remote.NewLocal(p,"BlurEffect",{
						Name = "WINDOW_THERMAL", 
						Size = 24, 
						Enabled = true,
					},"Camera")
				end
			end
		};
		
		UnThermalVision = {
			Prefix = server.Settings.Prefix;
			Commands = {"unthermal";"unthermalvision";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the thermal effect from the target player's screen";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.RemoveLocal(p,"WINDOW_THERMAL","Camera")
				end
			end
		};
		
		ZaWarudo = {
			Prefix = server.Settings.Prefix;
			Commands = {"zawarudo","stoptime"};
			Args = {};
			Fun = true;
			Description = "Freezes everything but the player running the command";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local doPause; doPause = function(obj)
					if obj:IsA("BasePart") and not obj.Anchored and not obj:IsDescendantOf(plr.Character) then
						obj.Anchored = true
						table.insert(server.Variables.FrozenObjects, obj)
					end
					
					for i,v in next,obj:GetChildren() do
						doPause(v)
					end
				end
				
				if server.Variables.ZaWarudo then
					local audio = service.New("Sound",workspace)
					audio.SoundId = "rbxassetid://676242549"
					audio.Volume = 0.5
					audio:Play()
					wait(2)
					for i,part in next,server.Variables.FrozenObjects do
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
					
					server.Variables.ZaWarudo:Disconnect()
					server.Variables.FrozenObjects = {}
					server.Variables.ZaWarudo = false
					audio:Destroy()
				else
					local audio = service.New("Sound",workspace)
					audio.SoundId = "rbxassetid://274698941"
					audio.Volume = 10
					audio:Play()
					wait(2.25)
					doPause(workspace)
					server.Variables.ZaWarudo = game.DescendantAdded:connect(function(c)
						if c:IsA("BasePart") and not c.Anchored and c.Name ~= "HumanoidRootPart" then
							c.Anchored = true
							table.insert(server.Variables.FrozenObjects,c)
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
				server.Remote.MakeGui(plr,"List",{
					Title = "Syned Ban List";
					Tab = server.HTTP.Trello.Bans;
				})
			end
		};
		
		MakeList = {
			Prefix = server.Settings.Prefix;
			Commands = {"makelist";"newlist";"newtrellolist";"maketrellolist";};
			Args = {"name";};
			Hidden = false;
			Description = "Adds a list to the Trello board set in server.Settings. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not args[1] then error("Missing argument") end		
				local trello = server.HTTP.Trello.API(server.Settings.Trello_AppKey,server.Settings.Trello_Token)
				local list = trello.makeList(server.Settings.Trello_Primary,args[1])
				server.Functions.Hint("Made list "..list.name,{plr})
			end
		};
		
		ViewList = {
			Prefix = server.Settings.Prefix;
			Commands = {"viewlist";"viewtrellolist";};
			Args = {"name";};
			Hidden = false;
			Description = "Views the specified Trello list from the board set in server.Settings.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not args[1] then error("Missing argument") end		
				local trello = server.HTTP.Trello.API(server.Settings.Trello_AppKey,server.Settings.Trello_Token)
				local list = trello.getList(server.Settings.Trello_Primary,args[1])
				if not list then error("List not found.") end
				local cards = trello.getCards(list.id)
				local temp = {}
				for i,v in pairs(cards) do
					table.insert(temp,{Text=v.name,Desc=v.desc})
				end
				server.Remote.MakeGui(plr,"List",{Title = list.name; Tab = temp})
			end
		};
		
		MakeCard = {
			Prefix = server.Settings.Prefix;
			Commands = {"makecard", "maketrellocard", "createcard"};
			Args = {};
			Hidden = false;
			Description = "Opens a gui to make new Trello cards. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"CreateCard")
			end
		};
		
		GetScript = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"getscript";"getadonis"};
			Args = {};
			Hidden = false;
			Description = "Get this script.";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				service.MarketPlace:PromptPurchase(plr, server.Core.LoaderID)
			end
		};
		
		Ping = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"ping";};
			Args = {};
			Hidden = false;
			Description = "Shows you your current ping (in seconds)";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,'Ping')
			end
		};
		
		GetPing = {
			Prefix = server.Settings.Prefix;
			Commands = {"getping";};
			Args = {"player";};
			Hidden = false;
			Description = "Shows the target player's ping (in seconds)";
			Fun = false;
			AdminLevel = "Helpers";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Functions.Hint(v.Name.."'s Ping is "..server.Remote.Get(v,"Ping").."ms",{plr})
				end
			end
		};
		
		Donors = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"donors";"donorlist";"donatorlist";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of donators who are currently in the server";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local temptable = {}
				for i,v in pairs(service.Players:children()) do
					if server.Admin.CheckDonor(v) then
						table.insert(temptable,v.Name)
					end
				end
				server.Remote.MakeGui(plr,'List',{Title = 'Donors In-Game'; Tab = temptable; Update = 'DonorList'})
			end
		};
		
		RequestHelp = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"help";"requesthelp";"gethelp";"lifealert";};
			Args = {};
			Hidden = false;
			Description = "Calls admins for help";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				if server.Settings.HelpSystem == true then
					local num = 0
					local answered = false
					
					if server.Variables.HelpRequests[plr.Name] ~= nil then 
						error("You already have a pending request")
					else
						server.Functions.Hint("Request sent",{plr})
						server.Variables.HelpRequests[plr.Name] = true
					end
					
					for ind,p in pairs(service.Players:GetChildren()) do 
						Routine(function()
							if server.Admin.CheckAdmin(p) then
								local ret = server.Remote.MakeGuiGet(p,"Notification",{
									Title = "Help Request";
									Message = plr.Name.." needs help!";
									Time = 30;
									OnClick = server.Core.Bytecode("return true");
									OnClose = server.Core.Bytecode("return false");
									OnIgnore = server.Core.Bytecode("return false");
								})
								
								num = num+1
								if ret then 
									if not answered then 
										answered = true
										server.Admin.RunCommand(server.Settings.Prefix.."tp",p.Name,plr.Name)
									end
								end
							end
						end)
					end
					
					local w = tick()
					repeat wait(0.5) until tick()-w>30 or answered
					
					server.Variables.HelpRequests[plr.Name] = nil
					
					if not answered then 
						server.Functions.Message("Help System","Sorry but no one is available to help you right now",{plr})
					end
				else
					server.Functions.Message("Help System","Help System Disabled by Place Owner",{plr})
				end
			end
		};
		
		Rejoin = {
			Prefix = server.Settings.PlayerPrefix;
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
					server.Functions.Hint("Could not rejoin.")
				end
			end
		};
		
		Join = {
			Prefix = server.Settings.PlayerPrefix;
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
						server.Functions.Hint("Could not follow "..args[1]..". "..errorMsg,{plr})
					end
				else 
					server.Functions.Hint(args[1].." is not a valid ROBLOX user",{plr})
				end
			end
		};
		
		ShowBackpack = {
			Prefix = server.Settings.Prefix;
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
						server.Remote.MakeGui(plr,"List",{Title = v.Name,Tab = tools})
					end)
				end
			end
		};
		
		PlayerList = {
			Prefix = server.Settings.Prefix;
			Commands = {"players","playerlist"};
			Args = {};
			Hidden = false;
			Description = "Shows you all players currently in-game, including nil ones";
			Fun = false;
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local plrs = {}
				local playz = server.Functions.GrabNilPlayers('all')
				server.Functions.Hint('Pinging players. Please wait. No ping = Ping > 5sec.',{plr})
				for i,v in pairs(playz) do
					Routine(function()
						if type(v)=="String" and v=="NoPlayer" then
							table.insert(plrs,{Text="PLAYERLESS CLIENT",Desc="PLAYERLESS SERVERREPLICATOR. COULD BE LOADING/LAG/EXPLOITER. CHECK AGAIN IN A MINUTE!"})
						else	
							local ping
							Routine(function()	
								ping = server.Remote.Ping(v).."ms"
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
					if server.Functions.CountTable(plrs)>=server.Functions.CountTable(playz) then break end
					wait(0.1)
				end
				server.Remote.MakeGui(plr,'List',{Title = 'Players', Tab = plrs, Update = "PlayerList"})
			end
		};
		
		Agents = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"agents";"trelloagents";"showagents";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of Trello agents pulled from the configured boards";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local temp={}
				for i,v in pairs(server.HTTP.Trello.Agents) do
					table.insert(temp,{Text = v,Desc = "A Trello agent"})
				end
				server.Remote.MakeGui(plr,"List",{Title = "Agents", Tab = temp})
			end
		};

		Credits = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"credit";"credits";};
			Args = {};
			Hidden = false;
			Description = "Credits";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"List",{
					Title = 'Credits', 
					Tab = server.Credits
				})
			end
		};	
		
		Alert = {
			Prefix = server.Settings.Prefix;
			Commands = {"alert";"alarm";"annoy";};
			Args = {"player";"message";};
			Filter = true;
			Description = "Get someone's attention";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1]:lower())) do
					server.Remote.MakeGui(v,"Alert",{Message = (service.Filter(args[2],plr,v) or "Wake up")})
				end
			end
		};	
		
		Usage = {
			Prefix = server.Settings.PlayerPrefix;
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
					'Ex: '..server.Settings.Prefix..'kill FUNCTION, so like '..server.Settings.Prefix..'kill '..server.Settings.SpecialPrefix..'all';
					'Put /e in front to make it silent (/e '..server.Settings.Prefix..'kill scel)';
					server.Settings.SpecialPrefix..'me - Runs a command on you';
					server.Settings.SpecialPrefix..'all - Runs a command on everyone';
					server.Settings.SpecialPrefix..'admins - Runs a command on all admins in the game';
					server.Settings.SpecialPrefix..'nonadmins - Same as !admins but for people who are not an admin';
					server.Settings.SpecialPrefix..'others - Runs command on everyone BUT you';
					server.Settings.SpecialPrefix..'random - Runs command on a random person';
					server.Settings.SpecialPrefix..'friends - Runs command on anyone on your friends list';
					server.Settings.SpecialPrefix..'besties - Runs command on anyone on your best friends list';
					'%TEAMNAME - Runs command on everyone in the team TEAMNAME Ex: '..server.Settings.Prefix..'kill %raiders';
					'$GROUPID - Run a command on everyone in the group GROUPID, Will default to the GroupId setting if no id is given';
					'-PLAYERNAME - Will remove PLAYERNAME from list of players to run command on. '..server.Settings.Prefix..'kill all,-scel will kill everyone except scel';
					'#NUMBER - Will run command on NUMBER of random players. '..server.Settings.Prefix..'ff #5 will ff 5 random players.';
					'radius-NUMBER -- Lets you run a command on anyone within a NUMBER stud radius of you. '..server.Settings.Prefix..'ff radius-5 will ff anyone within a 5 stud radius of you.';
					'Certain commands can be used by anyone, these commands have '..server.Settings.PlayerPrefix..' infront, such as '..server.Settings.PlayerPrefix..'clean and '..server.Settings.PlayerPrefix..'rejoin';
					''..server.Settings.Prefix..'kill me,noob1,noob2,'..server.Settings.SpecialPrefix..'random,%raiders,$123456,!nonadmins,-scel';
					'Multiple Commands at a time - '..server.Settings.Prefix..'ff me '..server.Settings.BatchKey..' '..server.Settings.Prefix..'sparkles me '..server.Settings.BatchKey..' '..server.Settings.Prefix..'rocket jim';
					'You can add a wait if you want; '..server.Settings.Prefix..'ff me '..server.Settings.BatchKey..' !wait 10 '..server.Settings.BatchKey..' '..server.Settings.Prefix..'m hi we waited 10 seconds';
					''..server.Settings.Prefix..'repeat 10(how many times to run the cmd) 1(how long in between runs) '..server.Settings.Prefix..'respawn jim';
					'Place owners can edit some settings in-game via the '..server.Settings.Prefix..'settings command';
					'Please refer to the Tips and Tricks section under the settings in the script for more detailed explanations'
				}
				server.Remote.MakeGui(plr,"List",{Title = 'Usage', Tab = usage})
			end
		};
		
		Waypoint = {
			Prefix = server.Settings.Prefix;
			Commands = {"waypoint";"wp";"checkpoint";};
			Args = {"name";};
			Filter = true;
			Description = "Makes a new waypoint/sets an exiting one to your current position with the name <name> that you can teleport to using :tp me waypoint-<name>";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local name=args[1] or tostring(#server.Waypoints+1)
				if plr.Character:FindFirstChild('HumanoidRootPart') then
					server.Variables.Waypoints[name] = plr.Character.HumanoidRootPart.Position
					server.Functions.Hint('Made waypoint '..name..' | '..tostring(server.Variables.Waypoints[name]),{plr})
				end
			end
		};
		
		DeleteWaypoint = {
			Prefix = server.Settings.Prefix;
			Commands = {"delwaypoint";"delwp";"delcheckpoint";"deletewaypoint";"deletewp";"deletecheckpoint";};
			Args = {"name";};
			Hidden = false;
			Description = "Deletes the waypoint named <name> if it exist";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(server.Variables.Waypoints) do
					if i:lower():sub(1,#args[1])==args[1]:lower() or args[1]:lower()=='all' then
						server.Variables.Waypoints[i]=nil
						server.Functions.Hint('Deleted waypoint '..i,{plr})
					end
				end
			end
		};
		
		Waypoints = {
			Prefix = server.Settings.Prefix;
			Commands = {"waypoints";};
			Args = {};
			Hidden = false;
			Description = "Shows available waypoints, mouse over their names to view their coordinates";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temp={}
				for i,v in pairs(server.Variables.Waypoints) do
					local x,y,z=tostring(v):match('(.*),(.*),(.*)')
					table.insert(temp,{Text=i,Desc='X:'..x..' Y:'..y..' Z:'..z})
				end
				server.Remote.MakeGui(plr,"List",{Title = 'Waypoints', Tab = temp})
			end
		};
		
		Cameras = {
			Prefix = server.Settings.Prefix;
			Commands = {"cameras";"cams";};
			Args = {};
			Hidden = false;
			Description = "Shows you admin cameras in the server and lets you delete/view them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local tab = {}
				for i,v in pairs(server.Variables.Cameras) do
					table.insert(tab,{Text = v.Name,Desc = "Pos: "..v.Object.Position})
				end
				server.Remote.MakeGui(plr,"List",{Title = "Cameras", Tab = tab})
			end
		};
		
		MakeCamera = {
			Prefix = server.Settings.Prefix;
			Commands = {"makecam";"makecamera";"camera";};
			Args = {"name";};
			Filter = true;
			Description = "Makes a camera named whatever you pick";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if plr and plr.Character and plr.Character:FindFirstChild('Head') then
					if service.Workspace:FindFirstChild('Camera: '..args[1]) then
						server.Functions.Hint(args[1].." Already Exists!",{plr})
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
						table.insert(server.Variables.Cameras,{Brick = cam, Name = args[1]})
					end
				end
			end
		};
		
		ViewCamera = {
			Prefix = server.Settings.Prefix;
			Commands = {"viewcam","viewc","camview","watchcam","cam"};
			Args = {"camera";};
			Description = "Makes you view the target player";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(server.Variables.Cameras) do
					if v.Name:sub(1,#args[1]) == args[1] then
						server.Remote.Send(plr,'Function','SetView',v.Brick)
					end
				end
			end
		};
		
		ForceView = {
			Prefix = server.Settings.Prefix;
			Commands = {"fview";"forceview";"forceviewplayer";"fv";};
			Args = {"player1";"player2";};
			Description = "Forces one player to view another";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for k,p in pairs(service.GetPlayers(plr, args[1])) do
					for i,v in pairs(service.GetPlayers(plr, args[2])) do
						if v and v.Character:FindFirstChild('Humanoid') then
							server.Remote.Send(p,'Function','SetView',v.Character.Humanoid)
						end
					end
				end
			end
		};
		
		View = {
			Prefix = server.Settings.Prefix;
			Commands = {"view";"watch";"nsa";"viewplayer";};
			Args = {"player";};
			Description = "Makes you view the target player";
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character:FindFirstChild('Humanoid') then
						server.Remote.Send(plr,'Function','SetView',v.Character.Humanoid)
					end
				end
			end
		};
		
		ResetView = {
			Prefix = server.Settings.Prefix;
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
					server.Remote.Send(plr,'Function','SetView','reset')
				end
			end
		};
		
		GuiView = {
			Prefix = server.Settings.Prefix;
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
					server.Functions.Hint("Loading GUIs",{plr})
					local guis,rlocked = server.Remote.Get(p,"Function","GetGuiData") 
					if rlocked then
						server.Functions.Hint("ROBLOXLOCKED GUI FOUND! CANNOT DISPLAY!",{plr})
					end
					if guis then
						server.Remote.Send(plr,"Function","LoadGuiData",guis)
					end
				end
			end;
		};
		
		UnGuiView = {
			Prefix = server.Settings.Prefix;
			Commands = {"unguiview","unshowguis","unviewguis"};
			Args = {};
			Description = "Removes the viewed player's GUIs";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				server.Remote.Send(plr,"Function","UnLoadGuiData")
			end;
		};
		
		ServerDetails = {
			Prefix = server.Settings.Prefix;
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
				if server.HTTP.CheckHttp() then
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
				--det.AdminVersion = server.version
				det.ServerStartTime = service.GetTime(server.ServerStartTime)
				local nonnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not server.Admin.CheckAdmin(v:GetPlayer(),false) then
						nonnumber=nonnumber+1
					end
				end
				det.NonAdmins=nonnumber
				local adminnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and server.Admin.CheckAdmin(v:GetPlayer(),false) then
						adminnumber=adminnumber+1
					end
				end
				det.CurrentTime=service.GetTime()
				det.ServerAge=service.GetTime(os.time()-server.Variables.ServerStartTime)
				det.Admins=adminnumber
				det.Objects=#server.Variables.Objects
				det.Cameras=#server.Variables.Cameras
				
				local tab = {}
				for i,v in pairs(det) do
					table.insert(tab,{Text = i..": "..tostring(v),Desc = tostring(v)})
				end
				server.Remote.MakeGui(plr,"List",{Title = "Server Details", Tab = tab, Update = "ServerDetails"})
				--server.Remote.Send(plr,'Function','ServerDetails',det)
			end
		};
		
		ChangeLog = {
			Prefix = server.Settings.Prefix;
			Commands = {"changelog";"changes";};
			Args = {};
			Description = "Shows you the script's changelog";
			AdminLevel = "Players";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"List",{
					Title = 'Change Log',
					Table = server.Changelog,
					Size = {500,400}
				})
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
				local temptable = {}
				
				for i,v in pairs(server.Settings.Creators) do 
					table.insert(temptable,v .. " - Creator") 
				end
				
				for i,v in pairs(server.Settings.Owners) do 
					table.insert(temptable,v .. " - Owner") 
				end
				
				for i,v in pairs(server.Settings.Admins) do 
					table.insert(temptable,v .. " - Admin") 
				end
				
				for i,v in pairs(server.Settings.Moderators) do 
					table.insert(temptable,v .. " - Mod") 
				end 
				
				for i,v in pairs(server.HTTP.Trello.Creators) do 
					table.insert(temptable,v .. " - Creator [Trello]") 
				end 
				
				for i,v in pairs(server.HTTP.Trello.Moderators) do 
					table.insert(temptable,v .. " - Mod [Trello]") 
				end 
				
				for i,v in pairs(server.HTTP.Trello.Admins) do 
					table.insert(temptable,v .. " - Admin [Trello]") 
				end 
				
				for i,v in pairs(server.HTTP.Trello.Owners) do 
					table.insert(temptable,v .. " - Owner [Trello]") 
				end
				
				service.Iterate(server.Settings.CustomRanks,function(rank,tab)
					service.Iterate(tab,function(ind,admin)
						table.insert(temptable,admin.." - "..rank) 
					end)
				end)
				
				table.insert(temptable,'==== Admins In-Game ====')
				for i,v in pairs(service.GetPlayers()) do 
					local level = server.Admin.GetLevel(v)
					if level>=4 then
						table.insert(temptable,v.Name..' - Creator')
					elseif level>=3 then 
						table.insert(temptable,v.Name..' - Owner')
					elseif level>=2 then
						table.insert(temptable,v.Name..' - Admin')
					elseif level>=1 then
						table.insert(temptable,v.Name..' - Mod')
					end 
					
					service.Iterate(server.Settings.CustomRanks,function(rank,tab)
						if server.Admin.CheckTable(v,tab) then
							table.insert(temptable,v.Name.." - "..rank) 
						end
					end)
				end
				
				server.Remote.MakeGui(plr,"List",{Title = 'Admin List',Table = temptable})
			end
		};
		
		BanList = {
			Prefix = server.Settings.Prefix;
			Commands = {"banlist";"banned";"bans";};
			Args = {};
			Hidden = false;
			Description = "Shows you the normal ban list";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local tab = {}
				for i,v in pairs(server.Settings.Banned) do
					table.insert(tab,{Text = tostring(v),Desc = tostring(v)})
				end
				server.Remote.MakeGui(plr,"List",{Title = 'Ban List', Tab = tab})
			end
		};
		
		Vote = {
			Prefix = server.Settings.Prefix;
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
						local response = server.Remote.GetGui(v,"Vote",{Question = question,Answers = anstab})
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
				server.Remote.MakeGui(plr,"List",{Title = 'Results', Tab = tab})
			end
		};
		
		ToolList = {
			Prefix = server.Settings.Prefix;
			Commands = {"tools";"toollist";};
			Args = {};
			Hidden = false;
			Description = "Shows you a list of tools that can be obtains via the give command";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local prefix = server.Settings.Prefix
				local split = server.Settings.SplitKey
				local num = 0
				local children = {
					server.Core.Bytecode([[Object:ResizeCanvas(false, true, false, false, 5, 5)]]);
				}
				
				for i, v in next,server.Settings.Storage:GetChildren() do 
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
									OnClick = server.Core.Bytecode([[
										client.Remote.Send("ProcessCommand", "]]..prefix..[[give]]..split..[[me]]..split..v.Name..[[");
									]]);
								}
							};
						})
						
						num = num+1;
					end 
				end
				
				server.Remote.MakeGui(plr, "Window", {
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
			Prefix = server.Settings.Prefix;
			Commands = {"piano";};
			Args = {"player"};
			Hidden = false;
			Description = "Gives you a playable keyboard piano. Credit to NickPatella.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,service.GetPlayers(plr, args[1]) do
					local piano = server.Deps.Assets.Piano:clone()
					piano.Parent = v:FindFirstChild("PlayerGui") or v.Backpack
					piano.Disabled = false
				end
			end
		};
		
		Insert = {
			Prefix = server.Settings.Prefix;
			Commands = {"insert";"ins";};
			Args = {"id";};
			Hidden = false;
			Description = "Inserts whatever object belongs to the ID you supply, the object must be in the place owner's or ROBLOX's inventory";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local obj = service.Insert(tonumber(args[1]))
				if obj and plr.Character then
					table.insert(server.Variables.InsertedObjects, obj) 
					obj.Parent = service.Workspace 
					pcall(function() obj:MakeJoints() end)
					obj:MoveTo(plr.Character:GetModelCFrame().p)
				end
			end
		};
		
		InsertClear = {
			Prefix = server.Settings.Prefix;
			Commands = {"insclear";"clearinserted";"clrins";"insclr";};
			Args = {};
			Hidden = false;
			Description = "Removes inserted objects";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(server.Variables.InsertedObjects) do 
					v:Destroy() 
					table.remove(server.Variables.InsertedObjects,i)
				end
			end
		};
		
		Clean = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"clean";};
			Args = {};
			Hidden = false;
			Description = "Cleans some useless junk out of service.Workspace";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args) 
				server.Functions.CleanWorkspace()
			end
		};
		
		Chik3n = {
			Prefix = server.Settings.Prefix;
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
				local scr = server.Deps.Assets.Quacker:Clone()
				scr.Name = "Quacker"
				scr.Parent = hat
				--]]
				hat.Anchored = true
				hat.CanCollide = false
				hat.ChickenSounds.Disabled = true
				table.insert(hats,hat)
				table.insert(server.Variables.Objects,hat)
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
						table.insert(server.Variables.Objects,nhat)
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
			Prefix = server.Settings.Prefix;
			Commands = {"clear";"cleargame";"clr";};
			Args = {};
			Hidden = false;
			Description = "Remove admin objects";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				service.StopLoop("ChickenSpam")
				for i,v in pairs(server.Variables.Objects) do 
					if v:IsA("Script") or v:IsA("LocalScript") then 
						v.Disabled = true 
					end 
					v:Destroy() 
				end
				
				for i,v in pairs(server.Variables.Cameras) do 
					if v then 
						table.remove(server.Variables.Cameras,i) 
						v:Destroy() 
					end 
				end
				
				for i,v in pairs(server.Variables.Jails) do
					if not v.Player or not v.Player.Parent then
						local ind = v.Index
						service.StopLoop(ind.."JAIL")
						Pcall(function() v.Jail:Destroy() end)
						server.Variables.Jails[ind] = nil
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
				
				server.Variables.Objects = {}
				--server.RemoveMessage()
			end
		};
		
		FullClear = {
			Prefix = server.Settings.Prefix;
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
				
				--for i,v in next,server.Functions.GetPlayers() do
				--	server.Remote.Send(v, "Function", "ClearAllInstances")
				--end
			end
		};
		
		ShowServerInstances = {
			Prefix = server.Settings.Prefix;
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
				
				server.Remote.MakeGui(plr, "List", {
					Title = "Adonis Instances";
					Table = temp;
					Stacking = false;
					Update = "Instances";
				})
			end
		};
		
		ShowClientInstances = {
			Prefix = server.Settings.Prefix;
			Commands = {"clientinstances";};
			Args = {"player"};
			Description = "Shows all instances created client-side by Adonis";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
					local instList = server.Remote.Get(v, "InstanceList")
					if instList then
						server.Remote.MakeGui(plr, "List", {
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
			Prefix = server.Settings.Prefix;
			Commands = {"clearguis";"clearmessages";"clearhints";"clrguis";"clrgui";"clearscriptguis";"removescriptguis"};
			Args = {"player","deleteAll?"};
			Hidden = false;
			Description = "Remove script GUIs such as :m and :hint";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1] or "all")) do
					if tostring(args[2]):lower() == "yes" or tostring(args[2]):lower() == "true" then
						server.Remote.RemoveGui(v,true)
					else
						server.Remote.RemoveGui(v,"Message")
						server.Remote.RemoveGui(v,"Hint")
						server.Remote.RemoveGui(v,"Notification")
						server.Remote.RemoveGui(v,"PM")
						server.Remote.RemoveGui(v,"Output")
						server.Remote.RemoveGui(v,"Effect")
						server.Remote.RemoveGui(v,"Alert")
					end
				end
			end
		};
		
		ResetLighting = {
			Prefix = server.Settings.Prefix;
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
				for i,v in pairs(service.Lighting:GetChildren()) do
					if v:IsA("Sky") then
						service.Delete(v)
					end
				end
				if server.Variables.OriginalLightingSettings.Sky then
					server.Variables.OriginalLightingSettings.Sky:Clone().Parent = service.Lighting
				end
			end
		};
		
		ClearLighting = {
			Prefix = server.Settings.Prefix;
			Commands = {"fixplayerlighting","rplighting","clearlighting","serverlighting"};
			Args = {"player"};
			Hidden = false;
			Description = "Sets the player's lighting to match the server's";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for prop,val in pairs(server.Variables.LightingSettings) do
						server.Remote.SetLighting(v,prop,val)
					end
				end
			end
		};
		
		Freaky = {
			Prefix = server.Settings.Prefix;
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
						server.Remote.SetLighting(v,"FogColor", Color3.new(tonumber(num1),tonumber(num2),tonumber(num3)))
						server.Remote.SetLighting(v,"FogEnd", 9e9)
					end
				else
					server.Functions.SetLighting("FogColor", Color3.new(tonumber(num1),tonumber(num2),tonumber(num3)))
					server.Functions.SetLighting("FogEnd", 9e9) --Thanks go to Janthran for another neat glitch
				end
			end
		};
		
		Info = {
			Prefix = server.Settings.Prefix;
			Commands = {"info";"age";};
			Args = {"player";"groupid";};
			Hidden = false;
			Description = "Shows you information about the target player";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local plz = service.GetPlayers(plr, args[1]:lower())
				for i,v in pairs(plz) do
					if args[2] and tonumber(args[2]) then
						local role = v:GetRoleInGroup(tonumber(args[2]))
						server.Functions.Hint("Lower: "..v.Name:lower().." - ID: "..v.userId.." - Age: "..v.AccountAge.." - Rank: "..tostring(role),{plr})
					else
						server.Functions.Hint("Lower: "..v.Name:lower().." - ID: "..v.userId.." - Age: "..v.AccountAge,{plr})
					end
				end
			end
		};
		
		ResetStats = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"gear";"givegear";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Gives the target player(s) a gear from the catalog based on the ID you supply";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local gear = service.Insert(tonumber(args[2]))
				if gear:IsA("Tool") or gear:IsA("HopperBin") then 
					service.New("StringValue",gear).Name = server.Variables.CodeName..gear.Name 
					for i, v in pairs(service.GetPlayers(plr,args[1])) do
						if v:findFirstChild("Backpack") then
							gear:Clone().Parent = v.Backpack 
						end
					end
				end
			end
		};
		
		Sell = {
			Prefix = server.Settings.Prefix;
			Commands = {"sell";};
			Args = {"player";"id";"currency";};
			Hidden = false;
			Description = "Prompts the player(s) to buy the product belonging to the ID you supply";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local type = args[3] or 'default'
				local t
				if type:lower()=='tix' or type:lower()=='tickets' or type:lower()=='t' then
					t = Enum.CurrencyType.Tix
				elseif type:lower()=='robux' or type:lower()=='rb' or type:lower()=='r' then
					t = Enum.CurrencyType.Robux
				else
					t = Enum.CurrencyType.Default
				end
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					service.MarketPlace:PromptPurchase(v,tonumber(args[2]),false,t)
				end
			end
		};
		
		Hat = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"capes";"capelist";};
			Args = {};
			Hidden = false;
			Description = "Shows you the list of capes for the cape command";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local list={}
				for i,v in pairs(server.Variables.Capes) do
					table.insert(list,v.Name)
				end
				server.Remote.MakeGui(plr,'List',{Title = 'Cape List',Tab = list})
			end
		};
		
		Cape = {
			Prefix = server.Settings.Prefix;
			Commands = {"cape";"givecape";};
			Args = {"player";"name/color";"material";"reflectance";"id";};
			Hidden = false;
			Description = "Gives the target player(s) the cape specified, do server.Settings.Prefixcapes to view a list of available capes ";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local color="White"
				if ypcall(function() return BrickColor.new(args[2]) end) then color = args[2] end
				local mat = args[3] or "Fabric"
				local ref = args[4]
				local id = args[5]
				if args[2] and not args[3] then
					for k,cape in pairs(server.Variables.Capes) do
						if args[2]:lower()==cape.Name:lower() then
							color = cape.Color
							mat = cape.Material
							ref = cape.Reflectance
							id = cape.ID
						end
					end
				end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do	
					server.Functions.Cape(v,false,mat,color,id,ref) 
				end 
			end
		};
		
		UnCape = {
			Prefix = server.Settings.Prefix;
			Commands = {"uncape";"removecape";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target player(s)'s cape";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					server.Functions.UnCape(v)
				end
			end
		};
		
		Slippery = {
			Prefix = server.Settings.Prefix;
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
				local scr = server.Deps.Assets.Slippery:Clone()
				
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"noclip";};
			Args = {"player";};
			Hidden = false;
			Description = "NoClips the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local clipper = server.Deps.Assets.Clipper:Clone()
				clipper.Name = "ADONIS_NoClip"
				
				for i,p in pairs(service.GetPlayers(plr,args[1])) do
					server.Admin.RunCommand(server.Settings.Prefix.."clip",p.Name)
					local new = clipper:Clone()
					new.Parent = p.Character.Humanoid
					new.Disabled = false
				end
			end
		};
		
		FlyNoClip = {
			Prefix = server.Settings.Prefix;
			Commands = {"flynoclip";"oldnoclip";};
			Args = {"player";};
			Hidden = false;
			Description = "Old flying NoClip";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = server.Deps.Assets.FlyClipper:Clone()
				scr.Name = "ADONIS_NoClip"
				
				local enabled = service.New("BoolValue",{
					Parent = scr;
					Value = true;
					Name = "Enabled";
				})
					
				for i,p in pairs(service.GetPlayers(plr,args[1])) do
					server.Admin.RunCommand(server.Settings.Prefix.."clip",p.Name)
					local new = scr:Clone()
					new.Parent = p.Character.Humanoid
					new.Disabled = false
				end
			end
		};
		
		Clip = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
						--table.insert(server.Variables.Objects, mod) 
						
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
						
						server.Variables.Jails[ind] = jail
						
						for l,k in pairs(v.Backpack:GetChildren()) do 
							if k:IsA("Tool") or k:IsA("HopperBin") then 
								table.insert(jail.Tools,k)
								k.Parent = nil
							end 
						end
						
						service.TrackTask("Thread: JailLoop"..tostring(ind), function()
							while wait() and server.Variables.Jails[ind] == jail and mod.Parent == service.Workspace do
								if server.Variables.Jails[ind] == jail and v.Parent == service.Players then
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
								elseif server.Variables.Jails[ind] ~= jail then
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
			Prefix = server.Settings.Prefix;
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
					local jail = server.Variables.Jails[ind]
					if jail then
						--service.StopLoop(ind.."JAIL")
						Pcall(function()
							for i,tool in pairs(jail.Tools) do
								tool.Parent = v.Backpack
							end
						end)
						Pcall(function() jail.Jail:Destroy() end)
						server.Variables.Jails[ind] = nil
						found = true
					end
				end
				
				if not found then 
					for i,v in next,server.Variables.Jails do
						if v.Name:lower():sub(1,#args[1]) == args[1]:lower() then
							local ind = v.Index
							service.StopLoop(ind.."JAIL")
							Pcall(function() v.Jail:Destroy() end)
							server.Variables.Jails[ind] = nil
						end
					end
				end
			end
		};
		
		BubbleChat = {
			Prefix = server.Settings.Prefix;
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
					server.Remote.MakeGui(v,"BubbleChat",{Color = color})
				end
			end
		};
		
		Track = {
			Prefix = server.Settings.Prefix;
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
						server.Remote.MakeLocal(plr,bb,false,true)
						local event;event = v.CharacterRemoving:connect(function() server.Remote.RemoveLocal(plr,v.Name..'Tracker') event:Disconnect() end)
						local event2;event2 = plr.CharacterRemoving:connect(function() server.Remote.RemoveLocal(plr,v.Name..'Tracker') event2:Disconnect() end)
					end
				end
			end
		};
		
		UnTrack = {
			Prefix = server.Settings.Prefix;
			Commands = {"untrack";"untrace";"unfind";};
			Args = {"player";};
			Hidden = false;
			Description = "Stops tracking the target player(s)";
			Fun = false;
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1]:lower() == server.Settings.SpecialPrefix.."all" then
					server.Remote.RemoveLocal(plr,'Tracker',false,true)
				else
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						server.Remote.RemoveLocal(plr,v.Name..'Tracker')
					end
				end
			end
		};
		
		Glitch = {
			Prefix = server.Settings.Prefix;
			Commands = {"glitch";"glitchdisorient";"glitch1";"glitchy";"gd";};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "Makes the target player(s)'s character teleport back and forth rapidly, quite trippy, makes bricks appear to move as the player turns their character";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 15)
				local scr = server.Deps.Assets.Glitcher:Clone()
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
			Prefix = server.Settings.Prefix;
			Commands = {"ghostglitch";"glitch2";"glitchghost";"gg";};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "The same as gd but less trippy, teleports the target player(s) back and forth in the same direction, making two ghost like images of the game";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 150)
				local scr = server.Deps.Assets.Glitcher:Clone()
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
			Prefix = server.Settings.Prefix;
			Commands = {"vibrate";"glitchvibrate";"gv";};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "Kinda like gd, but teleports the player to four points instead of two";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 0.1)
				local scr = server.Deps.Assets.Glitcher:Clone()
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"phase";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the player(s) character completely local";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.MakeLocal(v,v.Character)
				end
			end
		};
		
		UnPhase = {
			Prefix = server.Settings.Prefix;
			Commands = {"unphase";};
			Args = {"player";};
			Hidden = false;
			Description = "UnPhases the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.MoveLocal(v,v.Character.Name,false,service.Workspace)
					v.Character.Parent = service.Workspace
				end
			end
		};
		
		GiveStarterPack = {
			Prefix = server.Settings.Prefix;
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
							if not q:FindFirstChild(server.Variables.CodeName) then 
								service.New("StringValue", q).Name = server.Variables.CodeName 
							end 
							q.Parent = v.Backpack  
						end
					end
				end
			end
		};
		
		Sword = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
							table.insert(server.Variables.Objects,cl) 
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
		
		ClickTeleport = {
			Prefix = server.Settings.Prefix;
			Commands = {"clickteleport";"teleporttoclick";"ct";"clicktp";"forceteleport";"ctp";"ctt";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives you a tool that lets you click where you want the target player to stand, hold r to rotate them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local scr = server.Deps.Assets.ClickTeleport:Clone()
					scr.Mode.Value = "Teleport"
					scr.Target.Value = v.Name
					local tool = service.New('HopperBin')
					service.New("StringValue",tool).Name = server.Variables.CodeName
					scr.Parent = tool
					scr.Disabled = false
					tool.Parent = plr.Backpack
				end
			end
		};
		
		ClickWalk = {
			Prefix = server.Settings.Prefix;
			Commands = {"clickwalk";"cw";"ctw";"forcewalk";"walktool";"walktoclick";"clickcontrol";"forcewalk";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives you a tool that lets you click where you want the target player to walk, hold r to rotate them";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local scr = server.Deps.Assets.ClickTeleport:Clone()
					scr.Mode.Value = "Walk"
					scr.Target.Value = v.Name
					local tool = service.New('HopperBin')
					service.New("StringValue",tool).Name = server.Variables.CodeName
					scr.Parent = tool
					scr.Disabled = false
					tool.Parent = plr.Backpack
				end
			end
		};
		
		BodySwap = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
					ypcall(function() v.Character.Humanoid:UnequipTools() end)
					for k,t in pairs(v.Backpack:children()) do
						if t:IsA('Tool') or t:IsA('HopperBin') then
							table.insert(temptools,t)
						end
					end
					v:LoadCharacter()
					v.Character.HumanoidRootPart.CFrame = pos
					for d,f in pairs(v.Character:children()) do
						if f:IsA('ForceField') then f:Destroy() end
					end
					v:WaitForChild("Backpack")
					v.Backpack:ClearAllChildren()
					for l,m in pairs(temptools) do
						m:clone().Parent = v.Backpack
					end
				end
			end
		};
		
		Kill = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"respawn";"re"};
			Args = {"player";};
			Hidden = false;
			Description = "Repsawns the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					v:LoadCharacter()
					server.Remote.Send(v,'Function','SetView','reset')
				end
			end
		};
		
		Trip = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
						server.Functions.NewParticle(v.Character.HumanoidRootPart,"PointLight",{
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
			Prefix = server.Settings.Prefix;
			Commands = {"unlight";};
			Args = {"player";};
			Hidden = false;
			Description = "UnLights the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then 
						server.Functions.RemoveParticle(v.Character.HumanoidRootPart,"ADONIS_LIGHT")
					end
				end
			end
		};
		
		Oddliest = {
			Prefix = server.Settings.Prefix;
			Commands = {"oddliest";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns you into the one and only Oddliest";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Admin.RunCommand(server.Settings.Prefix.."char",v.Name,"51310503")
				end
			end
		};
		
		Sceleratis = {
			Prefix = server.Settings.Prefix;
			Commands = {"sceleratis";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns you into me <3";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Admin.RunCommand(server.Settings.Prefix.."char",v.Name,"1237666")
				end
			end
		};
		
		HatPets = {
			Prefix = server.Settings.Prefix;
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
								table.insert(server.Variables.Objects,m)
								mode = service.New('StringValue',m)
								mode.Name = 'Mode'
								mode.Value = 'Follow'
								obj = service.New('ObjectValue',m)
								obj.Name = 'Target'
								obj.Value = v.Character.HumanoidRootPart
								
								local scr = server.Deps.Assets.HatPets:Clone()
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
			Prefix = server.Settings.PlayerPrefix;
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
					server.Functions.Hint("You don't have any hat pets! If you are an admin use the :hatpets command to get some",{plr})
				end
			end
		};
		
		Ambient = {
			Prefix = server.Settings.Prefix;
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
						server.Remote.SetLighting(v,"Ambient",Color3.new(r,g,b))
					end
				else
					server.Functions.SetLighting("Ambient",Color3.new(r,g,b))
				end
			end
		};
		
		OutdoorAmbient = {
			Prefix = server.Settings.Prefix;
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
						server.Remote.SetLighting(v,"OutdoorAmbient",Color3.new(r,g,g))
					end
				else
					server.Functions.SetLighting("OutdoorAmbient",Color3.new(r,g,b))
				end
			end
		};
		
		RemoveFog = {
			Prefix = server.Settings.Prefix;
			Commands = {"nofog";"fogoff";};
			Args = {"optional player"};
			Hidden = false;
			Description = "Fog Off";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[1] then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						server.Remote.SetLighting(v,"FogEnd",1000000000000)
					end
				else
					server.Functions.SetLighting("FogEnd",1000000000000)
				end
			end
		};
		
		Shadows = {
			Prefix = server.Settings.Prefix;
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
							server.Remote.SetLighting(v,"GlobalShadows",true)
						end
					else
						server.Functions.SetLighting("GlobalShadows",true)
					end
				elseif args[1]:lower()=='off' or args[1]:lower()=="false" then
					if args[2] then
						for i,v in pairs(service.GetPlayers(plr,args[2])) do
							server.Remote.SetLighting(v,"GlobalShadows",false)
						end
					else
						server.Functions.SetLighting("GlobalShadows",false)
					end
				end
			end
		};
		
		Outlines = {
			Prefix = server.Settings.Prefix;
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
							server.Remote.SetLighting(v,"Outlines",true)
						end
					else
						server.Functions.SetLighting("Outlines",true)
					end
				elseif args[1]:lower()=='off' or args[1]:lower()=="false" then
					if args[2] then
						for i,v in pairs(service.GetPlayers(plr,args[2])) do
							server.Remote.SetLighting(v,"Outlines",false)
						end
					else
						server.Functions.SetLighting("Outlines",false)
					end
				end
			end
		};
		
		Brightness = {
			Prefix = server.Settings.Prefix;
			Commands = {"brightness";};
			Args = {"number";"optional player"};
			Hidden = false;
			Description = "Change Brightness";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[2] then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						server.Remote.SetLighting(v,"Brightness",args[1])
					end
				else
					server.Functions.SetLighting("Brightness",args[1])
				end
			end
		};
		
		Time = {
			Prefix = server.Settings.Prefix;
			Commands = {"time";"timeofday";};
			Args = {"time";"optional player"};
			Hidden = false;
			Description = "Change Time";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[2] then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						server.Remote.SetLighting(v,"TimeOfDay",args[1])
					end
				else
					server.Functions.SetLighting("TimeOfDay",args[1])
				end
			end
		};
		
		
		FogColor = {
			Prefix = server.Settings.Prefix;
			Commands = {"fogcolor";};
			Args = {"num";"num";"num";"optional player"};
			Hidden = false;
			Description = "Fog Color";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[4] then
					for i,v in pairs(service.GetPlayers(plr,args[4])) do
						server.Remote.SetLighting(v,"FogColor",Color3.new(args[1],args[2],args[3]))
					end
				else
					server.Functions.SetLighting("FogColor",Color3.new(args[1],args[2],args[3]))
				end
			end
		};
		
		FogStartEnd = {
			Prefix = server.Settings.Prefix;
			Commands = {"fog";};
			Args = {"start";"end";"optional player"};
			Hidden = false;
			Description = "Fog Start/End";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if args[3] then
					for i,v in pairs(service.GetPlayers(plr,args[3])) do
						server.Remote.SetLighting(v,"FogEnd",args[2])
						server.Remote.SetLighting(v,"FogStart",args[1])
					end
				else
					server.Functions.SetLighting("FogEnd",args[2])
					server.Functions.SetLighting("FogStart",args[1])
				end
			end
		};
		
		BuildingTools = {
			Prefix = server.Settings.Prefix;
			Commands = {"btools";"buildtools";"buildingtools";"buildertools";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives the target player(s) basic building tools and the F3X tool";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				--[[local t1 = service.New("HopperBin") 
				t1.Name = "Move" 
				t1.BinType = "GameTool"
				local t2 = service.New("HopperBin") 
				t2.Name = "Clone"
				t2.BinType = "Clone"
				local t3 = service.New("HopperBin") 
				t3.Name = "Delete"
				t3.BinType = "Hammer"--]]
				local f3x = service.New("Tool")
				f3x.CanBeDropped = false
				f3x.ManualActivationOnly = false
				f3x.ToolTip = "Building Tools by F3X"
				local handle = service.New("Part",f3x)
				handle.Name = "Handle"
				handle.Size = Vector3.new(1,1,1)
				handle.CanCollide = false
				handle.BrickColor = BrickColor.new("Really black")
				local mesh = service.New("BlockMesh",handle) --#Lazy
				mesh.Scale = Vector3.new(1.1,1.1,1.1)
				for k,m in pairs(server.Deps.Assets['F3X Deps']:children()) do
					m:Clone().Parent = f3x
				end
				f3x.Name='F3X'
				--local t4 = service.New("HopperBin") 
				--t4.Name = "Resize"
				--local cl=deps.ResizeScript:clone()
				--cl.Parent=t4
				--cl.Disabled=false --F3X Kinda replaces the need for this
				--[[service.New("StringValue",t1).Name = server.Variables.CodeName
				service.New("StringValue",t2).Name = server.Variables.CodeName
				service.New("StringValue",t3).Name = server.Variables.CodeName--]]
				--service.New("StringValue",t4).Name = server.Variables.CodeName
				service.New("StringValue",f3x).Name = server.Variables.CodeName
				
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					--server.Send.Remote(v,"Function","setEffectVal","AntiDeleteTool",false)
					if v:findFirstChild("Backpack") then 
						--[[t1:Clone().Parent = v.Backpack
						t2:Clone().Parent = v.Backpack
						t3:Clone().Parent = v.Backpack--]]
						f3x:Clone().Parent = v.Backpack
						--t4.Parent=v.Backpack
					end
				end
			end
		};
		
		StarterGive = {
			Prefix = server.Settings.Prefix;
			Commands = {"startergive";};
			Args = {"player";"toolname";};
			Hidden = false;
			Description = "Places the desired tool into the target player(s)'s StarterPack";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local found = {}
				local temp = service.New("Folder")
				for a, tool in pairs(server.Settings.Storage:GetChildren()) do
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"give";"tool";};
			Args = {"player";"tool";};
			Hidden = false;
			Description = "Gives the target player(s) the desired tool(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local found = {}
				local temp = service.New("Folder")
				for a, tool in pairs(server.Settings.Storage:GetChildren()) do
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"removeguis";"noguis";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove the target player(s)'s screen guis";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.LoadCode(v,[[for i,v in pairs(service.PlayerGui:GetChildren()) do if not client.Core.GetGui(v) then v:Destroy() end end]])
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
						for a, tool in pairs(v.Character:children()) do if tool:IsA("Tool") or tool:IsA("HopperBin") then tool:Destroy() end end
						for a, tool in pairs(v.Backpack:children()) do if tool:IsA("Tool") or tool:IsA("HopperBin") then tool:Destroy() end end
					end
				end
			end
		};
		
		Rank = {
			Prefix = server.Settings.Prefix;
			Commands = {"rank";"getrank";};
			Args = {"player";"groupID";};
			Hidden = false;
			Description = "Shows you what rank the target player(s) are in the group specified by groupID";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if  v:IsInGroup(args[2]) then 
						server.Functions.Hint("[" .. v:GetRankInGroup(args[2]) .. "] " .. v:GetRoleInGroup(args[2]), {plr})
					elseif not v:IsInGroup(args[2])then
						server.Functions.Hint(v.Name .. " is not in the group " .. args[2], {plr})
					end
				end
			end
		};
		
		Damage = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"speed";"setspeed";"walkspeed";};
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
		
		SetFOV = {
			Prefix = server.Settings.Prefix;
			Commands = {"fov";"fieldofview";"setfov"};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Set the target player(s)'s field of view to <number> (min 1, max 120)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2] and tonumber(args[2]), "Argument missing or invalid")
				for i,v in next,service.GetPlayers(plr, args[1]) do
					server.Remote.LoadCode(v,[[workspace.CurrentCamera.FieldOfView=]].. math.clamp(tonumber(args[2]), 1, 120))
				end
			end
		};
		
		ForcePlace = {
			Prefix = server.Settings.Prefix;
			Commands = {"forceplace";};
			Args = {"player";"placeid/serverName";};
			Hidden = false;
			Description = "Force the target player(s) to teleport to the desired place";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				local id = tonumber(args[2])
				local players = service.GetPlayers(plr,args[1])
				local servers = server.Core.GetData("PrivateServers") or {}
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
			Prefix = server.Settings.Prefix;
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
							Text = "Click to teleport to place "..args[2]..".",
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
			Prefix = server.Settings.Prefix;
			Commands = {"makeserver";"reserveserver";"privateserver";};
			Args = {"serverName";"(optional) placeId";};
			Filter = true;
			Description = "Makes a private server that you can teleport yourself and friends to using :place player(s) serverName; Will overwrite servers with the same name; Caps specific";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local place = tonumber(args[2]) or game.PlaceId		
				local code = service.TeleportService:ReserveServer(place)
				local servers = server.Core.GetData("PrivateServers") or {}	
				servers[args[1]] = {Code = code,ID = place}
				server.Core.SetData("PrivateServers",servers)
				server.Functions.Hint("Made server "..args[1].." | Place: "..place,{plr})
			end
		};
		
		DeleteServer = {
			Prefix = server.Settings.Prefix;
			Commands = {"delserver";"deleteserver"};
			Args = {"serverName";};
			Hidden = false;
			Description = "Deletes a private server from the list.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local servers = server.Core.GetData("PrivateServers") or {}
				if servers[args[1]] then	
					servers[args[1]] = nil
					server.Core.SetData("PrivateServers",servers)	
					server.Functions.Hint("Removed server "..args[1],{plr})
				else
					server.Functions.Hint("Server "..args[1].." was not found!",{plr})
				end	
			end
		};
		
		ListServers = {
			Prefix = server.Settings.Prefix;
			Commands = {"servers";"privateservers";};
			Args = {};
			Hidden = false;
			Description = "Shows you a list of private servers that were created with :makeserver";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local servers = server.Core.GetData("PrivateServers") or {}
				local tab = {}
				for i,v in pairs(servers) do
					table.insert(tab,{Text = i,Desc = "Place: "..v.ID.." | Code: "..v.Code})
				end
				server.Remote.MakeGui(plr,"List",{Title = "Servers",Table = tab})
			end
		};
		
		GRPlaza = {
			Prefix = server.Settings.Prefix;
			Commands = {"grplaza";"grouprecruitingplaza";"groupplaza";};
			Args = {"player";};
			Hidden = false;
			Description = "Teleports the target player(s) to the Group Recruiting Plaza to look for potential group members";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.MakeGui(v,"Notification",{
						Title = "Teleport",
						Text = "Click to teleport to GRP",
						Time = 30,
						OnClick = server.Core.Bytecode("service.TeleportService:Teleport(6194809)")
					})	
				end
			end
		};
		
		BunnyHop = {
			Prefix = server.Settings.Prefix;
			Commands = {"bunnyhop";"bhop"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the player jump, and jump... and jump. Just like the rabbit noobs you find in sf games ;)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local bunnyScript = server.Deps.Assets.BunnyHop
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
					
					for i,v in pairs(server.Variables.Waypoints) do
						if i:lower():sub(1,#m)==m:lower() then
							point=v
						end
					end
					
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						if point then
							v.Character:MoveTo(point)
						end
					end
					
					if not point then server.Functions.Hint('Waypoint '..m..' was not found.',{plr}) end
				elseif args[2]:find(',') then
					local x,y,z = args[2]:match('(.*),(.*),(.*)')
					for i,v in pairs(service.GetPlayers(plr,args[1])) do 
						v.Character:MoveTo(Vector3.new(tonumber(x),tonumber(y),tonumber(z))) 
					end
				else
					local target = service.GetPlayers(plr,args[2])[1]
					local players = service.GetPlayers(plr,args[1])
					if #players == 1 and players[1] == target then
						local n = players[1]
						if n.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("HumanoidRootPart") then
							n.Character.Humanoid.Jump = true
							wait()
							n.Character.HumanoidRootPart.CFrame = (target.Character.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(90/#players*1),0)*CFrame.new(5+.2*#players,0,0))*CFrame.Angles(0,math.rad(90),0)
						end
					else
						for k,n in pairs(players) do
							if n~=target then
								--if n.Character.Humanoid.Sit then
								--	n.Character.Humanoid.Sit = false
								--	wait(0.5)
								--end
								n.Character.Humanoid.Jump = true
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
			Prefix = server.Settings.Prefix;
			Commands = {"bring";"tptome";};
			Args = {"player";};
			Hidden = false;
			Description = "Teleport the target(s) to you";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Admin.RunCommand(server.Settings.Prefix.."tp",v.Name,plr.Name)
				end
			end
		};
		
		To = {
			Prefix = server.Settings.Prefix;
			Commands = {"to";"tpmeto";};
			Args = {"player";};
			Hidden = false;
			Description = "Teleport you to the target";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Admin.RunCommand(server.Settings.Prefix.."tp",plr.Name,v.Name)
				end
			end
		};
		
		FreeFall = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"shirt";"giveshirt";};
			Args = {"player";"ID";};
			Hidden = false;
			Description = "Give the target player(s) the shirt that belongs to <ID>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local image = server.Functions.GetTexture(args[2])
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if image then
						if v.Character and image then
							for g,k in pairs(v.Character:children()) do
								if k:IsA("Shirt") then k:Destroy() end
							end
							service.New('Shirt',v.Character).ShirtTemplate="http://www.roblox.com/asset/?id="..image
						end
					else
						for g,k in pairs(v.Character:children()) do
							if k:IsA("Shirt") then k:Destroy() end
						end
					end
				end
			end
		};
		
		Pants = {
			Prefix = server.Settings.Prefix;
			Commands = {"pants";"givepants";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Give the target player(s) the pants that belongs to <id>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local image = server.Functions.GetTexture(args[2])
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if image then
						if v.Character and image then 
							for g,k in pairs(v.Character:children()) do
								if k:IsA("Pants") then k:Destroy() end
							end
							service.New('Pants',v.Character).PantsTemplate="http://www.roblox.com/asset/?id="..image
						end
					else
						for g,k in pairs(v.Character:children()) do
							if k:IsA("Pants") then k:Destroy() end
						end
					end
				end
			end
		};
		
		Face = {
			Prefix = server.Settings.Prefix;
			Commands = {"face";"giveface";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Give the target player(s) the face that belongs to <id>";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					--local image=server.GetTexture(args[2])
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
			Prefix = server.Settings.Prefix;
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
						server.Functions.Cape(v,false,'Fabric','Pink',109301474)
					end
				end
			end
		};
		
		Shrek = {
			Prefix = server.Settings.Prefix;
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
							server.Admin.RunCommand(server.Settings.Prefix.."pants",v.Name,"233373970")
							server.Admin.RunCommand(server.Settings.Prefix.."shirt",v.Name,"133078195")
							
							for i,v in pairs(v.Character:children()) do
								if v:IsA("Accoutrement") or v:IsA("CharacterMesh") then
									v:Destroy()
								end
							end
							
							server.Admin.RunCommand(server.Settings.Prefix.."hat",v.Name,"20011951")
							
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
			Prefix = server.Settings.Prefix;
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
							service.New("Explosion",service.Workspace).Position = v.Character.HumanoidRootPart.Position
							v.Character:BreakJoints()
						end
					end)
				end
			end
		};
		
		Dance = {
			Prefix = server.Settings.Prefix;
			Commands = {"dance";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.Send(v,'Function','PlayAnimation',27789359)
				end
			end
		};
		
		BreakDance = {
			Prefix = server.Settings.Prefix;
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
						--server.Remote.Send(v,'Function','Effect','dance')
						server.Admin.RunCommand(server.Settings.Prefix.."sparkles",v.Name,color)
						server.Admin.RunCommand(server.Settings.Prefix.."fire",v.Name,color)
						server.Admin.RunCommand(server.Settings.Prefix.."nograv",v.Name)	
						server.Admin.RunCommand(server.Settings.Prefix.."smoke",v.Name,color)
						server.Admin.RunCommand(server.Settings.Prefix.."spin",v.Name)
						repeat hum.PlatformStand=true wait() until not hum or hum==nil or hum.Parent==nil
					end)
				end
			end
		};
		
		Puke = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"cut";"stab";"shank";"bleed";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) bleed";
			Fun = true;
			AdminLevel = "FunMod";
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
		
		PlayerPoints = {
			Prefix = server.Settings.Prefix;
			Commands = {"ppoints";"playerpoints";"getpoints";};
			Args = {};
			Hidden = false;
			Description = "Shows you the number of player points left in the game";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				server.Functions.Hint('Available Player Points: '..service.PointsService:GetAwardablePoints(),{plr})
			end
		};
		
		GivePlayerPoints = {
			Prefix = server.Settings.Prefix;
			Commands = {"giveppoints";"giveplayerpoints";"sendplayerpoints";};
			Args = {"player";"amount";};
			Hidden = false;
			Description = "Lets you give <player> <amount> player points";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local ran,failed = ypcall(function() service.PointsService:AwardPoints(v.userId,tonumber(args[2])) end)
					if ran and service.PointsService:GetAwardablePoints()>=tonumber(args[2]) then
						server.Functions.Hint('Gave '..args[2]..' points to '..v.Name,{plr})
					elseif service.PointsService:GetAwardablePoints()<tonumber(args[2]) then
						server.Functions.Hint("You don't have "..args[2]..' points to give to '..v.Name,{plr})
					else
						server.Functions.Hint("(Unknown Error) Failed to give "..args[2]..' points to '..v.Name,{plr})
					end
					server.Functions.Hint('Available Player Points: '..service.PointsService:GetAwardablePoints(),{plr})
				end
			end
		};
		
		Poison = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"taudio";"localsound";"localaudio";"lsound";"laudio";};
			Args = {"player";"audioId";};
			Description = "Lets you play an audio on the player's client";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if not tonumber(args[2]) then error(args[1].." is not a valid ID") return end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.Send(v,"Function","PlayAudio",args[2])
				end
			end
		};
		
		CharacterAudio = {
			Prefix = server.Settings.Prefix;
			Commands = {"charaudio", "charactermusic", "charmusic"};
			Args = {"player", "audioId"};
			Description = "Lets you place an audio in the target's character";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				assert(args[1] and args[2] and tonumber(args[2]), "Argument missing or invalid")
				local audio = service.New("Sound", {
					Looped = true;
					SoundId = "rbxassetid://"..args[2];
				})
				
				for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
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
			Prefix = server.Settings.Prefix;
			Commands = {"uncharaudio", "uncharactermusic", "uncharmusic"};
			Args = {"player"};
			Description = "Removes audio placed into character via :charaudio command";
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
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
			Prefix = server.Settings.Prefix;
			Commands = {"pitch";};
			Args = {"number";};
			Description = "Change the pitch of the currently playing song";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local pitch = args[1]
				for i,v in pairs(service.Workspace:children()) do 
					if v.Name=="ADONIS_SOUND" then 
						v.Pitch = pitch 
					end 
				end
			end
		};
		
		Volume = {
			Prefix = server.Settings.Prefix;
			Commands = {"volume"};
			Args = {"number"};
			Description = "Change the volume of the currently playing song";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local volume = tonumber(args[1])
				assert(volume, "Volume must be a valid number")
				for i,v in pairs(service.Workspace:children()) do 
					if v.Name=="ADONIS_SOUND" then 
						v.Volume = volume
					end 
				end
			end
		};
		
		Shuffle = {
			Prefix = server.Settings.Prefix;
			Commands = {"shuffle"};
			Args = {"songID1,songID2,songID3,etc"};
			Hidden = false;
			Description = "Play a list of songs automatically; Stop with :shuffle off";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				service.StopLoop("MusicShuffle")
				server.Admin.RunCommand(server.Settings.Prefix.."stopmusic")
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
			Prefix = server.Settings.Prefix;
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
					s.Name = "ADONIS_SOUND"
					s.Parent = service.Workspace
					s.SoundId = "http://www.roblox.com/asset/?id=" .. id 
					s.Volume = volume 
					s.Pitch = pitch 
					s.Looped = looped
					s.Archivable = false
					wait(0.5)
					s:Play()
					if server.Settings.SongHint then
						server.Functions.Hint(name..' ('..id..')',service.Players:GetChildren())
					end
				end
			end
		};
		
		StopMusic = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"musiclist";"listmusic";"songs";};
			Args = {};
			Hidden = false;
			Description = "Shows you the script's available music list";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local listforclient={}
				for i, v in pairs(server.Variables.MusicList) do 
					table.insert(listforclient,{Text=v.Name,Desc=v.ID})
				end
				for i, v in pairs(server.HTTP.Trello.Music) do 
					table.insert(listforclient,{Text=v.Name,Desc=v.ID})
				end
				server.Remote.MakeGui(plr,"List",{Title = "Music List", Table = listforclient})
			end
		};
		
		Stickify = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"lightning";"smite";};
			Args = {"player";};
			Hidden = false;
			Description = "Zeus strikes down the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						server.Admin.RunCommand(server.Settings.Prefix.."freeze",v.Name)
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
			Prefix = server.Settings.Prefix;
			Commands = {"fly";"flight";};
			Args = {"player", "speed"};
			Hidden = false;
			Description = "Lets the target player(s) fly";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local speed = tonumber(args[2]) or 2
				local scr = server.Deps.Assets.Fly:Clone()
				local sVal = service.New("NumberValue", {
					Name = "Speed";
					Value = speed;
					Parent = scr;
				})
				
				scr.Name = "ADONIS_FLIGHT"
				
				for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
					local part = v.Character:FindFirstChild("HumanoidRootPart")
					if part then
						local new = scr:Clone()
						local keepAlive = service.New("BoolValue")
						local oldk = part:FindFirstChild("ADONIS_FLIGHT_ALIVE")
						local olds = part:FindFirstChild("ADONIS_FLIGHT")
						if oldk then oldk:Destroy() wait(1) end
						if olds then olds:Destroy() end
						keepAlive.Name = "ADONIS_FLIGHT_ALIVE"
						keepAlive.Parent = part
						new.Parent = part
						new.Disabled = false
					end
				end
			end
		};
		
		UnFly = {
			Prefix = server.Settings.Prefix;
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
						local oldk = part:FindFirstChild("ADONIS_FLIGHT_ALIVE")
						local olds = part:FindFirstChild("ADONIS_FLIGHT")
						if oldk then oldk:Destroy() wait(1) end
						if olds then olds:Destroy() end
					end
				end
			end
		};
		
		Disco = {
			Prefix = server.Settings.Prefix;
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
					server.Functions.SetLighting("Ambient",color)
					server.Functions.SetLighting("OutdoorAmbient",color)
					server.Functions.SetLighting("FogColor",color)
				end)
			end
		};
		
		Spin = {
			Prefix = server.Settings.Prefix;
			Commands = {"spin";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) spin";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = server.Deps.Assets.Spinner:Clone()
				scr.Name = "SPINNER"
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for i,v in pairs(v.Character.HumanoidRootPart:children()) do 
							if v.Name == "SPINNER" then 
								v:Destroy() 
							end 
						end
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end
			end
		};
		
		UnSpin = {
			Prefix = server.Settings.Prefix;
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
							if q.Name == "SPINNER" then 
								q:Destroy() 
							end 
						end
					end
				end
			end
		};
		
		Dog = {
			Prefix = server.Settings.Prefix;
			Commands = {"dog";"dogify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a dog";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v and v.Character and v.Character:findFirstChild("HumanoidRootPart") then
							if v.Character:findFirstChild("Shirt") then 
								v.Character.Shirt.Parent = v.Character.HumanoidRootPart 
							end
							if v.Character:findFirstChild("Pants") then 
								v.Character.Pants.Parent = v.Character.HumanoidRootPart 
							end
							v.Character.HumanoidRootPart.Transparency = 1
							v.Character.HumanoidRootPart.Neck.C0 = CFrame.new(0,-.5,-2) * CFrame.Angles(math.rad(90),math.rad(180),0)
							v.Character.HumanoidRootPart["Right Shoulder"].C0 = CFrame.new(.5,-1.5,-1.5) * CFrame.Angles(0,math.rad(90),0)
							v.Character.HumanoidRootPart["Left Shoulder"].C0 = CFrame.new(-.5,-1.5,-1.5) * CFrame.Angles(0,math.rad(-90),0)
							v.Character.HumanoidRootPart["Right Hip"].C0 = CFrame.new(1.5,-1,1.5) * CFrame.Angles(0,math.rad(90),0)
							v.Character.HumanoidRootPart["Left Hip"].C0 = CFrame.new(-1.5,-1,1.5) * CFrame.Angles(0,math.rad(-90),0)
							local new = service.New("Seat", v.Character) 
							new.Name = "FAKETORSO" 
							new.formFactor = "Symmetric" 
							new.TopSurface = 0 
							new.BottomSurface = 0 
							new.Size = Vector3.new(3,1,4)
							new.CFrame = v.Character.HumanoidRootPart.CFrame
							local bf = service.New("BodyForce", new) 
							bf.force = Vector3.new(0,new:GetMass()*196.25,0)
							local weld = service.New("Weld", v.Character.HumanoidRootPart) 
							weld.Part0 = v.Character.HumanoidRootPart 
							weld.Part1 = new 
							weld.C0 = CFrame.new(0,-.5,0)
							for a, part in pairs(v.Character:children()) do 
								if part:IsA("BasePart") then 
									part.BrickColor = BrickColor.new("Brown") 
								elseif part:findFirstChild("NameTag") then 
									part.Head.BrickColor = BrickColor.new("Brown") 
								end 
							end
						end
					end)
				end
			end
		};
		
		Dogg = {
			Prefix = server.Settings.Prefix;
			Commands = {"dogg";"snoop";"snoopify";"dodoubleg";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns the target into the one and only D O Double G";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = server.Deps.Assets.Dogg:Clone()
				
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
					
					server.Admin.RunCommand(server.Settings.Prefix.."removehats",v.Name)
					server.Admin.RunCommand(server.Settings.Prefix.."invisible",v.Name)
					
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
			Prefix = server.Settings.Prefix;
			Commands = {"sp00ky";"spooky";"spookyscaryskeleton";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends shivers down ur spine";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = server.Deps.Assets.Sp00ks:Clone()
				
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
					
					server.Admin.RunCommand(server.Settings.Prefix.."removehats",v.Name)
					server.Admin.RunCommand(server.Settings.Prefix.."invisible",v.Name)
					
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
			Prefix = server.Settings.Prefix;
			Commands = {"k1tty";"cut3";};
			Args = {"player";};
			Hidden = false;
			Description = "2 cute 4 u";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = server.Deps.Assets.Kitty:Clone()
				
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
					
					server.Admin.RunCommand(server.Settings.Prefix.."removehats",v.Name)
					server.Admin.RunCommand(server.Settings.Prefix.."invisible",v.Name)
					
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
			Prefix = server.Settings.Prefix;
			Commands = {"nyan";"p0ptart"};
			Args = {"player";};
			Hidden = false;
			Description = "Poptart kitty";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = server.Deps.Assets.Nyan1:Clone()
				local c2 = server.Deps.Assets.Nyan2:Clone()
				
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
					
					server.Admin.RunCommand(server.Settings.Prefix.."removehats",v.Name)
					server.Admin.RunCommand(server.Settings.Prefix.."invisible",v.Name)
					
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
			Prefix = server.Settings.Prefix;
			Commands = {"fr0g";"fr0ggy";"mlgfr0g";"mlgfrog";};
			Args = {"player";};
			Hidden = false;
			Description = "MLG fr0g";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = server.Deps.Assets.Fr0g:Clone()
				
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
					
					server.Admin.RunCommand(server.Settings.Prefix.."removehats",v.Name)
					server.Admin.RunCommand(server.Settings.Prefix.."invisible",v.Name)
					
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
			Prefix = server.Settings.Prefix;
			Commands = {"sh1a";"lab00f";"sh1alab00f";"shia"};
			Args = {"player";};
			Hidden = false;
			Description = "Sh1a LaB00f";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = server.Deps.Assets.Shia:Clone()
				
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
					
					server.Admin.RunCommand(server.Settings.Prefix.."removehats",v.Name)
					server.Admin.RunCommand(server.Settings.Prefix.."invisible",v.Name)
					
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
			Prefix = server.Settings.Prefix;
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
				
				for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					for k,p in next,char:GetChildren() do
						if p:IsA("BasePart") then
							server.Functions.RemoveParticle(p,"ADONIS_CMD_TRAIL")
							server.Functions.NewParticle(p,"Trail",{
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
			Prefix = server.Settings.Prefix;
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
						server.Functions.RemoveParticle(torso, "PARTICLE")
					end
				end
			end
		};
		
		Particle = {
			Prefix = server.Settings.Prefix;
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
						server.Functions.NewParticle(torso,"ParticleEmitter",{
							Name = "PARTICLE";
							Texture = 'rbxassetid://'..args[2]; --server.Functions.GetTexture(args[1]); 
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
			Prefix = server.Settings.Prefix;
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
				
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					sizePlayer(v)
				end
			end
		};
		
		OldFlatten = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
						if torso and torso.Parent and not p:IsDescendantOf(v.Character) then
							server.Functions.MakeWeld(torso,p)
						elseif not torso or not torso.Parent then 
							event:disconnect()
						end
					end)
				end
			end
		};
		
		Break = {
			Prefix = server.Settings.Prefix;
			Commands = {"break";};
			Args = {"player";"optional num";};
			Hidden = false;
			Description = "Break the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
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
					end)
				end
			end
		};
		
		Skeleton = {
			Prefix = server.Settings.Prefix;
			Commands = {"skeleton";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a skeleton";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(v.Character:children()) do
						if m:IsA("CharacterMesh") or m:IsA("Accoutrement") then
							m:Destroy()
						end
					end
					service.Insert(36781518).Parent = v.Character
					service.Insert(36781481).Parent = v.Character
					service.Insert(36781407).Parent = v.Character
					service.Insert(36781447).Parent = v.Character
					service.Insert(36781360).Parent = v.Character
					service.Insert(36883367).Parent = v.Character
				end
			end
		};
		
		Creeper = {
			Prefix = server.Settings.Prefix;
			Commands = {"creeper";"creeperify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a creeper";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						if v.Character:findFirstChild("Shirt") then v.Character.Shirt.Parent = v.Character.HumanoidRootPart end
						if v.Character:findFirstChild("Pants") then v.Character.Pants.Parent = v.Character.HumanoidRootPart end
						v.Character.HumanoidRootPart.Transparency = 0
						v.Character.HumanoidRootPart.Neck.C0 = CFrame.new(0,1,0) * CFrame.Angles(math.rad(90),math.rad(180),0)
						v.Character.HumanoidRootPart["Right Shoulder"].C0 = CFrame.new(0,-1.5,-.5) * CFrame.Angles(0,math.rad(90),0)
						v.Character.HumanoidRootPart["Left Shoulder"].C0 = CFrame.new(0,-1.5,-.5) * CFrame.Angles(0,math.rad(-90),0)
						v.Character.HumanoidRootPart["Right Hip"].C0 = CFrame.new(0,-1,.5) * CFrame.Angles(0,math.rad(90),0)
						v.Character.HumanoidRootPart["Left Hip"].C0 = CFrame.new(0,-1,.5) * CFrame.Angles(0,math.rad(-90),0)
						for a, part in pairs(v.Character:children()) do if part:IsA("BasePart") then part.BrickColor = BrickColor.new("Bright green") if part.Name == "FAKETORSO" then part:Destroy() end elseif part:findFirstChild("NameTag") then part.Head.BrickColor = BrickColor.new("Bright green") end end
					end
				end
			end
		};
		
		BigHead = {
			Prefix = server.Settings.Prefix;
			Commands = {"bighead";};
			Args = {"player";};
			Hidden = false;
			Description = "Give the target player(s) a larger ego";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						v.Character.Head.Mesh.Scale = Vector3.new(3,3,3) 
						v.Character.HumanoidRootPart.Neck.C0 = CFrame.new(0,1.9,0) * CFrame.Angles(math.rad(90),math.rad(180),0) 
					end
				end
			end
		};
		
		Resize = {
			Prefix = server.Settings.Prefix;
			Commands = {"resize";"size";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Resize the target player(s)'s character by <number>";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if tonumber(args[2])>50 then 
					args[2] = 50 
				end
				
				local num = tonumber(args[2])	
				
				local function sizePlayer(p)
					local char = p.Character
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
				end
				
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					sizePlayer(v)
				end
			end
		};
		
		SmallHead = {
			Prefix = server.Settings.Prefix;
			Commands = {"smallhead";"minihead";};
			Args = {"player";};
			Hidden = false;
			Description = "Give the target player(s) a small head";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then 
						v.Character.Head.Mesh.Scale = Vector3.new(.75,.75,.75)
						v.Character.HumanoidRootPart.Neck.C0 = CFrame.new(0,.8,0) * CFrame.Angles(math.rad(90),math.rad(180),0) 
					end
				end
			end
		};
		
		Fling = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"sfling";"tothemoon";"superfling";};
			Args = {"player";"optional strength";};
			Hidden = false;
			Description = "Super fling the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local strength = tonumber(args[2]) or 5e6
				local scr = server.Deps.Assets.Sfling:Clone()
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
			Prefix = server.Settings.Prefix;
			Commands = {"seizure";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character spazz out on the floor";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = server.Deps.Assets.Seize
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
		
		Name = {
			Prefix = server.Settings.Prefix;
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
						wait(0.5)
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
				
				local part = service.Insert(args[2])
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(v.Character:children()) do 
						if m:IsA('CharacterMesh') and m.BodyPart=='RightLeg' then 
							m:Destroy() 
						end
					end
					
					part.Parent=v.Character
				end
			end
		};
		
		LeftLeg = {
			Prefix = server.Settings.Prefix;
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
				
				local part = service.Insert(args[2])
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(v.Character:children()) do 
						if m:IsA('CharacterMesh') and m.BodyPart=='LeftLeg' then 
							m:Destroy() 
						end 
					end
					
					part.Parent = v.Character
				end
			end
		};
		
		RightArm = {
			Prefix = server.Settings.Prefix;
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
				
				local part = service.Insert(args[2])
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(v.Character:children()) do 
						if m:IsA('CharacterMesh') and m.BodyPart=='RightArm' then
							 m:Destroy() 
						end 
					end
					
					part.Parent=v.Character
				end
			end
		};
		
		LeftArm = {
			Prefix = server.Settings.Prefix;
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
				
				local part = service.Insert(args[2])
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(v.Character:children()) do 
						if m:IsA('CharacterMesh') and m.BodyPart=='LeftArm' then 
							m:Destroy() 
						end 
					end
					
					part.Parent = v.Character
				end
			end
		};
		
		TorsoPackage = {
			Prefix = server.Settings.Prefix;
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
				
				local part = service.Insert(args[2])
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(v.Character:children()) do 
						if m:IsA('CharacterMesh') and m.BodyPart=='HumanoidRootPart' then 
							m:Destroy() 
						end 
					end
					
					part.Parent = v.Character
				end
			end
		};
		
		RemovePackage = {
			Prefix = server.Settings.Prefix;
			Commands = {"removepackage";"nopackage";"rpackage"};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the target player(s)'s Package";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(v.Character:children()) do
						if m:IsA("CharacterMesh") then 
							m:Destroy() 
						end
					end
				end
			end
		};
		
		GivePackage = {
			Prefix = server.Settings.Prefix;
			Commands = {"package", "givepackage", "setpackage"};
			Args = {"player", "id"};
			Hidden = false;
			Description = "Gives the target player(s) the desired package";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2] and tonumber(args[2]), "Argument missing or invalid ID")
				
				local parts = {}
				local assets = game.AssetService:GetAssetIdsForPackage(tonumber(args[2])) 
				local potProps = {
					BrickColor = true;
					Color = true;
					Material = true;
					MeshId = true;
					Reflectance = true;
					TextureID = true;
					Transparency = true;
					Size = true;
				}
				
				for i,v in next,assets do 
					table.insert(parts,service.Insert(v))
				end
				
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(v.Character:children()) do
						if m:IsA("CharacterMesh") then 
							m:Destroy() 
						end
					end
					
					
					for i,part in next,parts do
						if part:IsA("Folder") and part.Name == "R15" then
							for i,found in next,part:GetChildren() do
								local temp = v.Character:FindFirstChild(found.Name)
								if temp and temp:IsA(found.ClassName) then
									for prop,use in next,potProps do
										temp[prop] = found[prop]
									end
								end
							end
						else
							part:Clone().Parent = v.Character
						end
					end
				end
			end
		};
		
		Char = {
			Prefix = server.Settings.Prefix;
			Commands = {"char";"character";"appearance";};
			Args = {"player";"ID or player";};
			Hidden = false;
			Description = "Changes the target player(s)'s character appearence to <ID/Name>. If argument 2 is a number it will auto assume it's an ID.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if tonumber(args[2]) then
						v.CharacterAppearanceId = tonumber(args[2])
						server.Admin.RunCommand(server.Settings.Prefix.."refresh",v.Name)
					else
						if not service.Players:FindFirstChild(args[2]) then
							local userid=args[2]
							Pcall(function() userid=service.Players:GetUserIdFromNameAsync(args[2]) end)
							v.CharacterAppearanceId = userid
							server.Admin.RunCommand(server.Settings.Prefix.."refresh",v.Name)
						else
							for k,m in pairs(service.GetPlayers(plr,args[2])) do
								v.CharacterAppearanceId = m.userId
								server.Admin.RunCommand(server.Settings.Prefix.."refresh",v.Name)
							end
						end
					end
				end
			end
		};
		
		UnChar = {
			Prefix = server.Settings.Prefix;
			Commands = {"unchar";"uncharacter";"fixappearance";};
			Args = {"player";};
			Hidden = false;
			Description = "Put the target player(s)'s character appearence back to normal";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v and v.Character then 
						v.CharacterAppearanceId = v.userId
						v:LoadCharacter()
					end
				end
			end
		};
		
		Infect = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"rainbowify";"rainbow";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character flash random colors";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = server.Core.NewScript("LocalScript",[[
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
			Prefix = server.Settings.Prefix;
			Commands = {"noobify";"noob";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) look like a noob";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
							if p:IsA("Shirt") or p:IsA("Pants") or p:IsA("CharacterMesh") or p:IsA("Accoutrement") then
								p:Destroy()
							elseif p.Name=="Left Arm" or p.Name=="Right Arm" or p.Name=="Head" then
								p.BrickColor=BrickColor.new("Bright yellow")
							elseif p.Name=="Left Leg" or p.Name=="Right Leg" then
								p.BrickColor=BrickColor.new("Bright green")
							elseif p.Name=="HumanoidRootPart" then
								p.BrickColor=BrickColor.new("Bright blue")
							end
						end
					end
				end
			end
		};
		
		Color = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"ghostify";"ghost";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a ghost";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then 
						server.Admin.RunCommand(server.Settings.Prefix.."noclip",v.Name)
						
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"lowres","pixelrender","pixel","pixelize"};
			Args = {"player","pixelSize","renderDist"};
			Hidden = false;
			Description = "Pixelizes the player's view";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local size = tonumber(args[2]) or 19
				local dist = tonumber(args[3]) or 100
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.MakeGui(v,"Effect",{
						Mode = "Pixelize";
						Resolution = size;
						Distance = dist;
					})
				end
			end
		};
		
		Spook = {
			Prefix = server.Settings.Prefix;
			Commands = {"spook";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s)'s screen 2spooky4them";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.MakeGui(v,"Effect",{Mode = "Spooky"})
				end
			end
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
				server.Remote.MakeGui(plr,"Effect",{Mode = "lifeoftheparty"})
			end
		};
		
		Blind = {
			Prefix = server.Settings.Prefix;
			Commands = {"blind";};
			Args = {"player";};
			Hidden = false;
			Description = "Blinds the target player(s)";
			Fun = true;
			AdminLevel = "FunMod";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.MakeGui(v,"Effect",{Mode = "Blind"})
				end
			end
		};
		
		ScreenImage = {
			Prefix = server.Settings.Prefix;
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
					server.Remote.MakeGui(v,"Effect",{Mode = "ScreenImage",Image = args[2]})
				end
			end
		};
		
		UnEffect = {
			Prefix = server.Settings.Prefix;
			Commands = {"uneffect";"unimage";"uneffectgui";"unspook";"unblind";"unstrobe";"untrippy";"unpixelize","unlowres","unpixel","undance";"unflashify";"unrainbowify";"guifix";"fixgui";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes any effect GUIs on the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.MakeGui(v,"Effect",{Mode = "Off"})
				end
			end
		};
		
		LoopHeal = {
			Prefix = server.Settings.Prefix;
			Commands = {"loopheal";};
			Args = {"player";};
			Hidden = false;
			Description = "Loop heals the target player(s)";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StartLoop(v.userId.."LOOPHEAL",1,function()
						server.Admin.RunCommand(server.Settings.Prefix.."heal",v.Name)
					end)
				end
			end
		};
		
		UnLoopHeal = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"loopfling";};
			Args = {"player";};
			Hidden = false;
			Description = "Loop flings the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StartLoop(v.userId.."LOOPFLING",2,function()
						server.Admin.RunCommand(server.Settings.Prefix.."fling",v.Name)
					end)
				end
			end
		};
		
		UnLoopFling = {
			Prefix = server.Settings.Prefix;
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
				server.Remote.MakeGui(plr,"UserPanel",{Tab = "Settings"})
			end
		};
		
		RestoreMap = {
			Prefix = server.Settings.Prefix;
			Commands = {"restoremap";"maprestore";"rmap";};
			Args = {};
			Hidden = false;
			Description = "Restore the map to the the way it was the last time it was backed up";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				server.Functions.Hint('Restoring Map...',service.Players:children())
				
				for i,v in pairs(service.Workspace:children()) do
					if v~=script and v.Archivable==true and not v:IsA('Terrain') then
						ypcall(function() v:Destroy() end)
						wait()
					end
				end
				
				local new = server.Variables.MapBackup:Clone()
				new:MakeJoints()
				new.Parent = service.Workspace
				new:MakeJoints()
				
				for i,v in pairs(new:GetChildren()) do
					v.Parent = service.Workspace
					pcall(function() v:MakeJoints() end)
				end
				
				new:Destroy()
				
				server.Admin.RunCommand(server.Settings.Prefix.."respawn","@everyone")
				server.Functions.Hint('Map Restore Complete.',service.Players:GetChildren())
			end
		};
		
		BackupMap = {
			Prefix = server.Settings.Prefix;
			Commands = {"backupmap";"mapbackup";"bmap";};
			Args = {};
			Hidden = false;
			Description = "Changes the backup for the restore map command to the map's current state";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if plr then
					server.Functions.Hint('Updating Map Backup...',{plr})
				else
					--warn("Performing Map Backup...")
				end
				
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
				
				server.Variables.MapBackup = tempmodel:Clone()
				tempmodel:Destroy()
				
				if plr then
					server.Functions.Hint('Backup Complete',{plr})
				else
					--warn("Backup Complete")
				end
				
				server.Logs.AddLog(server.Logs.Script,{
					Text = "Backup Complete";
					Desc = "Map was successfully backed up";
				})
			end
		};
		
		Explore = {
			Prefix = server.Settings.Prefix;
			Commands = {"explore";"explorer";};
			Args = {};
			Hidden = false;
			Description = "Lets you explore the game, kinda like a file browser";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				server.Remote.MakeGui(plr,"Explorer")
				--error("Disabled until I get around to finishing the explorer revamp; Use :dex for now")
			end
		};
		
		DexExplore = {
			Prefix = server.Settings.Prefix;
			Commands = {"dex";"dexexplorer";"dexexplorer"};
			Args = {};
			Description = "Lets you explore the game using Dex [Credit to Raspberry Pi/Raspy_Pi/raspymgx/OpenOffset(?)][Useless buttons disabled]";
			AdminLevel = "Owners";
			Function = function(plr,args)
				server.Remote.MakeLocal(plr,server.Deps.Assets.Dex_Explorer:Clone(),"PlayerGui")
			end
		};
		
		Tornado = {
			Prefix = server.Settings.Prefix;
			Commands = {"tornado";"twister";};
			Args = {"player";"optional time";};
			Description = "Makes a tornado on the target player(s)";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local p=service.New('Part',service.Workspace)
					table.insert(server.Variables.Objects,p)
					p.Transparency=1
					p.CFrame=v.Character.HumanoidRootPart.CFrame+Vector3.new(0,-3,0)
					p.Size=Vector3.new(0.2,0.2,0.2)
					p.Anchored=true
					p.CanCollide=false
					p.Archivable=false
					--local tornado=deps.Tornado:clone()
					--tornado.Parent=p
					--tornado.Disabled=false
					local cl=server.Core.NewScript('Script',[[
						local Pcall=function(func,...) local function cour(...) coroutine.resume(coroutine.create(func),...) end local ran,error=ypcall(cour,...) if error then print('Error: '..error) end end
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
			Prefix = server.Settings.Prefix;
			Commands = {"nuke";};
			Args = {"player";};
			Description = "Nuke the target player(s)";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				local nukes = {}
				local partsHit = {}
				
				for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
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
						
						table.insert(server.Variables.Objects, p)
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
			Prefix = server.Settings.Prefix;
			Commands = {"stopwildfire", "removewildfire", "unwildfire";};
			Args = {};
			Description = "Stops :wildfire from spreading further";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				server.Variables.WildFire = nil
			end
		};
		
		WildFire = {
			Prefix = server.Settings.Prefix;
			Commands = {"wildfire";};
			Args = {"player";};
			Description = "Starts a fire at the target player(s); Ignores locked parts and parts named 'BasePlate'";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				local finished = false
				local partsHit = {}
				local objs = {}
				
				server.Variables.WildFire = partsHit
				
				function fire(part)
					if finished or not partsHit or not objs then
						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and server.Variables.WildFire ~= partsHit then
						for i,v in next,objs do
							v:Destroy()
						end
						
						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and part:IsA("BasePart") and (not part.Locked or (part.Parent:IsA("Model") and service.Players:GetPlayerFromCharacter(part.Parent))) and part.Name ~= "BasePlate" and not partsHit[part] then
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
				
				for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
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
				
				server.Remote.MakeGui(plr,'List',{
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
					local temp = server.Remote.Get(v,"ClientLog") or {}
					server.Remote.MakeGui(plr,'List',{
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
			Prefix = server.Settings.Prefix;
			Commands = {"replications";"replicators";"replicationlogs";};
			Args = {"autoupdate"};
			Hidden = false;
			Description = "Shows a list of what players are *believed* to have created/destroyed object; Does not always imply exploiting";
			Fun = false;
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(server.Settings.ReplicationLogs,"Replication logs are disabled; Enable them in Settings")
				assert(server.FilteringEnabled == false,"Filtering Enabled; Replication logs disabled (not usable)")
				
				local tab = {}
				local auto
				
				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end
				
				for i,v in pairs(server.Logs.Replications) do
					table.insert(tab,{Text = v.Player.." "..v.Action.." "..v.ClassName,Desc = v.Path})
				end
				
				server.Remote.MakeGui(plr,"List",{
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
			Prefix = server.Settings.Prefix;
			Commands = {"createdparts","networkowners","playerparts"};
			Args = {"autoupdate"};
			Hidden = false;
			Description = "Shows what players created parts in workspace";
			Fun = false;
			Agents = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(server.Settings.NetworkOwners,"NetworkOwner logging is disabled; Enable them in Settings")
				assert(server.FilteringEnabled == false,"Filtering Enabled; NetworkOwner logs disabled (not usable)")
				
				local tab = {}
				local auto
				
				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end
				
				for i,v in pairs(server.Logs.NetworkOwners) do
					table.insert(tab,{Text = tostring(v.Player).." made "..tostring(v.Part),Desc = v.Path})
				end
				
				server.Remote.MakeGui(plr,"List",{
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
				for i,v in pairs(server.Logs.Errors) do
					table.insert(tab,{Time=v.Time;Text=v.Text..": "..tostring(v.Desc),Desc = tostring(v.Desc)})
				end
				server.Remote.MakeGui(plr,"List",{
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
			Prefix = server.Settings.Prefix;
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
				server.Remote.MakeGui(plr,'List',{
					Title = 'Exploit Logs', 
					Tab = server.Logs.Exploit,
					Dots = true; 
					Update = "ExploitLogs",
					AutoUpdate = auto,
					Sanitize = true;
					Stacking = true;
				})
			end
		};
		
		JoinLogs = {
			Prefix = server.Settings.Prefix;
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
				server.Remote.MakeGui(plr,'List',{
					Title = 'Join Logs';
					Tab = server.Logs.Joins;
					Dots = true; 
					Update = "JoinLogs";
					AutoUpdate = auto;
				})
			end
		};
		
		ChatLogs = {
			Prefix = server.Settings.Prefix;
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
				
				server.Remote.MakeGui(plr,'List',{
					Title = 'Chat Logs';
					Tab = server.Logs.Chats; 
					Dots = true;
					Update = "ChatLogs";
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = true;
				})
			end
		};
		
		RemoteLogs = {
			Prefix = server.Settings.Prefix;
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
				server.Remote.MakeGui(plr,"List",{
					Title = "Remote Logs";
					Table = server.Logs.RemoteFires;
					Dots = true;
					Update = "RemoteLogs";
					AutoUpdate = auto;
					Sanitize = true;
					Stacking = true;
				})
			end
		};
		
		ScriptLogs = {
			Prefix = server.Settings.Prefix;
			Commands = {"scriptlogs","scriptlog","adminlogs";"adminlog";"scriptlogs";};
			Args = {"autoupdate"};
			Description = "View the admin logs for the server";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local auto
				if args[1] and type(args[1]) == "string" and (args[1]:lower() == "yes" or args[1]:lower() == "true") then
					auto = 1
				end
				server.Remote.MakeGui(plr,"List",{
					Title = "Script Logs";
					Table = server.Logs.Script;
					Dots = true;
					Update = "ScriptLogs";
					AutoUpdate = auto;
					Santize = true;
					Stacking = true;
				})
			end
		};
		
		Logs = {
			Prefix = server.Settings.Prefix;
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
				
				for i,m in pairs(server.Logs.Commands) do
					table.insert(temp,{Time = m.Time;Text = m.Text..": "..m.Desc;Desc = m.Desc})
				end
				
				server.Remote.MakeGui(plr,"List",{
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
		
		ShowLogs = {
			Prefix = server.Settings.Prefix;
			Commands = {"showlogs";"showcommandlogs";};
			Args = {"player"};
			Description = "Shows the target player(s) the command logs.";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temp = {}
				for i,m in pairs(server.Logs.Commands) do
					table.insert(temp,{Time = m.Time;Text = m.Text..": "..m.Desc;Desc = m.Desc})
				end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do 
					server.Remote.MakeGui(plr,"List",{Title = "Admin Logs", Table = temp, Dots = true, Update = "CommandLogs"; Sanitize = true})
				end
			end
		};
		
		ScriptBuilder = {
			Prefix = server.Settings.Prefix;
			Commands = {"sb"};
			Args = {"create/remove/edit/close/clear/append/run/stop/list","localscript/script","scriptName","data"};
			Description = "Script Builder; make a script, then edit it and chat it's code or use :sb append <codeHere>";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				local sb = server.Variables.ScriptBuilder[tostring(plr.userId)]
				if not sb then 
					sb = {
						Script = {};
						LocalScript = {};
						Events = {};
					}
					server.Variables.ScriptBuilder[tostring(plr.userId)] = sb
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
					
					local wrapped,scr = server.Core.NewScript(class,code,false,true)
					
					sb[class][name] = {
						Wrapped = wrapped;
						Script = scr;
					}
					
					if args[4] then
						server.Functions.Hint("Created "..class.." "..name.." and appended text",{plr})
					else
						server.Functions.Hint("Created "..class.." "..name,{plr})
					end
				elseif action == "edit" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					if sb[class][name] then
						local scr = sb[class][name].Script
						local tab = server.Core.GetScript(scr)
						if scr and tab then
							sb[class][name].Event = plr.Chatted:connect(function(msg)
								if msg:sub(1,#(server.Settings.Prefix.."sb")) == server.Settings.Prefix.."sb" then
								
								else
									tab.Source = tab.Source.."\n"..msg
									server.Functions.Hint("Appended message to "..class.." "..name,{plr})
								end
							end)
							server.Functions.Hint("Now editing "..class.." "..name.."; Chats will be appended",{plr})
						end
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "close" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					local scr = sb[class][name].Script
					local tab = server.Core.GetScript(scr)
					if sb[class][name] then
						if sb[class][name].Event then
							sb[class][name].Event:disconnect()
							server.Functions.Hint("No longer editing "..class.." "..name,{plr})
						end
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "clear" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					local scr = sb[class][name].Script
					local tab = server.Core.GetScript(scr)
					if scr and tab then
						tab.Source = " "
						server.Functions.Hint("Cleared "..class.." "..name,{plr})
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
						local tab = server.Core.GetScript(scr)
						if scr and tab then
							tab.Source = tab.Source.."\n"..args[4]
							server.Functions.Hint("Appended message to "..class.." "..name,{plr})
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
						server.Functions.Hint("Running "..class.." "..name,{plr})
					else
						error(class.." "..name.." not found!")
					end
				elseif action == "stop" then
					assert(args[1] and args[2] and args[3],"Argument missing or nil")
					if sb[class][name] then
						sb[class][name].Script.Disabled = true
						server.Functions.Hint("Stopped "..class.." "..name,{plr})
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
					
					server.Remote.MakeGui(plr,"List",{Title = "SB Scripts",Table = tab})
				end
			end
		};
		
		MakeScript = {
			Prefix = server.Settings.Prefix;
			Commands = {"s";"scr";"script";"makescript"};
			Args = {"code";};
			Description = "Lets you run code on the server";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				local cl = server.Core.NewScript('Script',args[1])
				cl.Parent = service.ServerScriptService
				cl.Disabled = false	
				server.Functions.Hint("Ran Script",{plr})
			end
		};
		
		MakeLocalScript = {
			Prefix = server.Settings.Prefix;
			Commands = {"ls";"lscr";"localscript";};
			Args = {"code";};
			Description = "Lets you run code as a local script";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				local cl = server.Core.NewScript('LocalScript',"script.Parent = game:GetService('Players').LocalPlayer.PlayerScripts; "..args[1])
				cl.Parent = plr.Backpack
				cl.Disabled = false	
				server.Functions.Hint("Ran LocalScript",{plr})
			end
		};
		
		LoadLocalScript = {
			Prefix = server.Settings.Prefix;
			Commands = {"cs";"cscr";"clientscript";};
			Args = {"player";"code";};
			Description = "Lets you run a localscript on the target player(s)";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				local new = server.Core.NewScript('LocalScript',"script.Parent = game:GetService('Players').LocalPlayer.PlayerScripts; "..args[2])
				for i,v in next,service.GetPlayers(plr,args[1]) do
					local cl = new:Clone()
					cl.Parent = v.Backpack
					cl.Disabled = false	
					server.Functions.Hint("Ran LocalScript on "..v.Name,{plr})
				end
			end
		};
		
		Mute = {
			Prefix = server.Settings.Prefix;
			Commands = {"mute";"silence";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes it so the target player(s) can't talk";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then  
						server.Remote.LoadCode(v,[[service.StarterGui:SetCoreGuiEnabled("Chat",false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
						local check = true 
						for k,m in pairs(server.Settings.Muted) do 
							if server.Admin.DoCheck(v,m) then 
								check = false 
							end 
						end
						
						if check then 
							table.insert(server.Settings.Muted,v.Name..':'..v.userId) 
						end
					end
				end
			end
		};
		
		UnMute = {
			Prefix = server.Settings.Prefix;
			Commands = {"unmute";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes it so the target player(s) can talk again. No effect if on Trello mute list.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,m in pairs(server.Settings.Muted) do
						if server.Admin.DoCheck(v,m) then
							table.remove(server.Settings.Muted,k) 
							server.Remote.LoadCode(v,[[if not client.Variables.CustomChat then service.StarterGui:SetCoreGuiEnabled("Chat",true) client.Variables.ChatEnabled = false end client.Variables.Muted = true]])
						end
					end
				end
			end
		};
		
		MuteList = {
			Prefix = server.Settings.Prefix;
			Commands = {"mutelist";"mutes";"muted";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of currently muted players, like a ban list, but for mutes instead of bans";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local list = {}
				for i,v in pairs(server.Settings.Muted) do
					table.insert(list,v)
				end
				server.Remote.MakeGui(plr,"Lis",{Title = "Mute List",Table = list})
			end
		};
		
		Note = {
			Prefix = server.Settings.Prefix;
			Commands = {"note";"writenote";"makenote";};
			Args = {"player";"note";};
			Filter = true;
			Description = "Makes a note on the target player(s) that says <note>";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = server.Core.GetPlayer(v)
					if not PlayerData.AdminNotes then PlayerData.AdminNotes={} end
					table.insert(PlayerData.AdminNotes,args[2])
					server.Functions.Hint('Added '..v.Name..' Note '..args[2],{plr})
					server.Core.SavePlayer(v,PlayerData)
				end
			end
		};
		
		DeleteNote = {
			Prefix = server.Settings.Prefix;
			Commands = {"removenote";"remnote","deletenote"};
			Args = {"player";"note";};
			Description = "Removes a note on the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = server.Core.GetPlayer(v)
					if PlayerData.AdminNotes then
						if args[2]:lower() == "all" then
							PlayerData.AdminNotes={}
						else
							for k,m in pairs(PlayerData.AdminNotes) do
								if m:lower():sub(1,#args[2]) == args[2]:lower() then
									server.Functions.Hint('Removed '..v.Name..' Note '..m,{plr})
									table.remove(PlayerData.AdminNotes,k)
								end
							end
						end
						server.Core.SavePlayer(v,PlayerData)--v:SaveInstance("Admin Notes", notes)
					end
				end
			end
		};
		
		ShowNotes = {
			Prefix = server.Settings.Prefix;
			Commands = {"notes";"viewnotes";};
			Args = {"player";};
			Description = "Views notes on the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = server.Core.GetPlayer(v)
					local notes = PlayerData.AdminNotes
					if not notes then 
						server.Functions.Hint('No notes on '..v.Name,{plr}) 
						return 
					end
					server.Remote.MakeGui(plr,'List',{Title = v.Name,Table = notes})
				end
			end
		};
		
		LoopKill = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"lag";"fpslag";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s)'s FPS drop";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then
						server.Remote.Send(v,"Function","SetFPS",5)
					end
				end
			end
		};
		
		UnLag = {
			Prefix = server.Settings.Prefix;
			Commands = {"unlag";"unfpslag";};
			Args = {"player";};
			Hidden = false;
			Description = "Un-Lag";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.Send(v,"Function","RestoreFPS")
				end
			end
		};
		
		--[[FunBox = { -- Never forget :(((
			Prefix = server.Settings.Prefix;
			Commands = {"funbox";"trollbox";"trololo";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends players to The Fun Box. Please don't use this on people with epilepsy.";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local funid={
					241559484,
					266815338,
				}--168920853 RIP
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then
						service.TeleportService:Teleport(funid[math.random(1,#funid)],v)
					end
				end
			end
		};--]]
		
		Forest = {
			Prefix = server.Settings.Prefix;
			Commands = {"forest";"sendtotheforest";"intothewoods";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends player to The Forest for a time out";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then
						service.TeleportService:Teleport(209424751,v)
					end
				end
			end
		};
		
		Maze = {
			Prefix = server.Settings.Prefix;
			Commands = {"maze";"sendtothemaze";"mazerunner";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends player to The Maze for a time out";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if server.Admin.GetLevel(plr)>server.Admin.GetLevel(v) then
						service.TeleportService:Teleport(280846668,v)
					end
				end
			end
		};
		
		
		Freecam = {
			Prefix = server.Settings.Prefix;
			Commands = {"freecam";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes it so the target player(s)'s cam can move around freely";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					--[[v.Character.Archivable=true
					local newchar=v.Character:clone()
					newchar.Parent=server.Storage
					v.Character=nil--]]
					server.Remote.Send(v,'Function','setCamProperty','CameraType','Custom')
					server.Remote.Send(v,'Function','setCamProperty','CameraSubject',service.Workspace)
					v.Character.HumanoidRootPart.Anchored=true
				end
			end
		};
		
		UnFreecam = {
			Prefix = server.Settings.Prefix;
			Commands = {"unfreecam";};
			Args = {"player";};
			Hidden = false;
			Description = "UnFreecam";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					server.Remote.Send(v,'Function','setCamProperty','CameraType','Custom')
					server.Remote.Send(v,'Function','setCamProperty','CameraSubject',v.Character.Humanoid)
					v.Character.HumanoidRootPart.Anchored=false
				end
			end
		};
		
		Nil = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
						local brain = server.Deps.Assets.BotBrain:Clone()
						local event = brain.Event
						local oldAnim = new:FindFirstChild("Animate")
						local isR15 = (hum.RigType == "R15")
						local anim = (isR15 and server.Deps.Assets.R15Animate:Clone()) or server.Deps.Assets.R6Animate:Clone()
						
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
						
						table.insert(server.Variables.Objects,new)
					end
				end
				
				for i,v in pairs(service.GetPlayers(plr,args[1])) do 
					makeBot(v)
				end
			end
		};
		
		--[[
		Bots = {
			Prefix = server.Settings.Prefix;
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
						table.insert(server.Variables.Objects,cl)
						local anim = server.Deps.Assets.Animate:Clone()
						local brain = server.Deps.Assets.BotBrain:Clone()
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
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"quote";"inspiration";"randomquote";};
			Args = {};
			Description = "Shows you a random quote";
			AdminLevel = "Players";
			Function = function(plr,args)
				local quotes = require(server.Deps.Assets.Quotes)
				server.Functions.Message('Random Quote',quotes[math.random(1,#quotes)],{plr})
			end
		};
		
		TextToSpeech = {
			Prefix = server.Settings.Prefix;
			Commands = {"tell";"tts";"texttospeech"};
			Args = {"player";"message";};
			Filter = true;
			Description = "[WIP] Says the text you give it";
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					server.Remote.Send(v,"Function","TextToSpeech",args[2])
				end
			end
		};	
		
		Deadlands = {
			Prefix = server.Settings.Prefix;
			Commands = {"deadlands","farlands","renderingcyanide"};
			Args = {"player","mult"};
			Description = "The edge of ROBLOX math; WARNING CAPES CAN CAUSE LAG";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local dist = 1000000 * (tonumber(args[2]) or 1.5)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							server.Functions.UnCape(v)
							torso.CFrame = CFrame.new(dist, dist+10, dist)
							server.Admin.RunCommand(server.Settings.Prefix.."noclip",v.Name)
						end
					end
				end
			end
		};
		
		UnDeadlands = {
			Prefix = server.Settings.Prefix;
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
							server.Admin.RunCommand(server.Settings.Prefix.."clip",v.Name)
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
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
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
		
		Headlian = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"perms";"permissions";"comperms";};
			Args = {"server.Settings.Prefixcmd";"all/donor/temp/admin/owner/creator";};
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
				elseif args[2]:lower()=='funtemp' or args[2]:lower()=='-1' or args[2]:lower()=="funmod" then
					level="FunMod"
				elseif args[2]:lower()=='funadmin' or args[2]:lower()=='-2' then
					level="FunAdmin"
				elseif args[2]:lower()=='funowner' or args[2]:lower()=='-3' then
					level="FunOwner"
				end
				if level~=nil then
					for i=1,#server.Commands do
						if args[1]:lower()==server.Commands[i].Prefix..server.Commands[i].Cmds[1]:lower() then 	
							server.Commands[i].AdminLevel=level
							server.Functions.Hint("server "..server.Commands[i].Prefix..server.Commands[i].Cmds[1].." permission level to "..level,{plr})
						end
					end
				else
					server.OutputGui(plr,'Command Error:','Invalid Permission')
				end
			end
		};
		
		sh = {
			Prefix = server.Settings.Prefix;
			Commands = {"sh";"systemhint";};
			Args = {"message";};
			Hidden = false;
			Description = "Same as hint but says SYSTEM MESSAGE instead of your name, or whatever system message title is server to...";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				server.Functions.Hint(args[1],service.Players:children())
			end
		};
		
		flock = {
			Prefix = server.Settings.Prefix;
			Commands = {"flock";"flocklock";};
			Args = {"on/off";};
			Hidden = false;
			Description = "Makes it so only the place owner's friends can join";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if args[1]:lower()=='on' then
					server.flock=true 
					server.Functions.Hint("Server is now friends only", service.Players:children()) 
				elseif args[1]:lower()=='off' then
					server.flock = false 
					server.Functions.Hint("Server is no longer friends only", service.Players:children()) 
				end
			end
		};
		
		glock = {
			Prefix = server.Settings.Prefix;
			Commands = {"glock";"grouplock";"grouponlyjoin";};
			Args = {"on/off";};
			Hidden = false;
			Description = "Locks the server, makes it so only people in the group that is server in the group settings can join";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if args[1]:lower()=='on' then
					server['GroupOnlyJoin'] = true 
					server.Functions.Hint("Server is now Group Only.", service.Players:children())
				elseif args[1]:lower()=='off' then 
					server['GroupOnlyJoin'] = false 
					server.Functions.Hint("Server is no longer Group Only", service.Players:children()) 
				end
			end
		};
		
		points = {
			Prefix = server.Settings.Prefix;
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
						server.Functions.Hint(v.Name..' has 0 points.',{plr})
					else
						server.Functions.Hint(v.Name..' has '..points..' points.',{plr})
					end
				end
			end
		};
		
		givepoints = {
			Prefix = server.Settings.Prefix;
			Commands = {"givepoints";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Gives the player <number> points. Not PlayerPoints.";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not tonumber(args[2]) then server.Functions.Hint(args[2]..' is not a valid number.',{plr}) return end	
				local num=tonumber(args[2])
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = DataStore:GetAsync(tostring(v.userId))
					if not PlayerData.AdminPoints then 
						PlayerData.AdminPoints=num
					else
						PlayerData.AdminPoints=PlayerData.AdminPoints+num
					end
					DataStore:SetAsync(tostring(v.userId),PlayerData)
					server.Functions.Hint('Gave '..v.Name..' '..num..' points.',{plr})
				end
			end
		};
		
		takepoints = {
			Prefix = server.Settings.Prefix;
			Commands = {"takepoints";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Takes away <number> points from the player. Not PlayerPoints.";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not tonumber(args[2]) then server.Functions.Hint(args[2]..' is not a valid number.',{plr}) return end	
				local num=tonumber(args[2])
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					local PlayerData = DataStore:GetAsync(tostring(v.userId))
					if not PlayerData.AdminPoints then 
						PlayerData.AdminPoints=-num
					else
						PlayerData.AdminPoints=PlayerData.AdminPoints-num
					end
					DataStore:SetAsync(tostring(v.userId),PlayerData)
					server.Functions.Hint('Took '..num..' points from '..v.Name..'.',{plr})
				end
			end
		};
		
		notalk = {
			Prefix = server.Settings.Prefix;
			Commands = {"notalk";};
			Args = {"player";};
			Hidden = false;
			Description = "Tells the target player(s) they are not allowed to talk if they do and eventually kicks them";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
			for i,v in pairs(service.GetPlayers(plr,args[1])) do
			cPcall(function()
			if not v:FindFirstChild('NoTalk') and not server.Admin.CheckAdmin(v,false) then
				local talky=service.New('IntValue',v)
				talky.Name='NoTalk'
				talky.Value=0
			end
			end)
			end
			end
		};
		
		unnotalk = {
			Prefix = server.Settings.Prefix;
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
			Prefix = server.Settings.Prefix;
			Commands = {"normal";"normalify";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) look normal";
			Fun = true;
			AdminLevel = "FunMod";
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
			for a, sc in pairs(parent:children()) do if sc.Name == server.CodeName.."ify" or sc.Name==server.CodeName..'Glitch' or sc.Name == server.CodeName.."EpixPoison" then sc:Destroy() end end
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
				server.Admin.RunCommand(server.Settings.Prefix..'refresh',v.Name)
			end 
			end
			end
			end)
			end
			end
		};
		
		ko = {
			Prefix = server.Settings.Prefix;
			Commands = {"ko";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Kills the target player(s) <number> times giving you <number> KOs";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
			local num = 500 if num > tonumber(args[2]) then num = tonumber(args[2]) end
			for i, v in pairs(service.GetPlayers(plr,args[1])) do
			if server.CheckTrueOwner(plr) or not server.Admin.CheckAdmin(v, false) then
			local cl=server.LoadScript("Script",[=[
			v=service.Players:FindFirstChild(']=]..v.Name..[=[')
			for n = 1, ]=]..num..[=[]=] do
			wait()
			ypcall(function()
			if v and v.Character and v.Character:findFirstChild("Humanoid") then 
			local val = service.New("ObjectValue", v.Character.Humanoid) val.Value = service.Players:FindFirstChild("]=]..plr.Name..[=[") val.Name = "creator"
			v.Character:BreakJoints() 
			wait()
			v:LoadCharacter()
			end
			end)
			end]=],server.AssignName(),true,service.ServerScriptService)
			cl.Name=server.AssignName()
			cl.Parent=service.ServerScriptService
			cl.Disabled=false
			end
			end
			end
		};
		
		Flashify = {
			Prefix = server.Settings.Prefix;
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
						server.Remote.Send(v,'Function','Effect','flashify')
					end
				end
			end
		};
		
		uncreeper = {
			Prefix = server.Settings.Prefix;
			Commands = {"uncreeper";"uncreeperify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) back to normal";
			Fun = true;
			AdminLevel = "FunMod";
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
			Prefix = server.Settings.Prefix;
			Commands = {"undog";"undogify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn them back to normal";
			Fun = true;
			AdminLevel = "FunMod";
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
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"motd";"messageoftheday";"daymessage";};
			Args = {};
			Hidden = false;
			Description = "Shows you the current message of the day";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				server.PM('Message of the Day',plr,service.MarketPlace:GetProductInfo(server.Functions.MessageOfTheDayID).Description)
			end
		};
			
		version = {
			Prefix = server.Settings.Prefix;
			Commands = {"version";"ver";};
			Args = {};
			Hidden = false;
			Description = "Shows you the admin script's version number";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				server.Functions.Message("Epix Inc. Server Suite", tostring(server.version), true, {plr}) 
			end
		};
		
		ranks = {
			Prefix = server.Settings.Prefix;
			Commands = {"ranks";"adminranks";};
			Args = {};
			Hidden = false;
			Description = "Shows you group ranks that have admin";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temptable={}
				for i,v in pairs(server.Ranks) do
					table.insert(temptable,{Text=v.Group..":"..v.Rank.." - "..v.Type,Desc='Rank: '..v.Rank..' - Type: '..v.Type..' - Group: '..v.Group})
				end
				server.Remote.Send(plr,'Function','ListGui','Ranks',temptable)
			end
		};
		
		votekick = {
			Prefix = server.Settings.PlayerPrefix;
			Commands = {"votekick";"kick";};
			Args = {"player";};
			Hidden = false;
			Description = "Vote to kick a player";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				if server.VoteKick then
					for i,v in pairs(service.GetPlayers(plr,args[1])) do
						if server.Admin.CheckAdmin(v,false) then return end
						if not server.VoteKickVotes[v.Name] then
							server.VoteKickVotes[v.Name]={}
							server.VoteKickVotes[v.Name].Votes=0
							server.VoteKickVotes[v.Name].Players={}
						end
						for k,m in pairs(server.VoteKickVotes[v.Name].Players) do if m==plr.userId then return end end
						server.VoteKickVotes[v.Name].Votes=server.VoteKickVotes[v.Name].Votes+1
						table.insert(server.VoteKickVotes[v.Name].Players,plr.userId)
						if server.VoteKickVotes[v.Name].Votes>=((#service.Players:children()*server.VoteKickPercentage)/100) then
							v:Kick("Players voted to kick you from the game. You have been disconnected by the server.")
							server.VoteKickVotes[v.Name]=nil
						end
					end
				else
					server.Functions.Message("SYSTEM","VoteKick is disabled.",false,{plr})
				end
			end
		};
		
		votekicks = {
			Prefix = server.Settings.Prefix;
			Commands = {"votekicks";};
			Args = {};
			Hidden = false;
			Description = "Shows how many kick votes each player in-game has.";
			Fun = false;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local temp={}
				for i,v in pairs(server.VoteKickVotes) do
					if not service.Players:FindFirstChild(i) then server.VoteKickVotes[i]=nil return end
					if server.Admin.CheckAdmin(service.Players:FindFirstChild(i),false) then server.VoteKickVotes[i]=nil return end
					table.insert(temp,{Text=i..' - '..server.VoteKickVotes[v.Name].Votes,Desc='Player: '..i..' has '..server.VoteKickVotes[v.Name].Votes..' kick vote(s)'})
				end
				server.Remote.Send(plr,'Function','ListGui','Vote Kicks',temp)
			end
		};
	--]]
	};
end