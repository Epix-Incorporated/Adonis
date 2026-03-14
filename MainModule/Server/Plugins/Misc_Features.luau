--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!

return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	--// AutoClean
	if Settings.AutoClean then
		service.StartLoop("AUTO_CLEAN", Settings.AutoCleanDelay, Functions.CleanWorkspace, true)
		Logs:AddLog("Script", `Started autoclean with {Settings.AutoCleanDelay}s delay`)
	end

	-- // Add legacy donors
	Variables.OldDonorList = select(2, xpcall(require, warn, server.Deps.LegacyDonors)) or {}
	for _, v in Variables.OldDonorList do
		if v.Id then
			Variables.CachedDonors[tostring(v.Id)] = os.time()
		end
	end

	-- // Backwards compatibility
	local Pcall = server.Pcall
	local function cPcall(func, ...)
		return Pcall(function(...)
			return coroutine.resume(coroutine.create(func), ...)
		end, ...)
	end
	server.cPcall, service.cPcall = cPcall, cPcall
	service.AltUnpack = function(args, shift) -- TODO: Remove. This is not used in Adonis at all and is easily replicatable so you can safely remove it withour fear
		return table.unpack(args, 1 + (shift and shift - 1 or 0), 10 + (shift and shift - 1 or 0))
	end
	service.CloneTable = function(tbl)
		return (getmetatable(tbl) and not pcall(setmetatable(tbl, getmetatable(tbl)))) and setmetatable({}, {__index = function(_, k) return tbl[k] end}) or table.clone(tbl)
	end
	service.GoodSignal = service.Signal
	service.Yield = function()
		local event = service.Signal.new()
		return {
			Release = function(...) event:Fire(...) end;
			Wait = function(...) return event:Wait(...) end;
			Destroy = function() event:Destroy() end;
			Event = event;
		}
	end
	Remote.UnEncrypted = setmetatable({}, { -- TODO: Start adding a server.Messages message and remove later
		__newindex = function(_, ind, val)
			warn("Unencrypted remote commands are deprecated; moving", ind, "to Remote.Commands. Replace `Remote.Unencrypted` with `Remote.Commands`!")
			Remote.Commands[ind] = val
			Logs:AddLog("Script", `Attempted to add {ind} to legacy Remote.Unencrypted. Moving to Remote.Commands`)
		end
	})
	if service.Wrapped(server.Folder) then
		server.Folder:SetSpecial("Shared", server.Shared)
	end
	Functions.GetRandom = function(pLen)
		local random = math.random
		local format = string.format

		local Len = (type(pLen) == "number" and pLen) or random(5,10) --// reru
		local Res = {}
		for Idx = 1, Len do
			Res[Idx] = format("%02x", random(255))
		end
		return table.concat(Res)
	end
	if HTTP.Trello.API then
		HTTP.Trello.API.GenerateRequestID = Functions.GetRandom
	end
	--// Old settings/plugins backwards compatibility. Do not remove this because many games use old loader ranks!
	for _, rank in {"Owners", "HeadAdmins", "Admins", "Moderators", "Creators"} do
		if Settings[rank] and not Settings.CustomRanks[rank] then
			Settings.Ranks[if rank == "Owners" then "HeadAdmins" else rank].Users = Settings[rank]
		end
	end
	if Settings.CustomRanks then
		local Ranks = Settings.Ranks
		for name, users in Settings.CustomRanks do
			if not Ranks[name] then
				Ranks[name] = {
					Level = 1;
					Users = users;
				}
			end
		end
	end
	for k, v in {-- Legacy aliases
		[`{Settings.Prefix}giveppoints <player> <amount>`] = `{Settings.Prefix}clientscript <player> game:GetService("StarterGui"):SetCore("SendNotification", \{Title = "Points Awarded", Text = "You received <amount> points!", Icon = "rbxassetid://155221172"\})`,
		[`{Settings.Prefix}giveplayerpoints <player> <amount>`] = `{Settings.Prefix}clientscript <player> game:GetService("StarterGui"):SetCore("SendNotification", \{Title = "Points Awarded", Text = "You received <amount> points!", Icon = "rbxassetid://155221172"\})`,
		[`{Settings.Prefix}sendplayerpoints <player> <amount>`] = `{Settings.Prefix}clientscript <player> game:GetService("StarterGui"):SetCore("SendNotification", \{Title = "Points Awarded", Text = "You received <amount> points!", Icon = "rbxassetid://155221172"\})`,
		[`{Settings.Prefix}flyclip <player>`] = `{Settings.Prefix}fly <player> true`;
		[`{Settings.Prefix}showlogs true <player>`] = `{Settings.Prefix}showlogs <player> true`; -- TODO: Remove legacy :showlogs aliases, only temporarily here.
		[`{Settings.Prefix}showlogs false <player>`] = `{Settings.Prefix}showlogs <player> false`;
		[`{Settings.Prefix}showlogs yes <player>`] = `{Settings.Prefix}showlogs <player> true`;
		[`{Settings.Prefix}showlogs no <player>`] = `{Settings.Prefix}showlogs <player> false`;
		[`{Settings.Prefix}showcommandlogs true <player>`] = `{Settings.Prefix}showlogs <player> true`;
		[`{Settings.Prefix}showcommandlogs false <player>`] = `{Settings.Prefix}showlogs <player> false`;
		[`{Settings.Prefix}showcommandlogs yes <player>`] = `{Settings.Prefix}showlogs <player> true`;
		[`{Settings.Prefix}showcommandlogs no <player>`] = `{Settings.Prefix}showlogs <player> false`;
	} do
		if not Variables.Aliases[k] then
			Variables.Aliases[k] = v
		end
	end
	HTTP.CheckHttp = function()
		return HTTP.HttpEnabled
	end
	-- TODO: Remove \\/
	service.OwnsAsset = service.CheckAssetOwnership
	Functions.CatchError = server.Pcall

	Logs:AddLog("Script", "Misc Features Module Loaded")
end
