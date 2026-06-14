return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Flux = require(ReplicatedStorage.Packages.Flux)

	describe("State", function()
		it("should create a state with an initial value", function()
			local state = Flux:State(42)
			expect(state).to.be.ok()
			expect(state:Get()).to.equal(42)
		end)

		it("should create a state with nil initial value", function()
			local state = Flux:State(nil)
			expect(state).to.be.ok()
			expect(state:Get()).to.equal(nil)
		end)

		it("should create a state with no argument", function()
			local state = Flux:State()
			expect(state).to.be.ok()
			expect(state:Get()).to.equal(nil)
		end)

		it("should update value with Set", function()
			local state = Flux:State(0)
			state:Set(10)
			expect(state:Get()).to.equal(10)
		end)

		it("should set value to nil", function()
			local state = Flux:State(5)
			state:Set(nil)
			expect(state:Get()).to.equal(nil)
		end)

		it("should not fire observers when set to same value", function()
			local state = Flux:State(7)
			local callCount = 0

			state:Observe(function(_value)
				callCount = callCount + 1
			end)

			-- Initial observe call
			expect(callCount).to.equal(1)

			state:Set(7) -- same value
			expect(callCount).to.equal(1)
		end)

		it("should fire observer immediately with current value", function()
			local state = Flux:State("hello")
			local received = nil

			state:Observe(function(value)
				received = value
			end)

			expect(received).to.equal("hello")
		end)

		it("should fire observer on value change", function()
			local state = Flux:State(1)
			local received = nil

			state:Observe(function(value)
				received = value
			end)

			state:Set(99)
			expect(received).to.equal(99)
		end)

		it("should support multiple observers", function()
			local state = Flux:State(0)
			local receivedA = nil
			local receivedB = nil

			state:Observe(function(value)
				receivedA = value
			end)

			state:Observe(function(value)
				receivedB = value
			end)

			state:Set(5)
			expect(receivedA).to.equal(5)
			expect(receivedB).to.equal(5)
		end)

		it("should disconnect observer", function()
			local state = Flux:State(0)
			local callCount = 0

			local connection = state:Observe(function(_value)
				callCount = callCount + 1
			end)

			expect(callCount).to.equal(1) -- initial
			connection:Disconnect()

			state:Set(10)
			expect(callCount).to.equal(1) -- not called again
		end)

		it("should support string values", function()
			local state = Flux:State("foo")
			state:Set("bar")
			expect(state:Get()).to.equal("bar")
		end)

		it("should support boolean values", function()
			local state = Flux:State(false)
			state:Set(true)
			expect(state:Get()).to.equal(true)
		end)

		it("should create a computed state from dependencies", function()
			local count = Flux:State(4)
			local doubled = Flux:Computed(function(value)
				return value * 2
			end, { count })

			expect(doubled:Get()).to.equal(8)

			count:Set(7)
			expect(doubled:Get()).to.equal(14)
		end)

		it("should pass dependency values into the callback", function()
			local base = Flux:State(3)
			local multiplier = Flux:State(5)
			local total = Flux:Computed(function(value, factor)
				return value * factor
			end, { base, multiplier })

			expect(total:Get()).to.equal(15)

			base:Set(4)
			expect(total:Get()).to.equal(20)
		end)

		it("should clean up computed observers when destroyed", function()
			local count = Flux:State(1)
			local doubled = Flux:Computed(function()
				return count:Get() * 2
			end, { count })
			local callCount = 0

			doubled:Observe(function(_value)
				callCount = callCount + 1
			end)

			expect(callCount).to.equal(1)
			doubled:Destroy()
			count:Set(9)

			expect(callCount).to.equal(1)
		end)

		it("should return a working Setter function", function()
			local state = Flux:State(0)
			local setter = state:Setter()

			setter(42)
			expect(state:Get()).to.equal(42)
		end)

		it("should clean up on Destroy", function()
			local state = Flux:State(10)
			state:Destroy()

			expect(function()
				state:Get()
			end).to.throw()
		end)
	end)
end
