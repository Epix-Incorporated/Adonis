server = nil

--// Commands
return function(Vargs)
	local server = Vargs.Server;

	local Commands, Admin, Logs
	local function Init()
		Admin = server.Admin;
		Logs = server.Logs;
		Commands = server.Commands;

		--// Automatic New Command Caching and Ability to do server.Commands[":ff"]
		setmetatable(Commands, {
			__index = function(self, ind)
				local targInd = Admin.CommandCache[ind:lower()]
				if targInd then
					return rawget(Commands, targInd)
				end
			end;

			__newindex = function(self, ind, val)
				rawset(Commands, ind, val)
				if val and type(val) == "table" and val.Commands and val.Prefix then
					for i,cmd in next,val.Commands do
						Admin.CommandCache[(val.Prefix..cmd):lower()] = ind
					end
				end
			end;
		})

		Logs:AddLog("Script", "Commands Module Initialized")
	end;

	server.Commands = {
		Init = Init;
	};
end
