client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local localplayer = service.Players.LocalPlayer

	local window = client.UI.Make("Window", {
		Name  = "HatList";
		Title = "Hats";
		Icon = client.MatIcons["Format list bulleted"];
		Size  = {320, 220};
		MinSize = {280, 150};
	})

	local connections: {RBXScriptConnection} = {}

	local function generate()
		task.wait(0.3)
		window:ClearAllChildren()
		if not localplayer.Character then return end
		for _, v in pairs(connections) do if v then v:Disconnect() end end
		table.insert(connections, localplayer.Character.ChildAdded:Connect(generate))
		table.insert(connections, localplayer.Character.ChildRemoved:Connect(generate))
		local num = 0
		for _, hat in pairs(service.Players.LocalPlayer.Character:GetChildren()) do
			if not hat:IsA("Accoutrement") then continue end
			window:Add("TextLabel", {
				Name = hat.Name;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.fromOffset(5, num*30);
				BackgroundTransparency = 1;
				TextXAlignment = "Left";
				Text = `  {if hat.Name:sub(-9) == "Accessory" then hat.Name:sub(1, -10) else hat.Name}`;
				ToolTip = hat.ClassName;
				Children = {
					{
						Class = "TextButton";
						Size = UDim2.new(0, 80, 1, -4);
						Position = UDim2.new(1, -82, 0, 2);
						Text = "Remove";
						OnClick = function(self)
							if not self.Active then return end
							self.Active = false
							client.Remote.Send("ProcessCommand", `{data.PlayerPrefix}removehat{data.SplitKey}{hat.Name}`)
							self.Parent:TweenSize(UDim2.fromOffset(0, 30), "Out", "Quint", 0.4)
							task.wait(0.3)
							if self and not hat then
								self.Parent:Destroy()
							else --// something wrong happened
								self.Parent:TweenSize(UDim2.new(1, -10, 0, 30), "Out", "Quint", 0.4)
							end
						end
					},
				};
			})
			num += 1
		end
		window:SetTitle(`Hats ({num})`)
		if num > 0 then
			window:Add("TextButton", {
				Size = UDim2.new(1, -10, 0, 25);
				Position = UDim2.fromOffset(5, num*30 + 5);
				Text = "Remove All";
				OnClick = function()
					client.Remote.Send("ProcessCommand", `{data.PlayerPrefix}removehats`)
				end
			})
		end
		window:ResizeCanvas(false, true, false, false, 5, 5)
	end

	generate()
	localplayer.CharacterAdded:Connect(generate)
	localplayer.CharacterRemoving:Connect(generate)

	window:Ready()
end
