local RunService = game:GetService("RunService")

local Value = require(script.Parent.Packages.Value)

local SETTLE_THRESHOLD = 1e-3
local MAX_DT = 1 / 30

type AnimatedState<T> = {
	Get: (self: AnimatedState<T>) -> T?,
	Observe: (self: AnimatedState<T>, callback: (T?) -> ()) -> Value.EventConnection,
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
	error("Spring: unsupported type '" .. t .. "'", 2)
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
	error("Spring: unsupported type '" .. typeName .. "'", 2)
end

local function Spring<T>(source: Value.Self<T>, speed: number, damping: number): AnimatedState<T>
	local initial = source:Get()
	assert(initial ~= nil, "Spring: source must have a non-nil initial value")

	local position, typeName = decompose(initial)
	local target: Components = table.clone(position)
	local velocity: Components = table.create(#position, 0)
	local animated = Value.new(initial)
	local settled = true
	local started = false
	local heartbeatConn: RBXScriptConnection? = nil

	-- Hoist constants — speed and damping are fixed at construction time
	local twoZetaOmega = 2 * damping * speed
	local omegaSq = speed * speed

	local function cancelHeartbeat()
		if heartbeatConn then
			heartbeatConn:Disconnect()
			heartbeatConn = nil
		end
	end

	local function step(dt: number)
		-- Clamp dt so a frame spike cannot push the integrator past its stability limit
		dt = math.min(dt, MAX_DT)

		local allSettled = true

		for i = 1, #position do
			local accel = (target[i] - position[i]) * omegaSq - velocity[i] * twoZetaOmega
			velocity[i] += accel * dt
			position[i] += velocity[i] * dt
			if math.abs(velocity[i]) > SETTLE_THRESHOLD or math.abs(position[i] - target[i]) > SETTLE_THRESHOLD then
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
	end

	local connection = source:Observe(function(newTarget: T?)
		if not started then
			started = true
			return
		end

		if newTarget == nil then
			cancelHeartbeat()
			animated:Set(nil)
			return
		end

		local newComponents = decompose(newTarget)
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
			return animated:Get()
		end,
		Observe = function(_self: AnimatedState<T>, callback: (T?) -> ()): Value.EventConnection
			return animated:Observe(callback)
		end,
		Destroy = function(_self: AnimatedState<T>)
			cancelHeartbeat()
			connection:Disconnect()
			animated:Destroy()
		end,
	}

	return animatedState
end

return Spring
