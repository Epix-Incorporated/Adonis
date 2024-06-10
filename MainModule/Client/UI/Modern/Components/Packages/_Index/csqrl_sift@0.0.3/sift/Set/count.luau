--!strict
local Sift = script.Parent.Parent

local Util = require(Sift.Util)

--[=[
  @function count
  @within Set

  @param set { [T]: boolean } -- The set to count.
  @param predicate? (item: T, set: { [T]: boolean }) -> boolean? -- The predicate to use to count.
  @return number -- The number of items in the set.

  Counts the number of items in a set.

  ```lua
  local set = { hello = true, world = true }

  local count = Count(set) -- 2
  local count = Count(set, function(item)
    return item == "hello"
  end) -- 1
  ```
]=]
local function count<T>(set: { [T]: boolean }, predicate: ((item: T, set: { [T]: boolean }) -> boolean?)?): number
	local counter = 0

	predicate = if type(predicate) == "function" then predicate else Util.func.truthy

	for item, _ in pairs(set) do
		if predicate(item, set) then
			counter += 1
		end
	end

	return counter
end

return count
