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
- `Size` (`UDim2`) default `UDim2.fromOffset(720, 450)`
- `Position` (`UDim2`) default centered
- `Parent` (`Instance`) custom GUI parent
- `DisplayOrder` (number) default `500`
- `Theme` (table) optional color overrides

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

---

## 6. Tab API

## `Tab:Section(text)`

Adds a section header label.

## `Tab:Label(text)`

Adds a plain info label line.

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
