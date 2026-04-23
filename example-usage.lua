local Drip = loadstring(game:HttpGet("https://raw.githubusercontent.com/Young-Apfelmus/Drip-Library/main/drip-ui-library.lua"))()

local function loadLucide()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local lucideModule = ReplicatedStorage:FindFirstChild("Lucide")

	if lucideModule and lucideModule:IsA("ModuleScript") then
		local ok, lib = pcall(require, lucideModule)
		if ok and type(lib) == "table" then
			return lib
		end
	end

	local ok, lib = pcall(require, 15279939717)
	if ok and type(lib) == "table" then
		return lib
	end

	warn("[Drip Library] Lucide was not found. Add a ModuleScript named 'Lucide' to ReplicatedStorage, or ensure require(15279939717) works.")
	return nil
end

local Lucide = loadLucide()
if Lucide then
	Drip:SetLucide(Lucide)
end

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
