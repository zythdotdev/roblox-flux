return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Flux = require(ReplicatedStorage.Packages.Flux)

	describe("Component", function()
		local function makeScreenGui(): ScreenGui
			local gui = Instance.new("ScreenGui")
			return gui
		end

		describe("Mount", function()
			it("should invoke the component function with the instance", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui

				local receivedInstance = nil
				local function TestComponent(instance: Instance, _scope: Flux.Scope)
					receivedInstance = instance
				end

				controller:Mount(TestComponent, frame)
				expect(receivedInstance).to.equal(frame)
				controller:Unmount()
			end)

			it("should pass props to the component", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui

				local receivedProps = nil
				local function TestComponent(_instance: Instance, _scope: Flux.Scope, props: {[string]: any}?)
					receivedProps = props
				end

				local props = { color = "red", size = 10 }
				controller:Mount(TestComponent, frame, props)
				expect(receivedProps).to.be.ok()
				expect(receivedProps.color).to.equal("red")
				expect(receivedProps.size).to.equal(10)
				controller:Unmount()
			end)

			it("should pass nil props when not provided", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui

				local propsCalled = false
				local receivedProps = "sentinel"
				local function TestComponent(_instance: Instance, _scope: Flux.Scope, props: {[string]: any}?)
					propsCalled = true
					receivedProps = props
				end

				controller:Mount(TestComponent, frame)
				expect(propsCalled).to.equal(true)
				expect(receivedProps).to.equal(nil)
				controller:Unmount()
			end)
		end)

		describe("Scope:Bind", function()
			it("should bind state within a component scope", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui

				local state = Flux:State(0)
				local received = nil

				local function TestComponent(_instance: Instance, scope: Flux.Scope)
					scope:Bind(state, function(value)
						received = value
					end)
				end

				controller:Mount(TestComponent, frame)
				expect(received).to.equal(0)

				state:Set(50)
				expect(received).to.equal(50)
				controller:Unmount()
			end)

			it("should clean up scope bindings on Unmount", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui

				local state = Flux:State(0)
				local callCount = 0

				local function TestComponent(_instance: Instance, scope: Flux.Scope)
					scope:Bind(state, function(_value)
						callCount = callCount + 1
					end)
				end

				controller:Mount(TestComponent, frame)
				expect(callCount).to.equal(1) -- initial

				controller:Unmount()
				state:Set(10)
				expect(callCount).to.equal(1) -- should not fire after unmount
			end)
		end)

		describe("Scope:Mount (nested components)", function()
			it("should mount a child component via scope", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui
				local label = Instance.new("TextLabel")
				label.Parent = frame

				local childMounted = false
				local function ChildComponent(instance: Instance, _scope: Flux.Scope)
					childMounted = true
					expect(instance).to.equal(label)
				end

				local function ParentComponent(instance: Instance, scope: Flux.Scope)
					local childInstance = instance:FindFirstChild("TextLabel")
					scope:Mount(ChildComponent, childInstance)
				end

				controller:Mount(ParentComponent, frame)
				expect(childMounted).to.equal(true)
				controller:Unmount()
			end)

			it("should clean up child component bindings on Unmount", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui
				local label = Instance.new("TextLabel")
				label.Parent = frame

				local state = Flux:State("initial")
				local childCallCount = 0

				local function ChildComponent(_instance: Instance, scope: Flux.Scope)
					scope:Bind(state, function(_value)
						childCallCount = childCallCount + 1
					end)
				end

				local function ParentComponent(instance: Instance, scope: Flux.Scope)
					local childInstance = instance:FindFirstChild("TextLabel")
					scope:Mount(ChildComponent, childInstance)
				end

				controller:Mount(ParentComponent, frame)
				expect(childCallCount).to.equal(1) -- initial bind

				state:Set("updated")
				expect(childCallCount).to.equal(2)

				controller:Unmount()
				state:Set("after unmount")
				expect(childCallCount).to.equal(2) -- should not fire
			end)

			it("should pass props to child components", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui
				local label = Instance.new("TextLabel")
				label.Parent = frame

				local receivedChildProps = nil
				local function ChildComponent(_instance: Instance, _scope: Flux.Scope, props: {[string]: any}?)
					receivedChildProps = props
				end

				local function ParentComponent(instance: Instance, scope: Flux.Scope)
					local childInstance = instance:FindFirstChild("TextLabel")
					scope:Mount(ChildComponent, childInstance, { text = "hello" })
				end

				controller:Mount(ParentComponent, frame)
				expect(receivedChildProps).to.be.ok()
				expect(receivedChildProps.text).to.equal("hello")
				controller:Unmount()
			end)
		end)

		describe("Real-world patterns", function()
			it("should update UI text via state binding in a component", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local label = Instance.new("TextLabel")
				label.Text = ""
				label.Parent = gui

				local textState = Flux:State("Hello")

				local function LabelComponent(instance: Instance, scope: Flux.Scope)
					scope:Bind(textState, function(value)
						(instance :: TextLabel).Text = tostring(value or "")
					end)
				end

				controller:Mount(LabelComponent, label)
				expect(label.Text).to.equal("Hello")

				textState:Set("World")
				expect(label.Text).to.equal("World")
				controller:Unmount()
			end)

			it("should update UI size via state binding in a component", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local bar = Instance.new("Frame")
				bar.Parent = gui

				local healthState = Flux:State(100)

				local function HealthBar(instance: Instance, scope: Flux.Scope)
					scope:Bind(healthState, function(hp)
						(instance :: Frame).Size = UDim2.fromScale((hp or 0) / 100, 1)
					end)
				end

				controller:Mount(HealthBar, bar)
				expect(bar.Size).to.equal(UDim2.fromScale(1, 1))

				healthState:Set(50)
				expect(bar.Size).to.equal(UDim2.fromScale(0.5, 1))

				healthState:Set(0)
				expect(bar.Size).to.equal(UDim2.fromScale(0, 1))
				controller:Unmount()
			end)
		end)
	end)
end
