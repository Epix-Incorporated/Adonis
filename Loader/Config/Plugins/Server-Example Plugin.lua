--[[
	SERVER PLUGINS' NAMES MUST START WITH "Server:" OR "Server-"
	CLIENT PLUGINS' NAMES MUST START WITH "Client:" OR "Client-"

	Plugins have full access to the server/client tables and most variables.

	You can use the MakePluginEvent to use the script instead of setting up an event.
	PlayerChatted will get chats from the custom chat and nil players.
	PlayerJoined will fire after the player finishes initial loading
	CharacterAdded will also fire after the player is loaded, it does not use the CharacterAdded event.

	service.Events.PlayerChatted(function(plr, msg)
		print(msg..' from '..plr.Name..' Example Plugin')
	end)

	service.Events.PlayerAdded(function(p)
		print(p.Name..' Joined! Example Plugin')
	end)

	service.Events.CharacterAdded(function(p)
		server.RunCommand('name',plr.Name,'BobTest Example Plugin')
	end)

--]]

return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service

	server.Commands.ExampleCommand = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"example"};	-- Commands
		Args = {"arg1"};	-- Command arguments
		Description = "Example command";	-- Command Description
		Hidden = true; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr,args)    -- Function to run for command
			print("HELLO WORLD FROM AN EXAMPLE COMMAND :)")
			print("Player supplied args[1] "..tostring(args[1]))
		end
	}
end
