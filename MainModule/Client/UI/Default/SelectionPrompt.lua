
client = nil
service = nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local gTable
	local answer

	local done = false;
	local options = data.Options;
	local name = data.Name;

	local window = client.UI.Make("Window",{
		Name  = name or "SelectionPrompt";
		Title = name or "Selection Prompt";
		Icon = client.MatIcons["Format list bulleted"];
		Size  = {225,150};
		SizeLocked = true;
		OnClose = function()
			if not answer then
				answer = nil
			end
			
			done = true;
		end
	})


	local frame = window:Add("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0);
		Position = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = 1;
	})

	local layout = service.New("UIListLayout", {
		Parent = frame;
		FillDirection = "Vertical";
		HorizontalAlignment = "Center";
		VerticalAlignment = "Top";
	})

	for i,v in next,options do
		frame:Add("TextButton", {
			Text = v.Text;
			Size = UDim2.new(1, 0, 0, 30);
			OnClick = function()
				answer = v.Data;
				done = true;
				window:Destroy();
			end;
		})
	end

	frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	frame.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)


	gTable = window.gTable
	window:Ready()
	repeat task.wait() until done == true;
	return answer
end
