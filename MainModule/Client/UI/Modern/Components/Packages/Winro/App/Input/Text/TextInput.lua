-- TextInput: A string input component, a textbox

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

local TextRoot = script.Parent
local Descriptions = require(TextRoot.Descriptions.TextInputDescriptions)

local TEXTINPUT_COLOR_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/Input/Button/Color"
local TEXTINPUT_TRANSPARENCY_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/Input/Button/Transparency"

local TextInput = Roact.PureComponent:extend(script.Name)

TextInput.StyleBindings = {
	'Button',
	'Highlight',
	'Stroke',
	'Text',
}

TextInput.defaultProps = {

	--- @prop @optional Text string Current text
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
}

TextInput.validateProps = t.strictInterface({

})

function TextInput:init()
	local props = self.props

	-- Text value binding
	self.Text, self.SetText = Roact.createBinding(props.Text)

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

function TextInput:willUnmount()

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

function TextInput:ApplyDescription(Description, Theme)
	return ApplyDescription(self, Description, Theme,  Theme[TEXTINPUT_COLOR_ANIMATION_SPRING_SETTINGS], Theme[TEXTINPUT_TRANSPARENCY_ANIMATION_SPRING_SETTINGS])
end

function TextInput:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)
		
		-- Apply description
		if state.State == 'Focused' then
			
		end
	end)
end

return TextInput