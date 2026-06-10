return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Component Methods", function()
		it("Should call Remove to remove component from entity", function()
			Anima:_DefineComponent("RemovableComponent", {
				OnInit = function(self, props)
					return {}
				end
			})

			Anima:_DefineEntity("ClientTestEntity8", {
				OnInit = function(self, properties)
					return {}
				end
			})

			local entity = Anima:CreateEntity("ClientTestEntity8")
			local component = Anima:CreateComponent("RemovableComponent")
			entity:AddComponent(component)
			
			component:Remove()
			
			expect(entity:GetComponent("RemovableComponent")).never.to.be.ok()
			expect(component:GetEntity()).never.to.be.ok()
		end)
	end)
end
