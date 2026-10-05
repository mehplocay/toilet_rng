local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Models = require(script.Parent.Models)
local MeshLoader = require(script.Parent.MeshLoader)
local DisplayRows = require(script.Parent.DisplayRows)
local Layout = require(game.ReplicatedStorage.Shared.Config.MapLayout)
local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local Visuals = require(game.ReplicatedStorage.Shared.Config.Visuals)
local Hub = require(script.Parent.Builders.Hub)
local Plot = require(script.Parent.Builders.Plot)
local PlotSpawn = require(script.Parent.PlotSpawn).Runtime()
local PlotChooser = require(game.ReplicatedStorage.Shared.PlotChooser)
local Config = game.ReplicatedStorage.Shared.Config
local Items, Rarities, Assets = require(Config.Items), require(Config.Rarities), require(Config.Assets)
local rankings = require(game.ReplicatedStorage.Shared.LeaderboardStats).new(Items)
local World = { Plots = {}, Assigned = {} }
local IncomeDisplay = require(script.Parent.IncomeDisplay)
function World:RefreshIncome(player, pending)
	local plot = self.Assigned[player]
	if plot and plot.Owner == player then
		plot.PendingCoins = pending
		IncomeDisplay.Refresh(plot, player, pending)
	end
end
local byId = {}
for _, item in ipairs(Items) do
	byId[item.Id] = item
end
function World:RecordFlush(player, item)
	local definition = byId[item.Id]
	if definition ~= item or item.Chance <= (self.BestChance or 0) then
		return
	end
	self.BestChance = item.Chance
	local odds = tostring(item.Chance):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	local text = "BEST FLUSH EVER\n"
		.. player.DisplayName
		.. "  •  "
		.. item.Name
		.. "\n"
		.. item.Rarity
		.. "  |  1 in "
		.. odds
	workspace:SetAttribute("BestFlushChance", item.Chance)
	workspace:SetAttribute("BestFlushRarity", item.Rarity)
	workspace:SetAttribute("BestFlushItemId", item.Id)
	workspace:SetAttribute("BestFlushPlayer", player.DisplayName)
	workspace:SetAttribute("BestFlushUserId", player.UserId)
	workspace:SetAttribute("BestFlushEver", text)
	if self.BestBoard then
		self.BestBoard.Text = text
		self.BestBoard.TextColor3 = if item.Rarity == "Secret"
			then Visuals.Palette.Cyan
			else Rarities[item.Rarity].Color
	end
end
function World:Refresh(player, profile)
	local plot = self.Assigned[player]
	if not plot then
		return
	end
	plot.Sign.Text = player.DisplayName .. "'s Plot"
	if plot.Tier ~= profile.ToiletTier then
		local upgraded = plot.Tier and profile.ToiletTier > plot.Tier
		if plot.Toilet then
			plot.Toilet:Destroy()
		end
		plot.Toilet = Models.Toilet(plot.Model, plot.CFrame, profile.ToiletTier, Layout.ToiletScale)
		plot.Tier = profile.ToiletTier
		if plot.FlushPrompt then
			plot.FlushPrompt:Destroy()
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText, prompt.ObjectText, prompt.MaxActivationDistance =
			"FLUSH", player.DisplayName .. "'s Toilet", 10
		prompt:SetAttribute("OwnerUserId", player.UserId)
		prompt.RequiresLineOfSight = false
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.Parent = plot.PromptAnchor
		plot.FlushPrompt = prompt
		prompt.Triggered:Connect(function(visitor)
			if visitor == player then
				self.Flush(player)
			end
		end)
		if upgraded then
			-- A bounded one-shot glow; the stable dais is never moved by toilet animation.
			for _, segment in ipairs(plot.GlowRing) do
				if segment.Tween then
					segment.Tween:Cancel()
				end
				local ring = segment.Part
				ring.Size = segment.Size * Layout.UpgradeGlow.Scale
				ring.Color = Color3.fromRGB(unpack(Layout.UpgradeGlow.Color))
				ring.Transparency = 0
				segment.Tween = TweenService:Create(
					ring,
					TweenInfo.new(Layout.UpgradeGlow.Seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Size = segment.Size,
						Color = Color3.fromRGB(unpack(Layout.UpgradeGlow.RestColor)),
						Transparency = 0.15,
					}
				)
				segment.Tween:Play()
			end
		end
	end
	local entries =
		{ tostring(profile.DisplaySlots), tostring(profile.ToiletTier), tostring((profile.Upgrades or {}).CashBoost) }
	for slot = 1, profile.DisplaySlots do
		table.insert(entries, profile.Displays[tostring(slot)] or "-")
	end
	local signature = table.concat(entries, ":")
	plot.Profile = profile
	if plot.DisplaySignature ~= signature then
		plot.DisplaySignature, plot.Page = signature, 1
		self:RenderDisplays(plot)
	end
	-- RenderDisplays already counts structural changes. Ordinary flush/state
	-- updates must not traverse the entire plot just for a diagnostic attribute.
	PlotSpawn:Ready(player)
