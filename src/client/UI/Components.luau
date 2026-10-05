local TweenService = game:GetService("TweenService")
local Visuals = require(game.ReplicatedStorage.Shared.Config.Visuals)
local C = { Navy = Visuals.Palette.Navy, Font = Visuals.Font }
function C.Commas(value)
	return (tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
function C.New(class, parent, props)
	local object = Instance.new(class)
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	if object:IsA("GuiObject") and (not props or props.ZIndex == nil) then
		object.ZIndex = if parent:IsA("GuiObject") then parent.ZIndex + 2 else 1
	end
	object.Parent = parent
	return object
end
function C.Round(object, color)
	C.New("UICorner", object, { CornerRadius = UDim.new(0, 12) })
	return C.New(
		"UIStroke",
		object,
		{ ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color or Color3.fromRGB(84, 128, 175), Thickness = 2 }
	)
end
function C.Outline(object)
	C.New("UIStroke", object, { Color = Color3.fromRGB(9, 16, 30), Thickness = 1.5 })
end
function C.Chrome(object, color)
	object.BackgroundTransparency = 1
	local shadow = C.New("Frame", object, {
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(4, 6),
		BackgroundColor3 = Color3.fromRGB(4, 9, 19),
		BackgroundTransparency = 0.2,
		ZIndex = object.ZIndex,
	})
	C.New("UICorner", shadow, { CornerRadius = UDim.new(0, 12) })
	local background = C.New("Frame", object, {
		Name = "Background",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = object.ZIndex + 1,
	})
	C.Round(background, color)
	C.New("UIGradient", background, {
		Color = ColorSequence.new(
			(color or C.Navy):Lerp(Color3.new(1, 1, 1), 0.18),
			(color or C.Navy):Lerp(Color3.new(), 0.22)
		),
		Rotation = 90,
	})
	return background
end
function C.Text(parent, text, size, position)
	local label = C.New("TextLabel", parent, {
		Text = text,
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		Font = C.Font,
		TextScaled = true,
	})
	C.New("UITextSizeConstraint", label, { MaxTextSize = 36, MinTextSize = 8 })
	C.Outline(label)
	return label
end
function C.Button(parent, text, size, position, callback, color)
	local button = C.New("TextButton", parent, {
		Text = text,
		TextTransparency = 1,
		AutoButtonColor = false,
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		Font = C.Font,
	})
	C.Chrome(button, color or Color3.fromRGB(35, 130, 207))
	local label = C.Text(button, text, UDim2.fromScale(0.9, 0.82), UDim2.fromScale(0.05, 0.09))
	local scale = C.New("UIScale", button, { Scale = 1 })
	local active
	local function animate(value)
		if active then
			active:Cancel()
		end
		active = TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = value })
		active:Play()
	end
	button:GetPropertyChangedSignal("Text"):Connect(function()
		label.Text = button.Text
	end)
	button:GetPropertyChangedSignal("Interactable"):Connect(function()
		label.TextTransparency = if button.Interactable then 0 else 0.35
	end)
	button.MouseEnter:Connect(function()
		if button.Interactable then
			animate(1.04)
		end
	end)
	button.MouseLeave:Connect(function()
		animate(1)
	end)
	button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			animate(0.96)
		end
	end)
	button.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			animate(1)
		end
	end)
	button.Destroying:Connect(function()
		if active then
			active:Cancel()
		end
	end)
	button.Activated:Connect(callback)
	return button
end
function C.Icon(parent, kind, size, position)
	local icon = C.New("Frame", parent, { Size = size, Position = position, BackgroundTransparency = 1 })
	C.New("UIAspectRatioConstraint", icon, { AspectRatio = 1 })
	local function shape(w, h, x, y, color, round)
		local f = C.New("Frame", icon, {
			Size = UDim2.fromScale(w, h),
			Position = UDim2.fromScale(x, y),
			BackgroundColor3 = color or Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		})
		if round then
			C.New("UICorner", f, { CornerRadius = UDim.new(1, 0) })
		end
		return f
	end
	if kind == "Coins" then
		shape(0.9, 0.9, 0.05, 0.05, Visuals.Palette.Gold, true)
		local inset = shape(0.67, 0.67, 0.165, 0.165, Color3.fromRGB(255, 220, 80), true)
		C.New("UIStroke", inset, { Color = Color3.fromRGB(198, 124, 25), Thickness = 2 })
		C.Text(icon, "$", UDim2.fromScale(0.7, 0.7), UDim2.fromScale(0.15, 0.15)).TextColor3 =
			Color3.fromRGB(255, 251, 179)
	elseif kind == "Shop" then
		shape(0.65, 0.43, 0.2, 0.28)
		shape(0.12, 0.48, 0.08, 0.14).Rotation = -12
		shape(0.18, 0.18, 0.22, 0.76, nil, true)
		shape(0.18, 0.18, 0.67, 0.76, nil, true)
	elseif kind == "Collection" then
		for i = 0, 1 do
			for j = 0, 1 do
				shape(0.33, 0.35, 0.1 + i * 0.46, 0.08 + j * 0.46)
			end
		end
	elseif kind == "Teleport" then
		shape(0.73, 0.86, 0.13, 0.07, Color3.fromRGB(217, 180, 255), true)
		shape(0.4, 0.55, 0.3, 0.2, Visuals.Palette.Navy, true)
	elseif kind == "Settings" then
		for i = 0, 3 do
			shape(0.2, 0.9, 0.4, 0.05).Rotation = i * 45
		end
		shape(0.3, 0.3, 0.35, 0.35, Visuals.Palette.Navy, true)
	else
		C.Text(icon, "^", UDim2.fromScale(1, 0.7)).TextColor3 = Color3.new(1, 1, 1)
		shape(0.25, 0.48, 0.375, 0.45)
	end
	return icon
end
function C.Panel(parent, title)
	local panel = C.New("Frame", parent, {
		Size = UDim2.fromScale(0.77, 0.76),
		Position = UDim2.fromScale(0.21, 0.13),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 10,
	})
	C.Chrome(panel, C.Navy)
	C.Text(panel, title, UDim2.fromScale(0.8, 0.09), UDim2.fromScale(0.03, 0.02))
	C.Button(panel, "X", UDim2.fromScale(0.07, 0.08), UDim2.fromScale(0.91, 0.02), function()
		panel.Visible = false
	end, Color3.fromRGB(233, 55, 65))
	return panel
end
return C
