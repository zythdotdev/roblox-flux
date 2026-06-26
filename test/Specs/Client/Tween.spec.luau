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

		it("should reject a source value whose type changes", function()
			-- The type guard lives in the Tween's observer. Observer errors are isolated by the
			-- Event library (they surface asynchronously), so Set does not throw synchronously.
			-- What we can assert is that the invalid write never reaches the animated output.
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.2))

			state:Set("oops" :: any)
			task.wait(0.1)

			expect(typeof(anim:Get())).never.to.equal("string")
			anim:Destroy()
		end)

		it("should jump instantly when animated is false, without waiting", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.5))

			state:Set(100, false)
			-- No task.wait: an instant write must land synchronously.
			expect(anim:Get()).to.equal(100)
			anim:Destroy()
		end)

		it("should fire Completed when an instant write arrives", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.5))

			local fired = false
			anim:Completed(function()
				fired = true
			end)

			state:Set(100, false)
			expect(fired).to.equal(true)
			anim:Destroy()
		end)

		it("should not arrive instantly for an animated write", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.5))

			state:Set(100) -- animated (default)
			-- Without waiting, the value should still be at (or near) the start.
			expect(anim:Get()).never.to.equal(100)
			anim:Destroy()
		end)

		it("should not fire Completed when instantly cleared to nil", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.5))

			local fired = false
			anim:Completed(function()
				fired = true
			end)

			state:Set(nil, false)
			expect(anim:Get()).to.equal(nil)
			expect(fired).to.equal(false)
			anim:Destroy()
		end)

		it("should keep source and displayed value coherent after an instant write", function()
			-- Regression: an instant seed must update the single source of truth, so a later
			-- Set to the same value is a true no-op (no missed animation).
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.2))

			state:Set(50, false)
			expect(state:Get()).to.equal(50)
			expect(anim:Get()).to.equal(50)

			-- Animate away, then back to the seeded value to prove it animates normally.
			state:Set(0)
			task.wait(0.3)
			expect(math.abs((anim:Get() or 0) - 0) < 0.01).to.equal(true)
			anim:Destroy()
		end)

		it("should cancel an in-flight animation when an instant write lands", function()
			local state = Flux:State(0)
			local anim = Flux:Tween(state, TweenInfo.new(0.5))

			state:Set(100) -- start animating
			task.wait(0.1)
			state:Set(25, false) -- instant write mid-flight
			expect(anim:Get()).to.equal(25)

			-- Confirm the old animation did not keep running.
			task.wait(0.2)
			expect(anim:Get()).to.equal(25)
			anim:Destroy()
		end)
	end)
end
