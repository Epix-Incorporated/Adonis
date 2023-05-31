--!strict
local Sift = script.Parent.Parent

local None = require(Sift.None)

--[=[
  @function merge
  @within Dictionary

  @param dictionaries? ...any -- The dictionaries to merge.
  @return T -- The merged dictionary.

  Merges the given dictionaries into a single dictionary. If the
  value is `None`, it will be removed from the result. The
  parameters may be any number of dictionaries or `nil`.
  Non-dictonaries will be ignored.

  Aliases: `join`

  ```lua
  local dictionary1 = { hello = "roblox", goodbye = "world" }
  local dictionary2 = { goodbye = "goodbye" }

  local merged = Merge(dictionary1, dictionary2) -- { hello = "roblox", goodbye = "goodbye" }
  ```
]=]
local function merge<T>(...: any): T
	local result = {}

	for dictionaryIndex = 1, select("#", ...) do
		local dictionary = select(dictionaryIndex, ...)

		if type(dictionary) ~= "table" then
			continue
		end

		for key, value in pairs(dictionary) do
			result[key] = if value == None then nil else value
		end
	end

	return result
end

return merge
