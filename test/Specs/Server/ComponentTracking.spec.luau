return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Component Tracking", function()
		Anima:_DefineComponent("TestComponent2", {
			OnInit = function(self, props)
				return {}
			end
		})

		Anima:_DefineEntity("TestEntity3", {
			OnInit = function(self, properties)
				return {}
			end
		})

		it("Should track an item", function()
			local component = Anima:CreateComponent("TestComponent2")
			local instance = Instance.new("Part")
			
			local tracked = component:Track(instance)
			expect(tracked).to.equal(instance)
		end)

		it("Should destroy tracked items when component is destroyed", function()
			local component = Anima:CreateComponent("TestComponent2")
			local instance = Instance.new("Part")
			instance.Parent = workspace
			
			component:Track(instance)
			component:Destroy()
			
			expect(instance.Parent).never.to.be.ok()
		end)

		it("Should untrack an item", function()
			local component = Anima:CreateComponent("TestComponent2")
			local instance = Instance.new("Part")
			
			component:Track(instance)
			local result = component:Untrack(instance)
			
			expect(result).to.equal(true)
		end)

		it("Should track with custom dispose method", function()
			local component = Anima:CreateComponent("TestComponent2")
			local connection = workspace.ChildAdded:Connect(function() end)
			
			component:Track(connection, "Disconnect")
			component:Destroy()
			
			expect(connection.Connected).to.equal(false)
		end)
	end)
end
