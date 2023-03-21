--// Function stuff
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server
	local service = Vargs.Service

	local cPcall = env.cPcall

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

		Functions.Init = nil
		Logs:AddLog("Script", "Functions Module Initialized")
	end;

	local function RunAfterPlugins(data)
		--// AutoClean
		if Settings.AutoClean then
			service.StartLoop("AUTO_CLEAN", Settings.AutoCleanDelay, Functions.CleanWorkspace, true)
		end

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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
					table.insert(players, plr)
					plus()
				end;
			};

			["all"] = {
				Match = "all";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Pefix = true;
				Function = function(...)
					return Functions.PlayerFinders.all.Function(...)
				end
			};

			["others"] = {
				Match = "others";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
					table.insert(randplayers, "random")
					plus()
				end;
			};

			["admins"] = {
				Match = "admins";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
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
					local matched = msg:match("%#(.*)")
					if matched and tonumber(matched) then
						local num = tonumber(matched)
						if not num then
							Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = "Invalid number!"})
							return;
						end

						for i = 1,num do
							Functions.PlayerFinders.random.Function(msg, plr, ...)
						end
					end
				end;
			};

			["radius-"] = {
				Match = "radius-";
				Function = function(msg, plr, parent, players, delplayers, addplayers, randplayers, getplr, plus, isKicking, useFakePlayer, allowUnknownUsers)
					local matched = msg:match("radius%-(.*)")
					if matched and tonumber(matched) then
						local num = tonumber(matched)
						if not num then
							Remote.MakeGui(plr, "Output", {Message = "Invalid number!"})
							return;
						end

						for _,v in parent:GetChildren() do
							local p = getplr(v)
							if p and p ~= plr and plr:DistanceFromCharacter(p.Character.Head.Position) <= num then
								table.insert(players,p)
								plus()
							end
						end
					end
				end;
			};
		};

		CatchError = function(func, ...)
			local ret = {pcall(func, ...)}

			if not ret[1] then
				logError(ret[2] or "Unknown error occurred")
			else
				return unpack(ret, 2)
			end
		end;

		GetFakePlayer = function(options)
			local fakePlayer = service.Wrap(service.New("Folder", {
				Name = options.Name or "Fake_Player";
			}))

			local data = {
				ClassName = "Player";
				Name = "[Unknown User]";
				DisplayName = "[Unknown User]";
				UserId = 0;
				AccountAge = 0;
				MembershipType = Enum.MembershipType.None;
				CharacterAppearanceId = if options.UserId then tostring(options.UserId) else "0";
				FollowUserId = 0;
				GameplayPaused = false;
				Parent = service.Players;
				Character = service.New("Model", {Name = options.Name or "Fake_Player"});
				Backpack = service.New("Folder", {Name = "FakeBackpack"});
				PlayerGui = service.New("Folder", {Name = "FakePlayerGui"});
				PlayerScripts = service.New("Folder", {Name = "FakePlayerScripts"});
				GetJoinData = function() return {} end;
				GetFriendsOnline = function() return {} end;
				GetRankInGroup = function() return 0 end;
				GetRoleInGroup = function() return "Guest" end;
				IsFriendsWith = function() return false end;
				Kick = function() fakePlayer:Destroy() fakePlayer:SetSpecial("Parent", nil) end;
				IsA = function(_, className) return className == "Player" end;
			}

			for i, v in options do
				data[i] = v
			end

			if data.UserId ~= -1 then
				local success, actualName = pcall(service.Players.GetNameFromUserIdAsync, service.Players, data.UserId)
				if success then
					data.Name = actualName
				end
			end

			data.userId = data.UserId
			data.ToString = data.Name

			for i, v in data do
				fakePlayer:SetSpecial(i, v)
			end

			return fakePlayer
		end;

		GetChatService = function()
			local chatHandler = service.ServerScriptService:WaitForChild("ChatServiceRunner", 120)
			local chatMod = chatHandler and chatHandler:WaitForChild("ChatService", 120)

			if chatMod then
				return require(chatMod)
			end
			return nil
		end;

		IsClass = function(obj, classList)
			for _,class in classList do
				if obj:IsA(class) then
					return true
				end
			end
			return false
		end;

		ArgsToString = function(args)
			local str = ""
			for i, arg in args do
				str ..= `Arg{i}: {arg}; `
			end
			return str:sub(1, -3)
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
				if argument:match("^##") then
					error(`String passed to GetPlayers is filtered: {argument}`, 2)
				end

				for s in argument:gmatch("([^,]+)") do
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
								not options.NoFakePlayer,
								options.AllowUnknownUsers
							)
						end
					end

					if plrCount == 0 then
						--// Check for display names
						for _, v in parent:GetChildren() do
							local p = getplr(v)
							if p and p.ClassName == "Player" and p.DisplayName:lower():match(`^{s}`) then
								table.insert(players, p)
								plus()
							end
						end

						if plrCount == 0 then
							--// Check for usernames
							for _, v in parent:GetChildren() do
								local p = getplr(v)
								if p and p.ClassName == "Player" and p.Name:lower():match(`^{s}`) then
									table.insert(players, p)
									plus()
								end
							end

							if plrCount == 0 then
								if not options.NoFakePlayer then
									--// Attempt to retrieve non-ingame user

									local UserId = Functions.GetUserIdFromNameAsync(s)
									if UserId or options.AllowUnknownUsers then
										table.insert(players, Functions.GetFakePlayer({
											Name = s;
											DisplayName = s;
											UserId = UserId or -1;
										}))
										plus()
									end
								end

								if plrCount == 0 and not options.DontError then
									Remote.MakeGui(plr, "Output", {
										Message = if not options.NoFakePlayer then `No user named '{s}' exists`
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

		GetRandom = function(pLen)
			--local str = ""
			--for i=1,math.random(5,10) do str=str..string.char(math.random(33,90)) end
			--return str

			local random = math.random
			local format = string.format

			local res = {}
			for i = 1, if type(pLen) == "number" then pLen else random(5, 10) do
				res[i] = format("%02x", random(126))
			end
			return table.concat(res)
		end;


		AdonisEncrypt = function(key)
			local ae_info = {
				version = "1";
				ver_codename = "aencrypt_xorB64";
				ver_full = "v1_AdonisEncrypt";
			}

			--return "adonis:enc;;"..ver..";;"..Base64Encode(string.char(unpack(t)))
			return {
				encrypt = function(data)
					-- Add as many layers of encryption that are useful, even a basic cipher that throws exploiters off the actual encrypted data is accepted.
					-- What could count: XOR, Base64, Simple Encryption, A Cipher to cover the encryption, etc.
					-- What would be too complex: AES-256 CTR-Mode, Base91, PGP/Pretty Good Privacy

					-- TO:DO; - Script XOR + Custom Encryption Backend, multiple security measures, if multiple encryption layers are used,
					--          manipulate the key as much as possible;
					--
					--        - Create Custom Lightweight Encoding + Cipher format, custom B64 Alphabet, etc.
					--          'ADONIS+HUJKLMSBP13579VWXYZadonis/hujklmsbp24680vwxyz><_*+-?!&@%#'
					--
					--        - A basic form of string compression before encrypting should be used
					--          If this becomes really nice, find a way to convert old datastore saved data to this new format.
					--
					--        ? This new format has an URI-Like structure to provide correct versioning and easy migrating between formats

					--[[ INSERT ALREADY USED ADONIS "ENCRYPTION" HERE ]]
					--[[ INSERT BIT32 BITWISE XOR OPERAND HERE]]
					--[[ INSERT ROT47 CIPHER HERE ]]
					--[[ INSERT CUSTOM ADONIS BASE64 ENCODING HERE ]]
					--[[ CONVERT EVERYTHING TO AN URI WITH VERSIONING AND INFORMATION ]]

				end;

				decrypt = function(data)

				end;
			}
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
				return (string.gsub(str, '.', function(s)
					if not rot47_convertible(s) then return s end
					return string.char(((string.byte(s) - base + key) % range) + base)
				end))
			end
			if mode == "enc" then return cipher(data,47) end
			if mode == "dec" then return cipher(data,-47) end
		end;

		-- CUSTOM BASE64 ALPHABET ENCODING
		Base64_A_Decode = function(data)
			local sub = string.sub
			local gsub = string.gsub
			local find = string.find
			local char = string.char
			local b = 'ADONIS+HUJKLMSBP13579VWXYZadonis/hujklmsbp24680vwxyz><_*+-?!&@%#'


			data = gsub(data, `[^{b}=]`, '')
			return (gsub(gsub(data, '.', function(x)
				if x == '=' then
					return ''
				end
				local r, f = '', (find(b, x) - 1)
				for i = 6, 1, -1 do
					r ..= (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end), '%d%d%d?%d?%d?%d?%d?%d?', function(x)
				if #x ~= 8 then
					return ''
				end
				local c = 0
				for i = 1, 8 do
					c += (sub(x, i, i) == '1' and 2 ^ (8 - i) or 0)
				end
				return char(c)
			end))
		end;

		Base64_A_Encode = function(data)
			local sub = string.sub
			local byte = string.byte
			local gsub = string.gsub

			return (gsub(gsub(data, '.', function(x)
				local r, b = "", byte(x)
				for i = 8, 1, -1 do
					r ..= (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end) .. '0000', '%d%d%d?%d?%d?%d?', function(x)
				if #(x) < 6 then
					return ''
				end
				local c = 0
				for i = 1, 6 do
					c += (sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
				end
				return sub('ADONIS+HUJKLMSBP13579VWXYZadonis/hujklmsbp24680vwxyz><_*+-?!&@%#', c + 1, c + 1)
			end)..({
				'',
				'==',
				'='
			})[#(data) % 3 + 1])
		end;
		--

		Base64Encode = function(data)
			local sub = string.sub
			local byte = string.byte
			local gsub = string.gsub

			return (gsub(gsub(data, '.', function(x)
				local r, b = "", byte(x)
				for i = 8, 1, -1 do
					r ..= (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end) .. '0000', '%d%d%d?%d?%d?%d?', function(x)
				if #(x) < 6 then
					return ''
				end
				local c = 0
				for i = 1, 6 do
					c += (sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
				end
				return sub('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', c + 1, c + 1)
			end)..({
				'',
				'==',
				'='
			})[#(data) % 3 + 1])
		end;

		Base64Decode = function(data)
			local sub = string.sub
			local gsub = string.gsub
			local find = string.find
			local char = string.char

			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

			data = gsub(data, `[^{b}=]`, '')
			return (gsub(gsub(data, '.', function(x)
				if x == '=' then
					return ''
				end
				local r, f = '', (find(b, x) - 1)
				for i = 6, 1, -1 do
					r ..= (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end), '%d%d%d?%d?%d?%d?%d?%d?', function(x)
				if #x ~= 8 then
					return ''
				end
				local c = 0
				for i = 1, 8 do
					c += (sub(x, i, i) == '1' and 2 ^ (8 - i) or 0)
				end
				return char(c)
			end))
		end;

		Hint = function(message, players, duration)
			duration = duration or (#tostring(message) / 19 + 2.5)

			for _, v in players do
				Remote.MakeGui(v, "Hint", {
					Message = message;
					Time = duration;
				})
			end
		end;

		Message = function(title, message, players, scroll, duration)
			duration = duration or (#tostring(message) / 19) + 2.5

			for _, v in players do
				task.defer(function()
					Remote.RemoveGui(v, "Message")
					Remote.MakeGui(v, "Message", {
						Title = title;
						Message = message;
						Scroll = scroll;
						Time = duration;
					})
				end)
			end
		end;

		Notify = function(title, message, players, duration)
			duration = duration or (#tostring(message) / 19) + 2.5

			for _, v in players do
				task.defer(function()
					Remote.RemoveGui(v, "Notify")
					Remote.MakeGui(v, "Notify", {
						Title = title;
						Message = message;
						Time = duration;
					})
				end)
			end
		end;

		Notification = function(title, message, players, duration, icon)
			for _, v in players do
				Remote.MakeGui(v, "Notification", {
					Title = title;
					Message = message;
					Time = duration;
					Icon = server.MatIcons[icon or "Info"];
				})
			end
		end;

		MakeWeld = function(a, b)
			local weld = service.New("ManualWeld")
			weld.Part0 = a
			weld.Part1 = b
			weld.C0 = a.CFrame:Inverse() * b.CFrame
			weld.Parent = a
			return weld
		end;

		SetLighting = function(prop,value)
			if service.Lighting[prop] ~= nil then
				service.Lighting[prop] = value
				Variables.LightingSettings[prop] = value
				for _, p in service.GetPlayers() do
					Remote.SetLighting(p, prop, value)
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

		NewParticle = function(target, particleType, props)
			local ind = Functions.GetRandom()
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

		Cape = function(player,isdon,material,color,decal,reflect)
			material = material or "Neon"
			if not Functions.GetEnumValue(Enum.Material, material) then
				error("Invalid material value")
			end

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
					local ind = Functions.GetRandom()
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
				local rigType = humanoid.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
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

			local clone
			char.Archivable = true
			clone = char:Clone()
			char.Archivable = false

			for i = 1, num do
				local new = clone:Clone()
				local hum = new:FindFirstChildOfClass("Humanoid")

				local brain = Deps.Assets.BotBrain:Clone()
				local event = brain.Event

				local oldAnim = new:FindFirstChild("Animate")
				local isR15 = hum.RigType == "R15"
				local anim = isR15 and Deps.Assets.R15Animate:Clone() or Deps.Assets.R6Animate:Clone()

				new.Name = player.Name
				new.HumanoidRootPart.CFrame = pos*CFrame.Angles(0, math.rad((360/num)*i), 0) * CFrame.new((num*0.2)+5, 0, 0)

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

				task.wait()

				event:Fire("SetSetting", {
					Creator = player;
					Friendly = friendly;
					TeamColor = player.TeamColor;
					Attack = attack;
					Swarm = attack;
					Walk = walk;
					Damage = damage;
					Health = health;
					WalkSpeed = speed;
					SpecialKey = math.random();
				})

				if walk then
					event:Fire("Init")
				end

				table.insert(Variables.Objects, new)
			end
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
				cl.Name = name or Functions.GetRandom()
				cl.Parent = parent
				cl.Disabled = false
				if object then
					table.insert(Variables.Objects,cl)
				end
			end
		end;

		Split = function(msg,key,num)
			if not msg or not key or not num or num <= 0 then return {} end
			if key=="" then key = " " end

			local tab = {}
			local str = ''

			for arg in string.gmatch(msg,`([^{key}]+)`) do
				if #tab>=num then
					break
				elseif #tab>=num-1 then
					table.insert(tab,string.sub(msg,#str+1,#msg))
				else
					str ..= arg..key
					table.insert(tab,arg)
				end
			end

			return tab
		end;

		BasicSplit = function(msg,key)
			local ret = {}
			for arg in string.gmatch(msg,`([^{key}]+)`) do
				table.insert(ret,arg)
			end
			return ret
		end;

		CountTable = function(tab)
			local num = 0
			for i in tab do
				num += 1
			end
			return num
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

		Round = function(num)
			return math.floor(num + 0.5)
		end;

		RoundToPlace = function(num, places)
			return math.floor((num*(10^(places or 0)))+0.5)/(10^(places or 0))
		end;

		CleanWorkspace = function()
			for _, v in workspace:GetChildren() do
				if v:IsA("BackpackItem") or v:IsA("Accoutrement") then
					v:Destroy()
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
			for _,v in service.NetworkServer:GetChildren() do
				pcall(function()
					if v:IsA("NetworkReplicator") then
						if string.sub(string.lower(v:GetPlayer().Name),1,#name)==string.lower(name) or name=='all' then
							table.insert(AllGrabbedPlayers, (v:GetPlayer() or "NoPlayer"))
						end
					end
				end)
			end
			return AllGrabbedPlayers
		end;

		GetUserIdFromNameAsync = function(name)
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

		Shutdown = function(reason)
			Functions.Message(Settings.SystemTitle, "The server is shutting down...", service.Players:GetPlayers(), false, 5)
			task.wait(1)

			service.Players.PlayerAdded:Connect(function(player)
				player:Kick(`Server Shutdown\n\n{reason or "No Reason Given"}`)
			end)

			for _, v in service.Players:GetPlayers() do
				v:Kick(`Server Shutdown\n\n{reason or "No Reason Given"}`)
			end
		end;

		Donor = function(plr)
			if Admin.CheckDonor(plr) and Settings.DonorCapes then
				local PlayerData = Core.GetPlayer(plr) or {Donor = {}}
				local donor = PlayerData.Donor or {}
				if donor and donor.Enabled then
					local img,color,material
					if donor and donor.Cape then
						img,color,material = donor.Cape.Image,donor.Cape.Color,donor.Cape.Material
					else
						img,color,material = '0','White','Neon'
					end
					if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						Functions.Cape(plr,true,material,color,img)
					end
				end
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

				return good and num == Functions.CountTable(match)
			end
			return false
		end;

		LaxCheckMatch = function(check, match)
			if check == match then
				return true
			elseif type(check) == "table" and type(match) == "table" then
				for k, v in match do
					if type(v) == "table" and not Functions.LaxCheckMatch(check[k], v) then
						return false
					elseif check[k] ~= v then
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
			local newCharacterModel: Model = service.Players:CreateHumanoidModelFromDescription(HumanoidDescription, rigType, Enum.AssetTypeVerification.Always)
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

		ParseColor3 = function(str: string?)
			if not str then return nil end
			if str:lower() == "random" then
				return Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
			end

			local color = {}
			for s in string.gmatch(str, "[%d]+") do
				table.insert(color, tonumber(s))
			end

			if #color == 3 then
				color = Color3.fromRGB(color[1], color[2], color[3])
			else
				local brickColor = BrickColor.new(str)
				if str == tostring(brickColor) then
					color = brickColor.Color
				else
					return
				end
			end

			return color
		end;

		ParseBrickColor = function(str: string, allowNil: boolean?)
			if not str and allowNil then
				return nil
			end
			if not str or str:lower() == "random" then
				return BrickColor.random()
			end

			local brickColor = BrickColor.new(str)
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
	};
end
