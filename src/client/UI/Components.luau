local TweenService = game:GetService("TweenService")
local Visuals = require(game.ReplicatedStorage.Shared.Config.Visuals)
local Assets = require(game.ReplicatedStorage.Shared.Config.Assets)
local Layout = require(script.Parent.Layout)
local C = {
	Navy = Visuals.Palette.Navy,
	Font = Enum.Font.FredokaOne,
	Ink = Color3.fromRGB(9, 16, 32),
	Blue = Color3.fromRGB(28, 163, 245),
	Green = Color3.fromRGB(54, 206, 91),
	Gold = Color3.fromRGB(255, 193, 47),
	Purple = Color3.fromRGB(160, 82, 240),
	Muted = Color3.fromRGB(173, 196, 218),
}
local white = Color3.new(1, 1, 1)
local tweens = setmetatable({}, { __mode = "k" })
function C.Commas(value)
	return (tostring(math.floor(value)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
function C.New(class, parent, props)
	local object = Instance.new(class)
	if object:IsA("GuiObject") then
		object.BorderSizePixel = 0
		object.ZIndex = if parent and parent:IsA("GuiObject") then parent.ZIndex + 2 else 1
	end
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end
function C.Place(object, r)
	object.Position = UDim2.fromOffset(r.X + r.W * object.AnchorPoint.X, r.Y + r.H * object.AnchorPoint.Y)
	object.Size = UDim2.fromOffset(r.W, r.H)
end
function C.Tween(object, duration, props, style)
	if tweens[object] then
		tweens[object]:Cancel()
	end
	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	)
	tweens[object] = tween
	tween:Play()
	return tween
end
function C.Round(object, color, radius, thickness)
	C.New("UICorner", object, { CornerRadius = UDim.new(0, radius or 12) })
	return C.New(
		"UIStroke",
		object,
		{ ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color or C.Ink, Thickness = thickness or 3 }
	)
end
function C.Outline(object, thickness)
	object.TextStrokeTransparency = 1
	return C.New(
		"UIStroke",
		object,
		{ ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = C.Ink, Thickness = thickness or 2 }
	)
end
function C.Gradient(object, color)
	return C.New(
		"UIGradient",
		object,
		{ Color = ColorSequence.new(color:Lerp(white, 0.28), color:Lerp(C.Ink, 0.18)), Rotation = 90 }
	)
end
function C.Chrome(object, color, glossy)
	object.BackgroundTransparency = 1
	local shadow = C.New("Frame", object, {
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 5),
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.22,
		ZIndex = object.ZIndex,
	})
	C.New("UICorner", shadow, { CornerRadius = UDim.new(0, 14) })
	local background = C.New(
		"Frame",
		object,
		{ Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = white, ZIndex = object.ZIndex + 1 }
	)
	C.Round(background)
	C.Gradient(background, color or C.Navy)
	local inset = C.New("Frame", background, {
		Name = "Inset",
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		BackgroundTransparency = 1,
		ZIndex = background.ZIndex,
	})
	C.Round(inset, white, 9, 1).Transparency = 0.76
	if glossy then
		local gloss = C.New("Frame", background, {
			Name = "Gloss",
			Size = UDim2.new(1, -12, 0.38, 0),
			Position = UDim2.fromOffset(6, 5),
			BackgroundColor3 = white,
			BackgroundTransparency = 0.82,
			ZIndex = background.ZIndex,
		})
		C.New("UICorner", gloss, { CornerRadius = UDim.new(0, 8) })
		C.New("UIGradient", gloss, { Rotation = 90, Transparency = NumberSequence.new(0.1, 1) })
	end
	return background
end
function C.Text(parent, text, size, position, maxSize)
	local label = C.New("TextLabel", parent, {
		Text = text,
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		TextColor3 = white,
		Font = C.Font,
		TextScaled = true,
		TextWrapped = true,
	})
	C.New("UITextSizeConstraint", label, { MaxTextSize = maxSize or 28, MinTextSize = 10 })
	C.Outline(label)
	return label
