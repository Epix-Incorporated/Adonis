-- DropdownButton: A button that is meant to be used as the button for dropdown components

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme
local ApplyDescription = Theme.ApplyDescription
local RegisterStateAction = Theme.RegisterStateAction

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local UIStroke = require(Winro.App.Effect.UIStroke)

local DROPDOWNBUTTON_CHEVRONDOWN_IMAGE = 'images/Fluent/ChevronDownMed/12px'
local DROPDOWNBUTTON_COLOR_ANIMATION_SPRING_SETTINGS = 'styles/AnimationSpringParams/Control/Input/Button/Color'
local DROPDOWNBUTTON_TRANSPARENCY_ANIMATION_SPRING_SETTINGS = 'styles/AnimationSpringParams/Control/Input/Button/Transparency'
local DROPDOWNBUTTON_LAYOUT_PADDING = 11
local DROPDOWNBUTTON_PADDING_HORIZONTAL = 11
local DROPDOWNBUTTON_PADDING_VERTICAL = 4

local DropdownRoot = script.Parent
local Descriptions = require(DropdownRoot.Descriptions.DropdownButtonDescriptions)

local DropdownButton = Roact.PureComponent:extend(script.Name)

DropdownButton.Descriptions = Descriptions

DropdownButton.StyleBindings = {
	'Stroke',
	'Fill',
	'Text',
}

DropdownButton.defaultProps = {
	Size = UDim2.fromOffset(120, 32), --- @defaultProp
}

DropdownButton.validateProps = t.strictInterface({

	--- @prop @optional Text string The DropdownButton's text
	Text = t.optional(t.string),

	--- @prop @optional AnchorPoint Vector2 The DropdownButton's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional Disabled boolean Determines if the DropdownButton is shown as disabled
	Disabled = t.optional(t.boolean),

	--- @prop @optional LayoutOrder number The DropdownButton's Layout order
	LayoutOrder = t.optional(t.number),

	--- @prop @optional Position UDim2 The DropdownButton's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 The DropdownButton's size
	Size = t.optional(t.UDim2),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),

	--- @prop @optional [Roact.Children] table Roact.Children
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

function DropdownButton:init()

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
		State = 'Rest',
	})
end

function DropdownButton:ApplyDescription(Description, Theme)
	ApplyDescription(self, Description, Theme, Theme[DROPDOWNBUTTON_COLOR_ANIMATION_SPRING_SETTINGS], Theme[DROPDOWNBUTTON_TRANSPARENCY_ANIMATION_SPRING_SETTINGS])
end

function DropdownButton:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)

		-- Apply description
		if props.Disabled then
			self:ApplyDescription(self.Descriptions.Disabled, Theme)
		elseif state.State == 'Rest' then
			self:ApplyDescription(self.Descriptions.Rest, Theme)
		elseif state.State == 'Hover' then
			self:ApplyDescription(self.Descriptions.Hover, Theme)
		elseif state.State == 'Pressed' then
			self:ApplyDescription(self.Descriptions.Pressed, Theme)
		end

		-- ////////// Chevron Icon
		
		local ChevronImageIcon = Theme[DROPDOWNBUTTON_CHEVRONDOWN_IMAGE]

		local Chevron = new('ImageButton', {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Image = ChevronImageIcon.Image,
			ImageRectOffset = ChevronImageIcon.ImageRectOffset,
			ImageRectSize = ChevronImageIcon.ImageRectSize,
			Position = UDim2.new(1, -DROPDOWNBUTTON_PADDING_HORIZONTAL, 0.5, 0),
			Size = UDim2.fromOffset(ChevronImageIcon.ImageRectSize.X, ChevronImageIcon.ImageRectSize.Y),

			ImageColor3 = self.Text:map(function(Style)
				return Style.Color
			end),
			ImageTransparency = self.Text:map(function(Style)
				return Style.Transparency
			end),
		})

		-- ////////// Button Label

		local LabelFontStyle = Theme['fonts/Body']

		local Label = new('TextLabel', {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			FontFace = LabelFontStyle.Font,
			LineHeight = LabelFontStyle.LineHeight,
			Position = UDim2.new(0, DROPDOWNBUTTON_PADDING_HORIZONTAL, 0.5, 0),
			Size = UDim2.new(0, 0),
			Text = props.Text,
			TextSize = LabelFontStyle.Size,
			TextXAlignment = Enum.TextXAlignment.Left,

			TextColor3 = self.Text:map(function(Style)
				return Style.Color
			end),
			TextTransparency = self.Text:map(function(Style)
				return Style.Transparency
			end)
		})

		-- ////////// Button Fill

		local Fill = new('Frame', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2), -- Account for stroke thickness

			BackgroundColor3 = self.Fill:map(function(Style)
				return Style.Color
			end),
			BackgroundTransparency = self.Fill:map(function(Style)
				return Style.Transparency
			end),
		}, {

			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Inner']),
			}),
			Stroke = new(UIStroke, {
				BorderMode = Enum.BorderMode.Outline,
			}, {

				Gradient = new('UIGradient', {
					Rotation = 90,

					Color = self.Stroke:map(function(Style)
						return Style.ColorSequence or ColorSequence.new(Style.Color)
					end),
					Transparency = self.Stroke:map(function(Style)
						return Style.TransparencySequence or NumberSequence.new(Style.Transparency)
					end),
				}),
			}),
		})

		-- ////////// Dropdown Button
		return new('ImageButton', Sift.Dictionary.join({
			AnchorPoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			Size = props.Size,
			Position = props.Position,
			LayoutOrder = props.LayoutOrder,

			[Roact.Event.Activated] = self[Roact.Event.Activated],
			[Roact.Event.MouseButton1Down] = self[Roact.Event.MouseButton1Down],
			[Roact.Event.MouseButton1Up] = self[Roact.Event.MouseButton1Up],
			[Roact.Event.MouseEnter] = self[Roact.Event.MouseEnter],
			[Roact.Event.MouseLeave] = self[Roact.Event.MouseLeave],
		}, props.Native), {
			Label = Label,
			Chevron = Chevron,
			Fill = Fill,

			ChildWrapper = props[Roact.Children] and new('Frame', {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, props[Roact.Children])
		})
	end)
end

return DropdownButton