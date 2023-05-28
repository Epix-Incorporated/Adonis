return function (Value)
	if Value == nil then
		return 'Indeterminate'
	elseif Value == true then
		return 'Selected'
	elseif Value == false then
		return 'None'
	end
end