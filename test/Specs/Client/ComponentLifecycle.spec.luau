return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Component Lifecycle", function()
		-- Define component and entity once at startup
		Anima:_DefineComponent("ClientTestComponent", {
			OnInit = function(self, props)
				return { Value = props.Value or 100 }
			end,
			OnDeinit = function(self)
				-- cleanup
			end
		})

		Anima:_DefineEntity("ClientTestEntity2", {
			OnInit = function(self, properties)
				return {}
			end
		})

		it("Should create a component", function()
			local component = Anima:CreateComponent("ClientTestComponent")
			expect(component).to.be.ok()
			expect(component._Name).to.equal("ClientTestComponent")
			expect(component._Destroyed).to.equal(false)
		end)

		it("Should create a component with properties", function()
			local component = Anima:CreateComponent("ClientTestComponent", { Value = 42 })
			expect(component.Value).to.equal(42)
		end)

		it("Should add component to entity", function()
			local entity = Anima:CreateEntity("ClientTestEntity2")
			local component = Anima:CreateComponent("ClientTestComponent")
			
			entity:AddComponent(component)
			expect(entity:GetComponent("ClientTestComponent")).to.equal(component)
			expect(component:GetEntity()).to.equal(entity)
		end)

		it("Should fire ComponentAdded event", function()
			local fired = false
			local connection = Anima.ComponentAdded:Connect(function(entity, component)
				fired = true
			end)

			local entity = Anima:CreateEntity("ClientTestEntity2")
			local component = Anima:CreateComponent("ClientTestComponent")
			entity:AddComponent(component)
			
			connection:Disconnect()
			expect(fired).to.equal(true)
		end)

		it("Should remove component from entity", function()
			local entity = Anima:CreateEntity("ClientTestEntity2")
			local component = Anima:CreateComponent("ClientTestComponent")
			entity:AddComponent(component)
			
			local removed = entity:RemoveComponent("ClientTestComponent")
			expect(removed).to.equal(component)
			expect(entity:GetComponent("ClientTestComponent")).never.to.be.ok()
		end)

		it("Should fire ComponentRemoved event", function()
			local fired = false
			local entity = Anima:CreateEntity("ClientTestEntity2")
			local component = Anima:CreateComponent("ClientTestComponent")
			entity:AddComponent(component)
			
			local connection = Anima.ComponentRemoved:Connect(function(e, c)
				fired = true
			end)

			entity:RemoveComponent("ClientTestComponent")
			connection:Disconnect()
			expect(fired).to.equal(true)
		end)

		it("Should destroy component", function()
			local component = Anima:CreateComponent("ClientTestComponent")
			component:Destroy()
			
			expect(component._Destroyed).to.equal(true)
		end)

		it("Should remove component from entity when destroyed", function()
			local entity = Anima:CreateEntity("ClientTestEntity2")
			local component = Anima:CreateComponent("ClientTestComponent")
			entity:AddComponent(component)

			component:Destroy()
			expect(entity:GetComponent("ClientTestComponent")).never.to.be.ok()
		end)
	end)
end
