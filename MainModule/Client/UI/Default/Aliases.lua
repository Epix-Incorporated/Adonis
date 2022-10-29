client = nil
service = nil

--// Ported from Kronos

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local gTable
	
	local window = client.UI.Make("Window",{
		Name  = "Aliases";
		Title = "Alias Editor";
		Size  = {420, 240};
		AllowMultiple = false;
	})

	local template =  {
		Alias = "",
		Args = {Names = {}, Defaults = {}},
		Command = "",
		Description = ""
	}
	for i,v in template do
		if not data[i] then
			data[i] = v
		end
	end

	if window then
		local bg = window:Add("ScrollingFrame", {
			BackgroundColor3 = Color3.fromRGB(31, 31, 31):lerp(Color3.new(1,1,1), 0.2);
			Size = UDim2.new(1, -10, 1, -10);
			Position = UDim2.new(0, 5, 0, 5)
		})

		local content = bg:Add("ScrollingFrame", {
			Size = UDim2.new(1, -10, 1, -35);
			Position = UDim2.new(0, 5, 0, 5);
			BackgroundTransparency = 0.5;
		})

		local draw;
		local curArgName, curArgDefault, argIndex;
		local argBox; argBox = window:Add("Frame", {
			Visible = false;
			Size = UDim2.new(0, 200, 0, 150);
			Position = UDim2.new(0.5, -100, 0.5, -75);
			Children = {
				{
					Class = "TextLabel";
					Text = "Argument Name:";
					Position = UDim2.new(0, 0, 0, 10);
					Size = UDim2.new(1, 0, 0, 20);
					BackgroundTransparency = 1;
				};
				{
					Class = "TextLabel";
					Text = "Default:";
					Position = UDim2.new(0, 0, 0, 65);
					Size = UDim2.new(1, 0, 0, 20);
					BackgroundTransparency = 1;
				};
				{
					Class = "TextButton";
					Text = "Save";
					Position = UDim2.new(0.5, 0, 1, -30);
					Size = UDim2.new(0.5, -20, 0, 20);
					BackgroundTransparency = 1;
					OnClicked = function()
						if argIndex == 0 then
							table.insert(data.Args.Names, curArgName)
							table.insert(data.Args.Defaults, curArgDefault or "")
						else
							data.Args.Names[argIndex] = curArgName
							data.Args.Defaults[argIndex] = curArgDefault or ""
						end
						draw()
						curArgName = nil
						curArgDefault = nil
						argBox.Visible = false
					end
				};
			}
		})

		local endBtn = argBox:Add({
			Class = "TextButton";
			Text = "Remove";
			Position = UDim2.new(0, 10, 1, -30);
			Size = UDim2.new(0.5, -20, 0, 20);
			BackgroundTransparency = 1;
			OnClicked = function()
				if argIndex ~= 0 then
					table.remove(data.Args.Names, argIndex)
					table.remove(data.Args.Defaults, argIndex)
				end
				draw()
				curArgName = nil
				curArgDefault = nil
				argBox.Visible = false
			end
		})

		local argNameBox = argBox:Add("TextBox", {
			Text = curArgName or "name";
			Position = UDim2.new(0, 10, 0, 35);
			Size = UDim2.new(1, -20, 0, 20);
			TextChanged = function(newText, enter, box)
				curArgName = newText
			end
		});

		local argDefaultBox = argBox:Add("TextBox", {
			Text = curArgDefault or "";
			Position = UDim2.new(0, 10, 0, 90);
			Size = UDim2.new(1, -20, 0, 20);
			TextChanged = function(newText, enter, box)
				curArgDefault = newText
			end
		});

		argBox.BackgroundColor3 = argBox.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.05)
		argNameBox.BackgroundColor3 = argNameBox.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.1)
		argDefaultBox.BackgroundColor3 = argNameBox.BackgroundColor3

		local function showArgBox(argData)
			if not argBox.Visible then
				if argData then
					curArgName = argData.Name
					curArgDefault = argData.Default
				end
				if argIndex == 0 then
					endBtn.Text = "Cancel"
				else
					endBtn.Text = "Remove"
				end
				argNameBox.Text = curArgName or "name"
				argDefaultBox.Text = curArgDefault or ""
				argBox.Visible = true
			end
		end

		function draw()
			content:ClearAllChildren();

			local i = 1
			content:Add("TextLabel", {
				Text = "  ".."Alias"..": ";
				ToolTip = "Set the alias Adonis should check for in chat";
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
				Children = {
					[data.ExistingAlias and "TextLabel" or "TextBox"] = {
						Text = data.Alias or "";
						Size = UDim2.new(0, 200, 1, 0);
						Position = UDim2.new(1, -200, 0, 0); 
						BackgroundTransparency = 1;
						TextChanged = not data.ExistingAlias and function(text, enter, new)
							data.Alias = text
						end or nil
					}
				}
			})
			i = i + 1
			content:Add("TextLabel", {
				Text = "  ".."Command"..": ";
				ToolTip = "Set the command(s) Adonis should execute when finding the alias";
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
				Children = {
					TextBox = {
						Text = data.Command or "";
						Size = UDim2.new(0, 200, 1, 0);
						Position = UDim2.new(1, -200, 0, 0); 
						BackgroundTransparency = 1;
						TextChanged = function(text, enter, new)
							data.Command = text
						end
					}
				}
			})
			i = i + 1
			content:Add("TextLabel", {
				Text = "  ".."Description"..": ";
				ToolTip = "What does the alias do?";
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
				Children = {
					TextBox = {
						Text = data.Description or "";
						Size = UDim2.new(0, 200, 1, 0);
						Position = UDim2.new(1, -200, 0, 0); 
						BackgroundTransparency = 1;
						TextChanged = function(text, enter, new)
							data.Description = text
						end
					}
				}
			})
			i = i + 2
			content:Add("TextButton", {
				Text = "Add Argument",
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				OnClicked = function(button)
					argIndex = 0
					showArgBox()
				end
			})
			for index,arg in ipairs(data.Args.Names) do
				i = i + 1
				content:Add("TextButton", {
					Text = "Argument: ".. arg .." | Default: "..data.Args.Defaults[index];
					BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
					Size = UDim2.new(1, -10, 0, 30);
					Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
					OnClicked = function(button)
						argIndex = index
						showArgBox({Name = arg, Default = data.Args.Defaults[index]})
					end
				})
			end

			content:ResizeCanvas(false, true, false, false, 5, 5)

			bg:Add("TextButton", {
				Text = "Cancel";
				Position = UDim2.new(0, 5, 1, -25);
				Size = UDim2.new(1/3, -8, 0, 20);
				OnClicked = function(button)
					window:Close()
				end
			})

			bg:Add("TextButton", {
				Text = "Remove";
				Position = UDim2.new(1/3, 3, 1, -25);
				Size = UDim2.new(1/3, -7, 0, 20);
				OnClicked = function(button)
					if data.ExistingAlias then
						client.Functions.RemoveAlias(data.Alias)
						client.UI.Remove("UserPanel")
						client.UI.Make("UserPanel", {Tab = "Aliases"})
					end
					window:Close()
				end
			})

			bg:Add("TextButton", {
				Text = "Save";
				Position = UDim2.new(2/3, 3, 1, -25);
				Size = UDim2.new(1/3, -8, 0, 20);
				OnClicked = function(button)
					if data.Alias == "" or data.Command == "" then
						client.UI.Make("Output", {Message = "A required field is missing!"})
					else
						client.Functions.SetAlias(data.Alias, data)
						client.UI.Remove("UserPanel")
						client.UI.Make("UserPanel", {Tab = "Aliases"})
						window:Close()
					end
				end
			})
		end

		draw()
		gTable = window.gTable
		window:Ready()
	end
end
