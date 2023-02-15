--!strict
--[=[
	@class Set

	Sets are a collection of values. They are used to store unique values.
	They are essentially a dictionary, but each value is stored as a boolean.
	This means that a value can only be in a set once.

	```lua
	local set = { hello = true }

	local newSet = Add(set, "world") -- { hello = true, world = true }
	```
]=]
local set = {
	add = require(script.add),
	copy = require(script.copy),
	count = require(script.count),
	delete = require(script.delete),
	filter = require(script.filter),
	fromArray = require(script.fromArray),
	has = require(script.has),
	intersection = require(script.intersection),
	isSubset = require(script.isSubset),
	isSuperset = require(script.isSuperset),
	map = require(script.map),
	merge = require(script.merge),
	toArray = require(script.toArray),
}

set.fromList = set.fromArray
set.join = set.merge
set.subtract = set.delete
set.union = set.merge

return set
