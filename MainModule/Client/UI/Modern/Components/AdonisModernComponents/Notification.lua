-- Notification: Ported from roblox studio using codify plugin due to complexity, work on a better component soon

local Components = script.Parent
local Packages = Components.Parent.Packages

local Roact = require(Packages.Roact)
local new = Roact.createElement

return function (props)

	return new("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		AutoLocalize = false,
	}, {
		content = new("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.fromScale(1, 0),
		}, props[Roact.Children]),

		uIListLayout = new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}),

		header = new("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 25),
		}, {
			fill = new("CanvasGroup", {
				GroupColor3 = Color3.fromRGB(0, 0, 0),
				GroupTransparency = 0.5,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 0,
			}, {
				corner = new("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.new(1, 0, 0, 35),
				}, {
					uICorner = new("UICorner", {
						CornerRadius = UDim.new(0, 4),
					}),

					cornerFilling = new("Frame", {
						AnchorPoint = Vector2.new(0, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0, 1),
						Size = UDim2.new(1, 0, 0, 5),
					}),
				}),
			}),

			wrapper = new("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				uIPadding = new("UIPadding", {
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					PaddingTop = UDim.new(0, 5),
				}),

				left = new("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, {
					icon = props.Image and new("ImageLabel", {
						Image = props.Image,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.fromOffset(5, 5),
						Size = UDim2.fromOffset(16, 16),
						ZIndex = 10,
						AutoLocalize = false,
					}),

					title = new("TextLabel", {
						FontFace = Font.fromEnum(Enum.Font.SourceSansBold),
						Text = props.TitleText,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14,
						TextStrokeColor3 = Color3.fromRGB(90, 90, 90),
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.fromOffset(30, 8),
						Size = UDim2.new(1, -60, 0, 15),
						ZIndex = 10,
						AutoLocalize = false,
					}),

					uIListLayout1 = new("UIListLayout", {
						Padding = UDim.new(0, 5),
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
				}),

				right = new("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, {
					close = new("TextButton", {
						FontFace = Font.fromEnum(Enum.Font.FredokaOne),
						Text = "x",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 19,
						TextWrapped = true,
						BackgroundColor3 = Color3.fromRGB(195, 33, 35),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.new(1, -25, 0, 5),
						Size = UDim2.fromOffset(12, 12),
						ZIndex = 10,
						AutoLocalize = false,
						[Roact.Event.Activated] = props.OnClose,
					}),

					uIListLayout2 = new("UIListLayout", {
						Padding = UDim.new(0, 5),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}),
			}),
		}),

		uICorner1 = new("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
	})
end