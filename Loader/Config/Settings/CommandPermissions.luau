--[[
	Format example:

		Permissions = {
			"CommandName:NewLevel";
			"CommandName:CustomRank1,CustomRank2,CustomRank3";
		};
]]

----------------------------------
-- COMMAND PERMISSIONS SETTINGS --
----------------------------------

return {
	Permissions = {
		-- "ff:HeadAdmins";	-- Changes :ff to HeadAdmins and higher (HeadAdmins = Level 300 by default)
		-- "kill:300";		-- Changes :kill to level 300 and higher (Level 300 = HeadAdmins by default)
		-- "ban:200,300";	-- Makes it so :ban is only usable by levels 200 and 300 specifically (nothing higher or lower or in between)
	};
};