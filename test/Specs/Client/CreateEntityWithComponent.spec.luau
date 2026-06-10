return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("CreateEntityWithComponent", function()
		Anima:_DefineComponent("ClientSingleTestComponent", {
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
			local entity = Anima:CreateEntityWithComponent("ClientSingleTestComponent")

			expect(entity).to.be.ok()
			expect(entity._Name).to.equal("ClientSingleTestComponent")
			expect(entity._Destroyed).to.equal(false)

			local component = entity:GetComponent("ClientSingleTestComponent")
			expect(component).to.be.ok()
			expect(component._Name).to.equal("ClientSingleTestComponent")
		end)

		it("Should create entity with component properties", function()
			local entity = Anima:CreateEntityWithComponent("ClientSingleTestComponent", {
				TestValue = "custom",
				Count = 42
			})

			local component = entity:GetComponent("ClientSingleTestComponent")
			expect(component.TestValue).to.equal("custom")
			expect(component.Count).to.equal(42)
		end)

		it("Should create entity with instance", function()
			local instance = Instance.new("IntValue")
			instance:SetAttribute("_AnimaId", 55555)
			local entity = Anima:CreateEntityWithComponent("ClientSingleTestComponent", nil, instance)

			expect(entity._Instance).to.equal(instance)
			expect(entity._Id).to.be.ok()
		end)

		it("Should call component OnAdd lifecycle", function()
			local entity = Anima:CreateEntityWithComponent("ClientSingleTestComponent")
			local component = entity:GetComponent("ClientSingleTestComponent")

			expect(component.AddCalled).to.equal(true)
		end)

		it("Should fire EntityCreated event", function()
			local fired = false
			local connection = Anima.EntityCreated:Connect(function(entity)
				fired = true
			end)

			Anima:CreateEntityWithComponent("ClientSingleTestComponent")
			connection:Disconnect()
			expect(fired).to.equal(true)
		end)

		it("Should fire ComponentAdded event", function()
			local fired = false
			local connection = Anima.ComponentAdded:Connect(function(entity, component)
				fired = true
			end)

			Anima:CreateEntityWithComponent("ClientSingleTestComponent")
			connection:Disconnect()
			expect(fired).to.equal(true)
		end)

		it("Should allow adding more components after creation", function()
			Anima:_DefineComponent("ClientAdditionalComponent", {
				OnInit = function(self, props)
					return { Extra = true }
				end
			})

			local entity = Anima:CreateEntityWithComponent("ClientSingleTestComponent")
			local extraComponent = Anima:CreateComponent("ClientAdditionalComponent")
			entity:AddComponent(extraComponent)

			expect(entity:GetComponent("ClientSingleTestComponent")).to.be.ok()
			expect(entity:GetComponent("ClientAdditionalComponent")).to.be.ok()
		end)

		it("Should properly destroy entity with component", function()
			local entity = Anima:CreateEntityWithComponent("ClientSingleTestComponent")
			local component = entity:GetComponent("ClientSingleTestComponent")

			entity:Destroy()

			expect(entity._Destroyed).to.equal(true)
			expect(component._Destroyed).to.equal(true)
			expect(component.DeinitCalled).to.equal(true)
		end)

		it("Should be retrievable by id", function()
			local instance = Instance.new("IntValue")
			instance:SetAttribute("_AnimaId", 44444)
			local entity = Anima:CreateEntityWithComponent("ClientSingleTestComponent", nil, instance)
			local id = entity:GetId()

			local retrieved = Anima:GetEntityForId(id)
			expect(retrieved).to.equal(entity)
		end)

		it("Should be retrievable by instance", function()
			local instance = Instance.new("IntValue")
			instance:SetAttribute("_AnimaId", 33333)
			local entity = Anima:CreateEntityWithComponent("ClientSingleTestComponent", nil, instance)

			local retrieved = Anima:GetEntityForInstance(instance)
			expect(retrieved).to.equal(entity)
		end)
	end)
end
