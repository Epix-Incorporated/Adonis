--!strict
--[=[
	@function findWhereLast
	@within Array

	@param array {T} -- The array to search.
	@param predicate (value: T, index: number, array: {T}) -> any -- The predicate to use to check the array.
	@param from? number -- The index to start searching from.
	@return number -- The index of the last item in the array that matches the predicate.

	Finds the index of the last item in the array that passes the predicate.

	```lua
	local array = { "hello", "world", "hello" }

	local index = FindWhereLast(array, function(item, index)
		return item == "hello"
	end) -- 3

	local index = FindWhereLast(array, function(item, index)
		return item == "hello"
	end, 2) -- 1
	```
]=]
local function findWhereLast<T>(
	array: { T },
	predicate: (value: T, index: number, array: { T }) -> any,
	from: number?
): number?
	local length = #array

	from = if type(from) == "number" then if from < 1 then length + from else from else length

	for index = from, 1, -1 do
		if predicate(array[index], index, array) then
			return index
		end
	end

	return
end

return findWhereLast
