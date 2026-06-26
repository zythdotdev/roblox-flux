local Players = game:GetService("Players")

local Value = require(script.Parent.Value)
local State = require(script.State)
local Controller = require(script.Controller)
local Tween = require(script.Tween)
local Spring = require(script.Spring)

--[=[
	@within Flux
	@interface Scope
	@field Bind (self, state: State<T>, callback: (newValue: T?) -> ()) -> () -- Binds to a `State` scoped to this component's lifecycle
	@field BindProperty (self, state: State<T>, instance: Instance, property: string) -> () -- Binds a `State` directly to a named property on an instance
	@field BindEvent (self, instance: Instance, eventName: string, callback: (...any) -> ()) -> () -- Connects an instance event scoped to this component's lifecycle
	@field Mount (self, component: Component, instance: Instance, properties: {[string]: any}?) -> () -- Mounts a child component scoped to this component's lifecycle
	@field MountWhen (self, condition: State<boolean>, component: Component, instance: Instance, properties: {[string]: any}?) -> () -- Conditionally mounts a child component based on state

	A minimal lifecycle scope passed to each component function. Use `Bind` to subscribe to reactive state,
	`BindProperty` to drive a named instance property directly from state, `BindEvent` to connect instance
	events, `Mount` to compose child components, and `MountWhen` for conditional rendering.
	All bindings, event connections, and child mounts made through this scope are automatically
	cleaned up when the parent GUI is unmounted.
]=]
export type Scope = Controller.Scope

--[=[
	@within Flux
	@type Component (instance: Instance, scope: Scope, properties: {[string]: any}?) -> ()

	A reusable function that applies behavior to a GUI child `Instance`. Components are mounted to a specific
	`Instance` in the GUI hierarchy and can bind to reactive state using the provided `Scope`. Components
	should be used for reusable pieces of UI behavior. For example, you might have a "HealthBar" component that
	you mount to any Frame to turn it into a health bar, or a "Draggable" component that makes any GUI element
	draggable. Components should not manage the lifecycle of their own `Instance` (i.e. by destroying it or
	reparenting it), they should only be responsible for updating the instance's properties in response to state changes,
	passed down through `properties` or observed via `Bind`. Let the parent `Controller` manage the lifecycle of all instances.
]=]
export type Component = Controller.Component

--[=[
	@within Flux
	@interface State

	A reactive state object. Create these using `Flux:State` and pass them to
	`Controller:Bind` or `Scope:Bind` inside components to reactively drive UI updates.
	`Set` accepts an optional `animated` flag (defaulting to `true`); pass `false` to make any
	`Tween` or `Spring` derived from this state jump instantly instead of interpolating.
]=]
export type State<T> = State.Self<T>

--[=[
	@within Flux
	@interface AnimatedState
	@field Get (self) -> T? -- Returns the current animated value
	@field Observe (self, callback: (T?) -> ()) -> EventConnection -- Fires immediately and on every animated value change
	@field Completed (self, callback: () -> ()) -> EventConnection -- Fires each time the animation reaches its target and settles
	@field Destroy (self) -> () -- Stops the animation and frees resources

	A read-only animated state returned by `Flux:Tween` and `Flux:Spring`. Supports `Get`, `Observe`,
	`Completed`, and `Destroy` — compatible with `Bind` and `BindProperty`. It is driven entirely by its
	source `State`: write the source with `Set(value)` to animate toward `value`, or `Set(value, false)` to
	jump instantly (e.g. to seed an entrance). Use `Completed` to run logic once the motion settles. Call
	`Destroy` when you are finished with it to stop the animation and free resources.
]=]
export type AnimatedState<T> = {
	Get: (self: AnimatedState<T>) -> T?,
	Observe: (self: AnimatedState<T>, callback: (T?) -> ()) -> Value.EventConnection,
	Completed: (self: AnimatedState<T>, callback: () -> ()) -> Value.EventConnection,
	Destroy: (self: AnimatedState<T>) -> (),
}

