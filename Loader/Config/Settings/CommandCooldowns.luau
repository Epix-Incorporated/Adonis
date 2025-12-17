--[[
	Format example:

		["commandname"] = {
			Player = 0; -- (optional) Per player cooldown in seconds
			Server = 0; -- (optional) Per server cooldown in seconds
			Cross = 0; -- (optional) Global cooldown in seconds
		}

		Make sure to include the prefix infront of the command name.
]]

--------------------------------
-- COMMAND COOLDOWNS SETTINGS --
--------------------------------

return {
	CommandCooldowns = {
		-- [":logs"] = {
		-- 	Player = 5; -- 5 seconds
		-- }
	}
}