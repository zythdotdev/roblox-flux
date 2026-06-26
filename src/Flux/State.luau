local Value = require(script.Parent.Parent.Value)

--[=[
	@within State
	@interface State

	A reactive state object created by `Flux:State`. Wraps a `Value` and adds an `animated`
	flag to `Set`, so a single source of truth can drive both instant and animated transitions
	on any `Tween` or `Spring` derived from it.
]=]
type State<T> = {
	_Value: Value.Self<T>,
	_PendingAnimated: boolean,

	Destroy: (self: State<T>) -> (),
	Get: (self: State<T>) -> T?,
	Set: (self: State<T>, value: T?, animated: boolean?) -> (),
	Setter: (self: State<T>) -> (value: T?, animated: boolean?) -> (),
	Observe: (self: State<T>, callback: (T?) -> ()) -> Value.EventConnection,
	IsAnimated: (self: State<T>) -> boolean,
}

--[=[
	@within Flux
	@type Self Flux
]=]
export type Self<T> = State<T>

export type EventConnection = Value.EventConnection

local State = {}
State.__index = State

--[=[
	@within State
	@param initialValue T? -- An optional starting value
	@return State

	Creates a new `State` that supports animated and instant writes.
]=]
function State.new<T>(initialValue: T?): State<T>
	local self = setmetatable({
		_Value = Value.new(initialValue),
		_PendingAnimated = true,
	}, State)

	return self
end

--[=[
	@within State

	Destroys the underlying value and frees resources.
]=]
function State.Destroy<T>(self: State<T>)
	self._Value:Destroy()
end

--[=[
	@within State
	@return T? -- The current value

	Returns the current value.
]=]
function State.Get<T>(self: State<T>): T?
	return self._Value:Get()
end

--[=[
	@within State
	@param value T? -- The new value
	@param animated boolean? -- Whether derived Tweens/Springs should animate toward `value` (defaults to `true`)

	Sets the new value and updates observers. When `animated` is `false`, any `Tween` or `Spring`
	derived from this state jumps to `value` instantly instead of interpolating. The state is the
	single source of truth, so the displayed value can never disagree with it.

	```lua
	local position = Flux:State(restPos)
	local animPosition = Flux:Tween(position, TweenInfo.new(0.2))

	position:Set(startPos, false) -- jump, no animation
	position:Set(restPos) -- animate startPos -> restPos
	```
]=]
function State.Set<T>(self: State<T>, value: T?, animated: boolean?)
	self._PendingAnimated = animated ~= false
	local ok, err = pcall(self._Value.Set, self._Value, value)
	self._PendingAnimated = true
	if not ok then
		error(err, 0)
	end
end

--[=[
	@within State
	@return (value: T?, animated: boolean?) -> () -- A setter bound to this state

	Returns a setter function that forwards to `Set`, preserving the `animated` flag.
]=]
function State.Setter<T>(self: State<T>): (value: T?, animated: boolean?) -> ()
	return function(value: T?, animated: boolean?)
		self:Set(value, animated)
	end
end

--[=[
	@within State
	@param callback (T?) -> () -- Invoked immediately and on every change
	@return EventConnection

	Observes the state. Fires once with the current value, then on every change.
]=]
function State.Observe<T>(self: State<T>, callback: (T?) -> ()): Value.EventConnection
	return self._Value:Observe(callback)
end

--[=[
	@within State
	@return boolean -- Whether the in-flight write should animate

	Reads the pending `animated` intent for the current `Set`. Intended to be called by derived
	`Tween`/`Spring` observers from inside their observer callback; returns `true` for normal writes
	and outside of any `Set`. This is a plain read — `Set` resets the flag once it returns — so
	multiple animations derived from the same state all observe the same intent for a given write.
]=]
function State.IsAnimated<T>(self: State<T>): boolean
	return self._PendingAnimated
end

return State
