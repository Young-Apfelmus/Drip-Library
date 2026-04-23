local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local DripUI = {}
DripUI.__index = DripUI
DripUI._lucide = nil

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local BASE_TWEEN = TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOVER_TWEEN = TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FAST_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TOGGLE_TWEEN = TweenInfo.new(0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local DRAG_TWEEN = TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local INDICATOR_TWEEN = TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local DEFAULT_TOGGLE_BIND = Enum.KeyCode.RightShift
local DEFAULT_KEYBINDER_BIND = Enum.KeyCode.E
local TYPEWRITER_STEP_DELAY = 0.07
local TYPEWRITER_START_DELAY = 0.35
local TYPEWRITER_DELETE_STEP_DELAY = 0.05
local TYPEWRITER_HOLD_DELAY = 0.9
local TYPEWRITER_EMPTY_HOLD_DELAY = 0.25
local TYPEWRITER_CURSOR = "|"
local COLORPICKER_TWEEN = TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local DEFAULT_THEME = {
	Background = Color3.fromRGB(8, 8, 8),
	Panel = Color3.fromRGB(16, 16, 16),
	Surface = Color3.fromRGB(12, 12, 12),
	Accent = Color3.fromRGB(255, 255, 255),
	TextStrong = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(232, 232, 232),
	TextMuted = Color3.fromRGB(180, 180, 180),
	StrokeTransparency = 0.84,
}

local LUCIDE_REMOTE_SOURCES = {
	"https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau",
	"https://raw.githubusercontent.com/latte-soft/lucide-roblox/master/lucide-roblox.luau",
}

local HAS_CANVAS_GROUP = pcall(function()
	local probe = Instance.new("CanvasGroup")
	probe:Destroy()
end)

local function make(className, properties)
	local instance = Instance.new(className)
	for key, value in pairs(properties or {}) do
		instance[key] = value
	end
	return instance
end

local function applyCorner(instance, radius)
	return make("UICorner", {
		CornerRadius = UDim.new(0, radius or 8),
		Parent = instance,
	})
end

local function applyStroke(instance, transparency)
	return make("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = transparency,
		Parent = instance,
	})
end

local function tween(instance, tweenInfo, properties)
	local animation = TweenService:Create(instance, tweenInfo, properties)
	animation:Play()
	return animation
end

local function parseIconName(inputValue)
	if type(inputValue) == "table" and type(inputValue.__drip_icon) == "string" then
		return inputValue.__drip_icon
	end

	if type(inputValue) == "string" then
		return inputValue
	end

	return nil
end

local function normalizeKeyCodeName(name)
	return string.lower((name or ""):gsub("[%s_%-]", ""))
end

local function parseKeyCode(bindValue, fallback)
	if typeof(bindValue) == "EnumItem" and bindValue.EnumType == Enum.KeyCode then
		return bindValue
	end

	if type(bindValue) == "string" and bindValue ~= "" then
		local direct = Enum.KeyCode[bindValue]
		if direct then
			return direct
		end

		local normalized = normalizeKeyCodeName(bindValue)
		for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
			if normalizeKeyCodeName(keyCode.Name) == normalized then
				return keyCode
			end
		end
	end

	return fallback
end

local function parseToggleBind(bindValue)
	return parseKeyCode(bindValue, DEFAULT_TOGGLE_BIND)
end

local function fetchRemoteText(url)
	local okHttpGetMethod, httpGetMethod = pcall(function()
		return game.HttpGet
	end)

	if okHttpGetMethod and type(httpGetMethod) == "function" then
		local ok, body = pcall(httpGetMethod, game, url)
		if ok and type(body) == "string" and body ~= "" then
			return body
		end
	end

	local okHttpGetCall, bodyFromCall = pcall(function()
		return game:HttpGet(url)
	end)
	if okHttpGetCall and type(bodyFromCall) == "string" and bodyFromCall ~= "" then
		return bodyFromCall
	end

	local requestMethods = {}
	if type(request) == "function" then
		table.insert(requestMethods, request)
	end
	if type(http_request) == "function" then
		table.insert(requestMethods, http_request)
	end
	if type(syn) == "table" and type(syn.request) == "function" then
		table.insert(requestMethods, syn.request)
	end
	if type(http) == "table" and type(http.request) == "function" then
		table.insert(requestMethods, http.request)
	end

	for _, requestFn in ipairs(requestMethods) do
		local ok, response = pcall(requestFn, {
			Url = url,
			Method = "GET",
		})

		if ok and type(response) == "table" then
			local body = response.Body or response.body
			local statusCode = response.StatusCode or response.Status
			if type(body) == "string" and body ~= "" and (statusCode == nil or statusCode == 200) then
				return body
			end
		end
	end

	return nil
end

local function formatRuntime(seconds)
	local clamped = math.max(0, math.floor(seconds))
	local hours = math.floor(clamped / 3600)
	local minutes = math.floor((clamped % 3600) / 60)
	local secs = clamped % 60
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function colorToRgb(color)
	return math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5)
end

local function clampUnit(value)
	return math.clamp(tonumber(value) or 0, 0, 1)
end

