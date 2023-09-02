--!strict
local Sift = script.Parent.Parent

local Util = require(Sift.Util)

local function compare(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end

	local aLength = #a

	if #b ~= aLength then
		return false
	end

	for i = 1, aLength do
		if a[i] ~= b[i] then
			return false
		end
	end

	return true
end

--[=[
	@function equals
	@within Array

	@param ... ...{any} -- The arrays to compare.
	@return boolean -- Whether the arrays are equal.

	Compares two arrays for equality.

	```lua
	local array = { 1, 2, 3 }
	local other = { 1, 2, 3 }

	local value = Equals(array, other) -- true
	local value = Equals(array, other, { 1, 2, 3 }) -- true
	local value = Equals(array, other, { 1, 2, 4 }) -- false
	```
]=]
local function equals<T>(...: { T }): boolean
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
