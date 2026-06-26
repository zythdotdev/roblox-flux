local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Value = require(script.Parent.Parent.Value)
local Event = require(script.Parent.Parent.Event)
local State = require(script.Parent.State)

type AnimatedState<T> = {
	Get: (self: AnimatedState<T>) -> T?,
	Observe: (self: AnimatedState<T>, callback: (T?) -> ()) -> Value.EventConnection,
	Completed: (self: AnimatedState<T>, callback: () -> ()) -> Value.EventConnection,
	Destroy: (self: AnimatedState<T>) -> (),
}

local function lerp(a: any, b: any, alpha: number): any
	if typeof(a) == "number" then
		return a + (b - a) * alpha
	else
		return a:Lerp(b, alpha)
	end
end

local function isFiniteNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function Tween<T>(source: State.Self<T>, tweenInfo: TweenInfo): AnimatedState<T>
	assert(source ~= nil, "[Flux] Tween: source state is required")
	assert(typeof(tweenInfo) == "TweenInfo", "[Flux] Tween: tweenInfo must be a TweenInfo")
	assert(isFiniteNumber(tweenInfo.Time) and tweenInfo.Time >= 0, "[Flux] Tween: tweenInfo.Time must be a finite number >= 0")

	if tweenInfo.RepeatCount ~= 0 or tweenInfo.Reverses or tweenInfo.DelayTime ~= 0 then
		warn("[Flux] Tween: TweenInfo RepeatCount, Reverses, and DelayTime are not supported and will be ignored")
	end

	local animated = Value.new(source:Get())
	local completedEvent = Event.new()
	local heartbeatConn: RBXScriptConnection? = nil
	local started = false
	local hadNilTarget = false
	local isDestroyed = false
	local lastValue: T? = source:Get()

	local function cancelHeartbeat()
		if heartbeatConn then
			heartbeatConn:Disconnect()
			heartbeatConn = nil
		end
	end

	local sourceConn = source:Observe(function(target: T?)
		if not started then
			started = true
			return
		end

		local animate = source:IsAnimated()

		cancelHeartbeat()

		if target == nil then
			hadNilTarget = true
			animated:Set(nil)
			return
		end

		if not animate then
			hadNilTarget = false
			animated:Set(target)
			completedEvent:Fire()
			return
		end

		if hadNilTarget then
			hadNilTarget = false
			animated:Set(target)
			return
		end

		local startValue = animated:Get()
		if startValue == nil then
			animated:Set(target)
			return
		end

		local startType = typeof(startValue)
		local targetType = typeof(target)
		assert(startType == targetType, string.format("[Flux] Tween: source type changed from '%s' to '%s'", startType, targetType))

		local elapsed = 0
		local duration = tweenInfo.Time
		local style = tweenInfo.EasingStyle
		local direction = tweenInfo.EasingDirection

		if duration <= 0 then
			animated:Set(target)
			completedEvent:Fire()
			return
		end

		heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
			elapsed += dt
			local alpha = math.min(elapsed / duration, 1)
			local easedAlpha = TweenService:GetValue(alpha, style, direction)
			local ok, valueOrErr = pcall(lerp, startValue, target, easedAlpha)
			if not ok then
				cancelHeartbeat()
				error(string.format("[Flux] Tween: failed to interpolate '%s' values (%s)", startType, tostring(valueOrErr)), 0)
			end

			animated:Set(valueOrErr)
			if alpha >= 1 then
				cancelHeartbeat()
				completedEvent:Fire()
			end
		end)
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
			sourceConn:Disconnect()
			completedEvent:Destroy()
			animated:Destroy()
		end,
	}

	return animatedState
end

return Tween