local function makeLoadInConfig(animationOptions)
	local config = type(animationOptions) == "table" and animationOptions or {}

	return {
		Enabled = config.Enabled ~= false,
		Duration = tonumber(config.Duration) or 0.55,
		FromScale = tonumber(config.FromScale) or 0.92,
		FromOffsetY = tonumber(config.FromOffsetY) or 16,
		EasingStyle = config.EasingStyle or Enum.EasingStyle.Quart,
		EasingDirection = config.EasingDirection or Enum.EasingDirection.Out,
	}
end

local function resolveLucideExport(moduleResult)
	if type(moduleResult) ~= "table" then
		return nil
	end

	if type(moduleResult.ImageLabel) == "function" then
		return moduleResult
	end

	local nestedKeys = { "Lucide", "default", "Icons", "Module" }
	for _, key in ipairs(nestedKeys) do
		local nested = moduleResult[key]
		if type(nested) == "table" and type(nested.ImageLabel) == "function" then
			return nested
		end
	end

	return nil
end

local function safeCallback(callback, ...)
	if type(callback) ~= "function" then
		return
	end

	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[DripUI] Callback failed:", err)
	end
end

local function resolveGuiParent(overrideParent)
	if typeof(overrideParent) == "Instance" then
		return overrideParent
	end

	local ok, hiddenGui = pcall(function()
		if gethui then
			return gethui()
		end
	end)

	if ok and typeof(hiddenGui) == "Instance" then
		return hiddenGui
	end

	local player = Players.LocalPlayer
	if player then
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			return playerGui
		end
	end

	return CoreGui
end

local function icon(name)
	return {
		__drip_icon = tostring(name),
	}
end

DripUI.icon = icon

do
	local ok, environment = pcall(function()
		if getgenv then
			return getgenv()
		end
		return _G
	end)

	if ok and type(environment) == "table" and environment.icon == nil then
		environment.icon = icon
	end
end

local function mergeTheme(overrides)
	local merged = {}
	for key, value in pairs(DEFAULT_THEME) do
		merged[key] = value
	end

	if type(overrides) == "table" then
		for key, value in pairs(overrides) do
			merged[key] = value
		end
	end

	return merged
end

function DripUI:SetLucide(lucideModule)
	local resolved = resolveLucideExport(lucideModule)
	if not resolved then
		error("DripUI:SetLucide expects the Lucide module table", 2)
	end

	self._lucide = resolved
	return self
end

function DripUI:_tryLoadLucideFromGitHub()
	if type(loadstring) ~= "function" then
		return nil
	end

	for _, sourceUrl in ipairs(LUCIDE_REMOTE_SOURCES) do
		local source = fetchRemoteText(sourceUrl)
		if source then
			local okLoad, chunkOrError = pcall(loadstring, source)
			if okLoad and type(chunkOrError) == "function" then
				local okRun, moduleResult = pcall(chunkOrError)
				if okRun then
					local resolved = resolveLucideExport(moduleResult)
					if resolved then
						return resolved
					end
				end
			end
		end
	end

	return nil
end

function DripUI:AutoLoadLucide()
	if self._lucide then
		return self._lucide
	end

	local fromGithub = self:_tryLoadLucideFromGitHub()
	if fromGithub then
		self._lucide = fromGithub
		return self._lucide
	end

	return nil
end

