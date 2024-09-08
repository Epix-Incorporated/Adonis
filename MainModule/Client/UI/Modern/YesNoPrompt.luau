client, service = nil
local Packages = script.Parent.Components.Packages

local Signal = require(Packages.Signal)
local Winro = require(Packages.Winro)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Dialog = Winro.App.Window.Dialog

export type YesNoPromptProps = {
	Delay: number?,
	Icon: string?,
	Name: string,
	Question: string,
	Size: {number},
	Title: string
}

return function(data: YesNoPromptProps, env): "No" | "Yes"

	local Variables = client.Variables
	local themeData = Variables.LastServerTheme or {Desktop = "Default"; Mobile = "Mobilius"}
	local theme = Variables.CustomTheme or (service.IsMobile() and themeData.Mobile) or themeData.Desktop

	local answerSignal = Signal.new()

	local app = new("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 500,
	}, {
		Dialog = new(Dialog, {
			TitleText = data.Name,
			BodyText = data.Question,
			Size = UDim2.new(0, 400, 0, 100),
			AutomaticSize = Enum.AutomaticSize.Y,

			Buttons = {
				[1] = {
					Text = 'Yes',
					Style = 'Accent',
					[Roact.Event.Activated] = function()
						answerSignal:Fire(true)
					end,
				},
				[2] = {
					Text = 'No',
					Style = 'Standard',
					[Roact.Event.Activated] = function()
						answerSignal:Fire(false)
					end,
				},
			},
			TitleBarProps = {
				Icon = data.Icon and {
					Image = data.Icon;
					ImageRectSize = Vector2.new();
					ImageRectOffset = Vector2.new();
				} or nil,
				Text = data.Name or "Confirmation",
				CanClose = false
			},
			WindowProps = {
				FooterHeight = 80,
			}
		})
	})

	local handle = Roact.mount(new(Winro.Theme.Provider, {
		Theme = theme == "Modern" and Winro.Theme.Themes.DarkTheme or Winro.Theme.Themes.LightTheme,
	}, app), service.UnWrap(service.PlayerGui), "Adonis.YesNoPrompt")

	local answer = answerSignal:Wait()
	Roact.unmount(handle)

	return if answer then "Yes" else "No"
end