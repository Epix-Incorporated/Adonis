--!strict
--[=[
	@class Dictionary

	Dictionaries are a type of data structure that can be used to store key-value pairs.

	```lua
	local dictionary = {
		cats = 2,
		dogs = 1
	}

	print(dictionary.cats) -- 2
	```
]=]
local Dictionary = {
	copy = require(script.copy),
	copyDeep = require(script.copyDeep),
	count = require(script.count),
	entries = require(script.entries),
	equals = require(script.equals),
	equalsDeep = require(script.equalsDeep),
	every = require(script.every),
	filter = require(script.filter),
	flatten = require(script.flatten),
	flip = require(script.flip),
	freeze = require(script.freeze),
	freezeDeep = require(script.freezeDeep),
	fromArrays = require(script.fromArrays),
	fromEntries = require(script.fromEntries),
	has = require(script.has),
	includes = require(script.includes),
	keys = require(script.keys),
	map = require(script.map),
	merge = require(script.merge),
	mergeDeep = require(script.mergeDeep),
	removeKey = require(script.removeKey),
	removeKeys = require(script.removeKeys),
	removeValue = require(script.removeValue),
	removeValues = require(script.removeValues),
	set = require(script.set),
	some = require(script.some),
	update = require(script.update),
	values = require(script.values),
}

Dictionary.join = Dictionary.merge
Dictionary.joinDeep = Dictionary.mergeDeep

return Dictionary
