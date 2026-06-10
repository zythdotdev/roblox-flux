return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Update Loops", function()
		Anima:_DefineEntity("TestEntity4", {
			OnInit = function(self, properties)
				return {}
				end
		})

		it("Should call OnHeartbeat", function()
			local called = false
			
			Anima:_DefineComponent("HeartbeatComponent", {
				OnInit = function(self, props)
					return {}
				end,
				OnHeartbeat = function(self, deltaTime)
					called = true
				end
			})

			local entity = Anima:CreateEntity("TestEntity4")
			local component = Anima:CreateComponent("HeartbeatComponent")
			entity:AddComponent(component)
			
			-- Wait for a heartbeat
			task.wait(0.1)
			expect(called).to.equal(true)
		end)

		it("Should call OnStepped", function()
			local called = false
			
			Anima:_DefineComponent("SteppedComponent", {
				OnInit = function(self, props)
					return {}
				end,
				OnStepped = function(self, time, deltaTime)
					called = true
				end
			})

			local entity = Anima:CreateEntity("TestEntity4")
			local component = Anima:CreateComponent("SteppedComponent")
			entity:AddComponent(component)
			
			-- Wait for a step
			task.wait()
			expect(called).to.equal(true)
		end)

		it("Should call OnUpdate with custom interval", function()
			local callCount = 0
			
			Anima:_DefineComponent("UpdateComponent", {
				OnInit = function(self, props)
					return {}
				end,
				OnUpdate = function(self, deltaTime)
					callCount += 1
				end,
				UpdateInterval = 0.1
			})

			local entity = Anima:CreateEntity("TestEntity4")
			local component = Anima:CreateComponent("UpdateComponent")
			entity:AddComponent(component)
			
			-- Wait for updates to occur
			task.wait(1)
			expect(callCount).to.never.to.equal(0)
		end)

		it("Should stop calling updates when component is destroyed", function()
			local callCount = 0
			
			Anima:_DefineComponent("DestroyableComponent", {
				OnInit = function(self, props)
					return {}
				end,
				OnHeartbeat = function(self, deltaTime)
					callCount = callCount + 1
				end
			})

			local entity = Anima:CreateEntity("TestEntity4")
			local component = Anima:CreateComponent("DestroyableComponent")
			entity:AddComponent(component)
			
			task.wait(0.1)
			local countBeforeDestroy = callCount
			component:Destroy()
			task.wait(0.1)
			
			expect(component.callCount).to.equal(countBeforeDestroy)
		end)
	end)
end
