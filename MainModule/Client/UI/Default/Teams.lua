client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local window = client.UI.Make("Window", {
		Name  = "Teams";
		Title = "Teams";
		Icon = client.MatIcons.People;
		Size  = {300, 280};
		AllowMultiple = false;
	})

	local scroller = window:Add("ScrollingFrame", {
		List = {};
		ScrollBarThickness = 3;
		Position = UDim2.new(0, 5, 0, 5);
		Size = UDim2.new(1, -10, 1, -70);
		BackgroundTransparency = 1;
	})

	local creator = window:Add("Frame", {
		AnchorPoint = Vector2.new(0, 1);
		Position = UDim2.new(0, 5, 1, -5);
		Size = UDim2.new(1, -10, 0, 65);
		Children = {
			{
				Class = "TextLabel";
				Size = UDim2.new(0, 50, 0, 25);
				Position = UDim2.new(0, 5, 0, 5);
				TextXAlignment = "Left";
				Text = "Name:";
				BackgroundTransparency = 1;
			},
			{
				Class = "TextLabel";
				Size = UDim2.new(0, 50, 0, 25);
				Position = UDim2.new(0, 5, 0, 35);
				TextXAlignment = "Left";
				Text = "Color:";
				BackgroundTransparency = 1;
			},
		}
	})

	local teamName = creator:Add("TextBox", {
		Size = UDim2.new(0, 150, 0, 25);
		Position = UDim2.new(0, 50, 0, 5);
		BackgroundColor3 = Color3.fromRGB(70, 70, 70);
		TextXAlignment = "Left";
		Text = "";
	})
	teamName:Add("UIPadding", {PaddingLeft=UDim.new(0, 4)})

	local teamColor = creator:Add("TextBox", {
		Size = UDim2.new(0, 150, 0, 25);
		Position = UDim2.new(0, 50, 0, 35);
		BackgroundColor3 = Color3.fromRGB(70, 70, 70);
		TextXAlignment = "Left";
		PlaceholderText = "BrickColor";
		Text = "";
	})
	teamColor:Add("UIPadding", {PaddingLeft=UDim.new(0, 4)})
	teamColor:Add("ImageButton", {
		Size = UDim2.new(0, 21, 0, 21);
		Position = UDim2.new(1, -23, 0, 2);
		BackgroundTransparency = 0.8;
		Image = client.MatIcons.Palette;
		ImageTransparency = 0.2;
	}).MouseButton1Down:Connect(function()
		client.Remote.Send("ProcessCommand", `{data.CmdPlayerPrefix}brickcolors`)
	end)

	local createTeam = creator:Add("TextButton", {
		Class = "TextButton";
		AnchorPoint = Vector2.new(1, 1);
		BackgroundColor3 = Color3.fromRGB(45, 45, 45);
		Size = UDim2.new(0, 65, 0, 28);
		Position = UDim2.new(1, -5, 1, -5);
		Text = "Create";
		OnClick = function(self)
			if teamName.Text ~= "" and teamColor.Text ~= "" then
				self.Active = false
				self.AutoButtonColor = false
				self.Text = "..."
				client.Remote.Send("ProcessCommand", string.format("%snewteam%s%s%s%s", data.CmdPrefix, data.CmdSplitKey, teamName.Text, data.CmdSplitKey, teamColor.Text));
				teamName.Text = ""
				teamColor.Text = ""
				wait(1.2)
				if self then
					self.Active = true
					self.AutoButtonColor = true
					self.Text = "Create"
				end
			end
		end;
	})

	teamName:GetPropertyChangedSignal("Text"):Connect(function()
		teamName.Text = string.gsub(teamName.Text, data.CmdSplitKey, "")
	end)
	teamColor:GetPropertyChangedSignal("Text"):Connect(function()
		teamColor.TextColor3 = BrickColor.new(teamColor.Text).Color
		--teamColor.TextColor3 = `{BrickColor.new(teamColor.Text:sub(1, 1):upper()}{teamColor.Text:sub(2):lower()).Color}` -- unfortunately we have BrickColors with names like "New Yeller"
	end)

	local function generate()
		local count = 0
		scroller:ClearAllChildren()
		scroller:Add("UIListLayout", {
			Padding = UDim.new(0, 4);
			SortOrder = Enum.SortOrder.Name;
			FillDirection = Enum.FillDirection.Vertical;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
		})
		for i, team: Team in ipairs(service.Teams:GetTeams()) do
			count += 1
			scroller:Add("TextLabel", {
				Name = team.Name;
				Size = UDim2.new(1, -10, 0, 30);
				BackgroundTransparency = 0.5;
				TextXAlignment = "Left";
				Text = "";
				ZIndex = 11;
				Children = {
					{
						Class = "Frame";
						AnchorPoint = Vector2.new(0, 0.5);
						BackgroundColor3 = team.TeamColor.Color;
						Size = UDim2.new(0, 35, 1, -4);
						Position = UDim2.new(0, 2, 0.5, 0);
						ToolTip = team.TeamColor.Name;
						ZIndex = 13;
					},
					{
						Class = "TextLabel";
						Size = UDim2.new(1, -144, 1, 0);
						Position = UDim2.new(0, 42, 0, 0);
						BackgroundTransparency = 1;
						TextXAlignment = "Left";
						TextYAlignment = "Center";
						Text = team.Name;
						ToolTip = `[Auto-Assignable]: {tostring(team.AutoAssignable)}`;
						ZIndex = 13;
					},
					{
						Class = "TextButton";
						AnchorPoint = Vector2.new(1, 0.5);
						Size = UDim2.new(0, 60, 0, 26);
						Position = UDim2.new(1, -30, 0.5, 0);
						Text = "Join";
						ZIndex = 13;
						OnClick = function(self)
							self.Active = false
							self.AutoButtonColor = false
							self.Text = "..."
							client.Remote.Send("ProcessCommand", string.format("%steam%s%sme%s%s", data.CmdPrefix, data.CmdSplitKey, data.CmdSpecialPrefix, data.CmdSplitKey, team.Name));
							wait(1.2)
							if self then
								self.Active = true
								self.AutoButtonColor = true
								self.Text = "Join"
							end
						end;
					},
					{
						Class = "ImageButton";
						AnchorPoint = Vector2.new(1, 0.5);
						Size = UDim2.new(0, 26, 0, 26);
						Position = UDim2.new(1, -2, 0.5, 0);
						Image = client.MatIcons.Clear;
						ZIndex = 13;
						OnClick = function(self)
							self.Visible = false
							client.Remote.Send("ProcessCommand", string.format("%sremoveteam%s%s", data.CmdPrefix, data.CmdSplitKey, team.Name));
							wait(1.2)
							if self then
								self.Visible = true
							end
						end;
					},
				};
			})
		end
		scroller:ResizeCanvas(false, true, false, false, 5, 0)
		window:SetTitle(`Teams ({count})`)
	end

	service.Teams.ChildAdded:Connect(generate)
	service.Teams.ChildRemoved:Connect(generate)
	generate()

	window:Ready()
end
