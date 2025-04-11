--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!

return function(Vargs, GetEnv)
	local client = Vargs.Client;
	local service = Vargs.Service;

	local Settings = client.Settings
	local Functions, Anti, Core, Logs, Remote, Process, Variables = client.Functions, client.Anti, client.Core, client.Logs, client.Remote, client.Process, client.Variables

	-- // Backwards compatibility
	local Pcall = client.Pcall
	local function cPcall(func, ...)
		return Pcall(function(...)
			return coroutine.resume(coroutine.create(func), ...)
		end, ...)
	end
	client.cPcall, service.cPcall = cPcall, cPcall
	service.CloneTable = function(tbl)
		return (getmetatable(tbl) and not pcall(setmetatable(tbl, getmetatable(tbl)))) and setmetatable({}, {__index = function(_, k) return tbl[k] end}) or table.clone(tbl)
	end
	service.AltUnpack = function(args, shift) -- TODO: Remove. This is not used in Adonis at all and is easily replicatable so you can safely remove it withour fear
		return table.unpack(args, 1 + (shift and shift - 1 or 0), 10 + (shift and shift - 1 or 0))
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
	Remote.UnEncrypted = setmetatable({}, {
		__newindex = function(_, ind, val)
			warn("Unencrypted remote commands are deprecated; moving", ind, "to Remote.Commands. Replace `Remote.Unencrypted` with `Remote.Commands`!")
			Remote.Commands[ind] = val
			Logs:AddLog("Script", `Attempted to add {ind} to legacy Remote.Unencrypted. Moving to Remote.Commands`)
		end
	})
	client.Folder:SetSpecial("Shared", client.Shared)
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
	-- TODO: Remove \\/
	service.OwnsAsset = service.CheckAssetOwnership
	Functions.CatchError = client.Pcall

	Logs:AddLog("Script", "Misc Features Module Loaded")
end
