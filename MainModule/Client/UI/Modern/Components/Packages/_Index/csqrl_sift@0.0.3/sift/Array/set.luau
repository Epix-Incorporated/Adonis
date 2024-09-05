--!strict
--[=[
	@function set
	@within Array

	@param array {T} -- The array to set the value on.
	@param index number -- The index to set the value at (can be negative).
	@param value T -- The value to set.
	@return {T} -- The array with the value set.

	Sets a value on an array at the given index.

	```lua
	local array = { 1, 2, 3 }

	local new = Set(array, 2, 4) -- { 1, 4, 3 }
	local new = Set(array, -1, 4) -- { 1, 2, 4 }
	```
]=]
local function set<T>(array: { T }, index: number, value: T?): { T }
	local length = #array
	local result = {}

	if index < 1 then
		index += length
	end

	for arrIndex, arrValue in ipairs(array) do
		if arrIndex == index then
			table.insert(result, value)
		else
			table.insert(result, arrValue)
		end
	end

	return result
end

return set
