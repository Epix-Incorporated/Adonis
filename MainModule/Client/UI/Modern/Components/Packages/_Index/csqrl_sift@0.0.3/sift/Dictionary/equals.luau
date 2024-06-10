--!strict
local Sift = script.Parent.Parent

local Util = require(Sift.Util)
local _T = require(Sift.Types)

local function compare(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end

	for key, value in pairs(a) do
		if b[key] ~= value then
			return false
		end
	end

	for key, value in pairs(b) do
		if a[key] ~= value then
			return false
		end
	end

	return true
end

--[=[
  @function equals
  @within Dictionary

  @param ... ...{ [any]: any } -- The dictionaries to compare.
  @return boolean -- Whether the dictionaries are equal.

  Compares two dictionaries for equality.

  ```lua
  local dictionary = { hello = "world", goodbye = "world" }
  local other1 = { hello = "world", goodbye = "world" }
  local other2 = { hello = "hello", world = "goodbye" }

  local value = Equals(dictionary, other1) -- true
  local value = Equals(dictionary, other1, other2) -- false
  ```
]=]
local function equals(...: _T.AnyDictionary): boolean
	if Util.equalObjects(...) then
		return true
	end

	local totalArgs = select("#", ...)
	local firstItem = select(1, ...)

	for i = 2, totalArgs do
		local item = select(i, ...)

		if not compare(firstItem, item) then
			return false
		end
	end

	return true
end

return equals
