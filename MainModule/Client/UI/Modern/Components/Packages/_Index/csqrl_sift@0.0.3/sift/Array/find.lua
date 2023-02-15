--!strict
--[=[
	@function find
	@within Array

	@param array {T} -- The array to search.
	@param value? any -- The value to search for.
	@param from? number -- The index to start searching from.
	@return number? -- The index of the first item in the array that matches the value.

	Finds the index of the first item in the array that matches the value. This is
	mostly a wrapper around `table.find`, with the ability to specify a negative
	number as the start index (to search relative to the end of the array).

	#### Aliases
	`indexOf`

	```lua
	local array = { "hello", "world", "hello" }

	local index = Find(array, "hello") -- 1
	local index = Find(array, "hello", 2) -- 3
	```
]=]
local function find<T>(array: { T }, value: any?, from: number?): number?
	local length = #array

	from = if type(from) == "number" then if from < 1 then length + from else from else 1

	return table.find(array, value, from)
end

return find
