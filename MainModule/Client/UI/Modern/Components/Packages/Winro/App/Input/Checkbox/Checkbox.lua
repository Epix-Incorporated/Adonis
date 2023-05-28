-- Checkbox: The basic checkbox component
-- https://www.figma.com/file/uNmIxgdbUT44MZjQCTIMe3/Windows-UI-3-(Community)?node-id=25616%3A1593

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme
local ApplyDescription = Theme.ApplyDescription
local RegisterStateAction = Theme.RegisterStateAction

local Validators = Winro.Validators
local StyleValidator = require(Validators.StyleValidator)

local Flipper = require(Packages.Flipper)
local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local CheckboxRoot = script.Parent
local Descriptions = require(CheckboxRoot.Descriptions.CheckboxStateDescriptions)
local GetSelectedStateFromValue = require(CheckboxRoot.Util.GetSelectedStateFromValue)

local CHECKBOX_COLOR_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/Input/Checkbox/Color"
local CHECKBOX_TRANSPARENCY_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/Input/Checkbox/Transparency"
local CHECKBOX_CHECKED = "images/Fluent/AcceptMedium/12px"
local CHECKBOX_INDETERMINATE = "images/Fluent/Dash12/12px"
local LABEL_FONT = "font/Body"
local CHECKBOX_LEFT_MARGIN = 4

local Checkbox = Roact.PureComponent:extend(script.Name)

Checkbox.StyleBindings = {
	'Check',
	'Fill',
	'Stroke',
	'Text',
}

Checkbox.defaultProps = {
	Size = UDim2.fromOffset(20, 20) --- @defaultProp
}

Checkbox.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The Checkbox's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional @style Font string|table The label's font style
	Font = t.optional(StyleValidator),

	--- @prop @optional Position UDim2 The Checkbox's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 The Checkbox's size
	Size = t.optional(t.UDim2),

	--- @prop Selected boolean The Checkbox's selected status
	Selected = t.optional(t.boolean),

	--- @prop @optional Label string The Checkbox's label
	Label = t.optional(t.string),

	--- @prop @optional TextWrapped boolean For the `Label` prop
	TextWrapped = t.optional(t.boolean),

	--- @prop @optional @style TextColor string|table The label's text color style
	TextColor = t.optional(StyleValidator),

	--- @prop @optional Disabled boolean Determines if the Checkbox is disabled
	Disabled = t.optional(t.boolean),

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

function Checkbox:init()

	-- Create Style Bindings
	for _, StyleBinding in pairs(self.StyleBindings) do
		self[StyleBinding], self['Set' .. StyleBinding] = Roact.createBinding({})
	end

	-- Custom Style binding
	self.CheckObscureWidth, self.SetCheckObscureWidth = Roact.createBinding(0)

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

function Checkbox:willUnmount()

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

function Checkbox:ApplyDescription(Description, Theme)
	Description = Sift.Dictionary.copy(Description)

	-- Custom style binding
	local CheckObscureWidth = self.CheckObscureWidth:getValue()
	
	-- Animate
	if CheckObscureWidth then

		-- Remove exiting motor
		local Existing = self.CheckObscureWidthMotor
		if Existing then
			pcall(Existing.destroy, Existing)
		end

		-- Create a new motor
		local Motor = Flipper.SingleMotor.new(CheckObscureWidth)
		self.CheckObscureWidthMotor = Motor

		-- Bind
		Motor:onStep(self.SetCheckObscureWidth)
		Motor:onComplete(function()
			Motor:destroy()
			self.CheckObscureWidthMotor = nil
		end)

		-- Animate
		Motor:setGoal(Flipper.Spring.new(Description.CheckObscureWidth, {
			frequency = 2.5,
			dampingRatio = 1,
		}))
	else
		self.SetCheckObscureWidth(Description.CheckObscureWidth)
	end

	-- Prop overrides
	local TextStyleOverride = self.props.TextColor

	if TextStyleOverride then
		Description.Text = TextStyleOverride
	end

	ApplyDescription(self, Description, Theme, Theme[CHECKBOX_COLOR_ANIMATION_SPRING_SETTINGS], Theme[CHECKBOX_TRANSPARENCY_ANIMATION_SPRING_SETTINGS])
end

