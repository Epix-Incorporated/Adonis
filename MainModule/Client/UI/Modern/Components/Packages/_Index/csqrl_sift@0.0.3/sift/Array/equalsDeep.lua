--!strict
local Sift = script.Parent.Parent

local Util = require(Sift.Util)

local function compareDeep(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end

	local aLength = #a

	if #b ~= aLength then
		return false
	end

	for i = 1, aLength do
		if not compareDeep(a[i], b[i]) then
			return false
		end
	end

	return true
end

--[=[
	@function equalsDeep
	@within Array

	@param ... ...{any} -- The arrays to compare.
	@return boolean -- Whether the arrays are equal.

	Compares two arrays for equality using deep comparison.

	```lua
	local array = { 1, 2, 3, { 4, 5 } }
	local other = { 1, 2, 3, { 4, 5 } }

	local value = EqualsDeep(array, other) -- true
	local value = EqualsDeep(array, other, { 1, 2, 3, { 4, 5 } }) -- true
	local value = EqualsDeep(array, other, { 1, 2, 3, { 4, 6 } }) -- false
	```
]=]
local function equalsDeep<T>(...: { T }): boolean
	if Util.equalObjects(...) then
		return true
	end

	local totalArgs = select("#", ...)
	local firstItem = select(1, ...)

	for i = 2, totalArgs do
		local item = select(i, ...)

		if not compareDeep(firstItem, item) then
			return false
		end
	end

	return true
end

return equalsDeep
