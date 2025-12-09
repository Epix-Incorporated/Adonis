local serviceUtils = {}

local CreatedItems = setmetatable({}, {__mode = "v"})


serviceUtils.InstanceNew = function(class, data, noWrap, noAdd)
	--local new = noWrap and oldInstNew(class) or Instance.new(class)
	local new = Instance.new(class)
	if data then
		if type(data) == "table" then
			local parent = data.Parent
			--if service.Wrapped(parent) then parent = parent:GetObject() end
			data.Parent = nil

			for val,prop in data do
				new[val] = prop
			end

			if parent then
				new.Parent = parent
			end
		elseif type(data) == "userdata" then
			--[[if service.Wrapped(data) then
				new.Parent = data:GetObject()
			else
				new.Parent = data
			end]]
			new.Parent = data
		end
	end

	if new and not noAdd then
		table.insert(CreatedItems, new)
	end

	return new
end

return serviceUtils