function Checkbox:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)
		local SelectedState = GetSelectedStateFromValue(props.Selected)

		-- Apply Description
		if SelectedState == 'None' then
			if props.Disabled then
				self:ApplyDescription(Descriptions.NoFill.Disabled, Theme)
			elseif state.State == 'Rest' then
				self:ApplyDescription(Descriptions.NoFill.Rest, Theme)
			elseif state.State == 'Hover' then
				self:ApplyDescription(Descriptions.NoFill.Hover, Theme)
			else
				self:ApplyDescription(Descriptions.NoFill.Pressed, Theme)
			end
		else
			if props.Disabled then
				self:ApplyDescription(Descriptions.Fill.Disabled, Theme)
			elseif state.State == 'Rest' then
				self:ApplyDescription(Descriptions.Fill.Rest, Theme)
			elseif state.State == 'Hover' then
				self:ApplyDescription(Descriptions.Fill.Hover, Theme)
			else
				self:ApplyDescription(Descriptions.Fill.Pressed, Theme)
			end
		end

		-- ////////// Checkbox Label

		local LabelFont = Theme[props.Font or LABEL_FONT]

		local Label = props.Label and new('TextLabel', {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			FontFace = LabelFont.Font,
			Position = UDim2.new(0, props.Size.X.Offset + 20 + CHECKBOX_LEFT_MARGIN, 0.5, 0),
			Size = UDim2.new(1, -30, 1, 0),
			Text = props.Label,
			TextSize = LabelFont.Size,
			TextXAlignment = 'Left',

			TextColor3 = self.Text:map(function(Style)
				return Style.Color
			end),
			TextTransparency = self.Text:map(function(Style)
				return Style.Transparency
			end),
		})
		
		-- ////////// Check animation gradient

		local Gradient = new('UIGradient', {
			Transparency = NumberSequence.new({
				[1] = NumberSequenceKeypoint.new(0.0, 0),
				[2] = NumberSequenceKeypoint.new(0.001, 0),
				[3] = NumberSequenceKeypoint.new(0.002, 1),
				[4] = NumberSequenceKeypoint.new(1, 1)
			}),
			Offset = self.CheckObscureWidth:map(function(Width)
				return Vector2.new(1 - Width, 0)
			end)
		})

		-- ////////// Checkbox Icon
		
		local CheckStyle = Theme[SelectedState == 'Selected' and CHECKBOX_CHECKED or CHECKBOX_INDETERMINATE]

		local Check = new('ImageLabel', {
			Visible = SelectedState ~= 'None',
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ResampleMode = CheckStyle.ResampleMode,
			Image = CheckStyle.Image,
			ImageRectOffset = CheckStyle.ImageRectOffset,
			ImageRectSize = CheckStyle.ImageRectSize,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(CheckStyle.ImageRectSize.X, CheckStyle.ImageRectSize.Y),

			ImageColor3 = self.Check:map(function(Style)
				return Style.Color
			end),
			ImageTransparency = self.Check:map(function(Style)
				return Style.Transparency
			end),
		}, {
			ObscureGradient = Gradient
		})

		-- ////////// Checkbox Stroke

		local Stroke = new('UIStroke', {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,

			Color = self.Stroke:map(function(Style)
				return Style.Color
			end),
			Transparency = self.Stroke:map(function(Style)
				return Style.Transparency
			end),
		})
		
		-- ////////// Checkbox Base

		local Checkbox = new('ImageButton', {
			AnchorPoint = Vector2.new(0, 0.5),
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 1 + (props.Label and CHECKBOX_LEFT_MARGIN or 0), 0.5, 0),
			Size = props.Size - UDim2.fromOffset(2, 2), -- Target size is 20px * 20px, but border adds 2px each axis
			
			[Roact.Event.Activated] = self[Roact.Event.Activated],
			[Roact.Event.MouseButton1Down] = self[Roact.Event.MouseButton1Down],
			[Roact.Event.MouseButton1Up] = self[Roact.Event.MouseButton1Up],
			[Roact.Event.MouseEnter] = self[Roact.Event.MouseEnter],
			[Roact.Event.MouseLeave] = self[Roact.Event.MouseLeave],

			BackgroundColor3 = self.Fill:map(function(Style)
				return Style.Color
			end),
			BackgroundTransparency = self.Fill:map(function(Style)
				return Style.Transparency
			end),
		}, {
			Check = Check,
			Stroke = Stroke,

			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Inner'] - 1) -- Account for the 1px added by UIStroke
			}),
		})

		-- ////////// Checkbox

		return new('Frame', Sift.Dictionary.join({
			AnchorPoint = props.AnchorPoint,
			Position = props.Position,
			BackgroundTransparency = 1,
			Size = props.Size
		}, props.Native), {
			Checkbox = Checkbox,
			Label = Label
		})
	end)
end

return Checkbox