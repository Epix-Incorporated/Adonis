--!strict
--[=[
	@function insert
	@within Array

	@param array {T} -- The array to insert the value into.
	@param index number -- The index to insert the value at (can be negative).
	@param values ...T -- The values to insert.
	@return {T} -- The array with the value inserted.

	Inserts the given values into an array at the given index, shifting all values after it to the right. If the index is negative (or 0), it is counted from the end of the array.

	If the index to insert at is out of range, the array is not modified.

	```lua
	local array = { 1, 2, 3 }

	local newArray = Insert(array, 2, 4) -- { 1, 4, 2, 3 }
	```
]=]
local function insert<T>(array: { T }, index: number, ...: T): { T }
	local length = #array

	if index < 1 then
		index += length + 1
	end

	if index > length then
		if index > length + 1 then
			return array
		end

		index = length + 1
		length += 1
	end

	local result = {}

	for i = 1, length do
		if i == index then
			for _, value in ipairs({ ... }) do
				table.insert(result, value)
			end
		end

		table.insert(result, array[i])
	end

	return result
end

return insert
