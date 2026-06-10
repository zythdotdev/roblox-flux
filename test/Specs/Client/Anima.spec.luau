return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Anima = require(ReplicatedStorage.Packages.Anima)

	describe("Anima Framework (Client)", function()
		describe("Entity Lifecycle", function()
			-- Define a simple test entity once at startup
			Anima:_DefineEntity("ClientTestEntity", {
				OnInit = function(self, properties)
					return {}
				end,
			})

			it("Should create an entity", function()
				local entity = Anima:CreateEntity("ClientTestEntity")
				expect(entity).to.be.ok()
				expect(entity._Name).to.equal("ClientTestEntity")
				expect(entity._Destroyed).to.equal(false)
			end)

			it("Should create an entity with an instance", function()
				local instance = Instance.new("IntValue")
				local entity = Anima:CreateEntity("ClientTestEntity", nil, instance)

				expect(entity).to.be.ok()
				expect(entity._Instance).to.equal(instance)
			end)

			it("Should fire EntityCreated event", function()
				local fired = false
				local connection = Anima.EntityCreated:Connect(function(entity)
					fired = true
				end)

				Anima:CreateEntity("ClientTestEntity")
				connection:Disconnect()
				expect(fired).to.equal(true)
			end)

			it("Should destroy an entity", function()
				local entity = Anima:CreateEntity("ClientTestEntity")
				entity:Destroy()
				
				expect(entity._Destroyed).to.equal(true)
			end)

			it("Should fire EntityDestroyed event", function()
				local fired = false
				local entity = Anima:CreateEntity("ClientTestEntity")
				
				local connection = Anima.EntityDestroyed:Connect(function(e)
					fired = true
				end)

				entity:Destroy()
				connection:Disconnect()
				expect(fired).to.equal(true)
			end)

			it("Should get entity by id", function()
				local instance = Instance.new("IntValue")
				instance:SetAttribute("_AnimaId", 99999)
				local entity = Anima:CreateEntity("ClientTestEntity", nil, instance)
				local id = entity:GetId()
				
				local retrieved = Anima:GetEntityForId(id)
				expect(retrieved).to.equal(entity)
			end)

			it("Should get entity by instance", function()
				local instance = Instance.new("IntValue")
				instance:SetAttribute("_AnimaId", 88888)
				local entity = Anima:CreateEntity("ClientTestEntity", nil, instance)
				
				local retrieved = Anima:GetEntityForInstance(instance)
				expect(retrieved).to.equal(entity)
			end)

			it("Should not be retrievable after destruction", function()
				local instance = Instance.new("IntValue")
				instance:SetAttribute("_AnimaId", 77777)
				local entity = Anima:CreateEntity("ClientTestEntity", nil, instance)
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
				instance:SetAttribute("_AnimaId", 66666)
				local entity = Anima:CreateEntity(nil, nil, instance)
				
				expect(entity).to.be.ok()
				expect(entity._Name).to.equal(nil)
				expect(entity._Instance).to.equal(instance)
				expect(entity:GetId()).to.be.ok()
			end)

			it("Should allow adding components to empty entity", function()
				local entity = Anima:CreateEntity(nil)
				local component = Anima:CreateComponent("ClientTestComponent")
				
				entity:AddComponent(component)
				
				expect(entity:GetComponent("ClientTestComponent")).to.equal(component)
				expect(component:GetEntity()).to.equal(entity)
			end)

			it("Should retrieve empty entity by ID", function()
				local instance = Instance.new("IntValue")
				instance:SetAttribute("_AnimaId", 55554)
				local entity = Anima:CreateEntity(nil, nil, instance)
				local id = entity:GetId()
				
				local retrieved = Anima:GetEntityForId(id)
				expect(retrieved).to.equal(entity)
			end)

			it("Should retrieve empty entity by instance", function()
				local instance = Instance.new("IntValue")
				instance:SetAttribute("_AnimaId", 44443)
				local entity = Anima:CreateEntity(nil, nil, instance)
				
				local retrieved = Anima:GetEntityForInstance(instance)
				expect(retrieved).to.equal(entity)
			end)

			it("Should destroy empty entity correctly", function()
				local entity = Anima:CreateEntity(nil)
				local component = Anima:CreateComponent("ClientTestComponent")
				entity:AddComponent(component)
				
				entity:Destroy()
				
				expect(entity._Destroyed).to.equal(true)
				expect(component._Destroyed).to.equal(true)
			end)
		end)

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

		describe("Component Tracking", function()
			Anima:_DefineComponent("ClientTestComponent2", {
				OnInit = function(self, props)
					return {}
				end
			})

			Anima:_DefineEntity("ClientTestEntity3", {
				OnInit = function(self, properties)
					return {}
				end
			})

			it("Should track an item", function()
				local component = Anima:CreateComponent("ClientTestComponent2")
				local instance = Instance.new("Part")
				
				local tracked = component:Track(instance)
				expect(tracked).to.equal(instance)
			end)

			it("Should destroy tracked items when component is destroyed", function()
				local component = Anima:CreateComponent("ClientTestComponent2")
				local instance = Instance.new("Part")
				instance.Parent = workspace
				
				component:Track(instance)
				component:Destroy()
				
				expect(instance.Parent).never.to.be.ok()
			end)

			it("Should untrack an item", function()
				local component = Anima:CreateComponent("ClientTestComponent2")
				local instance = Instance.new("Part")
				
				component:Track(instance)
				local result = component:Untrack(instance)
				
				expect(result).to.equal(true)
			end)

			it("Should track with custom dispose method", function()
				local component = Anima:CreateComponent("ClientTestComponent2")
				local connection = workspace.ChildAdded:Connect(function() end)
				
				component:Track(connection, "Disconnect")
				component:Destroy()
				
				expect(connection.Connected).to.equal(false)
			end)
		end)

		describe("Update Loops (Client-specific)", function()
			Anima:_DefineEntity("ClientTestEntity4", {
				OnInit = function(self, properties)
					return {}
				end
			})

			Anima:_DefineComponent("RenderSteppedComponent", {
				OnInit = function(self, props)
					return { called = false }
				end,
				OnRenderStepped = function(self, deltaTime)
					self.called = true
				end
			})

			Anima:_DefineComponent("HeartbeatComponent", {
				OnInit = function(self, props)
					return { called = false }
				end,
				OnHeartbeat = function(self, deltaTime)
					self.called = true
				end
			})

			Anima:_DefineComponent("UpdateComponent", {
				OnInit = function(self, props)
					return { callCount = 0 }
				end,
				OnUpdate = function(self, deltaTime)
					self.callCount = self.callCount + 1
				end,
				UpdateInterval = 0.1
			})

			Anima:_DefineComponent("DestroyableComponent", {
				OnInit = function(self, props)
					return { callCount = 0 }
				end,
				OnRenderStepped = function(self, deltaTime)
					self.callCount = self.callCount + 1
				end
			})

			it("Should call OnRenderStepped on client", function()
				if not RunService:IsClient() then
					return
				end

				local entity = Anima:CreateEntity("ClientTestEntity4")
				local component = Anima:CreateComponent("RenderSteppedComponent")
				entity:AddComponent(component)

				-- Wait for two frames to ensure connection fires
				RunService.RenderStepped:Wait()
				RunService.RenderStepped:Wait()
				expect(component.called).to.equal(true)
			end)

			it("Should call OnHeartbeat", function()
				local entity = Anima:CreateEntity("ClientTestEntity4")
				local component = Anima:CreateComponent("HeartbeatComponent")
				entity:AddComponent(component)
				
				-- Wait for a heartbeat
				task.wait(0.1)
				expect(component.called).to.equal(true)
			end)

			it("Should call OnUpdate with custom interval", function()
				local entity = Anima:CreateEntity("ClientTestEntity4")
				local component = Anima:CreateComponent("UpdateComponent")
				entity:AddComponent(component)
				
				-- Wait for updates to occur
				task.wait(0.25)
				expect(component.callCount).to.be.near(2, 1)
			end)

			it("Should stop calling updates when component is destroyed", function()
				if not RunService:IsClient() then
					return
				end

				local entity = Anima:CreateEntity("ClientTestEntity4")
				local component = Anima:CreateComponent("DestroyableComponent")
				entity:AddComponent(component)
				
				RunService.RenderStepped:Wait()
				local countBeforeDestroy = component.callCount
				component:Destroy()
				RunService.RenderStepped:Wait()
				
				expect(component.callCount).to.equal(countBeforeDestroy)
			end)
		end)

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

				Anima:_DefineEntity("ClientTestEntity6", {
					OnInit = function(self, properties)
						return {}
					end
				})

				local entity = Anima:CreateEntity("ClientTestEntity6")
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

				Anima:_DefineEntity("ClientTestEntity7", {
					OnInit = function(self, properties)
						return {}
					end
				})

				local entity = Anima:CreateEntity("ClientTestEntity7")
				local component = Anima:CreateComponent("CallbackComponent2")
				entity:AddComponent(component)
				entity:RemoveComponent("CallbackComponent2")
				
				expect(removeCalled).to.equal(true)
			end)
		end)

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
	end)
end