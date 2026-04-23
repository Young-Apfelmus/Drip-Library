local Drip = loadstring(game:HttpGet("https://raw.githubusercontent.com/Young-Apfelmus/Drip-Library/main/drip-ui-library.lua"))()

local lucide = Drip:AutoLoadLucide()
if not lucide then
	warn("[Drip Library] Could not load lucide-roblox from GitHub release source.")
end

local icon = Drip.icon

local window = Drip:CreateWindow({
	Title = "Drip Library",
	Subtitle = "Black / White + Lucide",
	ToggleBind = Enum.KeyCode.RightShift,
	LoadInAnimation = {
		Enabled = true,
		Duration = 0.65,
		FromScale = 0.9,
		FromOffsetY = 20,
	},
})

local main = window:Tab("Main", icon "home")
main:Section("Quick Actions")
main:Label("Tabs can use Lucide icon names with icon \"name\" syntax.")
main:Button({
	Title = "Print Hello",
	Description = "Simple callback example",
	Callback = function()
		print("Hello from Drip Library")
	end,
})

main:Toggle({
	Title = "Demo Toggle",
	Description = "Shows toggle callback behavior",
	Default = false,
	Callback = function(state)
		print("Toggle state:", state)
	end,
})

main:Dropdown({
	Title = "Theme Mode",
	Options = { "Default", "Compact", "Clean" },
	Default = "Default",
	Callback = function(selected)
		print("Dropdown selected:", selected)
	end,
})

main:ColorPicker({
	Title = "Accent Color",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(color)
		print("Color:", color)
	end,
})

main:KeyBinder({
	Title = "Action Key",
	Default = Enum.KeyCode.E,
	Callback = function(key)
		print("Key pressed:", key.Name)
	end,
	ChangedCallback = function(newKey)
		print("Key changed:", newKey.Name)
	end,
})

local settings = window:Tab({
	Title = "Settings",
	Icon = icon "settings",
})

settings:Paragraph({
	Title = "Info",
	Text = "Executor mode: icons are auto-loaded from the official lucide-roblox GitHub release source.",
})
