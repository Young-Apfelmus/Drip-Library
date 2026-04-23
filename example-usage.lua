local Drip = loadstring(game:HttpGet("https://raw.githubusercontent.com/Young-Apfelmus/Drip-Library/main/drip-ui-library.lua"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lucide = require(ReplicatedStorage:WaitForChild("Lucide"))

Drip:SetLucide(Lucide)

local icon = Drip.icon

local window = Drip:CreateWindow({
	Title = "Drip Library",
	Subtitle = "Black / White + Lucide",
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

local settings = window:Tab({
	Title = "Settings",
	Icon = icon "settings",
})

settings:Paragraph({
	Title = "Info",
	Text = "Import lucide-roblox in your place and call Drip:SetLucide(Lucide) once before creating tabs.",
})
