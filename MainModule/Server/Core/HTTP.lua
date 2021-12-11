server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// HTTP
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;

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

		HTTP.Trello.API = require(server.Deps.TrelloAPI)

		--// Trello updater
		if Settings.Trello_Enabled then
			service.StartLoop("TRELLO_UPDATER", Settings.HttpWait, HTTP.Trello.Update, true)
		end

		HTTP.Init = nil;
		Logs:AddLog("Script", "HTTP Module Initialized")
	end;

	server.HTTP = {
		Init = Init;
		Service = service.HttpService;
	--	HttpEnabled = pcall(service.HttpService.GetAsync, service.HttpService, "https://google.com");
		HttpEnabled = pcall(service.HttpService.GetAsync, service.HttpService, "http://www.google.com/robots.txt");
		LoadstringEnabled = pcall(loadstring,"");

		CheckHttp = function()
			return server.HTTP.HttpEnabled
		end;

		WebPanel = {
			Moderators = {};
			Admins = {};
			HeadAdmins = {};
			Creators = {};
			Mutes = {};
			Bans = {};
			Blacklist = {};
			Whitelist = {};
		};

		Trello = {
			Helpers = {};
			Moderators = {};
			Admins = {};
			HeadAdmins = {};
			Creators = {};
			Mutes = {};
			Bans = {};
			Music = {};
			InsertList = {};
			Blacklist = {};
			Whitelist = {};
			PerformedCommands = {};

			Update = function()
				if not Settings.Trello_Enabled then
					return;
				end

				if not HTTP.CheckHttp() then
					--HTPP.Trello.Bans = {'Http is not enabled! Cannot connect to Trello!'}
					warn('Http is not enabled! Cannot connect to Trello!')
				else
					local admins, mods, HeadAdmins, creators = {}, {}, {}, {}
					local bans = {}
					local mutes = {}
					local music = {}
					local whitelist = {}
					local blacklist = {}
					local insertlist = {}
					local boards = {}
					local customranks = {}

					local function grabData(board)
						local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
						if not trello then warn("Unable to fetch Trello table for data. (Make sure to lessen down HTTP Requests or to increase the trello HttpWait)") return end;

						local oldListObj = trello.getListObj;
						trello.getListObj = function(...)
							local vargs = table.pack(...)
							return select(2, service.Queue("TrelloCall", function()
								wait(10/60)
								return oldListObj(table.unpack(vargs, 1, vargs.n))
							end, 30, true))
						end

						local lists = trello.getListsAndCards(board)
						local banList = trello.getListObj(lists,{"Banlist","Ban List","Bans"})
						local commandList = trello.getListObj(lists,{"Commands","Command List"})
						local adminList = trello.getListObj(lists,{"Admins","Admin List","Adminlist"})
						local modList = trello.getListObj(lists,{"Moderators","Moderator List","Moderatorlist","Modlist","Mod List","Mods"})
						local creatorList = trello.getListObj(lists,{"Creators","Creator List","Creatorlist","Place Owners"})
						local ownerList = trello.getListObj(lists,{"Owners", "HeadAdmins", "HeadAdmin List","Owner List","Ownerlist"})
						local musicList = trello.getListObj(lists,{"Music","Music List","Musiclist","Songs"})
						local insertList = trello.getListObj(lists,{"InsertList","Insert List","Insertlist","Inserts","ModelList","Model List","Modellist","Models"})
						local permList = trello.getListObj(lists,{"Permissions","Permission List","Permlist"})
						local muteList = trello.getListObj(lists,{"Mutelist","Mute List"})
						local bList = trello.getListObj(lists,{"Blacklist"})
						local wList = trello.getListObj(lists,{"Whitelist"})

						local function getNames(list, targTab)
							if list and list.id then
								local cards = list.cards or trello.getCards(list.id)
								for l,k in pairs(cards) do
									table.insert(targTab, k.name)
								end
							end
						end

						getNames(banList, bans);
						getNames(creatorList , creators);
						getNames(modList, mods);
						getNames(adminList, admins)
						getNames(ownerList, HeadAdmins);
						getNames(muteList, mutes);
						getNames(bList, blacklist);
						getNames(wList, whitelist);

						if musicList then
							local cards = musicList.cards or trello.getCards(musicList.id)
							for l,k in pairs(cards) do
								if string.match(k.name, '^(.*):(.*)') then
									local a,b=string.match(k.name, '^(.*):(.*)')
									table.insert(music,{Name = a,ID = tonumber(b)})
								end
							end
						end

						if insertList then
							local cards = insertList.cards or trello.getCards(insertList.id)

							for _, k in pairs(cards) do
								if string.match(k.name, '^(.*):(.*)') then
									local a,b=string.match(k.name, '^(.*):(.*)')
									table.insert(insertlist,{Name = a,ID = tonumber(b)})
								end
							end
						end

						if permList then
							local cards = permList.cards or trello.getCards(permList.id)
							for _, k in pairs(cards) do
								local com,level = string.match(k.name, "^(.*):(.*)")
								if com and level then
									Admin.SetPermission(com,level)
								end
							end
						end

						if commandList then
							local cards = commandList.cards or trello.getCards(commandList.id)
							for _, k in pairs(cards) do
								if not HTTP.Trello.PerformedCommands[tostring(k.id)] then
									local cmd = k.name
									local placeid

									if string.sub(cmd, 1, 1) == "$" then
										placeid = string.match(string.sub(cmd, 2), ".%d+")
										cmd = string.sub(cmd, #placeid+2)
										placeid = tonumber(placeid)
									end
									if placeid and game.PlaceId ~= placeid then return end

									Admin.RunCommand(cmd)
									HTTP.Trello.PerformedCommands[tostring(k.id)] = true

									Logs.AddLog(Logs.Script,{
										Text = "Trello command executed";
										Desc = cmd;
									})

									if Settings.Trello_Token ~= "" then
										pcall(trello.makeComment,k.id,"Ran Command: "..cmd.."\nPlace ID: "..game.PlaceId.."\nServer Job Id: "..game.JobId.."\nServer Players: "..#service.GetPlayers().."\nServer Time: "..service.FormatTime())
									end
								end
							end
						end
						
						--// Load all custom ranks; see if they exist in ranks and see if they are on the trello
						--// Due to multiple boards; going to set them to the internal ranks before setting them to the end one
						--// This will let multiple boards combine one rank into one
						for _,list in pairs(lists) do 
							--// Make sure it exists as a custom rank & is not one of the four main ranks
							if list and list.name and Settings.Ranks[list.name] and not table.find({"Moderators", "Admins", "HeadAdmins", "Creators"}, list.name) then 
								local Users = {}
								local TrelloRankName = string.format("[Trello] %s", server.Functions.Trim(list.name))
								if not customranks[TrelloRankName] then
									customranks[TrelloRankName] = {
										Level = Settings.Ranks[list.name].Level or 1;
										Users = Users
									}
								end
								Users = customranks[TrelloRankName].Users 
								getNames(list, Users)
							end
						end
						
					end

					for i,v in pairs(Settings.Trello_Secondary) do table.insert(boards,v) end
					if Settings.Trello_Primary~="" then table.insert(boards,Settings.Trello_Primary) end
					for i,v in pairs(boards) do
						local ran,err = pcall(grabData,v)
						if not ran then
							warn(tostring(err))
						end
					end

					if #bans>0 then HTTP.Trello.Bans = bans end
					if #creators>0 then HTTP.Trello.Creators = creators end
					if #admins>0 then HTTP.Trello.Admins = admins end
					if #mods>0 then HTTP.Trello.Moderators = mods end
					if #HeadAdmins>0 then HTTP.Trello.HeadAdmins = HeadAdmins end
					if #music>0 then HTTP.Trello.Music = music end
					if #insertlist>0 then HTTP.Trello.InsertList = insertlist end
					if #mutes>0 then HTTP.Trello.Mutes = mutes end
					if #blacklist>0 then HTTP.Trello.Blacklist = blacklist end
					if #whitelist>0 then HTTP.Trello.Whitelist = whitelist end

					Settings.Ranks["[Trello] Creators"] = {
						Level = Settings.Ranks.Creators.Level;
						Users = HTTP.Trello.Creators or {};
					}

					Settings.Ranks["[Trello] HeadAdmins"] = {
						Level = Settings.Ranks.HeadAdmins.Level;
						Users = HTTP.Trello.HeadAdmins or {};
					}

					Settings.Ranks["[Trello] Admins"] = {
						Level = Settings.Ranks.Admins.Level;
						Users = HTTP.Trello.Admins or {};
					}

					Settings.Ranks["[Trello] Moderators"] = {
						Level = Settings.Ranks.Moderators.Level;
						Users = HTTP.Trello.Moderators or {};
					}
					
					--// Load up and custom ranks that were fetched from Trello
					for rank,info in pairs(customranks) do 
						--// Don't set any of your hardcoded ranks to have the IsExternal value to true, it'll delete the rank if you're not careful!
						info.IsExternal = true 
						Settings.Ranks[rank] = info
					end
					
					--// Clear any rcustom anks that were not fetched from Trello
					for name,rank in pairs(Settings.Ranks) do 
						if rank.IsExternal and not customranks[name] then 
							Settings.Ranks[name] = nil
						end
					end

					Variables.Blacklist.Lists.Trello = blacklist;
					Variables.Whitelist.Lists.Trello = whitelist;

					for i,v in pairs(service.GetPlayers()) do
						if Admin.CheckBan(v) then
							v:Kick(Variables.BanMessage)
						end

						if v and v.Parent then
							for ind,admin in pairs(HTTP.Trello.Mutes) do
								if Admin.DoCheck(v,admin) then
									Remote.LoadCode(v,[[service.StarterGui:SetCoreGuiEnabled("Chat",false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
								end
							end
						end

						Admin.UpdateCachedLevel(v)
					end

					Logs.AddLog(Logs.Script,{
						Text = "Updated Trello Data";
						Desc = "Data was retreived from Trello";
					})
				end
			end;
		};
	};
end
