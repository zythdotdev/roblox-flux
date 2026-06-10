return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Anima Framework", function()
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
		end)

		describe("Component Lifecycle", function()
			-- Define component and entity once at startup
			Anima:_DefineComponent("TestComponent", {
				OnInit = function(self, props)
					return { Value = props.Value or 100 }
					end,
				OnDeinit = function(self)
					-- cleanup
				end
			})

			Anima:_DefineEntity("TestEntity2", {
				OnInit = function(self, properties)
					return {}
				end
			})

			it("Should create a component", function()
				local component = Anima:CreateComponent("TestComponent")
				expect(component).to.be.ok()
				expect(component._Name).to.equal("TestComponent")
				expect(component._Destroyed).to.equal(false)
			end)

			it("Should create a component with properties", function()
				local component = Anima:CreateComponent("TestComponent", { Value = 42 })
				expect(component.Value).to.equal(42)
			end)

			it("Should add component to entity", function()
				local entity = Anima:CreateEntity("TestEntity2")
				local component = Anima:CreateComponent("TestComponent")
				
				entity:AddComponent(component)
				expect(entity:GetComponent("TestComponent")).to.equal(component)
				expect(component:GetEntity()).to.equal(entity)
			end)

			it("Should fire ComponentAdded event", function()
				local fired = false
				local connection = Anima.ComponentAdded:Connect(function(entity, component)
					fired = true
				end)

				local entity = Anima:CreateEntity("TestEntity2")
				local component = Anima:CreateComponent("TestComponent")
				entity:AddComponent(component)
				
				connection:Disconnect()
				expect(fired).to.equal(true)
			end)

			it("Should remove component from entity", function()
				local entity = Anima:CreateEntity("TestEntity2")
				local component = Anima:CreateComponent("TestComponent")
				entity:AddComponent(component)
				
				local removed = entity:RemoveComponent("TestComponent")
				expect(removed).to.equal(component)
				expect(entity:GetComponent("TestComponent")).never.to.be.ok()
			end)

			it("Should fire ComponentRemoved event", function()
				local fired = false
				local entity = Anima:CreateEntity("TestEntity2")
				local component = Anima:CreateComponent("TestComponent")
				entity:AddComponent(component)
				
				local connection = Anima.ComponentRemoved:Connect(function(e, c)
					fired = true
				end)

				entity:RemoveComponent("TestComponent")
				connection:Disconnect()
				expect(fired).to.equal(true)
			end)

			it("Should destroy component", function()
				local component = Anima:CreateComponent("TestComponent")
				component:Destroy()
				
				expect(component._Destroyed).to.equal(true)
			end)

			it("Should remove component from entity when destroyed", function()
				local entity = Anima:CreateEntity("TestEntity2")
				local component = Anima:CreateComponent("TestComponent")
				entity:AddComponent(component)
				
				component:Destroy()
				expect(entity:GetComponent("TestComponent")).never.to.be.ok()
			end)
		end)

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

		describe("Update Loops", function()
			Anima:_DefineEntity("TestEntity4", {
				OnInit = function(self, properties)
					return {}
					end
			})

			it("Should call OnHeartbeat", function()
				local called = false
				
				Anima:_DefineComponent("HeartbeatComponent", {
					OnInit = function(self, props)
						return {}
					end,
					OnHeartbeat = function(self, deltaTime)
						called = true
					end
				})

				local entity = Anima:CreateEntity("TestEntity4")
				local component = Anima:CreateComponent("HeartbeatComponent")
				entity:AddComponent(component)
				
				-- Wait for a heartbeat
				task.wait(0.1)
				expect(called).to.equal(true)
			end)

			it("Should call OnStepped", function()
				local called = false
				
				Anima:_DefineComponent("SteppedComponent", {
					OnInit = function(self, props)
						return {}
					end,
					OnStepped = function(self, time, deltaTime)
						called = true
					end
				})

				local entity = Anima:CreateEntity("TestEntity4")
				local component = Anima:CreateComponent("SteppedComponent")
				entity:AddComponent(component)
				
				-- Wait for a step
				task.wait()
				expect(called).to.equal(true)
			end)

			it("Should call OnUpdate with custom interval", function()
				local callCount = 0
				
				Anima:_DefineComponent("UpdateComponent", {
					OnInit = function(self, props)
						return {}
					end,
					OnUpdate = function(self, deltaTime)
						callCount += 1
					end,
					UpdateInterval = 0.1
				})

				local entity = Anima:CreateEntity("TestEntity4")
				local component = Anima:CreateComponent("UpdateComponent")
				entity:AddComponent(component)
				
				-- Wait for updates to occur
				task.wait(1)
				expect(callCount).to.never.to.equal(0)
			end)

			it("Should stop calling updates when component is destroyed", function()
				local callCount = 0
				
				Anima:_DefineComponent("DestroyableComponent", {
					OnInit = function(self, props)
						return {}
					end,
					OnHeartbeat = function(self, deltaTime)
						callCount = callCount + 1
					end
				})

				local entity = Anima:CreateEntity("TestEntity4")
				local component = Anima:CreateComponent("DestroyableComponent")
				entity:AddComponent(component)
				
				task.wait(0.1)
				local countBeforeDestroy = callCount
				component:Destroy()
				task.wait(0.1)
				
				expect(callCount).to.equal(countBeforeDestroy)
			end)
		end)

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
	end)
end