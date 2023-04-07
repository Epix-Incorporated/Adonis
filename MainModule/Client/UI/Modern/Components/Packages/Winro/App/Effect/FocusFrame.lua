-- FocusFrame: This frame will show above all other ui

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local FocusFrame = Roact.PureComponent:extend(script.Name)

FocusFrame.defaultProps = {
	Priority = 1, --- @defaultProp
	RelativeToParent = false, --- @defaultProp
	ConsumeInput = true, --- @defaultProp
	BackgroundTransparency = 1, --- @defaultProp
	Size = UDim2.fromScale(1, 1), --- @defaultProp
}

FocusFrame.validateProps = t.interface({
	
	--- @prop @optional Priority number THe priority the frame will be shown at
	Priority = t.optional(t.number),

	--- @prop Reason string The reason that this frame is being used for orver another frame, this is for futureproofing, a few examples are: DROPDOWN, TOOLTIP, MOUSECURSORADORNMENT
	Reason = t.string,

	--- @prop @optional RelativeToParent boolean Determines if the position is relative to the Frame's parent
	RelativeToParent = t.optional(t.boolean),

	--- @prop @optional ConsumeInput boolean If true, the FocusFrame will block all input to other components, any attempt to interact with external components will cause the focus to be lost
	ConsumeInput = t.optional(t.boolean),

	--- @prop @optional [Roact.Event.FocusLost] function The functin to call when the focus is lost
	[Roact.Event.FocusLost] = t.optional(t.callback),
})

function FocusFrame:init()
	local props = self.props

	-- Connection container
	self.Connections = {}

	-- ////////// Safe Props

	local SafeProps =  Sift.Dictionary.copy(props)

	-- Remove unsafe props
	SafeProps.Priority = nil
	SafeProps.RelativeToParent = nil
	SafeProps.Reason = nil
	SafeProps.ConsumeInput = nil
	SafeProps[Roact.Event.FocusLost] = nil

	-- Register safe props
	self.SafeProps = SafeProps

	-- ////////// Wrapper Frame

	-- Frame reference for mirroring size and position
	self.rbx = props[Roact.Ref] or Roact.createRef() -- Roact does not support multiple refs, use provided
end

function FocusFrame:didMount()
	local SafeProps = self.SafeProps

	-- ////////// Wrapper Frame

	-- Create a wrapper frame
	local WrapperFrame = Instance.new('Frame')
	
	for Property, Value in pairs(SafeProps) do

		-- Avoid Roact PropMarkers
		if typeof(Property) ~= 'string' then
			continue
		end

		WrapperFrame[Property] = Value
	end

	-- Register
	self.WrapperFrame = WrapperFrame

	-- ////////// Mirror

	-- Mirror
	self:Update()

	local rbx = self.rbx.current
	local Gui = rbx:FindFirstAncestorWhichIsA('GuiMain') or rbx:FindFirstAncestorWhichIsA('PluginGui')

	self.Connections.Changed = rbx.Changed:Connect(function()
		self:Update()
	end)
end

function FocusFrame:didUpdate()
	self:Update()
end

function FocusFrame:Update()
	local props = self.props
	local rbx = self.rbx.current
	local WrapperFrame = self.WrapperFrame

	local Gui = rbx:FindFirstAncestorWhichIsA('GuiMain') or rbx:FindFirstAncestorWhichIsA('PluginGui')

	if not Gui then
		return
	end

	-- ////////// Input Consumer

	if props.ConsumeInput and not self.InputConsumer then

		local InputConsumer = Instance.new('ImageButton')
		InputConsumer.BackgroundTransparency = 1
		InputConsumer.Size = UDim2.fromScale(1, 1)

		-- Sink input
		self.Connections.InputConsumerHover = InputConsumer.MouseEnter:Connect(function()end)
		self.Connections.InputConsumerFocusLost = InputConsumer.MouseButton1Down:Connect(function()
			self:ReleaseFocus()
		end)

		self.InputConsumer = InputConsumer
		InputConsumer.Parent = Gui

		local ScrollConsumer = Instance.new('ScrollingFrame')
		ScrollConsumer.Size = UDim2.fromScale(1, 1)
		ScrollConsumer.ScrollingEnabled = true
		ScrollConsumer.CanvasSize = UDim2.fromScale(1, 1)
		ScrollConsumer.BorderSizePixel = 1
		ScrollConsumer.BackgroundTransparency = 1
		ScrollConsumer.ScrollBarImageTransparency = 1
		ScrollConsumer.ScrollBarThickness = 0

		ScrollConsumer.Parent = InputConsumer

	end

	-- ////////// Wrapper Frame

	local AbsoluteSize = rbx.AbsoluteSize
	local AbsolutePosition = rbx.AbsolutePosition
	local AbsoluteRotation = rbx.AbsoluteRotation

	WrapperFrame.Size = UDim2.fromOffset(AbsoluteSize.X, AbsoluteSize.Y)
	WrapperFrame.Position = UDim2.fromOffset(AbsolutePosition.X, AbsolutePosition.Y)
	WrapperFrame.Rotation = AbsoluteRotation

	-- Move children
	for _, Child in pairs(rbx:GetChildren()) do
		Child.Parent = WrapperFrame
	end

	-- Priority level
	WrapperFrame.ZIndex = props.Priority

	-- Show above all Gui with the MainGui
	WrapperFrame.Parent = Gui
end

function FocusFrame:ReleaseFocus()

	if self.props[Roact.Event.FocusLost] then
		task.spawn(self.props[Roact.Event.FocusLost], self.rbx.current)
	end
end

function FocusFrame:Cleanup()
	self.WrapperFrame:Destroy()

	if self.InputConsumer then
		self.InputConsumer:Destroy()
	end

	for _, Connection in pairs(self.Connections) do
		pcall(Connection.Disconnect, Connection)
	end
end

function FocusFrame:willUnmount()
	self:Cleanup()
end

function FocusFrame:render()
	local SafeProps = self.SafeProps

	-- ////////// FocusFrame
	return new('Frame', Sift.Dictionary.join({
		[Roact.Ref] = self.rbx,
	}, SafeProps))
	
end

return FocusFrame