local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ButtonRoot = script.Parent
local Button = require(ButtonRoot.Button)

local BORDER_PADDING = UDim.new(0, 8)

local ButtonStory = Roact.PureComponent:extend(script.Name)

function ButtonStory:render()
	local props = self.props

	return WithTheme(function(Theme)
		return new('Frame', {
			BackgroundTransparency = props.BackgroundTransparency,
			BackgroundColor3 = Theme['colors/Background/Fill_Color/Solid_Background/Base'].Color,
			AutomaticSize = 'XY'
		}, {
			Padding = new('UIPadding', {
				PaddingBottom = BORDER_PADDING,
				PaddingLeft = BORDER_PADDING,
				PaddingRight = BORDER_PADDING,
				PaddingTop = BORDER_PADDING,
			}),
			Button = new(Button, {
				AnchorPoint = Vector2.new(0, 0),
				Disabled = props.Disabled,
				Position = UDim2.fromScale(0, 0),
				Style = props.Style,
				[Roact.Event.Activated] = print
			})
		})
	end)
end

return {
	controls = {
		Disabled = false,
		Style = {
			'Accent',
			'Primary',
			'Secondary',
			'Standard',
			'Default',
		}
	},
	stories = {
		Button = function (props)
			return Roact.createFragment({
				OnBackground = new(ButtonStory, Sift.Dictionary.join({
					BackgroundTransparency = 0,
				}, props.controls)),
				NoBackground = new(ButtonStory, Sift.Dictionary.join({
					BackgroundTransparency = 1,
				}, props.controls))
			})
		end
	}
}