type Flux = {
	State: <T>(self: Flux, initialValue: T?) -> State<T>,
	Computed: <T>(self: Flux, callback: (...any) -> T, dependencies: {State<any>}?) -> State<T>,
	Compose: (self: Flux, components: {Component}) -> Component,
	Tween: <T>(self: Flux, source: State<T>, tweenInfo: TweenInfo) -> AnimatedState<T>,
	Spring: <T>(self: Flux, source: State<T>, speed: number, damping: number) -> AnimatedState<T>,
	MountScreenGui: (self: Flux, gui: ScreenGui) -> Controller.Self,
	MountSurfaceGui: (self: Flux, gui: SurfaceGui, adornee: BasePart, face: Enum.NormalId?) -> Controller.Self,
	MountBillboardGui: (self: Flux, gui: BillboardGui, adornee: BasePart) -> Controller.Self,
}

--[=[
	@within Flux
	@type Self Flux
]=]
export type Self = Flux

--[=[
	@class Flux

	Client module for mounting and managing GUI instances. Each mount parents the GUI to
	`PlayerGui` and returns a `Controller` that owns the instance's lifecycle.
	The caller is responsible for cloning templates before passing them in.

	```lua
	local Flux = require(ReplicatedStorage.Flux)

	-- Create reactive state
	local coins: Flux.State<number> = Flux:State(0)

	-- Clone and mount the GUI
	local gui = ReplicatedStorage.Assets.Gui.CoinScreenGui:Clone()
	local controller = Flux:MountScreenGui(gui)

	-- Bind state to UI
	controller:Bind(coins, function(count: number)
		local frame = controller:GetInstance():FindFirstChild("Frame")
		if frame then
			local coinsLabel = frame:FindFirstChild("CoinsLabel")
			if coinsLabel and coinsLabel:IsA("TextLabel") then
				coinsLabel.Text = tostring(count)
			end
		end
	end)

	-- Update state from gameplay
	coins:Set(42)
	```
]=]
local Flux = {}

--[=[
	@param initialValue T? -- An optional starting value
	@return State<T>

	Creates a new reactive `State` object that can be bound to GUI updates. Call `Set` on
	the returned object to update the state and trigger UI updates.

	```lua
	local coins: Flux.State<number> = Flux:State(0)
	controller:Bind(coins, function(n: number) label.Text = tostring(n) end)
	coins:Set(42)
	```
]=]
function Flux.State<T>(_self: Flux, initialValue: T?): State<T>
	return State.new(initialValue)
end

