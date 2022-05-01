server = nil
service = nil
cPcall = nil

--// Function stuff
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

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

		Functions.Init = nil;
		Logs:AddLog("Script", "Functions Module Initialized")
	end;

	local function RunAfterPlugins(data)
			--// AutoClean
			if Settings.AutoClean then
				service.StartLoop("AUTO_CLEAN", Settings.AutoCleanDelay, Functions.CleanWorkspace, true)
			end

			Functions.RunAfterPlugins = nil;
			Logs:AddLog("Script", "Functions Module RunAfterPlugins Finished");
	end

	server.Functions = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		PlayerFinders = {
			["me"] = {
				Match = "me";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					table.insert(players,plr)
					plus()
				end;
			};

			["all"] = {
				Match = "all";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local everyone = true
					if isKicking then
						local lower = string.lower
						local sub = string.sub

						for i,v in ipairs(parent:GetChildren()) do
							local p = getplr(v)
							if p and sub(lower(p.Name), 1, #msg)==lower(msg) then
								everyone = false
								table.insert(players,p)
								plus()
							end
						end
					end

					if everyone then
						for i,v in ipairs(parent:GetChildren()) do
							local p = getplr(v)
							if p then
								table.insert(players,p)
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
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					for i,v in ipairs(parent:GetChildren()) do
						local p = getplr(v)
						if p and p ~= plr then
							table.insert(players,p)
							plus()
						end
					end
				end;
			};

			["random"] = {
				Match = "random";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					if #players >= #parent:GetChildren() then return end
					local rand = parent:GetChildren()[math.random(#parent:GetChildren())]
					local p = getplr(rand)

					for _, v in pairs(players) do
						if v.Name == p.Name then
							Functions.PlayerFinders.random.Function(msg, plr, parent, players, getplr, plus, isKicking)
							return;
						end
					end

					table.insert(players, p)
					plus();
				end;
			};

			["admins"] = {
				Match = "admins";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					for i,v in ipairs(parent:GetChildren()) do
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
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					for i,v in ipairs(parent:GetChildren()) do
						local p = getplr(v)
						if p and not Admin.CheckAdmin(p,false) then
							table.insert(players,p)
							plus()
						end
					end
				end;
			};

			["friends"] = {
				Match = "friends";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					for i,v in ipairs(parent:GetChildren()) do
						local p = getplr(v)
						if p and p:IsFriendsWith(plr.UserId) then
							table.insert(players,p)
							plus()
						end
					end
				end;
			};

			["@username"] = {
				Match = "@";
				Prefix = false;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = string.match(msg, "@(.*)")
					local foundNum = 0

					if matched then
						for i,v in ipairs(parent:GetChildren()) do
							local p = getplr(v)
							if p and p.Name == matched then
								table.insert(players,p)
								plus()
								foundNum = foundNum+1
							end
						end
					end
				end;
			};

			["%team"] = {
				Match = "%";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = string.match(msg, "%%(.*)")

					local lower = string.lower
					local sub = string.sub

					if matched then
						for i,v in ipairs(service.Teams:GetChildren()) do
							if sub(lower(v.Name), 1, #matched) == lower(matched) then
								for k, m in ipairs(parent:GetChildren()) do
									local p = getplr(m)
									if p and p.TeamColor == v.TeamColor then
										table.insert(players,p)
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
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = string.match(msg, "%$(.*)")
					if matched and tonumber(matched) then
						for _,v in ipairs(parent:GetChildren()) do
							local p = getplr(v)
							if p and p:IsInGroup(tonumber(matched)) then
								table.insert(players,p)
								plus()
							end
						end
					end
				end;
			};

			["id-"] = {
				Match = "id-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = tonumber(string.match(msg, "id%-(.*)"))
					local foundNum = 0
					if matched then
						for _,v in ipairs(parent:GetChildren()) do
							local p = getplr(v)
							if p and p.UserId == matched then
								table.insert(players,p)
								plus()
								foundNum += 1
							end
						end

						if foundNum == 0 then
							local ran,name = pcall(function() return service.Players:GetNameFromUserIdAsync(matched) end)
							if ran and name then
								local fakePlayer = server.Functions.GetFakePlayer({
									Name = name;
									ToString = name;
									CharacterAppearanceId = tostring(matched);
									UserId = tonumber(matched);
									userId = tonumber(matched);
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
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = tonumber(string.match(msg, "displayname%-(.*)"))
					local foundNum = 0

					if matched then
						for _,v in ipairs(parent:GetChildren()) do
							local p = getplr(v)
							if p and p.DisplayName == matched then
								table.insert(players,p)
								plus()
								foundNum = foundNum+1
							end
						end
					end
				end;
			};

			["team-"] = {
				Match = "team-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local lower = string.lower
					local sub = string.sub

					local matched = string.match(msg, "team%-(.*)")
					if matched then
						for i,v in ipairs(service.Teams:GetChildren()) do
							if sub(lower(v.Name), 1, #matched) == lower(matched) then
								for k,m in ipairs(parent:GetChildren()) do
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
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = string.match(msg, "group%-(.*)")
					matched = tonumber(matched)

					if matched then
						for _,v in ipairs(parent:GetChildren()) do
							local p = getplr(v)
							if p and p:IsInGroup(matched) then
								table.insert(players,p)
								plus()
							end
						end
					end
				end;
			};

			["-name"] = {
				Match = "-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = string.match(msg, "%-(.*)")
					if matched then
						local removes = service.GetPlayers(plr,matched, {
							DontError = true;
						})

						for i,v in pairs(players) do
							for k,p in pairs(removes) do
								if p and v.Name == p.Name then
									table.remove(players,i)
									plus()
								end
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
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = msg:match("radius%-(.*)")
					if matched and tonumber(matched) then
						local num = tonumber(matched)
						if not num then
							Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = "Invalid number!"})
							return;
						end

						for i,v in ipairs(parent:GetChildren()) do
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
			local ret = {pcall(func, ...)};

			if not ret[1] then
				logError(ret[2] or "Unknown error occurred");
			else
				return unpack(ret, 2);
			end
		end;

		GetFakePlayer = function(data2)
			local fakePlayer = service.Wrap(service.New("Folder"))
			local data = {
				Name = "Fake Player";
				ClassName = "Player";
				UserId = 0;
				userId = 0;
				AccountAge = 0;
				CharacterAppearanceId = 0;
				Parent = service.Players;
				Character = Instance.new("Model");
				Backpack = Instance.new("Folder");
				PlayerGui = Instance.new("Folder");
				PlayerScripts = Instance.new("Folder");
				Kick = function() fakePlayer:Destroy() fakePlayer:SetSpecial("Parent", nil) end;
				IsA = function(ignore, arg) if arg == "Player" then return true end end;
			}

			data.ToString = data.Name;

			for i,v in pairs(data2) do
				data[i] = v;
			end;

			for i,v in pairs(data) do fakePlayer:SetSpecial(i, v) end

			return fakePlayer;
		end;

		GetChatService = function()
			local chatHandler = service.ServerScriptService:WaitForChild("ChatServiceRunner", 120);
			local chatMod = chatHandler and chatHandler:WaitForChild("ChatService", 120);

			if chatMod then
				return require(chatMod);
			end
		end;

		IsClass = function(obj, classList)
			for _,class in pairs(classList) do
				if obj:IsA(class) then
					return true
				end
			end
		end;

		ArgsToString = function(args)
			local str = ""
			for i,arg in pairs(args) do
				str = str.."Arg"..tostring(i)..": "..tostring(arg).."; "
			end
			return str
		end;

		GetPlayers = function(plr, names, data)
			if data and type(data) ~= "table" then data = {} end

			local noSelectors = data and data.NoSelectors
			local dontError = data and data.DontError
			local isServer = data and data.IsServer
			local isKicking = data and data.IsKicking
			--local noID = data and data.NoID;
			local useFakePlayer = (data and data.UseFakePlayer ~= nil and data.UseFakePlayer) or true

			local players = {}
			--local prefix = (data and data.Prefix) or Settings.SpecialPrefix
			--if isServer then prefix = "" end
			local parent = (data and data.Parent) or service.Players

			local lower = string.lower
			local sub = string.sub
			local gmatch = string.gmatch

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
			end

			local function checkMatch(msg)
				local doReturn
				local PlrLevel = Admin.GetLevel(plr)

				for ind, data in pairs(Functions.PlayerFinders) do
					if not data.Level or (data.Level and PlrLevel >= data.Level) then
						local check = ((data.Prefix and Settings.SpecialPrefix) or "")..data.Match
						if (data.Absolute and lower(msg) == check) or (not data.Absolute and sub(lower(msg), 1, #check) == lower(check)) then
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
				for _, v in ipairs(parent:GetChildren()) do
					local p = getplr(v)
					if p then
						table.insert(players, p)
					end
				end
			elseif plr and not names then
				return {plr}
			else
				if sub(lower(names), 1, 2) == "##" then
					error("String passed to GetPlayers is filtered: ".. tostring(names))
				else
					for s in gmatch(names, '([^,]+)') do
						local plrs = 0
						local function plus() plrs += 1 end

						local matchFunc = checkMatch(s)
						if matchFunc and not noSelectors then
							matchFunc.Function(s, plr, parent, players, getplr, plus, isKicking, isServer, dontError)
						else
							for _, v in ipairs(parent:GetChildren()) do
								local p = getplr(v)
								if p and p.ClassName == "Player" and sub(lower(p.DisplayName), 1, #s) == lower(s) then
									table.insert(players, p)
									plus()
								end
							end

							if plrs == 0 then
								for _, v in ipairs(parent:GetChildren()) do
									local p = getplr(v)
									if p and p.ClassName == "Player" and sub(lower(p.Name), 1, #s) == lower(s) then
										table.insert(players, p)
										plus()
									end
								end
							end

							if plrs == 0 and useFakePlayer then
								local ran, userid = pcall(function() return service.Players:GetUserIdFromNameAsync(s) end)
								if ran and tonumber(userid) then
									local fakePlayer = Functions.GetFakePlayer({
										Name = s;
										ToString = s;
										IsFakePlayer = true;
										CharacterAppearanceId = tostring(userid);
										UserId = tonumber(userid);
										userId = tonumber(userid);
										Parent = service.New("Folder");
									})

									table.insert(players, fakePlayer)
									plus()
								end
							end
						end

						if plrs == 0 and not dontError then
							Remote.MakeGui(plr, "Output", {
								Message = "No players matching "..s.." were found!"
							})
						end
					end
				end
			end

			--// The following is intended to prevent name spamming (eg. :re scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel...)
			--// It will also prevent situations where a player falls within multiple player finders (eg. :re group-1928483,nonadmins,radius-50 (one player can match all 3 of these))
			local filteredList = {}
			local checkList = {}

			for _, v in pairs(players) do
				if not checkList[v] then
					table.insert(filteredList, v)
					checkList[v] = true
				end
			end

			return filteredList
		end;

		GetRandom = function(pLen)
			--local str = ""
			--for i=1,math.random(5,10) do str=str..string.char(math.random(33,90)) end
			--return str

			local random = math.random
			local format = string.format

			local Len = (type(pLen) == "number" and pLen) or random(5,10) --// reru
			local Res = {};
			for Idx = 1, Len do
				Res[Idx] = format('%02x', random(126));
			end;
			return table.concat(Res)
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
				local v = char:byte()
				return v >= 33 and v <= 126
			end

			local function cipher(str, key)
				return (str:gsub('.', function(s)
				if not rot47_convertible(s) then return s end
					return string.char(((s:byte() - base + key) % range) + base)
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


			data = gsub(data, '[^'..b..'=]', '')
			return (gsub(gsub(data, '.', function(x)
				if x == '=' then
					return ''
				end
				local r, f = '', (find(b, x) - 1)
				for i = 6, 1, -1 do
					r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end), '%d%d%d?%d?%d?%d?%d?%d?', function(x)
				if #x ~= 8 then
					return ''
				end
				local c = 0
				for i = 1, 8 do
					c = c + (sub(x, i, i) == '1' and 2 ^ (8 - i) or 0)
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
					r = r..(b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end) .. '0000', '%d%d%d?%d?%d?%d?', function(x)
				if #(x) < 6 then
					return ''
				end
				local c = 0
				for i = 1, 6 do
					c = c + (sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
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
					r = r..(b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end) .. '0000', '%d%d%d?%d?%d?%d?', function(x)
				if #(x) < 6 then
					return ''
				end
				local c = 0
				for i = 1, 6 do
					c = c + (sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
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

			data = gsub(data, '[^'..b..'=]', '')
			return (gsub(gsub(data, '.', function(x)
				if x == '=' then
					return ''
				end
				local r, f = '', (find(b, x) - 1)
				for i = 6, 1, -1 do
					r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end), '%d%d%d?%d?%d?%d?%d?%d?', function(x)
				if #x ~= 8 then
					return ''
				end
				local c = 0
				for i = 1, 8 do
					c = c + (sub(x, i, i) == '1' and 2 ^ (8 - i) or 0)
				end
				return char(c)
			end))
		end;

		Hint = function(message,players,time)
			for i,v in pairs(players) do
				Remote.MakeGui(v,"Hint",{
					Message = message;
					Time = time or (#tostring(message) / 19) + 2.5; -- Should make longer messages not dissapear too quickly
				})
			end
		end;

		Message = function(title,message,players,scroll,tim)
			for i,v in pairs(players) do
				Remote.RemoveGui(v,"Message")
				Remote.MakeGui(v,"Message",{
					Title = title;
					Message = message;
					Scroll = scroll;
					Time = tim or (#tostring(message) / 19) + 2.5;
				})
			end
		end;

		Notify = function(title,message,players,tim)
			for i,v in pairs(players) do
				Remote.RemoveGui(v,"Notify")
				Remote.MakeGui(v,"Notify",{
					Title = title;
					Message = message;
					Time = tim or (#tostring(message) / 19) + 2.5;
				})
			end
		end;

		Notification = function(title, message, players, tim, icon)
			for _, v in pairs(players) do
				Remote.MakeGui(v, "Notification", {
					Title = title;
					Message = message;
					Time = tim;
					Icon = server.MatIcons[icon or "Info"];
				})
			end
		end;

		MakeWeld = function(a, b)
			local weld = service.New("ManualWeld", a)
			weld.Part0 = a
			weld.Part1 = b
			weld.C0 = a.CFrame:inverse() * b.CFrame
			return weld
		end;

		SetLighting = function(prop,value)
			if service.Lighting[prop]~=nil then
				service.Lighting[prop] = value
				Variables.LightingSettings[prop] = value
				for _, p in pairs(service.GetPlayers()) do
					Remote.SetLighting(p, prop, value)
				end
			end
		end;

		LoadEffects = function(plr)
			for i,v in pairs(Variables.LocalEffects) do
				if (v.Part and v.Part.Parent) or v.NoPart then
					if v.Type == "Cape" then
						Remote.Send(plr,"Function","NewCape",v.Data)
					elseif v.Type == "Particle" then
						Remote.NewParticle(plr,v.Part,v.Class,v.Props)
					end
				else
					Variables.LocalEffects[i] = nil
				end
			end
		end;

		NewParticle = function(target,type,props)
			local ind = Functions.GetRandom()
			Variables.LocalEffects[ind] = {
				Part = target;
				Class = type;
				Props = props;
				Type = "Particle";
			}
			for i,v in ipairs(service.Players:GetPlayers()) do
				Remote.NewParticle(v,target,type,props)
			end
		end;

		RemoveParticle = function(target,name)
			for i,v in pairs(Variables.LocalEffects) do
				if v.Type == "Particle" and v.Part == target and (v.Props.Name == name or v.Class == name) then
					Variables.LocalEffects[i] = nil
				end
			end
			for i,v in ipairs(service.Players:GetPlayers()) do
				Remote.RemoveParticle(v,target,name)
			end
		end;

		UnCape = function(plr)
			for i,v in pairs(Variables.LocalEffects) do
				if v.Type == "Cape" and v.Player == plr then
					Variables.LocalEffects[i] = nil
				end
			end
			for i,v in pairs(service.GetPlayers()) do
				Remote.Send(v,"Function","RemoveCape",plr.Character)
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
					color = Color3.new(color[1],color[2],color[3])
				end

				local data = {
					Color = color;
					Parent = player.Character;
					Material = material;
					Reflectance = reflect;
					Decal = decal;
				}

				if isdon and Settings.DonorCapes and Settings.LocalCapes then
					Remote.Send(player,"Function","NewCape",data)
				else
					local ind = Functions.GetRandom()
					Variables.LocalEffects[ind] = {
						Player = player;
						Part = player.Character.HumanoidRootPart;
						Data = data;
						Type = "Cape";
					}
					for i,v in pairs(service.GetPlayers()) do
						Remote.Send(v,"Function","NewCape",data)
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
			for _,v in ipairs(enum:GetEnumItems()) do
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
						for _,v in pairs(part:GetChildren()) do
							for _,x in pairs(children) do
								if x:IsA("CharacterMesh") and x.BodyPart == v.BodyPart then
									x:Destroy()
								end
							end
							v:Clone().Parent = character
						end
					elseif rigType == "R15" then
						for _,v in pairs(part:GetChildren()) do
							local value = Functions.GetEnumValue(Enum.BodyPartR15, v.Name)
							if value then
								humanoid:ReplaceBodyPartR15(value, v:Clone())
							end
						end
					end
				end
			end
		end;

		GetJoints = function(character)
			local temp = {}
			for _,v in pairs(character:GetDescendants()) do
				if v:IsA("Motor6D") then
					temp[v.Name] = v -- assumes no 2 joints have the same name, hopefully this wont cause issues
				end
			end
			return temp
		end;

		LoadOnClient = function(player,source,object,name)
			if service.Players:FindFirstChild(player.Name) then
				local parent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild('PlayerGui', 15) or player:WaitForChild('Backpack')
				local cl = Core.NewScript('LocalScript',source)
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

			for arg in string.gmatch(msg,'([^'..key..']+)') do
				if #tab>=num then
					break
				elseif #tab>=num-1 then
					table.insert(tab,string.sub(msg,#str+1,#msg))
				else
					str = str..arg..key
					table.insert(tab,arg)
				end
			end

			return tab
		end;

		BasicSplit = function(msg,key)
			local ret = {}
			for arg in string.gmatch(msg,"([^"..key.."]+)") do
				table.insert(ret,arg)
			end
			return ret
		end;

		CountTable = function(tab)
			local num = 0
			for i in pairs(tab) do
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
			for _, v in ipairs(workspace:GetChildren()) do
				if v.ClassName == "Tool" or v.ClassName == "HopperBin" or v:IsA("Accessory") or v:IsA("Accoutrement") or v.ClassName == "Hat" then
					v:Destroy()
				end
			end
		end;

		RemoveSeatWelds = function(seat)
			if seat ~= nil then
				for i,v in ipairs(seat:GetChildren()) do
					if v:IsA("Weld") then
						if v.Part1 ~= nil and v.Part1.Name == "HumanoidRootPart" then
							v:Destroy()
						end
					end
				end
			end
		end;

		GrabNilPlayers = function(name)
			local AllGrabbedPlayers = {}
			for i,v in pairs(service.NetworkServer:GetChildren()) do
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

		Shutdown = function(reason)
			Functions.Message(Settings.SystemTitle, "The server is shutting down...", service.Players:GetPlayers(), false, 5)
			wait(1)

			service.Players.PlayerAdded:Connect(function(player)
				player:Kick("Server Shutdown\n\n".. tostring(reason or "No Reason Given"))
			end)

			for _, v in ipairs(service.Players:GetPlayers()) do
				v:Kick("Server Shutdown\n\n" .. tostring(reason or "No Reason Given"))
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
					--[[
					if Admin.CheckDonor(plr) and (Settings.DonorPerks or Admin.GetLevel(plr)>=4) then
						local gear=service.InsertService:LoadAsset(57902997):GetChildren()[1]
						if not plr.Backpack:FindFirstChild(gear.Name..'DonorTool') then
							gear.Name=gear.Name..'DonorTool'
							gear.Parent=plr.Backpack
						else
							gear:Destroy()
						end
					end --]]
				end
			end
		end;

		CheckMatch = function(check,match)
			if check == match then
				return true
			elseif type(check) == "table" and type(match) == "table" then
				local good = false
				local num = 0
				for k,m in pairs(check) do
					if m == match[k] then
						good = true
					else
						good = false
						break
					end
					num = num+1
				end

				if good and num == Functions.CountTable(check) then
					return true
				end
			end
		end;

		DSKeyNormalize = function(intab, reverse)
			local tab = {}

			if reverse then
				for i,v in pairs(intab) do
					if tonumber(i) then
						tab[tonumber(i)] = v;
					end
				end
			else
				for i,v in pairs(intab) do
					tab[tostring(i)] = v;
				end
			end

			return tab;
		end;

		GetIndex = function(tab,match)
			for i,v in pairs(tab) do
				if v==match then
					return i
				elseif type(v)=="table" and type(match)=="table" then
					local good = false
					for k,m in pairs(v) do
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
			local newCharacterModel: Model = service.Players:CreateHumanoidModelFromDescription(HumanoidDescription, rigType)
			local Animate: BaseScript = newCharacterModel.Animate

			newCharacterModel.Humanoid.DisplayName = Humanoid.DisplayName
			newCharacterModel.Name = plr.Name

			local oldCFrame = plr.Character and plr.Character:GetPivot() or CFrame.new()

			if plr.Character then
				plr.Character:Destroy()
				plr.Character = nil
			end
			plr.Character = newCharacterModel

			newCharacterModel:PivotTo(oldCFrame)
			newCharacterModel.Parent = workspace

			-- hacky way to fix other people being unable to see animations.
			for _=1,2 do
				if Animate then
					Animate.Disabled = not Animate.Disabled
				end
			end

			return newCharacterModel
		end;

		CreateClothingFromImageId = function(clothingtype, Id)
			local Clothing = Instance.new(clothingtype)
			Clothing.Name = clothingtype
			Clothing[clothingtype == "Shirt" and "ShirtTemplate" or clothingtype == "Pants" and "PantsTemplate" or clothingtype == "ShirtGraphic" and "Graphic"] = string.format("rbxassetid://%d", Id)
			return Clothing
		end;

		ParseColor3 = function(str: string)
			-- Handles BrickColor and Color3
			if not str then return end

			local color = {}
			for s in str:gmatch("[%d]+") do
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

		ParseBrickColor = function(str: string)
			if not str then return end

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
		end;
	};
end
