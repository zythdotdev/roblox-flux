return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Entity with Components", function()
		Anima:_DefineComponent("ComponentA", {
			OnInit = function(self, props)
				return { name = "A" }
			end
		})

		Anima:_DefineComponent("ComponentB", {
			OnInit = function(self, props)
				return { name = "B" }
			end
		})

		Anima:_DefineEntity("TestEntity5", {
			OnInit = function(self, properties)
				return {}
			end
		})

		it("Should destroy all components when entity is destroyed", function()
			local entity = Anima:CreateEntity("TestEntity5")
			local compA = Anima:CreateComponent("ComponentA")
			local compB = Anima:CreateComponent("ComponentB")
			
			entity:AddComponent(compA)
			entity:AddComponent(compB)
			
			entity:Destroy()
			
			expect(compA._Destroyed).to.equal(true)
			expect(compB._Destroyed).to.equal(true)
		end)

		it("Should manage multiple components", function()
			local entity = Anima:CreateEntity("TestEntity5")
			local compA = Anima:CreateComponent("ComponentA")
			local compB = Anima:CreateComponent("ComponentB")
			
			entity:AddComponent(compA)
			entity:AddComponent(compB)
			
			expect(entity:GetComponent("ComponentA")).to.equal(compA)
			expect(entity:GetComponent("ComponentB")).to.equal(compB)
		end)
	end)
end
