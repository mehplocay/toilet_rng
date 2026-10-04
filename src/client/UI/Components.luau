local C = {}
C.Navy = Color3.fromRGB(20, 30, 50)
function C.New(class, parent, props)
	local object = Instance.new(class)
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end
function C.Round(object, color)
	C.New("UICorner", object, { CornerRadius = UDim.new(0, 10) })
	C.New("UIStroke", object, { Color = color or Color3.fromRGB(75, 115, 150), Thickness = 2 })
end
function C.Text(parent, text, size, position)
	return C.New("TextLabel", parent, {
		Text = text,
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
	})
end
function C.Button(parent, text, size, position, callback, color)
	local button = C.New("TextButton", parent, {
		Text = text,
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = color or Color3.fromRGB(35, 95, 145),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
	})
	C.Round(button, color)
	button.Activated:Connect(callback)
	return button
end
function C.Panel(parent, title)
	local panel = C.New("Frame", parent, {
		Size = UDim2.fromScale(0.77, 0.76),
		Position = UDim2.fromScale(0.21, 0.13),
		BackgroundColor3 = C.Navy,
		Visible = false,
	})
	C.Round(panel)
	C.New("UIGradient", panel, { Color = ColorSequence.new(Color3.fromRGB(40, 65, 85), C.Navy), Rotation = 90 })
	C.Text(panel, title, UDim2.fromScale(0.8, 0.09), UDim2.fromScale(0.03, 0.02))
	C.Button(panel, "X", UDim2.fromScale(0.07, 0.08), UDim2.fromScale(0.91, 0.02), function()
		panel.Visible = false
	end, Color3.fromRGB(215, 55, 65))
	return panel
end
return C
