--!strict
local Sift = script.Parent.Parent

local Util = require(Sift.Util)

--[=[
  @function filter
  @within Set

  @param set { [T]: boolean } -- The set to filter.
  @param predicate? (item: T, set: { [T]: boolean }) -> any -- The function to filter the set with.
  @return { [T]: boolean } -- The filtered set.

  Filters a set using a predicate. Any items that do not pass the predicate will be removed from the set.

  ```lua
  local set = { hello = true, world = true }

  local newSet = Filter(set, function(value)
    return value ~= "hello"
  end) -- { world = true }
  ```
]=]
local function filter<T>(set: { [T]: boolean }, predicate: ((T, { [T]: boolean }) -> any)?): { [T]: boolean }
	local result = {}

	predicate = if type(predicate) == "function" then predicate else Util.func.truthy

	for key, _ in pairs(set) do
		if predicate(key, set) then
			result[key] = true
		end
	end

	return result
end

return filter
