--!strict
local Sift = script.Parent.Parent

local None = require(Sift.None)
local copyDeep = require(script.Parent.copyDeep)

--[=[
	@function mergeDeep
	@within Dictionary

	@param dictionaries? ...any -- The dictionaries to merge.
	@return T -- The merged dictionary.

	Merges the given dictionaries into a single dictionary. If the
	value is `None`, it will be removed from the result. This is
	recursive. The parameters may be any number of dictionaries or
	`nil`. Non-dictonaries will be ignored.

	Aliases: `joinDeep`

	```lua
	local dictionary1 = { hello = "roblox", goodbye = { world = "goodbye" } }
	local dictionary2 = { goodbye = { world = "world" } }

	local merged = MergeDeep(dictionary1, dictionary2) -- { hello = "roblox", goodbye = { world = "world" } }
	```
]=]
local function mergeDeep<T>(...: any): T
	local result = {}

	for dictionaryIndex = 1, select("#", ...) do
		local dictionary = select(dictionaryIndex, ...)

		if type(dictionary) ~= "table" then
			continue
		end

		for key, value in pairs(dictionary) do
			if value == None then
				result[key] = nil
			elseif type(value) == "table" then
				if result[key] == nil or type(result[key]) ~= "table" then
					result[key] = copyDeep(value)
				else
					result[key] = mergeDeep(result[key], value)
				end
			else
				result[key] = value
			end
		end
	end

	return result
end

return mergeDeep
