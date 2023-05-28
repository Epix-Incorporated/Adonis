return function()
	local SingleMotor = require(script.Parent.SingleMotor)
	local Instant = require(script.Parent.Instant)

	it("should assign new state on step", function()
		local motor = SingleMotor.new(0, false)

		motor:setGoal(Instant.new(5))
		motor:step(1/60)

		expect(motor._state.complete).to.equal(true)
		expect(motor._state.value).to.equal(5)
	end)

	it("should invoke onComplete listeners when the goal is completed", function()
		local motor = SingleMotor.new(0, false)

		local didComplete = false
		motor:onComplete(function()
			didComplete = true
		end)

		motor:setGoal(Instant.new(5))
		motor:step(1/60)

		expect(didComplete).to.equal(true)
	end)

	it("should start when the goal is set", function()
		local motor = SingleMotor.new(0, false)

		local bool = false
		motor:onStart(function()
			bool = not bool
		end)

		motor:setGoal(Instant.new(5))

		expect(bool).to.equal(true)

		motor:setGoal(Instant.new(5))

		expect(bool).to.equal(false)
	end)
end
