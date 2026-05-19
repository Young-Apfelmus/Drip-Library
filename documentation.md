# Drip Library Documentation

## 1. Overview

`drip-ui-library.lua` returns a table called `DripUI`.

Core goals:

- Black/white theme by default
- Smooth, slower tweens for tab switches and UI interactions
- Tab icon integration with `lucide-roblox`
- Support for `icon "icon-name"` shorthand

---

## 2. Loading

```lua
local Drip = loadstring(game:HttpGet("https://raw.githubusercontent.com/Young-Apfelmus/Drip-Library/main/drip-ui-library.lua"))()
```

---

## 3. Lucide Integration

For executor usage, auto-load [`lucide-roblox`](https://github.com/latte-soft/lucide-roblox) from the GitHub release source:

```lua
local Lucide = Drip:AutoLoadLucide()
if not Lucide then
	warn("Failed to load lucide-roblox from GitHub")
end
```

The library uses `Lucide.ImageLabel(iconName, imageSize, overrides)` internally for tab icons.

If Lucide is not set, tabs still work and fall back to a text initial icon.

---

## 4. API

## `Drip:SetLucide(lucideModule)`

Registers the Lucide module table.

- `lucideModule` must be the required module from `lucide-roblox`.

Returns: `Drip` (chainable)

## `Drip:AutoLoadLucide()`

Attempts to load lucide-roblox from official GitHub release source using executor HTTP APIs.

Returns: Lucide table on success, `nil` on failure.

## `Drip.icon(name)`

Builds an icon token used by tabs.

Returns: `{ __drip_icon = "name" }`

You can use it in Lua shorthand style:

```lua
local icon = Drip.icon
window:Tab("Main", icon "home")
```

`icon` is also exported globally (if not already defined) for direct use.

## `Drip:CreateWindow(options)`

Creates a draggable window and returns a `Window` object.

`options` fields:

- `Title` (string) window title
- `Subtitle` (string) subtitle below title
- `Size` (`UDim2`) default desktop `UDim2.fromOffset(620, 390)` with mobile-responsive scale fallback
- `Position` (`UDim2`) default centered
- `Parent` (`Instance`) custom GUI parent
- `DisplayOrder` (number) default `500`
- `Theme` (table) optional color overrides
- `ToggleBind` (`Enum.KeyCode` or string) hide/unhide bind, default `Enum.KeyCode.RightShift`
- `TabRailBottomInset` (number) optional bottom inset to keep left-bottom rounded corner clean
- `LoadInAnimation` (table) window intro animation settings
  - `Enabled` (boolean)
  - `Duration` (number)
  - `FromScale` (number)
  - `FromOffsetY` (number)

Returns: `Window`

---

## 5. Window API

## `Window:Tab(title, iconTokenOrString)`

Creates a tab and returns a `Tab` object.

Examples:

```lua
local tabA = window:Tab("Main", icon "home")
local tabB = window:Tab("Visuals", "sparkles")
```

## `Window:Tab(optionsTable)`

Alternative tab creation with table:

```lua
local tab = window:Tab({
	Title = "Settings",
	Icon = icon "settings",
})
```

## `Window.CreateTab`

Alias of `Window:Tab`.

## `Window:Destroy()`

Destroys the root `ScreenGui`.

## `Window:SetToggleBind(bindValue)`

Sets runtime hide/unhide keybind. Accepts `Enum.KeyCode` or key name string.

## `Window:GetToggleBind()`

Returns current hide/unhide keybind.

## `Window:SetVisible(boolean)`

Shows or hides the UI window.

## `Window:IsVisible()`

Returns whether the UI window is currently visible.

## `Window:PlayLoadIn(animationOptions?)`

Plays/replays smooth load-in animation and optionally overrides animation config.

---

## 6. Tab API

## `Tab:Section(text)`

Adds a section header label.

## `Tab:Label(text)`

Adds a plain info label line.

## `Tab:Dropdown({ Title, Options, Default?, Callback? })`

Adds an expandable dropdown selector.

Returns controller:

- `controller:Set(value, fireCallback?)`
- `controller:Get()`
- `controller:SetOptions(newOptions)`

## `Tab:ColorPicker({ Title, Default?, Callback? })`

Adds an expandable rounded HSV color picker (saturation/value canvas + hue bar).

Returns controller:

- `controller:Set(Color3, fireCallback?)`
- `controller:Get()` -> `Color3`

## `Tab:KeyBinder({ Title, Default?, Callback?, ChangedCallback? })`

Adds a keybind control that captures **keyboard keys and mouse buttons**.

Supported mouse bindings:

| Display | UserInputType |
|---|---|
| `RMB` | `MouseButton2` — Right click |
| `Thumb` | `MouseButton3` — Middle / thumb click |

> LMB is excluded (it's used to click the binder).  
> Press `Escape` while listening to cancel without changing the binding.

The binding is a table: `{ kind = "key"|"mouse", value = EnumItem, name = string }`

Returns controller:

- `controller:Set(Enum.KeyCode | Enum.UserInputType | bindingTable)`
- `controller:Get()` → binding table

`ChangedCallback(binding)` receives the full binding table.

```lua
aTab:KeyBinder({
    Title   = "Aim Key",
    Default = Enum.KeyCode.Q,
    ChangedCallback = function(binding)
        -- binding.kind  = "key" or "mouse"
        -- binding.value = EnumItem
        -- binding.name  = "Q", "RMB", "Thumb", "MB4", "MB5" …
        cfg.aimBinding = binding
    end,
})
```

## `Tab:Slider({ Title, Min?, Max?, Step?, Default?, Suffix?, Description?, Callback? })`

Adds a draggable horizontal slider with a fill bar, knob, and live value label.

Config fields:

- `Title` (string)
- `Description` (string, optional) — adds a subtitle line and increases row height
- `Min` (number, default `0`)
- `Max` (number, default `100`)
- `Step` (number, default `1`) — snapping increment; supports decimals (e.g. `0.5`)
- `Default` (number, default `Min`)
- `Suffix` (string, optional) — appended to the value label, e.g. `" px"` or `"%"`
- `Callback(value)` — fires on every drag tick with the snapped number value

Returns controller:

- `controller:Set(value, fireCallback?)` — programmatically set the value
- `controller:Get()` → current snapped number value

Example:

```lua
local smooth = tab:Slider({
    Title    = "Smooth Speed",
    Description = "1 = slow · 30 = instant",
    Min      = 1,
    Max      = 30,
    Step     = 1,
    Default  = 10,
    Callback = function(v)
        cfg.smoothSpeed = v
    end,
})

-- Read or set later:
print(smooth:Get())
smooth:Set(15)
```

---

## `Tab:Paragraph({ Title, Text })`

Adds a multi-line block with title + wrapped body text.

## `Tab:Button({ Title, Description?, Callback? })`

Adds a clickable button.

- `Callback()` runs when clicked.

## `Tab:Toggle({ Title, Description?, Default?, Callback? })`

Adds a toggle switch.

- `Default` defaults to `false`.
- `Callback(state)` runs on each state change.

Returns a controller table:

- `controller:Set(boolean)` set state and fire callback
- `controller:Get()` read current state

---

## 7. Animation Behavior

- Tab changes animate with slower fade transitions.
- Button hover/press uses smooth tween steps.
- Toggle switch knob and color transitions are tweened.

---

## 8. Full Example

See `example-usage.lua` in this repository for a ready-to-run script.
