local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Value = require(script.Parent.Packages.Value)

type AnimatedState<T> = {
	Get: (self: AnimatedState<T>) -> T?,
	Observe: (self: AnimatedState<T>, callback: (T?) -> ()) -> Value.EventConnection,
	Destroy: (self: AnimatedState<T>) -> (),
}

local function lerp(a: any, b: any, alpha: number): any
	if typeof(a) == "number" then
		return a + (b - a) * alpha
	else
		return a:Lerp(b, alpha)
	end
end

local function Tween<T>(source: Value.Self<T>, tweenInfo: TweenInfo): AnimatedState<T>
	if tweenInfo.RepeatCount ~= 0 or tweenInfo.Reverses or tweenInfo.DelayTime ~= 0 then
		warn("[Flux] Tween: TweenInfo RepeatCount, Reverses, and DelayTime are not supported and will be ignored")
	end

	local animated = Value.new(source:Get())
	local heartbeatConn: RBXScriptConnection? = nil
	local started = false

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

		cancelHeartbeat()

		if target == nil then
			animated:Set(nil)
			return
		end

		local startValue = animated:Get()
		if startValue == nil then
			animated:Set(target)
			return
		end

		local elapsed = 0
		local duration = tweenInfo.Time
		local style = tweenInfo.EasingStyle
		local direction = tweenInfo.EasingDirection

		if duration <= 0 then
			animated:Set(target)
			return
		end

		heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
			elapsed += dt
			local alpha = math.min(elapsed / duration, 1)
			local easedAlpha = TweenService:GetValue(alpha, style, direction)
			animated:Set(lerp(startValue, target, easedAlpha))
			if alpha >= 1 then
				cancelHeartbeat()
			end
		end)
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
			sourceConn:Disconnect()
			animated:Destroy()
		end,
	}

	return animatedState
end

return Tween
