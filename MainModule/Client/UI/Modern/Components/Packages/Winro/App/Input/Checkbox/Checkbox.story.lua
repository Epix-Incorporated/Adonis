local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Roact = require(Packages.Roact)
local new = Roact.createElement

local Checkbox = require(script.Parent.Checkbox)

local BORDER_PADDING = UDim.new(0, 8)

local CheckboxStory = Roact.PureComponent:extend(script.Name)

function CheckboxStory:init()
	self:setState({
		Selected = nil
	})
end

function CheckboxStory:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)

		local Checkbox = new(Checkbox, {
			Label = state.Selected == nil and 'Indeterminate' or state.Selected == true and 'Selected' or 'Deselected',
			Selected = state.Selected,
			Disabled = self.props.Disabled,
			[Roact.Event.Activated] = function(...)
				print(...)
				self:setState({
					Selected = not state.Selected
				})
			end
		})

		if props.OnBackground then
			return new('Frame', {
				BackgroundTransparency = props.BackgroundTransparency,
				BackgroundColor3 = Theme['colors/Background/Fill_Color/Solid_Background/Base'].Color,
				AutomaticSize = 'XY',
				Size = UDim2.new(1, 0, 0, 45)
			}, {
				Padding = new('UIPadding', {
				PaddingBottom = BORDER_PADDING,
				PaddingLeft = BORDER_PADDING,
				PaddingRight = BORDER_PADDING,
				PaddingTop = BORDER_PADDING,
			}),
				Checkbox = Checkbox
			})
		else
			return Checkbox
		end
	end)	
end

local Controls = {
	OnBackground = true,
	Disabled = false
}

return {
	storyElement = CheckboxStory,
	roact = Roact,
	controls = Controls,
	stories = {
		Checkbox = function(props)
			local controls = props.controls

			return Roact.createElement(CheckboxStory, controls)
		end
	}
}