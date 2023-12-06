client,service = nil,nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local AdminLevel = data.AdminLevel
	local CanBan = data.CanBan
	local CanTimeBan = data.CanTimeBan
	local CanPermBan = data.CanPermBan
	local Tabbed
	local gTable
	
	local window = client.UI.Make("Window", {
		Name  = "Ban Menu";
		Title = "Ban Menu";
		Size  = {267, 250};
		Position = UDim2.new(0.5, -125, 0.5, -125);
		Icon = client.MatIcons["Gavel"];
		MinSize = {267,250};
		AllowMultiple = false;
		Walls = true;
		NoHide = true;
		NoClose = false;
		CanKeepAlive = true;
		SizeLocked = false;
		NoDrag = false;
	})
	
	if window then
		local tabFrame = window:Add("TabFrame",{
			Size = UDim2.new(1, -10, 1, -10);
			Position = UDim2.new(0, 5, 0, 5)
		})
		
		--// Server Ban
		do
			if CanBan then
				local tab,button = tabFrame:NewTab("Server Ban",{
					Text = "Server Ban"
				})

				local searchBar: TextBox = tab:Add("TextBox",{
					Size = UDim2.new(1, -10, 0, 20);
					Position = UDim2.new(0, 5, 0, 5);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
					BorderColor3 = Color3.new(0,0,0);
					TextColor3 = Color3.new(1, 1, 1);
					Text = "";
					PlaceholderText = `Search player`;
					TextStrokeTransparency = 0.8;
					ClearTextOnFocus = false;
				})
				
				local PossiblePlayers = tab:Add("ScrollingFrame",{
					Size = UDim2.new(1, -10, 0, 85);
					Position = UDim2.new(0, 5, 0, 27);
					BackgroundColor3 = Color3.new(20/255, 20/255, 20/255);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
					BorderColor3 = Color3.new(0,0,0);
					ZIndex = 5
				})
				
				local reasonFrame = tab:Add("Frame",{
					Size = UDim2.new(1, -10, 1, -65);
					Position = UDim2.new(0, 5, 0, 30);
					BackgroundColor3 = Color3.new(20/255, 20/255, 20/255);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
				})
				
				local reason = reasonFrame:Add("TextBox",{
					Size = UDim2.new(1, -10, 1, -10);
					Position = UDim2.new(0, 5, 0, 5);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					TextColor3 = Color3.new(1, 1, 1);
					Text = "";
					PlaceholderText = `Reason`;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					TextWrapped = true;
				})
				
				local unbanButton = tab:Add("TextButton",{
					Size = UDim2.new(.5, -10, 0, 25);
					Position = UDim2.new(0, 5, 1, -30);
					Text = "Unban";
					OnClick = function()
						client.Remote.Send("ProcessCommand",`{data.Prefix}unban {searchBar.Text}`)
					end,
				})
				
				local banButton = tab:Add("TextButton",{
					Size = UDim2.new(.5, -10, 0, 25);
					Position = UDim2.new(1, -5, 1, -30);
					Text = "Ban";
					AnchorPoint = Vector2.new(1,0);
					OnClick = function()
						client.Remote.Send("ProcessCommand",`{data.Prefix}ban {searchBar.Text} {reason.Text}`)
					end,
				})
				
				local function getPlayers()
					PossiblePlayers:ClearAllChildren()
					local ind = 0
					for i,v in pairs(game.Players:GetPlayers()) do
						local button:TextButton = PossiblePlayers:Add("TextButton",{
							Text = `{v.DisplayName} (@{v.Name})`;
							Size = UDim2.new(1, 0, 0, 25);
							Position = UDim2.new(0, 0, 0, 25*ind);
							ZIndex = 5
						})
						
						button.MouseButton1Down:Connect(function()
							searchBar.Text = v.Name
							searchBar:ReleaseFocus()
						end)
						
						ind += 1
					end
					PossiblePlayers:ResizeCanvas(false,true)
				end
				
				PossiblePlayers.Visible = false
				
				searchBar.Focused:Connect(function() PossiblePlayers.Visible = true; searchBar.BorderSizePixel = 2; PossiblePlayers.BorderSizePixel = 2 end)
				searchBar.FocusLost:Connect(function() task.wait(); PossiblePlayers.Visible = false; searchBar.BorderSizePixel = 0; PossiblePlayers.BorderSizePixel = 0 end)
				
				searchBar:GetPropertyChangedSignal("Text"):Connect(function()
					if searchBar.Text ~= "" then
						local ind = 0
						for i,v in pairs(PossiblePlayers:GetChildren()) do
							if v.Text:find(searchBar.Text) ~= nil then
								v.Visible = true
								v.Position = UDim2.new(0, 0, 0, 25*ind)
								ind += 1
							else
								v.Visible = false
							end
						end
						PossiblePlayers:ResizeCanvas(false,true)
					else
						getPlayers()
					end
				end)
				
				button.MouseButton1Click:Connect(function()
					getPlayers()
				end)
				
				getPlayers()
			end
		end
		
		--// Perm Ban
		do
			if CanPermBan then
				local tab,button = tabFrame:NewTab("Perm Ban",{
					Text = "Perm Ban"
				})
				
				local searchBar: TextBox = tab:Add("TextBox",{
					Size = UDim2.new(1, -10, 0, 20);
					Position = UDim2.new(0, 5, 0, 5);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
					BorderColor3 = Color3.new(0,0,0);
					TextColor3 = Color3.new(1, 1, 1);
					Text = "";
					PlaceholderText = `Search player`;
					TextStrokeTransparency = 0.8;
					ClearTextOnFocus = false;
				})

				local PossiblePlayers = tab:Add("ScrollingFrame",{
					Size = UDim2.new(1, -10, 0, 85);
					Position = UDim2.new(0, 5, 0, 27);
					BackgroundColor3 = Color3.new(20/255, 20/255, 20/255);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
					BorderColor3 = Color3.new(0,0,0);
					ZIndex = 5
				})

				local reasonFrame = tab:Add("Frame",{
					Size = UDim2.new(1, -10, 1, -65);
					Position = UDim2.new(0, 5, 0, 30);
					BackgroundColor3 = Color3.new(20/255, 20/255, 20/255);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
				})

				local reason = reasonFrame:Add("TextBox",{
					Size = UDim2.new(1, -10, 1, -10);
					Position = UDim2.new(0, 5, 0, 5);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					TextColor3 = Color3.new(1, 1, 1);
					Text = "";
					PlaceholderText = `Reason`;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					TextWrapped = true;
				})

				local unbanButton = tab:Add("TextButton",{
					Size = UDim2.new(.5, -10, 0, 25);
					Position = UDim2.new(0, 5, 1, -30);
					Text = "Unban";
					OnClick = function()
						client.Remote.Send("ProcessCommand",`{data.Prefix}unpermban {searchBar.Text}`)
					end,
				})

				local banButton = tab:Add("TextButton",{
					Size = UDim2.new(.5, -10, 0, 25);
					Position = UDim2.new(1, -5, 1, -30);
					Text = "Ban";
					AnchorPoint = Vector2.new(1,0);
					OnClick = function()
						client.Remote.Send("ProcessCommand",`{data.Prefix}permban {searchBar.Text} {reason.Text}`)
					end,
				})

				local function getPlayers()
					PossiblePlayers:ClearAllChildren()
					local ind = 0
					for i,v in pairs(game.Players:GetPlayers()) do
						local button:TextButton = PossiblePlayers:Add("TextButton",{
							Text = `{v.DisplayName} (@{v.Name})`;
							Size = UDim2.new(1, 0, 0, 25);
							Position = UDim2.new(0, 0, 0, 25*ind);
							ZIndex = 5
						})

						button.MouseButton1Down:Connect(function()
							searchBar.Text = v.Name
							searchBar:ReleaseFocus()
						end)

						ind += 1
					end
					PossiblePlayers:ResizeCanvas(false,true)
				end

				PossiblePlayers.Visible = false

				searchBar.Focused:Connect(function() PossiblePlayers.Visible = true; searchBar.BorderSizePixel = 2; PossiblePlayers.BorderSizePixel = 2 end)
				searchBar.FocusLost:Connect(function() task.wait(); PossiblePlayers.Visible = false; searchBar.BorderSizePixel = 0; PossiblePlayers.BorderSizePixel = 0 end)

				searchBar:GetPropertyChangedSignal("Text"):Connect(function()
					if searchBar.Text ~= "" then
						local ind = 0
						for i,v in pairs(PossiblePlayers:GetChildren()) do
							if v.Text:find(searchBar.Text) ~= nil then
								v.Visible = true
								v.Position = UDim2.new(0, 0, 0, 25*ind)
								ind += 1
							else
								v.Visible = false
							end
						end
						PossiblePlayers:ResizeCanvas(false,true)
					else
						getPlayers()
					end
				end)
				
				button.MouseButton1Click:Connect(function()
					getPlayers()
				end)

				getPlayers()
			end
		end
		
		--// Time Ban
		do
			if CanTimeBan then
				local tab,button = tabFrame:NewTab("Time Ban",{
					Text = "Time Ban"
				})
				
				button:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
					local AbsolutePosition = window:GetPosition()
					local AbsoluteSize = window:GetSize()
					if button.BackgroundTransparency == 0 then
						window:SetPosition(UDim2.new(0, AbsolutePosition.X, 0, AbsolutePosition.Y-(15/2)))
						window:SetSize({AbsoluteSize.X,AbsoluteSize.Y+15})
						window:SetMinSize({267,265})
					else
						window:SetPosition(UDim2.new(0, AbsolutePosition.X, 0, AbsolutePosition.Y+(15/2)))
						window:SetSize({AbsoluteSize.X,AbsoluteSize.Y-15})
						window:SetMinSize({267,250})
					end
				end)

				local searchBar: TextBox = tab:Add("TextBox",{
					Size = UDim2.new(1, -10, 0, 20);
					Position = UDim2.new(0, 5, 0, 5);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
					BorderColor3 = Color3.new(0,0,0);
					TextColor3 = Color3.new(1, 1, 1);
					Text = "";
					PlaceholderText = `Search player`;
					TextStrokeTransparency = 0.8;
					ClearTextOnFocus = false;
				})

				local PossiblePlayers = tab:Add("ScrollingFrame",{
					Size = UDim2.new(1, -10, 0, 85);
					Position = UDim2.new(0, 5, 0, 27);
					BackgroundColor3 = Color3.new(20/255, 20/255, 20/255);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
					BorderColor3 = Color3.new(0,0,0);
					ZIndex = 5
				})
				
				local duration = tab:Add("TextBox",{
					Size = UDim2.new(1, -10, 0, 20);
					Position = UDim2.new(0, 5, 0, 30);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
					TextColor3 = Color3.new(1, 1, 1);
					Text = "";
					PlaceholderText = `Duration (example: 1h)`;
				})

				local reasonFrame = tab:Add("Frame",{
					Size = UDim2.new(1, -10, 1, -90);
					Position = UDim2.new(0, 5, 0, 55);
					BackgroundColor3 = Color3.new(20/255, 20/255, 20/255);
					BackgroundTransparency = 0;
					BorderSizePixel = 0;
				})

				local reason = reasonFrame:Add("TextBox",{
					Size = UDim2.new(1, -10, 1, -10);
					Position = UDim2.new(0, 5, 0, 5);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					TextColor3 = Color3.new(1, 1, 1);
					Text = "";
					PlaceholderText = `Reason`;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					TextWrapped = true;
				})

				local unbanButton = tab:Add("TextButton",{
					Size = UDim2.new(.5, -10, 0, 25);
					Position = UDim2.new(0, 5, 1, -30);
					Text = "Unban";
					OnClick = function()
						client.Remote.Send("ProcessCommand",`{data.Prefix}untimeban {searchBar.Text}`)
					end,
				})

				local banButton = tab:Add("TextButton",{
					Size = UDim2.new(.5, -10, 0, 25);
					Position = UDim2.new(1, -5, 1, -30);
					Text = "Ban";
					AnchorPoint = Vector2.new(1,0);
					OnClick = function()
						client.Remote.Send("ProcessCommand",`{data.Prefix}timeban {searchBar.Text} {duration.Text or "1h"} {reason.Text}`)
					end,
				})

				local function getPlayers()
					PossiblePlayers:ClearAllChildren()
					local ind = 0
					for i,v in pairs(game.Players:GetPlayers()) do
						local button:TextButton = PossiblePlayers:Add("TextButton",{
							Text = `{v.DisplayName} (@{v.Name})`;
							Size = UDim2.new(1, 0, 0, 25);
							Position = UDim2.new(0, 0, 0, 25*ind);
							ZIndex = 5
						})

						button.MouseButton1Down:Connect(function()
							searchBar.Text = v.Name
							searchBar:ReleaseFocus()
						end)

						ind += 1
					end
					PossiblePlayers:ResizeCanvas(false,true)
				end

				PossiblePlayers.Visible = false

				searchBar.Focused:Connect(function() PossiblePlayers.Visible = true; searchBar.BorderSizePixel = 2; PossiblePlayers.BorderSizePixel = 2 end)
				searchBar.FocusLost:Connect(function() task.wait(); PossiblePlayers.Visible = false; searchBar.BorderSizePixel = 0; PossiblePlayers.BorderSizePixel = 0 end)

				searchBar:GetPropertyChangedSignal("Text"):Connect(function()
					if searchBar.Text ~= "" then
						local ind = 0
						for i,v in pairs(PossiblePlayers:GetChildren()) do
							if v.Text:find(searchBar.Text) ~= nil then
								v.Visible = true
								v.Position = UDim2.new(0, 0, 0, 25*ind)
								ind += 1
							else
								v.Visible = false
							end
						end
						PossiblePlayers:ResizeCanvas(false,true)
					else
						getPlayers()
					end
				end)
				
				button.MouseButton1Click:Connect(function()
					getPlayers()
				end)

				getPlayers()
			end
		end
	end
	
	gTable = window.gTable
	window:Ready()
end
