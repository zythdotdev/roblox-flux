# Flux

A simple, lightweight reactive UI framework for Roblox that makes building dynamic user interfaces easy and maintainable.

## Features

- 🔄 **Reactive State Management** - Create observable state that automatically updates your UI
- 🧩 **Component System** - Build reusable UI components with automatic lifecycle management
- 🧱 **Component Composition** - Combine behaviors with `Flux:Compose(...)`
- 🎬 **Smooth Animations** - Tween and Spring animations that follow reactive state with automatic cleanup
- 🧹 **Automatic Cleanup** - No memory leaks - all bindings are automatically cleaned up
- 📦 **Lightweight** - Minimal dependencies and small footprint
- 🔒 **Type-Safe** - Full Luau type annotations for better IDE support
- ✅ **Unit Tested** - Comprehensive test coverage ensures reliability

## Installation

### Using Wally

Add Flux to your `wally.toml`:

```toml
[dependencies]
Flux = "zythdotdev/flux@1.1.0"
```

Then run:

```bash
wally install
```

### Manual Installation

1. Download the latest release
2. Place the `Flux` folder in your `ReplicatedStorage` or wherever you store your modules

## Quick Start

```lua
local Flux = require(path.to.Flux)

-- Create reactive state
local coins = Flux:State(0)

-- Mount a ScreenGui
local gui = ReplicatedStorage.Gui.CoinsGui:Clone()
local controller = Flux:MountScreenGui(gui)

-- Bind state to UI updates
controller:Bind(coins, function(count: number)
    local frame = controller:GetInstance():FindFirstChild("Frame")
    if frame then
        local label = frame:FindFirstChild("CoinsLabel")
        if label and label:IsA("TextLabel") then
            label.Text = tostring(count)
        end
    end
end)

-- Update state (UI updates automatically)
coins:Set(100)

-- Clean up when done
controller:Unmount() -- or Destroy
coins:Destroy()
```

## Core Concepts

### Reactive State

Create reactive state with `Flux:State()`:

```lua
local health: Flux.State<number> = Flux:State(100)
local playerName: Flux.State<string> = Flux:State("Player")
```

Update state with `:Set()`:

```lua
health:Set(75)
playerName:Set("NewPlayer")
```

Get current value with `:Get()`:

```lua
local currentHealth = health:Get()
```

### Computed State

Use `Flux:Computed()` when a value should update automatically from one or more existing states:

```lua
local health = Flux:State(100)
local maxHealth = Flux:State(100)

local healthPercent = Flux:Computed(function(currentHealth, max)
    return currentHealth / max
end, { health, maxHealth })

controller:Bind(healthPercent, function(percent)
    local bar = controller:GetInstance():FindFirstChild("HealthBar")
    if bar and bar:IsA("Frame") then
        bar.Size = UDim2.fromScale(percent, 1)
    end
end)

health:Set(75)
```

The callback receives the current dependency values in the same order they are passed to the `dependencies` table, and the result behaves like any other reactive state value.

### Mounting GUIs

Flux supports all three GUI types. You are responsible for cloning templates before passing them in, allowing you to build UI in Roblox Studio — Flux takes ownership of the instance you provide.

#### ScreenGui
```lua
local gui = template:Clone()
local controller = Flux:MountScreenGui(gui)
```

#### SurfaceGui
```lua
local gui = template:Clone()
local controller = Flux:MountSurfaceGui(gui, partAdornee, Enum.NormalId.Front)
```

#### BillboardGui
```lua
local gui = template:Clone()
local controller = Flux:MountBillboardGui(gui, partAdornee)
```

### Binding State to UI

Use `controller:Bind()` to reactively update UI elements:

```lua
controller:Bind(health, function(hp: number)
    local healthBar = controller:GetInstance():FindFirstChild("HealthBar")
    if healthBar and healthBar:IsA("Frame") then
        healthBar.Size = UDim2.fromScale(hp / 100, 1)
    end
end)
```

The callback fires immediately with the current value and then again whenever the state changes.

For common cases where a state value maps directly to a single instance property, use `BindProperty` as a shorthand:

```lua
local label = controller:GetInstance():FindFirstChild("CoinsLabel") :: TextLabel
local frame = controller:GetInstance():FindFirstChild("HealthBar") :: Frame

controller:BindProperty(coins, label, "Text")
controller:BindProperty(visible, frame, "Visible")
```

`BindProperty` works the same way inside components via `scope:BindProperty`. Use `Bind` with a callback when you need to transform the value or update multiple properties at once.

