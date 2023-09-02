local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local DropdownRoot = script.Parent
local ComboBox = require(DropdownRoot.ComboBox)

local BORDER_PADDING = UDim.new(0, 8)

local ComboBoxStory = Roact.PureComponent:extend(script.Name)

function ComboBoxStory:render()
	local props = self.props

	return WithTheme(function(Theme)
		return new('Frame', {
			Size = UDim2.fromOffset(120, 32) + UDim2.fromOffset(BORDER_PADDING.Offset * 2, BORDER_PADDING.Offset * 2),
			BackgroundTransparency = props.BackgroundTransparency,
			BackgroundColor3 = Theme['colors/Background/Fill_Color/Solid_Background/Base'].Color,
			AutomaticSize = 'XY'
		}, {
			Padding = new('UIPadding', {
				PaddingBottom = BORDER_PADDING,
				PaddingLeft = BORDER_PADDING,
				PaddingRight = BORDER_PADDING,
				PaddingTop = BORDER_PADDING,
			}),
			ComboBox = new(ComboBox, {
				DropdownButtonProps = {
					Disabled = props.Disabled,
				},
				SelectedOption = self.state.SelectedOption,
				OnOptionSelected = function(Option, ...)
					print(Option, ...)
					self:setState({
						SelectedOption = Option
					})
				end,
				Options = {
					'Option A',
					'Option B',
					'Option C',
					'Option D',
					'Really really long option text',
				}
			})
		})
	end)
end

return {
	controls = {
		Disabled = false,
	},
	stories = {
		DropdownButton = function (props)
			return new(ComboBoxStory, Sift.Dictionary.join({
				BackgroundTransparency = 0,
			}, props.controls))
		end,
		NoBackground = function(props)
			return new(ComboBoxStory, Sift.Dictionary.join({
				BackgroundTransparency = 1,
			}, props.controls))
		end
	}
}