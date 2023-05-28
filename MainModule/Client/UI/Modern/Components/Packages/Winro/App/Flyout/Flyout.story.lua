local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Flyout = require(script.Parent.Flyout)
local Button = require(Winro.App.Input.Button.Button)

local FlyoutStory = Roact.PureComponent:extend(script.Name)

function FlyoutStory:render()
	return new(Flyout, Sift.Dictionary.join({
		Size = UDim2.new(1, 0, 0, 0),
		FitContents = true,
		Text = 'This is the flyout component\nThe flyout component should not be used as a dialog but instead to show quick actions or notification alerts.',
		[Roact.Children] = self.props.IncludeContents and new(Button, {
			Size = UDim2.new(0, 150, 0, 30),
			Text = 'Contents'
		})
	}, self.props.controls))
end

return {
	controls = {
		IncludeContents = true,
	},
	stories = {
		Flyout = function (props)
			return new(FlyoutStory, props.controls)
		end
	}
}