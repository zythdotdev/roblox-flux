local Players = game:GetService("Players")

local Value = require(script.Packages.Value)
local Controller = require(script.Controller)

--[=[
	@within Flux
	@interface Scope
	@field Bind (self, state: State<T>, callback: (newValue: T?) -> ()) -> () -- Binds to a `State` scoped to this component's lifecycle
	@field BindProperty (self, state: State<T>, instance: Instance, property: string) -> () -- Binds a `State` directly to a named property on an instance
	@field Mount (self, component: Component, instance: Instance, properties: {[string]: any}?) -> () -- Mounts a child component scoped to this component's lifecycle

	A minimal lifecycle scope passed to each component function. Use `Bind` to subscribe to reactive state,
	`BindProperty` to drive a named instance property directly from state, and `Mount` to compose child
	components. All bindings and child mounts made through this scope are automatically cleaned up when
	the parent GUI is unmounted.
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
]=]
export type State<T> = Value.Self<T>

type Flux = {
	State: <T>(self: Flux, initialValue: T?) -> State<T>,
	Computed: <T>(self: Flux, callback: (...any) -> T, dependencies: {State<any>}?) -> State<T>,
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
	return Value.new(initialValue)
end

--[=[
	@param callback () -> T -- A function that derives the computed value from current dependencies
	@param dependencies {State<any>}? -- Optional list of states to observe; if omitted, the callback is evaluated once
	@return State<T>

	Creates a reactive derived state value. The callback runs immediately to seed the value,
	then re-runs whenever any dependency changes. The returned state is read-only from the
	caller perspective and is cleaned up automatically when its dependencies are destroyed.
]=]
function Flux.Computed<T>(_self: Flux, callback: (...any) -> T, dependencies: {State<any>}?): State<T>
	return Value.computed(function(...: any)
		return callback(...)
	end, dependencies)
end

--[=[
	@param gui ScreenGui -- The GUI instance to mount
	@return Controller

	Parents the given `ScreenGui` to the local player's `PlayerGui` and returns a `Controller`
	that owns its lifecycle. The caller is responsible for cloning templates before passing them in.
]=]
function Flux.MountScreenGui(_self: Flux, gui: ScreenGui): Controller.Self
	gui.Parent = Players.LocalPlayer.PlayerGui
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
	gui.Adornee = adornee
	if face then
		gui.Face = face
	end
	gui.Parent = Players.LocalPlayer.PlayerGui
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
	gui.Adornee = adornee
	gui.Parent = Players.LocalPlayer.PlayerGui
	return Controller.new(gui)
end

return Flux