function DripUI:CreateWindow(options)
	options = options or {}
	local theme = mergeTheme(options.Theme)
	self:AutoLoadLucide()
	local isMobile = UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled or not UserInputService.MouseEnabled)
	local topBarHeight = options.TopBarHeight or (isMobile and 50 or 54)
	local railWidth = options.TabRailWidth or options.RailWidth or (isMobile and 154 or 186)
	local railBottomInset = options.TabRailBottomInset or 6
	local profileCardHeight = isMobile and 56 or 58
	local defaultSize = isMobile and UDim2.fromScale(0.9, 0.74) or UDim2.fromOffset(620, 390)
	local loadInConfig = makeLoadInConfig(options.LoadInAnimation or options.LoadIn or options.Animation)
	local root = make("ScreenGui", {
		Name = options.Name or "DripLibrary",
		DisplayOrder = options.DisplayOrder or 500,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	root.Parent = resolveGuiParent(options.Parent)

	local frame = make("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = options.Position or UDim2.fromScale(0.5, 0.5),
		Size = options.Size or defaultSize,
		Parent = root,
	})
	applyCorner(frame, 14)
	applyStroke(frame, 0.78)

	local topBar = make("Frame", {
		Name = "TopBar",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, topBarHeight),
		Parent = frame,
	})
	applyCorner(topBar, 14)

	make("Frame", {
		Name = "TopBarFill",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = topBar,
	})

	make("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(16, 9),
		Size = UDim2.new(1, -32, 0, 20),
		Text = tostring(options.Title or "Drip UI Library"),
		TextColor3 = theme.TextStrong,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topBar,
	})

	make("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Position = UDim2.fromOffset(16, 28),
		Size = UDim2.new(1, -32, 0, 18),
		Text = tostring(options.Subtitle or "Black / White Theme"),
		TextColor3 = theme.TextMuted,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topBar,
	})

	local tabRail = make("Frame", {
		Name = "TabRail",
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(0, topBarHeight),
		Size = UDim2.new(0, railWidth, 1, -(topBarHeight + railBottomInset)),
		Parent = frame,
	})

	make("Frame", {
		Name = "RailDivider",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -1, 0, 8),
		Size = UDim2.new(0, 1, 1, -16),
		Parent = tabRail,
	})

	local tabList = make("ScrollingFrame", {
		Name = "TabList",
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		Position = UDim2.fromOffset(8, 8),
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.7,
		ScrollBarThickness = 2,
		Size = UDim2.new(1, -14, 1, -(profileCardHeight + 24)),
		Parent = tabRail,
	})

	local localPlayer = Players.LocalPlayer
	local profileCard = make("Frame", {
		Name = "ProfileCard",
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8),
		Size = UDim2.new(1, -16, 0, profileCardHeight),
		Parent = tabRail,
	})
	applyCorner(profileCard, 6)
	applyStroke(profileCard, 0.78)

	local avatarImage = make("ImageLabel", {
		Name = "Avatar",
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(8, 11),
		Size = UDim2.fromOffset(36, 36),
		Image = "",
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Parent = profileCard,
	})
	applyCorner(avatarImage, 4)

	local usernameLabel = make("TextLabel", {
		Name = "Username",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Position = UDim2.fromOffset(52, 10),
		Size = UDim2.new(1, -68, 0, 17),
		Text = "",
		TextColor3 = theme.TextStrong,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = profileCard,
	})

	local runtimeLabel = make("TextLabel", {
		Name = "Runtime",
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Position = UDim2.fromOffset(52, 29),
		Size = UDim2.new(1, -68, 0, 16),
		Text = "Uptime 00:00:00",
		TextColor3 = theme.TextMuted,
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = profileCard,
	})

	if localPlayer then
		avatarImage.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100", localPlayer.UserId)
	end

	local usernameSource = localPlayer and ("@" .. localPlayer.Name) or "@unknown"
	local usernameTypeToken = 0

	local function playUsernameTypewriter(text)
		usernameTypeToken = usernameTypeToken + 1
		local token = usernameTypeToken
		local fullText = tostring(text or "@unknown")

		usernameLabel.Text = ""
		for index = 1, #fullText do
			if token ~= usernameTypeToken or not root.Parent or not usernameLabel.Parent then
				return
			end

			local withCursor = index < #fullText
			usernameLabel.Text = string.sub(fullText, 1, index) .. (withCursor and TYPEWRITER_CURSOR or "")
			task.wait(TYPEWRITER_STEP_DELAY)
		end

		if token == usernameTypeToken and usernameLabel.Parent then
			usernameLabel.Text = fullText
		end

		task.wait(TYPEWRITER_HOLD_DELAY)

		for index = #fullText, 0, -1 do
			if token ~= usernameTypeToken or not root.Parent or not usernameLabel.Parent then
				return
			end

			if index == 0 then
				usernameLabel.Text = ""
			else
				usernameLabel.Text = string.sub(fullText, 1, index) .. TYPEWRITER_CURSOR
			end
			task.wait(TYPEWRITER_DELETE_STEP_DELAY)
		end

		task.wait(TYPEWRITER_EMPTY_HOLD_DELAY)
	end

	task.spawn(function()
		task.wait(TYPEWRITER_START_DELAY)
		while root.Parent do
			playUsernameTypewriter(usernameSource)
		end
	end)

	local activeTabIndicator = make("Frame", {
		Name = "ActiveTabIndicator",
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(8, 24),
		Size = UDim2.fromOffset(3, 18),
		Visible = false,
		ZIndex = 3,
		Parent = tabRail,
	})
	applyCorner(activeTabIndicator, 2)

	local tabListLayout = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabList,
	})

	tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabList.CanvasSize = UDim2.fromOffset(0, tabListLayout.AbsoluteContentSize.Y + 8)
	end)

	local contentArea = make("Frame", {
		Name = "ContentArea",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(railWidth, topBarHeight),
		Size = UDim2.new(1, -railWidth, 1, -topBarHeight),
		Parent = frame,
	})

	local dragging = false
	local dragStart
	local dragWindowPosition
	local dragTween
	local scriptStartTime = os.clock()
	local toggleBind = parseToggleBind(options.ToggleBind or options.toggleBind or options.UiToggleBind or options.HideBind)
	local dragInputConnection
	local toggleInputConnection

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		dragStart = input.Position
		dragWindowPosition = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragTween = nil
			end
		end)
	end)

	dragInputConnection = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart
		local targetPosition = UDim2.new(
			dragWindowPosition.X.Scale,
			dragWindowPosition.X.Offset + delta.X,
			dragWindowPosition.Y.Scale,
			dragWindowPosition.Y.Offset + delta.Y
		)

		if dragTween then
			dragTween:Cancel()
		end

		dragTween = tween(frame, DRAG_TWEEN, {
			Position = targetPosition,
		})
	end)

	local windowObject = setmetatable({
		_theme = theme,
		_library = self,
		_lucide = self._lucide,
		_root = root,
		_frame = frame,
		_tabs = {},
		_tabRail = tabRail,
		_tabList = tabList,
		_activeTabIndicator = activeTabIndicator,
		_contentArea = contentArea,
		_activeTab = nil,
		_isVisible = true,
		_toggleBind = toggleBind,
		_dragInputConnection = dragInputConnection,
		_toggleInputConnection = nil,
		_connections = {},
		_isMobile = isMobile,
		_loadInConfig = loadInConfig,
	}, Window)

	windowObject:_trackConnection(dragInputConnection)

	toggleInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if UserInputService:GetFocusedTextBox() then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == windowObject._toggleBind then
			windowObject:SetVisible(not windowObject._isVisible)
		end
	end)
	windowObject._toggleInputConnection = toggleInputConnection
	windowObject:_trackConnection(toggleInputConnection)

	tabList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if windowObject._activeTab then
			windowObject:_moveActiveIndicator(windowObject._activeTab, true)
		end
	end)

	task.spawn(function()
		while root.Parent do
			runtimeLabel.Text = "Uptime " .. formatRuntime(os.clock() - scriptStartTime)
			task.wait(1)
		end
	end)

	windowObject:PlayLoadIn(loadInConfig)

	return windowObject
