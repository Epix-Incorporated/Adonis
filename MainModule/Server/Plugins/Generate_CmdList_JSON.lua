server = nil;
service = nil;

--// This module is only used to generate and update a list of non-custom commands for the webpanel and will not operate under normal circumstances

return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	--if true then return end --// fully disabled
	service.TrackTask("Thread: WEBPANEL_JSON_UPDATE", function()
		wait(1)
		local enabled = _G.ADONISWEB_CMD_JSON_DOUPDATE;
		local secret = _G.ADONISWEB_CMD_JSON_SECRET;
		local endpoint = _G.ADONISWEB_CMD_JSON_ENDPOINT;
		if not enabled or not secret or not endpoint then return end

		print("WEB ENABLED DO UPDATE");

		if Core.DebugMode and enabled then
			print("DEBUG DO LAUNCH ENABLED");
			wait(5)

			local list = {};
			local HTTP = service.HttpService;
			local Encode = Functions.Base64Encode
			local Decode = Functions.Base64Decode

			for i,cmd in next,Commands do
				table.insert(list, {
					Index = i;
					Prefix = cmd.Prefix;
					Commands = cmd.Commands;
					Arguments = cmd.Args;
					AdminLevel = cmd.AdminLevel;
					Hidden = cmd.Hidden or false;
					NoFilter = cmd.NoFilter or false;
				})
			end

			--warn("COMMANDS LIST JSON: ");
			--print("\n\n".. HTTP:JSONEncode(list) .."\n\n");
			--print("ENCODED")
			--// LAUNCH IT
			print("LAUNCHING")
			local success, res = pcall(HTTP.RequestAsync, HTTP, {
				Url = endpoint;
				Method = "POST";
				Headers = {
					["Content-Type"] = "application/json",
					["Secret"] = secret
				};

				Body = HTTP:JSONEncode({
					["data"] = Encode(HTTP:JSONEncode(list))
				})
			});

			print("LAUNCHED TO WEBPANEL")
			print("RESPONSE BELOW")
			print("SUCCESS: ".. tostring(success).. "\n"..
				"RESPONSE:\n"..(res and HTTP.JSONEncode(res)) or res)
		end
	end)
end