-- DropShadow: A component that is the base structure for a UI DropShadow

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

local DropShadow = Roact.PureComponent:extend(script.Name)

DropShadow.defaultProps = {
	CornerRadius = UDim.new(0, 8), --- @defaultProp
}

DropShadow.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The DropShadow's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional @style BackgroundColor string|table The DropShadow's background color
	BackgroundColor = t.optional(StyleValidator),

	--- @prop @optional CornerRadius UDim Corner radius
	CornerRadius = t.optional(t.UDim),

	--- @prop @optional AutomaticSize Enum.AutomaticSize Auto sizing
	AutomaticSize = t.optional(t.EnumItem),

	--- @prop @optional Position UDim2 The DropShadow's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 The DropShadow's size
	Size = t.union(t.UDim2, t.table),

	--- @prop @optional [Roact.Children] table The contents to display in the DropShadow area
	[Roact.Children] = t.optional(t.table),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),
})

function DropShadow:render()
	local props = self.props or {}

	return WithTheme(function(Theme)

		-- ////////// DropShadow
		return new('ImageLabel', Sift.Dictionary.join({
			BackgroundTransparency = 1,
			AnchorPoint = props.AnchorPoint,
			Position = props.Position,
			Image = 'rbxassetid://186491278',
			ImageTransparency = 0.25,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(20, 15, 76, 71),
			SliceScale = props.CornerRadius.Offset / 4, -- This works kinda?

			Size = props.Size,
		}, props.Native), props[Roact.Children])
	end)
end

return DropShadow