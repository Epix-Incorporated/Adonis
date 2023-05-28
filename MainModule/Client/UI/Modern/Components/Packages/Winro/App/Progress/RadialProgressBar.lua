-- RadialProgressBar: A circular progress bar
-- Adapted from https://gist.github.com/Reselim/6550108641a3f0f88d69033e7b6556dc

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Validators = Winro.Validators
local StyleValidator = require(Validators.StyleValidator)

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local TRANSPARENCY_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.505, 1),
	NumberSequenceKeypoint.new(1, 1)
})

local RadialProgressBar = Roact.PureComponent:extend(script.Name)

RadialProgressBar.defaultProps = {
	StrokeColor = 'colors/UNKNOWN',
	Value = 1, --- @defaultProp
	Size = UDim2.fromOffset(100, 100), --- @defaultProp
	Thickness = 30, --- @defaultProp
	Clockwise = true, --- @defaultProp
}

RadialProgressBar.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 Anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional Color string|Table The stroke's color
	StrokeColor = t.optional(StyleValidator),

	--- @prop @optional Clockwise boolean Determines if the rotation is clockwise
	Clockwise = t.optional(t.boolean),

	--- @prop @optional Position UDim2 Position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 Size
	Size = t.optional(t.UDim2),

	--- @prop @optional Thickness number The stroke's thickness, in pixels
	Thickness = t.optional(t.number),

	--- @prop @optional Value number The value of the radial progress bar
	Value = t.optional(t.numberConstrained(0, 1)),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),
})

function RadialProgressBar:init()
	
	-- Initial state
	self:setState({
		Size = UDim2.new(),
	})
end

function RadialProgressBar:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)

		-- ///////// Determine focus and progress

		local FocusedSide = nil
		local Progress = props.Value
		local IsLeftVisible = nil
		local IsRightVisible = nil

		if props.Clockwise then

			FocusedSide = Progress < 0.5 and 'Right'
			or Progress >= 0.5 and 'Left'

			IsLeftVisible = (FocusedSide == 'Left' or Progress >= 0.5) or nil
			IsRightVisible = (FocusedSide == 'Right' or Progress >= 0.5) or nil
		else
			Progress = 0.5 - Progress

			FocusedSide = Progress < 0.5 and 'Left'
			or Progress >= 0.5 and 'Right'

			IsLeftVisible = (FocusedSide == 'Left' or Progress >= 0.5) or true
			IsRightVisible = (FocusedSide == 'Right' or Progress >= 0.5) or true
		end

		-- ////////// Gradients

		local LeftGradient = FocusedSide == 'Left' and new('UIGradient', {
			Transparency = TRANSPARENCY_SEQUENCE,
			Rotation = Progress * 360,
		}) or nil

		local RightGradient = FocusedSide == 'Right' and new('UIGradient', {
			Transparency = TRANSPARENCY_SEQUENCE,
			Rotation = Progress * 360,
		}) or nil
		
		-- ////////// Stroke Wrappers
		
		local StrokeFill = Theme[props.StrokeColor]

		local StrokeSizeOffset = -UDim2.fromOffset(props.Thickness * 2, props.Thickness * 2)
		local SemiSize = UDim2.new(props.Size.X.Scale / 2, props.Size.X.Offset / 2, props.Size.Y.Scale, props.Size.Y.Offset)

		local LeftStrokeWrapper = new('Frame', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			BackgroundTransparency = 1,
			Size = state.Size + StrokeSizeOffset,
		}, {

			Stroke = new('UIStroke', {
				Thickness = props.Thickness,
				Color = StrokeFill.Color,
				Transparency = StrokeFill.Transparency,
			}, {
				Gradient = LeftGradient,
			}),
			Corner = new('UICorner', {
				CornerRadius = UDim.new(1, 0),
			}),
		})

		local RightStrokeWrapper = new('Frame', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			BackgroundTransparency = 1,
			Size = state.Size + StrokeSizeOffset,
		}, {

			Stroke = new('UIStroke', {
				Thickness = props.Thickness,
				Color = StrokeFill.Color,
				Transparency = StrokeFill.Transparency,
			}, {
				Gradient = RightGradient,
			}),
			Corner = new('UICorner', {
				CornerRadius = UDim.new(1, 0),
			}),
		})

		-- ////////// Semi Circles

		local LeftSemiCircle = IsLeftVisible and new('CanvasGroup', {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = SemiSize,
		}, {
			StrokeWrapper = LeftStrokeWrapper,
		})

		local RightSemiCircle = IsRightVisible and new('CanvasGroup', {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = SemiSize,
		}, {
			StrokeWrapper = RightStrokeWrapper,
		})

		-- ////////// Radial Progress Bar
		return new('Frame', {
			Anchorpoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			Positon = props.Position,
			Size = props.Size,

			[Roact.Change.AbsoluteSize] = function (rbx)
				local AbsoluteSize = rbx.AbsoluteSize

				self:setState({
					Size = UDim2.fromOffset(AbsoluteSize.X, AbsoluteSize.Y),
				})
			end,
		}, {
			LeftSemiCircle = LeftSemiCircle,
			RightSemiCircle = RightSemiCircle,
		})
	end)
end

return RadialProgressBar