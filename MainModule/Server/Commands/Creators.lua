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
			Args = {"player", "reason"};
			Description = "DirectBans the player (Saves)";
			AdminLevel = "Creators";
			Filter = true;
			Hidden = false;
			Fun = false;
			Function = function(plr,args,data)
				local reason = args[2] or "No reason provided";

				for i in string.gmatch(args[1], "[^,]+") do
					local UserId = service.Players:GetUserIdFromNameAsync(i)

					if UserId == plr.UserId then
						error("You cannot ban yourself or the creator of the game", 2)
						return
					end

					if UserId then
						Admin.AddBan({UserId = UserId, Name = i}, reason, true)
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
			Description = "Force all game-players to teleport to a desired place";
			AdminLevel = "Creators";
			CrossServerDenied = true;
			IsCrossServer = true;
			NoStudio = true;
			Function = function(plr,args)
				assert(args[1], "Must provide valid PlaceId")
				assert(tonumber(args[1]), "Invalid PlaceId (PlaceId must be a number)")

				local ans = Remote.GetGui(plr,"YesNoPrompt",{
					Question = "Force all game-players to teleport to place '".. args[1].."'?";
					Title = "Force teleport all users?";
				})
				if ans == "Yes" then
					if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, Settings.Prefix.."forceplace all "..args[1]) then
						error("CrossServer Handler Not Ready");
					end
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
			NoStudio = true;
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

		MakeHeadAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"headadmin","owner","hadmin","oa"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) a HeadAdmin; Saves";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr, args, data)
				local sendLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v, "HeadAdmins")
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are a head admin. Click to view commands.";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now a head admin',{plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};

		TempHeadAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"tempheadadmin","tempowner","toa","thadmin";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) a temporary head admin; Does not save";
			Fun = false;
			AdminLevel = "Creators";
			Function = function(plr, args, data)
				local sendLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v, "HeadAdmins", true)
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are a temp head admin. Click to view commands.";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now a temp head admin',{plr})
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
				assert(args[1], "Provide a player name");
				assert(args[2], "Enter a command to run as the target player");
				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					Process.Command(v, args[2], {isSystem = true});
				end
			end;
		};

		ClearPlayerData = {
			Prefix = Settings.Prefix;
			Commands = {"clearplayerdata","clrplrdata","clearplrdata"};
			Arguments = {"UserId"};
			Description = "Clears PlayerData linked to the specified UserId";
			AdminLevel = "Creators";
			Function = function(plr, args)
				local id = tonumber(args[1]);
				assert(id, "Must supply valid UserId");
				local username = (game:GetService("Players"):GetNameFromUserIdAsync(args[1]))
				local ans = Remote.GetGui(plr,"YesNoPrompt",{
					Question = "Clearing all PlayerData for "..username.." will erase all warns, notes, bans, and other data associated with " ..username.. " such as theme preference.\n Are you sure you want to erase "..username.."'s PlayerData? This action is irreversible.";
					Title = "Clear PlayerData for "..username.."?";
					Size = {281.25,187.5};
				})
				if ans == "Yes" then
					Core.RemoveData(tostring(id));
					Core.PlayerData[tostring(id)] = nil;
	
					Remote.MakeGui(plr,"Notification",{
						Title = "Notification";
						Message = "Cleared data for ".. id;
						Time = 10;
					})
				end
			end;
		};

		Terminal = {
			Prefix = ":";
			Commands = {"terminal";"console";};
			Args = {};
			Hidden = false;
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
	}
end
