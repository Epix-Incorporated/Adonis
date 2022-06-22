server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil

--// This module is for stuff specific to debugging
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	Commands.TestError = {
		Hidden = true;
		Prefix = ":";
		Commands = {"debugtesterror"};
		Args = {"type","msg"};
		Description = "Test Error";
		NoFilter = true;
		AdminLevel = "Creators";
		Function = function(plr,args)
			--assert(args[1] and args[2],"Argument missing or nil")
			Remote.Send(plr, "TestError")
			Routine(function() plr.Bobobobobobobo.Hi = 1 end)
			if not args[1] then
				error("This is an intentional test error")
			elseif args[1]:lower() == "error" then
				error(args[2])
			elseif args[1]:lower() == "assert" then
				assert(false,args[2])
			end
		end;
	};

	Commands.TestBigList = {
		Hidden = true;
		Prefix = ":";
		Commands = {"debugtestbiglist"};
		Args = {};
		Description = "Test Big List";
		AdminLevel = "Creators";
		Function = function(plr,args)
			local list = {}

			for i = 1, 5000 do
				table.insert(list, {Text = i});
			end

			Remote.MakeGui(plr,"List",{
				Title = "DebugBigList_PageSize250",
				Table = list,
				Font = "Code",
				PageSize = 250;
				Size = {500, 400},
			})

			Remote.MakeGui(plr,"List",{
				Title = "DebugBigList_PageSize100",
				Table = list,
				Font = "Code",
				PageSize = 100;
				Size = {500, 400},
			})

			Remote.MakeGui(plr,"List",{
				Title = "DebugBigList_PageSize25",
				Table = list,
				Font = "Code",
				PageSize = 25;
				Size = {500, 400},
			})
		end;
	};

	Commands.TestGet = {
		Prefix = ":";
		Commands = {"debugtestget"};
		Args = {};
		Description = "Test Error";
		Hidden = true;
		AdminLevel = "Creators";
		Function = function(plr,args)
			local tack = time()
			print(tack)
			print(Remote.Get(plr,"Test"))
			local tab = {
				{
					Children = {
						{Class = "sdfhasdfjkasjdf"}
				};
					{{Something = "hi"}};
				}
			}
			local m, ret = Remote.Get(plr, "Test", tab)
			if ret then
				print(ret)
				for i,v in next, ret do
					print(i,v)
					for i,v in next,v do
						print(i,v)
						for i,v in next,v do
							print(i,v)
							for i,v in next,v do
								print(i,v)
							end
						end
					end
				end
			end
			print(time()-tack)
			print("TESTING EVENT")
			Remote.MakeGui(plr,"Settings",{
				IsOwner = true
			})
			local testColor = Remote.GetGui(plr,"ColorPicker",{Color = Color3.new(1,1,1)})
			print(testColor)
			local ans,event = Remote.GetGui(plr,"YesNoPrompt",{
				Question = "Is this a test question?";
			}), Remote.NewPlayerEvent(plr,"TestEvent",function(...)
				print("EVENT WAS FIRED; WE GOT:")
				print(...)
				print("THAT'D BE ALL")
			end)
			print("PLAYER ANSWER: "..tostring(ans))
			wait(0.5)
			print("SENDING REMOTE EVENT TEST")
			Remote.Send(plr,"TestEvent","TestEvent","hi mom I went thru the interwebs")
			print("SENT")
		end;
	};

--[[
	Commands.DebugLoadstring = {
		Prefix = ":";
		Commands = {"debugloadstring";};
		Args = {"code";};
		Description = "DEBUG LOADSTRING";
		Hidden = true;
		NoFilter = true;
		AdminLevel = "Creators";
		Function = function(plr,args)
			--error("Disabled", 0)
			local ans = Remote.GetGui(plr, "YesNoPrompt", {
				Icon = server.MatIcons.Warning;
				Question = "Are you sure you want to load this script into the server env?";
				Title = "Adonis DebugLoadstring";
				Delay = 5;
			})
			if ans == "Yes" then
				local func,err = Core.Loadstring(args[1],GetEnv())
				if func then
					func()
				else
					logError("DEBUG",err)
					Functions.Hint(err,{plr})
				end
			end
		end
	};
--]]
	Logs:AddLog("Script", "Debug Module Loaded");
end;
