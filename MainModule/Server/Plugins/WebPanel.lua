--// WebPanel module uploaded as a group model due to there being multiple maintainers
--// Module source available at https://www.roblox.com/library/6289861017/WebPanel-Module


return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;
	local settings = server.Settings;

	--[[
		settings.WebPanel_Enabled = true;
		task.wait(1)
		settings.WebPanel_ApiKey = _G.ADONIS_WEBPANEL_TESTING_APIKEY;
	--]]

	--// Note: This will only run/be required if the WebPanel_Enabled setting is true at server startup
	if server.Settings.WebPanel_Enabled then
		local ran,WebModFunc = pcall(require, 6289861017)
		if ran and WebModFunc then
			coroutine.wrap(WebModFunc)(Vargs)
		elseif not ran then
			warn("WebPanel Loading Failed: ".. tostring(WebModFunc))
		end
	end

	server.Logs:AddLog("Script", "WebPanel Module Loaded");
end
