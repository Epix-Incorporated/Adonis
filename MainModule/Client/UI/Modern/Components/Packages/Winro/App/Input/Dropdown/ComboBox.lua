-- ComboBox: A drop down option selector

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ContextMenu = require(Winro.App.Menu.ContextMenu)
local FocusFrame = require(Winro.App.Effect.FocusFrame)

local DropdownRoot = script.Parent
local DropdownButton = require(DropdownRoot.DropdownButton)

local ComboBox = Roact.PureComponent:extend(script.Name)

ComboBox.defaultProps = {
	Size = UDim2.fromOffset(120, 32), --- @defaultProp
}

ComboBox.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 Anchorpoint
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional LayoutOrder number Layout order
	LayoutOrder = t.optional(t.number),

	--- @prop @optional Size UDim2 Size
	Size = t.optional(t.UDim2),

	--- @prop @optional Position UDim2 Position
	Position = t.optional(t.UDim2),

	--- @prop @optional DropdownButtonProps table The props for the dropdown button
	DropdownButtonProps = t.optional(t.table),

	--- @prop Options table The options to display
	Options = t.table,

	--- @prop @optional SelectedOption string The currently selected option
	SelectedOption = t.optional(t.string),

	--- @prop @optional OnOptionSelected function The callback to call when an option is selected
	OnOptionSelected = t.optional(t.callback),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),
})

function ComboBox:render()
	local props = self.props
	local state = self.state

	-- ////////// Context Menu

	local Options = {}

	for Index, Option in pairs(props.Options) do
		Options[Index] = {
			Text = Option,
			Selected = (Option == props.SelectedOption),
			OnClicked = function()

				self:setState({
					ContextMenuVisible = not state.ContextMenuVisible,
				})

				props.OnOptionSelected(Option)
			end
		}
	end

	local ContextMenu = state.ContextMenuVisible and new(FocusFrame, {
		RelativeToParent = true,
		Reason = 'COMBOBOX_DROPDOWN_CONTEXT_MENU',
		[Roact.Event.FocusLost] = function()
			self:setState({
				ContextMenuVisible = not state.ContextMenuVisible,
			})
		end,
	}, {

		ContextMenu = new(ContextMenu, {
			BackgroundTransparency = 0,
			Options = Options,
			Size = UDim2.new(1, 0, 0, props.Size),
		}),
	})

	-- ////////// Dropdown Button

	local Button = new(DropdownButton, Sift.Dictionary.join({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Text = props.SelectedOption or '*',

		[Roact.Event.Activated] = function ()

			if props.DropdownButtonProps and props.DropdownButtonProps.Disabled then
				return
			end

			self:setState({
				ContextMenuVisible = not state.ContextMenuVisible
			})
		end,
	}, props.DropdownButtonProps))

	-- ////////// ComboBox wrapper
	return new('Frame', Sift.Dictionary.join({
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		Size = props.Size,
	}, props.Native), {
		Button = Button,
		ContextMenu = ContextMenu,
	})
end

return ComboBox