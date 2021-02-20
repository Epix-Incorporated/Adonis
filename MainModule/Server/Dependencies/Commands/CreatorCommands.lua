server = nil
service = nil

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

	local Commands = {
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
		
		MakeGui = {
			Prefix = Settings.Prefix;
			Commands = {"makegui"};
			Arguments = {"UI"};
			Description = "Creates a specific UI on your client";
			AdminLevel = "Creators";
			Function = function(plr, args)
				assert(args[1], "Argument missing or nil")
				Remote.MakeGui(plr, args[1])
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
	}
	
	for ind, com in pairs(Commands) do
		server.Commands[ind] = com
	end
end