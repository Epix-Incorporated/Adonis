return function (self, Event, State)

	self[Event] = function(...)
		
		-- Set state
		self:setState({
			State = State
		})
		
		-- Custom callback
		local Callback = self.props[Event]
		if Callback then
			Callback(...)
		end
	end
end