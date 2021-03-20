return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
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

		Ban = {
			Prefix = Settings.Prefix;
			Commands = {"ban";};
			Args = {"player", "reason"};
			Description = "Bans the player from the server";
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				local level = data.PlayerData.Level
				local reason = args[2] or "No reason provided";
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
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
			Description = "UnBan";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local ret = Admin.RemoveBan(args[1])
				if ret then
					Functions.Hint(tostring(ret)..' has been Unbanned',{plr})
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
	}
end
