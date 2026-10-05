local UserInputService = game:GetService("UserInputService")
local C = require(script.Parent.Parent.UI.Components)
local Audio = require(game.ReplicatedStorage.Shared.Config.Audio)
local Settings = require(game.ReplicatedStorage.Shared.AudioSettings)
local UI = {}
function UI.Create(parent, remote, audio)
	local desired = Settings.Sanitize(nil, Audio.Defaults)
	local pending, scheduled, loaded = nil, false, false
	local rows = {}
	local function draw()
		for _, row in ipairs(rows) do
			local volume, muted = desired[row.Volume], desired[row.Mute]
			row.Value.Text = tostring(math.floor(volume * 100 + 0.5)) .. "%"
			row.Fill.Size = UDim2.fromScale(volume, 1)
			row.Knob.Position = UDim2.fromScale(volume, 0.5)
			row.Toggle.Text = row.Title .. (if muted then ": MUTED" else ": ON")
		end
	end
	local function change(key, value)
		if not loaded then
			return
		end
		desired[key] = value
		pending = table.clone(desired)
		audio:ApplySettings(desired)
		draw()
		if not scheduled then
			scheduled = true
			task.delay(1.1, function()
				scheduled = false
				remote:FireServer(table.clone(desired))
			end)
		end
	end
	for i, title in ipairs({ "Music", "SFX" }) do
		local volume, mute = title .. "Volume", title .. "Muted"
		local card = C.Card(parent, C.Blue)
		card.Name, card.Size, card.LayoutOrder = title .. "Audio", UDim2.new(1, -18, 0, 164), i + 1
		C.Text(card, title .. " volume", UDim2.new(1, -100, 0, 28), UDim2.fromOffset(12, 10), 23).TextXAlignment =
			Enum.TextXAlignment.Left
		local value = C.Text(card, "", UDim2.fromOffset(70, 28), UDim2.new(1, -82, 0, 10), 22)
		local track = C.New("TextButton", card, {
			Name = title .. "Slider",
			Text = "",
			AutoButtonColor = false,
			Active = true,
			Size = UDim2.new(1, -132, 0, 44),
			Position = UDim2.fromOffset(66, 50),
			BackgroundColor3 = C.Ink,
		})
		C.Round(track, C.Muted, 10, 1)
		local fill = C.New("Frame", track, { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Blue })
		C.New("UICorner", fill, { CornerRadius = UDim.new(0, 10) })
		local knob = C.New("Frame", track, {
			Name = "Knob",
			Size = UDim2.fromOffset(12, 32),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
		})
		C.Round(knob, C.Ink, 6, 1)
		local decrease = C.Button(card, "-", UDim2.fromOffset(44, 44), UDim2.fromOffset(12, 50), function()
			change(volume, math.max(0, desired[volume] - 0.05))
		end, C.Blue, { Name = title .. "Decrease" })
		local increase = C.Button(card, "+", UDim2.fromOffset(44, 44), UDim2.new(1, -56, 0, 50), function()
			change(volume, math.min(1, desired[volume] + 0.05))
		end, C.Blue, { Name = title .. "Increase" })
		local toggle = C.Button(card, "", UDim2.new(1, -24, 0, 44), UDim2.fromOffset(12, 106), function()
			change(mute, not desired[mute])
		end, C.Green, { Name = title .. "Mute", TextSize = 20 })
		table.insert(rows, {
			Title = title,
			Volume = volume,
			Mute = mute,
			Value = value,
			Fill = fill,
			Knob = knob,
			Toggle = toggle,
			Decrease = decrease,
			Increase = increase,
		})
		decrease.Interactable, increase.Interactable, toggle.Interactable = false, false, false
		local dragging
		local function pointer(input)
			if track.AbsoluteSize.X > 0 then
				local ratio = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
				change(volume, math.floor(math.clamp(ratio, 0, 1) * 100 + 0.5) / 100)
			end
		end
		track.InputBegan:Connect(function(input)
			if
				loaded
				and not dragging
				and (
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				dragging = input
				parent.ScrollingEnabled = false
				pointer(input)
			end
		end)
		local moved = UserInputService.InputChanged:Connect(function(input)
			if
				dragging
				and (
					input == dragging
					or (
						dragging.UserInputType == Enum.UserInputType.MouseButton1
						and input.UserInputType == Enum.UserInputType.MouseMovement
					)
				)
			then
				pointer(input)
			end
		end)
		local ended = UserInputService.InputEnded:Connect(function(input)
			if input == dragging then
				dragging = nil
				parent.ScrollingEnabled = true
			end
		end)
		track.Destroying:Connect(function()
			moved:Disconnect()
			ended:Disconnect()
		end)
	end
	draw()
	return {
		Update = function(raw)
			loaded = true
			for _, row in ipairs(rows) do
				row.Decrease.Interactable, row.Increase.Interactable, row.Toggle.Interactable = true, true, true
			end
			local saved = Settings.Sanitize(raw, Audio.Defaults)
			local matches = true
			for key, value in pairs(pending or {}) do
				if saved[key] ~= value then
					matches = false
				end
			end
			if pending and matches then
				pending = nil
			end
			desired = pending or saved
			audio:ApplySettings(desired)
			draw()
		end,
	}
end
return UI