end

function Window:_tweenIconColor(iconObject, color)
	if not iconObject then
		return
	end

	if iconObject:IsA("ImageLabel") or iconObject:IsA("ImageButton") then
		tween(iconObject, BASE_TWEEN, { ImageColor3 = color })
	elseif iconObject:IsA("TextLabel") or iconObject:IsA("TextButton") then
		tween(iconObject, BASE_TWEEN, { TextColor3 = color })
	end
end

function Window:_renderTabIcon(iconName, parent, iconSize)
	local size = iconSize or 18
	local lucide = self._lucide
	if not lucide and self._library then
		lucide = self._library:AutoLoadLucide()
		self._lucide = lucide
	end

	if type(iconName) == "string" and iconName ~= "" and type(lucide) == "table" and type(lucide.ImageLabel) == "function" then
		local ok, iconObject = pcall(lucide.ImageLabel, iconName, size, {
			BackgroundTransparency = 1,
			ImageColor3 = self._theme.TextMuted,
			Size = UDim2.fromOffset(size, size),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Parent = parent,
		})

		if ok and typeof(iconObject) == "Instance" then
			iconObject.Name = "Icon"
			iconObject.Parent = parent
			return iconObject
		end
	end

	if type(iconName) == "string" and iconName ~= "" then
		return make("TextLabel", {
			Name = "IconFallback",
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Size = UDim2.fromOffset(size, size),
			Text = string.upper(string.sub(iconName, 1, 1)),
			TextColor3 = self._theme.TextMuted,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = parent,
		})
	end

	return nil
end

function Window:_moveActiveIndicator(tabObject, instant)
	if not tabObject or not self._activeTabIndicator or not self._tabRail then
		return
	end

	local button = tabObject.TabButton
	if not button then
		return
	end

	local centerY = (button.AbsolutePosition.Y - self._tabRail.AbsolutePosition.Y) + (button.AbsoluteSize.Y * 0.5)
	local target = {
		Position = UDim2.fromOffset(8, math.floor(centerY + 0.5)),
		Size = UDim2.fromOffset(3, math.max(14, button.AbsoluteSize.Y - 16)),
		BackgroundTransparency = 0,
	}

	self._activeTabIndicator.Visible = true

	if instant then
		for key, value in pairs(target) do
			self._activeTabIndicator[key] = value
		end
	else
		tween(self._activeTabIndicator, INDICATOR_TWEEN, target)
	end
end

function Window:_activateTab(tabObject)
	if self._activeTab == tabObject then
		return
	end

	for _, tab in ipairs(self._tabs) do
		local active = tab == tabObject
		tab.Page.Visible = active

		if tab.Page:IsA("CanvasGroup") then
			if active then
				tab.Page.GroupTransparency = 1
				tween(tab.Page, TweenInfo.new(0.52, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					GroupTransparency = 0,
				})
			else
				tab.Page.GroupTransparency = 1
			end
		end

		tween(tab.TabButton, BASE_TWEEN, {
			BackgroundTransparency = 1,
		})

		tween(tab.TitleLabel, BASE_TWEEN, {
			TextColor3 = active and self._theme.TextStrong or self._theme.TextMuted,
		})

		self:_tweenIconColor(tab.IconObject, active and self._theme.TextStrong or self._theme.TextMuted)
	end

	self._activeTab = tabObject
	self:_moveActiveIndicator(tabObject, false)
end

