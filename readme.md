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

Use [`latte-soft/lucide-roblox`](https://github.com/latte-soft/lucide-roblox) in your game (for example inside `ReplicatedStorage`):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lucide = require(ReplicatedStorage:WaitForChild("Lucide"))

Drip:SetLucide(Lucide)
```

## Quick Example

```lua
local Drip = loadstring(game:HttpGet("https://raw.githubusercontent.com/Young-Apfelmus/Drip-Library/main/drip-ui-library.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lucide = require(ReplicatedStorage:WaitForChild("Lucide"))

Drip:SetLucide(Lucide)
local icon = Drip.icon

local window = Drip:CreateWindow({
	Title = "Drip UI",
	Subtitle = "Black / White",
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
