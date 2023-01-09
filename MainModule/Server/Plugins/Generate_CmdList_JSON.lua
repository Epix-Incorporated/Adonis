server = nil
service = nil

--// This module is only used to generate and update a list of non-custom commands for the webpanel and will not operate under normal circumstances

return function(Vargs, GetEnv)
	local env = GetEnv(nil, { script = script })
	setfenv(1, env)

	server = Vargs.Server
	service = Vargs.Service

	local Functions, Commands, Core, HTTP = server.Functions, server.Commands, server.Core, server.HTTP

	--if true then return end --// fully disabled
	service.TrackTask("Thread: WEBPANEL_JSON_UPDATE", function()
		task.wait(1)
		local enabled = rawget(_G, "ADONISWEB_CMD_JSON_DOUPDATE")
		local secret = rawget(_G, "ADONISWEB_CMD_JSON_SECRET")
		local endpoint = rawget(_G, "ADONISWEB_CMD_JSON_ENDPOINT")
		if not enabled or not secret or not endpoint then
			return
		end

		print("WEB ENABLED DO UPDATE")

		if Core.DebugMode and enabled then
			print("DEBUG DO LAUNCH ENABLED")
			task.wait(5)

			local list = {}
			local Encode = Functions.Base64Encode

			for i, cmd in Commands do
				table.insert(list, {
					Index = i,
					Prefix = cmd.Prefix,
					Commands = cmd.Commands,
					Arguments = cmd.Args,
					AdminLevel = cmd.AdminLevel,
					Hidden = cmd.Hidden or false,
					NoFilter = cmd.NoFilter or false,
				})
			end

			--// LAUNCH IT
			print("LAUNCHING")
			local success, res = pcall(HTTP.RequestAsync, HTTP, {
				Url = endpoint,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["Secret"] = secret,
				},

				Body = HTTP:JSONEncode({
					["data"] = Encode(HTTP:JSONEncode(list)),
				}),
			})

			print("LAUNCHED TO WEBPANEL")
			print("RESPONSE BELOW")
			print(`SUCCESS: {tostring(success)}\nRESPONSE:\n{(res and HTTP.JSONEncode(res)) or res}`)
		end
	end)
end
