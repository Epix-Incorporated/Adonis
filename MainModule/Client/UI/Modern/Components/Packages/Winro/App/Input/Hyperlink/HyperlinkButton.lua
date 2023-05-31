-- Hyperlink: Hyperlink Compoent

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme
local RegisterStateAction = Theme.RegisterStateAction
local ApplyDescription = Theme.ApplyDescription

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local HyperlinkRoot = script.Parent
local Descriptions = require(HyperlinkRoot.Descriptions)

local HYPERLINK_TRANSPARENCY_ANIMATION_OPTIONS = 'styles/AnimationSpringParams/Control/Input/Button/Color'
local HYPERLINK_COLOR_ANIMATION_OPTIONS = 'styles/AnimationSpringParams/Control/Input/Button/Transparency'

local HyperlinkButton = Roact.PureComponent:extend(script.Name)

HyperlinkButton.StyleBindings = {
	'Text',
}

HyperlinkButton.defaultProps = {
	Size = UDim2.fromScale(1, 1), --- @defaultProp
	Text = 'Hyperlink', --- @defaultProp
}

HyperlinkButton.validateProps = t.strictInterface({

	--- @prop @optional AutomaticSize Enum.AutmaticSize Autmatic size
	AutomaticSize = t.optional(t.enum(Enum.AutomaticSize)),

	--- @prop @optional Disabled boolean Determines if the HyperlinkButton shows as disabled
	Disabled = t.optional(t.boolean),

	--- @prop @optional Text string The hyperlink's text
	Text = t.optional(t.string),

	--- @prop @optional TextXAlignment Enum.TextXAlignment Horizontal text alignment
	TextXAlignment = t.optional(t.enum(Enum.TextXAlignment)),

	--- @prop @optional TextYAlignment Enum.TextYAlignment Vertical text alignment
	TextYAlignment = t.optional(t.enum(Enum.TextYAlignment)),

	--- @prop @optional Size UDim2 The Hyperlink's size
	Size = t.optional(t.UDim2),

	--- @prop @optional AnchorPoint Vector2 The Hyperlink's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional Position UDim2 The Hyperlink's positon
	Position = t.optional(t.UDim2),

	--- @prop @optional LayoutOrder number The Hyperlink's layout order
	LayoutOrder = t.optional(t.number),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),

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

function HyperlinkButton:init()

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

function HyperlinkButton:willUnmount()
	
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

function HyperlinkButton:ApplyDescription(Description, Theme)
	ApplyDescription(self, Description, Theme, Theme[HYPERLINK_COLOR_ANIMATION_OPTIONS], Theme[HYPERLINK_TRANSPARENCY_ANIMATION_OPTIONS])
end

function HyperlinkButton:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)
		
		-- Apply Description
		if props.Disabled then
			self:ApplyDescription(Descriptions.Disabled, Theme)
		elseif state.State == 'Rest' then
			self:ApplyDescription(Descriptions.Rest, Theme)
		elseif state.State == 'Hover' then
			self:ApplyDescription(Descriptions.Hover, Theme)
		elseif state.State == 'Pressed' then
			self:ApplyDescription(Descriptions.Pressed, Theme)
		end

		-- ////////// Hyperlink Button

		local HyperlinkButtonFontStyle = Theme['fonts/Body']

		return new('TextButton', Sift.Dictionary.join({
			AutomaticSize = props.AutomaticSize,
			AnchorPoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			FontFace = HyperlinkButtonFontStyle.Font,
			LayoutOrder = props.LayoutOrder,
			LineHeight = HyperlinkButtonFontStyle.LineHeight,
			Position = props.Position,
			Size = props.Size,
			Text = props.Text,
			TextSize = HyperlinkButtonFontStyle.Size,
			TextXAlignment = props.TextXAlignment,
			TextYalignment = props.TextYAlignment,

			[Roact.Event.Activated] = self[Roact.Event.Activated],
			[Roact.Event.MouseButton1Down] = self[Roact.Event.MouseButton1Down],
			[Roact.Event.MouseButton1Up] = self[Roact.Event.MouseButton1Up],
			[Roact.Event.MouseEnter] = self[Roact.Event.MouseEnter],
			[Roact.Event.MouseLeave] = self[Roact.Event.MouseLeave],

			TextColor3 = self.Text:map(function(Style)
				return Style.Color
			end),
			TextTransparency = self.Text:map(function(Style)
				return Style.Transparency
			end),
		}, props.Native))
	end)
end

return HyperlinkButton