local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Models = require(script.Parent.Models)
local Config = game.ReplicatedStorage.Shared.Config
local Style, Items, Rarities, Assets =
	require(Config.World), require(Config.Items), require(Config.Rarities), require(Config.Assets)
local World = { Plots = {}, Assigned = {} }
local byId = {}
for _, item in ipairs(Items) do
	byId[item.Id] = item
end
function World:Refresh(player, profile)
	local plot = self.Assigned[player]
	if not plot then
		return
	end
	if plot.Tier ~= profile.ToiletTier then
		if plot.Toilet then
			plot.Toilet:Destroy()
		end
		plot.Toilet = Models.Toilet(plot.Model, plot.CFrame, profile.ToiletTier)
		plot.Tier = profile.ToiletTier
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText, prompt.ObjectText, prompt.MaxActivationDistance =
			"FLUSH", player.DisplayName .. "'s Toilet", 10
		prompt:SetAttribute("OwnerUserId", player.UserId)
		prompt.RequiresLineOfSight = false
		prompt.Parent = plot.Toilet.PrimaryPart
		prompt.Triggered:Connect(function(visitor)
			if visitor == player then
				self.Flush(player)
			end
		end)
	end
	plot.Displays:ClearAllChildren()
	for slot = 1, profile.DisplaySlots do
		local cf = plot.CFrame * CFrame.new((slot - 1) % 5 * 4 - 8, 0, -8 - math.floor((slot - 1) / 5) * 5)
		local pedestal = Models.Part(
			plot.Displays,
			"Slot" .. slot,
			Vector3.new(3, 2, 3),
			cf * CFrame.new(0, 1, 0),
			Color3.fromRGB(35, 50, 80)
		)
		local item = byId[profile.Displays[tostring(slot)]]
		Models.Label(
			pedestal,
			if item then item.Name .. " 1/" .. item.Chance else "Display " .. slot,
			if item then Rarities[item.Rarity].Color else Color3.new(1, 1, 1),
			true
		)
		if item then
			Models.Item(plot.Displays, cf * CFrame.new(0, 3, 0), item)
		end
	end
end
function World:Assign(player)
	for _, plot in ipairs(self.Plots) do
		if not plot.Owner then
			plot.Owner = player
			self.Assigned[player] = plot
			plot.Sign.Text = player.DisplayName .. "'s Plot"
			player:SetAttribute("PlotPosition", plot.CFrame.Position + Vector3.new(0, 4, -4))
			return
		end
	end
	player:Kick("All plots are occupied. Please join another server.")
end
function World:Animate(player, item)
	local plot = self.Assigned[player]
	if not plot or not plot.Toilet then
		return
	end
	local toilet = plot.Toilet
	local pivot = toilet:GetPivot()
	local value = Instance.new("CFrameValue")
	value.Value = pivot
	local connection = value.Changed:Connect(function(cf)
		if toilet.Parent then
			toilet:PivotTo(cf)
		end
	end)
	local tween = TweenService:Create(
		value,
		TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true),
		{ Value = pivot * CFrame.Angles(0, 0, 0.08) }
	)
	tween:Play()
	tween.Completed:Once(function()
		connection:Disconnect()
		if toilet.Parent then
			toilet:PivotTo(pivot)
		end
		value:Destroy()
	end)
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Rarities[item.Rarity].Color)
	particles.Rate, particles.Lifetime, particles.Speed = 0, NumberRange.new(0.4, 1), NumberRange.new(4, 9)
	particles.Parent = toilet.PrimaryPart
	particles:Emit(if Rarities[item.Rarity].Order >= 4 then 90 else 25)
	Debris:AddItem(particles, 2)
	local soundId = Assets.Sounds.Flush
	if type(soundId) == "string" and soundId ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Parent = toilet.PrimaryPart
		sound:Play()
		Debris:AddItem(sound, 10)
	end
	local drop = Models.Item(plot.Model, plot.CFrame * CFrame.new(0, 6, 0), item)
	local float = Instance.new("CFrameValue")
	float.Value = drop:GetPivot()
	local link = float.Changed:Connect(function(cf)
		if drop.Parent then
			drop:PivotTo(cf)
		end
	end)
	local flight = TweenService:Create(
		float,
		TweenInfo.new(1.5, Enum.EasingStyle.Sine),
		{ Value = plot.CFrame * CFrame.new(0, 9, -3) }
	)
	flight:Play()
	flight.Completed:Once(function()
		link:Disconnect()
		float:Destroy()
		drop:Destroy()
	end)
