-- ButtonStack: A button list

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ButtonRoot = script.Parent
local Button = require(ButtonRoot.Button)

local ButtonStack = Roact.PureComponent:extend(script.Name)

ButtonStack.defaultProps = {
	ButtonHeight = UDim.new(0, 30), --- @defaultProp,
	Padding = UDim.new(0, 8), --- @defaultProp
	ButtonAlignment = Enum.HorizontalAlignment.Left, --- @defaultProp
	HorizontalAlignment = Enum.HorizontalAlignment.Right, --- @defaultProp
	VerticalAlignment = Enum.VerticalAlignment.Center, --- @defaultProp
	MinSlack = 50, --- @defaultProp
	StackWidth = UDim.new(1, 0), --- @defaultProp
	PaddingLeft = UDim.new(), --- @defaultProp
	PaddingRight = UDim.new(), --- @defaultProp
	PaddingBottom = UDim.new(), --- @defaultProp
	PaddingTop = UDim.new(), --- @defaultProp
}

ButtonStack.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The Stack's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional LayoutOrder number THe Stack's layout order
	LayoutOrder = t.optional(t.number),

	--- @prop @optional Position UDim2 The Stack's position
	Position = t.optional(t.UDim2),

	--- @prop @optional FillWidth boolean Determines if buttons fill the entire Stack
	FillWidth = t.optional(t.boolean),

	--- @prop @optional Padding UDim The padding between each button
	Padding = t.optional(t.UDim),

	--- @prop @optional PaddingLeft UDim The left padding
	PaddingLeft = t.optional(t.UDim),

	--- @prop @optional PaddingRight UDim The right padding
	PaddingRight = t.optional(t.UDim),

	--- @prop @optional PaddingTop UDim The top padding
	PaddingTop = t.optional(t.UDim),

	--- @prop @optional PaddingBottom UDim The bottom padding
	PaddingBottom = t.optional(t.UDim),

	--- @prop @optional Size UDim2 The Stack's size
	Size = t.optional(t.UDim2),

	--- @prop @optional StackWidth UDim The space to fill
	StackWidth = t.optional(t.UDim),

	--- @prop Buttons table The props for the buttons to display
	Buttons = t.table,

	--- @prop @optional ButtonHeight UDim Each Button's height
	ButtonHeight = t.optional(t.UDim),

	--- @prop @optional ButtonAlignment Enum.HorizontalAlignment The aligmnent of buttons
	ButtonAlignment = t.optional(t.enum(Enum.HorizontalAlignment)),

	--- @prop @optional HorizontalAlignment Enum.HorizontalAlignment The Horizontal alignment of the buttons
	HorizontalAlignment = t.optional(t.enum(Enum.HorizontalAlignment)),

	--- @prop @optional VerticalAlignment Enum.VerticalAlignment The Vertical alignment of the buttons
	VerticalAlignment = t.optional(t.enum(Enum.VerticalAlignment)),

	--- @prop @optional MinSlack number The MinSlack width between the end of the buttons to the end of the stack before buttons fill the entire Stack
	MinSlack = t.optional(t.number),

	--- @prop @optional [Roact.Children] table Roact.Children
	[Roact.Children] = t.optional(t.table),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),
})

function ButtonStack:init()
	
	-- Initial state
	self:setState({
		Width = 0
	})
end

function ButtonStack:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)
		
		-- ////////// Buttons
		local Buttons = {}

		-- Get the divided size for each button
		local FullWidthSize = UDim2.new(1 / #props.Buttons)

		local IsFirstButton = true
		for ButtonIndex, ButtonProps in pairs(props.Buttons) do
			
			Buttons['Button' .. ButtonIndex] = new(Button, Sift.Dictionary.join(ButtonProps, {
				LayoutOrder = props.ButtonAlignment == Enum.HorizontalAlignment.Right and -ButtonIndex or ButtonIndex,
				Size = UDim2.new(FullWidthSize.X.Scale, FullWidthSize.X.Offset - (IsFirstButton and 0 or props.Padding.Offset), props.ButtonHeight.Scale, props.ButtonHeight.Offset),
			}))

			-- Register first button
			IsFirstButton = false
		end

		-- ////////// Button Container

		local ButtonContainer = new('Frame', {
			BackgroundTransparency = 1,
			Size = UDim2.new(props.StackWidth.Scale, props.StackWidth.Offset, 1, 0),
		}, {
			Buttons = Roact.createFragment(Buttons),
			
			Layout = new('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = props.HorizontalAlignment,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = props.VerticalAlignment,
				Padding = props.Padding,
			}),
		})

		-- ////////// Button Stack
		return new('Frame', Sift.Dictionary.join({
			AnchorPoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Position = props.Position,
			Size = props.Size,

			[Roact.Change.AbsoluteSize] = function (rbx)
				self:setState({
					Width = rbx.AbsoluteSize.X
				})
			end,
		}, props.Native), {
			ButtonContainer = ButtonContainer,
			PropChildren = Roact.createFragment(props[Roact.Children] or {}),

			Layout = new('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = props.HorizontalAlignment,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = props.VerticalAlignment,
			}),
			Padding = new('UIPadding', {
				PaddingTop = props.PaddingTop,
				PaddingBottom = props.PaddingBottom,
				PaddingLeft = props.PaddingLeft,
				PaddingRight = props.PaddingRight,
			}),
		})
	end)
end

return ButtonStack