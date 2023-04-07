-- Flyout: Flyout component

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Acrylic = require(Winro.App.Surface.Acrylic)

local FLYOUT_BASE_FILL = "colors/Background/Fill_Color/Acrylic_Background/Base"
local FLYOUT_BASE_STROKE = "colors/Stroke_Color/Surface_Stroke/Flyout"
local FLYOUT_TEXT_STYLE = "colors/Fill_Color/Text/Primary"
local FLYOUT_FONT_STYLE = "fonts/Body"

local Flyout = Roact.PureComponent:extend(script.Name)

Flyout.defaultProps = {
	Size = UDim2.fromOffset(320, 72), --- @defaultProp
	FitContents = true, --- @defaultProp
}

Flyout.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The Flyout's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional Position UDim2 The Flyout's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 The Flyout's size
	Size = t.optional(t.UDim2),

	--- @prop @optional RichText boolean The Flyout's rich text property
	RichText = t.optional(t.boolean),

	--- @prop @optional Text string The Flyout's text
	Text = t.optional(t.string),

	--- @prop @optional FitContents boolean Determines if the Flyout will resize to fit it's contents
	FitContents = t.optional(t.boolean),

	--- @prop @optional Native table {property:value} The native props for the Flyout's main element
	Native = t.optional(t.table),

	--- @prop @optional [Roact.Children] table The flyout's contents
	[Roact.Children] = t.optional(t.table),
})

function Flyout:init()

	-- Content fitting
	self.ContentSize, self.SetContentSize = Roact.createBinding(self.props.Size)
end

function Flyout:render()
	local props = self.props

	return WithTheme(function(Theme)

		-- ////////// Flyout Surface

		local SurfaceStyle = Theme[FLYOUT_BASE_FILL]
		local StrokeStyle = Theme[FLYOUT_BASE_STROKE]

		local Base = new(Acrylic, {
			BackgroundColor3 = SurfaceStyle.Color,
			BackgroundTransparency = SurfaceStyle.Transparency,
			BorderSizePixel = 0,
			Size = self.ContentSize,
		}, {

			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Outer'] - 1), -- -1px to account for stroke
			}),
			Stroke = new('UIStroke', {
				Color = StrokeStyle.Color,
				Transparency = StrokeStyle.Transparency,
				Thickness = 1,
			}),
		})

		-- ////////// Flyout Content

		local TextStyle = Theme[FLYOUT_TEXT_STYLE]
		local TextFont = Theme[FLYOUT_FONT_STYLE]

		local Container = new('Frame', {
			AutomaticSize = props.FitContents and 'Y' or 'None',
			BackgroundTransparency = 1,
			Size = self.ContentSize,
		}, {

			Layout = new('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder
			}),
			Content = new('Frame', {
				AutomaticSize = props.FitContents and 'Y' or 'None',
				BackgroundTransparency = 1,
				Size = self.ContentSize,

				[Roact.Change.AbsoluteSize] = function(rbx)
					if props.FitContents then
						self.SetContentSize(UDim2.fromOffset(rbx.AbsoluteSize.X, rbx.AbsoluteSize.Y))
					end
				end,
			}, {
				Contents = Roact.createFragment(props[Roact.Children] or {}),
				
				_Padding = new('UIPadding', {
					PaddingBottom = UDim.new(0, 16),
					PaddingLeft = UDim.new(0, 16),
					PaddingRight = UDim.new(0, 16),
					PaddingTop = UDim.new(0, 16),
				}),
				_Layout = new('UIListLayout', {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 16),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				_Text = props.Text and new('TextLabel', {
					LayoutOrder = -1,
					BackgroundTransparency = 1,
					AutomaticSize = props.FitContents and 'Y' or 'None',
					FontFace = TextFont.Font,
					Size = UDim2.fromScale(1, props.FitContents and 0 or 1),
					LineHeight = TextFont.LineHeight,
					RichText = props.RichText,
					Text = props.Text,
					TextColor3 = TextStyle.Color,
					TextSize = TextFont.Size,
					TextTransparency = TextStyle.Transparency,
					TextWrapped = true,
					TextXAlignment = 'Left',
					TextYAlignment = 'Top',
				}),
			})
		})

		-- ////////// Flyout

		return new('Frame', Sift.Dictionary.join({
			AnchorPoint = props.AnchorPoint,
			AutomaticSize = props.FitContents and 'Y' or 'None',
			BackgroundTransparency = 1,
			Position = props.Position,
			Size = self.ContentSize,

			[Roact.Change.AbsoluteSize] = function(rbx)
				self.SetContentSize(UDim2.fromOffset(rbx.AbsoluteSize.X, rbx.AbsoluteSize.Y))
			end,
		}, props.Native), {
			Base = Base,
			Container = Container,
		})
	end)
end

return Flyout