return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps = 
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps
	
	if env then setfenv(1, env) end
	
	return {
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
						Admin.AddBan({UserId = userId, Name = i}, true)
						Functions.Hint("Direct banned "..i, {plr})
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

						Functions.Hint(i.." has been Unbanned", {plr})
					end
				end
			end
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
		
		Settings = {
			Prefix = "";
			Commands = {":adonissettings", Settings.Prefix.. "settings", Settings.Prefix.. "scriptsettings"};
			Args = {};
			Hidden = false;
			Description = "Opens the settings manager";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Settings"})
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
	}
end