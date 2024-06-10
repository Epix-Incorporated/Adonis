--!strict
--[=[
	@function findWhere
	@within Array

	@param array {T} -- The array to search.
	@param predicate (value: T, index: number, array: {T}) -> any -- The predicate to use to check the array.
	@param from? number -- The index to start searching from.
	@return number -- The index of the first item in the array that matches the predicate.

	Finds the index of the first item in the array that passes the predicate.

	```lua
	local array = { 1, 2, 3 }

	local index = FindWhere(array, function(item, index)
		return item > 1
	end) -- 2
	```
]=]
local function findWhere<T>(
	array: { T },
	predicate: (value: T, index: number, array: { T }) -> any,
	from: number?
): number?
	local length = #array

	from = if type(from) == "number" then if from < 1 then length + from else from else 1

	for index = from, #array do
		if predicate(array[index], index, array) then
			return index
		end
	end

	return
end

return findWhere
