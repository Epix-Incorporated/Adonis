-- Window: A component that is the base structure for a UI Window

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

local UserInputService = game:GetService('UserInputService')

local DropShadow = require(Winro.App.Effect.DropShadow)
local RoundedSurface = require(Winro.App.Surface.RoundedSurface)

local WindowRoot = script.Parent
local TitleBar = require(WindowRoot.TitleBar.TitleBar)

local Window = Roact.PureComponent:extend(script.Name)

Window.defaultProps = {
	AnchorPoint = Vector2.new(0.5, 0.5), --- @defaultProp
	BackgroundColor = 'colors/Background/Fill_Color/Solid_Background/Base', --- @defaultProp
	ContentBackgroundColor = {
		Color = Color3.new(),
		Transparency = 1,
	}, --- @defaultProp
	DropShadowEnabled = true, --- @defaultProp
	Draggable = true, --- @defaultProp
	FooterHeight = 0, --- @defaultProp
	Position = UDim2.fromScale(0.5, 0.5), --- @defaultProp
	Size = UDim2.fromOffset(300, 300), --- @defaultProp
	TitleBarProps = {}, --- @defaultProp
}

Window.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The Window's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional @style BackgroundColor string|table The Window's background color
	BackgroundColor = t.optional(StyleValidator),

	--- @prop @optional @style ContentBackgroundColor string|table The Content's background color
	ContentBackgroundColor = t.optional(StyleValidator),

	--- @prop @optional DropShadowEnabled boolean Determines if a drop shadow is shown
	DropShadowEnabled = t.optional(t.boolean),

	--- @prop @optional Draggable boolean Determines if the window can be dragged via the TopBar
	Draggable = t.optional(t.boolean),

	--- @prop @optional AutomaticSize Enum.AutomaticSize Auto sizing
	AutomaticSize = t.optional(t.EnumItem),

	--- @prop @optional FooterHeight number The Footer's height, in pixels
	FooterHeight = t.optional(t.number),

	--- @prop @optional FooterContents table The contents to display in the footer
	FooterContents = t.optional(t.table),

	--- @prop @optional Position UDim2 The Window's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 The Window's size
	Size = t.optional(t.UDim2),

	--- @prop @optional TitleBarProps table The props to be provided to the Title Bar
	TitleBarProps = t.optional(t.table),

	--- @prop @optional [Roact.Children] table The contents to display in the window area
	[Roact.Children] = t.optional(t.table),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),
})

function Window:init()
	
	-- Size binding, for FitContents
	self.Size, self.SetSize = Roact.createBinding(self.props.Size)

	-- TitleBar ref, for dragging and for height sizing
	self.TitleBarRef = Roact.createRef()

	-- Window ref, for dragging
	self.WindowRef = Roact.createRef()
	
	-- Connection, for dragging
	if self.props.Draggable then
		
		self.DragConnection = UserInputService.InputChanged:Connect(function(Input)

			-- Get the window
			local Window = self.WindowRef:getValue()

			-- Validate that this is drag input
			if Window and Input == self.DragInput and self.Dragging then

				local Delta = Input.Position - self.DragStart

				-- Set the position
				Window.Position = UDim2.new(self.StartPos.X.Scale, self.StartPos.X.Offset + Delta.X, self.StartPos.Y.Scale, self.StartPos.Y.Offset + Delta.Y)
			end
		end)
	end
end

function Window:willUnmount()
	
	if self.DragConnection then
		self.DragConnection:Disconnect()
	end
end

function Window:didMount()
	
	local TitleBar = self.TitleBarRef:getValue()
	local Window = self.WindowRef:getValue()

	-- Sizing
	if TitleBar then
		TitleBar:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
			local AbsoluteSize = TitleBar.AbsoluteSize
			self.TitleBarHeight = AbsoluteSize.Y
		end)
	end
	
	if TitleBar and Window and self.props.Draggable then
		TitleBar.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				self.Dragging = true
				self.DragStart = Input.Position
				self.StartPos = Window.Position
				
				local Connection = nil
				Connection = Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						self.Dragging = nil
						Connection:Disconnect()
					end
				end)
			end
		end)
		
		TitleBar.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
				self.DragInput = Input
			end
		end)
	end
end

function Window:render()
	local props = self.props

	return WithTheme(function(Theme)
	
		-- ////////// Title Bar

		local TitleBar = new(TitleBar, Sift.Dictionary.join({
			LayoutOrder = 1,
			Height = 32,--28,
			CaptionButtonWidth = 45,
			Native = {
				[Roact.Ref] = self.TitleBarRef,
			}
		}, props.TitleBarProps))

		-- ////////// Content Wrapper

		local ContentWrapperFillStyle = Theme[props.ContentBackgroundColor]

		local ContentWrapper = new(RoundedSurface, {
			AutomaticSize = props.AutomaticSize,
			BackgroundColor3 = ContentWrapperFillStyle.Color,
			BackgroundTransparency = ContentWrapperFillStyle.Transparency,
			BorderSizePixel = 0,
			CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Outer']),
			ShowBottomLeftCorner = props.FooterHeight < Theme['styles/CornerRadius/Default/Outer'] / 2,
			ShowBottomRightCorner = props.FooterHeight < Theme['styles/CornerRadius/Default/Outer'] / 2,
			LayoutOrder = 2,
			Size = props.Size,

			[Roact.Change.AbsoluteSize] = function (rbx)
				local AbsoluteSize = rbx.AbsoluteSize
				self.SetSize(UDim2.fromOffset(AbsoluteSize.X, AbsoluteSize.Y))
			end
		}, self.props[Roact.Children])

		-- ////////// Footer

		local Footer = new('Frame', {
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, props.FooterHeight),
		}, props.FooterContents)

		-- ////////// Window

		local WindowFillStyle = Theme[props.BackgroundColor]
		local StrokeStyle = Theme['colors/Stroke_Color/Surface_Stroke/Default']

		local Window = new('Frame', Sift.Dictionary.join({
			AnchorPoint = props.DropShadowEnabled and Vector2.new(0.5, 0.5) or props.AnchorPoint,
			Position = props.DropShadowEnabled and UDim2.fromScale(0.5, 0.5) or props.Position,
			BackgroundColor3 = WindowFillStyle.Color,
			BackgroundTransparency = WindowFillStyle.Transparency,

			[Roact.Ref] = (not props.Draggable) and self.WindowRef or nil,

			Size = self.Size:map(function(Size)
				return Size + UDim2.fromOffset(0, (self.TitleBarHeight or 0) + props.FooterHeight)
			end),
		}, props.Native), {
			TitleBar = TitleBar,
			ContentWrapper = ContentWrapper,
			Footer = Footer,
			
			Stroke = new('UIStroke', {
				Color = StrokeStyle.Color,
				Transparency = StrokeStyle.Transparency,
			}),
			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Outer']),
			}),
			Layout = new('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder,
			})
		})

		if props.DropShadowEnabled then
			
			-- ////////// Drop Shadow

			return new(DropShadow, {
				AnchorPoint = props.AnchorPoint,
				Position = props.Position,
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Outer']),

				Size = self.Size:map(function(Size)
					return Size + UDim2.fromOffset(0, (self.TitleBarHeight or 0) + props.FooterHeight) + UDim2.new(0, 50, 0, 50)
				end),

				Native = {
					[Roact.Ref] = self.WindowRef,
				},
			}, Window)
		else
			return Window
		end
	end)
end

return Window