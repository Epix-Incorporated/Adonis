-- CheckboxGroup: A grouped collection of CheckBox elements
-- https://www.figma.com/file/uNmIxgdbUT44MZjQCTIMe3/Windows-UI-3-(Community)?node-id=25616%3A1593

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local CheckboxRoot = script.Parent
local Checkbox = require(CheckboxRoot.Checkbox)

local CheckboxGroup = Roact.PureComponent:extend(script.Name)

CheckboxGroup.defaultProps = {
	HeaderFont = 'fonts/Body', --- @defaultProp
	HeaderTextColor = 'colors/Fill_Color/Text/Primary', --- @defaultProp
	HeaderHeight = 21, --- @defaultProp
	FitContents = false, --- @defaultProp
	Size = UDim2.new(1, 0, 1, 0), --- @defaultProp
}

CheckboxGroup.validateProps = t.strictInterface({
	
	--- @prop @optional HeaderText string The CheckboxGroup's header text
	HeaderText = t.string,

	--- @prop Checkboxes table {CheckboxProps} The checkboxes to display
	Checkboxes = t.table,

	--- @prop @optional Size UDim2 The CheckboxGroup's size
	Size = t.optional(t.UDim2),

	--- @prop @optional FitContents boolean Determines if the CheckboxGroup will resize to fit its contents
	FitContents = t.optional(t.boolean),

	--- @prop @optional @style HeaderTextColor string The color of the header's text
	HeaderTextColor = t.optional(t.string),

	--- @prop @optional @style HeaderFont string The font of the header
	HeaderFont = t.optional(t.string),

	--- @prop @optional HeaderHeight number The height, in pixels of the header
	HeaderHeight = t.optional(t.numberPositive),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table)
})

function CheckboxGroup:init()

	-- CheckboxGroup Checkbox Container height
	self.ContainerHeight, self.SetContainerHeight = Roact.createBinding(0)
end

function CheckboxGroup:GetCheckboxes()
	local props = self.props

	local Checkboxes = {}

	for Index, props in pairs(props.Checkboxes) do
		Checkboxes[Index] = new(Checkbox, props)
	end

	return Checkboxes
end

function CheckboxGroup:render()
	local props = self.props

	return WithTheme(function(Theme)
		
		-- ////////// CheckboxGroup Header Label
		
		local HeaderTextColor = Theme[props.HeaderTextColor]
		local HeaderFont = Theme[props.HeaderFont]

		local Label = new('TextLabel', {
			BackgroundTransparency = 1,
			FontFace = HeaderFont.Font,
			Position = UDim2.fromOffset(3, 1),
			Size = UDim2.new(1, -3, 1, -1),
			Text = props.HeaderText,
			TextColor3 = HeaderTextColor.Color,
			TextSize = HeaderFont.Size,
			TextTransparency = HeaderTextColor.Transparency,
			TextXAlignment = 'Left',
		})

		-- ////////// CheckboxGroup Header

		local Header = new('Frame', {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, props.HeaderHeight),
		}, {
			Label = Label,
		})

		-- ////////// CheckboxGroup Container

		local CheckboxContainer = new('Frame', {
			AutomaticSize = props.FitContents and 'Y' or 'None',
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, props.HeaderHeight),
			
			[Roact.Change.AbsoluteSize] = function(rbx)
				self.SetContainerHeight(rbx.AbsoluteSize.Y)
			end,

			Size = self.ContainerHeight:map(function(Height)

				-- Do not auto-size if FitContents is not set
				if not props.FitContents then
					return props.Size
				end

				return UDim2.new(1, 0, 0, Height)
			end),
		}, {
			Checkboxes = Roact.createFragment(self:GetCheckboxes()),

			InitialPadding = new('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = -1,
				Size = UDim2.new(1, 0, 0, 8)
			}),
			Layout = new('UIListLayout', {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder
			}),
		})

		-- ////////// CheckboxGroup
		return new('Frame', Sift.Dictionary.join({
			BackgroundTransparency = 1,
			Size = self.ContainerHeight:map(function(Height)

				-- Do not auto-size if FitContents is not set
				if not props.FitContents then
					return props.Size
				end

				return UDim2.new(props.Size.X.Scale, props.Size.X.Offset, 0, Height + props.HeaderHeight)
			end)
		}, props.Native), {
			Header = Header,
			CheckboxContainer = CheckboxContainer
		})
	end)
end

return CheckboxGroup