end
function C.BodyText(parent, text, size, position)
	local label = C.Text(parent, text, size, position, 17)
	label.Font = Enum.Font.BuilderSansBold
	label.TextColor3 = C.Muted
	label.UIStroke.Thickness = 1
	return label
end
function C.Pop(object)
	local scale = object:FindFirstChild("PopScale") or C.New("UIScale", object, { Name = "PopScale" })
	scale.Scale = 0.88
	C.Tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end
function C.Shine(object)
	local old = object:FindFirstChild("Shine")
	if old then
		old:Destroy()
	end
	local shine = C.New("Frame", object, {
		Name = "Shine",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = white,
		BackgroundTransparency = 0.65,
		ZIndex = object.ZIndex + 1,
	})
	C.New("UICorner", shine, { CornerRadius = UDim.new(0, 12) })
	local gradient = C.New("UIGradient", shine, {
		Rotation = 20,
		Offset = Vector2.new(-1, 0),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})
	C.Tween(gradient, 0.8, { Offset = Vector2.new(1, 0) }).Completed:Once(function()
		shine:Destroy()
	end)
end
function C.Button(parent, text, size, position, callback, color, options)
	options = options or {}
	local button = C.New("TextButton", parent, {
		Name = options.Name or text,
		Text = text,
		TextTransparency = 1,
		AutoButtonColor = false,
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		Font = C.Font,
	})
	C.Chrome(button, color or C.Blue, true)
	local label = C.Text(button, text, UDim2.fromScale(0.88, 0.76), UDim2.fromScale(0.06, 0.12), options.TextSize or 26)
	label.Name = "Label"
	if options.Icon then
		C.Icon(button, options.Icon, UDim2.fromScale(0.24, 0.72), UDim2.fromScale(0.04, 0.14))
		label.Position, label.Size = UDim2.fromScale(0.29, 0.12), UDim2.fromScale(0.66, 0.76)
	end
	local scale = C.New("UIScale", button, { Name = "PressScale", Scale = 1 })
	local function animate(value)
		C.Tween(scale, 0.12, { Scale = value })
	end
	button:GetPropertyChangedSignal("Text"):Connect(function()
		label.Text = button.Text
	end)
	button:GetPropertyChangedSignal("Interactable"):Connect(function()
		label.TextTransparency = if button.Interactable then 0 else 0.4
		if not button.Interactable then
			animate(1)
		end
	end)
	button.MouseEnter:Connect(function()
		if button.Interactable then
			animate(1.035)
			if C.SoundHook then
				C.SoundHook("Hover")
			end
		end
	end)
	button.MouseLeave:Connect(function()
		animate(1)
	end)
	local function press(input, value)
		if
			button.Interactable
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			animate(value)
		end
	end
	button.InputBegan:Connect(function(input)
		press(input, 0.95)
	end)
	button.InputEnded:Connect(function(input)
		press(input, 1)
	end)
	button.Activated:Connect(function()
		if not button.Interactable then
			return
		end
		if C.SoundHook then
			C.SoundHook(options.Sound or "Click")
		end
		callback()
	end)
	button.Destroying:Connect(function()
		if tweens[scale] then
			tweens[scale]:Cancel()
		end
	end)
	return button
end
function C.AssetId(value)
	if type(value) == "number" and value > 0 and value < math.huge then
		return "rbxassetid://" .. tostring(value)
	end
	if type(value) == "string" and value ~= "" and value ~= "0" and value ~= "rbxassetid://0" then
		return value
	end
	return nil
end
local ResolvedIcons = require(script.Parent.ResolvedIcons)
function C.PreloadIcons()
	ResolvedIcons.Start()
