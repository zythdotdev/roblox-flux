return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Component Lifecycle Callbacks", function()
		it("Should call OnAdd when added to entity", function()
			local addCalled = false
			
			Anima:_DefineComponent("CallbackComponent", {
				OnInit = function(self, props)
					return {}
				end,
				OnAdd = function(self, entity)
					addCalled = true
				end
			})

			Anima:_DefineEntity("TestEntity6", {
				OnInit = function(self, properties)
					return {}
				end
			})

			local entity = Anima:CreateEntity("TestEntity6")
			local component = Anima:CreateComponent("CallbackComponent")
			entity:AddComponent(component)
			
			expect(addCalled).to.equal(true)
		end)

		it("Should call OnRemove when removed from entity", function()
			local removeCalled = false
			
			Anima:_DefineComponent("CallbackComponent2", {
				OnInit = function(self, props)
					return {}
				end,
				OnRemove = function(self, entity)
					removeCalled = true
				end
			})

			Anima:_DefineEntity("TestEntity7", {
				OnInit = function(self, properties)
					return {}
				end
			})

			local entity = Anima:CreateEntity("TestEntity7")
			local component = Anima:CreateComponent("CallbackComponent2")
			entity:AddComponent(component)
			entity:RemoveComponent("CallbackComponent2")
			
			expect(removeCalled).to.equal(true)
		end)
	end)
end
