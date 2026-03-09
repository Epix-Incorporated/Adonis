--[[
	--------------------------------------------
	--                 Adonis                 --
	--          By Epix Incorporated          --
	--------------------------------------------
	--  Not Everything is so Black and White  --
	--------------------------------------------

	A lot of time goes into maintaining and updating Adonis. If you enjoy using Adonis,
	please consider leaving us a review, as your feedback means a lot:
	https://create.roblox.com/store/asset/7510622625/


	---------------------
	-- Getting started --
	---------------------

	- It's recommend you store Adonis_Loader in 'ServerScriptService'.
	- Configure Ranks in Config -> Settings -> Ranks module.
	- Configure general settings like prefixes, command settings, etc in Config -> Settings -> General module.
	- You can find the rest of the settings modules at Config -> Settings. They are sorted by categories.
	- You can create custom commands and plugins in Config -> Plugins.


	---------------------
	-- Basic luau info --
	---------------------

	This is only here to help you when editing settings so you understand how they work
	and don't break something.

	In case you don't know what Luau is; Luau is the scripting language Roblox uses...
	so every script you see (such as this one) and pretty much any code on Roblox is
	written in Luau.

	Anything that looks like {} is known as a table.
	Tables contain things, like the Luau version of a box.
	An example of a table would be setting = {"John", "Mary", "Bill"}
	You can have tables inside of tables, such in the case of setting = {{Group = 1234, Rank = 123, Type = "Admin"}}
	Just like real boxes, tables can contain pretty much anything including other tables.

	Note: Commas (,) as well as semicolons (;) can both be used to separate things inside a table.

	Anything that looks like "Bob" is what's known as a string. Strings
	are basically plain text; setting = "Bob" would be correct however
	setting = Bob would not; because if it's not surrounded by quotes Luau will think
	that Bob is a variable; Quotes indicate something is a string and therefore not a variable/number/code

	Numbers do not use quotes. setting = 56

	This block of text you are reading is called a comment. It's like a message
	from the programmer to anyone who reads their stuff. Anything in a comment will
	not be seen by Luau when the script is run.

	Comments can be made by putting -- at the start of a line

	For more information about roblox luau visit: https://create.roblox.com/docs/luau
--]]