end
function C.Icon(parent, kind, size, position, assetId, tint)
	local icon = C.New(
		"Frame",
		parent,
		{ Name = kind .. "Icon", Size = size, Position = position or UDim2.new(), BackgroundTransparency = 1 }
	)
	C.New("UIAspectRatioConstraint", icon, { AspectRatio = 1 })
	local fallback =
		C.New("Frame", icon, { Name = "Fallback", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	require(script.Parent.IconArt).Draw(C, fallback, kind, tint)
	local source = assetId or (Assets.Icons or {})[kind]
	local id = C.AssetId(source)
	if id then
		local image = C.New("ImageLabel", icon, {
			Name = "Asset",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = ResolvedIcons.Get(source) or "",
			ScaleType = Enum.ScaleType.Fit,
			ImageRectOffset = Vector2.new(0, 0),
			ImageRectSize = Vector2.new(0, 0),
			ResampleMode = Enum.ResamplerMode.Default,
			ImageColor3 = white,
			-- Stay render-eligible: invisible labels can keep IsLoaded false after preloading.
			ImageTransparency = 0.999,
			ZIndex = fallback.ZIndex + 10,
		})
		local function loaded()
			image.ImageTransparency = if image.Image ~= "" and image.IsLoaded then 0 else 0.999
			fallback.Visible = image.Image == "" or not image.IsLoaded
		end
		local disconnect = ResolvedIcons.Observe(source, function(resolved)
			if image.Image ~= (resolved or "") then
				image.Image = resolved or ""
			end
			loaded()
		end)
		icon.Destroying:Connect(disconnect)
		image:GetPropertyChangedSignal("IsLoaded"):Connect(loaded)
		loaded()
	end
	return icon
end
function C.StatusIcons(parent, size, position)
	local lock = C.Icon(parent, "Lock", size, position)
	local check = C.Icon(parent, "Check", size, position)
	check.Visible = false
	return function(locked, checked)
		lock.Visible, check.Visible = locked, checked
	end
end
function C.Card(parent, color, rare)
	local card = C.New("Frame", parent, { BackgroundTransparency = 1 })
	local background = C.Chrome(card, (color or C.Blue):Lerp(C.Navy, 0.82))
	background.UIStroke.Color = color or C.Blue
	if rare then
		local glow = C.New("Frame", card, {
			Name = "Glow",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(-3, -3),
			Size = UDim2.new(1, 6, 1, 6),
			ZIndex = card.ZIndex,
		})
		C.Round(glow, color, 15, 6).Transparency = 0.8
	end
	return card
end
function C.Pill(parent, text, color, size, position)
	local pill = C.New("Frame", parent, {
		Size = size or UDim2.fromOffset(150, 36),
		Position = position or UDim2.new(),
		BackgroundColor3 = color or C.Navy,
	})
	C.Round(pill, C.Ink, 12, 2)
	local label = C.Text(pill, text, UDim2.new(1, -12, 1, -6), UDim2.fromOffset(6, 3), 18)
	return pill, label
end
C.Chip = C.Pill
function C.Badge(parent, count)
	local badge, label =
		C.Pill(parent, tostring(count), Color3.fromRGB(244, 55, 77), UDim2.fromOffset(26, 26), UDim2.new(1, -18, 0, -8))
	badge.Name, badge.ZIndex, label.ZIndex = "ClaimBadge", parent.ZIndex + 12, parent.ZIndex + 14
	badge.Rotation = 8
	return {
		Frame = badge,
		Set = function(value)
			badge.Visible = value > 0
			label.Text = tostring(value)
		end,
	}
end
function C.ProgressBar(parent, size, position, color)
	local track =
		C.New("Frame", parent, { Size = size, Position = position, BackgroundColor3 = C.Ink, ClipsDescendants = true })
	C.New("UICorner", track, { CornerRadius = UDim.new(0, 7) })
	local fill = C.New("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = white })
	C.Gradient(fill, color or C.Green)
	C.New("UICorner", fill, { CornerRadius = UDim.new(0, 7) })
	local previous
	return {
		Frame = track,
		Set = function(value)
			value = math.clamp(value, 0, 1)
			if previous == value then
				return
			end
			previous = value
			C.Tween(fill, 0.2, { Size = UDim2.fromScale(value, 1) })
		end,
	}
end
function C.Scroll(parent, size, position, horizontal)
	local scroll = C.New("ScrollingFrame", parent, {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = if horizontal then Enum.AutomaticSize.X else Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = if horizontal then Enum.ScrollingDirection.X else Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.Blue,
		BorderSizePixel = 0,
	})
	C.New("UIPadding", scroll, {
		PaddingTop = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	})
	return scroll
end
function C.Grid(scroll, minimum, height, maximumColumns)
	local grid = C.New(
		"UIGridLayout",
		scroll,
		{ CellPadding = UDim2.fromOffset(14, 14), SortOrder = Enum.SortOrder.LayoutOrder }
	)
	local function resize()
		local _, width = Layout.Grid(math.max(1, scroll.AbsoluteSize.X - 24), minimum, 14, maximumColumns)
		grid.CellSize = UDim2.fromOffset(width, height)
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	return grid
end
function C.TabBar(parent, names, callback, colors)
	local row = C.Scroll(parent, UDim2.new(1, 0, 0, 60), nil, true)
	C.New("UIListLayout", row, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local buttons, selected = {}, nil
	local function selectTab(name)
		selected = name
		for key, button in pairs(buttons) do
			button.Background.UIStroke.Color = if key == name then C.Gold else C.Ink
		end
	end
	for i, name in ipairs(names) do
		buttons[name] = C.Button(row, name, UDim2.fromOffset(120, 44), nil, function()
			selectTab(name)
			callback(name)
		end, colors and colors[name], { TextSize = 18 })
		buttons[name].LayoutOrder = i
	end
	selectTab(names[1])
	return {
		Frame = row,
		Buttons = buttons,
		Select = selectTab,
		Selected = function()
			return selected
		end,
	}
end
function C.Panel(parent, title, color)
	local panel = C.New(
		"Frame",
		parent,
		{ Name = title, BackgroundTransparency = 1, Visible = false, ZIndex = 40, AnchorPoint = Vector2.new(0.5, 0.5) }
	)
	C.Chrome(panel, C.Navy)
	local bar = C.New("Frame", panel, {
		Name = "TitleBar",
		Size = UDim2.new(1, -12, 0, 58),
		Position = UDim2.fromOffset(6, 6),
		BackgroundColor3 = white,
	})
	C.New("UICorner", bar, { CornerRadius = UDim.new(0, 10) })
	C.Gradient(bar, color or C.Blue)
	C.Text(bar, title, UDim2.new(1, -78, 1, -10), UDim2.fromOffset(16, 5), 32).TextXAlignment = Enum.TextXAlignment.Left
	C.Button(bar, "X", UDim2.fromOffset(44, 44), UDim2.new(1, -51, 0, 7), function()
		panel.Visible = false
	end, Color3.fromRGB(237, 61, 78))
	local scroll = C.New("ScrollingFrame", panel, {
		Name = "ContentScroll",
		Size = UDim2.new(1, -28, 1, -88),
		Position = UDim2.fromOffset(14, 74),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.Blue,
	})
	local body = C.New("Frame", scroll, { Name = "Body", BackgroundTransparency = 1 })
	local function resize()
		local bounds = Layout.Modal(math.max(240, parent.AbsoluteSize.X), math.max(220, parent.AbsoluteSize.Y))
		C.Place(panel, bounds)
		body.Size = UDim2.new(1, -8, 0, math.max(540, bounds.H - 88))
	end
	parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if C.SoundHook then
			C.SoundHook(if panel.Visible then "Open" else "Close")
		end
		if panel.Visible then
			resize()
			C.Pop(panel)
		end
	end)
	resize()
	return panel
end
function C.Toast(parent)
	local frame, label = C.Pill(parent, "", C.Navy, UDim2.new(1, -32, 0, 58), UDim2.fromOffset(16, 68))
	frame.Visible, frame.ZIndex, label.ZIndex = false, 80, 82
	local token = 0
	return function(message, color)
		token += 1
		local current = token
		label.Text, label.TextColor3, frame.Visible = message, color or white, true
		C.Pop(frame)
		task.delay(3, function()
			if current == token then
				frame.Visible = false
			end
		end)
	end
end
return C
