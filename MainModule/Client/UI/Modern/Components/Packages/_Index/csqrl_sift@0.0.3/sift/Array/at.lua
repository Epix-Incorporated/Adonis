--!strict
--[=[
	@function at
	@within Array

	@param array {T} -- The array to get the value from.
	@param index number -- The index to get the value from (can be negative).
	@return T -- The value at the given index.

	Gets a value from an array at the given index.

	```lua
	local array = { 1, 2, 3 }

	local value = At(array, 1) -- 1
	local value = At(array, 0) -- 3
	```
]=]
local function at<T>(array: { T }, index: number): T
	local length = #array

	if index < 1 then
		index += length
	end

	return array[index]
end

return at
