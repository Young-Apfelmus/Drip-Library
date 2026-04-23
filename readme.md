# Drip Library (Luau)

Black/white Roblox UI library with smooth slow animations and Lucide tab icon support.

## Features

- Black + white themed window, tabs, and controls
- Slower/smoother tab and control hover/click animations
- Lucide icon support for tabs through `icon "name"` syntax
- Simple control API (`Section`, `Label`, `Paragraph`, `Button`, `Toggle`)

## Install / Load

```lua
local Drip = loadstring(game:HttpGet("https://raw.githubusercontent.com/Young-Apfelmus/Drip-Library/main/drip-ui-library.lua"))()
```

## Lucide Setup

For executor usage, the library can auto-load [`latte-soft/lucide-roblox`](https://github.com/latte-soft/lucide-roblox) directly from the GitHub release source:

```lua
local Lucide = Drip:AutoLoadLucide()
if not Lucide then
	warn("Failed to load lucide-roblox from GitHub")
end
```

## Quick Example

```lua
local Drip = loadstring(game:HttpGet("https://raw.githubusercontent.com/Young-Apfelmus/Drip-Library/main/drip-ui-library.lua"))()
local Lucide = Drip:AutoLoadLucide()
if not Lucide then
	warn("Failed to load lucide-roblox from GitHub")
end
local icon = Drip.icon

local window = Drip:CreateWindow({
	Title = "Drip UI",
	Subtitle = "Black / White",
	ToggleBind = Enum.KeyCode.RightShift, -- default if omitted
})

local main = window:Tab("Main", icon "home")
main:Button({
	Title = "Example Button",
	Callback = function()
		print("clicked")
	end,
})
```

## Files

- `drip-ui-library.lua`: Main library
- `example-usage.lua`: Full usage example
- `documentation.md`: Full API + behavior docs

## Toggle Keybind

- UI hide/unhide keybind is configurable via `ToggleBind` in `CreateWindow`.
- Default bind is `Enum.KeyCode.RightShift` when not provided.
