-------------------------------
-- Scroll down for settings  --
-------------------------------

--[[
	The Trello abilities of the script allow you to manage lists and permissions via a Trello board.
	The following will guide you through the process of setting up a board:

		1. Sign up for an account at trello
		2. Create a new board
		3. Get the board ID
		4. Set Trello_Primary to your board ID
		5. Set Trello_Enabled to true
		6. Congrats! The board is ready to be used
		7. Create a list and add cards to it

	You can view lists in-game using :viewlist ListNameHere

	Lists:
		Moderators			- Card Format: Same as settings.Moderators
		Admins				- Card Format: Same as settings.Admins
		HeadAdmins			- Card Format: Same as settings.HeadAdmins
		Creators			- Card Format: Same as settings.Creators
		Banlist				- Card Format: Same as settings.Banned
		Mutelist			- Card Format: Same as settings.Muted
		Blacklist			- Card Format: Same as settings.Blacklist
		Whitelist			- Card Format: Same as settings.Whitelist
		Permissions			- Card Format: Same as settings.Permissions
		Music				- Card Format: SongName:AudioID
		Commands			- Card Format: Command  (eg. :ff bob)

	Card format refers to how card names should look

	It is recommended you setup secrets in your experiences settings on the creator dashboard for
	the Trello_AppKey and Trello_Token variables.

	The following guide will help you through the process of setting set up secrets:

		1. Go to https://create.roblox.com/docs/cloud-services/secrets#add-secrets and follow the guide on
		   how to add a secret (not local secret).

		2. Steps for the first secret: Trello_AppKey
		3. Set the Name of the first secret to: Adonis_Trello_AppKey
		4. Set the Domain of the first secret to the trello domain
		5. Set the Value of the first secret to: your trello AppKey
		6. Set the Trello_AppKey variable to: game:GetService("HttpService"):GetSecret("Adonis_Trello_AppKey")

		7. Steps for the second secret: Trello_Token
		8. Set the Name of the second secret to: Adonis_Trello_Token
		9. Set the Domain of the second secret to the trello domain
		10. Set the Value of the second secret to: your trello Token
		11. Set the Trello_AppKey variable to: game:GetService("HttpService"):GetSecret("Adonis_Trello_Token")

	You can get your trello token at: /1/connect?name=Trello_API_Module&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE
--]]

---------------------
-- TRELLO SETTINGS --
---------------------

return {
	Trello_Enabled = false;		-- Are the Trello features enabled?
	Trello_Primary = "";		-- Primary Trello board
	Trello_Secondary = {};		-- Secondary Trello boards (read-only)		Format: {"BoardID";"BoardID2","etc"}
	Trello_AppKey = "";			-- Your Trello AppKey
	Trello_Token = "";			-- Trello token (DON'T SHARE WITH ANYONE!)    Get API key: /1/connect?name=Trello_API_Module&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE
	Trello_HideRanks = false;	-- If true, Trello-assigned ranks won't be shown in the admins list UI (accessed via :admins)
};