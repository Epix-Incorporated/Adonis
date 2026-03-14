--[[
	Format example for Join Messages:

		Messages = {
			"This is a message using the defaults!";
			{
				Title = "Message title";
				Message = "Message body";
				Time = 10;
				Icon = "rbxassetid://7510999669";
				Level = 300;
			};
		}

		Messages are shown to HeadAdmins+ (300) by default but tables can define a different minimum level via .Level
--]]

return {
	Messages = {
		-- {
		-- 	Title = "Message title";
		-- 	Message = "Message body";
		-- 	Time = 10;
		-- 	Icon = "rbxassetid://7510999669";
		-- 	Level = 300;
		-- };
	};	-- A list of notifications shown on join. Messages can either be strings or tables.
};