end
-- Preserve saved slot indexes/capacity; ten physical stands paginate legacy capacities.
function World:RenderDisplays(plot)
	if not plot.Profile then
		return
	end
	DisplayRows.Build(plot)
	if plot.Owner then
		IncomeDisplay.Refresh(plot, plot.Owner, plot.PendingCoins or 0)
	end
	local count = P.Count(plot.Model)
	plot.Model:SetAttribute("PartCount", count)
	assert(count <= Visuals.Budget.Plot, "Plot exceeds its visual part budget")
end
function World:RefreshLeaderboards()
	local entries = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = self.Data:Get(player)
		if profile then
			table.insert(entries, { Name = player.DisplayName, UserId = player.UserId, Profile = profile })
		end
	end
	for key, board in pairs(self.Boards) do
		local ranked = rankings:Rank(entries, key)
		for rank, row in ipairs(board) do
			local entry = ranked[rank]
			row.Name.Text = if entry then rank .. ".  " .. entry.Name elseif rank == 1 then "Waiting for players" else ""
			row.Value.Text = if entry
				then (if key == "Rarest" and entry.Value > 0 then "1 in " else "") .. string.format("%.0f", entry.Value)
				else ""
		end
	end
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
	local index = PlotChooser.Choose(owners, friends, Layout.Plots)
	if index then
		local plot = self.Plots[index]
		plot.Owner = player
		self.Assigned[player] = plot
		plot.Sign.Text = player.DisplayName .. "'s Plot"
		plot.Model:SetAttribute("OwnerUserId", player.UserId)
		player:SetAttribute("PlotPosition", plot.SpawnCFrame.Position)
		player:SetAttribute("PlotCFrame", plot.SpawnCFrame)
		player:SetAttribute("PlotCenter", plot.CFrame.Position)
		player:SetAttribute("PlotSignPosition", plot.SignPosition)
		PlotSpawn:Register(player, plot)
		local profile = self.Data:Get(player)
		if profile then
			self:Refresh(player, profile)
		end
		return
	end
	player:Kick("All plots are occupied. Please join another server.")
end
function World:Animate(player, item, skipAnimation, duration)
	duration = duration or 0.32
	-- Called only after the server has awarded a validated flush result.
	self:RecordFlush(player, item)
	local plot = self.Assigned[player]
	if not plot or not plot.Toilet then
		return
	end
	if skipAnimation then
		local drop = Models.Item(plot.Model, plot.CFrame * CFrame.new(0, 6, 0), item)
		Debris:AddItem(drop, duration)
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
		TweenInfo.new(duration / 12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true),
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
	Debris:AddItem(particles, duration)
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
		TweenInfo.new(duration, Enum.EasingStyle.Sine),
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
	MeshLoader.Preload()
	require(script.Parent.Builders.Island).Build(workspace.Terrain)
	require(script.Parent.Builders.Lighting).Build()
	self.Boards, self.BestBoard = Hub.Build(root)
	self.BestChance = 0
	workspace:SetAttribute("BestFlushChance", 0)
	workspace:SetAttribute("BestFlushRarity", "")
	workspace:SetAttribute("BestFlushItemId", "")
	workspace:SetAttribute("BestFlushPlayer", "")
	workspace:SetAttribute("BestFlushUserId", 0)
	workspace:SetAttribute("BestFlushEver", self.BestBoard.Text)
	for index, entry in ipairs(Layout.Plots) do
		local cf = CFrame.new(entry.X, Layout.FloorY, entry.Z) * CFrame.Angles(0, math.rad(entry.Yaw), 0)
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
			if plot.FlushPrompt then
				plot.FlushPrompt:Destroy()
				plot.FlushPrompt = nil
			end
			for _, segment in ipairs(plot.GlowRing) do
				if segment.Tween then
					segment.Tween:Cancel()
				end
				segment.Tween = nil
				segment.Part.Size = segment.Size
				segment.Part.Color = Color3.fromRGB(unpack(Layout.UpgradeGlow.RestColor))
				segment.Part.Transparency = 0
			end
			plot.Profile, plot.DisplaySignature, plot.Page = nil, nil, nil
			plot.PendingCoins, plot.IncomePoint, plot.IncomePrompt, plot.IncomeCoins = nil, nil, nil, nil
			plot.CollectPoints, plot.IncomeLabel = nil, nil
			plot.Sign.Text = "Available Plot"
			plot.Displays:ClearAllChildren()
			DisplayRows.Build(plot, { ToiletTier = 1, DisplaySlots = 0, Displays = {} })
			if plot.Toilet then
				plot.Toilet:Destroy()
				plot.Toilet = nil
			end
		end
		self.Assigned[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:Assign(player)
		end)
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
			self:RefreshLeaderboards()
			task.wait(Layout.RefreshSeconds)
		end
	end)
end
return World
