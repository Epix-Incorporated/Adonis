client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	local gTable
	local selected
	local question = data.Question
	local answers = data.Answers
	local randomOrder = data.IsRandomOrder
	local window = client.UI.Make("Window",{
		Name  = "Vote";
		Title = "Vote";
		Size  = {300, 200};
		Icon = client.MatIcons.Poll;
		OnClose = function()
			if not selected then
				selected = false
			end
		end
	})
	local quesText = window:Add("TextLabel", {
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
	if randomOrder then
		local shuffled = {}
		for i, v in ipairs(answers) do
			local pos = math.random(1, #shuffled+1)
			table.insert(shuffled, pos, v)
		end
		answers = shuffled
	end
	for i, ans in answers do
		ansList:Add("TextButton",{
			Text = `{i}. {ans}`;
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

	repeat task.wait() until selected or not gTable.Active
	return selected
end