### Event Handling

Use `BindEvent` to connect instance events that automatically disconnect on unmount:

```lua
local button = controller:GetInstance():FindFirstChild("PlayButton") :: TextButton
controller:BindEvent(button, "MouseButton1Click", function()
    print("Play clicked")
end)
```

Inside components, use `scope:BindEvent` for the same lifecycle-safe behavior.

### Conditional Rendering

Use `MountWhen` to mount a component only while a boolean state is true:

```lua
local isTooltipOpen = Flux:State(false)
local tooltip = controller:GetInstance():FindFirstChild("Tooltip")

if tooltip then
    controller:MountWhen(isTooltipOpen, TooltipComponent, tooltip)
end

isTooltipOpen:Set(true)  -- mounts component
isTooltipOpen:Set(false) -- unmounts component and cleans bindings/events
```

Inside components, `scope:MountWhen` enables the same pattern for nested UI trees. When the condition changes back to `true`, the component mounts again with a fresh scope.

### Animation

Use `Flux:Tween` or `Flux:Spring` to get an animated state that smoothly follows a source state. Both return an `AnimatedState` that works transparently with `BindProperty` and `Bind`. Call `Destroy` on it when you're done.

#### Tween

Interpolates toward the source value using `TweenInfo` for timing and easing. Supports `number` and any Roblox type with a `:Lerp` method (UDim2, Vector2, Vector3, Color3, CFrame, UDim). Note: TweenInfo `RepeatCount`, `Reverses`, and `DelayTime` properties are not supported and will be ignored.

```lua
local health = Flux:State(100)
local animHealth = Flux:Tween(health, TweenInfo.new(0.4, Enum.EasingStyle.Quad))

local bar = controller:GetInstance():FindFirstChild("HealthBar") :: Frame
controller:BindProperty(animHealth, bar, "Size")

health:Set(50) -- bar smoothly shrinks over 0.4s

-- Clean up when done
animHealth:Destroy()
controller:Unmount() -- or Destroy
```

#### Spring

Drives the value with spring physics — naturally overshoots when underdamped, settles cleanly when critically damped. **Supports** `number`, Vector2, Vector3, Color3, and UDim2 (not CFrame). The internal `Heartbeat` connection is only active while the spring is moving.

```lua
local open = Flux:State(UDim2.fromScale(0, 0))
-- speed = 20 (snappy), damping = 1 (critically damped, no overshoot)
local animOpen = Flux:Spring(open, 20, 1)

local panel = controller:GetInstance():FindFirstChild("Panel") :: Frame
controller:BindProperty(animOpen, panel, "Size")

open:Set(UDim2.fromScale(1, 1)) -- panel springs open

-- Clean up when done
animOpen:Destroy()
controller:Unmount() -- or Destroy
```

Typical damping values: `1.0` = critically damped (no overshoot), `0.7` = slightly bouncy, `0.5` = noticeably springy.

### Accessing GUI Elements

Access GUI elements through `controller:GetInstance()`:

```lua
-- Get a direct child
local frame = controller:GetInstance():FindFirstChild("Frame")

-- Find a nested descendant
local deepChild = controller:GetInstance():FindFirstChild("DeepChild", true)
```

Always check if instances exist before using them.

### Components

Create reusable components for common UI patterns:

```lua
type Properties = {
    health: Flux.State<number>,
    maxHealth: number?
}

local function HealthBar(instance: Instance, scope: Flux.Scope, properties: Properties)
    local maxHealth = properties.maxHealth or 100
    
    scope:Bind(properties.health, function(hp: number)
        local bar: Frame = instance :: Frame
        bar.Size = UDim2.fromScale(hp / maxHealth, 1)
        
        -- Color based on health
        if hp < maxHealth * 0.3 then
            bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        elseif hp < maxHealth * 0.6 then
            bar.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        else
            bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        end
    end)
end

-- Use the component
local healthState = Flux:State(100)
local healthBarFrame = controller:GetInstance():FindFirstChild("HealthBarFrame")
if healthBarFrame then
    controller:Mount(HealthBar, healthBarFrame, {
        health = healthState,
        maxHealth = 100
    })
end
```

Components receive a `Scope` that automatically cleans up bindings when the parent controller is unmounted/destroyed.

### Nested Components

Components can mount other components, creating a hierarchy that automatically cleans up when the parent controller is destroyed:

