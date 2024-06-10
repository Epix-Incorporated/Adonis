return function()
	local isMotor = require(script.Parent.isMotor)

	local SingleMotor = require(script.Parent.SingleMotor)
	local GroupMotor = require(script.Parent.GroupMotor)

	local singleMotor = SingleMotor.new(0)
	local groupMotor = GroupMotor.new({})

	it("should properly detect motors", function()
		expect(isMotor(singleMotor)).to.equal(true)
		expect(isMotor(groupMotor)).to.equal(true)
	end)

	it("shouldn't detect things that aren't motors", function()
		expect(isMotor({})).to.equal(false)
	end)

	it("should return the proper motor type", function()
		local _, singleMotorType = isMotor(singleMotor)
		local _, groupMotorType = isMotor(groupMotor)

		expect(singleMotorType).to.equal("Single")
		expect(groupMotorType).to.equal("Group")
	end)
end
