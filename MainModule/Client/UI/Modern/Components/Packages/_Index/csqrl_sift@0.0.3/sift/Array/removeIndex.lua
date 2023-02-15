--!strict
--[=[
	@function removeIndex
	@within Array

	@param array {T} -- The array to remove the value from.
	@param index number -- The index to remove the value from (can be negative).
	@return {T} -- The array with the value removed.

	Removes a value from an array at the given index.

	```lua
	local array = { 1, 2, 3 }

	local new = RemoveIndex(array, 1) -- { 2, 3 }
	local new = RemoveIndex(array, -1) -- { 1, 3 }
	```
]=]
local function removeIndex<T>(array: { T }, index: number): { T }
	local length = #array
	local result = {}

	if index < 1 then
		index += length
	end

	for arrIndex, value in ipairs(array) do
		if arrIndex ~= index then
			table.insert(result, value)
		end
	end

	return result
end

return removeIndex
