-- Run with `lune run Tests/LinkedList.spec.luau` from the repository root.
local LinkedList = require("../MainModule/Shared/DoubleLinkedList")

local list = LinkedList.new()
list:AddStart("second")
list:AddEnd("third")
list:AddStart("first")

-- Checks the stored values in order against an expected sequence.
local function expectValues(expected)
	local values = list:GetAsTable()
	assert(#values == #expected, "Linked-list length did not match")
	for index, value in expected do
		assert(values[index] == value, `Unexpected linked-list value at index {index}`)
	end
end

expectValues({"first", "second", "third"})
assert(list.count == 3, "Linked-list count did not match")

local middle = list:Get("second")[1]
assert(middle and middle.prev.data == "first" and middle.next.data == "third", "Linked-list node links did not match")
assert(list:RemoveNode(middle) == "second", "Removing a node returned the wrong value")
expectValues({"first", "third"})
assert(list.count == 2, "Removing a node did not update the count")

list:AddToStartAndRemoveEndIfEnd("new first", 2)
expectValues({"new first", "first"})
assert(list.count == 2, "Bounded insertion did not preserve the list limit")

print("Shared linked-list smoke test passed")
