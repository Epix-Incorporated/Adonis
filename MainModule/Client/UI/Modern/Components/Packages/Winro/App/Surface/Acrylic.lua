-- Acrylic: The acrylic surface

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local WithTheme = require(Winro.Theme).WithTheme

local ACRYLIC_TEXTURE_STYLE = 'images/Texture/Effect/Acrylic'

local Acrylic = Roact.PureComponent:extend(script.Name)

function Acrylic:render()
	
	-- Use the acrylic styling
	return WithTheme(function(Theme)
		
		-- Get the acrylic texture
		local Texture = Theme[ACRYLIC_TEXTURE_STYLE]

		return new('ImageLabel', Sift.Dictionary.join({
			BackgroundTransparency = 0.5,
			Image = Texture.Image,
			ImageRectOffset = Texture.ImageRectOffset,
			ImageRectSize = Texture.ImageRectSize,
			ImageTransparency = Texture.ImageTransparency,
			ScaleType = Texture.ScaleType,
			TileSize = Texture.TileSize
		}, self.props))
	end)
end

return Acrylic