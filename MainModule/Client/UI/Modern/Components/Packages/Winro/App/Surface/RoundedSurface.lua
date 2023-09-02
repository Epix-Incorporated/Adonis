-- RoundedSurface: A rounded surface with individual corner visibility support

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

local DEFAULT_CORNER_RADIUS = UDim.new(0, 5)

local RoundedSurface = Roact.PureComponent:extend(script.Name)

RoundedSurface.Corners = {
	TopLeft = 'TopLeft',
	TopRight = 'TopRight',
	BottomLeft = 'BottomLeft',
	BottomRight = 'BottomRight',
}

RoundedSurface.defaultProps = {
	Size = UDim2.fromScale(1, 1), --- @defaultProp
	BackgroundTransparency = 0, --- @defaultProp
	CornerRadius = DEFAULT_CORNER_RADIUS, --- @defaultProp
	ShowTopLeftCorner = false, --- @defaultProp
	ShowTopRightCorner = false, --- @defaultProp
	ShowBottomLeftCorner = false, --- @defaultProp
	ShowBottomRightCorner = false, --- @defaultProp
}

RoundedSurface.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The Frame's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional AutomaticSize Enum.AutomaticSize The Frame's autmatic size
	AutomaticSize = t.optional(t.enum(Enum.AutomaticSize)),

	--- @prop @optional @style BackgroundColor string|table Style
	BackgroundColor = t.optional(StyleValidator),

	--- @prop @optional BackgroundColor3 Color3 Background Color
	BackgroundColor3 = t.optional(t.Color3),

	--- @prop @optional BackgroundTransparency number positive Background Transparency
	BackgroundTransparency = t.optional(t.number),

	--- @prop @optional BorderSizePixel number Border thickness, in pixels
	BorderSizePixel = t.optional(t.number),

	--- @prop @optional LayoutOrder number The Surface's layout order
	LayoutOrder = t.optional(t.number),

	--- @prop @optional ShowTopLeftCorner boolean Determines the visibility status of the TopLeft Corner
	ShowTopLeftCorner = t.optional(t.boolean),
	
	--- @prop @optional ShowTopRightCorner boolean Determines the visibility status of the TopRight Corner
	ShowTopRightCorner = t.optional(t.boolean),
	
	--- @prop @optional ShowBottomLeftCorner boolean Determines the visibility status of the BottomLeft Corner
	ShowBottomLeftCorner = t.optional(t.boolean),
	
	--- @prop @optional ShowBottomRightCorner boolean Determines the visibility status of the BottomRight Corner
	ShowBottomRightCorner = t.optional(t.boolean),

	--- @prop @optional CornerRadius UDim The corner radius
	CornerRadius = t.optional(t.UDim),

	--- @prop @optional Position UDim2 The Frame's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 The Frame's size
	Size = t.optional(t.UDim2),

	--- @prop @optional Native table {property:value} The native props for the Frame's main element
	Native = t.optional(t.table),

	--- @prop @optional [Roact.Change.AbsoluteSize] function Roact.Change.AbsoluteSize
	[Roact.Change.AbsoluteSize] = t.optional(t.callback),

	--- @prop @optional [Roact.Children] table The Frame's contents
	[Roact.Children] = t.optional(t.table),
})

function RoundedSurface:CreateCornerFilling(Corner, Theme)
	local props = self.props
	local state = self.state
	
	local Radius = self.props.CornerRadius
	local AnchorPoint, Position = nil, nil

	-- Calculate the size
	local Size = UDim2.new(Radius.Scale, Radius.Offset, Radius.Scale, Radius.Offset)

	if Corner == self.Corners.TopLeft then
		AnchorPoint = Vector2.new(0, 0)
		Position = UDim2.fromScale(0, 0)

	elseif Corner == self.Corners.TopRight then
		AnchorPoint = Vector2.new(1, 0)
		Position = UDim2.fromScale(1, 0)

	elseif Corner == self.Corners.BottomLeft then
		AnchorPoint = Vector2.new(0, 1)
		Position = UDim2.fromScale(0, 1)

	elseif Corner == self.Corners.BottomRight then
		AnchorPoint = Vector2.new(1, 1)
		Position = UDim2.fromScale(1, 1)

	end

	local FillStyle = Theme[props.BackgroundColor or {
		Color = props.BackgroundColor3,
		Transparency = props.BackgroundTransparency,
	}]

	return new('Frame', {
		AnchorPoint = AnchorPoint,
		BackgroundColor3 = (not state.FallbackMode) and Color3.new(1, 1, 1) or FillStyle.Color,
		BackgroundTransparency = state.FallbackMode and FillStyle.Transparency or nil,
		BorderSizePixel = 0,
		Position = Position,
		Size = Size,
	})
end

