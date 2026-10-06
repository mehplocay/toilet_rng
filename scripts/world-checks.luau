local P = loadModule(node("src/shared/Visuals/Primitives"))
local Toilets = loadModule(node("src/shared/Visuals/Toilets"))
local Items = loadModule(node("src/shared/Config/Items"))
local ItemBuilder = loadModule(node("src/shared/Visuals/Items"))
local V = loadModule(node("src/shared/Config/Visuals"))
local Catalog = loadModule(node("src/shared/Config/MeshCatalog"))
local Loader = loadModule(node("src/server/World/MeshLoader"))
local Models = loadModule(node("src/server/World/Models"))
local ToiletConfig = loadModule(node("src/shared/Config/Toilets"))
local configured = 0
local names = {}
local sourceRoot = Instance.new("Model")
sourceRoot.Name = "ModelTemplates"
local envRoot = Instance.new("Model")
envRoot.Name = "EnvTemplates"
local waveRoot = Instance.new("Model")
waveRoot.Name = "Wave1Templates"
for name, entry in pairs(manifest) do
	assert(Catalog[name] and importedTemplates[name], "Missing catalog/template: " .. name)
	assert((Catalog[name].Size - entry.Size).Magnitude < 0.00001, "Manifest size drift: " .. name)
	assert(Catalog[name].Triangles == entry.Triangles, "Manifest triangle drift: " .. name)
	table.insert(names, name)
	local model = Instance.new("Model")
	model.Name = name
	local part = Instance.new("MeshPart")
	for key, value in pairs(importedTemplates[name]) do
		part[key] = value
	end
	part.Name = name
	part.RenderFidelity = Enum.RenderFidelity.Automatic
	if testMode == "Scaled" then
		part.Size *= 37
		local pivot = part.PivotOffset
		part.PivotOffset = (pivot - pivot.Position) + pivot.Position * 37
		part.CFrame = CFrame.new(800, -120, 370) * CFrame.Angles(0.3, 1.7, 0.4)
	elseif testMode == "Invalid" then
		part.Size = Vector3.new(0, 0, 0)
	end
	part.Parent, model.PrimaryPart = model, part
	if testMode ~= "Mixed" or name ~= "PalmTree" then
		model.Parent = if Catalog[name].Folder == "Wave1Templates"
			then waveRoot
			elseif Catalog[name].Folder == "EnvTemplates" then envRoot
			else sourceRoot
	end
end
for name in pairs(Catalog) do
	assert(manifest[name])
