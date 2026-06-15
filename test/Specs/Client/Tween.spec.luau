return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Flux = require(ReplicatedStorage.Packages.Flux)

	describe("Tween", function()
		it("should validate source and tweenInfo arguments", function()
			expect(function()
				Flux:Tween(nil :: any, TweenInfo.new(0.2))
			end).to.throw()

			expect(function()
				Flux:Tween(Flux:State(0), nil :: any)
			end).to.throw()
		end)

		it("should set the initial value immediately without animating", function()
			local state = Flux:State(10)
			local anim = Flux:Tween(state, TweenInfo.new(0.5))

			expect(anim:Get()).to.equal(10)
			anim:Destroy()
		end)

		it("should fire Observe immediately with the current value", function()
			local state = Flux:State(42)
			local anim = Flux:Tween(state, TweenInfo.new(0.5))
			local received = nil

			anim:Observe(function(value)
				received = value
			end)

			expect(received).to.equal(42)
			anim:Destroy()
		end)

		it("should animate toward the target value over time", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.2))

			state:Set(100)
			task.wait(0.3)

			local value = anim:Get() or 0
			expect(math.abs(value - 100) < 0.01).to.equal(true)
			anim:Destroy()
		end)

		it("should be mid-animation before the tween completes", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.5))

			state:Set(100)
			task.wait(0.1)

			local value = anim:Get() or 0
			expect(value > 0 and value < 100).to.equal(true)
			anim:Destroy()
		end)

		it("should stop updating after Destroy", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.2))

			anim:Destroy()
			state:Set(100)
			task.wait(0.3)

			expect(anim:Get()).to.equal(0)
		end)

		it("should support UDim2 values", function()
			local state = Flux:State(UDim2.fromScale(0, 0))
			local anim = Flux:Tween(state, TweenInfo.new(0.2))

			state:Set(UDim2.fromScale(1, 1))
			task.wait(0.3)

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
			local anim = Flux:Tween(state, TweenInfo.new(0.2))
			bag:Add(anim)

			expect(function()
				bag:Destroy()
			end).never.to.throw()
		end)

		it("should be safe to call Destroy twice", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.2))
			anim:Destroy()
			expect(function()
				anim:Destroy()
			end).never.to.throw()
		end)

		it("should be safe to Destroy manually then via Bag", function()
			local Bag = require(ReplicatedStorage.Packages.Bag)
			local bag = Bag.new()

			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.2))
			bag:Add(anim)
			anim:Destroy()
			expect(function()
				bag:Destroy()
			end).never.to.throw()
		end)

		it("should reset after nil and snap to next non-nil target", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.2))

			state:Set(nil)
			expect(anim:Get()).to.equal(nil)

			state:Set(25)
			expect(anim:Get()).to.equal(25)
			anim:Destroy()
		end)

		it("should error when source value type changes", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.2))

			expect(function()
				state:Set("oops")
			end).to.throw()

			anim:Destroy()
		end)
	end)
end
