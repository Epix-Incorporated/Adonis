--// WebPanel module uploaded as a group model due to there being multiple maintainers
--// Module source available at https://www.roblox.com/library/6289861017/WebPanel-Module


return function(Vargs, env)
	if env then
		setfenv(1, env)
	end

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	--[[
		settings.WebPanel_Enabled = true;
		wait(1)
		settings.WebPanel_ApiKey = _G.ADONIS_WEBPANEL_TESTING_APIKEY;
	--]]

	--// Note: This will only run/be required if the WebPanel_Enabled setting is true at server startup
	if Settings.WebPanel_Enabled then
		local ran, WebModFunc = pcall(require, 6289861017)

		if ran and type(WebModFunc) == "function" then
			task.defer(WebModFunc, Vargs, env)
		elseif not ran then
			warn("Unepexcted error while loading WebPanel!", tostring(WebModFunc))
		end
	end

	Logs:AddLog("Script", "WebPanel Module Loaded");
end
