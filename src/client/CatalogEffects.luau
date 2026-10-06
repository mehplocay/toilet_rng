-- Cosmetics stay client-local, with one bounded update loop and deterministic cleanup.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local C = require(script.Parent.UI.Components)
local Effects = {}
function Effects.Start(root, player, remotes)
	local pets, pieces, owned, mode = {}, {}, {}, "Full"
	local menu = C.Panel(root, "Celebration effects", C.Gold)
	local content = menu.ContentScroll.Body
	C.New("UIListLayout", content, { Padding = UDim.new(0, 8) })
	local selected = 0
	local toggle = C.Button(root, "Celebrate", UDim2.fromOffset(112, 36), UDim2.new(1, -124, 0, 152), function()
		menu.Visible = not menu.Visible
	end, C.Purple, { Name = "CelebrationMenu", TextSize = 16 })
	toggle.Visible = false
	for i, name in ipairs(Config.Celebrations) do
		C.Button(content, name, UDim2.new(1, -12, 0, 46), nil, function()
			selected = if selected == i then 0 else i
			menu.Visible = false
		end, C.Purple, { Name = "Celebration" .. i })
	end
	C.Button(content, "Stop celebration", UDim2.new(1, -12, 0, 46), nil, function()
		selected = 0
		menu.Visible = false
	end, C.Blue)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "LocalPassCompanions", workspace
	local function clearPieces()
		for _, piece in ipairs(pieces) do
			piece:Destroy()
		end
		table.clear(pieces)
	end
	local characters, removing = {}, {}
	local function clearOwner(owner)
		if pets[owner] then
			pets[owner]:Destroy()
			pets[owner] = nil
		end
		characters[owner] = nil
		if owner == player then
			selected = 0
			menu.Visible = false
			clearPieces()
		end
	end
	local function track(owner)
		characters[owner] = owner.Character
		removing[owner] = owner.CharacterRemoving:Connect(function()
			clearOwner(owner)
		end)
	end
	for _, owner in ipairs(Players:GetPlayers()) do
		track(owner)
	end
	local addedConnection = Players.PlayerAdded:Connect(track)
	local removingConnection = Players.PlayerRemoving:Connect(function(owner)
		clearOwner(owner)
		if removing[owner] then
			removing[owner]:Disconnect()
			removing[owner] = nil
		end
	end)
	local burstStyle = 0
	local function burst(count, gold, style)
		burstStyle = style or 0
		clearPieces()
		for i = 1, count do
			local piece = C.New("Frame", root, {
				Name = "RevealConfetti",
				Size = UDim2.fromOffset(7, 12),
				BackgroundColor3 = if gold then C.Gold else Color3.fromHSV(i / count, 0.8, 1),
				BorderSizePixel = 0,
				ZIndex = 75,
			})
			if burstStyle == 1 then
				piece.Size = UDim2.fromOffset(4, 4)
				piece.Rotation = 45
			end
			if burstStyle == 3 then
				piece.Size = UDim2.fromOffset(9, 9)
				C.New("UICorner", piece, { CornerRadius = UDim.new(1, 0) })
			end
			if burstStyle == 4 then
				piece.BackgroundTransparency = 1
				C.New("UICorner", piece, { CornerRadius = UDim.new(1, 0) })
				C.New("UIStroke", piece, { Color = piece.BackgroundColor3, Thickness = 2 })
			end
			table.insert(pieces, piece)
		end
	end
	local burstAge = 2
	local stateConnection = remotes.State.OnClientEvent:Connect(function(state)
		owned = require(game.ReplicatedStorage.Shared.MonetizationRules).Entitlements(state.OwnedPasses, Config)
		mode = (state.Settings or {}).RevealIntensity or "Full"
		toggle.Visible = owned.DancePack == true
		if not toggle.Visible or mode == "Off" then
			selected = 0
			menu.Visible = false
		end
		if mode == "Off" then
			clearPieces()
		end
	end)
	local resultConnection = remotes.Result.OnClientEvent:Connect(function(action)
		if action == "Flush" and owned.ConfettiReveal and mode ~= "Off" then
			burst(if mode == "Reduced" then 8 else 24, false)
			burstAge = 0
		end
	end)
	local function pet(owner)
		local model = Instance.new("Model")
		model.Name = "Companion_" .. owner.UserId
		local function part(name, size, offset, color, shape)
			local object = Instance.new("Part")
			object.Name, object.Size, object.CFrame, object.Color = name, size, CFrame.new(offset), color
			object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery, object.CastShadow =
				true, false, false, false, false
			object.Shape, object.Parent = shape or Enum.PartType.Ball, model
			return object
		end
		local gold = Color3.fromRGB(255, 217, 76)
		model.PrimaryPart = part("Body", Vector3.new(1.4, 1, 1.6), Vector3.new(), gold)
		part("Head", Vector3.new(0.95, 0.95, 0.95), Vector3.new(0, 0.65, -0.5), gold)
		part(
			"Beak",
			Vector3.new(0.7, 0.22, 0.5),
			Vector3.new(0, 0.58, -1),
			Color3.fromRGB(255, 139, 38),
			Enum.PartType.Block
		)
		for _, x in ipairs({ -1, 1 }) do
			part("Eye", Vector3.new(0.13, 0.18, 0.13), Vector3.new(x * 0.3, 0.82, -0.87), Color3.new(0.05, 0.06, 0.1))
			part("Wing", Vector3.new(0.3, 0.6, 0.8), Vector3.new(x * 0.65, 0.05, 0), gold)
		end
		model.Parent = folder
		pets[owner] = model
		return model
	end
	local elapsed, clock, celebrationAge = 0, 0, 0
	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		local step = elapsed
		elapsed = 0
		clock += step
		burstAge += step
		celebrationAge += step
		if burstAge > 1.4 then
			clearPieces()
		end
		for i, piece in ipairs(pieces) do
			local a = i * 2.399
			piece.Position = UDim2.fromScale(
				0.5 + math.cos(a) * burstAge * 0.3,
				0.45 - math.sin(a) * burstAge * 0.18 + burstAge * burstAge * 0.17
			)
			if burstStyle == 3 then
				piece.Position = UDim2.fromScale(0.5 + math.cos(a + clock) * 0.16, 0.35 + math.sin(a + clock) * 0.06)
			elseif burstStyle == 4 then
				local diameter = 30 + burstAge * 90 + i * 8
				piece.Size = UDim2.fromOffset(diameter, diameter)
				piece.Position = UDim2.new(0.5, -diameter / 2, 0.4, -diameter / 2)
			end
			piece.Rotation = i * 23 + burstAge * 130
			piece.BackgroundTransparency = if burstStyle == 4 then 1 else math.clamp(burstAge / 1.4, 0, 1)
		end
		if selected > 0 and owned.DancePack and mode ~= "Off" and celebrationAge >= 2 then
			celebrationAge = 0
			burstAge = 0
			burst(
				if selected == 4 then 3 elseif mode == "Reduced" then 6 else 8 + selected * 4,
				selected == 2,
				selected
			)
		end
		local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local active = {}
		local count = 0
		for _, owner in ipairs(Players:GetPlayers()) do
			local character = owner.Character
			if characters[owner] ~= character then
				clearOwner(owner)
				characters[owner] = character
			end
			local head = character and character:FindFirstChild("Head")
			local label = head and head:FindFirstChild("PassName")
			label = label and label:FindFirstChild("NameColor")
			if label then
				label.TextColor3 = if owner:GetAttribute("RainbowName")
					then Color3.fromHSV((clock / 6) % 1, 0.75, 1)
					else C.Gold
			end
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
			if
				count < 12
				and localRoot
				and hrp
				and humanoid
				and humanoid.Health > 0
				and owner:GetAttribute("Companion") == true
				and (hrp.Position - localRoot.Position).Magnitude <= 150
			then
				count += 1
				active[owner] = true
				local model = pets[owner] or pet(owner)
				model:PivotTo(hrp.CFrame * CFrame.new(2.6, -1.4 + math.sin(clock * 3) * 0.2, 2.5))
			end
		end
		for owner, model in pairs(pets) do
			if not active[owner] then
				model:Destroy()
				pets[owner] = nil
			end
		end
	end)
	root.Destroying:Connect(function()
		heartbeat:Disconnect()
		stateConnection:Disconnect()
		resultConnection:Disconnect()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
		for _, connection in pairs(removing) do
			connection:Disconnect()
		end
		table.clear(removing)
		table.clear(characters)
		clearPieces()
		folder:Destroy()
		table.clear(pets)
	end)
	return { Pets = pets, Menu = menu }
end
return Effects
