client = nil
service = nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local gTable
	local window = client.UI.Make("Window", {
		Name  = "CreateCard";
		Title = "Create Card";
		Icon = client.MatIcons["Add circle"];
		Size  = {400, 330};
		AllowMultiple = false;
		OnClose = function()
			
		end
	})
	
	if window then
		window:Add("TextLabel", {
			Text = "List Name:  ";
			BackgroundTransparency = 1;
			Size = UDim2.new(0, 80, 0, 30);
			Position = UDim2.new(0, 10, 0, 10);
			TextXAlignment = "Right";
		}):Copy("TextLabel", {
			Text = "Card Name:  ";
			Position = UDim2.new(0, 10, 0, 50);
		}):Copy("TextLabel", {
			Text = "Card Desc:  ";
			Position = UDim2.new(0, 10, 0, 90);
		})
		
		local list = window:Add("TextBox", {
			Text = "";
			BackgroundTransparency = 0.5;
			Position = UDim2.new(0, 90, 0, 10);
			Size = UDim2.new(1, -100, 0, 30);
			BackgroundColor3 = window.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.2);
			TextWrapped = true;
		})
		
		local name = list:Copy("TextBox", {
			Position = UDim2.new(0, 90, 0, 50);
		})
		
		local desc = list:Copy("TextBox", {
			Position = UDim2.new(0, 90, 0, 90);
			Size = UDim2.new(1, -100, 1, -100);
		})
		
		local done = false
		local create = window:Add("TextButton", {
			Text = "Create";
			Size = UDim2.new(0, 70, 0, 30);
			Position = UDim2.new(0, 10, 1, -40);
			OnClick = function()
				if not done then
					done = true
					window:Destroy()
					client.Remote.Send("TrelloOperation", {
						Action = "MakeCard";
						List = list.Text;
						Name = name.Text;
						Desc = desc.Text;
					})
				end
			end
		})
		
		
		gTable = window.gTable
		window:Ready()
	end
end