--[=[
	@param callback () -> T -- A function that derives the computed value from current dependencies
	@param dependencies {State<any>}? -- Optional array of states to observe; if omitted, the callback is evaluated once
	@return State<T>

	Creates a reactive derived state value. The callback runs immediately to seed the value,
	then re-runs whenever any dependency changes. The returned state is read-only from the
	caller perspective and is cleaned up automatically when its dependencies are destroyed.
]=]
function Flux.Computed<T>(_self: Flux, callback: (...any) -> T, dependencies: {State<any>}?): State<T>
	assert(type(callback) == "function", "[Flux] Computed: callback must be a function")

	if dependencies then
		assert(typeof(dependencies) == "table", "[Flux] Computed: dependencies must be a table")
		for i, dependency in dependencies do
			assert(dependency ~= nil, "[Flux] Computed: dependency at index " .. i .. " is nil")
			assert(type(dependency.Observe) == "function", "[Flux] Computed: dependency at index " .. i .. " is not a State")
		end
	end

	local computed = State.new(nil)
	local dependencyConnections: {Value.EventConnection} = {}
	local isDestroyed = false

	local function disconnectDependencies()
		for _, connection in dependencyConnections do
			if connection and connection.IsConnected and connection:IsConnected() then
				connection:Disconnect()
			end
		end
		table.clear(dependencyConnections)
	end

	local function destroyComputed()
		if isDestroyed then
			return
		end
		isDestroyed = true
		disconnectDependencies()
		computed:Destroy()
	end

	local function recompute()
		if isDestroyed then
			return
		end

		if dependencies then
			local values = table.create(#dependencies)
			for i, dependency in dependencies do
				local ok, valueOrErr = pcall(function()
					return dependency:Get()
				end)

				if not ok then
					destroyComputed()
					return
				end

				values[i] = valueOrErr
			end

			computed:Set(callback(table.unpack(values, 1, #values)))
		else
			computed:Set(callback())
		end
	end

	if dependencies then
		for _, dependency in dependencies do
			local connection = dependency:Observe(function()
				recompute()
			end)
			table.insert(dependencyConnections, connection)
		end
	else
		recompute()
	end

	local originalDestroy = computed.Destroy
	computed.Destroy = function(self: State<T>)
		disconnectDependencies()
		originalDestroy(self)
	end

	return computed
end

--[=[
	@param components {Component} -- Components to run in sequence for the same instance and scope
	@return Component

	Composes multiple components into one component. The returned component invokes each
	component in order using the same `instance`, `scope`, and `properties`.

	```lua
	local FancyButton = Flux:Compose({
		HoverEffect,
		ClickEffect,
		PulseEffect,
	})
	controller:Mount(FancyButton, button, {theme = themeState})
	```
]=]
function Flux.Compose(_self: Flux, components: {Component}): Component
	assert(typeof(components) == "table", "[Flux] Compose: components must be a table")

	for i, component in components do
		assert(type(component) == "function", string.format("[Flux] Compose: component at index %d must be a function", i))
	end

	return function(instance: Instance, scope: Scope, properties: {[string]: any}?)
		for _, component in components do
			component(instance, scope, properties)
		end
	end
end

--[=[
	@param source State<T> -- The reactive state to animate
	@param tweenInfo TweenInfo -- Controls duration, easing style, and easing direction
	@return AnimatedState<T>

	Returns an `AnimatedState` that smoothly interpolates toward `source` whenever it changes,
	using `TweenInfo` for timing and easing. Supports `number` and any Roblox type with a `:Lerp`
	method (UDim2, Vector2, Vector3, Color3, CFrame, UDim). Call `Destroy` when finished.

	```lua
	local health = Flux:State(100)
	local animHealth = Flux:Tween(health, TweenInfo.new(0.4, Enum.EasingStyle.Quad))
	scope:BindProperty(animHealth, bar, "Size")
	health:Set(50)
	```

	Pass `animated = false` to `source:Set` to seed a value instantly (no animation) and use `Completed`
	to react when a tween settles. This is the idiomatic "seed-then-animate" entrance: jump to the start,
	then animate to the rest value — all through the single source state.

	```lua
	local position = Flux:State(restPosition)
	local animPosition = Flux:Tween(position, TweenInfo.new(0.2))
	scope:BindProperty(animPosition, frame, "Position")

	position:Set(startPosition, false) -- instant, no animation
	position:Set(restPosition)         -- animates start -> rest
	animPosition:Completed(function()
		print("slide-in finished")
	end)
	```
]=]
function Flux.Tween<T>(_self: Flux, source: State<T>, tweenInfo: TweenInfo): AnimatedState<T>
	assert(source ~= nil, "[Flux] Tween: source state is required")
	assert(typeof(tweenInfo) == "TweenInfo", "[Flux] Tween: tweenInfo must be a TweenInfo")

	return Tween(source, tweenInfo)
end

--[=[
	@param source State<T> -- The reactive state to animate
	@param speed number -- Angular frequency — how quickly the spring responds (e.g. 15–25 for snappy UI)
	@param damping number -- Damping ratio — 1 is critically damped (no overshoot), < 1 is bouncy
	@return AnimatedState<T>

	Returns an `AnimatedState` driven by spring physics that follows `source` whenever it changes.
	Supports `number`, Vector2, Vector3, Color3, and UDim2. The Heartbeat connection is only active
	while the spring is moving and disconnects automatically when settled. Call `Destroy` when finished.

	```lua
	local open = Flux:State(UDim2.fromScale(0, 0))
	local animOpen = Flux:Spring(open, 20, 1)
	scope:BindProperty(animOpen, panel, "Size")
	open:Set(UDim2.fromScale(1, 1))
	```

	Like `Flux:Tween`, passing `animated = false` to `source:Set` jumps instantly to a value (resetting the
	spring's position and velocity, with no motion), and `Completed` fires each time the spring settles at
	its target.

	```lua
	open:Set(UDim2.fromScale(0, 0), false) -- instant, at rest
	open:Set(UDim2.fromScale(1, 1))        -- springs toward full size
	animOpen:Completed(function()
		print("panel finished opening")
	end)
	```
]=]
function Flux.Spring<T>(_self: Flux, source: State<T>, speed: number, damping: number): AnimatedState<T>
	assert(source ~= nil, "[Flux] Spring: source state is required")
	assert(type(speed) == "number", "[Flux] Spring: speed must be a number")
	assert(type(damping) == "number", "[Flux] Spring: damping must be a number")

	return Spring(source, speed, damping)
end

--[=[
	@param gui ScreenGui -- The GUI instance to mount
	@return Controller

	Parents the given `ScreenGui` to the local player's `PlayerGui` and returns a `Controller`
	that owns its lifecycle. The caller is responsible for cloning templates before passing them in.
]=]
function Flux.MountScreenGui(_self: Flux, gui: ScreenGui): Controller.Self
	assert(typeof(gui) == "Instance" and gui:IsA("ScreenGui"), "[Flux] MountScreenGui: gui must be a ScreenGui")

	local localPlayer = Players.LocalPlayer
	assert(localPlayer, "[Flux] MountScreenGui: LocalPlayer not available")

	gui.Parent = localPlayer.PlayerGui

	return Controller.new(gui)
end

--[=[
	@param gui SurfaceGui -- The GUI instance to mount
	@param adornee BasePart -- The part the SurfaceGui will be attached to
	@param face Enum.NormalId? -- The face of the part the SurfaceGui will be attached to (optional)
	@return Controller

	Sets the `Adornee` (and optionally `Face`) on the given `SurfaceGui`, parents it to the local
	player's `PlayerGui`, and returns a `Controller` that owns its lifecycle. The caller is
	responsible for cloning templates before passing them in.
]=]
function Flux.MountSurfaceGui(_self: Flux, gui: SurfaceGui, adornee: BasePart, face: Enum.NormalId?): Controller.Self
	assert(typeof(gui) == "Instance" and gui:IsA("SurfaceGui"), "[Flux] MountSurfaceGui: gui must be a SurfaceGui")
	assert(typeof(adornee) == "Instance" and adornee:IsA("BasePart"), "[Flux] MountSurfaceGui: adornee must be a BasePart")
	if face ~= nil then
		assert(typeof(face) == "EnumItem" and face.EnumType == Enum.NormalId, "[Flux] MountSurfaceGui: face must be an Enum.NormalId")
	end

	local localPlayer = Players.LocalPlayer
	assert(localPlayer, "[Flux] MountSurfaceGui: LocalPlayer not available")

	gui.Adornee = adornee
	if face then
		gui.Face = face
	end
	gui.Parent = localPlayer.PlayerGui

	return Controller.new(gui)
end

--[=[
	@param gui BillboardGui -- The GUI instance to mount
	@param adornee BasePart -- The part the BillboardGui will be attached to
	@return Controller

	Sets the `Adornee` on the given `BillboardGui`, parents it to the local player's `PlayerGui`,
	and returns a `Controller` that owns its lifecycle. The caller is responsible for cloning
	templates before passing them in.
]=]
function Flux.MountBillboardGui(_self: Flux, gui: BillboardGui, adornee: BasePart): Controller.Self
	assert(typeof(gui) == "Instance" and gui:IsA("BillboardGui"), "[Flux] MountBillboardGui: gui must be a BillboardGui")
	assert(typeof(adornee) == "Instance" and adornee:IsA("BasePart"), "[Flux] MountBillboardGui: adornee must be a BasePart")

	local localPlayer = Players.LocalPlayer
	assert(localPlayer, "[Flux] MountBillboardGui: LocalPlayer not available")

	gui.Adornee = adornee
	gui.Parent = localPlayer.PlayerGui

	return Controller.new(gui)
end

return Flux