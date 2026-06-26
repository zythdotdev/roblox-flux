local Bag = require(script.Parent.Parent.Bag)
local State = require(script.Parent.State)

--[=[
	@within Controller
	@interface Scope
	@field Bind (self, state: State<T>, callback: (newValue: T?) -> ()) -> () -- Binds to a `State` scoped to this component's lifecycle
	@field BindProperty (self, state: State<T>, instance: Instance, property: string) -> () -- Binds a `State` directly to a named property on an instance
	@field BindEvent (self, instance: Instance, eventName: string, callback: (...any) -> ()) -> () -- Connects an instance event scoped to this component's lifecycle
	@field Mount (self, component: Component, instance: Instance, properties: {[string]: any}?) -> () -- Mounts a child component scoped to this component's lifecycle
	@field MountWhen (self, condition: State<boolean>, component: Component, instance: Instance, properties: {[string]: any}?) -> () -- Conditionally mounts a child component based on state

	A lifecycle scope passed to each component function. Use `Bind` to subscribe to reactive state,
	`BindProperty` to drive a named instance property directly from state, `BindEvent` to connect instance
	events, `Mount` to compose child components, and `MountWhen` for conditional rendering.
	All bindings, event connections, and child mounts made through this scope are automatically cleaned
	up when the parent GUI is unmounted.
]=]
export type Scope = {
	Mount: (self: Scope, component: Component, instance: Instance, properties: {[string]: any}?) -> (),
	MountWhen: (self: Scope, condition: State<boolean>, component: Component, instance: Instance, properties: {[string]: any}?) -> (),
	Bind: <T>(self: Scope, state: State<T>, callback: (newValue: T?) -> ()) -> (),
	BindProperty: <T>(self: Scope, state: State<T>, instance: Instance, property: string) -> (),
	BindEvent: (self: Scope, instance: Instance, eventName: string, callback: (...any) -> ()) -> (),
}

--[=[
	@within Controller
	@type Component (instance: Instance, scope: Scope, properties: {[string]: any}?) -> ()

	A reusable function that applies behavior to a GUI child `Instance`. Components are mounted to a specific
	`Instance` in the GUI hierarchy and can bind to reactive state using the provided `Scope`. Components
	should be used for reusable pieces of UI behavior. For example, you might have a "HealthBar" component that
	you mount to any Frame to turn it into a health bar, or a "Draggable" component that makes a GUI element
	draggable. Components should not manage the lifecycle of their own `Instance` (i.e. by destroying it or
	reparenting it), they should only be responsible for updating the instance's properties in response to state changes,
	passed down through `properties` or observed via `Bind`. Let the parent `Controller` manage the lifecycle of all instances.
]=]
export type Component = (instance: Instance, scope: Scope, properties: {[string]: any}?) -> ()

--[=[
	@within Controller
	@interface State

	A reactive state object. Create these using `Flux:State` and pass them to
	`Controller:Bind` or `Scope:Bind` inside components to reactively drive UI updates.
]=]
export type State<T> = State.Self<T>

type Controller = {
	_Instance: ScreenGui | SurfaceGui | BillboardGui,
	_Bag: Bag.Self,
	_Scope: Scope,

	Destroy: (self: Self) -> (),
	Unmount: (self: Self) -> (),
	Mount: (self: Self, component: Component, instance: Instance, properties: {[string]: any}?) -> (),
	MountWhen: (self: Self, condition: State<boolean>, component: Component, instance: Instance, properties: {[string]: any}?) -> (),
	Bind: <T>(self: Self, state: State<T>, callback: (newValue: T?) -> ()) -> (),
	BindProperty: <T>(self: Self, state: State<T>, instance: Instance, property: string) -> (),
	BindEvent: (self: Self, instance: Instance, eventName: string, callback: (...any) -> ()) -> (),
	GetInstance: (self: Self) -> ScreenGui | SurfaceGui | BillboardGui,
}

