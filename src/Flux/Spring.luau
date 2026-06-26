local RunService = game:GetService("RunService")

local Value = require(script.Parent.Parent.Value)
local Event = require(script.Parent.Parent.Event)
local State = require(script.Parent.State)

local SETTLE_THRESHOLD = 1e-3
local MAX_DT = 1 / 30

type AnimatedState<T> = {
	Get: (self: AnimatedState<T>) -> T?,
	Observe: (self: AnimatedState<T>, callback: (T?) -> ()) -> Value.EventConnection,
	Completed: (self: AnimatedState<T>, callback: () -> ()) -> Value.EventConnection,
	Destroy: (self: AnimatedState<T>) -> (),
}

type Components = { number }

local function decompose(value: any): (Components, string)
	local t = typeof(value)
	if t == "number" then
		return { value }, "number"
	elseif t == "Vector2" then
		return { value.X, value.Y }, "Vector2"
	elseif t == "Vector3" then
		return { value.X, value.Y, value.Z }, "Vector3"
	elseif t == "Color3" then
		return { value.R, value.G, value.B }, "Color3"
	elseif t == "UDim2" then
		return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }, "UDim2"
	end
	error("[Flux] Spring: unsupported type '" .. t .. "'", 2)
end

local function recompose(typeName: string, c: Components): any
	if typeName == "number" then
		return c[1]
	elseif typeName == "Vector2" then
		return Vector2.new(c[1], c[2])
	elseif typeName == "Vector3" then
		return Vector3.new(c[1], c[2], c[3])
	elseif typeName == "Color3" then
		return Color3.new(math.clamp(c[1], 0, 1), math.clamp(c[2], 0, 1), math.clamp(c[3], 0, 1))
	elseif typeName == "UDim2" then
		return UDim2.new(c[1], c[2], c[3], c[4])
	end
	error("[Flux] Spring: unsupported type '" .. typeName .. "'", 2)
end

local function isFiniteNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function Spring<T>(source: State.Self<T>, speed: number, damping: number): AnimatedState<T>
	assert(source ~= nil, "[Flux] Spring: source state is required")
	assert(type(speed) == "number" and isFiniteNumber(speed) and speed > 0, "[Flux] Spring: speed must be a finite number > 0")
	assert(type(damping) == "number" and isFiniteNumber(damping) and damping >= 0, "[Flux] Spring: damping must be a finite number >= 0")

	local initial = source:Get()
	assert(initial ~= nil, "[Flux] Spring: source must have a non-nil initial value")

	local position, typeName = decompose(initial)
	local target: Components = table.clone(position)
	local velocity: Components = table.create(#position, 0)
	local animated = Value.new(initial)
	local completedEvent = Event.new()
	local settled = true
	local started = false
	local hadNilTarget = false
	local isDestroyed = false
	local lastValue: T? = initial
	local heartbeatConn: RBXScriptConnection? = nil

	local twoZetaOmega = 2 * damping * speed
	local omegaSq = speed * speed

	local function cancelHeartbeat()
		if heartbeatConn then
			heartbeatConn:Disconnect()
			heartbeatConn = nil
		end
	end

	local function step(dt: number)
		dt = math.min(dt, MAX_DT)

		local allSettled = true

		for i = 1, #position do
			local accel = (target[i] - position[i]) * omegaSq - velocity[i] * twoZetaOmega
			velocity[i] += accel * dt
			position[i] += velocity[i] * dt
			local displacement = target[i] - position[i]
			if math.abs(displacement) + math.abs(velocity[i]) > SETTLE_THRESHOLD then
				allSettled = false
			end
		end

		if allSettled then
			for i = 1, #position do
				position[i] = target[i]
				velocity[i] = 0
			end
			cancelHeartbeat()
			settled = true
		end

		animated:Set(recompose(typeName, position))

		if allSettled then
			completedEvent:Fire()
		end
	end

	local connection = source:Observe(function(newTarget: T?)
		if not started then
			started = true
			return
		end

		local animate = source:IsAnimated()

		if newTarget == nil then
			cancelHeartbeat()
			hadNilTarget = true
			settled = true
			for i = 1, #velocity do
				velocity[i] = 0
			end
			animated:Set(nil)
			return
		end

		local newComponents, newTypeName = decompose(newTarget)
		assert(newTypeName == typeName, string.format("[Flux] Spring: source type changed from '%s' to '%s'", typeName, newTypeName))

		if not animate then
			cancelHeartbeat()
			hadNilTarget = false
			for i = 1, #newComponents do
				position[i] = newComponents[i]
				target[i] = newComponents[i]
				velocity[i] = 0
			end
			settled = true
			animated:Set(recompose(typeName, position))
			completedEvent:Fire()
			return
		end

		if hadNilTarget then
			hadNilTarget = false
			for i = 1, #newComponents do
				position[i] = newComponents[i]
				target[i] = newComponents[i]
				velocity[i] = 0
			end
			settled = true
			animated:Set(recompose(typeName, position))
			return
		end

		for i = 1, #newComponents do
			target[i] = newComponents[i]
		end

		if settled then
			settled = false
			heartbeatConn = RunService.Heartbeat:Connect(step)
		end
	end)

	local animatedState: AnimatedState<T> = {
		Get = function(_self: AnimatedState<T>): T?
			if isDestroyed then
				return lastValue
			end
			return animated:Get()
		end,
		Observe = function(_self: AnimatedState<T>, callback: (T?) -> ()): Value.EventConnection
			return animated:Observe(callback)
		end,
		Completed = function(_self: AnimatedState<T>, callback: () -> ()): Value.EventConnection
			return completedEvent:Connect(callback)
		end,
		Destroy = function(_self: AnimatedState<T>)
			if isDestroyed then return end
			lastValue = animated:Get()
			isDestroyed = true
			cancelHeartbeat()
			connection:Disconnect()
			completedEvent:Destroy()
			animated:Destroy()
		end,
	}

	return animatedState
end

return Spring