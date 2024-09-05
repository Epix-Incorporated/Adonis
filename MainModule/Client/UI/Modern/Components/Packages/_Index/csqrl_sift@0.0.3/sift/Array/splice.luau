--!strict
--[=[
	@function splice
	@within Array

	@param array {T} -- The array to splice.
	@param start? number -- The index to start splicing at (can be negative).
	@param end? number -- The index to end splicing at (can be negative).
	@param ... ...T -- The values to insert.
	@return {T} -- The spliced array.

	Splices an array.

	```lua
	local array = { 1, 2, 3, 4, 5 }

	local new = Splice(array, 3, 4, 6, 7) -- { 1, 2, 6, 7, 4, 5 }
	local new = Splice(array, -1, 0, 6, 7) -- { 1, 2, 3, 4, 6, 7 }
	local new = Splice(array, 4, -1, 6, 7) -- { 1, 2, 3, 6, 7, 5 }
	```
]=]
local function splice<T>(array: { T }, from: number?, to: number?, ...: T?): { T }
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

	for index = 1, from - 1 do
		table.insert(result, array[index])
	end

	for _, value in ipairs({ ... }) do
		table.insert(result, value)
	end

	for index = to + 1, length do
		table.insert(result, array[index])
	end

	return result
end

return splice
