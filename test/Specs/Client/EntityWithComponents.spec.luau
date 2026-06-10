return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Entity with Components", function()
		Anima:_DefineComponent("ClientComponentA", {
			OnInit = function(self, props)
				return { name = "A" }
			end
		})

		Anima:_DefineComponent("ClientComponentB", {
			OnInit = function(self, props)
				return { name = "B" }
			end
		})

		Anima:_DefineEntity("ClientTestEntity5", {
			OnInit = function(self, properties)
				return {}
			end
		})

		it("Should destroy all components when entity is destroyed", function()
			local entity = Anima:CreateEntity("ClientTestEntity5")
			local compA = Anima:CreateComponent("ClientComponentA")
			local compB = Anima:CreateComponent("ClientComponentB")
			
			entity:AddComponent(compA)
			entity:AddComponent(compB)
			
			entity:Destroy()
			
			expect(compA._Destroyed).to.equal(true)
			expect(compB._Destroyed).to.equal(true)
		end)

		it("Should manage multiple components", function()
			local entity = Anima:CreateEntity("ClientTestEntity5")
			local compA = Anima:CreateComponent("ClientComponentA")
			local compB = Anima:CreateComponent("ClientComponentB")
			
			entity:AddComponent(compA)
			entity:AddComponent(compB)
			
			expect(entity:GetComponent("ClientComponentA")).to.equal(compA)
			expect(entity:GetComponent("ClientComponentB")).to.equal(compB)
		end)
	end)
end
