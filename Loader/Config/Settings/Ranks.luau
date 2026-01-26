-------------------------------
-- Scroll down for settings  --
-------------------------------

--[[
	How to add administrators:
		Below are the administrator permission levels/ranks (Mods, Admins, HeadAdmins, Creators, StuffYouAdd, etc)
		Simply place users into the respective "Users" table for whatever level/rank you want to give them.

		Format example:

			Ranks = {
				["Moderators"] = {
					Level = 100;
					Users = {
						"Username"; -- Example: "roblox"
						"Username:UserId"; -- Example: "roblox:1"
						UserId; -- Example: 1
						"Group:GroupId:GroupRank"; -- Example: "Group:123456:50"
						"Group:GroupId"; -- Example: "Group:123456"
						"Item:ItemID"; -- Example: "Item:123456"
						"GamePass:GamePassID"; -- Example: "GamePass:123456"
						"Subscription:SubscriptionId"; -- Example: "Subscription:123456"
					}
				}
			}

		If you use custom ranks, existing custom ranks will be imported with a level of 1.
		Add all new CustomRanks to the table below with the respective level you want them to be.

	NOTE: Changing the level of built-in ranks (Moderators, Admins, HeadAdmins, Creators)
	will also change the permission level for any built-in commands associated with that rank.
--]]

--------------------
-- RANKS SETTINGS --
--------------------

return {
	Ranks = {
		["Moderators"] = {
			Level = 100;
			Users = {
				-- Add users here
			};
		};

		["Admins"] = {
			Level = 200;
			Users = {
				-- Add users here
			};
		};

		["HeadAdmins"] = {
			Level = 300;
			Users = {
				-- Add users here
			};
		};

		["Creators"] = {
			Level = 900; -- Anything 900 or higher will be considered a creator and will bypass all perms & be allowed to edit settings in-game.
			Users = {
				-- Add users here (Also, don't forget quotations and all that)
			};
		};
	};
};