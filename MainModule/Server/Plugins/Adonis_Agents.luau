local AGENT_COMMANDS = {
	"ShowBackpack", "PlayerList", "View", "ResetView", "Track", "UnTrack", "ServerLog", "LocalLog", "ExploitLogs", "JoinLogs",
	"ChatLogs", "RemoteLogs", "ScriptLogs", "ErrorLogs"
}

return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	Commands.Agents = {
		Prefix = Settings.PlayerPrefix;
		Commands = {"agents"; "trelloagents"; "showagents"; "adonisagents"; "epixagents";};
		Args = {};
		Hidden = true;
		Description = "Shows a list of Trello agents pulled from the configured boards";
		Fun = false;
		AdminLevel = "Players";
		Function = function(plr,args)
			local temp = {}
			for i, v in HTTP.Trello.Agents do
				table.insert(temp, {Text = v, Desc = "A Trello agent"})
			end
			Remote.MakeGui(plr, "List", {Title = "Agents", Tab = temp})
		end
	};

	Admin.AgentCache = setmetatable({}, {__mode = "k"})
	HTTP.Trello.CheckAgent = function(p)
		if Admin.AgentCache[p] ~= nil then
			return Admin.AgentCache[p]
		end

		for ind, v in HTTP.Trello.Agents do
			if Admin.DoCheck(p, v) then
				Admin.AgentCache[p] = true
				return true
			else
				Admin.AgentCache[p] = false
			end
		end
	end;

	for _, v in AGENT_COMMANDS do
		local command = Commands[v]

		if command then
			command.Agent = true
		end
	end
end