function RoundedSurface:init()
	local props = self.props

	-- Content size binding
	self.Size, self.SetSize = Roact.createBinding(UDim2.fromScale(0, 0))

	-- Update size and call prop
	self[Roact.Change.AbsoluteSize] = function(rbx, ...)
		
		local AbsoluteSize = rbx.AbsoluteSize

		self.SetSize(UDim2.fromOffset(AbsoluteSize.X, AbsoluteSize.Y))

		local PropCallback = props[Roact.Change.AbsoluteSize]

		if PropCallback then
			task.spawn(PropCallback, rbx, ...)
		end
	end
end

function RoundedSurface:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)

		-- ////////// Corner Fillings

		-- Gather corner fillings
		local CornerFillings = {}

		for _, Corner in pairs(self.Corners) do
			local CornerVisibility = props['Show' .. Corner .. 'Corner']

			if not CornerVisibility then
				CornerFillings[Corner .. 'CornerFilling'] = self:CreateCornerFilling(Corner, Theme)
			end
		end

		-- ////////// Rounded frame

		local FillStyle = Theme[props.BackgroundColor or {
			Color = props.BackgroundColor3,
			Transparency = props.BackgroundTransparency,
		}]

		local RoundedFrame = new('Frame', {
			Size = self.Size,
			BackgroundColor3 = state.FallbackMode and FillStyle.Color or Color3.new(1, 1, 1),
			BorderSizePixel = props.BorderSizePixel,
			BackgroundTransparency = state.FallbackMode and FillStyle.Transparency or 0,
		}, {
			CornerFillings = Roact.createFragment(CornerFillings),

			Corners = new('UICorner', {
				CornerRadius = props.CornerRadius,
			}),
		})

		-- ////////// Rounded Filling

		local RoundedFilling = new((not state.FallbackMode) and 'CanvasGroup' or 'Frame', {
			GroupColor3 = (not state.FallbackMode) and FillStyle.Color or nil,
			GroupTransparency = (not state.FallbackMode) and FillStyle.Transparency or nil,
			BackgroundTransparency = 1,
			Size = self.Size,
			ZIndex = 1,

			-- Determine fallback mode, as CanvasGroup instances only work under a ScreenGui with ZIndexBehavior set to Sibling
			[Roact.Ref] = function (rbx: CanvasGroup | Frame)

				if self.DeterminedFallback then
					return
				end

				if rbx then

					task.spawn(function()

						task.wait(0.1)

						local Gui = rbx:FindFirstAncestorWhichIsA('LayerCollector') or rbx:FindFirstAncestorWhichIsA('PluginGui')

						self.DeterminedFallback = true

						if not Gui then
							self:setState({
								FallbackMode = true
							})

							warn(
								'[Winro Component Library]: The Component Winro.App.Surface.RoundedSurface must be the descendant of a ScreenGui in order to function correctly.'
								.. '\nDue to not being a descendant of a ScreenGui, rounded corners are being rendered in Fallback mode and may not display correctly.'
							)

							return
						end
						
						if Gui.ZIndexBehavior ~= Enum.ZIndexBehavior.Sibling then

							-- -- Automatically resolve on storybook
							-- if Gui.Name:lower():find('storybook') then
							-- 	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

							-- 	self:setState({
							-- 		FallbackMode = Roact.None,
							-- 	})

							-- 	return
							-- end

							self:setState({
								FallbackMode = true,
							})

							warn(
								'[Winro Component Library]: The Component Winro.App.Surface.RoundedSurface must be the descendant of a ScreenGui with ZIndexBehavior set to Enum.ZIndexBehavior.Sibling in order to function correctly.'
								.. '\nDue to ZIndexBehavior not being set to Enum.ZIndexBahavior.Sibling, rounded corners are being rendered in Fallback mode and may not display correctly.'
								.. '\nPlease set the ScreenGui\'s ZIndexBehaviour property to Enum.ZIndexBehavior.Sibling in order to resolve this issue.'
							)

							return
						end

						-- Disable fallback mode
						self:setState({
							FallbackMode = Roact.None,
						})
					end)
				end
			end
		}, {
			RoundedFrame = RoundedFrame
		})

		-- ////////// Content Wrapper

		local ContentWrapper = new('Frame', {
			AutomaticSize = props.AutomaticSize,
			BackgroundTransparency = 1,
			Size = props.Size,
			ZIndex = 2,
			
			[Roact.Change.AbsoluteSize] = self[Roact.Change.AbsoluteSize],
		}, props[Roact.Children])

		-- ////////// Rounded Surface
		return new('Frame', Sift.Dictionary.join({
			AutomaticSize = props.AutomaticSize,
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Size = props.Size,
			Position = props.Position,
			AnchorPoint = props.AnchorPoint,
		}, props.Native), {
			ContentWrapper = ContentWrapper,
			RoundedFilling = RoundedFilling,
		})
	end)
end

return RoundedSurface