function Window:Tab(nameOrOptions, maybeIcon)
	local options = {}
	if type(nameOrOptions) == "table" then
		options = nameOrOptions
	else
		options.Title = tostring(nameOrOptions or ("Tab " .. tostring(#self._tabs + 1)))
		options.Icon = maybeIcon
	end

	local title = tostring(options.Title or options.title or options.Name or ("Tab " .. tostring(#self._tabs + 1)))
	local iconName = parseIconName(options.Icon or options.icon or maybeIcon)
	local tabOrder = #self._tabs + 1

	local button = make("TextButton", {
		Name = title .. "Button",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -6, 0, 38),
		Text = "",
		LayoutOrder = tabOrder,
		Parent = self._tabList,
	})

	local iconHolder = make("Frame", {
		Name = "IconHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Parent = button,
	})

	local iconObject = self:_renderTabIcon(iconName, iconHolder, 18)
	local iconPadding = iconObject and 30 or 0

	local titleLabel = make("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Position = UDim2.new(0, 12 + iconPadding, 0, 0),
		Size = UDim2.new(1, -22 - iconPadding, 1, 0),
		Text = title,
		TextColor3 = self._theme.TextMuted,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = button,
	})

	local pageClass = HAS_CANVAS_GROUP and "CanvasGroup" or "Frame"
	local page = make(pageClass, {
		Name = title .. "Page",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = self._contentArea,
	})

	if page:IsA("CanvasGroup") then
		page.GroupTransparency = 1
	end

	local body = make("ScrollingFrame", {
		Name = "Body",
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		Position = UDim2.fromOffset(8, 10),
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.74,
		ScrollBarThickness = 2,
		Size = UDim2.new(1, -12, 1, -20),
		Parent = page,
	})

	make("UIPadding", {
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 2),
		Parent = body,
	})

	local bodyLayout = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = body,
	})

	bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		body.CanvasSize = UDim2.fromOffset(0, bodyLayout.AbsoluteContentSize.Y + 8)
	end)

	local tabObject = setmetatable({
		_window = self,
		_theme = self._theme,
		_body = body,
		_order = 0,
		TabButton = button,
		TitleLabel = titleLabel,
		IconObject = iconObject,
		Page = page,
	}, Tab)

	button.MouseEnter:Connect(function()
		tween(button, HOVER_TWEEN, { BackgroundTransparency = 1 })
		if self._activeTab ~= tabObject then
			tween(titleLabel, HOVER_TWEEN, { TextColor3 = self._theme.Text })
			self:_tweenIconColor(iconObject, self._theme.Text)
		end
	end)

	button.MouseLeave:Connect(function()
		tween(button, HOVER_TWEEN, { BackgroundTransparency = 1 })
		if self._activeTab ~= tabObject then
			tween(titleLabel, HOVER_TWEEN, { TextColor3 = self._theme.TextMuted })
			self:_tweenIconColor(iconObject, self._theme.TextMuted)
		end
	end)

	button.MouseButton1Click:Connect(function()
		self:_activateTab(tabObject)
	end)

	table.insert(self._tabs, tabObject)
	if #self._tabs == 1 then
		self:_activateTab(tabObject)
	end

	return tabObject
end

Window.CreateTab = Window.Tab

function Window:_trackConnection(connection)
	if connection then
		table.insert(self._connections, connection)
	end
	return connection
end

function Window:SetVisible(isVisible)
	self._isVisible = isVisible and true or false
	if self._frame then
		self._frame.Visible = self._isVisible
	end
	return self._isVisible
end

function Window:IsVisible()
	return self._isVisible == true
end

function Window:SetToggleBind(bindValue)
	self._toggleBind = parseToggleBind(bindValue)
	return self._toggleBind
end

function Window:GetToggleBind()
	return self._toggleBind or DEFAULT_TOGGLE_BIND
end

function Window:PlayLoadIn(animationOptions)
	if not self._frame then
		return
	end

	local config = makeLoadInConfig(animationOptions or self._loadInConfig)
	self._loadInConfig = config

	if not config.Enabled then
		return
	end

	local scale = self._frame:FindFirstChild("DripLoadScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "DripLoadScale"
		scale.Parent = self._frame
	end

	local startPosition = self._frame.Position
	scale.Scale = config.FromScale
	self._frame.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset,
		startPosition.Y.Scale,
		startPosition.Y.Offset + config.FromOffsetY
	)

	local tweenInfo = TweenInfo.new(config.Duration, config.EasingStyle, config.EasingDirection)
	tween(scale, tweenInfo, { Scale = 1 })
	tween(self._frame, tweenInfo, { Position = startPosition })
end

function Window:Destroy()
	for _, connection in ipairs(self._connections or {}) do
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
	end
	self._connections = {}

	if self._root and self._root.Parent then
		self._root:Destroy()
	end
end

function Tab:_nextOrder()
	self._order = self._order + 1
	return self._order
end

function Tab:_createItemHolder(height)
	local holder = make("Frame", {
		BackgroundColor3 = self._theme.Panel,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = self:_nextOrder(),
		Parent = self._body,
	})
	applyCorner(holder, 10)
	applyStroke(holder, self._theme.StrokeTransparency)
	return holder
end

function Tab:Section(text)
	local section = make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = self:_nextOrder(),
		Text = tostring(text or "Section"),
		TextColor3 = self._theme.TextStrong,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._body,
	})
	return section
end

function Tab:Label(text)
	local label = make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = self:_nextOrder(),
		Text = tostring(text or ""),
		TextColor3 = self._theme.TextMuted,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._body,
	})
	return label
end

