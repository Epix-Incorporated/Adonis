local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Expander = require(script.Parent.Expander)

local ExpanderStory = Roact.PureComponent:extend(script.Name)

function ExpanderStory:render()
	local props = self.props
	local state = self.state

	return new(Expander, Sift.Dictionary.join({
		Expanded = state.Expanded,
		Heading = props.Heading and 'Power button functionality' or nil,
		Caption = props.Caption and 'Adjust what your power buttons control' or nil,
		Icon = props.Icon and 'images/roblox/icons/logo/studiologo/1x',

		[Roact.Event.Activated] = function(...)
			print(...)

			self:setState({
				Expanded = not state.Expanded,
			})
		end,
	}, props.Props))
end

return {
	controls = {
		Icon = true,
		Heading = true,
		Caption = true,
	},
	stories = {
		Expander = function(props)
			
			return new(ExpanderStory, props.controls)
		end
	}
}