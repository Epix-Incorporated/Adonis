-- Button: The basic button component
-- https://www.figma.com/file/uNmIxgdbUT44MZjQCTIMe3/Windows-UI-3-(Community)?node-id=24412%3A121169

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme
local ApplyDescription = Theme.ApplyDescription
local RegisterStateAction = Theme.RegisterStateAction

local Validators = Winro.Validators
local StyleValidator = require(Validators.StyleValidator)

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ButtonRoot = script.Parent
local ButtonStyleValidator = require(ButtonRoot.Validators.ButtonStyleValidator)
local Descriptions = require(ButtonRoot.Descriptions.ButtonStateDescriptions)

local BUTTON_COLOR_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/Input/Button/Color"
local BUTTON_TRANSPARENCY_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/Input/Button/Transparency"

local Button = Roact.PureComponent:extend(script.Name)

Button.StyleBindings = {
	'Fill',
	'Stroke',
	'Text',
}

Button.defaultProps = {
	AnchorPoint = Vector2.new(0.5, 0.5), --- @defaultProp
	BorderSizePixel = 1, --- @defaultProp
	Font = "fonts/Body", --- @defaultProp
	Position = UDim2.fromScale(0.5, 0.5), --- @defaultProp
	Size = UDim2.fromOffset(240, 30), --- @defaultProp
	Style = 'Standard', --- @defaultProp
	Text = 'Text', --- @defaultProp
}

Button.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The Button's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional @style BackgroundColor string|table The style to use for the Button's background color
	BackgroundColor = t.optional(StyleValidator),

	--- @prop @optional @style BorderColor string|table The button's border style
	BorderColor = t.optional(StyleValidator),

	--- @prop @optional BorderSizePixel number The size, in pixels, of the border
	BorderSizePixel = t.optional(t.numberPositive),

	--- @prop @optional CornerRadius UDim The radius of the Button's corners
	CornerRadius = t.optional(t.UDim),

	--- @prop @optional Disabled boolean If `true`, the button will appear as disabled
	Disabled = t.optional(t.boolean),

	--- @prop @optional @style Font string|table The font style of the Button's text
	Font = t.optional(StyleValidator),

	--- @prop @optional LayoutOrder number The Button's layout order
	LayoutOrder = t.optional(t.number),

	--- @prop @optional Position UDim2 The Button's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 The Button's size
	Size = t.optional(t.UDim2),

	--- @prop @optional Style string The Button's style
	Style = t.optional(ButtonStyleValidator),

	--- @prop @optional Text string The Button's text
	Text = t.optional(t.string),

	--- @prop @optional Native table The native props
	Native = t.optional(t.table),

	--- @prop @optional [Roact.Children] table Child contents
	[Roact.Children] = t.optional(t.table),

	--- @prop @optional [Roact.Event.Activated] function Roact.Event.Activated
	[Roact.Event.Activated] = t.optional(t.callback),

	--- @prop @optional [Roact.Event.MouseButton1Down] function Roact.Event.MouseButton1Down
	[Roact.Event.MouseButton1Down] = t.optional(t.callback),

	--- @prop @optional [Roact.Event.MouseButton1Up] function Roact.Event.MouseButton1Up
	[Roact.Event.MouseButton1Up] = t.optional(t.callback),

	--- @prop @optional [Roact.Event.MouseEnter] function Roact.Event.MouseEnter
	[Roact.Event.MouseEnter] = t.optional(t.callback),

	--- @prop @optional [Roact.Event.MouseLeave] function Roact.Event.MouseLeave
	[Roact.Event.MouseLeave] = t.optional(t.callback),
})

function Button:init()

	-- Create Style Bindings
	for _, StyleBinding in pairs(self.StyleBindings) do
		self[StyleBinding], self['Set' .. StyleBinding] = Roact.createBinding({})
	end

	-- Actions
	RegisterStateAction(self, Roact.Event.Activated, nil)
	RegisterStateAction(self, Roact.Event.MouseButton1Down, 'Pressed')
	RegisterStateAction(self, Roact.Event.MouseButton1Up, 'Hover')
	RegisterStateAction(self, Roact.Event.MouseEnter, 'Hover')
	RegisterStateAction(self, Roact.Event.MouseLeave, 'Rest')

	-- Initial State
	self:setState({
		State = 'Rest'
	})
end

function Button:willUnmount()

	-- Clear motors for each style binding
	for _, StyleBinding in pairs(self.StyleBindings) do

		-- Look for a motor
		local Motor = self[StyleBinding .. 'Motor']

		-- Remove motor if found
		if Motor then
			pcall(Motor.destroy, Motor)
			self[StyleBinding .. 'Motor'] = nil
		end
	end
end