function Tab:Dropdown(config)
	local options = type(config) == "table" and config or { Title = tostring(config) }
	local title = tostring(options.Title or options.title or "Dropdown")
	local callback = options.Callback or options.callback
	local optionList = options.Options or options.options or {}
	local collapsedHeight = 44
	local expanded = false
	local selected = options.Default or options.default

	local holder = self:_createItemHolder(collapsedHeight)
	local headerButton = make("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, collapsedHeight),
		Text = "",
		Parent = holder,
	})

	make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -46, 0, 14),
		Text = title,
		TextColor3 = self._theme.TextStrong,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	local selectedLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Position = UDim2.fromOffset(12, 22),
		Size = UDim2.new(1, -46, 0, 14),
		Text = "",
		TextColor3 = self._theme.TextMuted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	local arrowLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Position = UDim2.new(1, -24, 0, 14),
		Size = UDim2.fromOffset(12, 16),
		Text = "v",
		TextColor3 = self._theme.TextMuted,
		TextSize = 12,
		Parent = holder,
	})

	local listFrame = make("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(8, collapsedHeight),
		Size = UDim2.new(1, -16, 0, 0),
		Visible = false,
		Parent = holder,
	})

	local listLayout = make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listFrame,
	})

	local optionButtons = {}

	local function setSelected(value, fireCallback)
		selected = value
		selectedLabel.Text = selected and tostring(selected) or "Select..."
		if fireCallback then
			safeCallback(callback, selected)
		end
	end

	local function renderOptions()
		for _, button in ipairs(optionButtons) do
			if button.Parent then
				button:Destroy()
			end
		end
		optionButtons = {}

		for index, value in ipairs(optionList) do
			local optionButton = make("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = self._theme.Panel,
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0,
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, 28),
				Text = tostring(value),
				TextColor3 = self._theme.Text,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				Parent = listFrame,
			})
			applyCorner(optionButton, 6)

			optionButton.MouseButton1Click:Connect(function()
				setSelected(value, true)
				expanded = false
				arrowLabel.Text = "v"
				listFrame.Visible = false
				tween(holder, BASE_TWEEN, { Size = UDim2.new(1, 0, 0, collapsedHeight) })
				tween(listFrame, BASE_TWEEN, { Size = UDim2.new(1, -16, 0, 0) })
			end)

			table.insert(optionButtons, optionButton)
		end
	end

	renderOptions()
	if selected == nil and optionList[1] ~= nil then
		selected = optionList[1]
	end
	setSelected(selected, false)

	local function setExpanded(newState)
		expanded = newState and true or false
		arrowLabel.Text = expanded and "^" or "v"
		local optionsHeight = math.min(6, #optionList) * 32
		local targetListHeight = expanded and optionsHeight or 0
		local targetHolderHeight = collapsedHeight + targetListHeight + (expanded and 8 or 0)
		listFrame.Visible = expanded
		tween(holder, BASE_TWEEN, { Size = UDim2.new(1, 0, 0, targetHolderHeight) })
		tween(listFrame, BASE_TWEEN, { Size = UDim2.new(1, -16, 0, targetListHeight) })
	end

	headerButton.MouseButton1Click:Connect(function()
		setExpanded(not expanded)
	end)

	headerButton.MouseEnter:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.84 })
	end)

	headerButton.MouseLeave:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.9 })
	end)

	return {
		Set = function(_, value, fireCallback)
			setSelected(value, fireCallback == true)
		end,
		Get = function()
			return selected
		end,
		SetOptions = function(_, nextOptions)
			optionList = nextOptions or {}
			renderOptions()
			if optionList[1] and not selected then
				setSelected(optionList[1], false)
			end
		end,
	}
end

