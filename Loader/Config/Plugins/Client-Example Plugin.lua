return function(Vargs)
	local client, service = Vargs.Client, Vargs.Service

	--Acts the same as a server plugin but with client functions instead of server.
	--[[
	local window = client.UI.Make("Window",{
		Title = "Changing DataStore";
		Size = {700,300};
		Icon = "rbxassetid://357249130";
	})
	
	window:Add("ImageLabel",{
		Image = "rbxassetid://531490964";
	})
	
	--]]
end
