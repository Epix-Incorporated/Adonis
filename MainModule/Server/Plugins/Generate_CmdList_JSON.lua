server = nil;
service = nil;

local enabled = false;

return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;
	
	local Core = server.Core;
	local Commands = server.Commands;
	
	if Core.DebugMode and enabled then
		wait(5)
		
		local list = {};
		local http = service.HttpService;
		
		for i,cmd in next,Commands do
			table.insert(list, {
				Index = i;
				Prefix = cmd.Prefix;
				Commands = cmd.Commands;
				Arguments = cmd.Args;
				AdminLevel = cmd.AdminLevel;
				Hidden = cmd.Hidden or false;
				NoFilter = cmd.NoFilter or false;
			})
		end
		
		warn("COMMANDS LIST JSON: ");
		print("\n\n".. http:JSONEncode(list) .."\n\n");
	end
end