function Tab:ColorPicker(config)
	local options = type(config) == "table" and config or { Title = tostring(config) }
	local title = tostring(options.Title or options.title or "Color")
	local callback = options.Callback or options.callback
	local currentColor = typeof(options.Default) == "Color3" and options.Default or Color3.fromRGB(255, 255, 255)
	local hue, saturation, value = currentColor:ToHSV()
	local collapsedHeight = 44
	local pickerHeight = 166
	local pickerContentHeight = pickerHeight + 24
	local expanded = false

	local holder = self:_createItemHolder(collapsedHeight)
	holder.ClipsDescendants = true
	local headerButton = make("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, collapsedHeight),
		Text = "",
		Parent = holder,
	})

	make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Position = UDim2.fromOffset(12, 13),
		Size = UDim2.new(1, -90, 0, 16),
		Text = title,
		TextColor3 = self._theme.TextStrong,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	local preview = make("Frame", {
		BackgroundColor3 = currentColor,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -40, 0, 10),
		Size = UDim2.fromOffset(24, 24),
		Parent = holder,
	})
	applyCorner(preview, 6)
	applyStroke(preview, 0.72)

	local pickerFrame = make("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(10, collapsedHeight),
		Size = UDim2.new(1, -20, 0, 0),
		Visible = false,
		Parent = holder,
	})

	local pickerContent = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = pickerFrame,
	})

	local saturationValueArea = make("Frame", {
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(1, -34, 0, pickerHeight),
		Parent = pickerContent,
	})
	applyCorner(saturationValueArea, 10)
	applyStroke(saturationValueArea, 0.76)

	local saturationOverlay = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = saturationValueArea,
	})
	applyCorner(saturationOverlay, 10)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = saturationOverlay,
	})

	local valueOverlay = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = saturationValueArea,
	})
	applyCorner(valueOverlay, 10)
	make("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = valueOverlay,
	})

	local saturationValueCursor = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 4,
		Parent = saturationValueArea,
	})
	applyCorner(saturationValueCursor, 7)
	make("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(0, 0, 0),
		Transparency = 0.16,
		Thickness = 1,
		Parent = saturationValueCursor,
	})

	local hueBar = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -22, 0, 2),
		Size = UDim2.fromOffset(22, pickerHeight),
		Parent = pickerContent,
	})
	applyCorner(hueBar, 11)
	applyStroke(hueBar, 0.76)
	make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hueBar,
	})

	local hueCursor = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, hue, 0),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 4,
		Parent = hueBar,
	})
	applyCorner(hueCursor, 9)
	make("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(0, 0, 0),
		Transparency = 0.16,
		Thickness = 1,
		Parent = hueCursor,
	})

	local valueLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Position = UDim2.fromOffset(0, pickerHeight + 8),
		Size = UDim2.new(1, 0, 0, 14),
		Text = "",
		TextColor3 = self._theme.TextMuted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = pickerContent,
	})

	local function emitColorChanged(fireCallback)
		if fireCallback then
			safeCallback(callback, Color3.fromHSV(hue, saturation, value))
		end
	end

	local function updatePickerVisuals()
		local color = Color3.fromHSV(hue, saturation, value)
		local r, g, b = colorToRgb(color)

		preview.BackgroundColor3 = color
		saturationValueArea.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		saturationValueCursor.Position = UDim2.new(clampUnit(saturation), 0, clampUnit(1 - value), 0)
		hueCursor.Position = UDim2.new(0.5, 0, clampUnit(hue), 0)
		valueLabel.Text = string.format("#%02X%02X%02X  (%d, %d, %d)", r, g, b, r, g, b)
	end

	local function setColor(color, fireCallback)
		if typeof(color) ~= "Color3" then
			return
		end

		hue, saturation, value = color:ToHSV()
		updatePickerVisuals()
		emitColorChanged(fireCallback)
	end

	local function bindDrag(guiObject, updateFromPosition)
		guiObject.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			local moveConnection
			local endConnection

			updateFromPosition(input.Position, true)

			moveConnection = UserInputService.InputChanged:Connect(function(changedInput)
				if changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch then
					updateFromPosition(changedInput.Position, true)
				end
			end)

			endConnection = UserInputService.InputEnded:Connect(function(endedInput)
				if endedInput.UserInputType == Enum.UserInputType.MouseButton1 or endedInput.UserInputType == Enum.UserInputType.Touch then
					if moveConnection then
						moveConnection:Disconnect()
					end
					if endConnection then
						endConnection:Disconnect()
					end
				end
			end)
		end)
	end

	bindDrag(saturationValueArea, function(pointerPosition, fireCallback)
		local x = (pointerPosition.X - saturationValueArea.AbsolutePosition.X) / math.max(1, saturationValueArea.AbsoluteSize.X)
		local y = (pointerPosition.Y - saturationValueArea.AbsolutePosition.Y) / math.max(1, saturationValueArea.AbsoluteSize.Y)
		saturation = clampUnit(x)
		value = 1 - clampUnit(y)
		updatePickerVisuals()
		emitColorChanged(fireCallback)
	end)

	bindDrag(hueBar, function(pointerPosition, fireCallback)
		local y = (pointerPosition.Y - hueBar.AbsolutePosition.Y) / math.max(1, hueBar.AbsoluteSize.Y)
		hue = clampUnit(y)
		updatePickerVisuals()
		emitColorChanged(fireCallback)
	end)

	updatePickerVisuals()

	local expandToken = 0
	local function setExpanded(newState)
		expandToken = expandToken + 1
		local token = expandToken
		expanded = newState and true or false
		local targetHeight = expanded and (collapsedHeight + pickerContentHeight + 8) or collapsedHeight

		if expanded then
			pickerFrame.Visible = true
			pickerFrame.Position = UDim2.fromOffset(10, collapsedHeight + 4)
			tween(holder, COLORPICKER_TWEEN, { Size = UDim2.new(1, 0, 0, targetHeight) })
			tween(pickerFrame, COLORPICKER_TWEEN, {
				Position = UDim2.fromOffset(10, collapsedHeight),
				Size = UDim2.new(1, -20, 0, pickerContentHeight),
			})
		else
			tween(holder, COLORPICKER_TWEEN, { Size = UDim2.new(1, 0, 0, targetHeight) })
			tween(pickerFrame, COLORPICKER_TWEEN, {
				Position = UDim2.fromOffset(10, collapsedHeight + 4),
				Size = UDim2.new(1, -20, 0, 0),
			})
			task.delay(COLORPICKER_TWEEN.Time + 0.03, function()
				if token ~= expandToken or expanded then
					return
				end
				pickerFrame.Visible = false
				pickerFrame.Position = UDim2.fromOffset(10, collapsedHeight)
			end)
		end
	end

	headerButton.MouseButton1Click:Connect(function()
		setExpanded(not expanded)
	end)

	headerButton.MouseEnter:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.84 })
	end)

	headerButton.MouseLeave:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.9 })
	end)

	return {
		Set = function(_, color, fireCallback)
			setColor(color, fireCallback == true)
		end,
		Get = function()
			return Color3.fromHSV(hue, saturation, value)
		end,
	}
end

