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
	local env = GetEnv(nil, { script = script })
	setfenv(1, env)

	server = Vargs.Server

	local Commands, Logs, Remote = server.Commands, server.Logs, server.Remote

	Commands.TestError = {
		Hidden = true,
		Prefix = ":",
		Commands = { "debugtesterror" },
		Args = { "optional type (error/assert)", "optional message" },
		Description = "Test Error",
		NoFilter = true,
		AdminLevel = "Creators",
		Function = function(plr: Player, args: { string })
			Remote.Send(plr, "TestError")
			Routine(function()
				plr.Bobobobobobobo.Hi = 1
			end)
			if not args[1] then
				error("This is an intentional test error")
			elseif args[1]:lower() == "error" then
				error(args[2])
			elseif args[1]:lower() == "assert" then
				assert(false, args[2])
			end
		end,
	}

	Commands.TestBigList = {
		Hidden = true,
		Prefix = ":",
		Commands = { "debugtestbiglist" },
		Args = {},
		Description = "Test Big List",
		AdminLevel = "Creators",
		Function = function(plr: Player)
			local list = {}

			for i = 1, 5000 do
				table.insert(list, { Text = i })
			end

			Remote.MakeGui(plr, "List", {
				Title = "DebugBigList_PageSize250",
				Table = list,
				Font = "Code",
				PageSize = 250,
				Size = { 500, 400 },
			})

			Remote.MakeGui(plr, "List", {
				Title = "DebugBigList_PageSize100",
				Table = list,
				Font = "Code",
				PageSize = 100,
				Size = { 500, 400 },
			})

			Remote.MakeGui(plr, "List", {
				Title = "DebugBigList_PageSize25",
				Table = list,
				Font = "Code",
				PageSize = 25,
				Size = { 500, 400 },
			})
		end,
	}

	Commands.TestGet = {
		Prefix = ":",
		Commands = { "debugtestget" },
		Args = {},
		Description = "Remote Test",
		Hidden = true,
		AdminLevel = "Creators",
		Function = function(plr: Player)
			local tack = time()
			print(tack)
			print(Remote.Get(plr, "Test"))
			local tab = {
				{
					Children = {
						{ Class = "sdfhasdfjkasjdf" },
					},
					{ { Something = "hi" } },
				},
			}
			local _, ret = Remote.Get(plr, "Test", tab)
			if ret then
				print(ret)
				for i1, v1 in pairs(ret) do
					print(i1, v1)
					for i2, v2 in pairs(v1) do
						print(i2, v2)
						for i3, v3 in pairs(v2) do
							print(i3, v3)
							for i4, v4 in pairs(v3) do
								print(i4, v4)
							end
						end
					end
				end
			end
			print(time() - tack)
			print("TESTING EVENT")
			Remote.MakeGui(plr, "Settings", {
				IsOwner = true,
			})
			local testColor = Remote.GetGui(plr, "ColorPicker", { Color = Color3.new(1, 1, 1) })
			print(testColor)
			local ans, _ =
				Remote.GetGui(plr, "YesNoPrompt", {
					Icon = server.MatIcons["Bug report"],
					Question = "Is this a test question?",
				}), Remote.NewPlayerEvent(plr, "TestEvent", function(...)
					print("EVENT WAS FIRED; WE GOT:")
					print(...)
					print("THAT'D BE ALL")
				end)
			print(`PLAYER ANSWER: {tostring(ans)}`)
			task.wait(0.5)
			print("SENDING REMOTE EVENT TEST")
			Remote.Send(plr, "TestEvent", "TestEvent", "hi mom I went thru the interwebs")
			print("SENT")
		end,
	}

	Logs:AddLog("Script", "Debug Module Loaded")
end
