

local Bag = require(script.Parent.Packages.Bag)
local Value = require(script.Parent.Packages.Value)

--[=[
	@within GuiController
	@interface GuiScope
	@field Bind (self, state: GuiState<T>, callback: (newValue: T?) -> ()) -> () -- Binds to a `GuiState` scoped to this component's lifecycle

	A lifecycle scope passed to each component function. Use `Bind` to subscribe to reactive state. All bindings made
	through this scope are automatically cleaned up when the parent GUI is unmounted, so you don't have to worry about
	disconnecting them manually.
]=]
export type GuiScope = {
	Bind: <T>(self: GuiScope, state: GuiState<T>, callback: (newValue: T?) -> ()) -> (),
}

--[=[
	@within GuiController
	@type GuiComponent (instance: Instance, scope: GuiScope, props: {[string]: any}?) -> ()

	A reusable function that applies behavior to a GUI child `Instance`. Components are mounted to a specific
	`Instance` in the GUI hierarchy and can bind to reactive state using the provided `GuiScope`. Components
	should be used for reusable pieces of UI behavior. For example, you might have a "HealthBar" component that
	you mount to any Frame to turn it into a health bar, or a "Draggable" component that makes a GUI element
	draggable. Components should not manage the lifecycle of their own `Instance` (i.e. by destroying it or
	reparenting it), they should only be responsible for updating the instance's properties in response to state changes,
	passed down through `props` or observed via `Bind`. Let the parent `GuiController` manage the lifecycle of all instances.
]=]
export type GuiComponent = (instance: Instance, scope: GuiScope, props: {[string]: any}?) -> ()

--[=[
	@within GuiController
	@interface GuiState

	A reactive state object. Create these using `Flux:State` and pass them to
	`GuiController:Bind` or `GuiScope:Bind` inside components to reactively drive UI updates.
]=]
export type GuiState<T> = Value.Self<T>

type GuiController = {
	Instance: ScreenGui | SurfaceGui | BillboardGui,
	_Bag: Bag.Self,

	Unmount: (self: Self) -> (),
	Mount: (self: Self, component: GuiComponent, instance: Instance, props: {[string]: any}?) -> (),
	Bind: <T>(self: Self, state: GuiState<T>, callback: (newValue: T?) -> ()) -> (),
}

--[=[
	@within GuiController
	@type Self GuiController
]=]
export type Self = GuiController

--[=[
	@class GuiController

	Controller for a mounted GUI. Returned by every `Mount` method call. A `GuiController` manages the lifecycle of
	the GUI `Instance` and all reactive connections. Call `Unmount` to clean up, `Bind` to react to state changes, `Get`
	to navigate the GUI `Instance` hierarchy, and `Mount` to apply reusable components that are automatically cleaned
	up when the controller is unmounted.
]=]
local GuiController = {}
GuiController.__index = GuiController

--[=[
	@param gui ScreenGui | SurfaceGui | BillboardGui -- The GUI instance to manage
	@return GuiController -- A new GuiController for the given GUI instance

	Creates a new GuiController for the given GUI instance.
]=]
function GuiController.new(gui: ScreenGui | SurfaceGui | BillboardGui): GuiController
	local bag = Bag.new()
	bag:GiveTask(gui)

	return setmetatable({
		Instance = gui,
		_Bag = bag,
	}, GuiController) :: any
end

--[=[
	Destroys the GUI `Instance` and disconnects all bindings. This should be called when you
	are finished with the GUI to properly clean up resources and prevent memory leaks.

	```lua
	local controller = Flux:MountScreenGuiAsync(gui)
	controller:Unmount() -- Clean up when done
	```
]=]
function GuiController.Unmount(self: Self)
	self._Bag:DoCleaning()
end

--[=[
	Applies a reusable `GuiComponent` function to a child instance. The component receives a `GuiScope`
	that allows it to bind to reactive state. All bindings made by the component are automatically
	cleaned up when the controller is unmounted.

	@param component GuiComponent -- The component function to apply
	@param instance Instance -- The GUI instance to pass to the component
	@param props {[string]: any}? -- Optional props table to pass to the component

	```lua
	local function HealthBar(instance: Instance, scope: Flux.GuiScope, props: {health: Flux.GuiState<number>})
		scope:Bind(props.health, function(hp: number)
			local bar: Frame = instance :: Frame
			bar.Size = UDim2.fromScale(hp / 100, 1)
		end)
	end

	local healthState = Flux:State(100)
	controller:Mount(HealthBar, controller:Get("HealthBarFrame"), {health = healthState})
	```
]=]
function GuiController.Mount(self: Self, component: GuiComponent, instance: Instance, props: {[string]: any}?)
	local componentBag = Bag.new()
	self._Bag:GiveTask(componentBag)

	local scope = {}
	function scope:Bind<U>(state: GuiState<U>, callback: (newValue: U?) -> ())
		local connection = state:Observe(callback)
		componentBag:GiveTask(function()
			connection:Disconnect()
		end)
	end

	component(instance, scope, props)
end

--[=[
	@param state GuiState<T> -- The reactive state to observe
	@param callback (newValue: T?) -> () -- Function to call with the current and future values

	Binds to a `GuiState` object so that `callback` fires immediately with the current value,
	and then again every time the state changes. The binding is automatically cleaned up when
	the controller is unmounted.

	```lua
	local coins: Flux.GuiState<number> = Flux:State(0)
	controller:Bind(coins, function(count: number)
		local label: TextLabel = controller:Get("CoinsLabel")
		label.Text = tostring(count)
	end)
	```
]=]
function GuiController.Bind<T>(self: Self, state: GuiState<T>, callback: (newValue: T?) -> ())
	local connection = state:Observe(callback)
	self._Bag:GiveTask(connection)
end

return GuiController