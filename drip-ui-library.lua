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
local DRAG_TWEEN = TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0.05)
local INDICATOR_TWEEN = TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

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
	if type(lucideModule) ~= "table" then
		error("DripUI:SetLucide expects the Lucide module table", 2)
	end

	self._lucide = lucideModule
	return self
end

function DripUI:CreateWindow(options)
	options = options or {}
	local theme = mergeTheme(options.Theme)
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
		Size = options.Size or UDim2.fromOffset(720, 450),
		Parent = root,
	})
	applyCorner(frame, 14)
	applyStroke(frame, 0.78)

	local topBar = make("Frame", {
		Name = "TopBar",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 54),
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
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(0, 192, 1, -54),
		Parent = frame,
	})
	applyCorner(tabRail, 14)

	make("Frame", {
		Name = "RailTopFill",
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = tabRail,
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
		Position = UDim2.fromOffset(10, 8),
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.7,
		ScrollBarThickness = 2,
		Size = UDim2.new(1, -16, 1, -16),
		Parent = tabRail,
	})

	local activeTabIndicator = make("Frame", {
		Name = "ActiveTabIndicator",
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(5, 24),
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
		Position = UDim2.fromOffset(192, 54),
		Size = UDim2.new(1, -192, 1, -54),
		Parent = frame,
	})

	local dragging = false
	local dragStart
	local dragWindowPosition
	local dragTween

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

	UserInputService.InputChanged:Connect(function(input)
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
		_lucide = self._lucide,
		_root = root,
		_tabs = {},
		_tabRail = tabRail,
		_tabList = tabList,
		_activeTabIndicator = activeTabIndicator,
		_contentArea = contentArea,
		_activeTab = nil,
	}, Window)

	tabList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if windowObject._activeTab then
			windowObject:_moveActiveIndicator(windowObject._activeTab, true)
		end
	end)

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
		Position = UDim2.fromOffset(5, math.floor(centerY + 0.5)),
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
			BackgroundTransparency = active and 0.92 or 1,
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
		Position = UDim2.fromOffset(10, 10),
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.74,
		ScrollBarThickness = 2,
		Size = UDim2.new(1, -20, 1, -20),
		Parent = page,
	})

	make("UIPadding", {
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 2),
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
		if self._activeTab ~= tabObject then
			tween(button, HOVER_TWEEN, { BackgroundTransparency = 0.975 })
		end
	end)

	button.MouseLeave:Connect(function()
		if self._activeTab ~= tabObject then
			tween(button, HOVER_TWEEN, { BackgroundTransparency = 1 })
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

function Window:Destroy()
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
