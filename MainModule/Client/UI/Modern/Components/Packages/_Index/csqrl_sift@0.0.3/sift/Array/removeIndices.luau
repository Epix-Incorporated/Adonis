--!strict
--[=[
	@function removeIndices
	@within Array

	@param array {T} -- The array to remove the indices from.
	@param ... ...number -- The indices to remove the values from (can be negative).
	@return {T} -- The array with the values removed.

	Removes values from an array at the given indices.

	```lua
	local array = { 1, 2, 3 }

	local new = RemoveIndices(array, 1, 2) -- { 3 }
	local new = RemoveIndices(array, 0, -1) -- { 1 }
	```
]=]
local function removeIndices<T>(array: { T }, ...: number): { T }
	local length = #array
	local indices = {}
	local result = {}

	for _, index in ipairs({ ... }) do
		if index < 1 then
			index += length
		end

		indices[index] = true
	end

	for index, value in ipairs(array) do
		if not indices[index] then
			table.insert(result, value)
		end
	end

	return result
end

return removeIndices
