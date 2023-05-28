local Components = script.Parent
local Packages = Components.Parent.Packages

local Roact = require(Packages.Roact)
local new = Roact.createElement

local Notification = require(script.Parent.Notification)
local NotificationStory = Roact.PureComponent:extend(script.Name)

function NotificationStory:render()

	return new(Notification, {
		TitleText = "Notification",
		OnClose = warn,
	}, {
		Test = new('TextLabel', {
			Size = UDim2.fromOffset(200, 100),
			BackgroundTransparency = 0.9,
			Text = '[Roact.Children] goes here.\n200 x 100 test TextLabel',
			TextColor3 = Color3.fromRGB(255, 255, 255),
		})
	})
end

return NotificationStory