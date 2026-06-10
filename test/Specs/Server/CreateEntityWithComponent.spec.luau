return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("CreateEntityWithComponent", function()
		Anima:_DefineComponent("SingleTestComponent", {
			OnInit = function(self, props)
				return { 
					TestValue = props.TestValue or "default",
					Count = props.Count or 0
				}
			end,
			OnAdd = function(self, entity)
				self.AddCalled = true
			end,
			OnDeinit = function(self)
				self.DeinitCalled = true
			end
		})

		it("Should create entity with a single component", function()
			local entity = Anima:CreateEntityWithComponent("SingleTestComponent")

			expect(entity).to.be.ok()
			expect(entity._Name).to.equal("SingleTestComponent")
			expect(entity._Destroyed).to.equal(false)

			local component = entity:GetComponent("SingleTestComponent")
			expect(component).to.be.ok()
			expect(component._Name).to.equal("SingleTestComponent")
		end)

		it("Should create entity with component properties", function()
			local entity = Anima:CreateEntityWithComponent("SingleTestComponent", {
				TestValue = "custom",
				Count = 42
			})

			local component = entity:GetComponent("SingleTestComponent")
			expect(component.TestValue).to.equal("custom")
			expect(component.Count).to.equal(42)
		end)

		it("Should create entity with instance", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntityWithComponent("SingleTestComponent", nil, instance)

			expect(entity._Instance).to.equal(instance)
			expect(entity._Id).to.be.ok()
			expect(instance:GetAttribute("_AnimaId")).to.equal(entity._Id)
		end)

		it("Should call component OnAdd lifecycle", function()
			local entity = Anima:CreateEntityWithComponent("SingleTestComponent")
			local component = entity:GetComponent("SingleTestComponent")

			expect(component.AddCalled).to.equal(true)
		end)

		it("Should fire EntityCreated event", function()
			local fired = false
			local connection = Anima.EntityCreated:Connect(function(entity)
				fired = true
			end)

			Anima:CreateEntityWithComponent("SingleTestComponent")
			connection:Disconnect()
			expect(fired).to.equal(true)
		end)

		it("Should fire ComponentAdded event", function()
			local fired = false
			local connection = Anima.ComponentAdded:Connect(function(entity, component)
				fired = true
			end)

			Anima:CreateEntityWithComponent("SingleTestComponent")
			connection:Disconnect()
			expect(fired).to.equal(true)
		end)

		it("Should allow adding more components after creation", function()
			Anima:_DefineComponent("AdditionalComponent", {
				OnInit = function(self, props)
					return { Extra = true }
				end
			})

			local entity = Anima:CreateEntityWithComponent("SingleTestComponent")
			local extraComponent = Anima:CreateComponent("AdditionalComponent")
			entity:AddComponent(extraComponent)

			expect(entity:GetComponent("SingleTestComponent")).to.be.ok()
			expect(entity:GetComponent("AdditionalComponent")).to.be.ok()
		end)

		it("Should properly destroy entity with component", function()
			local entity = Anima:CreateEntityWithComponent("SingleTestComponent")
			local component = entity:GetComponent("SingleTestComponent")

			entity:Destroy()

			expect(entity._Destroyed).to.equal(true)
			expect(component._Destroyed).to.equal(true)
			expect(component.DeinitCalled).to.equal(true)
		end)

		it("Should be retrievable by id", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntityWithComponent("SingleTestComponent", nil, instance)
			local id = entity:GetId()

			local retrieved = Anima:GetEntityForId(id)
			expect(retrieved).to.equal(entity)
		end)

		it("Should be retrievable by instance", function()
			local instance = Instance.new("IntValue")
			local entity = Anima:CreateEntityWithComponent("SingleTestComponent", nil, instance)

			local retrieved = Anima:GetEntityForInstance(instance)
			expect(retrieved).to.equal(entity)
		end)
	end)
end
