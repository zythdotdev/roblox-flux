return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Entity Lifecycle", function()
		-- Define a simple test entity once at startup
		Anima:_DefineEntity("TestEntity", {
			OnInit = function(self, properties)
				return {}
			end,
			OnDeinit = function(self)
				-- cleanup
			end
		})

		it("Should create an entity", function()
			local entity = Anima:CreateEntity("TestEntity")
			expect(entity).to.be.ok()
			expect(entity._Name).to.equal("TestEntity")
			expect(entity._Destroyed).to.equal(false)
		end)

		it("Should create an entity with an instance", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntity("TestEntity", nil, instance)
			
			expect(entity).to.be.ok()
			expect(entity._Instance).to.equal(instance)
			expect(entity._Id).to.be.ok()
			expect(instance:GetAttribute("_AnimaId")).to.equal(entity._Id)
		end)

		it("Should fire EntityCreated event", function()
			local fired = false
			local connection = Anima.EntityCreated:Connect(function(entity)
				fired = true
			end)

			Anima:CreateEntity("TestEntity")
			connection:Disconnect()
			expect(fired).to.equal(true)
		end)

		it("Should destroy an entity", function()
			local entity = Anima:CreateEntity("TestEntity")
			entity:Destroy()
			
			expect(entity._Destroyed).to.equal(true)
		end)

		it("Should fire EntityDestroyed event", function()
			local fired = false
			local entity = Anima:CreateEntity("TestEntity")
			
			local connection = Anima.EntityDestroyed:Connect(function(e)
				fired = true
			end)

			entity:Destroy()
			connection:Disconnect()
			expect(fired).to.equal(true)
		end)

		it("Should get entity by id", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntity("TestEntity", nil, instance)
			local id = entity:GetId()
			
			local retrieved = Anima:GetEntityForId(id)
			expect(retrieved).to.equal(entity)
		end)

		it("Should get entity by instance", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntity("TestEntity", nil, instance)
			
			local retrieved = Anima:GetEntityForInstance(instance)
			expect(retrieved).to.equal(entity)
		end)

		it("Should not be retrievable after destruction", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntity("TestEntity", nil, instance)
			local id = entity:GetId()
			
			entity:Destroy()
			
			expect(Anima:GetEntityForId(id)).never.to.be.ok()
			expect(Anima:GetEntityForInstance(instance)).never.to.be.ok()
		end)

		it("Should create an empty entity with nil name", function()
			local entity = Anima:CreateEntity(nil)
			
			expect(entity).to.be.ok()
			expect(entity._Name).to.equal(nil)
			expect(entity._Destroyed).to.equal(false)
			expect(next(entity._Components)).to.equal(nil) -- No components
		end)

		it("Should create empty entity with instance", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntity(nil, nil, instance)
			
			expect(entity).to.be.ok()
			expect(entity._Name).to.equal(nil)
			expect(entity._Instance).to.equal(instance)
			expect(entity:GetId()).to.be.ok()
		end)

		it("Should allow adding components to empty entity", function()
			local entity = Anima:CreateEntity(nil)
			local component = Anima:CreateComponent("TestComponent")
			
			entity:AddComponent(component)
			
			expect(entity:GetComponent("TestComponent")).to.equal(component)
			expect(component:GetEntity()).to.equal(entity)
		end)

		it("Should retrieve empty entity by ID", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntity(nil, nil, instance)
			local id = entity:GetId()
			
			local retrieved = Anima:GetEntityForId(id)
			expect(retrieved).to.equal(entity)
		end)

		it("Should retrieve empty entity by instance", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntity(nil, nil, instance)
			
			local retrieved = Anima:GetEntityForInstance(instance)
			expect(retrieved).to.equal(entity)
		end)

		it("Should destroy empty entity correctly", function()
			local entity = Anima:CreateEntity(nil)
			local component = Anima:CreateComponent("TestComponent")
			entity:AddComponent(component)
			
			entity:Destroy()
			
			expect(entity._Destroyed).to.equal(true)
			expect(component._Destroyed).to.equal(true)
		end)
	end)
end
