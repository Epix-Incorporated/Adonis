local StarterGui = game:GetService("StarterGui")
local Theme = script.Parent
local Winro = Theme.Parent
local Packages = Winro.Parent

local Roact = require(Packages.Roact)
local StyleContext = require(Theme.StyleContext)

local StyleProvider = Roact.Component:extend("StyleProvider")

-- // UIBlox theme provider //

function StyleProvider:init()
	-- This is typically considered an anti-pattern, but it's the simplest
	-- way to preserve the behavior that these context solutions employed

	self.UpdateConnection = StarterGui:GetAttributeChangedSignal('Theme'):Connect(function()

		-- If provided as a prop, ignore override
		if self.props.Theme then
			return
		end

		self.ThemeObject:Update(require(Theme).Themes[StarterGui:GetAttribute('Theme')])
	end)

	self:setState({
		Theme = self.props.Theme or require(Theme).Themes[StarterGui:GetAttribute('Theme')],
	})
end

function StyleProvider:render()

	local ThemeObject = {
		Theme = self.state.Theme,
		Update = function(_self, NewTheme)
			if self.mounted then
				_self.Theme = NewTheme
				self:setState({ Theme = NewTheme })
			end
		end,
	}

	self.ThemeObject = ThemeObject

	return Roact.createElement(StyleContext.Provider, {
		value = ThemeObject,
	}, Roact.createFragment(self.props[Roact.Children]))
end

function StyleProvider:didMount()
	self.mounted = true
end

function StyleProvider:willUnmount()
	self.UpdateConnection:Disconnect()
	self.mounted = false
end

return StyleProvider
