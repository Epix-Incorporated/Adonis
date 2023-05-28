--!strict
--[=[
	@function slice
	@within Array

	@param array {T} -- The array to slice.
	@param from? number -- The index to start from (can be negative).
	@param to? number -- The index to end at (can be negative).
	@return {T} -- The sliced array.

	Slices an array.

	```lua
	local array = { 1, 2, 3, 4, 5 }

	local new = Slice(array, 2, 3) -- { 2, 3 }
	local new = Slice(array, -2, -1) -- { 3, 4 }
	local new = Slice(array, 3) -- { 3, 4, 5 }
	```
]=]
local function slice<T>(array: { T }, from: number?, to: number?): { T }
	local length = #array
	local result = {}

	from = if type(from) == "number" then from else 1
	to = if type(to) == "number" then to else length

	if from < 1 then
		from += length
	end

	if to < 1 then
		to += length
	end

	for i = from, to do
		table.insert(result, array[i])
	end

	return result
end

return slice
