local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local SurfaceRoot = script.Parent
local RoundedSurface = require(SurfaceRoot.RoundedSurface)

local RoundedSurfaceStory = Roact.PureComponent:extend(script.Name)

function RoundedSurfaceStory:render()
	return new(RoundedSurface, Sift.Dictionary.join({
		Size = UDim2.fromOffset(50, 50),
		BackgroundColor = {
			Color = Color3.new(1, 1, 1),
			Transparency = self.props.Alpha or 0.5
		},
		CornerRadius = UDim.new(0, self.props.Radius or 5),
		ShowTopLeftCorner = self.props.TLeft,
		ShowTopRightCorner =self.props.TRight,
		ShowBottomLeftCorner =self.props.BLeft,
		ShowBottomRightCorner = self.props.BRight,
	}, self.props.Props))
end

return {
	controls = {
		Radius = 10,
		Alpha = 0.5,
		TLeft = false,
		TRight = true,
		BLeft = true,
		BRight = false,
	},
	stories = {
		RoundedSurface = function (props)
			return new(RoundedSurfaceStory, props.controls)
		end
	}
}