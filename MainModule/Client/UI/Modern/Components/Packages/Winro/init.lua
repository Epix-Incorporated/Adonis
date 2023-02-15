local App = script.App

local Winro = {
	Theme = require(script.Theme),
	
	Utility = {
		GetTextSize = require(script.Utility.GetTextSize),
	},

	App = {

		Effect = {
			DropShadow = require(App.Effect.DropShadow),
		},
		Flyout = {
			Flyout = require(App.Flyout.Flyout),
		},
		Info = {
			Tooltip = require(App.Info.Tooltip),
		},
		Input = {
			Button = {
				Button = require(App.Input.Button.Button),
				ButtonStack = require(App.Input.Button.ButtonStack),
			},
			Checkbox = {
				Checkbox = require(App.Input.Checkbox.Checkbox),
				CheckboxGroup = require(App.Input.Checkbox.CheckboxGroup),
			},
			Dropdown = {
				ComboBox = require(App.Input.Dropdown.ComboBox),
			},
			Hyperlink = {
				HyperlinkButton = require(App.Input.Hyperlink.HyperlinkButton),
			},
		},
		List = {
			Divider = require(App.List.ListDivider),
			ListItem = require(App.List.ListItem),
		},
		Menu = {
			ContextMenu = require(App.Menu.ContextMenu),
		},
		Surface = {
			Acrylic = require(App.Surface.Acrylic),
			RoundedSurface = require(App.Surface.RoundedSurface),
		},
		Window = {
			Dialog = require(App.Window.Dialog),
			Window = require(App.Window.Window),
		}
	}
}

return Winro