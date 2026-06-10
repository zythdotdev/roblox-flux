local Bag = require(script.Parent.Packages.Bag)
local Value = require(script.Parent.Packages.Value)

--[=[
	@within Controller
	@interface Scope
	@field Bind (self, state: State<T>, callback: (newValue: T?) -> ()) -> () -- Binds to a `State` scoped to this component's lifecycle
	@field Mount (self, component: Component, instance: Instance, props: {[string]: any}?) -> () -- Mounts a child component scoped to this component's lifecycle

	A lifecycle scope passed to each component function. Use `Bind` to subscribe to reactive state and `Mount`
	to compose child components. All bindings and child mounts made through this scope are automatically cleaned
	up when the parent GUI is unmounted.
]=]
export type Scope = {
	Bind: <T>(self: Scope, state: State<T>, callback: (newValue: T?) -> ()) -> (),
	Mount: (self: Scope, component: Component, instance: Instance, props: {[string]: any}?) -> (),
}

--[=[
	@within Controller
	@type Component (instance: Instance, scope: Scope, props: {[string]: any}?) -> ()

	A reusable function that applies behavior to a GUI child `Instance`. Components are mounted to a specific
	`Instance` in the GUI hierarchy and can bind to reactive state using the provided `Scope`. Components
	should be used for reusable pieces of UI behavior. For example, you might have a "HealthBar" component that
	you mount to any Frame to turn it into a health bar, or a "Draggable" component that makes a GUI element
	draggable. Components should not manage the lifecycle of their own `Instance` (i.e. by destroying it or
	reparenting it), they should only be responsible for updating the instance's properties in response to state changes,
	passed down through `props` or observed via `Bind`. Let the parent `Controller` manage the lifecycle of all instances.
]=]
export type Component = (instance: Instance, scope: Scope, props: {[string]: any}?) -> ()

--[=[
	@within Controller
	@interface State

	A reactive state object. Create these using `Flux:State` and pass them to
	`Controller:Bind` or `Scope:Bind` inside components to reactively drive UI updates.
]=]
export type State<T> = Value.Self<T>

type Controller = {
	_Instance: ScreenGui | SurfaceGui | BillboardGui,
	_Bag: Bag.Self,

	Unmount: (self: Self) -> (),
	GetInstance: (self: Self) -> ScreenGui | SurfaceGui | BillboardGui,
	Mount: (self: Self, component: Component, instance: Instance, props: {[string]: any}?) -> (),
	Bind: <T>(self: Self, state: State<T>, callback: (newValue: T?) -> ()) -> (),
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
	Access the GUI hierarchy via `GetInstance()`.
]=]
local Controller = {}
Controller.__index = Controller

local function createScope(parentBag: Bag.Self): Scope
	local scope = {}

	function scope:Bind<U>(state: State<U>, callback: (newValue: U?) -> ())
		local connection = state:Observe(callback)
		parentBag:Add(connection)
	end

	function scope:Mount(component: Component, instance: Instance, props: {[string]: any}?)
		local childBag = Bag.new()
		parentBag:Add(childBag)
		component(instance, createScope(childBag), props)
	end

	return scope :: any
end

--[=[
	@param gui ScreenGui | SurfaceGui | BillboardGui -- The GUI instance to manage
	@return Controller -- A new Controller for the given GUI instance

	Creates a new Controller for the given GUI instance.
]=]
function Controller.new(gui: ScreenGui | SurfaceGui | BillboardGui): Controller
	local bag = Bag.new()
	bag:Add(gui)

	return setmetatable({
		_Instance = gui,
		_Bag = bag,
	}, Controller) :: any
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
	Applies a reusable `Component` function to a child instance. The component receives a `Scope`
	that allows it to bind to reactive state. All bindings made by the component are automatically
	cleaned up when the controller is unmounted.

	@param component Component -- The component function to apply
	@param instance Instance -- The GUI instance to pass to the component
	@param props {[string]: any}? -- Optional props table to pass to the component

	```lua
	local function HealthBar(instance: Instance, scope: Flux.Scope, props: {health: Flux.State<number>})
		scope:Bind(props.health, function(hp: number)
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
function Controller.Mount(self: Self, component: Component, instance: Instance, props: {[string]: any}?)
	if self._Bag._Destroyed then return end
	local componentBag = Bag.new()
	self._Bag:Add(componentBag)
	component(instance, createScope(componentBag), props)
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
	local connection = state:Observe(callback)
	self._Bag:Add(connection)
end

return Controller