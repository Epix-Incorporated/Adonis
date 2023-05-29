return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	local Routine = env.Routine
	local Pcall = env.Pcall
	local cPcall = env.cPcall

	return {
		ViewCommands = {
			Prefix = Settings.Prefix;
			Commands = {"cmds", "commands", "cmdlist"};
			Args = {};
			Description = "Lists all available commands";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local tab = {}
				local cmdCount = 0

				for _, cmd in Admin.SearchCommands(plr, "all") do
					if cmd.Hidden or cmd.Disabled then
						continue
					end

					local permissionDesc = Admin.FormatCommandAdminLevel(cmd)
					table.insert(tab, {
						Text = Admin.FormatCommand(cmd),
						Desc = string.format("[%s] %s", permissionDesc, cmd.Description or "(No description provided)"),
						Filter = permissionDesc
					})
					cmdCount += 1
				end

				for alias, command in Core.GetPlayer(plr).Aliases or {} do
					table.insert(tab, {
						Text = alias,
						Desc = `[User Alias] {command}`,
						Filter = command
					})
					cmdCount += 1
				end

				table.sort(tab, function(a, b) return a.Text < b.Text end)

				Remote.MakeGui(plr, "List", {
					Title = `Commands ({cmdCount})`;
					Table = tab;
					TitleButtons = {
						{
							Text = "?";
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.PlayerPrefix}usage')`)
						}
					};
				})
			end
		};
		
		CommsPanel = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notifications", "comms", "nc"};
			Args = {};
			Description = "Opens the communications panel, showing you all the Adonis messages you have recieved in a timeline";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "CommsPanel")
			end
		};

		ClientTab = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"client", "clientsettings", "playersettings"};
			Args = {};
			Description = "Opens the client settings panel";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Client"})
			end
		};

		ChangeLog = {
			Prefix = Settings.Prefix;
			Commands = {"changelog", "changes", "updates", "version"};
			Args = {};
			Description = "Shows you the script's changelog";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				server.Admin.RunCommandAsPlayer(":aciminfo", plr)
			end
		};

		UserPanel = {
			Prefix = "";
			Commands = {":userpanel"};
			Args = {};
			Hidden = true;
			Description = "Backup command for opening the userpanel window";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Info";})
			end
		};

		ScriptInfo = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"info", "about", "userpanel"};
			Args = {};
			Description = "Shows info about the admin system (Adonis)";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Info";})
			end
		};

		Aliases = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"aliases", "addalias", "removealias", "newalias"};
			Args = {};
			Description = "Opens the alias manager";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Aliases";})
			end
		};

		Keybinds = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"keybinds", "binds", "bind", "keybind", "clearbinds", "removebind"};
			Args = {};
			Description = "Opens the keybind manager";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "KeyBinds";})
			end
		};

		DevConsole = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"devconsole", "developerconsole", "opendevconsole"};
			Args = {};
			Description = "Opens the Roblox developer console";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.Send(plr, "Function", "SetCore", "DevConsoleVisible", true)
			end
		};
	};
end
