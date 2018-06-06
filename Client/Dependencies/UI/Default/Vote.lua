
client = nil
service = nil

return function(data)
	local gTable
	local selected
	
	local question = data.Question
	local answers = data.Answers
	
	local window = client.UI.Make("Window",{
		Name  = "Vote";
		Title = "Vote";
		Size  = {300,200};
		AllowMultiple = false;
		OnClose = function()
			if not selected then
				selected = false
			end
		end
	})
	
	local quesText = window:Add("TextLabel",{
		Text = question;
		TextScaled = true;
		TextWrapped = true;
		Size = UDim2.new(1, -10, 0, 50);
		BackgroundTransparency = 1;
	})
	
	local ansList = window:Add("ScrollingFrame",{
		Size = UDim2.new(1, -10, 1, -60);
		Position = UDim2.new(0, 5, 0, 55);
	})
	
	for i,ans in next,answers do
		ansList:Add("TextButton",{
			Text = i..". "..ans;
			Size = UDim2.new(1, -10, 0, 25);
			Position = UDim2.new(0, 5, 0, 25*(i-1));
			TextXAlignment = "Left";
			Events = {
				MouseButton1Click = function()
					window:Close()
					selected = ans
				end
			}
		})
	end
	
	ansList:ResizeCanvas()
	gTable = window.gTable
	window:Ready()
	
	repeat wait() until selected or not gTable.Active
	return selected
end