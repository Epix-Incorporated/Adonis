return function()
	local RunService = game:GetService("RunService")

	local BaseMotor = require(script.Parent.BaseMotor)

	describe("connection management", function()
		local motor = BaseMotor.new()

		it("should hook up connections on :start()", function()
			motor:start()
			expect(typeof(motor._connection)).to.equal("RBXScriptConnection")
		end)

		it("should remove connections on :stop() or :destroy()", function()
			motor:stop()
			expect(motor._connection).to.equal(nil)
		end)
	end)

	it("should call :step() with deltaTime", function()
		local motor = BaseMotor.new()

		local argumentsProvided
		function motor:step(...)
			argumentsProvided = { ... }
			motor:stop()
		end

		motor:start()
		
		local expectedDeltaTime = RunService.RenderStepped:Wait()

		-- Give it another frame, because connections tend to be invoked later than :Wait() calls
		RunService.RenderStepped:Wait()

		expect(argumentsProvided).to.be.ok()
		expect(argumentsProvided[1]).to.equal(expectedDeltaTime)
	end)
end
