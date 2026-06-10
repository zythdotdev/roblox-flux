local Players = game:GetService("Players")

local Value = require(script.Packages.Value)
local GuiController = require(script.GuiController)

--[=[
	@within Flux
	@interface GuiScope
	@field Bind (self, state: GuiState<T>, callback: (newValue: T?) -> ()) -> () -- Binds to a `GuiState` scoped to this component's lifecycle

	A minimal lifecycle scope passed to each component function. Use `Bind` to subscribe to reactive state. All bindings made
	through this scope are automatically cleaned up when the parent GUI is unmounted, so you don't have to worry about
	disconnecting them manually.
]=]
export type GuiScope = GuiController.GuiScope

--[=[
	@within Flux
	@type GuiComponent (instance: Instance, scope: GuiScope, props: {[string]: any}?) -> ()

	A reusable function that applies behavior to a GUI child `Instance`. Components are mounted to a specific
	`Instance` in the GUI hierarchy and can bind to reactive state using the provided `GuiScope`. Components
	should be used for reusable pieces of UI behavior. For example, you might have a "HealthBar" component that
	you mount to any Frame to turn it into a health bar, or a "Draggable" component that makes any GUI element
	draggable. Components should not manage the lifecycle of their own `Instance` (i.e. by destroying it or
	reparenting it), they should only be responsible for updating the instance's properties in response to state changes,
	passed down through `props` or observed via `Bind`. Let the parent `GuiController` manage the lifecycle of all instances.
]=]
export type GuiComponent = GuiController.GuiComponent

--[=[
	@within Flux
	@interface GuiState

	A reactive state object. Create these using `Flux:State` and pass them to
	`GuiController:Bind` or `GuiScope:Bind` inside components to reactively drive UI updates.
]=]
export type GuiState<T> = Value.Self<T>

type Flux = {
	State: <T>(self: Flux, initialValue: T?) -> GuiState<T>,
	MountScreenGuiAsync: (self: Flux, gui: ScreenGui) -> GuiController.Self,
	MountSurfaceGuiAsync: (self: Flux, gui: SurfaceGui, adornee: BasePart, face: Enum.NormalId?) -> GuiController.Self,
	MountBillboardGuiAsync: (self: Flux, gui: BillboardGui, adornee: BasePart) -> GuiController.Self,
}

--[=[
	@within Flux
	@type Self Flux
]=]
export type Self = Flux


--[=[
	@class Flux

	Client module for mounting and unmounting GUI instances built in-engine and stored under
	`ReplicatedStorage/Assets/Gui`. Each mount clones the asset, parents it appropriately,
	and returns a `GuiController` that owns the GUI instance's lifecycle.

	:::note
	Give each GUI its own module in `Modules/ClientModules/Gui/` that manages state, mounts via Flux, and
	exposes a typed public API. This keeps all GUI-related code in one place and makes it easy to manage
	the lifecycle of each GUI.
	:::

	```lua
	local Flux = require(MVDK.ClientModules.Flux)

	local coins: Flux.GuiState<number> = Flux:State(0) -- Create reactive state for the coin count

	local CoinGui = {}

	function CoinGui.Init(_self)
		local controller = Flux:MountScreenGuiAsync("CoinScreenGui")
		controller:Bind(coins, function(count: number)
			local coinsLabel: TextLabel = controller:Get("Frame", "CoinsLabel")
			coinsLabel.Text = tostring(count)
		end)
	end

	function CoinGui.SetCoins(_self, count: number)
		coins:Set(count)
	end

	return CoinGui
	```
]=]
local Flux = {}

--[=[
	@param initialValue T? -- An optional starting value
	@return GuiState<T>

	Creates a new reactive `GuiState` object that can be bound to GUI updates. Call `Set` on
	the returned object to update the state and trigger UI updates.

	```lua
	local coins: Flux.GuiState<number> = Flux:State(0)
	controller:Bind(coins, function(n: number) label.Text = tostring(n) end)
	coins:Set(42)
	```
]=]
function Flux.State<T>(_self: Flux, initialValue: T?): GuiState<T>
	return Value.new(initialValue)
end

--[=[
	@yields
	@param gui ScreenGui -- The GUI asset to mount
	@return GuiController

	Clones the named asset from `ReplicatedStorage/Assets/Gui/<guiName>`, parents it to the
	local player's `PlayerGui`, and returns a `GuiController`. This method will yield if the player's
	`PlayerGui` is not immediately available, so it should be called from a context where yielding
	is allowed (e.g. not from a constructor or property initializer that's invoked synchronously).
]=]
function Flux.MountScreenGuiAsync(_self: Flux, gui: ScreenGui): GuiController.Self
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local clone = gui:Clone()
	clone.Parent = playerGui

	return GuiController.new(clone)
end

--[=[
	@yields
	@param gui SurfaceGui -- The GUI asset to mount
	@param adornee BasePart -- The part the SurfaceGui will be attached to
	@param face Enum.NormalId? -- The face of the part the SurfaceGui will be attached to (optional)
	@return GuiController

	Clones the named asset from `ReplicatedStorage/Assets/Gui/<guiName>`, sets its `Adornee`,
	parents it to the adornee part, sets its `Face` if provided, and returns a `GuiController`.
	This method will yield if the player's `PlayerGui` is not immediately available, so it should
	be called from a context where yielding is allowed (e.g. not from a constructor or property 
	initializer that's invoked synchronously).
]=]
function Flux.MountSurfaceGuiAsync(_self: Flux, gui: SurfaceGui, adornee: BasePart, face: Enum.NormalId?): GuiController.Self
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local clone = gui:Clone()
	clone.Parent = playerGui
	clone.Adornee = adornee
	if face then
		clone.Face = face
	end

	return GuiController.new(clone)
end

--[=[
	@yields
	@param gui BillboardGui -- The GUI asset to mount
	@param adornee BasePart -- The part the BillboardGui will be attached to
	@return GuiController

	Clones the named asset from `ReplicatedStorage/Assets/Gui/<guiName>`, sets its `Adornee`,
	parents it to the adornee part, and returns a `GuiController`. This method will yield if the
	player's `PlayerGui` is not immediately available, so it should be called from a context where
	yielding is allowed (e.g. not from a constructor or property initializer that's invoked synchronously).
]=]
function Flux.MountBillboardGuiAsync(_self: Flux, gui: BillboardGui, adornee: BasePart): GuiController.Self
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local clone = gui:Clone()
	clone.Parent = playerGui
	clone.Adornee = adornee

	return GuiController.new(clone)
end

return Flux