local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Models = require(script.Parent.Models)
local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local Visuals = require(game.ReplicatedStorage.Shared.Config.Visuals)
local Hub = require(script.Parent.Builders.Hub)
local Plot = require(script.Parent.Builders.Plot)
local PlotSpawn = require(script.Parent.PlotSpawn)
local PlotChooser = require(game.ReplicatedStorage.Shared.PlotChooser)
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
	plot.Sign.Text = player.DisplayName .. "'s Plot\n" .. require(Config.Toilets)[profile.ToiletTier].Name
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
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.Parent = plot.Toilet.PrimaryPart
		prompt.Triggered:Connect(function(visitor)
			if visitor == player then
				self.Flush(player)
			end
		end)
	end
	local entries = { tostring(profile.DisplaySlots) }
	for slot = 1, profile.DisplaySlots do
		table.insert(entries, profile.Displays[tostring(slot)] or "-")
	end
	local signature = table.concat(entries, ":")
	plot.Profile = profile
	if plot.DisplaySignature ~= signature then
		plot.DisplaySignature, plot.Page = signature, 1
		self:RenderDisplays(plot)
	end
	plot.Model:SetAttribute("PartCount", P.Count(plot.Model))
	PlotSpawn:Ready(player)
end
-- Larger saved capacities rotate through five physical stands to retain the part budget.
function World:RenderDisplays(plot)
	local profile = plot.Profile
	if not profile then
		return
	end
	plot.Displays:ClearAllChildren()
	local pageSize = Visuals.Budget.DisplayPageSize
	local first = ((plot.Page or 1) - 1) * pageSize + 1
	local last = math.min(profile.DisplaySlots, first + pageSize - 1)
	local count = last - first + 1
	for slot = first, last do
		local cf = plot.CFrame * CFrame.new((slot - first - (count - 1) / 2) * 5.2, 0, -8)
		local pedestal = P.Part(
			plot.Displays,
			"Slot" .. slot,
			Vector3.new(3.9, 1.8, 3.9),
			cf * CFrame.new(0, 0.9, 0),
			Visuals.Palette.Navy
		)
		pedestal:SetAttribute("DisplaySlot", slot)
		local item = byId[profile.Displays[tostring(slot)]]
		local color = if item then Rarities[item.Rarity].Color else Visuals.Palette.Cyan
		if item and item.Rarity == "Secret" then
			color = Visuals.Palette.Cyan
		end
		P.Ring(plot.Displays, "PedestalGlow", cf * CFrame.new(0, 1.86, 0), 1.9, 1.9, 0.13, color, Enum.Material.Neon, 8)
		Models.Label(pedestal, if item then item.Name .. "\n1/" .. item.Chance else "Display " .. slot, color, true)
		if item then
			Models.Item(plot.Displays, cf * CFrame.new(0, 2.8, 0), item)
		end
	end
	if profile.DisplaySlots > pageSize then
		local page = P.Part(
			plot.Displays,
			"DisplayPage",
			Vector3.new(6, 0.8, 0.1),
			plot.CFrame * CFrame.new(0, 5, -8),
			Visuals.Palette.Navy
		)
		Models.Label(
			page,
			"Display page " .. plot.Page .. "/" .. math.ceil(profile.DisplaySlots / pageSize),
			Color3.new(1, 1, 1),
			true
		)
	end
	local countParts = P.Count(plot.Model)
	plot.Model:SetAttribute("PartCount", countParts)
	assert(countParts <= Visuals.Budget.Plot, "Plot exceeds its visual part budget")
end
function World:Assign(player)
	if self.Assigned[player] or self.Assigning[player] then
		return
	end
	self.Assigning[player] = true
	local friends = {}
	for _, plot in ipairs(self.Plots) do
		local owner = plot.Owner
		if owner and player.Parent == Players then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWithAsync(owner.UserId)
			end)
			if ok and isFriend then
				friends[owner.UserId] = true
			end
		end
	end
	self.Assigning[player] = nil
	if player.Parent ~= Players then
		return
	end
	-- Friendship checks yield. Read current occupancy and reserve without yielding.
	local owners = {}
	for index, plot in ipairs(self.Plots) do
		owners[index] = if plot.Owner then plot.Owner.UserId else false
	end
	local index = PlotChooser.Choose(owners, friends)
	if index then
		local plot = self.Plots[index]
		plot.Owner = player
		self.Assigned[player] = plot
		plot.Sign.Text = player.DisplayName .. "'s Plot"
		plot.Model:SetAttribute("OwnerUserId", player.UserId)
		player:SetAttribute("PlotPosition", plot.SpawnCFrame.Position)
		player:SetAttribute("PlotCFrame", plot.SpawnCFrame)
		player:SetAttribute("PlotCenter", plot.CFrame.Position)
		player:SetAttribute("PlotSignPosition", (plot.CFrame * CFrame.new(0, 11, 11)).Position)
		PlotSpawn:Register(player, plot)
		local profile = self.Data:Get(player)
		if profile then
			self:Refresh(player, profile)
		end
		return
	end
	player:Kick("All plots are occupied. Please join another server.")
end
function World:Animate(player, item)
	local plot = self.Assigned[player]
	if not plot or not plot.Toilet then
		return
	end
	local toilet = plot.Toilet
	toilet:SetAttribute("Flushing", true)
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
			toilet:SetAttribute("Flushing", false)
		end
		value:Destroy()
	end)
	local particles = P.Particles(
		toilet.PrimaryPart,
		"FlushBurst",
		Rarities[item.Rarity].Color,
		0,
		{ Speed = NumberRange.new(4, 7), SpreadAngle = Vector2.new(160, 160) }
	)
	particles:Emit(Visuals.Budget.Burst)
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
	self.Data, self.Assigning = data, {}
	local root = Instance.new("Folder")
	root.Name = "ToiletWorld"
	root.Parent = workspace
	require(script.Parent.Builders.Lighting).Build()
	self.Board = Hub.Build(root)
	for index = 1, Style.PlotCount do
		local angle = index * math.pi * 2 / Style.PlotCount
		local position = Vector3.new(math.sin(angle) * Style.Radius, 0, math.cos(angle) * Style.Radius)
		local cf = CFrame.lookAt(position, Vector3.new(0, 0, 0))
		table.insert(self.Plots, Plot.Build(root, cf, index))
	end
	Players.PlayerAdded:Connect(function(player)
		self:Assign(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		PlotSpawn:Remove(player)
		local plot = self.Assigned[player]
		if plot then
			plot.Owner = nil
			plot.Model:SetAttribute("OwnerUserId", nil)
			plot.Tier = nil
			plot.Profile, plot.DisplaySignature, plot.Page = nil, nil, nil
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
			for _, plot in ipairs(self.Plots) do
				if plot.Profile and plot.Profile.DisplaySlots > Visuals.Budget.DisplayPageSize then
					local pages = math.ceil(plot.Profile.DisplaySlots / Visuals.Budget.DisplayPageSize)
					plot.Page = (plot.Page or 1) % pages + 1
					self:RenderDisplays(plot)
				end
			end
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
