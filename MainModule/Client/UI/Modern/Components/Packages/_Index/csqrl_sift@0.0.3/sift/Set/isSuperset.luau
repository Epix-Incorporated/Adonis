--!strict
local isSubset = require(script.Parent.isSubset)

--[=[
  @function isSuperset
  @within Set

  @param superset { [any]: boolean } -- The superset to check.
  @param subset { [any]: boolean } -- The subset to check against.
  @return boolean -- Whether the superset is a superset of the subset.

  Checks whether a set is a superset of another set.

  ```lua
  local set = { hello = true, world = true }
  local subset = { hello = true }

  local isSuperset = IsSuperset(set, subset) -- true
  ```
]=]
local function isSuperset<any>(superset: { [any]: boolean }, subset: { [any]: boolean }): boolean
	return isSubset(subset, superset)
end

return isSuperset