end
assert(#names == 119)
if testMode ~= "Empty" and testMode ~= "Late" then
	sourceRoot.Parent, envRoot.Parent, waveRoot.Parent = storage, storage, storage
end
Loader.Preload()
local startupCalls = calls
local startupClones = templateClones
Loader.Preload()
assert(templateClones == startupClones, "Normalization cache repeated work")
assert(calls == 0 and preloads == 0, "Templates must not request assets")
for _, name in ipairs(names) do
	local model = Loader.Clone(name, nil, CFrame.new())
	if model then
		configured += 1
		local part = model.PrimaryPart
		assert((part.Size - manifest[name].Size).Magnitude < 0.001, "Normalization size: " .. name)
		assert(model:GetPivot().Position.Magnitude < 0.0001, "Base pivot: " .. name)
		assert(math.abs(part.CFrame.Position.Y - part.Size.Y / 2) < 0.0001, "Floating/buried: " .. name)
		assert(math.abs(part.CFrame.R[5] - 1) < 0.0001 and part.CFrame.R[1] == -1, "Y-up/front correction: " .. name)
		assert(
			part.MeshContent == importedTemplates[name].MeshContent
				and part.TextureID == importedTemplates[name].TextureID
		)
		if Catalog[name].Center or Catalog[name].PreserveFoot then
			assert(model:GetAttribute("SeatHeight") == 2.08)
			local expected = if Catalog[name].Folder == "Wave1Templates"
				then importedTemplates[name].PivotOffset.Position
				else Catalog[name].Center
			assert(math.abs(part.CFrame.Position.X - expected.X) < 0.001, "Foot X: " .. name)
			local z = if Catalog[name].Folder == "Wave1Templates" then expected.Z else -expected.Z
			assert(math.abs(part.CFrame.Position.Z - z) < 0.001, "Foot Z: " .. name)
		end
		local placed = Loader.Clone(name, nil, CFrame.new(7, 4, -11) * CFrame.Angles(0, 0.8, 0), 1.7)
		assert((placed.PrimaryPart.Size - part.Size * 1.7).Magnitude < 0.001)
		assert((placed:GetPivot().Position - Vector3.new(7, 4, -11)).Magnitude < 0.0001)
		placed.PrimaryPart.TextureID = "mutated only in mock"
		placed:Destroy()
		assert(part.TextureID == importedTemplates[name].TextureID, "Clone isolation")
		model:Destroy()
	end
end
assert(
	configured == (if testMode == "Ready" or testMode == "Scaled" then 119 elseif testMode == "Mixed" then 118 else 0)
)
local root = Instance.new("Folder")
local function checkAccents(model)
	local effect = loadModule(node("src/shared/Config/TemplateEffects"))[model:GetAttribute("MeshAsset")]
	if effect and not model:GetAttribute("MeshFallback") then
		local lights, emitters = 0, 0
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("PointLight") then
				lights += 1
			end
			if child:IsA("ParticleEmitter") then
				emitters += 1
				assert(child.Name == effect.Particles and child.Rate == (effect.Rate or 2))
			end
		end
		assert(lights == 1 and emitters == 1)
		local count = #model:GetDescendants()
		loadModule(node("src/shared/Visuals/TemplateAccents")).Apply(model)
		assert(#model:GetDescendants() == count, "Accents duplicated")
	end
end
local function validate(container)
	for _, object in ipairs(container:GetDescendants()) do
		if isPart(object) then
			assert(object.Anchored, "Unanchored geometry: " .. object.Name)
			assert(
				not object.CanTouch or object:GetAttribute("IncomePad") == true,
				"Touch-enabled decoration: " .. object.Name
			)
			assert(object.CanCollide or not object.CanQuery, "Queryable decoration: " .. object.Name)
			assert(object.Size.X > 0 and object.Size.Y > 0 and object.Size.Z > 0, "Invalid part size")
			if object.ClassName == "MeshPart" then
				assert(not object.CanCollide)
				assert(object.TextureID ~= "" or object.Parent:GetAttribute("SolidFinish"))
				assert(
					object.Parent.ModelStreamingMode
						== (
							if object.Parent:GetAttribute("ResortSkyline")
								then Enum.ModelStreamingMode.Persistent
								elseif object.Parent._persistentPlayer then Enum.ModelStreamingMode.PersistentPerPlayer
								else Enum.ModelStreamingMode.Atomic
						)
				)
			end
		elseif object:IsA("ParticleEmitter") then
			assert(
				object.Rate <= V.Budget.IdleRate and not object.Enabled and object:GetAttribute("VisualIdle"),
				"Unbounded idle particles"
			)
		elseif object:IsA("PointLight") then
			assert(
				not object.Shadows and not object.Enabled and object:GetAttribute("VisualIdle"),
				"Unbounded idle light"
			)
		end
		assert(object.ClassName ~= "UnionOperation", "Runtime union geometry")
	end
end
local Hub = loadModule(node("src/server/World/Builders/Hub"))
local Plot = loadModule(node("src/server/World/Builders/Plot"))
local boards, bestBoard = Hub.Build(root)
local hubCount = P.Count(root)
assert(hubCount <= V.Budget.Hub)
local used = {}
local function stats(container)
	local meshes, fallbacks, triangles = 0, 0, 0
	for _, object in ipairs(container:GetDescendants()) do
		if object:IsA("MeshPart") then
			meshes += 1
			triangles += Catalog[object.Name].Triangles
		end
		if object:GetAttribute("MeshFallback") then
			fallbacks += 1
		end
	end
	return meshes, fallbacks, triangles
end
local hubMeshes, hubFallbacks, hubTriangles = stats(root)
local function recordAssets(container)
	for _, object in ipairs(container:GetDescendants()) do
		local asset = object:GetAttribute("MeshAsset")
		if asset then
			used[asset] = true
			local ready = Loader.Status(asset) == "Ready"
			assert(object:GetAttribute("MeshFallback") == not ready, "Wrong fallback state: " .. asset)
		end
	end
end
recordAssets(root)
local maxItem, maxItemId, maxItemTriangles = 0, nil, 0
local maxItemMeshes, maxItemInstances, maxItemHighlights = 0, 0, 0
local function countClass(container, class)
	local count = 0
	for _, object in ipairs(container:GetDescendants()) do
		if object:IsA(class) then
			count += 1
		end
	end
	return count
end
local function effectCost(container)
	local emitters, rate, particles = 0, 0, 0
	for _, object in ipairs(container:GetDescendants()) do
		if object:IsA("ParticleEmitter") then
			emitters += 1
			rate += object.Rate
			particles += object.Rate * (object.Lifetime[2] or object.Lifetime[1])
		end
	end
	return emitters, rate, particles
end
local hubEmitters, hubRate, hubParticles = effectCost(root)
local hubLabels = countClass(root, "BillboardGui")
local maxPlotEmitters, maxPlotRate, maxPlotParticles, maxPlotLabels = 0, 0, 0, 0
local maxItemEmitters, maxItemRate, maxItemParticles = 0, 0, 0
local maxPartItemTriangles = 0
for _, item in ipairs(Items) do
	local preview = ItemBuilder.Build(root, CFrame.new(), item, true)
	assert(preview.PrimaryPart and P.Count(preview) >= 1, item.Id .. " missing preview geometry")
	if Loader.Status(loadModule(node("src/shared/Config/WorldModels")).ItemNames[item.Id] or item.Id) == "Ready" then
		assert(
			preview:GetAttribute("MeshAsset") and P.Count(preview) == 1,
			"Preview missed template or has idle effects"
		)
	end
	validate(preview)
	preview:Destroy()
	local model = Models.Item(root, CFrame.new(), item)
	assert(model.PrimaryPart)
	checkAccents(model)
	local itemMeshes, _, itemTriangles = stats(model)
	maxItemMeshes = math.max(maxItemMeshes, itemMeshes)
	maxItemInstances = math.max(maxItemInstances, #model:GetDescendants())
	maxItemHighlights = math.max(maxItemHighlights, countClass(model, "Highlight"))
	local emitters, rate, particles = effectCost(model)
	maxItemEmitters, maxItemRate, maxItemParticles =
		math.max(maxItemEmitters, emitters), math.max(maxItemRate, rate), math.max(maxItemParticles, particles)
	if P.Count(model) > maxItem or (P.Count(model) == maxItem and itemTriangles > maxPartItemTriangles) then
		maxItem, maxItemId = P.Count(model), item.Id
		maxPartItemTriangles = itemTriangles
	end
	maxItemTriangles = math.max(maxItemTriangles, itemTriangles)
	recordAssets(model.Parent)
	validate(model)
	model:Destroy()
end
local World = loadModule(node("src/server/World/WorldService"))
World.Boards = boards
local boardPlayers = { { UserId = 2, DisplayName = "<b>Second</b>" }, { UserId = 1, DisplayName = "First" } }
services.Players.GetPlayers = function()
	return boardPlayers
end
World.Data = {
	Get = function(_, player)
		return {
			Coins = player.UserId * 100,
			Stats = { Flushes = 10 - player.UserId, RarestItemId = Items[player.UserId].Id },
		}
	end,
}
World:RefreshLeaderboards()
assert(boards.Coins[1].Name.Text == "1.  <b>Second</b>" and not boards.Coins[1].Name.RichText)
assert(boards.Flushes[1].Name.Text == "1.  First" and boards.Coins[1].Value.Text == "200")
boardPlayers = {}
World:RefreshLeaderboards()
assert(boards.Coins[1].Name.Text == "Waiting for players" and boards.Coins[2].Name.Text == "")
local maxPlot, maxToilet, maxPlotMeshes, maxPlotTriangles = 0, 0, 0, 0
local hubInstances, maxPlotInstances = #root:GetDescendants(), 0
local maxPlotHighlights = 0
-- Exercise the real refresh path: fixed prompt, all seven tier swaps, one glow
-- per upgrade, same-profile idempotence, and no tween allocation on first load.
do
	local layout = loadModule(node("src/shared/Config/MapLayout"))
	local plot = Plot.Build(root, CFrame.new(20, 0, -40) * CFrame.Angles(0, 0.7, 0), 1)
	local owner = { UserId = 101, DisplayName = "A very long owner display name" }
	local profile = { ToiletTier = 1, DisplaySlots = 3, Displays = {} }
	World.Assigned[owner], plot.Owner = plot, owner
	local count = #tweens
	World:Refresh(owner, profile)
	local placePrompts = 0
	for _, object in ipairs(plot.Displays:GetDescendants()) do
		if object.Name == "DisplayPrompt" then
			placePrompts += 1
			assert(object.ActionText == "Place" and object.Enabled and object:GetAttribute("DisplaySlot") <= 3)
		end
		if object:GetAttribute("IncomePad") then
			local unlocked = object:GetAttribute("CollectSlot") <= 3
			assert(object.CanTouch == unlocked)
			assert((object:FindFirstChild("IncomePrompt") ~= nil) == unlocked)
		end
	end
	assert(placePrompts == 3, "Empty/locked display prompts do not match capacity")
	assert(#tweens == count, "Initial toilet load is not an upgrade")
	local anchor = plot.PromptAnchor
	local originalCount = P.Count
	P.Count = function()
		error("Unchanged State refresh traversed the plot")
	end
	for _ = 1, 100 do
		World:Refresh(owner, profile)
	end
	P.Count = originalCount
	for tier = 1, #ToiletConfig do
		local previous, oldTween = plot.Toilet, plot.GlowRing[1].Tween
		profile.ToiletTier = tier
		World:Refresh(owner, profile)
		assert(plot.FlushPrompt.Parent == anchor and plot.FlushPrompt.ActionText == "FLUSH")
		assert(plot.FlushPrompt:GetAttribute("OwnerUserId") == owner.UserId)
		assert(#anchor:GetChildren() == 1, "Tier swap duplicated prompt")
		assert((plot.Toilet:GetPivot().Position - plot.CFrame.Position).Magnitude < 0.001)
		assert((plot.SpawnCFrame.Position - anchor.CFrame.Position).Magnitude < plot.FlushPrompt.MaxActivationDistance)
		if tier > 1 then
			assert(previous.Parent == nil)
			for _, segment in ipairs(plot.GlowRing) do
				assert(segment.Tween.Played and segment.Tween.Target == segment.Part)
				assert(segment.Tween.Info[1] == layout.UpgradeGlow.Seconds)
				assert((segment.Tween.Goal.Size - segment.Size).Magnitude < 0.001)
			end
			if oldTween then
				assert(oldTween.Cancelled, "Overlapping upgrade glow leaked a tween")
			end
		end
		local currentToilet, currentPrompt = plot.Toilet, plot.FlushPrompt
		World:Refresh(owner, profile)
		assert(plot.Toilet == currentToilet and plot.FlushPrompt == currentPrompt)
	end
	assert(#plot.GlowRing == 10 and #tweens == count + (#ToiletConfig - 1) * #plot.GlowRing)
	World.Assigned[owner] = nil
	plot.Model:Destroy()
end
for tier = 1, #ToiletConfig do
	local plot = Plot.Build(root, CFrame.new(), tier)
	assert(plot.Spawn:IsA("SpawnLocation") and plot.Spawn.Neutral and plot.Spawn.Enabled)
	assert(plot.Spawn.Transparency == 1 and not plot.Spawn.CanCollide and not plot.Spawn.AllowTeamChangeOnTouch)
	local layout = loadModule(node("src/shared/Config/MapLayout"))
	local guidance = loadModule(node("src/shared/Config/PlotGuidance"))
	assert((plot.SpawnCFrame.Position - plot.CFrame.Position - guidance.SpawnOffset).Magnitude < 0.001)
	assert((plot.SpawnCFrame.Position - plot.PromptAnchor.CFrame.Position).Magnitude < 10, "Home must enable FLUSH")
	-- Preserve the original primitive tier contract used by client previews.
	local preview = Toilets.Build(root, CFrame.new(), tier, true)
	for _, name in ipairs({ "Bowl", "Tank", "Foot", "OpenLid", "FlushHandle", "Water", "Seat" }) do
		assert(preview:GetAttribute("MeshAsset") or preview:FindFirstChild(name), "Missing toilet component: " .. name)
	end
	preview:Destroy()
	plot.Toilet = Models.Toilet(plot.Model, plot.CFrame, tier, layout.ToiletScale)
	if not plot.Toilet:GetAttribute("MeshFallback") then
		assert(
			(plot.Toilet.PrimaryPart.Size - Catalog[plot.Toilet:GetAttribute("MeshAsset")].Size * layout.ToiletScale).Magnitude
				< 0.001,
			"Toilet hero scale drift"
		)
	end
	assert(
		(plot.Toilet:GetPivot().Position - plot.CFrame.Position).Magnitude < 0.001,
		"Tier swap moved the toilet base"
	)
	for _, part in ipairs(plot.Toilet:GetDescendants()) do
		if isPart(part) then
			local cf = plot.LayoutCFrame:Inverse() * part.CFrame
			local extent = math.abs(cf:VectorToWorldSpace(Vector3.new(part.Size.X / 2, 0, 0)).Y)
				+ math.abs(cf:VectorToWorldSpace(Vector3.new(0, part.Size.Y / 2, 0)).Y)
				+ math.abs(cf:VectorToWorldSpace(Vector3.new(0, 0, part.Size.Z / 2)).Y)
			assert(cf.Position.Y + extent < layout.PavilionHeight, "Toilet ornament intersects pavilion roof")
		end
	end
	checkAccents(plot.Toilet)
	maxToilet = math.max(maxToilet, P.Count(plot.Toilet))
	local profile = { ToiletTier = tier, DisplaySlots = 100, Displays = {} }
	for slot = 1, 100 do
		profile.Displays[tostring(slot)] = maxItemId
	end
	plot.Profile = profile
	plot.Owner = { UserId = tier, DisplayName = "Budget fixture" }
	World.Assigned[plot.Owner] = plot
	World:Refresh(plot.Owner, profile)
	for page = 1, 10 do
		plot.Page = page
		World:RenderDisplays(plot)
		local names, itemsBySlot, displayPrompts = 0, {}, 0
		for _, object in ipairs(plot.Displays:GetDescendants()) do
			if object.Name == "IncomeNametag" then
				names += 1
				local gui = object:GetChildren()[1]
				local text = gui:GetChildren()[1].Text
				assert(
					gui.MaxDistance == layout.Labels.OccupiedDistance and text:find("1 in ") and text:find("/s"),
					"Occupied nametag lost odds/income"
				)
			end
			if object:IsA("Model") and object:GetAttribute("DisplaySlot") and object.Name:sub(1, 4) ~= "Slot" then
				local slot = object:GetAttribute("DisplaySlot")
				assert(not itemsBySlot[slot], "Duplicate render for one slot")
				itemsBySlot[slot] = object
			end
			if object.Name == "DisplayPrompt" then
				displayPrompts += 1
				assert(object.ActionText == "Put Back" and object.HoldDuration == 0 and not object.RequiresLineOfSight)
				assert(object:GetAttribute("OwnerUserId") == tier and object:GetAttribute("DisplayOccupied"))
			end
		end
		assert(names == 10 and displayPrompts == 10, "Identical items lost per-slot nametags or prompts")
		assert(#plot.CollectPoints == 11, "Ten collect pads plus jar required")
		for i = 1, 10 do
			local pad = plot.CollectPoints[i]
			local slot = (page - 1) * 10 + i
			assert(itemsBySlot[slot] and pad.CanTouch and pad:GetAttribute("CollectSlot") == slot)
			assert(plot.CollectSlots[slot] == pad)
			local prompt = pad:FindFirstChild("IncomePrompt")
			assert(prompt:GetAttribute("CollectSlot") == slot and prompt.MaxActivationDistance == 6)
			assert(
				prompt.ActionText == "Collect"
					and prompt.Enabled
					and prompt.HoldDuration == 0
					and not prompt.RequiresLineOfSight
			)
			local contacts = 0
			World.CollectIncome = function(visitor, target, touching)
				assert(visitor == plot.Owner and target == slot and touching)
				contacts += 1
			end
			pad.Touched:Fire({ Parent = { TestPlayer = { UserId = -1 } } })
			pad.Touched:Fire({ Parent = {} })
			assert(contacts == 0, "Foreign touch reached collect transaction")
			plot.Owner.Character = {}
			pad.Touched:Fire({ Parent = plot.Owner.Character })
			assert(contacts == 1, "Owner step did not reach the exact pad transaction")
			assert(pad.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -1)).Y > 0.99, "Collect dollar faces underground")
		end
		assert(plot.IncomePoint.Parent == plot.Displays and plot.IncomePrompt.ActionText == "Collect All")
		assert(plot.IncomePrompt:GetAttribute("IncomeOwnerUserId") == tier)
		assert(
			plot.IncomePrompt.Enabled
				and plot.IncomePrompt.HoldDuration == 0
				and not plot.IncomePrompt.RequiresLineOfSight
		)
		assert(plot.IncomePrompt.MaxActivationDistance == 10 and plot.IncomePrompt:GetAttribute("CollectSlot") == nil)
		local incomeVisual = loadModule(node("src/server/World/IncomeDisplay"))
		for _, pending in ipairs({ 0, 1, 10, 100, 0 }) do
			profile.Income = { Pending = { [tostring((page - 1) * 10 + 1)] = pending * 6000 } }
			incomeVisual.Refresh(plot, plot.Owner, pending)
			assert(plot.IncomeLabel.Text == "COLLECT ALL\n$" .. pending)
			assert(plot.IncomePoint:FindFirstChild("IncomeGlow"):GetAttribute("IncomeReady") == (pending >= 1))
			assert(plot.CollectPoints[1]:FindFirstChild("IncomeGlow"):GetAttribute("IncomeReady") == (pending >= 1))
			assert(
				not plot.CollectPoints[2]:FindFirstChild("IncomeGlow"):GetAttribute("IncomeReady"),
				"Pad glow used aggregate balance"
			)
			for level, coin in ipairs(plot.IncomeCoins) do
				assert(coin.Transparency == (if pending >= ({ 1, 10, 100 })[level] then 0 else 1))
			end
		end
		local count = P.Count(plot.Model) + maxItem
		assert(count <= V.Budget.Plot, "Plot with transient drop exceeds budget: " .. count)
		-- FastFlush can briefly overlap two 1.5-second visuals at the Galaxy tier.
		assert(count + maxItem <= V.Budget.Plot, "Overlapping drops exceed plot budget")
		maxPlot = math.max(maxPlot, count)
		maxPlotInstances = math.max(maxPlotInstances, #plot.Model:GetDescendants())
		maxPlotHighlights = math.max(maxPlotHighlights, countClass(plot.Model, "Highlight"))
		local emitters, rate, particles = effectCost(plot.Model)
		maxPlotEmitters, maxPlotRate, maxPlotParticles =
			math.max(maxPlotEmitters, emitters), math.max(maxPlotRate, rate), math.max(maxPlotParticles, particles)
		maxPlotLabels = math.max(maxPlotLabels, countClass(plot.Model, "BillboardGui"))
		local meshes, _, triangles = stats(plot.Model)
		maxPlotMeshes = math.max(maxPlotMeshes, meshes)
		-- The most parts and the most triangles need not belong to the same item.
		-- Reserve ten maximum-triangle meshes as well as the maximum-part fixture.
		maxPlotTriangles = math.max(maxPlotTriangles, triangles + 10 * (maxItemTriangles - maxPartItemTriangles))
		assert(plot.Displays:FindFirstChild("Slot" .. ((page - 1) * 10 + 1)), "Display page lost a slot")
	end
	recordAssets(plot.Model)
	validate(plot.Model)
	World.Assigned[plot.Owner] = nil
	plot.Model:Destroy()
end
validate(root)
print(
	string.format(
		"Audit2 full-scene effects envelope: %d emitters, %.0f idle particles/sec, <=%.1f particles at maximum lifetime; %d billboards (excludes avatars, transient bursts and UI)",
		hubEmitters + 12 * (maxPlotEmitters + 2 * maxItemEmitters),
		hubRate + 12 * (maxPlotRate + 2 * maxItemRate),
		hubParticles + 12 * (maxPlotParticles + 2 * maxItemParticles),
		hubLabels + 12 * maxPlotLabels
	)
)
for name in pairs(Catalog) do
	assert(used[name], "No world placement covers " .. name)
end
assert(calls == startupCalls, "Building world/flush/display made a network request")
assert(templateClones == startupClones, "Placements renormalized cached templates")

if checkWorld then
	local Island = loadModule(node("src/server/World/Builders/Island"))
	Island.Build(terrain)
	assert(terrainWrites == 1 and terrainMaterials[Enum.Material.Water])
	loadModule(node("src/server/World/Builders/Lighting")).Build()
	loadModule(node("src/server/World/Builders/Lighting")).Build()
	assert(#services.Lighting:GetChildren() == 5 and #terrain:GetChildren() == 1, "Duplicate sky/effects")
	World.BestBoard = bestBoard
	local winner = { DisplayName = "First player", UserId = 42 }
	World:RecordFlush(winner, Items[1])
	assert(workspace:GetAttribute("BestFlushChance") == Items[1].Chance)
	local best = Items[1]
	for _, item in ipairs(Items) do
		World:RecordFlush(winner, item)
		if item.Chance > best.Chance then
			best = item
		end
	end
	assert(
		workspace:GetAttribute("BestFlushChance") == best.Chance
			and workspace:GetAttribute("BestFlushItemId") == best.Id
	)
	assert(
		workspace:GetAttribute("BestFlushRarity") == best.Rarity
			and bestBoard.Text == workspace:GetAttribute("BestFlushEver")
	)
	World:RecordFlush({ DisplayName = "Tie", UserId = 2 }, best)
	World:RecordFlush({ DisplayName = "Lower", UserId = 3 }, Items[1])
	local spoof = table.clone(best)
	spoof.Chance *= 10
	World:RecordFlush({ DisplayName = "Spoof", UserId = 4 }, spoof)
	assert(workspace:GetAttribute("BestFlushUserId") == 42 and workspace:GetAttribute("BestFlushChance") == best.Chance)
	if testMode == "Invalid" then
		assert(warnings == 119, "Invalid templates must warn once and stay uncached")
	elseif testMode == "Late" then
		sourceRoot.Parent, envRoot.Parent, waveRoot.Parent = storage, storage, storage
		assert(Loader.Status("Poop") == "Ready", "Late replication did not recover")
		assert(Loader.Status("HaloHamster") == "Ready", "Late Wave 1 item did not recover")
		assert(Loader.Status("InfinityFlush") == "Ready", "Late Wave 1 toilet did not recover")
		local preview = ItemBuilder.Build(root, CFrame.new(), Items[1], true)
		assert(preview:GetAttribute("MeshAsset"), "Client preview did not recover")
		preview:Destroy()
	else
		assert(warnings == 0)
	end
	if testMode == "Ready" then
		-- A Model can arrive before its MeshPart on a client. Retry when children arrive.
		local source = sourceRoot:FindFirstChild("Poop")
		source.Parent = nil
		local partial = Instance.new("Model")
		partial.Name, partial.Parent = "Poop", sourceRoot
		assert(Loader.Status("Poop") == "Invalid")
		local copy = source.PrimaryPart:Clone()
		copy.Parent = partial
		assert(Loader.Status("Poop") == "Ready", "Partial replication stayed in fallback")
		assert(source.PrimaryPart.Size.Y == importedTemplates.Poop.Size.Y, "Source template mutated")
	end
end

-- Exercise production world currency text at the actual v2 upper income scale.
do
	local plot = Plot.Build(root, CFrame.new(), 1)
	local owner = { UserId = 981, DisplayName = "Income fixture" }
	local profile =
		{ ToiletTier = 7, DisplaySlots = 10, Displays = {}, RebirthLevel = 15, Upgrades = { CashBoost = 10 } }
	profile.Monetization = { Passes = { DoubleCash = true, VIPPack = true } }
	for slot = 1, 10 do
		profile.Displays[tostring(slot)] = "Mystery"
	end
	plot.Owner, plot.Profile, World.Assigned[owner] = owner, profile, plot
	World:Refresh(owner, profile)
	local names = 0
	for _, object in ipairs(plot.Displays:GetDescendants()) do
		if object.Name == "IncomeNametag" then
			names += 1
			assert(object:GetChildren()[1]:GetChildren()[1].Text:find("$12M/s", 1, true))
		end
	end
	assert(names == 10)
	loadModule(node("src/server/World/IncomeDisplay")).Refresh(plot, owner, 34560000000)
	assert(plot.IncomeLabel.Text == "COLLECT ALL\n$34.5B")
	World.Assigned[owner] = nil
	plot.Model:Destroy()
	print("Economy world text passed: ten $12M/s nametags at 120x and $34.5B collection jar")
end

if snapshot then
	local Layout = loadModule(node("src/shared/Config/MapLayout"))
	-- Clearly named fixtures exercise the production board formatter in offline previews.
	for i = 1, 12 do
		boardPlayers[i] = { UserId = i, DisplayName = "Preview player " .. i }
	end
	World.Data = {
		Get = function(_, player)
			return {
				Coins = player.UserId * 1400,
				Stats = { Flushes = player.UserId * 410, RarestItemId = Items[player.UserId % #Items + 1].Id },
			}
		end,
	}
	World:RefreshLeaderboards()
	for i, entry in ipairs(Layout.Plots) do
		local plot = Plot.Build(root, CFrame.new(entry.X, 0, entry.Z) * CFrame.Angles(0, math.rad(entry.Yaw), 0), i)
		plot.Toilet = Models.Toilet(plot.Model, plot.CFrame, (i - 1) % 7 + 1, Layout.ToiletScale)
		plot.Sign.Text = "Preview owner's Plot"
		plot.Profile = { ToiletTier = (i - 1) % 7 + 1, DisplaySlots = 10, Displays = {} }
		for slot = 1, 10 do
			plot.Profile.Displays[tostring(slot)] = Items[(i + slot - 2) % #Items + 1].Id
		end
		plot.Owner = { UserId = i }
		World:RenderDisplays(plot)
	end
	for _, part in ipairs(root:GetDescendants()) do
		if isPart(part) and part.Transparency < 1 then
			local cf, color = part.CFrame, part.Color
			local values = {
				part.Size.X,
				part.Size.Y,
				part.Size.Z,
				color.R,
				color.G,
				color.B,
				cf.Position.X,
				cf.Position.Y,
				cf.Position.Z,
			}
			for _, v in ipairs(cf.R) do
				table.insert(values, v)
			end
			print(
				"SCENE|PART|"
					.. part.Name
					.. "|"
					.. part.ClassName
					.. "|"
					.. tostring(part.Shape)
					.. "|"
					.. tostring(part.Material)
					.. "|"
					.. table.concat(values, ",")
					.. "|"
					.. tostring(part.Parent:GetAttribute("SolidFinish") == true)
			)
		elseif part.ClassName == "TextLabel" and part.Text ~= "" then
			local gui = part.Parent
			local frame = if gui.ClassName == "Frame" then gui else nil
			if frame then
				gui = frame.Parent
			end
			if gui.ClassName ~= "SurfaceGui" and gui.ClassName ~= "BillboardGui" then
				continue
			end
			local anchor = gui.Parent
			local cf, size = anchor.CFrame, anchor.Size
			if frame then
				local w, h = frame.Size[1] * part.Size[1], frame.Size[2] * part.Size[2]
				local x = frame.Position[1] + frame.Size[1] * part.Position[1] + w / 2
				local y = frame.Position[2] + frame.Size[2] * part.Position[2] + h / 2
				cf *= CFrame.new((0.5 - x) * size.X, (0.5 - y) * size.Y, 0)
				size = Vector3.new(size.X * w, size.Y * h, size.Z)
			end
			local values = { size.X, size.Y, size.Z, cf.Position.X, cf.Position.Y, cf.Position.Z }
			for _, v in ipairs(cf.R) do
				table.insert(values, v)
			end
			local color = part.TextColor3
			print(
				"SCENE|LABEL|"
					.. part.Text:gsub("\n", "~"):gsub("|", "/")
					.. "|"
					.. table.concat(values, ",")
					.. "|"
					.. gui.ClassName
					.. "|"
					.. tostring(gui.MaxDistance)
					.. "|"
					.. table.concat({ color.R, color.G, color.B }, ",")
			)
		end
	end
end
do
	local hook = loadModule(node("src/server/World/RebirthHook"))
	local anchor = Instance.new("Part")
	local prompt = hook.Attach(anchor, { UserId = 123 })
	assert(prompt:GetAttribute("RebirthOwnerUserId") == 123 and prompt.Enabled)
	assert(hook.Attach(anchor, { UserId = 456 }) == prompt and prompt:GetAttribute("RebirthOwnerUserId") == 456)
	hook.Attach(anchor, nil)
	assert(not prompt.Enabled and prompt:GetAttribute("OwnerUserId") == 0)
	anchor:Destroy()
end
print(
	string.format(
		"Headless %s checks passed: hub %d parts; worst plot + drop %d; largest toilet %d, item %d; all 119 asset paths covered; %d normalized templates. Startup calls: %d.",
		testMode,
		hubCount,
		maxPlot,
		maxToilet,
		maxItem,
		configured,
		startupCalls
	)
)
print(
	string.format(
		"Hub: %d meshes, %d fallback models, %d uploaded triangles. Largest populated plot: %d meshes, %d uploaded triangles (primitives/particles/terrain excluded from triangle count).",
		hubMeshes,
		hubFallbacks,
		hubTriangles,
		maxPlotMeshes,
		maxPlotTriangles
	)
)
