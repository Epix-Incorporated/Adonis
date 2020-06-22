--[[

	Current Documentation:
	https://github.com/Sceleratis/Adonis/wiki
	
	
	
	------------------------------------------------------
	The following documentation is old and likely outdated.
	Documentation updates will be made to the GitHub wiki.
	
	--// INCOMPLETE; WILL FINISH LATER
	
	Adonis API Documentation for developers
	
	Require:
		Adonis' MainModule can be loaded by using require(359948692)()
			- This allows you to require the module via the console and test things per server
			  without having to add the loader and save the game;
			- If you want to edit things like settings, themes, or plugins you can do the following:
				local data = {
					Settings = {
						Admins = {"SomeGuy"}
					};
					Themes = {
						game.Workspace.ThemeFolder1;
						game.Workspace.ThemeFolder2;
					};
					Plugins = {
						game.Workspace.Plugin1;
						game.Workspace.Plugin2;
				}
				require(359948692)(data)
						
			- The MainModule will use a set of default settings for any setting not provided
	
	
	_G.Adonis: 
		Read-only table in _G that can be used to access certain things in Adonis from other server scripts
		
		Functions:
			_G.Adonis.Access(accessKey, serverSubTable)
				- Returns a read-only version of a server subtable; allowing you to use all of it's functions
				- Settings can be changed in the Settings module for what to allow access to and to change if scripts can read/write
			
			_G.Adonis.CheckAdmin(player) 
				- Returns true if the player is an Adonis admin
				
			_G.Adonis.GetLevel(player)
				- Returns a player's admin level
				- Levels:
					0 - Player
					1 - Moderator
					2 - Admin
					3 - Owner
					4 - Creators (basically place owners)
					5 - Place owner (the person who actually owns the place)
					
			_G.Adonis.CheckDonor(player)
				- Returns true if the player is an Adonis donor
				
			_G.Adonis.CheckAgent(player) 
				- Returns true if the player is a Trello agent
				
			_G.Adonis.SetLighting(property, value)
				- Sets the lighting property for the server and all clients
				- Mainly used for local lighting to update all clients
				
			_G.Adonis.SetPlayerLighting(player, property, value)
				- Sets the lighting property for a specific player
				- Requires LocalLighting be enabled in settings in order to workspace
				
			_G.Adonis.NewParticle(part, type, properties)
				- Lets you create local particles on the target part with properties defined in the properties table
				- Type can be any classname that is place into a brick and has the .Enabled property
				- Part must be a weldable part
			_G.Adonis.RemoveParticle(part, name)
				- Removes local particles named <name> for all players from <part>
				
			_G.Adonis.NewLocal(player, type, properties, newParent)
				- Creates Instance.new(type) with properties <properties table> 
				  in local parent newParent for player
				- newParents: "Camera", "LocalContainer", "PlayerGui"
				- Defaults to LocalContainer if no parent is given 
			
			_G.Adonis.MakeLocal(player, object, newParent) 
				- Localizes object for player by moving it to newParent (a local container)
				- newParents: "Camera", "LocalContainer", "PlayerGui"
				- Defaults to LocalContainer if no parent is given 
			
			_G.Adonis.MoveLocal(player, object, oldParent, newParent) 
				- Same as MakeLocal except moves an existing local based on name/object provided
				
			_G.Adonis.RemoveLocal(player, object, oldParent) 
				- Finds and removes object from oldParent (a local container) 
				  for player
			
	
	Service:
		Metatable used to access ROBLOX services and some utility functions
		For example: service.Players
		
		Extra functions:
			service.Delete(object) 
				- Uses service.Debris to delete an object; Works on some RobloxLocked objects
			
			service.HookEvent(eventName, function) 
				- Hooks events fired by service.FireEvent; Useful for running PlayerAdded after the admin finishes loading them
				- Returns a table conaining the UnHook() function to "unhook" the event
			
			service.FireEvent(eventName, params) 
				- Fires all functions for a specific event added by service.HookEvent
			
			service.StartLoop(loopName, delay, function) 
				- Starts an infinite loop that can be stopped using service.StopLoop(loopName)
				- Delay accepts a number, "Heartbeat", or "Stepped"
			
			service.StopLoop(loopName) 
				- Stops a loop started by service.StartLoop
	
			service.ReadOnly(table) 
				- Returns a read-only version of the table supplied to it
				
			service.GetPlayers(commandPlayer, nameString, dontError, isServer)
				- Finds players via their name/modifiers provided in nameString
					- If no args are given it will return a list of all players connected to the server, not just in game.Players
			
			Events:
				service.Events.eventName
					- Returns a table containing :connect and :disconnect
					- Basically the same as service.HookEvent but more like a ROBLOX event
					
				Event List:
					PlayerAdded
						- Runs after Adonis client finishes loading
						- Returns player
					
					PlayerRemoving 
						- Fired when a player leaves
						- Returns player
						
					NetworkAdded
						- Fired when a new NetworkClient appears
						- Returns NetworkClient
					
					NetworkRemoved
						- Fired when a NetworkClient is removed
						- Returns NetworkClient
						
					PlayerChatted
						- Fired when player chats; Works with anything that fires server.Process.Chat; Including Adonis' custom chat
						- Returns player, msg
						
					CharacterAdded
						- Fired when character loads; Does not use player.CharacterAdded
						- Returns player
						
					ErrorMessage 
						- Fired when an error is found
						- Returns message, trace, script
					
					Output
						- Fired when anything prints
						- Returns message, type
						
					CommandRan
						- Fired when a command is ran
						- Returns msg, command, args, table, index, ran, error 
						
						- msg is the message the player chatted
						- command is the command pulled from msg
						- args is a table containing supplied command arguments
						- table is the command table
						- index is it's position in server.Commands
						- ran returns true is the command ran successfully
						- error returns any errors from the command function
					
	Server: 
		Main script table containing most of the functions and variables used by the admin
		
		Subtables: 
			Logs
			Variables
			Core
			Remote
			Functions
			Process
			Admin
			HTTP
			Anti
			Commands
			Settings
	
--]]
