--[[
	Use the below table to define "pre-set" command aliases

	Format example:

		Aliases = {
			[":alias <arg1> <arg2> ..."] = ":command <arg1> <arg2> ..."
		}
]]

------------------------------
-- COMMAND ALIASES SETTINGS --
------------------------------

return {
	Aliases = {
		-- [":examplealias <player> <fireColor>"] = ":ff <player> | :fling <player> | :fire <player> <fireColor>" -- Order arguments appear in alias string determines their required order in the command message when ran later
	};
};