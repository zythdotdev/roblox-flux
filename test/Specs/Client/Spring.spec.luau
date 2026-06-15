return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Flux = require(ReplicatedStorage.Packages.Flux)

	describe("Spring", function()
		it("should validate source, speed, and damping arguments", function()
			expect(function()
				Flux:Spring(nil :: any, 20, 1)
			end).to.throw()

			expect(function()
				Flux:Spring(Flux:State(0), nil :: any, 1)
			end).to.throw()

			expect(function()
				Flux:Spring(Flux:State(0), 20, nil :: any)
			end).to.throw()
		end)

		it("should set the initial value immediately without animating", function()
			local state = Flux:State(10)
			local anim = Flux:Spring(state, 20, 1)

			expect(anim:Get()).to.equal(10)
			anim:Destroy()
		end)

		it("should fire Observe immediately with the current value", function()
			local state = Flux:State(42)
			local anim = Flux:Spring(state, 20, 1)
			local received = nil

			anim:Observe(function(value)
				received = value
			end)

			expect(received).to.equal(42)
			anim:Destroy()
		end)

		it("should animate toward the target value over time", function()
			local state = Flux:State(0)
			local anim = Flux:Spring(state, 30, 1)

			state:Set(100)
			task.wait(0.5)

			local value = anim:Get() or 0
			expect(math.abs(value - 100) < 1).to.equal(true)
			anim:Destroy()
		end)

		it("should be mid-animation before settling", function()
			local state = Flux:State(0)
			local anim = Flux:Spring(state, 10, 1)

			state:Set(100)
			task.wait(0.05)

			local value = anim:Get() or 0
			expect(value > 0 and value < 100).to.equal(true)
			anim:Destroy()
		end)

		it("should stop updating after Destroy", function()
			local state = Flux:State(0)
			local anim = Flux:Spring(state, 20, 1)

			anim:Destroy()
			state:Set(100)
			task.wait(0.3)

			expect(anim:Get()).to.equal(0)
		end)

		it("should support Vector2 values", function()
			local state = Flux:State(Vector2.new(0, 0))
			local anim = Flux:Spring(state, 30, 1)

			state:Set(Vector2.new(100, 200))
			task.wait(0.5)

			local value = anim:Get()
			expect(value).to.be.ok()
			expect(math.abs(value.X - 100) < 1).to.equal(true)
			expect(math.abs(value.Y - 200) < 1).to.equal(true)
			anim:Destroy()
		end)

		it("should support UDim2 values", function()
			local state = Flux:State(UDim2.fromScale(0, 0))
			local anim = Flux:Spring(state, 30, 1)

			state:Set(UDim2.fromScale(1, 1))
			task.wait(0.5)

			local value = anim:Get()
			expect(value).to.be.ok()
			expect(math.abs(value.X.Scale - 1) < 0.01).to.equal(true)
			expect(math.abs(value.Y.Scale - 1) < 0.01).to.equal(true)
			anim:Destroy()
		end)

		it("should be destroyable via Bag", function()
			local Bag = require(ReplicatedStorage.Packages.Bag)
			local bag = Bag.new()

			local state = Flux:State(0)
			local anim = Flux:Spring(state, 20, 1)
			bag:Add(anim)

			expect(function()
				bag:Destroy()
			end).never.to.throw()
		end)

		it("should be safe to call Destroy twice", function()
			local state = Flux:State(0)
			local anim = Flux:Spring(state, 20, 1)
			anim:Destroy()
			expect(function()
				anim:Destroy()
			end).never.to.throw()
		end)

		it("should be safe to Destroy manually then via Bag", function()
			local Bag = require(ReplicatedStorage.Packages.Bag)
			local bag = Bag.new()

			local state = Flux:State(0)
			local anim = Flux:Spring(state, 20, 1)
			bag:Add(anim)
			anim:Destroy()
			expect(function()
				bag:Destroy()
			end).never.to.throw()
		end)

		it("should reset after nil and snap to next non-nil target", function()
			local state = Flux:State(0)
			local anim = Flux:Spring(state, 20, 1)

			state:Set(nil)
			expect(anim:Get()).to.equal(nil)

			state:Set(25)
			expect(anim:Get()).to.equal(25)
			anim:Destroy()
		end)

		it("should reject invalid speed and damping values", function()
			local state = Flux:State(0)

			expect(function()
				Flux:Spring(state, 0, 1)
			end).to.throw()

			expect(function()
				Flux:Spring(state, 20, -1)
			end).to.throw()
		end)
	end)
end
