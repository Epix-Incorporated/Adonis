--// WebPanel module uploaded as a group model due to there being multiple maintainers
--// Module source available at https://www.roblox.com/library/6289861017/WebPanel-Module

return function(Vargs, GetEnv)
	local env = GetEnv(nil, { script = script })
	setfenv(1, env)

	local server = Vargs.Server

	local Settings = server.Settings
	local Logs = server.Logs

	--// Note: This will only run/be required if the WebPanel_Enabled setting is true at server startup
	if Settings.WebPanel_Enabled then
		local ran, WebModFunc = pcall(require, 6289861017)

		if ran and type(WebModFunc) == "function" then
			task.defer(WebModFunc, Vargs, env)
		elseif not ran then
			warn("Unexpected error while loading WebPanel!", tostring(WebModFunc))
		end
	end

	Logs:AddLog("Script", "WebPanel Module Loaded")
end