function Button:ApplyDescription(Description, Theme)
	local props = self.props
	Description = Sift.Dictionary.copy(Description)
	
	-- Prop Overrides
	local FillOverride = props.BackgroundColor
	local StrokeOverride = props.BorderColor
	local TextOverride = props.TextColor

	if FillOverride then
		Description.Fill = FillOverride
	end

	if StrokeOverride then
		Description.Stroke = StrokeOverride
	end

	if TextOverride then
		Description.Text = TextOverride
	end

	ApplyDescription(self, Description, Theme, Theme[BUTTON_COLOR_ANIMATION_SPRING_SETTINGS], Theme[BUTTON_TRANSPARENCY_ANIMATION_SPRING_SETTINGS])
end

function Button:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)

		-- Apply Description
		if props.Style == 'Accent' then
			if props.Disabled then
				self:ApplyDescription(Descriptions.Accent.Disabled, Theme)
			elseif state.State == 'Rest' then
				self:ApplyDescription(Descriptions.Accent.Rest, Theme)
			elseif state.State == 'Hover' then
				self:ApplyDescription(Descriptions.Accent.Hover, Theme)
			elseif state.State == 'Pressed' then
				self:ApplyDescription(Descriptions.Accent.Pressed, Theme)
			end
		elseif props.Style == 'Standard' or props.Style == 'Default' then
			if props.Disabled then
				self:ApplyDescription(Descriptions.Standard.Disabled, Theme)
			elseif state.State == 'Rest' then
				self:ApplyDescription(Descriptions.Standard.Rest, Theme)
			elseif state.State == 'Hover' then
				self:ApplyDescription(Descriptions.Standard.Hover, Theme)
			elseif state.State == 'Pressed' then
				self:ApplyDescription(Descriptions.Standard.Pressed, Theme)
			end
		elseif props.Style == 'Primary' then
			if props.Disabled then
				self:ApplyDescription(Descriptions.Primary.Disabled, Theme)
			elseif state.State == 'Rest' then
				self:ApplyDescription(Descriptions.Primary.Rest, Theme)
			elseif state.State == 'Hover' then
				self:ApplyDescription(Descriptions.Primary.Hover, Theme)
			elseif state.State == 'Pressed' then
				self:ApplyDescription(Descriptions.Primary.Pressed, Theme)
			end
		elseif props.Style == 'Secondary' then
			if props.Disabled then
				self:ApplyDescription(Descriptions.Secondary.Disabled, Theme)
			elseif state.State == 'Rest' then
				self:ApplyDescription(Descriptions.Secondary.Rest, Theme)
			elseif state.State == 'Hover' then
				self:ApplyDescription(Descriptions.Secondary.Hover, Theme)
			elseif state.State == 'Pressed' then
				self:ApplyDescription(Descriptions.Secondary.Pressed, Theme)
			end
		end

		-- ////////// Button Stroke

		local Stroke = new('UIStroke', {
			Enabled = not props.Disabled,
			ApplyStrokeMode = 'Border',
			Thickness = props.BorderSizePixel,

			Color = self.Stroke:map(function(Style)
				return Style.Color
			end),
		}, {

			Gradient = new('UIGradient', {
				Rotation = 90,

				Color = self.Stroke:map(function(Style)
					return (Style.ColorSequence or ColorSequence.new(Style.Color))
				end),
				Transparency = self.Stroke:map(function(Style)
					return (Style.TransparencySequence or NumberSequence.new(Style.Transparency))
				end),
			})
		})

		-- ////////// Button

		local ButtonFont = Theme[props.Font]

		local Button = new('TextButton', {
			AutoButtonColor = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = ButtonFont.Font,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1) - UDim2.fromOffset(2, 2), -- Account for stroke thickness
			Text = props.Text,
			TextSize = ButtonFont.Size,

			BackgroundColor3 = self.Fill:map(function(Style)
				return Style.Color
			end),
			BackgroundTransparency = self.Fill:map(function(Style)
				return Style.Transparency
			end),
			TextColor3 = self.Text:map(function(Style)
				return Style.Color
			end),
			TextTransparency = self.Text:map(function(Style)
				return Style.Transparency
			end),

			[Roact.Event.Activated] = self[Roact.Event.Activated],
			[Roact.Event.MouseButton1Down] = self[Roact.Event.MouseButton1Down],
			[Roact.Event.MouseButton1Up] = self[Roact.Event.MouseButton1Up],
			[Roact.Event.MouseEnter] = self[Roact.Event.MouseEnter],
			[Roact.Event.MouseLeave] = self[Roact.Event.MouseLeave],
		}, {
			Stroke = Stroke,

			Corners = new('UICorner', {
				CornerRadius = props.CornerRadius or UDim.new(0, Theme['styles/CornerRadius/Default/Inner']),
			}),
		})

		-- ////////// Content Wrapper

		local ContentWrapper = props[Roact.Children] and new('Frame', {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, props[Roact.Children]) or nil

		-- ////////// Button Wrapper
		return new('Frame', Sift.Dictionary.join({
			AnchorPoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Position = props.Position,
			Size = props.Size,
		}, props.Native), {
			Button = Button,
			ContentWrapper = ContentWrapper,
		})
	end)
end

return Button