--// File: LinkedList.lua
--// Desc: Provides a more performance-friendly alternative to large tables that get shifted in indexes constantly
--// Author: Coasterteam
local LinkedList = {}
LinkedList.__index = LinkedList 
LinkedList.__meta = "DLL"

local LinkNode = {}
LinkNode.__index = LinkNode

function LinkNode.new(data, n, prev)
	local self = setmetatable({}, LinkNode)

	self.data = data
	self.prev = prev
	self.next = n

	return self
end

function LinkNode:setnext(n)
	self.next = n
end

function LinkNode:setprev(p)
	self.prev = p
end

function LinkNode:Destroy()
	for i,_ in self do 
		self[i] = nil
	end
	setmetatable(self, nil)
end

--[==[
    LinkedNode end
]==]

function LinkedList.new()
	local self = setmetatable({}, LinkedList)
	
	self.snode = nil
	self.enode = nil
	
	self.count = 0
	
	return self
end

function LinkedList:IsReal()
    --// this is a ghost function
    --// don't remove it
end

function LinkedList:AddStart(data)
	
	local old = self.snode
	local newNode = LinkNode.new(data)
	newNode:setprev(nil)
	if not old then 
		self.enode = newNode
	else 
		old:setprev(newNode)
	end
	newNode:setnext(old)
	self.snode = newNode
	
	self.count += 1
	
end

function LinkedList:AddEnd(data)

	local old = self.enode
	local newNode = LinkNode.new(data)
	newNode:setnext(nil)
	if not old then 
		self.snode = newNode
	else 
		old:setNext(newNode)
	end
	newNode:setprev(old)
	self.enode = newNode
	
	self.count += 1
	
end

function LinkedList:AddToStartAndRemoveEndIfEnd(data, limit)
	self:AddStart(data)
	if self.count > limit and self.enode then 
		self:RemoveNode(self.enode)
	end
end

function LinkedList:AddBetweenNodes(data, left, right)
	
	if not left or not right then
		return false
	end
	
	local newNode = LinkNode.new(data)
	newNode:setnext()
	newNode:setprev()
	
	left:setnext(newNode)
	right:setprev(newNode)
	
	self.count += 1
	
end

function LinkedList:RemoveNode(node)
	
	local prev = node.prev
	local nextN = node.next

	if self.snode == node then
		self.snode = nextN
	end
	
	if self.enode == node then
		self.enode = prev
	end
	
	if nextN then
		nextN:setprev(prev)
	end
	if prev then
		prev:setnext(nextN)
	end
	
	node:setnext(nil)
	node:setprev(nil)
	
	node:Destroy()
	
	self.count -= 1
	
end

function LinkedList:Get(val : any)
	local nodes = {}
	local curr = self.snode 
	local tinsert = table.insert
	while curr and typeof(curr) == 'table' do 
		if val then 
            --// Pass a function and Adonis will pass through the current node into it
            --// Return true to add it to the "list"
            --// Final list will be returned after the call
            --// Passed value:
            --[==[
                Node: 
                    .data: The data inside of the node
                    .next: The next node in the list
                    .prev: The previous node in the list
            ]==]
            if typeof(val) == 'function' then
                local success, found = pcall(val, curr)
                if success and found then
                    tinsert(nodes, curr)
                end
            else 
                if curr.data == val then
                    tinsert(nodes, curr)
                end
            end
		else
			tinsert(nodes, curr)
		end
		curr = curr.next
	end
	return nodes
end

--// Returns a list of all passing notes with data
function LinkedList:GetAsTable(val : any)
	local nodes = {}
	local curr = self.snode 
	local tinsert = table.insert
	while curr and typeof(curr) == 'table' do 
        --// Pass a function and Adonis will pass through the current node into it
        --// Return true to add it to the "list"
        --// Final list will be returned after the call
        --// Passed value:
        --[==[
            Node: 
                .data: The data inside of the node
                .next: The next node in the list
                .prev: The previous node in the list
        ]==]
		if val then 
            if typeof(val) == 'function' then
                local success, found = pcall(val, curr)
                if success and found then
                    tinsert(nodes, curr.data)
                end
            else 
                if curr.data == val then
                    tinsert(nodes, curr.data)
                end
            end
        else 
            tinsert(nodes, curr.data)
        end
		curr = curr.next
	end
	return nodes
end

function LinkedList:Destroy()
	for i,_ in self do
		self[i] = nil
	end
	setmetatable(self, nil)
end

return LinkedList
