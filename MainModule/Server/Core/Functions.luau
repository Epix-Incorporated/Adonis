--// Function stuff
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server
	local service = Vargs.Service

	local logError
	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;
		logError = server.logError;
		Functions.NuclearExplode = select(2, xpcall(require, warn, server.Dependencies.FastNuke));

		Functions.Init = nil
		Logs:AddLog("Script", "Functions Module Initialized")
	end;

	local function RunAfterPlugins(data)
		Functions.RunAfterPlugins = nil
		Logs:AddLog("Script", "Functions Module RunAfterPlugins Finished")
	end

	server.Functions = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		PlayerFinders = {
			["me"] = {
				Match = "me";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					table.insert(players, plr)
					plus()
				end;
			};

			["all"] = {
				Match = "all";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local everyone = true
					if isKicking then
						local lower = string.lower
						local sub = string.sub

						for _,v in parent:GetChildren() do
							local p = getplr(v)
							if p and sub(lower(p.Name), 1, #msg)==lower(msg) then
								everyone = false
								table.insert(players, p)
								plus()
							end
						end
					end

					if everyone then
						for _,v in parent:GetChildren() do
							local p = getplr(v)
							if p then
								table.insert(players, p)
								plus()
							end
						end
					end
				end;
			};

			["everyone"] = {
				Match = "everyone";
				Absolute = true;
				Prefix = true;
				Function = function(...)
					return Functions.PlayerFinders.all.Function(...)
				end
			};

			["others"] = {
				Match = "others";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					for _,v in parent:GetChildren() do
						local p = getplr(v)
						if p and p ~= plr then
							table.insert(players, p)
							plus()
						end
					end
				end;
			};

			["random"] = {
				Match = "random";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					table.insert(randplayers, "random")
					plus()
				end;
			};

			["admins"] = {
				Match = "admins";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					for _,v in parent:GetChildren() do
						local p = getplr(v)
						if p and Admin.CheckAdmin(p,false) then
							table.insert(players, p)
							plus()
						end
					end
				end;
			};

			["nonadmins"] = {
				Match = "nonadmins";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					for _,v in parent:GetChildren() do
						local p = getplr(v)
						if p and not Admin.CheckAdmin(p,false) then
							table.insert(players, p)
							plus()
						end
					end
				end;
			};

			["friends"] = {
				Match = "friends";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					for _,v in parent:GetChildren() do
						local p = getplr(v)
						if p and p:IsFriendsWith(plr.UserId) then
							table.insert(players, p)
							plus()
						end
					end
				end;
			};

			["@username"] = {
				Match = "@";
				Prefix = false;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = string.match(msg, "@(.*)")
					local foundNum = 0

					if matched then
						for _,v in parent:GetChildren() do
							local p = getplr(v)
							if p and p.Name == matched then
								table.insert(players, p)
								plus()
								foundNum += 1
							end
						end
					end
				end;
			};

			["%team"] = {
				Match = "%";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = string.match(msg, "%%(.*)")

					local lower = string.lower
					local sub = string.sub

					if matched and #matched > 0 then
						for _,v in service.Teams:GetChildren() do
							if sub(lower(v.Name), 1, #matched) == lower(matched) then
								for _,m in parent:GetChildren() do
									local p = getplr(m)
									if p and p.TeamColor == v.TeamColor then
										table.insert(players, p)
										plus()
									end
								end
							end
						end
					end
				end;
			};

			["$group"] = {
				Match = "$";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = string.match(msg, "%$(.*)")
					if matched and tonumber(matched) then
						for _,v in parent:GetChildren() do
							local p = getplr(v)
							if p and p:IsInGroup(tonumber(matched)) then
								table.insert(players, p)
								plus()
							end
						end
					end
				end;
			};

			["id-"] = {
				Match = "id-";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = tonumber(string.match(msg, "id%-(.*)"))
					local foundNum = 0
					if matched then
						for _,v in parent:GetChildren() do
							local p = getplr(v)
							if p and p.UserId == matched then
								table.insert(players, p)
								plus()
								foundNum += 1
							end
						end

						if foundNum == 0 and useFakePlayer then
							local ran, name = pcall(service.Players.GetNameFromUserIdAsync, service.Players, matched)
							if ran or allowUnknownUsers then
								local fakePlayer = Functions.GetFakePlayer({
									UserId = matched,
									Name = name,
								})
								table.insert(players, fakePlayer)
								plus()
							end
						end
					end
				end;
			};

			["displayname-"] = {
				Match = "displayname-";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = tonumber(string.match(msg, "displayname%-(.*)"))
					local foundNum = 0

					if matched then
						for _,v in parent:GetChildren() do
							local p = getplr(v)
							if p and p.DisplayName == matched then
								table.insert(players, p)
								plus()
								foundNum += 1
							end
						end
					end
				end;
			};

			["team-"] = {
				Match = "team-";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local lower = string.lower
					local sub = string.sub

					local matched = string.match(msg, "team%-(.*)")
					if matched then
						for _,v in service.Teams:GetChildren() do
							if sub(lower(v.Name), 1, #matched) == lower(matched) then
								for _,m in parent:GetChildren() do
									local p = getplr(m)
									if p and p.TeamColor == v.TeamColor then
										table.insert(players, p)
										plus()
									end
								end
							end
						end
					end
				end;
			};

			["group-"] = {
				Match = "group-";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = string.match(msg, "group%-(.*)")
					matched = tonumber(matched)

					if matched then
						for _,v in parent:GetChildren() do
							local p = getplr(v)
							if p and p:IsInGroup(matched) then
								table.insert(players, p)
								plus()
							end
						end
					end
				end;
			};

			["-name"] = {
				Match = "-";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = string.match(msg, "%-(.*)")
					if matched then
						local removes = service.GetPlayers(plr,matched, {
							DontError = true;
						})

						for k,p in removes do
							if p then
								table.insert(delplayers,p)
								plus()
							end
						end
					end
				end;
			};

			["+name"] = {
				Match = "+";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = string.match(msg, "%+(.*)")
					if matched then
						local adds = service.GetPlayers(plr,matched, {
							DontError = true;
						})

						for k,p in adds do
							if p then
								table.insert(addplayers,p)
								plus()
							end
						end
					end
				end;
			};

			["#number"] = {
				Match = "#";
				Function = function(msg, plr, ...)
					local matched = string.match(msg, "#(.*)")
					if matched and tonumber(matched) then
						local num = tonumber(matched)
						if not num then
							Remote.MakeGui(plr,"Output", {Title = "Invalid argument"; Message = "Argument supplied is not a number!"})
							return;
						end

						for i = 1, math.min(num, #service.Players:GetPlayers()) do
							Functions.PlayerFinders.random.Function(msg, plr, ...)
						end
					end
				end;
			};

			["radius-"] = {
				Match = "radius-";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, isServer, dontError, useFakePlayer, allowUnknownUsers)
					local matched = string.match(msg, "radius%-(.*)")
					if matched and tonumber(matched) then
						local num = tonumber(matched)
						if not num then
							Remote.MakeGui(plr,"Output", {Title = "Invalid argument"; Message = "Argument supplied is not a number!"})
							return;
						end

						for _,v in parent:GetChildren() do
							local p = getplr(v)
							local character = p.Character
							local Head = character and character:FindFirstChild("Head")

							if Head and p and p ~= plr and plr:DistanceFromCharacter(Head.Position) <= num then
								table.insert(players,p)
								plus()
							end
						end
					end
				end;
			};
		};

		GetFakePlayer = function(options)
			local fakePlayer = service.Wrap(service.New("Folder", {
				Name = options.Name or "Fake_Player";
				Archivable = false;
			}))

			local data = {
				ClassName = "Player";
				Name = "[Unknown User]";
				DisplayName = "[Unknown User]";
				UserId = 0;
				AccountAge = 0;
				MembershipType = Enum.MembershipType.None;
				CharacterAppearanceId = options.UserId or 0;
				FollowUserId = 0;
				GameplayPaused = false;
				Parent = service.Players;
				Character = service.New("Model", {Name = options.Name or "Fake_Player"});
				Backpack = service.New("Backpack", {Name = "FakeBackpack"});
				PlayerGui = service.New("Folder", {Name = "FakePlayerGui"});
				PlayerScripts = service.New("Folder", {Name = "FakePlayerScripts"});
				GetJoinData = function() return {} end;
				GetFriendsOnline = function() return {} end;
				GetRankInGroup = function() return 0 end;
				GetRoleInGroup = function() return "Guest" end;
				IsFriendsWith = function() return false end;
				Kick = function() fakePlayer:SetSpecial("Parent", nil) fakePlayer:Destroy() end;
				IsA = function(_, className) return className == "Player" or className == "Instance" end;
			}

			for k, v in options do
				data[k] = v
			end

			if data.UserId > 0 then
				local success, actualName = pcall(service.Players.GetNameFromUserIdAsync, service.Players, data.UserId)
				if success then
					data.Name = actualName
				end
			end

			data.userId = data.UserId
			data.ToString = data.Name

			for k, v in data do
				fakePlayer:SetSpecial(k, v)
			end

			return fakePlayer
		end;

		GetChatService = function()
			return if service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then false else nil
		end;

		ArgsToString = function(args)
			local str = table.create(args.n or #args)
			for i, arg in args do
				str[i] = `Arg{i}: {arg}; `
			end
			return string.sub(table.concat(str), 1, -3)
		end;

		GetPlayers = function(plr, argument, options)
			options = options or {}

			local parent = options.Parent or service.Players
			local players = {}
			local delplayers = {}
			local addplayers = {}
			local randplayers = {}

			local function getplr(p)
				if p then
					if p.ClassName == "Player" then
						return p
					elseif p:IsA("NetworkReplicator") then
						local networkPeerPlayer = p:GetPlayer()
						if networkPeerPlayer and networkPeerPlayer.ClassName == "Player" then
							return networkPeerPlayer
						end
					end
				end
				return nil
			end

			local function checkMatch(msg)
				msg = string.lower(msg)
				local doReturn
				local PlrLevel = if plr then Admin.GetLevel(plr) else 0

				for _, data in Functions.PlayerFinders do
					if not data.Level or (data.Level and PlrLevel >= data.Level) then
						local check = ((data.Prefix and Settings.SpecialPrefix) or "")..data.Match
						if (data.Absolute and msg == check) or (not data.Absolute and string.sub(msg, 1, #check) == string.lower(check)) then
							if data.Absolute then
								return data
							else --// Prioritize absolute matches over non-absolute matches
								doReturn = data
							end
						end
					end
				end

				return doReturn
			end

			if plr == nil then
				--// Select all players
				for _, v in parent:GetChildren() do
					local p = getplr(v)
					if p then
						table.insert(players, p)
					end
				end
			elseif plr and not argument then
				--// Default to the executor ("me")
				return {plr}
			else
				if string.match(argument, "^##") then
					error(`String passed to GetPlayers is filtered: {argument}`, 2)
				end

				local selectors = string.gmatch(argument, "([^,]+)")

				--// This is for player commands that take in service.GetPlayers() to make sure someone isnt passing in a message that is insanely long
				local PlrLevel = if plr then Admin.GetLevel(plr) else 0
				local AllowUnsafeSelectors = PlrLevel > 0 or options.AllowUnsafeSelectors
				local MaxSelectors = Variables.MaxSafeSelectors or 400 -- 400 seems like a good "max" that won't ever be reached

				local index = 0

				for s in selectors do
					index += 1
					if not AllowUnsafeSelectors and index > MaxSelectors then
						break
					end
					local plrCount = 0
					local function plus() plrCount += 1 end

					if not options.NoSelectors then
						local matchFunc = checkMatch(s)
						if matchFunc then
							matchFunc.Function(
								s,
								plr,
								parent,
								players,
								delplayers,
								addplayers,
								randplayers,
								getplr,
								plus,
								options.IsKicking,
								options.IsServer,
								options.DontError,
								options.UseFakePlayer,
								options.AllowUnknownUsers
							)
						end
					end

					if plrCount == 0 then
						--// Check for display names
						for _, v in parent:GetChildren() do
							local p = getplr(v)
							if p and p.ClassName == "Player" and string.match(string.lower(p.DisplayName), `^{service.SanitizePattern(string.lower(s))}`) then
								table.insert(players, p)
								plus()
							end
						end

						if plrCount == 0 then
							--// Check for usernames
							for _, v in parent:GetChildren() do
								local p = getplr(v)
								if p and p.ClassName == "Player" and string.match(string.lower(p.Name), `^{service.SanitizePattern(string.lower(s))}`) then
									table.insert(players, p)
									plus()
								end
							end

							--// Check for user IDs
							if tonumber(s) then
								for _, v in parent:GetChildren() do
									local p = getplr(v)
									if p and p.ClassName == "Player" and p.UserId == tonumber(s) then
										table.insert(players, p)
										plus()
									end
								end
							end

							if plrCount == 0 then
								if options.UseFakePlayer then
									--// Attempt to retrieve non-ingame user
									local UserId
									if Functions.GetUserIdFromNameAsync(s) then
										UserId = Functions.GetUserIdFromNameAsync(s)
									else
										if tonumber(s) then
											UserId = s
										end
									end
									if UserId or options.AllowUnknownUsers then
										table.insert(players, Functions.GetFakePlayer({
											Name = s;
											DisplayName = s;
											UserId = if UserId then UserId else -1;
										}))
										plus()
									end
								end

								if plrCount == 0 and not options.DontError then
									Remote.MakeGui(plr, "Output", {
										Title = "Missing player";
										Message = if options.UseFakePlayer then `No user named '{s}' exists`
											else `No players matching '{s}' were found!`;
									})
								end
							end
						end
					end
				end
			end

			--// The following is intended to prevent name spamming (eg. :re scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel...)
			--// It will also prevent situations where a player falls within multiple player finders (eg. :re group-1928483,nonadmins,radius-50 (one player can match all 3 of these))
			--// Edited to adjust removals and randomizers.

			local filteredList = {}
			local checkList = {}

			for _, v in players do
				if not checkList[v] then
					table.insert(filteredList, v)
					checkList[v] = true
				end
			end

			local delFilteredList = {}
			local delCheckList = {}

			for _, v in delplayers do
				if not delCheckList[v] then
					table.insert(delFilteredList, v)
					delCheckList[v] = true
				end
			end

			local addFilteredList = {}
			local addCheckList = {}

			for _, v in addplayers do
				if not addCheckList[v] then
					table.insert(addFilteredList, v)
					addCheckList[v] = true
				end
			end

			local removalSuccessList = {}

			for i, v in filteredList do
				for j, w in delFilteredList do
					if v.Name == w.Name then
						table.remove(filteredList,i)
						table.insert(removalSuccessList, w)
					end
				end
			end


			for j, w in addFilteredList do
				table.insert(filteredList, w)
			end

			local checkList2 = {}
			local finalFilteredList = {}

			for _, v in filteredList do
				if not checkList2[v] then
					table.insert(finalFilteredList, v)
					checkList2[v] = true
				end
			end


			local comboTableCheck = {}

			for _, v in finalFilteredList do
				table.insert(comboTableCheck, v)
			end
			for _, v in delFilteredList do
				table.insert(comboTableCheck, v)
			end

			local function rplrsort()
				local children = parent:GetChildren()
				local childcount = #children
				local excludecount = #comboTableCheck
				if excludecount < childcount then
					local rand = children[math.random(#children)]
					local rp = getplr(rand)

					for _, v in comboTableCheck do
						if v.Name == rp.Name then
							rplrsort()
							return
						end
					end

					table.insert(finalFilteredList, rp)

					local comboTableCheck = {}
					for _, v in finalFilteredList do
						table.insert(comboTableCheck, v)
					end
					for _, v in delFilteredList do
						table.insert(comboTableCheck, v)
					end
				end
			end

			for i, v in randplayers do
				rplrsort()
			end

			return finalFilteredList
		end;

		-- ROT 47: ROT13 BUT BETTER
		Rot47Cipher = function(data,mode)
			if not (mode == "enc" or mode == "dec") then error("Invalid ROT47 Cipher Mode") end

			local base = 33
			local range = 126 - 33 + 1

			-- Checks if the given char is convertible
			-- ASCII Code should be within the range [33 .. 126]
			local function rot47_convertible(char)
				local v = string.byte(char)
				return v >= 33 and v <= 126
			end

			local function cipher(str, key)
				return (string.gsub(str, ".", function(s)
					if not rot47_convertible(s) then return s end
					return string.char(((string.byte(s) - base + key) % range) + base)
				end))
			end
			if mode == "enc" then return cipher(data,47) end
			if mode == "dec" then return cipher(data,-47) end
		end;

		-- Thanks to Tiffany352 for this base64 implementation!

		Base64Encode = function(str)
			local floor = math.floor
			local char = string.char
			local sub = string.sub

			local nOut = 0
			local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			local strLen = #str
			local out = table.create(math.ceil(strLen / 0.75))

			-- 3 octets become 4 hextets
			for i = 1, strLen - 2, 3 do
				local b1, b2, b3 = string.byte(str, i, i + 3)
				local word = b3 + b2 * 256 + b1 * 256 * 256

				local h4 = word % 64 + 1
				word = floor(word / 64)
				local h3 = word % 64 + 1
				word = floor(word / 64)
				local h2 = word % 64 + 1
				word = floor(word / 64)
				local h1 = word % 64 + 1

				out[nOut + 1] = sub(alphabet,h1, h1)
				out[nOut + 2] = sub(alphabet,h2, h2)
				out[nOut + 3] = sub(alphabet,h3, h3)
				out[nOut + 4] = sub(alphabet,h4, h4)
				nOut = nOut + 4
			end

			local remainder = strLen % 3

			if remainder == 2 then
				-- 16 input bits -> 3 hextets (2 full, 1 partial)
				local b1, b2 = str:byte(-2, -1)
				-- partial is 4 bits long, leaving 2 bits of zero padding ->
				-- offset = 4
				local word = b2 * 4 + b1 * 4 * 256

				local h3 = word % 64 + 1
				word = floor(word / 64)
				local h2 = word % 64 + 1
				word = floor(word / 64)
				local h1 = word % 64 + 1

				out[nOut + 1] = sub(alphabet,h1, h1)
				out[nOut + 2] = sub(alphabet,h2, h2)
				out[nOut + 3] = sub(alphabet,h3, h3)
				out[nOut + 4] = "="
			elseif remainder == 1 then
				-- 8 input bits -> 2 hextets (2 full, 1 partial)
				local b1 = str:byte(-1, -1)
				-- partial is 2 bits long, leaving 4 bits of zero padding ->
				-- offset = 16
				local word = b1 * 16

				local h2 = word % 64 + 1
				word = floor(word / 64)
				local h1 = word % 64 + 1

				out[nOut + 1] = sub(alphabet,h1, h1)
				out[nOut + 2] = sub(alphabet,h2, h2)
				out[nOut + 3] = "="
				out[nOut + 4] = "="
			end
			-- if the remainder is 0, then no work is needed

			return table.concat(out, "")
		end;

		Base64Decode = function(str)
			local floor = math.floor
			local char = string.char
			local sub = string.sub

			local nOut = 0
			local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			local strLen = #str
			local out = table.create(math.ceil(strLen * 0.75))
			local acc = 0
			local nAcc = 0

			local alphabetLut = {}
			for i = 1, #alphabet do
				alphabetLut[sub(alphabet, i, i)] = i - 1
			end

			-- 4 hextets become 3 octets
			for i = 1, strLen do
				local ch = sub(str, i, i)
				local byte = alphabetLut[ch]
				if byte then
					acc = acc * 64 + byte
					nAcc += 1
				end

				if nAcc == 4 then
					local b3 = acc % 256
					acc = floor(acc / 256)
					local b2 = acc % 256
					acc = floor(acc / 256)
					local b1 = acc % 256

					out[nOut + 1] = char(b1)
					out[nOut + 2] = char(b2)
					out[nOut + 3] = char(b3)
					nOut += 3
					nAcc = 0
					acc = 0
				end
			end

			if nAcc == 3 then
				-- 3 hextets -> 16 bit output
				acc *= 64
				acc = floor(acc / 256)
				local b2 = acc % 256
				acc = floor(acc / 256)
				local b1 = acc % 256

				out[nOut + 1] = char(b1)
				out[nOut + 2] = char(b2)
			elseif nAcc == 2 then
				-- 2 hextets -> 8 bit output
				acc *= 64
				acc = floor(acc / 256)
				acc *= 64
				acc = floor(acc / 256)
				local b1 = acc % 256

				out[nOut + 1] = char(b1)
			elseif nAcc == 1 then
				error("Base64 has invalid length")
			end

			return table.concat(out, "")
		end;

		Hint = function(message, players, duration, title, image)
			duration = duration or (#tostring(message) / 19) + 2.5

			for _, v in players do
				Remote.MakeGui(v, "Hint", {
					Message = message;
					Time = duration;
					Title = title;
					Image = image;
				})
			end
		end;

		Message = function(sender, title, message, image, players, scroll, duration)

			-- Currently not used
			if sender == "Adonis" or sender == "HelpSystem" or sender == "Command" then
				sender = nil
			end

			-- ////////// Compatability for older plugins (before sender and image ares were introduced)
			if sender ~= nil and typeof(sender) ~= "Instance" and typeof(sender) ~= "userdata" and type(sender) ~= "table" then
				local oldVars = {
					sender = sender,
					title = title,
					message = message,
					image = image,
					players = players,
					scroll = scroll,
					duration = duration,
				}

				title = oldVars.sender
				message = oldVars.title
				players = oldVars.message
				scroll = oldVars.image
				duration = oldVars.players

				sender = nil
				image = nil
			end

			duration = duration or (#tostring(message) / 19) + 2.5

			if image then
				-- Support "MatIcon://" for fast access to maticons
				local MatIcon = string.match(image, "MatIcon://(.+)")

				if MatIcon then
					image = server.MatIcons[MatIcon]
				elseif sender and (image == "HeadShot") then
					image = `rbxthumb://type=AvatarHeadShot&id={sender.UserId}&w=48&h=48`
				end
			end

			for _, v in players do
				task.defer(function()
					Remote.RemoveGui(v, "Message")
					Remote.MakeGui(v, "Message", {
						Title = title;
						Message = message;
						Scroll = scroll;
						Time = duration;
						Image = image;
						UserId = sender and sender.UserId or nil;
					})
				end)
			end
		end;

		Notify = function(title, message, players, duration, author)
			duration = duration or (#tostring(message) / 19) + 2.5

			for _, v in players do
				task.defer(function()
					Remote.RemoveGui(v, "Notify")
					Remote.MakeGui(v, "Notify", {
						Title = title;
						Message = message;
						Time = duration;
						UserId = author and author.UserId or nil;
					})
				end)
			end
		end;

		Notification = function(title, message, players, duration, icon, onClick)
			icon = icon and string.match(icon, "MatIcon://(.+)") or icon

			for _, v in players do
				Remote.MakeGui(v, "Notification", {
					Title = title;
					Message = message;
					Time = duration;
					Icon = server.MatIcons[icon or "Info"];
					OnClick = onClick;
				})
			end
		end;

		MakeWeld = function(a, b, c0, c1)
			local weld = service.New("Weld")
			weld.Part0 = a
			weld.Part1 = b
			weld.C0 = c0 or a.CFrame:Inverse() * b.CFrame
			weld.C1 = c1 or CFrame.new()
			weld.Parent = a
			return weld
		end;

		SetLighting = function(prop, value)
			if service.CheckProperty(service.Lighting, prop) then
				local success = pcall(function()
					service.Lighting[prop] = value
				end)
				if success then
					Variables.LightingSettings[prop] = value
					for _, p in service.GetPlayers() do
						Remote.SetLighting(p, prop, value)
					end
				end
			end
		end;

		SetAtmosphere = function(prop,value)
			local atmosphere = service.Lighting:FindFirstChildWhichIsA("Atmosphere")

			if atmosphere then
				if value == nil and atmosphere[prop] and typeof(atmosphere[prop]) ~= "Instance" then
					atmosphere:Destroy()
					table.clear(Variables.AtmosphereSettings)
				else
					atmosphere[prop] = value
					Variables.AtmosphereSettings[prop] = value
				end

				for _, p in service.GetPlayers() do
					Remote.SetAtmosphere(p, prop, value)
				end
			end
		end;

		LoadEffects = function(plr)
			for i, v in Variables.LocalEffects do
				if (v.Part and v.Part.Parent) or v.NoPart then
					if v.Type == "Cape" then
						Remote.Send(plr, "Function", "NewCape", v.Data)
					elseif v.Type == "Particle" then
						Remote.NewParticle(plr, v.Part, v.Class, v.Props)
					end
				else
					Variables.LocalEffects[i] = nil
				end
			end
		end;

		LogAdminAction = function(plr, action, targetPlayerName, additionalDetails)
			-- kept function here for potential future reimplementation
		end;

		NewParticle = function(target, particleType, props)
			local ind = service.HttpService:GenerateGUID(false)
			Variables.LocalEffects[ind] = {
				Part = target;
				Class = particleType;
				Props = props;
				Type = "Particle";
			}
			for _, v in service.Players:GetPlayers() do
				Remote.NewParticle(v, target, particleType, props)
			end
		end;

		RemoveParticle = function(target,name)
			for i, v in Variables.LocalEffects do
				if v.Type == "Particle" and v.Part == target and (v.Props.Name == name or v.Class == name) then
					Variables.LocalEffects[i] = nil
				end
			end
			for _, v in service.Players:GetPlayers() do
				Remote.RemoveParticle(v, target, name)
			end
		end;

		UnCape = function(plr)
			for i, v in Variables.LocalEffects do
				if v.Type == "Cape" and v.Player == plr then
					Variables.LocalEffects[i] = nil
				end
			end
			for _, v in service.Players:GetPlayers() do
				Remote.Send(v, "Function", "RemoveCape", plr.Character)
			end
		end;

		Cape = function(player, isdon, material, color, decal, reflect)
			material = material or "Neon"
			if not Functions.GetEnumValue(Enum.Material, material) then
				error("Invalid material value")
			end
			--material = assert(Enum.Material:FromName(material or "Neon"), "Invalid material value")

			Functions.UnCape(player)
			local torso = player.Character:FindFirstChild("HumanoidRootPart")

			if torso then
				if type(color) == "table" then
					color = Color3.new(unpack(color))
				end

				local data = {
					Color = color;
					Parent = player.Character;
					Material = material;
					Reflectance = reflect;
					Decal = decal;
				}

				if isdon and Settings.DonorCapes and Settings.LocalCapes then
					Remote.Send(player, "Function", "NewCape", data)
				else
					local ind = service.HttpService:GenerateGUID(false)
					Variables.LocalEffects[ind] = {
						Player = player;
						Part = player.Character.HumanoidRootPart;
						Data = data;
						Type = "Cape";
					}
					for _, v in service.Players:GetPlayers() do
						Remote.Send(v, "Function", "NewCape", data)
					end
				end
			end
		end;

		PlayAnimation = function(player, animId)
			if player.Character and tonumber(animId) then
				local human = player.Character:FindFirstChildOfClass("Humanoid")
				if human and not human:FindFirstChildOfClass("Animator") then
					service.New("Animator", human)
				end
				Remote.Send(player,"Function","PlayAnimation",animId)
			end
		end;

		StopAnimation = function(player)
			if player.Character then
				local human = player.Character:FindFirstChildOfClass("Humanoid")
				if human and not human:FindFirstChildOfClass("Animator") then
					service.New("Animator", human)
				end
				Remote.Send(player,"Function","StopAnimation")
			end
		end;

		GetEnumValue = function(enum, item)
			local valid = false
			for _,v in enum:GetEnumItems() do
				if v.Name == item then
					valid = v.Value
					break
				end
			end
			return valid
		end;

		ApplyBodyPart = function(character, model)
			-- NOTE: Use HumanoidDescriptions to apply body parts where possible, unless applying custom parts
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local rigType = humanoid.RigType.Name
				local part = model:FindFirstChild(rigType)

				if not part and rigType == "R15" then
					part = model:FindFirstChild("R15Fixed")
				end

				if part then
					if rigType == "R6" then
						local children = character:GetChildren()
						for _,v in part:GetChildren() do
							for _,x in children do
								if x:IsA("CharacterMesh") and x.BodyPart == v.BodyPart then
									x:Destroy()
								end
							end
							v:Clone().Parent = character
						end
					elseif rigType == "R15" then
						for _,v in part:GetChildren() do
							local value = Functions.GetEnumValue(Enum.BodyPartR15, v.Name)
							--local value = Enum.BodyPartR15:FromName(v.Name)
							if value then
								humanoid:ReplaceBodyPartR15(value, v:Clone())
							end
						end
					end
				end
			end
		end;

		makeRobot = function(player, num, health, speed, damage, walk, attack, friendly)
			local Deps = server.Deps

			local char = player.Character
			local torso = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
			local pos = torso.CFrame

			local oldArchivable = char.Archivable
			char.Archivable = true
			local clone = char:Clone()
			char.Archivable = oldArchivable

			for i = 1, num do
				local new = clone:Clone()
				local hum = new:FindFirstChildOfClass("Humanoid")

				local brain = Deps.Assets.BotBrain:Clone()
				local event = brain.Event

				local oldAnim = new:FindFirstChild("Animate")
				local anim = hum.RigType == Enum.HumanoidRigType.R15 and Deps.Assets.R15Animate:Clone() or Deps.Assets.R6Animate:Clone()

				new.Name = player.Name
				new.Archivable = false
				new.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
				new:PivotTo(pos * CFrame.Angles(0, math.rad((360/num)*i+90), 0) * CFrame.new((num*0.2)+5, 0, 0) * CFrame.Angles(0, math.pi / 2, 0))

				hum.WalkSpeed = speed
				hum.MaxHealth = health
				hum.Health = health

				if oldAnim then
					oldAnim:Destroy()
				end

				anim.Parent = new
				brain.Parent = new

				anim.Disabled = false
				brain.Disabled = false
				new.Parent = workspace

				if i % 5 == 1 then
					task.wait()
				end

				task.defer(event.Fire, event, "SetSetting", {
					Creator = player;
					Friendly = friendly;
					TeamColor = player.TeamColor;
					Attack = attack;
					Swarm = attack;
					Walk = walk;
					Damage = damage;
					Health = health;
					WalkSpeed = speed;
					SpecialKey = service.HttpService:GenerateGUID(false);
				})

				if walk then
					task.defer(task.defer, event.Fire, event, "Init")
				end

				table.insert(Variables.Objects, new)
			end

			clone:Destroy()
		end,

		GetJoints = function(character)
			local temp = {}
			for _,v in character:GetDescendants() do
				if v:IsA("Motor6D") then
					temp[v.Name] = v -- assumes no 2 joints have the same name, hopefully this wont cause issues
				end
			end
			return temp
		end;

		ResetReplicationFocus = function(player)
			--if not workspace.StreamingEnabled then return end
			local rootPart = player.Character and player.Character.PrimaryPart
			player.ReplicationFocus = rootPart or nil
		end;

		LoadOnClient = function(player,source,object,name)
			if service.Players:FindFirstChild(player.Name) then
				local parent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 15) or player:WaitForChild("Backpack")
				local cl = Core.NewScript("LocalScript", source)
				cl.Name = name or service.HttpService:GenerateGUID(false)
				cl.Parent = parent
				cl.Disabled = false
				if object then
					table.insert(Variables.Objects,cl)
				end
			end
		end;

		Split = function(msg, key, num, useMagicChars)
			-- Rebuilt revamped version (the old one was broken) which supports quotation is based off Paul's answer to stackoverflow question #28664139, with the addition of better escaping support, thanks Paul! I hate lua patterns with a passion ngl, this is a one line regex...
			if not msg or not key then return {} end
			if key=="" or key == nil then key = " " end
			if num==nil then num = math.huge end
			if useMagicChars==nil then useMagicChars = true end

			local tab = {}
			local str = ""

			local spat, epat, escquotpat, buf, quoted = [=[^(['"])]=], [=[(['"])$]=], [=[(\(['"]))]=], nil, nil

			if useMagicChars == false then
				spat = ""
				epat = ""
				escquotpat = ""
			end

			local keyPattern = "[^"..key.."]+"

			if string.match(key, "%s") then
				keyPattern = "%S+" -- If the key is a whitespace character, use any whitespace character as the pattern
			end

			for arg in string.gmatch(msg, keyPattern) do
				local squoted = string.match(arg, spat)
				local equoted = string.match(arg, epat)
				local escaped = string.match(arg, [=[(\*)['"]$]=])

				if #tab>=num then
					break
				elseif #tab>=num-1 then
					table.insert(tab,string.sub(msg,#str+1,#msg))
					continue
				end

				if squoted and not quoted and not equoted then
					buf, quoted = arg, squoted
				elseif buf and equoted == quoted and #escaped % 2 == 0 then
					arg, buf, quoted = buf .. key .. arg, nil, nil
				elseif buf then
					buf = buf .. key .. arg
				end

				if not buf then
					local result = string.gsub(string.gsub(string.gsub(arg, spat, ""), epat, ""), escquotpat, "%2")
					str ..= result .. key
					table.insert(tab,result)
				end
			end

			return tab
		end;

		IsValidTexture = function(id)
			local id = tonumber(id)
			local ran, info = pcall(function() return service.MarketPlace:GetProductInfo(id) end)

			if ran and info and info.AssetTypeId == 1 then
				return true;
			else
				return false;
			end
		end;

		GetTexture = function(id)
			local id = tonumber(id);
			if id and Functions.IsValidTexture(id) then
				return id;
			else
				return 6825455804;
			end
		end;

		Trim = function(str)
			return string.match(str, "^%s*(.-)%s*$")
		end;

		RoundToPlace = function(num, places)
			return math.floor((num*(10^(places or 0)))+0.5)/(10^(places or 0))
		end;

		CleanWorkspace = function()
			if workspace:FindFirstChildOfClass("BackpackItem") or workspace:FindFirstChildOfClass("Accoutrement") then
				for _, v in workspace:GetChildren() do
					if v:IsA("BackpackItem") or v:IsA("Accoutrement") then
						v:Destroy()
					end
				end
			end
		end;

		RemoveSeatWelds = function(seat)
			if seat then
				for _,v in seat:GetChildren() do
					if v:IsA("Weld") then
						if v.Part1 and v.Part1.Name == "HumanoidRootPart" then
							v:Destroy()
						end
					end
				end
			end
		end;

		GrabNilPlayers = function(name)
			local AllGrabbedPlayers = {}
			for _, v in service.NetworkServer:GetChildren() do
				pcall(function()
					if v:IsA("NetworkReplicator") then
						if string.sub(string.lower(v:GetPlayer().Name), 1, #name) == string.lower(name) or name == "all" then
							table.insert(AllGrabbedPlayers, (v:GetPlayer() or "NoPlayer"))
						end
					end
				end)
			end
			return AllGrabbedPlayers
		end;

		GetUserIdFromNameAsync = function(name: string | Player)
			if type(name) == "userdata" and name:IsA("Player") then
				return name.UserId
			end

			local cache = Admin.UserIdCache[name]
			if not cache then
				local success, UserId = pcall(service.Players.GetUserIdFromNameAsync, service.Players, name)

				if success then
					Admin.UserIdCache[name] = UserId
					return UserId
				end
			end

			return cache
		end;

		GetNameFromUserIdAsync = function(id: number | Player)
			if type(id) == "userdata" and id:IsA("Player") then
				return id.Name
			end

			local cache = Admin.UsernameCache[id]
			if not cache then
				local success, Username = pcall(service.Players.GetNameFromUserIdAsync, service.Players, id)

				if success then
					Admin.UsernameCache[id] = Username
					return Username
				end
			end

			return cache
		end;

		Shutdown = function(reason)
			Functions.Message("Adonis", Settings.SystemTitle, "The server is shutting down...", "MatIcon://Warning", service.Players:GetPlayers(), false, 5)
			task.wait(1)

			service.Players.PlayerAdded:Connect(function(player)
				player:Kick(`Server Shutdown: {reason or "No Reason Given"}`)
			end)

			for _, v in service.Players:GetPlayers() do
				v:Kick(`Server Shutdown: {reason or "No Reason Given"}`)
			end
		end;

		Donor = function(plr)
			if Admin.CheckDonor(plr) and Settings.DonorCapes then
				local PlayerData = Core.GetPlayer(plr) or {Donor = {}}
				local donor = PlayerData.Donor or {}

				if donor and donor.Enabled then
					local img, color, material
					if donor and donor.Cape then
						img, color, material = donor.Cape.Image, donor.Cape.Color, donor.Cape.Material
					else
						img, color, material = "0", "White", "Neon"
					end
					if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						Functions.Cape(plr, true, material, color, img)
					end
				end
			end
		end;

		AddJoinFilter = function(name, func)
			if server.Variables.PlayerJoinFilters[name] then
				error(string.format("The Join Filter %s already exists!", name))
			else
				server.Variables.PlayerJoinFilters[name] = func
			end
		end;

		RemoveJoinFilter = function(name)
			if server.Variables.PlayerJoinFilters[name] then
				server.Variables.PlayerJoinFilters[name] = nil
			end
		end;

		CheckMatch = function(check, match)
			if check == match then
				return true
			elseif type(check) == "table" and type(match) == "table" then
				local good = false
				local num = 0

				for k, v in check do
					if v == match[k] then
						good = true
					else
						good = false
						break
					end
					num += 1
				end

				return good and num == service.CountTable(match)
			end
			return false
		end;

		LaxCheckMatch = function(check, match, opts)
			local keys = if opts and type(opts) == "table" and opts.IgnoreKeys then opts.IgnoreKeys else {}
			if check == match then
				return true
			elseif type(check) == "table" and type(match) == "table" then
				for k, v in match do
					if table.find(keys, k) then continue end
					if type(v) == "table" and not Functions.LaxCheckMatch(check[k], v, opts) then
						return false
					elseif type(v) ~= "table" and check[k] ~= v then
						return false
					end
				end
				return true
			end
			return false
		end;

		DSKeyNormalize = function(intab, reverse)
			local tab = {}

			if reverse then
				for i,v in intab do
					if tonumber(i) then
						tab[tonumber(i)] = v;
					end
				end
			else
				for i,v in intab do
					tab[tostring(i)] = v;
				end
			end

			return tab;
		end;

		GetIndex = function(tab,match)
			for i,v in tab do
				if v==match then
					return i
				elseif type(v)=="table" and type(match)=="table" then
					local good = false
					for k,m in v do
						if m == match[k] then
							good = true
						else
							good = false
							break
						end
					end
					if good then
						return i
					end
				end
			end
		end;

		ConvertPlayerCharacterToRig = function(plr: Player, rigType: EnumItem)
			rigType = rigType or Enum.HumanoidRigType.R15

			local Humanoid: Humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")

			local HumanoidDescription = Humanoid:GetAppliedDescription() or service.Players:GetHumanoidDescriptionFromUserId(plr.UserId)
			local newCharacterModel: any = service.Players:CreateHumanoidModelFromDescription(HumanoidDescription, rigType, Enum.AssetTypeVerification.Always)
			local Animate: BaseScript = newCharacterModel.Animate

			newCharacterModel.Humanoid.DisplayName = Humanoid.DisplayName
			newCharacterModel.Name = plr.Name

			local oldCFrame = plr.Character and plr.Character:GetPivot() or CFrame.new()

			if plr.Character then
				plr.Character:Destroy()
				plr.Character = nil
			end
			plr.Character = newCharacterModel

			-- Clone StarterCharacterScripts to new character
			if service.StarterPlayer:FindFirstChild("StarterCharacterScripts") then
				for _, v in service.StarterPlayer:FindFirstChild("StarterCharacterScripts"):GetChildren() do
					if v.Archivable then
						v:Clone().Parent = newCharacterModel
					end
				end
			end

			newCharacterModel:PivotTo(oldCFrame)
			newCharacterModel.Parent = workspace

			-- hacky way to fix other people being unable to see animations.
			for _ = 1, 2 do
				if Animate then
					Animate.Disabled = not Animate.Disabled
				end
			end

			return newCharacterModel
		end;

		CreateClothingFromImageId = function(clothingType, id)
			return service.New(clothingType, {
				Name = clothingType;
				[assert(if clothingType == "Shirt" then "ShirtTemplate"
					elseif clothingType == "Pants" then "PantsTemplate"
					elseif clothingType == "ShirtGraphic" then "Graphic"
					else nil, "Invalid clothing type")
				] = `rbxassetid://{id}`;
			})
		end;

		ParseColor3 = function(str: string)
			if not str then return nil end
			if str:lower() == "random" then
				return Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
			end

			local color = {}
			for s in string.gmatch(str, "[%d]+") do
				table.insert(color, tonumber(s))
			end

			if #color == 3 then
				return Color3.fromRGB(color[1], color[2], color[3])
			else
				local brickColor = BrickColor.new(str::any);
				if str == tostring(brickColor) then
					return brickColor.Color
				else
					return
				end
			end
		end;

		SHA256 = function(...)
			return require(server.Shared.HashLib).SHA256(...)
		end;

		ParseBrickColor = function(str: string, allowNil: boolean?)
			if not str and allowNil then
				return nil
			end
			if not str or str:lower() == "random" then
				return BrickColor.random()
			end

			local brickColor = BrickColor.new(str::any)
			if str == tostring(brickColor) then
				return brickColor
			else
				-- If provided a Color3, return closest BrickColor
				local color = Functions.ParseColor3(str)
				if color then
					return BrickColor.new(color)
				end
			end
			return if allowNil then nil else BrickColor.random()
		end;

		GetMainPrefix = function()
			if type(Settings.Prefix) == "table" then return Settings.Prefix[1] else return Settings.Prefix end
		end;
	}


end
