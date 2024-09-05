--!strict
--[=[
	@class Array

	An array is a table consisting of index-value pairs. You don't need to
	manually specify the indices when you create an array.

	```lua
	local array = {
		"hello",
		"world",
	}
	```

	<br><br>

	#### Aliases

	`List`
]=]
local Array = {
	at = require(script.at),
	concat = require(script.concat),
	concatDeep = require(script.concatDeep),
	copy = require(script.copy),
	copyDeep = require(script.copyDeep),
	count = require(script.count),
	create = require(script.create),
	equals = require(script.equals),
	equalsDeep = require(script.equalsDeep),
	every = require(script.every),
	filter = require(script.filter),
	find = require(script.find),
	findLast = require(script.findLast),
	findWhere = require(script.findWhere),
	findWhereLast = require(script.findWhereLast),
	first = require(script.first),
	flatten = require(script.flatten),
	freeze = require(script.freeze),
	freezeDeep = require(script.freezeDeep),
	includes = require(script.includes),
	insert = require(script.insert),
	last = require(script.last),
	map = require(script.map),
	pop = require(script.pop),
	push = require(script.push),
	reduce = require(script.reduce),
	reduceRight = require(script.reduceRight),
	removeIndex = require(script.removeIndex),
	removeIndices = require(script.removeIndices),
	removeValue = require(script.removeValue),
	removeValues = require(script.removeValues),
	reverse = require(script.reverse),
	set = require(script.set),
	shift = require(script.shift),
	shuffle = require(script.shuffle),
	slice = require(script.slice),
	some = require(script.some),
	sort = require(script.sort),
	splice = require(script.splice),
	toSet = require(script.toSet),
	unshift = require(script.unshift),
	update = require(script.update),
	zip = require(script.zip),
	zipAll = require(script.zipAll),
}

Array.join = Array.concat
Array.merge = Array.concat
Array.joinDeep = Array.concatDeep
Array.mergeDeep = Array.concatDeep
Array.append = Array.push
Array.prepend = Array.unshift
Array.indexOf = Array.find
Array.has = Array.includes
Array.contains = Array.includes

return Array
