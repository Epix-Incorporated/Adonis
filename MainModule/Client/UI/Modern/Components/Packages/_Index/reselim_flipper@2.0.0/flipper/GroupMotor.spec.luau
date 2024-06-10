return function()
	local GroupMotor = require(script.Parent.GroupMotor)

	local Instant = require(script.Parent.Instant)
	local Spring = require(script.Parent.Spring)

	it("should complete when all child motors are complete", function()
		local motor = GroupMotor.new({
			A = 1,
			B = 2,
		}, false)

		expect(motor._complete).to.equal(true)

		motor:setGoal({
			A = Instant.new(3),
			B = Spring.new(4, { frequency = 7.5, dampingRatio = 1 })
		})

		expect(motor._complete).to.equal(false)

		motor:step(1/60)

		expect(motor._complete).to.equal(false)

		for _ = 1, 0.5 * 60 do
			motor:step(1/60)
		end

		expect(motor._complete).to.equal(true)
	end)

	it("should start when the goal is set", function()
		local motor = GroupMotor.new({
			A = 0,
		}, false)

		local bool = false
		motor:onStart(function()
			bool = not bool
		end)

		motor:setGoal({
			A = Instant.new(1)
		})

		expect(bool).to.equal(true)

		motor:setGoal({
			A = Instant.new(1)
		})

		expect(bool).to.equal(false)
	end)

	it("should properly return all values", function()
		local motor = GroupMotor.new({
			A = 1,
			B = 2,
		}, false)

		local value = motor:getValue()

		expect(value.A).to.equal(1)
		expect(value.B).to.equal(2)
	end)

	it("should error when a goal is given to GroupMotor.new", function()
		local success = pcall(function()
			GroupMotor.new(Instant.new(0))
		end)

		expect(success).to.equal(false)
	end)

	it("should error when a single goal is provided to GroupMotor:step", function()
		local success = pcall(function()
			GroupMotor.new({ a = 1 }):setGoal(Instant.new(0))
		end)

		expect(success).to.equal(false)
	end)
end
