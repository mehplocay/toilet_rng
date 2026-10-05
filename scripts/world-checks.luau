local P = loadModule(node("src/shared/Visuals/Primitives"))
local Toilets = loadModule(node("src/shared/Visuals/Toilets"))
local Items = loadModule(node("src/shared/Config/Items"))
local ItemBuilder = loadModule(node("src/shared/Visuals/Items"))
local V = loadModule(node("src/shared/Config/Visuals"))
local Catalog = loadModule(node("src/shared/Config/MeshCatalog"))
local Loader = loadModule(node("src/server/World/MeshLoader"))
local Models = loadModule(node("src/server/World/Models"))
local configured = 0
local names = {}
local sourceRoot = Instance.new("Model")
sourceRoot.Name = "ModelTemplates"
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
		model.Parent = sourceRoot
	end
end
for name in pairs(Catalog) do
	assert(manifest[name])
end
assert(#names == 31)
if testMode ~= "Empty" and testMode ~= "Late" then
	sourceRoot.Parent = storage
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
		if Catalog[name].Center then
			assert(model:GetAttribute("SeatHeight") == 2.08)
			local expected = Catalog[name].Center
			assert(math.abs(part.CFrame.Position.X - expected.X) < 0.001)
			assert(math.abs(part.CFrame.Position.Z + expected.Z) < 0.001)
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
assert(configured == (if testMode == "Ready" or testMode == "Scaled" then 31 elseif testMode == "Mixed" then 30 else 0))
local root = Instance.new("Folder")
local function checkAccents(model)
	local effect = loadModule(node("src/shared/Config/TemplateEffects"))[model:GetAttribute("MeshAsset")]
	if effect and not model:GetAttribute("MeshFallback") then
		local lights, emitters, bubbles = 0, 0, 0
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("PointLight") then
				lights += 1
			end
			if child:IsA("ParticleEmitter") then
				emitters += 1
				assert(child.Name == effect.Particles and child.Rate == 2)
			end
			if child.Name == "RadioactiveBubble" then
				bubbles += 1
			end
		end
		assert(lights == 1 and emitters == (if effect.Bubbles then 0 else 1))
		assert(bubbles == (if effect.Bubbles then 3 else 0))
		local count = #model:GetDescendants()
		loadModule(node("src/shared/Visuals/TemplateAccents")).Apply(model)
		assert(#model:GetDescendants() == count, "Accents duplicated")
	end
end
local function validate(container)
	for _, object in ipairs(container:GetDescendants()) do
		if isPart(object) then
			assert(object.Anchored, "Unanchored geometry: " .. object.Name)
			assert(not object.CanTouch, "Touch-enabled decoration: " .. object.Name)
			assert(object.CanCollide or not object.CanQuery, "Queryable decoration: " .. object.Name)
			assert(object.Size.X > 0 and object.Size.Y > 0 and object.Size.Z > 0, "Invalid part size")
			if object.ClassName == "MeshPart" then
				assert(not object.CanCollide and object.Color.R == 1 and object.Color.G == 1 and object.Color.B == 1)
				assert(object.TextureID ~= "" and object.Parent.ModelStreamingMode == Enum.ModelStreamingMode.Atomic)
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
local _, bestBoard = Hub.Build(root)
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
	local _, _, itemTriangles = stats(model)
	if P.Count(model) > maxItem or (P.Count(model) == maxItem and itemTriangles > maxItemTriangles) then
		maxItem, maxItemId = P.Count(model), item.Id
		maxItemTriangles = itemTriangles
	end
	recordAssets(model.Parent)
	validate(model)
	model:Destroy()
end
local World = loadModule(node("src/server/World/WorldService"))
local maxPlot, maxToilet, maxPlotMeshes, maxPlotTriangles = 0, 0, 0, 0
for tier = 1, 7 do
	local plot = Plot.Build(root, CFrame.new(), tier)
	assert(plot.Spawn:IsA("SpawnLocation") and plot.Spawn.Neutral and plot.Spawn.Enabled)
	assert(plot.Spawn.Transparency == 1 and not plot.Spawn.CanCollide and not plot.Spawn.AllowTeamChangeOnTouch)
	assert(plot.SpawnCFrame.Position.Z == -5 and plot.SpawnCFrame.Position.Y == 4.3)
	-- Preserve the original primitive tier contract used by client previews.
	local preview = Toilets.Build(root, CFrame.new(), tier, true)
	for _, name in ipairs({ "Bowl", "Tank", "Foot", "OpenLid", "FlushHandle", "Water", "Seat" }) do
		assert(preview:GetAttribute("MeshAsset") or preview:FindFirstChild(name), "Missing toilet component: " .. name)
	end
	preview:Destroy()
	plot.Toilet = Models.Toilet(plot.Model, plot.CFrame, tier)
	checkAccents(plot.Toilet)
	maxToilet = math.max(maxToilet, P.Count(plot.Toilet))
	local profile = { DisplaySlots = 100, Displays = {} }
	for slot = 1, 100 do
		profile.Displays[tostring(slot)] = maxItemId
	end
	plot.Profile = profile
	plot.Owner = { UserId = tier }
	for page = 1, 20 do
		plot.Page = page
		World:RenderDisplays(plot)
		assert(plot.IncomePoint.Parent == plot.Displays and plot.IncomePrompt.ActionText == "Collect")
		assert(plot.IncomePrompt:GetAttribute("IncomeOwnerUserId") == tier)
		local incomeVisual = loadModule(node("src/server/World/IncomeDisplay"))
		for _, pending in ipairs({ 0, 1, 10, 100, 0 }) do
			incomeVisual.Refresh(plot, plot.Owner, pending)
			for level, coin in ipairs(plot.IncomeCoins) do
				assert(coin.Transparency == (if pending >= ({ 1, 10, 100 })[level] then 0 else 1))
			end
		end
		local count = P.Count(plot.Model) + maxItem
		assert(count <= V.Budget.Plot, "Plot with transient drop exceeds budget: " .. count)
		-- FastFlush can briefly overlap two 1.5-second visuals at the Galaxy tier.
		assert(count + maxItem <= V.Budget.Plot, "Overlapping drops exceed plot budget")
		maxPlot = math.max(maxPlot, count)
		local meshes, _, triangles = stats(plot.Model)
		maxPlotMeshes = math.max(maxPlotMeshes, meshes)
		maxPlotTriangles = math.max(maxPlotTriangles, triangles)
		assert(plot.Displays:FindFirstChild("Slot" .. ((page - 1) * 5 + 1)), "Display page lost a slot")
	end
	recordAssets(plot.Model)
	validate(plot.Model)
	plot.Model:Destroy()
end
validate(root)
for name in pairs(Catalog) do
	assert(used[name], "No world placement covers " .. name)
end
assert(calls == startupCalls, "Building world/flush/display made a network request")
assert(templateClones == startupClones, "Placements renormalized cached templates")

if checkWorld then
	local Island = loadModule(node("src/server/World/Builders/Island"))
	Island.Build(terrain)
	assert(terrainWrites == 100 and terrainCells == 819200)
	for _, material in ipairs({ "Grass", "Sand", "Water", "Rock", "Air" }) do
		assert(terrainMaterials[Enum.Material[material]], "Missing terrain material: " .. material)
	end
	for x = -100, 100, 4 do
		for z = -100, 100, 4 do
			if x * x + z * z <= 106 * 106 then
				assert(Island.Height(x, z) == -0.35, "Gameplay core obstructed")
			end
		end
	end
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
		assert(warnings == 31, "Invalid templates must warn once and stay uncached")
	elseif testMode == "Late" then
		sourceRoot.Parent = storage
		assert(Loader.Status("Poop") == "Ready", "Late replication did not recover")
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

if snapshot then
	local Style = loadModule(node("src/shared/Config/World"))
	local Island = loadModule(node("src/server/World/Builders/Island"))
	for i = 1, 10 do
		local a = i * math.pi * 2 / 10
		local p = Vector3.new(math.sin(a) * Style.Radius, 0, math.cos(a) * Style.Radius)
		local plot = Plot.Build(root, CFrame.lookAt(p, Vector3.new()), i)
		plot.Toilet = Models.Toilet(plot.Model, plot.CFrame, (i - 1) % 7 + 1)
		plot.Profile = {
			DisplaySlots = 3,
			Displays = { ["1"] = Items[(i - 1) % 11 + 1].Id, ["2"] = "GoldenPoop", ["3"] = "Duck" },
		}
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
			)
		elseif part.ClassName == "TextLabel" and part.Parent.ClassName == "SurfaceGui" then
			print("SCENE|TEXT|" .. part.Parent.Parent.Name .. "|" .. part.Text:gsub("\n", "~"))
		end
	end
	for x = -320, 320, 4 do
		for z = -320, 320, 4 do
			print("SCENE|HEIGHT|" .. x .. "," .. z .. "," .. Island.Height(x, z))
		end
	end
end
print(
	string.format(
		"Headless %s checks passed: hub %d parts; worst plot + drop %d; largest toilet %d, item %d; all 31 asset paths covered; %d normalized templates. Startup calls: %d.",
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
