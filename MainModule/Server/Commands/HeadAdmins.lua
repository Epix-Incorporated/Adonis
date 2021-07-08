return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		TimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"tban";"timedban";"timeban";};
			Args = {"player";"number<s/m/h/d>";};
			Hidden = false;
			Description = "Bans the target player(s) for the supplied amount of time; Data Persistent; Undone using :undataban";
			Fun = false;
			AdminLevel = "HeadAdmins";
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
							Table = {"Variables", "TimeBans"};
							Value = data;
						})

						v:Kick("\nBanned until "..endTime)
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
			AdminLevel = "HeadAdmins";
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

		GameBan = {
			Prefix = Settings.Prefix;
			Commands = {"gameban", "saveban", "databan", "pban"};
			Args = {"player", "reason"};
			Description = "Bans the player from the game (Saves)";
			AdminLevel = "HeadAdmins";
			Function = function(plr,args,data)
				local level = data.PlayerData.Level
				local reason = args[2] or "No reason provided";

				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > Admin.GetLevel(v) then
						Admin.AddBan(v, reason, true)
						Functions.Hint("Game banned "..tostring(v),{plr})
					end
				end
			end
		};

		UnGameBan = {
			Prefix = Settings.Prefix;
			Commands = {"ungameban", "saveunban", "undataban", "unpban"};
			Args = {"player";};
			Description = "UnBans the player from game (Saves)";
			AdminLevel = "HeadAdmins";
			Function = function(plr,args)
				local ret = Admin.RemoveBan(args[1], true)
				if ret then
					Functions.Hint(tostring(ret)..' has been Unbanned',{plr})
				end
			end
		};

		Admin = {
			Prefix = Settings.Prefix;
			Commands = {"permadmin","pa","padmin","fulladmin"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) an admin; Saves";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr, args, data)
				local sendLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v, "Admins")
						Remote.MakeGui(v, "Notification",{
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

		GlobalMessage = {
			Prefix = Settings.Prefix;
			Commands = {"globalmessage","gm","globalannounce"};
			Args = {"message"};
			Description = "Sends a global message to all servers";
			AdminLevel = "HeadAdmins";
			Filter = true;
			CrossServerDenied = true;
			Function = function(plr,args)
				assert(args[1], "Argument #1 must be supplied")

				local globalMessage = string.format([[
					local server = server
					local service = server.Service
					local Remote = server.Remote

					for i,v in pairs(service.Players:GetPlayers()) do
						Remote.RemoveGui(v, "Message")
						Remote.MakeGui(v, "Message", {
							Title = "Global Message from %s";
							Message = "%s";
							Scroll = true;
							Time = (#("%s") / 19) + 2.5;
						})
					end
				]], plr.Name, args[1], args[1])

				if not Core.CrossServer("Loadstring", globalMessage) then
					error("CrossServer Handler Not Ready");
				end
			end;
		};

		MakeList = {
			Prefix = Settings.Prefix;
			Commands = {"makelist";"newlist";"newtrellolist";"maketrellolist";};
			Args = {"name";};
			Hidden = false;
			Description = "Adds a list to the Trello board set in Settings. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr,args)
				if not args[1] then error("Missing argument") end
				local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
				local list = trello.Boards.MakeList(Settings.Trello_Primary,args[1])
				Functions.Hint("Made list "..list.name,{plr})
			end
		};

		ViewList = {
			Prefix = Settings.Prefix;
			Commands = {"viewlist";"viewtrellolist";};
			Args = {"name";};
			Hidden = false;
			Description = "Views the specified Trello list from the primary board set in Settings.";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr,args)
				if not args[1] then error("Missing argument") end
				local trello = HTTP.Trello.API(Settings.Trello_AppKey, Settings.Trello_Token)
				local list = trello.Boards.GetList(Settings.Trello_Primary, args[1])
				if not list then error("List not found.") end
				local cards = trello.Lists.GetCards(list.id)
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
			AdminLevel = "HeadAdmins";
			Function = function(plr,args)
				Remote.MakeGui(plr,"CreateCard")
			end
		};

		FullClear = {
			Prefix = Settings.Prefix;
			Commands = {"fullclear";"clearinstances";"fullclr";};
			Args = {};
			Description = "Removes any instance created server-side by Adonis; May break things";
			AdminLevel = "HeadAdmins";
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

		BackupMap = {
			Prefix = Settings.Prefix;
			Commands = {"backupmap";"mapbackup";"bmap";};
			Args = {};
			Hidden = false;
			Description = "Changes the backup for the restore map command to the map's current state";
			Fun = false;
			AdminLevel = "HeadAdmins";
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
			AdminLevel = "HeadAdmins";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Explorer")
			end
		};

		PromptInvite = {
			Prefix = Settings.Prefix;
			Commands = {"promptinvite";"inviteprompt";"forceinvite"};
			Args = {"player"};
			Description = "Opens the friend invitation popup for the target player(s), same as them running !invite";
			Hidden = false;
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					game:GetService("SocialService"):PromptGameInvite(v)
				end
			end
		};

		FullShutdown = {
			Prefix = Settings.Prefix;
			Commands = {"fullshutdown"};
			Args = {"reason"};
			Description = "Initiates a shutdown for every running game server";
			PanicMode = true;
			AdminLevel = "HeadAdmins";
			Filter = true;
			Function = function(plr,args)
				assert(args[1], "Reason must be supplied for this command!")
				local ans = Remote.GetGui(plr,"YesNoPrompt",{
					Question = "Shutdown all running servers for the reason "..tostring(args[1]).."?";
				})
				if ans == "Yes" then
				if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, Settings.Prefix.."shutdown "..args[1] .. "\n\n\n[GLOBAL SHUTDOWN]") then
					error("An error has occured");
					end
				end
			end;
		};
	}
end
