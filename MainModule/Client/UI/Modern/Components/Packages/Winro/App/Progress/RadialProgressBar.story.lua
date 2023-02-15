local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local RadialProgressBar = require(script.Parent.RadialProgressBar)
local RadialProgressBarStory = Roact.PureComponent:extend(script.Name)

function RadialProgressBarStory:render()
	local props = self.props

	return new(RadialProgressBar, Sift.Dictionary.join({
		--StartValue = props.Start,
		Clockwise = props.Clockwise,
		Value = props.End,
	}, props.Props))
end

return {
	controls = {
		Clockwise = false,
		End = 0.5,
	},
	stories = {
		ClockwiseRadialProgressBar = function(props)
			props.controls.Clockwise = true
			return new(RadialProgressBarStory, props.controls)
		end,
		ConterClockwiseRadialProgressBar = function(props)
			props.controls.Clockwise = false
			return new(RadialProgressBarStory, props.controls)
		end
	},
}