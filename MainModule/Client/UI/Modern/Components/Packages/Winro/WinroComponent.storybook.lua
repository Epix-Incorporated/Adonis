local Winro = script.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local ThemeProvider = Theme.Provider

local Roact = require(Packages.Roact)
local new = Roact.createElement

local function SortProps(Props)
	table.sort(Props, function(A, B)
		return A.Name < B.Name
	end)
end

local function ParseDocument(Document: string)
	
	local Summary = ''
	local RequiredProps = {}
	local OptionalProps = {}
	local Styles = {}

	Summary = Document:split('\n')[1]

	for _, Line in pairs(Document:split('\n')) do
		if Line:find('@prop') then
			Line = Line:gsub('@prop', '')

			-- Optional
			local Target = RequiredProps
			if Line:find('@optional') then
				Line = Line:gsub('@optional', '')
				Target = OptionalProps
			end

			-- Style
			if Line:find('@style') then
				Line = Line:gsub('@style', '')
				Target = Styles
			end

			-- Parse
			local Name, Type, Comment = Line:match('([%w%p]+)%s([%w%p]+)%s(.+)')

			if not (Name and Type and Comment) then
				warn('Invalid prop tag:' .. Line)
				continue
			end
			
			table.insert(Target, {
				Name = Name,
				Type = Type, 
				Comment = Comment
			})
		end
	end

	-- Sort the props
	SortProps(RequiredProps)
	SortProps(OptionalProps)

	return {
		Summary = Summary,
		Docs = {
			Required = RequiredProps,
			Optional = OptionalProps,
			Style = Styles
		}
	}
end

return {
	name = 'Winro'..utf8.char(0xE000),
	roact = require(script.Parent.Parent.Roact),
	storyRoots = {script.Parent.App},
	mapDefinition = function (Story)
		local Parsed = ParseDocument(Story.source.Parent:FindFirstChild((Story.source.Name::string):gsub('.story', '')).Source)

		Story.summary = Parsed.Summary
		Story.docs = Parsed.Docs

		local Stories = {}

		if typeof(Story.stories) == 'function' then
			Stories = {
				name = "story",
				summary = "",
				story = function(props)
					return new(ThemeProvider, {
						Theme = Theme.Themes[props.theme .. 'Theme'],
					}, Stories.story(props))
				end
			}
		else
			
			for Key, StoryFunction in pairs(Story.stories) do
				Stories[Key] = {
					name = Key,
					summary = "",
					story = function(props)
						return new(ThemeProvider, {
							Theme = Theme.Themes[props.theme .. 'Theme'],
						}, StoryFunction.story(props))
					end
				}
			end
		end

		Story.stories = Stories

		return Story
	end
}