--[=[
	@within Controller
	@type Self Controller
]=]
export type Self = Controller

--[=[
	@class Controller

	Controller for a mounted GUI. Returned by every `Mount` method call. A `Controller` manages the lifecycle of
	the GUI `Instance` and all reactive connections. Call `Unmount` to clean up, `Bind` to react to state changes,
	and `Mount` to apply reusable components that are automatically cleaned up when the controller is unmounted.
	`Destroy` is provided as an alias of `Unmount` for compatibility with APIs that expect `:Destroy()`.
	Access the GUI hierarchy via `GetInstance()`.
]=]
local Controller = {}
Controller.__index = Controller

local function createScope(parentBag: Bag.Self): Scope
	local scope = {}

	function scope:Bind<U>(state: State<U>, callback: (newValue: U?) -> ())
		assert(state ~= nil and type(state.Observe) == "function", "[Flux] Bind: state must be a State")
		assert(type(callback) == "function", "[Flux] Bind: callback must be a function")

		local connection = state:Observe(callback)
		parentBag:Add(connection)
	end

	function scope:BindProperty<U>(state: State<U>, instance: Instance, property: string)
		assert(state ~= nil and type(state.Observe) == "function", "[Flux] BindProperty: state must be a State")
		assert(typeof(instance) == "Instance", "[Flux] BindProperty: instance must be an Instance")
		assert(type(property) == "string" and #property > 0, "[Flux] BindProperty: property must be a non-empty string")

		scope:Bind(state, function(value: U?)
			instance[property] = value
		end)
	end

	function scope:BindEvent(instance: Instance, eventName: string, callback: (...any) -> ())
		assert(type(eventName) == "string" and #eventName > 0, "[Flux] BindEvent: eventName must be a non-empty string")
		assert(type(callback) == "function", "[Flux] BindEvent: callback must be a function")

		local signal = instance[eventName]
		assert(typeof(signal) == "RBXScriptSignal", string.format("[Flux] BindEvent: '%s' is not a valid event on %s", eventName, instance.ClassName))

		local connection = signal:Connect(callback)
		parentBag:Add(connection)
	end

	function scope:Mount(component: Component, instance: Instance, properties: {[string]: any}?)
		assert(type(component) == "function", "[Flux] Mount: component must be a function")
		assert(typeof(instance) == "Instance", "[Flux] Mount: instance must be an Instance")
		assert(properties == nil or typeof(properties) == "table", "[Flux] Mount: properties must be a table or nil")

		local childBag = Bag.new()
		parentBag:Add(childBag)
		component(instance, createScope(childBag), properties)
	end

	function scope:MountWhen(condition: State<boolean>, component: Component, instance: Instance, properties: {[string]: any}?)
		assert(condition ~= nil and type(condition.Observe) == "function", "[Flux] MountWhen: condition must be a State<boolean>")
		assert(type(component) == "function", "[Flux] MountWhen: component must be a function")
		assert(typeof(instance) == "Instance", "[Flux] MountWhen: instance must be an Instance")
		assert(properties == nil or typeof(properties) == "table", "[Flux] MountWhen: properties must be a table or nil")

		local mounted = false
		local mountedBag: Bag.Self? = nil

		scope:Bind(condition, function(shouldMount: boolean)
			if shouldMount and not mounted then
				mountedBag = Bag.new()
				parentBag:Add(mountedBag)
				component(instance, createScope(mountedBag), properties)
				mounted = true
			elseif not shouldMount and mounted then
				if mountedBag then
					parentBag:Remove(mountedBag)
				end
				mounted = false
				mountedBag = nil
			end
		end)
	end

	return scope :: any
end

--[=[
	@param gui ScreenGui | SurfaceGui | BillboardGui -- The GUI instance to manage
	@return Controller -- A new Controller for the given GUI instance

	Creates a new Controller for the given GUI instance.
]=]
function Controller.new(gui: ScreenGui | SurfaceGui | BillboardGui): Controller
	assert(typeof(gui) == "Instance", "[Flux] Controller.new: gui must be an Instance")
	assert(gui:IsA("ScreenGui") or gui:IsA("SurfaceGui") or gui:IsA("BillboardGui"), "[Flux] Controller.new: gui must be a ScreenGui, SurfaceGui, or BillboardGui")

	local bag = Bag.new()
	bag:Add(gui)

	local controller = setmetatable({
		_Instance = gui,
		_Bag = bag,
	}, Controller) :: any

	controller._Scope = createScope(bag)
	return controller
end

--[=[
	Destroys the GUI `Instance` and disconnects all bindings. This should be called when you
	are finished with the GUI to properly clean up resources and prevent memory leaks.

	```lua
	local controller = Flux:MountScreenGui(gui)
	controller:Unmount() -- Clean up when done
	```
]=]
function Controller.Unmount(self: Self)
	if self._Bag._Destroyed then return end
	self._Bag:Destroy()
end

--[=[
	Compatibility alias for `Unmount`. Calling `Destroy` and `Unmount` has identical behavior.
]=]
function Controller.Destroy(self: Self)
	self:Unmount()
end

--[=[
	@return ScreenGui | SurfaceGui | BillboardGui -- The managed GUI instance

	Returns the GUI instance managed by this controller.

	```lua
	local gui = controller:GetInstance()
	local frame = gui:FindFirstChild("Frame")
	```
]=]
function Controller.GetInstance(self: Self): ScreenGui | SurfaceGui | BillboardGui
	return self._Instance
end

--[=[
	@param state State<T> -- The reactive state to observe
	@param callback (newValue: T?) -> () -- Function to call with the current and future values

	Binds to a `State` object so that `callback` fires immediately with the current value,
	and then again every time the state changes. The binding is automatically cleaned up when
	the controller is unmounted.

	```lua
	local coins: Flux.State<number> = Flux:State(0)
	controller:Bind(coins, function(count: number)
		local label = controller:GetInstance():FindFirstChild("CoinsLabel")
		if label and label:IsA("TextLabel") then
			label.Text = tostring(count)
		end
	end)
	```
]=]
function Controller.Bind<T>(self: Self, state: State<T>, callback: (newValue: T?) -> ())
	if self._Bag._Destroyed then return end

	assert(state ~= nil and type(state.Observe) == "function", "[Flux] Bind: state must be a State")
	assert(type(callback) == "function", "[Flux] Bind: callback must be a function")

	self._Scope:Bind(state, callback)
end

--[=[
	@param state State<T> -- The reactive state to observe
	@param instance Instance -- The GUI instance to update
	@param property string -- The name of the property to bind to

	Binds a `State` directly to a named property on an instance. The property is updated immediately
	with the current state value and then again every time the state changes.

	```lua
	local size = Flux:State(UDim2.fromScale(0.5, 0.5))
	controller:BindProperty(size, frame, "Size")
	size:Set(UDim2.fromScale(1, 1)) -- frame.Size updates automatically
	```
]=]
function Controller.BindProperty<T>(self: Self, state: State<T>, instance: Instance, property: string)
	if self._Bag._Destroyed then return end

	assert(state ~= nil and type(state.Observe) == "function", "[Flux] BindProperty: state must be a State")
	assert(typeof(instance) == "Instance", "[Flux] BindProperty: instance must be an Instance")
	assert(type(property) == "string" and #property > 0, "[Flux] BindProperty: property must be a non-empty string")

	self._Scope:BindProperty(state, instance, property)
end

--[=[
	@param instance Instance -- The GUI instance whose event to connect to
	@param eventName string -- The name of the event (e.g. "Activated", "MouseEnter")
	@param callback (...any) -> () -- Function to call when the event fires

	Connects to a named event on an instance with automatic cleanup. The connection is automatically
	disconnected when the controller is unmounted.

	```lua
	local button = controller:GetInstance():FindFirstChild("Button")
	if button then
		controller:BindEvent(button, "Activated", function()
			print("Button clicked!")
		end)
	end
	```
]=]
function Controller.BindEvent(self: Self, instance: Instance, eventName: string, callback: (...any) -> ())
	if self._Bag._Destroyed then return end

	assert(typeof(instance) == "Instance", "[Flux] BindEvent: instance must be an Instance")
	assert(type(eventName) == "string" and #eventName > 0, "[Flux] BindEvent: eventName must be a non-empty string")
	assert(type(callback) == "function", "[Flux] BindEvent: callback must be a function")

	self._Scope:BindEvent(instance, eventName, callback)
end

--[=[
	Applies a reusable `Component` function to a child instance. The component receives a `Scope`
	that allows it to bind to reactive state. All bindings made by the component are automatically
	cleaned up when the controller is unmounted.

	@param component Component -- The component function to apply
	@param instance Instance -- The GUI instance to pass to the component
	@param properties {[string]: any}? -- Optional properties table to pass to the component

	```lua
	local function HealthBar(instance: Instance, scope: Flux.Scope, properties: {health: Flux.State<number>})
		scope:Bind(properties.health, function(hp: number)
			local bar: Frame = instance :: Frame
			bar.Size = UDim2.fromScale(hp / 100, 1)
		end)
	end

	local healthState = Flux:State(100)
	local healthBarFrame = controller:GetInstance():FindFirstChild("HealthBarFrame")
	if healthBarFrame then
		controller:Mount(HealthBar, healthBarFrame, {health = healthState})
	end
	```
]=]
function Controller.Mount(self: Self, component: Component, instance: Instance, properties: {[string]: any}?)
	if self._Bag._Destroyed then return end

	assert(type(component) == "function", "[Flux] Mount: component must be a function")
	assert(typeof(instance) == "Instance", "[Flux] Mount: instance must be an Instance")
	assert(properties == nil or typeof(properties) == "table", "[Flux] Mount: properties must be a table or nil")

	self._Scope:Mount(component, instance, properties)
end

--[=[
	@param condition State<boolean> -- A boolean state that drives visibility
	@param component Component -- The component function to conditionally mount
	@param instance Instance -- The GUI instance to pass to the component
	@param properties {[string]: any}? -- Optional properties table to pass to the component

	Conditionally mounts a component based on a boolean state. When the condition becomes `true`,
	the component is mounted and receives its own scope. When it becomes `false`, the component
	and all its bindings are cleaned up. If the condition becomes `true` again, the component is
	mounted again with a fresh scope (it does not resume prior local state). The target `instance`
	remains in the hierarchy; only component behavior is mounted/unmounted. Only one mounted
	component scope is active at a time.

	```lua
	local isVisible = Flux:State(false)
	local function Panel(instance: Instance, scope: Flux.Scope)
		local text = Flux:State("Hello")
		scope:BindProperty(text, instance, "Text")
	end
	local panelFrame = controller:GetInstance():FindFirstChild("Panel")
	if panelFrame then
		controller:MountWhen(isVisible, Panel, panelFrame)
	end
	isVisible:Set(true) -- Component mounts
	isVisible:Set(false) -- Component unmounts
	```
]=]
function Controller.MountWhen(self: Self, condition: State<boolean>, component: Component, instance: Instance, properties: {[string]: any}?)
	if self._Bag._Destroyed then return end

	assert(condition ~= nil and type(condition.Observe) == "function", "[Flux] MountWhen: condition must be a State<boolean>")
	assert(type(component) == "function", "[Flux] MountWhen: component must be a function")
	assert(typeof(instance) == "Instance", "[Flux] MountWhen: instance must be an Instance")
	assert(properties == nil or typeof(properties) == "table", "[Flux] MountWhen: properties must be a table or nil")

	self._Scope:MountWhen(condition, component, instance, properties)
end

return Controller