function Tab:KeyBinder(config)
	local options = type(config) == "table" and config or { Title = tostring(config) }
	local title = tostring(options.Title or options.title or "KeyBinder")
	local callback = options.Callback or options.callback
	local changedCallback = options.ChangedCallback or options.Changed or options.changed
	local listening = false
	local boundKey = parseKeyCode(options.Default or options.default or options.Key or options.key, DEFAULT_KEYBINDER_BIND)

	local holder = self:_createItemHolder(44)
	local captureButton = make("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = holder,
	})

	make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Position = UDim2.fromOffset(12, 13),
		Size = UDim2.new(1, -90, 0, 16),
		Text = title,
		TextColor3 = self._theme.TextStrong,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	local keyLabel = make("TextLabel", {
		BackgroundColor3 = self._theme.Panel,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -72, 0, 9),
		Size = UDim2.fromOffset(58, 24),
		Text = boundKey.Name,
		TextColor3 = self._theme.Text,
		TextSize = 11,
		Font = Enum.Font.GothamSemibold,
		Parent = holder,
	})
	applyCorner(keyLabel, 6)

	local function setBoundKey(nextKey, fireChanged)
		boundKey = parseKeyCode(nextKey, DEFAULT_KEYBINDER_BIND)
		listening = false
		keyLabel.Text = boundKey.Name
		keyLabel.TextColor3 = self._theme.Text
		if fireChanged then
			safeCallback(changedCallback, boundKey)
		end
	end

	captureButton.MouseButton1Click:Connect(function()
		listening = true
		keyLabel.Text = "..."
		keyLabel.TextColor3 = self._theme.TextStrong
	end)

	captureButton.MouseEnter:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.84 })
	end)

	captureButton.MouseLeave:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.9 })
	end)

	local keyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if listening then
			setBoundKey(input.KeyCode, true)
			return
		end

		if UserInputService:GetFocusedTextBox() then
			return
		end

		if gameProcessed then
			return
		end

		if input.KeyCode == boundKey then
			safeCallback(callback, boundKey)
		end
	end)
	self._window:_trackConnection(keyConnection)

	return {
		Set = function(_, nextKey)
			setBoundKey(nextKey, true)
		end,
		Get = function()
			return boundKey
		end,
	}
end

function Tab:Paragraph(config)
	local options = type(config) == "table" and config or { Text = tostring(config) }
	local title = tostring(options.Title or options.title or "Paragraph")
	local text = tostring(options.Text or options.text or "")

	local holder = self:_createItemHolder(80)
	holder.AutomaticSize = Enum.AutomaticSize.Y

	make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 18),
		Text = title,
		TextColor3 = self._theme.TextStrong,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	local body = make("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Position = UDim2.fromOffset(12, 28),
		Size = UDim2.new(1, -24, 0, 0),
		Text = text,
		TextColor3 = self._theme.TextMuted,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = holder,
	})

	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		holder.Size = UDim2.new(1, 0, 0, body.AbsoluteSize.Y + 36)
	end)

	return holder
end

function Tab:Button(config)
	local options = type(config) == "table" and config or { Title = tostring(config) }
	local title = tostring(options.Title or options.title or options.Text or "Button")
	local description = options.Description or options.description
	local callback = options.Callback or options.callback
	local height = description and 62 or 44

	local holder = self:_createItemHolder(height)
	local button = make("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = holder,
	})

	make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Position = UDim2.fromOffset(12, description and 8 or 12),
		Size = UDim2.new(1, -24, 0, 16),
		Text = title,
		TextColor3 = self._theme.TextStrong,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	if description then
		make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(12, 28),
			Size = UDim2.new(1, -24, 0, 24),
			Text = tostring(description),
			TextColor3 = self._theme.TextMuted,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = holder,
		})
	end

	button.MouseEnter:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.84 })
	end)

	button.MouseLeave:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.9 })
	end)

	button.MouseButton1Down:Connect(function()
		tween(holder, FAST_TWEEN, { BackgroundTransparency = 0.78 })
	end)

	button.MouseButton1Up:Connect(function()
		tween(holder, FAST_TWEEN, { BackgroundTransparency = 0.84 })
	end)

	button.MouseButton1Click:Connect(function()
		safeCallback(callback)
	end)

	return button
end

function Tab:Toggle(config)
	local options = type(config) == "table" and config or { Title = tostring(config) }
	local title = tostring(options.Title or options.title or "Toggle")
	local description = options.Description or options.description
	local callback = options.Callback or options.callback
	local state = options.Default == true or options.default == true
	local height = description and 64 or 46

	local holder = self:_createItemHolder(height)
	local clickTarget = make("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = holder,
	})

	make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Position = UDim2.fromOffset(12, description and 9 or 14),
		Size = UDim2.new(1, -86, 0, 14),
		Text = title,
		TextColor3 = self._theme.TextStrong,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	if description then
		make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Position = UDim2.fromOffset(12, 30),
			Size = UDim2.new(1, -86, 0, 22),
			Text = tostring(description),
			TextColor3 = self._theme.TextMuted,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = holder,
		})
	end

	local switch = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(42, 22),
		Parent = holder,
	})
	applyCorner(switch, 11)
	applyStroke(switch, 0.72)

	local knob = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(16, 16),
		Parent = switch,
	})
	applyCorner(knob, 8)

	local function setState(newState, fireCallback)
		state = newState and true or false

		tween(switch, TOGGLE_TWEEN, {
			BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30),
		})

		tween(knob, TOGGLE_TWEEN, {
			BackgroundColor3 = state and Color3.fromRGB(12, 12, 12) or Color3.fromRGB(255, 255, 255),
			Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
		})

		if fireCallback then
			safeCallback(callback, state)
		end
	end

	setState(state, false)

	clickTarget.MouseEnter:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.84 })
	end)

	clickTarget.MouseLeave:Connect(function()
		tween(holder, HOVER_TWEEN, { BackgroundTransparency = 0.9 })
	end)

	clickTarget.MouseButton1Click:Connect(function()
		setState(not state, true)
	end)

	return {
		Set = function(_, newState)
			setState(newState, true)
		end,
		Get = function()
			return state
		end,
	}
end

return DripUI
