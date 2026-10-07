-- Cosmetics stay client-local, with bounded update loops and deterministic cleanup.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local C = require(script.Parent.UI.Components)
local Effects = {}
function Effects.Start(root, player, remotes)
	local pets = {}
	local celebration = require(script.Parent.DancePackEffects).Start(root, player, remotes)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "LocalPassCompanions", workspace
	local characters, removing = {}, {}
	local function clearOwner(owner)
		if pets[owner] then
			pets[owner]:Destroy()
			pets[owner] = nil
		end
		characters[owner] = nil
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
	local elapsed, clock = 0, 0
	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		local step = elapsed
		elapsed = 0
		clock += step
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
		addedConnection:Disconnect()
		removingConnection:Disconnect()
		for _, connection in pairs(removing) do
			connection:Disconnect()
		end
		table.clear(removing)
		table.clear(characters)
		celebration.Destroy()
		folder:Destroy()
		table.clear(pets)
	end)
	return { Pets = pets, Menu = celebration.Menu }
end
return Effects
