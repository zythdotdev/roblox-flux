return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Flux = require(ReplicatedStorage.Packages.Flux)

	describe("Controller", function()
		local function makeScreenGui(): ScreenGui
			local gui = Instance.new("ScreenGui")
			return gui
		end

		describe("Creation", function()
			it("should create a controller from MountScreenGui", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				expect(controller).to.be.ok()
				controller:Unmount()
			end)

			it("should parent ScreenGui to PlayerGui", function()
				local gui = makeScreenGui()
				local Players = game:GetService("Players")
				local controller = Flux:MountScreenGui(gui)
				expect(gui.Parent).to.equal(Players.LocalPlayer.PlayerGui)
				controller:Unmount()
			end)

			it("should create a controller from MountSurfaceGui", function()
				local gui = Instance.new("SurfaceGui")
				local part = Instance.new("Part")
				local controller = Flux:MountSurfaceGui(gui, part)
				expect(controller).to.be.ok()
				expect(gui.Adornee).to.equal(part)
				controller:Unmount()
				part:Destroy()
			end)

			it("should set face on SurfaceGui when provided", function()
				local gui = Instance.new("SurfaceGui")
				local part = Instance.new("Part")
				local controller = Flux:MountSurfaceGui(gui, part, Enum.NormalId.Top)
				expect(gui.Face).to.equal(Enum.NormalId.Top)
				controller:Unmount()
				part:Destroy()
			end)

			it("should create a controller from MountBillboardGui", function()
				local gui = Instance.new("BillboardGui")
				local part = Instance.new("Part")
				local controller = Flux:MountBillboardGui(gui, part)
				expect(controller).to.be.ok()
				expect(gui.Adornee).to.equal(part)
				controller:Unmount()
				part:Destroy()
			end)

			it("should validate mount arguments", function()
				expect(function()
					Flux:MountScreenGui(Instance.new("Frame") :: any)
				end).to.throw()

				expect(function()
					Flux:MountSurfaceGui(Instance.new("SurfaceGui"), Instance.new("Folder") :: any)
				end).to.throw()

				expect(function()
					Flux:MountBillboardGui(Instance.new("BillboardGui"), Instance.new("Folder") :: any)
				end).to.throw()
			end)
		end)

		describe("GetInstance", function()
			it("should return the mounted GUI instance", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				expect(controller:GetInstance()).to.equal(gui)
				controller:Unmount()
			end)
		end)

		describe("Unmount", function()
			it("should destroy the GUI instance", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				controller:Unmount()
				expect(gui.Parent).to.equal(nil)
			end)

			it("should be safe to call Unmount multiple times", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				controller:Unmount()
				expect(function()
					controller:Unmount()
				end).never.to.throw()
			end)
		end)

		describe("Destroy", function()
			it("should be an alias of Unmount", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				controller:Destroy()
				expect(gui.Parent).to.equal(nil)
			end)

			it("should be safe to call Destroy multiple times", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				controller:Destroy()
				expect(function()
					controller:Destroy()
				end).never.to.throw()
			end)

			it("should be safe to mix Destroy and Unmount", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				controller:Destroy()
				expect(function()
					controller:Unmount()
				end).never.to.throw()
			end)
		end)

		describe("BindProperty", function()
			it("should set the property immediately with the current state value", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local label = Instance.new("TextLabel")
				label.Text = ""
				label.Parent = gui

				local textState = Flux:State("hello")
				controller:BindProperty(textState, label, "Text")

				expect(label.Text).to.equal("hello")
				controller:Unmount()
			end)

			it("should update the property when state changes", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local label = Instance.new("TextLabel")
				label.Text = ""
				label.Parent = gui

				local textState = Flux:State("initial")
				controller:BindProperty(textState, label, "Text")

				textState:Set("updated")
				expect(label.Text).to.equal("updated")
				controller:Unmount()
			end)

			it("should disconnect property binding on Unmount", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local label = Instance.new("TextLabel")
				label.Text = "initial"
				label.Parent = gui

				local textState = Flux:State("initial")
				controller:BindProperty(textState, label, "Text")

				controller:Unmount()
				textState:Set("after unmount")
				expect(label.Text).to.equal("initial")
			end)
		end)

		describe("Bind", function()
			it("should fire callback immediately with current state value", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				local state = Flux:State(42)
				local received = nil

				controller:Bind(state, function(value)
					received = value
				end)

				expect(received).to.equal(42)
				controller:Unmount()
			end)

			it("should fire callback when state changes", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				local state = Flux:State(0)
				local received = nil

				controller:Bind(state, function(value)
					received = value
				end)

				state:Set(100)
				expect(received).to.equal(100)
				controller:Unmount()
			end)

			it("should disconnect bindings on Unmount", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				local state = Flux:State(0)
				local callCount = 0

				controller:Bind(state, function(_value)
					callCount = callCount + 1
				end)

				expect(callCount).to.equal(1) -- initial
				controller:Unmount()

				state:Set(10)
				expect(callCount).to.equal(1) -- should not have fired again
			end)

			it("should support multiple bindings", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)
				local stateA = Flux:State("a")
				local stateB = Flux:State("b")
				local receivedA = nil
				local receivedB = nil

				controller:Bind(stateA, function(value)
					receivedA = value
				end)

				controller:Bind(stateB, function(value)
					receivedB = value
				end)

				stateA:Set("x")
				stateB:Set("y")
				expect(receivedA).to.equal("x")
				expect(receivedB).to.equal("y")
				controller:Unmount()
			end)

			it("should validate bind arguments", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				expect(function()
					controller:Bind(nil :: any, function() end)
				end).to.throw()

				expect(function()
					controller:Bind(Flux:State(0), nil :: any)
				end).to.throw()

				controller:Unmount()
			end)
		end)

		describe("MountWhen", function()
			it("should conditionally mount and unmount a component from boolean state", function()
				local gui = makeScreenGui()
				local controller = Flux:MountScreenGui(gui)

				local frame = Instance.new("Frame")
				frame.Parent = gui

				local condition = Flux:State(false)
				local source = Flux:State(0)
				local callCount = 0

				local function TestComponent(_instance: Instance, scope: Flux.Scope)
					scope:Bind(source, function(_value)
						callCount = callCount + 1
					end)
				end

				controller:MountWhen(condition, TestComponent, frame)
				expect(callCount).to.equal(0)

				condition:Set(true)
				expect(callCount).to.equal(1)

				source:Set(1)
				expect(callCount).to.equal(2)

				condition:Set(false)
				source:Set(2)
				expect(callCount).to.equal(2)

				condition:Set(true)
				expect(callCount).to.equal(3)

				controller:Unmount()
			end)
		end)
	end)
end
