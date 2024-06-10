local Theme = script.Parent
local Winro = Theme.Parent
local Packages = Winro.Parent

local Roact = require(Packages.Roact)
local StyleConsumer = require(Theme.StyleConsumer)

-- Since our style consumer object receives the whole update-able container,
-- we need to send only the contained style value through to the
-- renderCallback provided
return function(renderCallback)
	assert(type(renderCallback) == "function", "Expect renderCallback to be a function.")
	return Roact.createElement(StyleConsumer, {
		render = function(styleContainer)
			return renderCallback(styleContainer.style)
		end,
	})
end