```lua
-- Child component: displays a single stat
local function StatDisplay(instance: Instance, scope: Flux.Scope, properties: {
    label: string,
    value: Flux.State<number>
})
    scope:Bind(properties.value, function(val: number)
        local label = instance:FindFirstChild("Label")
        local valueLabel = instance:FindFirstChild("Value")
        
        if label and label:IsA("TextLabel") then
            label.Text = properties.label
        end
        if valueLabel and valueLabel:IsA("TextLabel") then
            valueLabel.Text = tostring(val)
        end
    end)
end

-- Parent component: mounts multiple StatDisplay components
local function PlayerStats(instance: Instance, scope: Flux.Scope, properties: {
    health: Flux.State<number>,
    mana: Flux.State<number>,
    coins: Flux.State<number>
})
    local container = instance:FindFirstChild("Container")
    if not container then return end
    
    -- Mount child components using the parent's scope
    local healthFrame = container:FindFirstChild("HealthFrame")
    if healthFrame then
        scope:Mount(StatDisplay, healthFrame, {
            label = "Health",
            value = properties.health
        })
    end
    
    local manaFrame = container:FindFirstChild("ManaFrame")
    if manaFrame then
        scope:Mount(StatDisplay, manaFrame, {
            label = "Mana",
            value = properties.mana
        })
    end
    
    local coinsFrame = container:FindFirstChild("CoinsFrame")
    if coinsFrame then
        scope:Mount(StatDisplay, coinsFrame, {
            label = "Coins",
            value = properties.coins
        })
    end
end

-- Usage: all nested components clean up when controller unmounts
local healthState = Flux:State(100)
local manaState = Flux:State(50)
local coinsState = Flux:State(0)

local statsPanel = controller:GetInstance():FindFirstChild("StatsPanel")
if statsPanel then
    controller:Mount(PlayerStats, statsPanel, {
        health = healthState,
        mana = manaState,
        coins = coinsState
    })
end

-- Later: controller:Unmount() cleans up ALL components and bindings
```

When you call `controller:Unmount()`, it automatically cleans up:
- All bindings in `PlayerStats`
- All three `StatDisplay` child components and their bindings
- Any deeper nested components

This cascading cleanup prevents memory leaks in complex component hierarchies.

### Compose Components

Use `Flux:Compose()` to combine multiple components into one reusable component.
Composed components run in order and receive the same `instance`, `scope`, and `properties`.

```lua
local FancyButton = Flux:Compose({
    HoverEffect,
    ClickEffect,
    PulseEffect,
})

local button = controller:GetInstance():FindFirstChild("PlayButton")
if button then
    controller:Mount(FancyButton, button, {
        accent = Color3.fromRGB(0, 170, 255),
    })
end
```

### Cleanup

Always call `Unmount()` (or the compatibility alias `Destroy()`) when you're done with a GUI controller:

```lua
controller:Unmount() -- or controller:Destroy()
```

This destroys the GUI instance and disconnects all bindings, preventing memory leaks.

`Flux:Tween` and `Flux:Spring` return an `AnimatedState` that holds a `Heartbeat` connection (active while animating) and an observer on the source state. You **must** call `:Destroy()` when finished — it is not owned or cleaned up by the controller automatically:

```lua
local health = Flux:State(100)
local animHealth = Flux:Tween(health, TweenInfo.new(0.4))

controller:BindProperty(animHealth, bar, "Size")

-- Clean up when tearing down
controller:Destroy()
animHealth:Destroy()
health:Destroy()
```

Animation constraints and behavior:
- `TweenInfo.RepeatCount`, `Reverses`, and `DelayTime` are ignored by `Flux:Tween`
- `Flux:Spring(source, speed, damping)` requires `speed > 0` and `damping >= 0`
- `Spring` requires a non-nil initial source value
- `Tween` and `Spring` expect source values to keep a consistent value type over time
- `AnimatedState:Destroy()` is idempotent (safe to call more than once)

If a `State` or `Computed` is no longer needed, call `:Destroy()` and release references to it.

## Best Practices

1. **Always teardown controllers** - Call `controller:Unmount()` or `controller:Destroy()` when done
2. **Check for nil** - Always check if `FindFirstChild()` returns a valid instance
3. **Use components** - Encapsulate reusable UI behavior in component functions
4. **One state, many bindings** - Multiple UI elements can bind to the same state
5. **Destroy temporary state** - Call `:Destroy()` on short-lived `State`, `Computed`, and `AnimatedState` values
6. **Organize state** - Keep related state together in a module