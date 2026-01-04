---------------------
-- _G API SETTINGS --
---------------------

return {
	G_API = true;					-- If true, allows other server scripts to access certain functions described in the API module through _G.Adonis
	G_Access = false;				-- If enabled, allows other scripts to access Adonis using _G.Adonis.Access; Scripts will still be able to do things like _G.Adonis.CheckAdmin(player)
	G_Access_Key = "Example_Key";	-- Key required to use the _G access API; Example_Key will not work for obvious reasons
	G_Access_Perms = "Read";		-- Access perms
	Allowed_API_Calls = {
		Client = false;				-- Allow access to the Client (not recommended)
		Settings = false;			-- Allow access to settings (not recommended)
		DataStore = false;			-- Allow access to the DataStore (not recommended)
		Core = false;				-- Allow access to the script's core table (REALLY not recommended)
		Service = false;			-- Allow access to the script's service metatable
		Remote = false;				-- Communication table
		HTTP = false;				-- HTTP-related things like Trello functions
		Anti = false;				-- Anti-Exploit table
		Logs = false;
		UI = false;					-- Client UI table
		Admin = false;				-- Admin related functions
		Functions = false;			-- Functions table (contains functions used by the script that don't have a subcategory)
		Variables = true;			-- Variables table
		API_Specific = true;		-- API Specific functions
	};
};