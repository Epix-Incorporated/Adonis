-- Theme: The theming utility used all throught Winro

local Winro = script.Parent
local Packages = Winro.Parent

local Roact = require(Packages.Roact)
local Sift = require(Packages.Sift)
local strict = require(Winro.strict)

-- Theme
local Theme = {
	Provider = require(script.StyleProvider),
	Consumer = require(script.StyleConsumer),
	ApplyDescription = require(script.ApplyDescription),
	RegisterStateAction = require(script.RegisterStateAction),
}

-- Theme Containers
Theme.ColorThemes = {
	DarkTheme = require(script.Themes["Color.DarkTheme"]),
	LightTheme = require(script.Themes["Color.LightTheme"]),
}
Theme.FontThemes = {
	SourceSans = require(script.Themes["Font.SourceSansTheme"]),
	Gotham = require(script.Themes["Font.GothamTheme"]),
}
Theme.StyleThemes = {
	Default = require(script.Themes["Style.Default"]),
}
Theme.ImageThemes = {
	Default = require(script.Themes["Image.Default"]),
	RobloxImages = require(script.Themes["Image.RobloxImages.lua"])
}

-- Register Themes
for _, CustomTheme in pairs(script.Themes:GetChildren()) do

	-- Extract Theme info
	local Type, Name = unpack(CustomTheme.Name:split('.'))

	-- Validate
	if (not (Type and Name)) or (Type ~= 'Color' and Type ~= 'Font' and Type ~= 'Style') then
		continue
	end

	-- Register
	xpcall(function()
		Theme[Type .. 'Themes'][Name] = require(CustomTheme)
	end, function(Error)
		warn('Failed to register theme. Theme:', CustomTheme, 'Error:', Error)
	end)
end

-- Custom fallback handlers
local Fallbacks = {
	colors = function(index)

		-- If the index is a color, use it
		if typeof(index) == 'Color3' then
			return {
				Color = index,
				Transparency = 0
			}
		end

		-- Warn of missing color style
		warn('A missing color style was found for', index, 'in Winro theme files')

		local Color = nil
		local RandomNumber = math.random(0, 2)

		if RandomNumber == 0 then
			Color = Color3.new(0, 1, 1)
		elseif RandomNumber == 1 then
			Color = Color3.new(1, 0, 1)
		elseif RandomNumber == 2 then
			Color = Color3.new(1, 1, 0)
		end

		return {
			Color = Color,
			Transparency = 0.25,
		}
	end,
	images = function(index)
		
		-- If the index is an image, use it
		if tostring(index):find('rbxassetid://') then
			return {
				Image = index,
				ImageRectOffset = Vector2.new(),
				ImageRectSize = Vector2.new()
			}
		end

		-- Warn of missing image
		warn('A missing image style was found for', index, 'in Winro image files')

		return {
			Image = 'rbxassetid://925810526',--'rbxasset://textures/ui/GuiImagePlaceholder.png',
			ImageTransparency = 0.75,
			ImageRectOffset = Vector2.new(),
			ImageRectSize = Vector2.new(),
			ScaleType = Enum.ScaleType.Tile,
			ResampleMode = Enum.ResamplerMode.Pixelated,
			TileSize = UDim2.fromOffset(25, 25)
		}
	end,
	styles = function(index)
		error(('could not find a style with the path of `%s`'):format(index))
	end,
	fonts = function(index)
		-- If the index is a FontEnum, use it
		if typeof(index) == 'EnumItem' then
			return {
				Font = Font.fromEnum(index),
				Size = 20,
				LineHeight = 20,
				ParagraphSpacing = 0.0,
			}
		end

		-- Warn of missing font style
		warn('A missing font style was found for', index, 'in Winro theme files')

		return {
			Font = Font.fromEnum(Enum.Font.RobotoMono),
			Size = 14,
			LineHeight = 0.74,
			ParagraphSpacing = 0.0,
		}
	end
}

-- Creates a new theme by combining all the provided theme components
function Theme.new(Themes)

	-- Merge the themes
	local Theme = Sift.Dictionary.join({}, unpack(Themes))

	-- Attach metatable
	return setmetatable({}, {
		__newindex = function()
			error('Theme is read only.')
		end,
		__index = function(_, index)

			-- Fetch an existing value
			local Existing = rawget(Theme, index)
			if Existing ~= nil then--and (typeof(Existing) ~= 'table' or math.random(0, 6) ~= 0) then
				return Existing
			end

			-- Extract the path's root
			local PathRoot = tostring(index):split('/')[1]

			-- Get the last-resort fallback
			local Fallback = Fallbacks[PathRoot]
			if Fallback then
				return Fallback(index)
			elseif index ~= nil then
				return index
			else
				warn(('`%s` is not a valid member of Theme.'):format(tostring(index)))

				-- Return something that should throw an error at the source of the index as it cannot be used as a theme
				return function ()
					error(('`%s` is not a valid member of Theme.'):format(tostring(index)))
				end
			end
		end
	})
end

-- Prebuilt themes
Theme.Themes = {
	DarkTheme = Theme.new({
		Theme.ImageThemes.Default,
		Theme.ImageThemes.RobloxImages,
		Theme.StyleThemes.Default,
		Theme.FontThemes.SourceSans,
		Theme.ColorThemes.DarkTheme,
	}),
	LightTheme = Theme.new({
		Theme.ImageThemes.Default,
		Theme.ImageThemes.RobloxImages,
		Theme.StyleThemes.Default,
		Theme.FontThemes.SourceSans,
		Theme.ColorThemes.LightTheme,
	}),
}

-- Theme Provider
function Theme.WithTheme(RenderFunction)

	return Roact.createElement(Theme.Consumer, {
		render = function(ThemeContainer)
			
			-- Fallback
			if not ThemeContainer then
				return RenderFunction(Theme.Themes.LightTheme)
			end

			return RenderFunction(ThemeContainer.Theme)
		end
	})
end

return strict(Theme, 'Winro.Theme')