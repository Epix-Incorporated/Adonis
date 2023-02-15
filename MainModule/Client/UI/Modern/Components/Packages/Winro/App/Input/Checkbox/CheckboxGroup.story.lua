local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent
local Roact = require(Packages.Roact)
local new = Roact.createElement

local CheckboxRoot = script.Parent
local CheckboxGroup = require(CheckboxRoot.CheckboxGroup)
local CheckboxStoryElement = require(CheckboxRoot["Checkbox.story"]).storyElement

local CheckboxGroupStory = Roact.PureComponent:extend(script.Name)

function CheckboxGroupStory:GetCheckboxes()

	local Checkboxes = {}

	for Index = 1, self.props.Amount do
		Checkboxes[Index] = {
			Label = tostring(Index),
		}
	end

	return Checkboxes
end

function CheckboxGroupStory:render()
	return new(CheckboxGroup, {
		HeaderText = self.props.HeaderText,
		Checkboxes = self:GetCheckboxes()
	})
end

return {
	controls = {
		HeaderText = 'Header text',
		Amount = 10,
		Disabled = false,
	},
	stories = {
		CheckboxGroup = function (props)
			return new(CheckboxGroupStory, props.controls)
		end
	}
}