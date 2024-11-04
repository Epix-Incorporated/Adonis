--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!

return function(Vargs, GetEnv)
	local client = Vargs.Client;
	local service = Vargs.Service;

	local Settings = client.Settings
	local Functions, Anti, Core, Logs, Remote, Process, Variables = client.Functions, client.Anti, client.Core, client.Logs, client.Remote, client.Process, client.Variables

	-- Context data
	local localPlayer = service.Players.LocalPlayer
	local hasPreloaded = false
	local gameName = string.lower(game.Name)
	local isClown = string.match(gameName, "clown")
	local isScary = string.match(gameName, "scary") or string.match(gameName, "creepy") or string.match(gameName, "mugen") or isClown
	local accountAge = localPlayer.AccountAge
	local sId1, sId2, sId3, sId4 = string.match(game.JobId, "(%x+)%-(%x+)%-(%x+)%-(%x+)")
	local serverId = sId1 and tonumber(sId1, 16) + tonumber(sId2, 16) + tonumber(sId3, 16) + tonumber(sId4, 16) or 0

	local function checkId(id, min, max, rand)
		return id * rand + math.floor((math.sin(rand * 3) + 1) * 1000) % (max * rand) >= (min * rand)
	end

	--[[
	# Ruleset for clown (excluding wait and debounce):

	- OR Clown van exists in the game
		- AND 1/3 chance
		- AND game has loaded properly
		- AND
			- OR Game is a clown game AND 4/5th of games
			- OR Game is a scary game AND 3/4th of games
			- OR Game is NOT scary AND 2/5th of games
			- OR 1/14th of servers
			- OR AccountAge < 1.5 months AND 1/7th of servers
			- OR 1/59th of users
		- AND NOT
			- AND Minutes played > 9.75
			- AND AccountAge > 1.5 months
			- AND 1/3th of servers
		- OR
			- AND Player is in clown van van
			- AND 2/3 chance
	- OR Game is a clown game
		- AND 1/5 chance
		- AND
			- OR 1/32 of games
			- OR 1/64 of servers
			- OR AccountAge < 1.5 months AND 1/32th of servers
			- OR 1/128 of users
			- OR AccountAge < 1.5 months AND 1/64th of users
			- OR 1/64 chance
	- OR Game is a scary game
		- AND 1/6th chance
		- AND
			- OR 1/64 of games
			- OR 1/128 of servers
			- OR AccountAge < 1.5 months AND 1/64th of servers
			- OR 1/256 of users
			- OR AccountAge < 1.5 months AND 1/128th of users
			- OR 1/128 chance
	- OR Server is 1/583th of servers
		- AND 4/5th of players
		- AND 5.25 minutes < Minutes played < 6.75 minutes  
		- AND 29/30 chance
	- OR DebugMode is on and NightlyMode is on
		- AND 1/10 chance -- FOR TESTING
	- OR 1 in 12k+ random chance
	]]

	Functions.PromptClown = function(noDebounce)
		if not Variables.MaximusTrollicus or noDebounce then
			local longPlaytime = time() > 9.75 * 60
			local shortPlaytime = time() > 2.75 * 60
			local hasLoaded = game:IsLoaded() and localPlayer.Character and shortPlaytime

			if
				workspace:FindFirstChild("ADONIS_VAN") and (math.random(1, 3) == 1 and hasLoaded and (
					isClown and checkId(game.GameId, 4, 5, 523)
					or isScary and checkId(game.GameId, 3, 4, 8107)
					or not isScary and checkId(game.GameId, 2, 5, 1022)
					or checkId(serverId, 1, 14, 958)
					or accountAge < 45 and checkId(serverId, 1, 7, 1667)
					or checkId(localPlayer.UserId, 1, 59, 3194)
				) and not (
					time() > 9.75 * 60
					and accountAge > 45
					and checkId(serverId, 1, 3, 2017)
				) or localPlayer.Character and localPlayer.Character:GetAttribute("ADONIS_Kidnapped") and math.random(1, 3) == 1)
				or isClown and math.random(1, 5) == 1 and (
					checkId(game.GameId, 1, 32, 2458)
					or checkId(serverId, 1, 64, 576)
					or accountAge < 45 and checkId(serverId, 1, 32, 5149)
					or checkId(localPlayer.UserId, 1, 128, 8606)
					or accountAge < 45 and checkId(localPlayer.UserId, 1, 64, 8987)
					or math.random(1, 64) == 1
				) or isScary and math.random(1, 6) == 1 and (
					checkId(game.GameId, 1, 64, 4994)
					or checkId(serverId, 1, 128, 2209)
					or accountAge < 45 and checkId(serverId, 1, 64, 6666)
					or checkId(localPlayer.UserId, 1, 256, 4592)
					or accountAge < 45 and checkId(localPlayer.UserId, 1, 128, 6275)
					or math.random(1, 128) == 1
				)
				or checkId(serverId, 1, 583, 5784) and checkId(localPlayer.UserId, 4, 5, 3474) and math.random(1, 30) ~= 1
				and time() < 6.75 * 60 and time() > 5.25 * 60
				or Core.DebugMode and Variables.NightlyMode and math.random(1, 10) == 1
				or math.random(1, 2^14) == 1 -- About 1 in 16k+ chance
			then
				Variables.MaximusTrollicus = true
				task.delay( -- Random variance in re-enabling
					math.random(1, 41) == 1 and math.random(1, 20) / 10
					or math.random(1, 3) == 1 and math.random(11, 36) * 60
					or math.random(3, 12) * 60,
				function()
					Variables.MaximusTrollicus = false
				end)
				client.UI.MakeGui("Effect", {Mode = "lifeoftheparty";})
			end
		end
	end

	Functions.PreloadClown = function()
		if not hasPreloaded then
			local CLOWN_IMAGES = {
				299733203; 299733248; 299733284; 299733309; 299733355; 299733386;
				299733404; 299733425; 299733472; 299733489; 299733501; 299733523;
				299733544; 299733551; 299733564; 299733570; 299733581; 299733597;
				299733609; 299733621; 299733632; 299733640; 299733648; 299733663;
				299733674; 299733694;
			}
			local preload = table.create(27)
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://172906410"
			preload[27] = sound
			hasPreloaded = true

			for i, v in CLOWN_IMAGES do
				preload[i] = `rbxassetid://{v}`
			end

			service.ContentProvider:PreloadAsync(preload)
			sound:Destroy()
		end
	end

	-- // Backwards compatibility
	local Pcall = client.Pcall
	local function cPcall(func, ...)
		return Pcall(function(...)
			return coroutine.resume(coroutine.create(func), ...)
		end, ...)
	end
	client.cPcall, service.cPcall = cPcall, cPcall
	Remote.UnEncrypted = setmetatable({}, {
		__newindex = function(_, ind, val)
			warn("Unencrypted remote commands are deprecated; moving", ind, "to Remote.Commands. Replace `Remote.Unencrypted` with `Remote.Commands`!")
			Remote.Commands[ind] = val
			Logs:AddLog("Script", `Attempted to add {ind} to legacy Remote.Unencrypted. Moving to Remote.Commands`)
		end
	})
	Functions.GetRandom = function(pLen)
		local random = math.random
		local format = string.format

		local Len = (type(pLen) == "number" and pLen) or random(5,10) --// reru
		local Res = {}
		for Idx = 1, Len do
			Res[Idx] = format('%02x', random(255))
		end
		return table.concat(Res)
	end

	Logs:AddLog("Script", "Misc Features Module Loaded")
end
