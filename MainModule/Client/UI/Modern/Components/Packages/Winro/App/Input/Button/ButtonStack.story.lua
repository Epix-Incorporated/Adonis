-- TitleBar: The top bar of a window component

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local FrameVisualizer = require(Winro.Utility.FrameVisualizer)

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ButtonStack = require(script.Parent.ButtonStack)

local ButtonStackStory = Roact.PureComponent:extend(script.Name)

function ButtonStackStory:render()
	
	local ButtonStack = new(ButtonStack, Sift.Dictionary.join({
		Size = UDim2.new(1, 0, 0, 30),
		ButtonHeight = UDim.new(0, 30),
		Buttons = {
			[1] = {
				Text = 'Primary',
				Style = 'Accent',
				[Roact.Event.Activated] = print,
			},
			[2] = {
				Text = 'Secondary',
				Style = 'Standard',
				[Roact.Event.Activated] = print,
			},
			[3] = {
				Text = 'Tertiary',
				Style = 'Standard',
				[Roact.Event.Activated] = print,
			},
		}
	}, self.props.Props))

	if self.props.Wireframe then
		return new(FrameVisualizer, {
			Size = UDim2.new(1, 0, 1, 0),
		}, ButtonStack)
	else
		return ButtonStack
	end
end

return {
	controls = {
		Wireframe = false,
	},
	stories = {
		ButtonStack = function(props)
			return new(ButtonStackStory, props.controls)
		end
	}
}