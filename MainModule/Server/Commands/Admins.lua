return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		--[[
		--// Unfortunately not viable
		Reboot = {
			Prefix = ":";
			Commands = {"rebootadonis", "reloadadonis"};
			Args = {};
			Description = "Attempts to force Adonis to reload";
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				local rebootHandler = server.Deps.RebootHandler:Clone();

				if server.Runner then
					rebootHandler.mParent.Value = service.UnWrap(server.ModelParent);
					rebootHandler.Dropper.Value = service.UnWrap(server.Dropper);
					rebootHandler.Runner.Value = service.UnWrap(server.Runner);
					rebootHandler.Model.Value = service.UnWrap(server.Model);
					rebootHandler.Mode.Value = "REBOOT";
					wait()
					rebootHandler.Parent = service.ServerScriptService;
					rebootHandler.Disabled = false;
					wait()
					server.CleanUp();
				else
					error("Unable to reload: Runner missing");
				end
			end;
		};--]]

		SetRank = {
			Prefix = Settings.Prefix;
			Commands = {"setrank", "setadminrank"};
			Args = {"player", "rank"};
			Description = "Sets the target player(s) admin rank; THIS SAVES!";
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				local senderLevel = data.PlayerData.Level;
				local rankName = args[2];
				local newRank = assert(Settings.Ranks[rankName], "Rank not found");
				local newLevel = newRank and newRank.Level;

				assert(newLevel < senderLevel, "Rank level cannot be equal to or greater than your own permission level (".. senderLevel ..")");

				for i,p in pairs(Functions.GetPlayers(plr, args[1], {UseFakePlayer = true;}))do
					local targetLevel = Admin.GetLevel(p);

					assert(targetLevel < senderLevel, "Target player's permission level is greater than or equal to your permission level");

					if targetLevel < senderLevel then
						Admin.AddAdmin(p, rankName)
						Remote.MakeGui(p,"Notification",{
							Title = "Notification";
							Message = "You are a(n) "..rankName..". Click to view commands.";
							Icon = "rbxassetid://7536784790";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})

						Functions.Hint(p.Name..' is now rank '.. args[2] .. " (Permission Level: ".. newLevel ..")", {plr})
					end
				end
			end;
		};

		SetTempRank = {
			Prefix = Settings.Prefix;
			Commands = {"settemprank", "settempadminrank", "tempsetrank"};
			Args = {"player", "rank"};
			Description = "Identical to :setrank except doesn't save";
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				local senderLevel = data.PlayerData.Level;
				local rankName = args[2];
				local newRank = assert(Settings.Ranks[rankName], "Rank not found");
				local newLevel = newRank and newRank.Level;

				assert(newLevel < senderLevel, "Rank level cannot be equal to or greater than your own permission level (".. senderLevel ..")");

				for i,p in pairs(service.GetPlayers(plr, args[1]))do
					local targetLevel = Admin.GetLevel(p);

					assert(targetLevel < senderLevel, "Target player's permission level is greater than or equal to your permission level");

					if targetLevel < senderLevel then
						Admin.AddAdmin(p, rankName, true)
						Remote.MakeGui(p,"Notification",{
							Title = "Notification";
							Message = "You are a temp "..rankName..". Click to view commands.";
							Icon = "rbxassetid://7536784790";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})

						Functions.Hint(p.Name..' is now rank '.. args[2] .. " (Permission Level: ".. newLevel ..")", {plr})
					end
				end
			end;
		};

		SetLevel = {
			Prefix = Settings.Prefix;
			Commands = {"setlevel", "setadminlevel"};
			Args = {"player", "level"};
			Description = "Sets the target player(s) permission level for the current server; Does not save";
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				local senderLevel = data.PlayerData.Level;
				local newLevel = assert(tonumber(args[2]), "Level must be a number");

				assert(newLevel < senderLevel, "Level cannot be equal to or greater than your own permission level (".. senderLevel ..")");

				for i,p in pairs(service.GetPlayers(plr, args[1]))do
					local targetLevel = Admin.GetLevel(p);

					assert(targetLevel < senderLevel, "Target player's permission level is greater than or equal to your permission level");

					if targetLevel < senderLevel then
						Admin.SetLevel(p, newLevel)--, args[3] == "true")
						Remote.MakeGui(p,"Notification",{
							Title = "Notification";
							Message = "Your admin permission level was set to "..newLevel.." for this server only. Click to view commands.";
							Icon = "rbxassetid://7536784790";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})

						Functions.Hint(p.Name..' is now permission level '.. newLevel, {plr})
					end
				end
			end;
		};


		UnAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"unadmin";"unmod","unowner","unhelper","unpadmin","unheadadmin","unrank"};
			Args = {"player", "temp (true/false)"};
			Hidden = false;
			Description = "Removes the target players' admin powers; Saves unless <temp> is 'true'";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				assert(args[1], "Argument missing or nil")

				local temp = args[2] ~= "true";
				local sendLevel = data.PlayerData.Level
				local plrs = service.GetPlayers(plr, args[1], {
					UseFakePlayer = true;
				})

				if plrs and #plrs > 0 then
					for i,v in pairs(plrs)do
						local targLevel = Admin.GetLevel(v)
						if targLevel > 0 then
							if sendLevel > targLevel then
								Admin.RemoveAdmin(v, temp, temp)
								Functions.Hint("Removed "..v.Name.."'s admin powers",{plr})
								Remote.MakeGui(v,"Notification",{
									Title = "Notification";
									Message = "Your admin powers have been removed";
									Icon = "rbxassetid://7536810074";
									Time = 10;
								})
							else
								Functions.Hint("You do not have permission to remove "..v.Name.."'s admin powers",{plr})
							end
						else
							Functions.Hint(v.Name..' is not an admin',{plr})
						end
					end
				else
					if sendLevel < 900 then
						error("Player not found. Try the full username or use id-USERSIDHERE");
					else
						local checkThis = args[1];
						local found = false;

						for rank,data in pairs(Settings.Ranks) do
							if sendLevel > data.Level then
								for i,user in ipairs(data.Users) do
									if Admin.DoCheck(checkThis, user) then
										local ans = Remote.GetGui(plr,"YesNoPrompt",{
											Question = "Remove '"..tostring(user).."' from '".. rank .."'?";
										})

										if ans == "Yes" then
											table.remove(data.Users, i);

											if not temp and Settings.SaveAdmins then
												service.TrackTask("Thread: RemoveAdmin", Core.DoSave, {
													Type = "TableRemove";
													Table = {"Settings", "Ranks", rank, "Users"};
													Value = user;
												});
											end

											Functions.Hint("Removed ".. tostring(user) .." from ".. rank,{plr})
											Logs:AddLog("Script", string.format("%s removed %s from %s", tostring(plr), tostring(user), rank))
											found = true;
										end
									end
								end
							end
						end

						if not found then
							error("No table entries matching '".. checkThis .."' found");
						end
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
				local plrs = service.GetPlayers(plr, args[1], {
					DontError = true;
				})
				if plrs and #plrs>0 then
					for i,v in pairs(plrs) do
						local targLevel = Admin.GetLevel(v)
						if targLevel>0 then
							if sendLevel>targLevel then
								Admin.RemoveAdmin(v,true)
								Functions.Hint("Removed "..v.Name.."'s admin powers",{plr})
								Remote.MakeGui(v,"Notification",{
									Title = "Notification";
									Message = "Your admin powers have been temporarily removed";
									Icon = "rbxassetid://7536810074";
									Time = 10;
								})
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

		TempModerator = {
			Prefix = Settings.Prefix;
			Commands = {"tempmod","tmod","temp","helper";};
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
						Admin.AddAdmin(v, "Moderators", true)
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are a temp moderator. Click to view commands.";
							Icon = "rbxassetid://7536784790";
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
						Admin.AddAdmin(v, "Moderators")
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are a moderator. Click to view commands.";
							Icon = "rbxassetid://7536784790";
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

		Broadcast = {
			Prefix = Settings.Prefix;
			Commands = {"broadcast";"bc";};
			Args = {"Message";};
			Filter = true;
			Description = "Makes a message in the chat window";
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers()) do
					Remote.Send(v, "Function", "ChatMessage", string.format("[%s] %s", Settings.SystemTitle, service.Filter(args[1], plr, v)), Color3.new(1,64/255,77/255))
				end
			end
		};

		ShutdownLogs = {
			Prefix = Settings.Prefix;
			Commands = {"shutdownlogs";"shutdownlog";"slogs";"shutdowns";};
			Args = {};
			Hidden = false;
			Description = "Shows who shutdown or restarted a server and when";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local logs = Core.GetData("ShutdownLogs") or {}
				local tab = {}
				for i,v in pairs(logs) do
					if v.Restart then v.Time = v.Time.." [SOFT]" end
					table.insert(tab, {Text=v.Time..": "..v.User, Desc="Reason: "..v.Reason})
				end
				Remote.MakeGui(plr,"List",{Title = "Shutdown Logs",Table = tab,Update = "shutdownlogs"})
			end
		};

		ServerLock = {
			Prefix = Settings.Prefix;
			Commands = {"slock","serverlock","lockserver"};
			Args = {"on/off"};
			Hidden = false;
			Description = "Enables/disables server lock";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				if not args[1] or (args[1] and (string.lower(args[1]) == "on" or string.lower(args[1]) == "true")) then
					Variables.ServerLock = true
					Functions.Hint("Server Locked",{plr})
				elseif string.lower(args[1]) == "off" or string.lower(args[1]) == "false" then
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
				if string.lower(args[1])=='on' or string.lower(args[1])=='enable' then
					Variables.Whitelist.Enabled = true
					Functions.Hint("Server Whitelisted", service.Players:GetPlayers())
				elseif string.lower(args[1])=='off' or string.lower(args[1])=='disable' then
					Variables.Whitelist.Enabled = false
					Functions.Hint("Server Unwhitelisted", service.Players:GetPlayers())
				elseif string.lower(args[1])=="add" then
					if args[2] then
						local plrs = service.GetPlayers(plr,args[2], {
							DontError = true;
							IsServer = false;
							IsKicking = false;
							UseFakePlayer = true;
						})
						if #plrs>0 then
							for i,v in pairs(plrs) do
								table.insert(Variables.Whitelist.Lists.Settings,v.Name..":"..v.userId)
								Functions.Hint("Whitelisted "..v.Name,{plr})
							end
						else
							table.insert(Variables.Whitelist.Lists.Settings, args[2])
						end
					else
						error('Missing name to whitelist')
					end
				elseif string.lower(args[1])=="remove" then
					if args[2] then
						for i,v in pairs(Variables.Whitelist.Lists.Settings) do
							if string.sub(string.lower(v), 1,#args[2]) == string.lower(args[2])then
								table.remove(Variables.Whitelist.Lists.Settings,i)
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

		SystemNotify = {
			Prefix = Settings.Prefix;
			Commands = {"sn","systemnotify","sysnotif","sysnotify"};
			Args = {"message";};
			Filter = true;
			Description = "Makes a system small message,";
			AdminLevel = "Admins";
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

		Notif = {
			Prefix = Settings.Prefix;
			Commands = {"setmessage";"notif";"setmsg";};
			Args = {"message OR off";};
			Filter = true;
			Description = "Sets a small hint message at the top of the screen";
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")

				if args[1] == "off" or args[1] == "false" then
					Variables.NotifMessage = nil
					for i,v in pairs(service.GetPlayers()) do
						Remote.RemoveGui(v,"Notif")
					end
				else
					Variables.NotifMessage = args[1]
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
			Commands = {"setlockmessage"; "slockmsg"};
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
			Commands = {"sm";"systemmessage";"sysmsg"};
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
						Message = args[1];
					})
				end
			end
		};

		SetCoreGuiEnabled = {
			Prefix = Settings.Prefix;
			Commands = {"setcoreguienabled";"setcoreenabled";"showcoregui";"setcoregui";"setcgui";"setcore"};
			Args = {"player";"element";"true/false";};
			Hidden = false;
			Description = "SetCoreGuiEnabled. Enables/Disables CoreGui elements. ";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if string.lower(args[3])=='on' or string.lower(args[3])=='true' then
						Remote.Send(v,'Function','SetCoreGuiEnabled',args[2],true)
					elseif string.lower(args[3])=='off' or string.lower(args[3])=='false' then
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
				for i,v in pairs(service.GetPlayers(plr,string.lower(args[1])))do
					Remote.MakeGui(v,"Alert",{Message = args[2] and service.Filter(args[2],plr,v) or "Wake up; Your attention is required"})
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
				for _, Obj in ipairs(workspace:GetDescendants())do
					if Obj:IsA("BasePart")then
						Obj.Locked = true
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
				for _, Obj in ipairs(workspace:GetDescendants())do
					if Obj:IsA("BasePart")then
						Obj.Locked = false
					end
				end
			end
		};

		BuildingTools = {
			Prefix = Settings.Prefix;
			Commands = {"btools";"f3x";"buildtools";"buildingtools";"buildertools";};
			Args = {"player";};
			Hidden = false;
			Description = "Gives the target player(s) F3X building tools.";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local F3X = service.New("Tool", {
					GripPos = Vector3.new(0, 0, 0.4),
					CanBeDropped = false,
					ManualActivationOnly = false,
					ToolTip = "Building Tools by F3X",
					Name = "Building Tools"
				})
				service.New("StringValue", {
					Name = "__ADONIS_VARIABLES_" .. Variables.CodeName,
					Parent = F3X
				})

				local clonedDeps = Deps.Assets:FindFirstChild("F3X Deps"):Clone()
				for _, SourceContainer in ipairs(clonedDeps:GetDescendants()) do
					if SourceContainer.ClassName == "LocalScript" or SourceContainer.ClassName == "Script" then
						SourceContainer.Disabled = false
					end
				end
				for _, Child in ipairs(clonedDeps:GetChildren()) do
					Child.Parent = F3X
				end

				for _, v in pairs(service.GetPlayers(plr,args[1])) do
					local Backpack = v:FindFirstChildOfClass("Backpack")

					if Backpack then
						F3X:Clone().Parent = Backpack
					end
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
			AdminLevel = "Admins";
			Function = function(plr,args)
				local id = string.lower(args[1])
				for i,v in pairs(Variables.InsertList) do
					if id == string.lower(v.Name)then
						id = v.ID
						break
					end
				end

				local obj = service.Insert(tonumber(id), true)
				if obj and plr.Character then
					table.insert(Variables.InsertedObjects, obj)
					obj.Parent = service.Workspace
					pcall(obj.MakeJoints, obj)
					obj:PivotTo(plr.Character:GetPivot())
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
				local color = BrickColor.new(math.random(1, 227))
				if BrickColor.new(args[2]) ~= nil then color = BrickColor.new(args[2]) end
				local team = service.New("Team", service.Teams)
				team.Name = args[1]
				team.AutoAssignable = false
				team.TeamColor = color
			end
		};

		RemoveTeam = {
			Prefix = Settings.Prefix;
			Commands = {"removeteam";"deleteteam"};
			Args = {"name";};
			Hidden = false;
			Description = "Remove the specified team";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.Teams:GetChildren()) do
					if v:IsA("Team") and string.sub(string.lower(v.Name), 1,#args[1]) == string.lower(args[1])then
						v:Destroy()
					end
				end
			end
		};

		RestoreMap = {
			Prefix = Settings.Prefix;
			Commands = {"restoremap";"maprestore";"rmap";};
			Args = {};
			Description = "Restore the map to the the way it was the last time it was backed up";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local plr_name = plr and plr.Name

				if not Variables.MapBackup then
					error("Cannot restore when there are no backup maps!",0)
					return
				end
				if Variables.RestoringMap then
					error("Map has not been backed up",0)
					return
				end
				if Variables.BackingupMap then
					error("Cannot restore map while backing up map is in process!",0)
					return
				end

				Variables.RestoringMap = true
				Functions.Hint('Restoring Map...', service.Players:GetPlayers())

				for _, Obj in ipairs(workspace:GetChildren()) do
					if Obj.ClassName ~= "Terrain" and not service.Players:GetPlayerFromCharacter(Obj) then
						Obj:Destroy()
						service.RunService.Stepped:Wait()
					end
				end

				local new = Variables.MapBackup:Clone()
				for _, Obj in ipairs(new:GetChildren()) do
					Obj.Parent = workspace
					if Obj:IsA("Model") then
						Obj:MakeJoints()
					end
				end
				new:Destroy()

				local Terrain = workspace.Terrain or workspace:FindFirstChildOfClass("Terrain")
				if Terrain and Variables.TerrainMapBackup then
					Terrain:Clear()
					Terrain:PasteRegion(Variables.TerrainMapBackup, Terrain.MaxExtents.Min, true)
				end

				wait();

				Admin.RunCommand(Settings.Prefix .. "respawn", "all")
				Variables.RestoringMap = false
				Functions.Hint('Map Restore Complete.',service.Players:GetPlayers())

				Logs:AddLog("Script", {
					Text = "Map Restoration Complete",
					Desc = (plr_name or "<SERVER>") .. " has restored the map.",
				})
			end
		};

		ScriptBuilder = {
			Prefix = Settings.Prefix;
			Commands = {"scriptbuilder";"scriptb";"sb"};
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

				local action = string.lower(args[1])
				local class = args[2] or "LocalScript"
				local name = args[3]

				if string.lower(class) == "script" or string.lower(class) == "s" then
					class = "Script"
				elseif string.lower(class) == "localscript" or string.lower(class) == "ls" then
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
							sb.ChatEvent:Disconnect()
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
							sb[class][name].Event = plr.Chatted:Connect(function(msg)
								if string.sub(msg, 1,#(Settings.Prefix.."sb")) == Settings.Prefix.."sb" then

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
							sb[class][name].Event:Disconnect()
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
							sb.ChatEvent:Disconnect()
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
			Commands = {"s";"ss";"serverscript";"sscript";"makescript";"script"};
			Args = {"code";};
			Description = "Executes the given code on the server";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				assert(Settings.CodeExecution, "CodeExecution must be enabled for this command to work")
				assert(args[1], "Missing 1st argument.")

				local bytecode = Core.Bytecode(args[1])
				assert(string.find(bytecode,"\27Lua"), "Script unable to be created,".. string.gsub(bytecode, "Loadstring%.LuaX:%d+:", ""))

				local cl = Core.NewScript('Script', args[1], true)
				cl.Name = "[Adonis] Script"
				cl.Parent = service.ServerScriptService
				wait()
				cl.Disabled = false
				Functions.Hint("Ran Script",{plr})
			end
		};

		MakeLocalScript = {
			Prefix = Settings.Prefix;
			Commands = {"ls";"localscript";"lscript";"makelscript"};
			Args = {"code";};
			Description = "Executes the given code on the client";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				assert(args[1], "Missing 1st argument.")

				local bytecode = Core.Bytecode(args[1])
				assert(string.find(bytecode,"\27Lua"), "Script unable to be created,".. string.gsub(bytecode, "Loadstring%.LuaX:%d+:", ""))

				local cl = Core.NewScript('LocalScript',"script.Parent = game:GetService('Players').LocalPlayer.PlayerScripts; "..args[1], true)
				cl.Name = "[Adonis] LocalScript"
				cl.Disabled = true
				cl.Parent = plr.Backpack
				wait()
				cl.Disabled = false
				Functions.Hint("Ran LocalScript",{plr})
			end
		};

		LoadLocalScript = {
			Prefix = Settings.Prefix;
			Commands = {"cs";"cscr";"clientscript";};
			Args = {"player";"code";};
			Description = "Executes the given code on the client of the target player(s)";
			AdminLevel = "Admins";
			NoFilter = true;
			Function = function(plr,args)
				assert(args[2], "Missing 2nd argument.")

				local bytecode = Core.Bytecode(args[2])
				assert(string.find(bytecode,"\27Lua"), "Script unable to be created,".. string.gsub(bytecode, "Loadstring%.LuaX:%d+:", ""))

				local new = Core.NewScript('LocalScript',"script.Parent = game:GetService('Players').LocalPlayer.PlayerScripts; "..args[2], true)
				for i,v in pairs(service.GetPlayers(plr,args[1]))do
					local cl = new:Clone()
					cl.Name = "[Adonis] LocalScript"
					cl.Disabled = true
					cl.Parent = v.Backpack
					wait()
					cl.Disabled = false
					Functions.Hint("Ran LocalScript on "..v.Name,{plr})
				end
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
						if string.lower(args[2]) == "all" then
							PlayerData.AdminNotes={}
						else
							for k,m in pairs(PlayerData.AdminNotes) do
								if string.sub(string.lower(m), 1,#args[2]) == string.lower(args[2])then
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
						Remote.Send(v,"Function","SetFPS",5.6)
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

		Crash = {
			Prefix = Settings.Prefix;
			Commands = {"crash";};
			Args = {"player";};
			Hidden = false;
			Description = "Crashes the target player(s)";
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
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
				for i,v in pairs(service.GetPlayers(plr,args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
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
				for i,v in pairs(service.GetPlayers(plr,args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
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
				for i,v in pairs(service.GetPlayers(plr,args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
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
				if Core.DataStore and not Core.PanicMode then
					Core.UpdateData("ShutdownLogs", function(logs)
						if plr then
							table.insert(logs, 1, {
								User = plr.Name,
								Time = service.GetTime(),
								Reason = args[1] or "N/A"
							})
						else
							table.insert(logs,1,{
								User = "[Server]",
								Time = service.GetTime(),
								Reason = args[1] or "N/A"
							})
						end

						if #logs > 1000 then
							table.remove(logs,#logs)
						end

						return logs
					end)
				end

				Functions.Shutdown(args[1])
			end
		};

		ServerBan = {
			Prefix = Settings.Prefix;
			Commands = {"ban", "serverban"};
			Args = {"player", "reason"};
			Description = "Bans the player from the server";
			AdminLevel = "Admins";
			Filter = true;
			Hidden = false;
			Fun = false;
			Function = function(plr,args,data)
				local level = data.PlayerData.Level
				local reason = args[2] or "No reason provided";
				for i,v in pairs(service.GetPlayers(plr,args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					}))do
					if level > Admin.GetLevel(v) then
						Admin.AddBan(v, reason)
						Functions.Hint("Server banned "..tostring(v),{plr})
					end
				end
			end
		};

		UnBan = {
			Prefix = Settings.Prefix;
			Commands = {"unban";};
			Args = {"player";};
			Description = "Unbans the target player(s)";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local ret = Admin.RemoveBan(args[1])
				if ret then
					if type(ret) == "table" then
						ret = tostring(ret.Name) .. ":" .. tostring(ret.UserId);
					else
						ret = tostring(ret);
					end

					Functions.Hint(ret.. ' has been Unbanned', {plr})
				end
			end
		};

		TrelloBan = {
			Prefix = Settings.Prefix;
			Commands = {"trelloban";"tban"};
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

				if not Settings.Trello_Enabled or board == "" or appkey == "" or token == "" then Functions.Hint('Trello has not been configured in settings', {plr}) return end

				local trello = HTTP.Trello.API(appkey,token)
				local lists = trello.getLists(board)
				local list = trello.getListObj(lists,{"Banlist","Ban List","Bans"})

				local level = data.PlayerData.Level
				local reason = string.format("Administrator: %s\nReason: %s", plr.Name, (args[2] or "N/A"))

				for _, v in pairs(service.GetPlayers(plr,args[1], {
						DontError = false;
						IsServer = false;
						IsKicking = true;
						UseFakePlayer = true;
					})) do

					if level > Admin.GetLevel(v) then
						trello.makeCard(
							list.id,
							string.format("%s:%d", (v and tostring(v.Name) or tostring(v)), tostring(v.UserId)),
							reason
						)

						--Functions.Hint("Trello banned ".. (v and tostring(v.Name) or tostring(v)), {plr})
						pcall(function() plr:Kick(reason) end)
						Remote.MakeGui(p,"Notification",{
							Title = "Notification";
							Message = "Trello banned ".. (v and tostring(v.Name) or tostring(v));
							Icon = "rbxassetid://7536784790";
							Time = 5;
						})
					end
				end

				HTTP.Trello.Update()
			end;
		};

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
				for i,v in pairs(service.Players:GetPlayers()) do
					Remote.RemoveGui(v,"Message")
					Remote.MakeGui(v,"Message",{
						Title = args[1];
						Message = args[2];
						Time = (#tostring(args[1]) / 19) + 2.5;
						--service.Filter(args[1],plr,v);
					})
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

		PromptPremiumPurchase = {
			Prefix = Settings.Prefix;
			Commands = {"promptpremiumpurchase";"premiumpurchaseprompt";};
			Args = {"player"};
			Description = "Opens the Roblox Premium purchase prompt for the target player(s)";
			Hidden = false;
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.MarketplaceService:PromptPremiumPurchase(v)
				end
			end
		};

		RobloxNotify = {
			Prefix = Settings.Prefix;
			Commands = {"rbxnotify";"robloxnotify";"robloxnotif";"rblxnotify";"rnotif";"rn"};
			Args = {"player","duration (seconds)","text"};
			Filter = true;
			Description = "Sends a Roblox default notification for the target player(s)";
			Hidden = false;
			Fun = false;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.LoadCode(v,"service.StarterGui:SetCore('SendNotification',{Title='Notification',Text='"..args[3].."',Duration="..tostring(tonumber(args[2])).."})")
				end
			end
		};
	}
end
