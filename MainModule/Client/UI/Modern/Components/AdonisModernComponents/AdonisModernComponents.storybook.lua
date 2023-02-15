local AdonisModernComponents = script.Parent
local Packages = AdonisModernComponents.Parent.Packages

local Roact = require(Packages.Roact)

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
	name = 'Adonis Modern Theme',
	roact = Roact,
	storyRoots = {
		script.Parent
	},
	mapDefinition = function (Story)

		-- Parse the document
		local Parsed = ParseDocument(Story.source.Parent:FindFirstChild((Story.source.Name::string):gsub('.story', '')).Source)

		Story.summary = Parsed.Summary
		Story.docs = Parsed.Docs

		return Story
	end
}