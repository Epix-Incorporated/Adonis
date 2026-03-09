-------------------------------
-- Scroll down for settings  --
-------------------------------

--[[
	Format example for Aliases:

		Aliases = {
			[":alias <arg1> <arg2> ..."] = ":command <arg1> <arg2> ..."
		}


	Format example for CommandCooldowns:

		CommandCooldowns = {
			[":commandname"] = {
				Player = 0; -- (optional) Per player cooldown in seconds
				Server = 0; -- (optional) Per server cooldown in seconds
				Cross = 0; -- (optional) Global cooldown in seconds
			}
		}

		Make sure to include the prefix infront of the command name.


	Format example for Permissions:

		Permissions = {
			"CommandName:NewLevel";
			"CommandName:CustomRank1,CustomRank2,CustomRank3";
		};
--]]

----------------------------------
-- COMMAND ADJUSTMENTS SETTINGS --
----------------------------------

return {
	Aliases = {
		-- [":examplealias <player> <fireColor>"] = ":ff <player> | :fling <player> | :fire <player> <fireColor>" -- Order arguments appear in alias string determines their required order in the command message when ran later
	};

	CommandCooldowns = {
		-- [":logs"] = {
		-- 	Player = 5; -- 5 seconds
		-- }
	};

	Permissions = {
		-- "ff:HeadAdmins";	-- Changes :ff to HeadAdmins and higher (HeadAdmins = Level 300 by default)
		-- "kill:300";		-- Changes :kill to level 300 and higher (Level 300 = HeadAdmins by default)
		-- "ban:200,300";	-- Makes it so :ban is only usable by levels 200 and 300 specifically (nothing higher or lower or in between)
	};
}