return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Update Loops (Client-specific)", function()
		Anima:_DefineEntity("ClientTestEntity4", {
			OnInit = function(self, properties)
				return {}
			end
		})

		Anima:_DefineComponent("RenderSteppedComponent", {
			OnInit = function(self, props)
				return { called = false }
			end,
			OnRenderStepped = function(self, deltaTime)
				self.called = true
			end
		})

		Anima:_DefineComponent("HeartbeatComponent", {
			OnInit = function(self, props)
				return { called = false }
			end,
			OnHeartbeat = function(self, deltaTime)
				self.called = true
			end
		})

		Anima:_DefineComponent("UpdateComponent", {
			OnInit = function(self, props)
				return { callCount = 0 }
			end,
			OnUpdate = function(self, deltaTime)
				self.callCount = self.callCount + 1
			end,
			UpdateInterval = 0.1
		})

		Anima:_DefineComponent("DestroyableComponent", {
			OnInit = function(self, props)
				return { callCount = 0 }
			end,
			OnRenderStepped = function(self, deltaTime)
				self.callCount = self.callCount + 1
			end
		})

		it("Should call OnRenderStepped on client", function()
			if not RunService:IsClient() then
				return
			end

			local entity = Anima:CreateEntity("ClientTestEntity4")
			local component = Anima:CreateComponent("RenderSteppedComponent")
			entity:AddComponent(component)

			-- Wait for two frames to ensure connection fires
			RunService.RenderStepped:Wait()
			RunService.RenderStepped:Wait()
			expect(component.called).to.equal(true)
		end)

		it("Should call OnHeartbeat", function()
			local entity = Anima:CreateEntity("ClientTestEntity4")
			local component = Anima:CreateComponent("HeartbeatComponent")
			entity:AddComponent(component)
			
			-- Wait for a heartbeat
			task.wait(0.1)
			expect(component.called).to.equal(true)
		end)

		it("Should call OnUpdate with custom interval", function()
			local entity = Anima:CreateEntity("ClientTestEntity4")
			local component = Anima:CreateComponent("UpdateComponent")
			entity:AddComponent(component)
			
			-- Wait for updates to occur
			task.wait(0.25)
			expect(component.callCount).to.be.near(2, 1)
		end)

		it("Should stop calling updates when component is destroyed", function()
			if not RunService:IsClient() then
				return
			end

			local entity = Anima:CreateEntity("ClientTestEntity4")
			local component = Anima:CreateComponent("DestroyableComponent")
			entity:AddComponent(component)
			
			RunService.RenderStepped:Wait()
			local countBeforeDestroy = component.callCount
			component:Destroy()
			RunService.RenderStepped:Wait()
			
			expect(component.callCount).to.equal(countBeforeDestroy)
		end)
	end)
end