end
function World:Start(data)
	local root = Instance.new("Folder")
	root.Name = "ToiletWorld"
	root.Parent = workspace
	Models.Part(root, "Plaza", Vector3.new(240, 1, 240), CFrame.new(0, -0.5, 0), Color3.fromRGB(195, 230, 245))
	Models.Part(root, "Hub", Vector3.new(70, 0.3, 70), CFrame.new(0, 0.15, 0), Color3.fromRGB(255, 220, 135))
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.6, 0)
	spawn.Neutral = true
	spawn.Parent = root
	local banner =
		Models.Part(root, "Banner", Vector3.new(42, 7, 1), CFrame.new(0, 13, 28), Color3.fromRGB(30, 65, 100))
	Models.Label(banner, "TOILETS MAKE DREAMS COME TRUE!", Color3.fromRGB(255, 235, 80), true)
	local shop = Models.Part(root, "Shop", Vector3.new(20, 8, 2), CFrame.new(-25, 5, 18), Color3.fromRGB(30, 65, 100))
	Models.Label(shop, "SHOP\nToilet Upgrades", Color3.fromRGB(100, 255, 150), true)
	Models.Toilet(root, CFrame.new(-24, 0, 10), 3)
	Models.Toilet(root, CFrame.new(24, 0, 10), 7)
	local board =
		Models.Part(root, "Leaderboard", Vector3.new(22, 16, 1), CFrame.new(25, 9, 22), Color3.fromRGB(20, 30, 55))
	self.Board = Models.Label(board, "Top Toilets", Color3.fromRGB(255, 220, 70), true)
	for index = 1, Style.PlotCount do
		local angle = index * math.pi * 2 / Style.PlotCount
		local position = Vector3.new(math.sin(angle) * Style.Radius, 0, math.cos(angle) * Style.Radius)
		local cf = CFrame.lookAt(position, Vector3.new(0, 0, 0))
		local model = Instance.new("Model")
		model.Name = "Plot" .. index
		model.Parent = root
		Models.Part(model, "Floor", Vector3.new(30, 0.4, 28), cf, Color3.fromRGB(170, 245, 150))
		local sign =
			Models.Part(model, "Sign", Vector3.new(18, 4, 1), cf * CFrame.new(0, 8, 9), Color3.fromRGB(30, 50, 80))
		local displays = Instance.new("Folder")
		displays.Name = "Displays"
		displays.Parent = model
		table.insert(
			self.Plots,
			{ Model = model, CFrame = cf, Sign = Models.Label(sign, "Available Plot", nil, true), Displays = displays }
		)
		for _, x in ipairs({ -13, 13 }) do
			Models.Part(model, "Pot", Vector3.new(2, 2, 2), cf * CFrame.new(x, 1, 7), Color3.fromRGB(190, 115, 65))
			Models.Part(
				model,
				"Plant",
				Vector3.new(3, 6, 3),
				cf * CFrame.new(x, 4, 7),
				Color3.fromRGB(40, 195, 75),
				Enum.PartType.Ball
			)
		end
	end
	Players.PlayerAdded:Connect(function(player)
		self:Assign(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local plot = self.Assigned[player]
		if plot then
			plot.Owner = nil
			plot.Tier = nil
			plot.Sign.Text = "Available Plot"
			plot.Displays:ClearAllChildren()
			if plot.Toilet then
				plot.Toilet:Destroy()
				plot.Toilet = nil
			end
		end
		self.Assigned[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		self:Assign(player)
	end
	task.spawn(function()
		while root.Parent do
			local ranking = {}
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = data:Get(player)
				if profile then
					local score = 0
					for _, item in ipairs(Items) do
						score += (profile.Inventory[item.Id] or 0) * item.Value
					end
					table.insert(ranking, { Name = player.DisplayName, Value = score })
				end
			end
			table.sort(ranking, function(a, b)
				return a.Value > b.Value
			end)
			local lines = { "Top Toilets" }
			for i = 1, math.min(10, #ranking) do
				table.insert(lines, i .. ". " .. ranking[i].Name .. "  " .. ranking[i].Value)
			end
			self.Board.Text = table.concat(lines, "\n")
			task.wait(10)
		end
	end)
end
return World
