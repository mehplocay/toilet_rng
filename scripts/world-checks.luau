local P = loadModule(node("src/shared/Visuals/Primitives"))
local Toilets = loadModule(node("src/shared/Visuals/Toilets"))
local Items = loadModule(node("src/shared/Config/Items"))
local ItemBuilder = loadModule(node("src/shared/Visuals/Items"))
local V = loadModule(node("src/shared/Config/Visuals"))
local Catalog = loadModule(node("src/shared/Config/MeshCatalog"))
local Assets = loadModule(node("src/shared/Config/Assets"))
local Loader = loadModule(node("src/server/World/MeshLoader"))
local Models = loadModule(node("src/server/World/Models"))
local configured = 0
local names = {}
for name, entry in pairs(manifest) do
	assert(Catalog[name] and Assets.Meshes[name], "Missing catalog/ID slot: " .. name)
	assert((Catalog[name].Size - entry.Size).Magnitude < 0.00001, "Manifest size drift: " .. name)
	assert(Catalog[name].Triangles == entry.Triangles, "Manifest triangle drift: " .. name)
	if Assets.Meshes[name].MeshId ~= "" then
		configured += 1
	end
	table.insert(names, name)
end
for name in pairs(Catalog) do
	assert(manifest[name], "Unexpected catalog asset: " .. name)
end
for name in pairs(Assets.Meshes) do
	assert(manifest[name], "Unexpected mesh ID slot: " .. name)
end
assert(#names == 31)
table.sort(names)
-- These IDs only reach the mock InsertService; they are never written into production.
for index, name in ipairs(names) do
	Assets.Meshes[name] = {
		MeshId = if testMode == "Empty" then "" else tostring(index),
		TextureId = if testMode == "Empty" then "" else tostring(index + 100),
	}
end
Loader.Preload()
local startupCalls = calls
Loader.Preload()
assert(calls == startupCalls, "Repeated warm requested assets twice")
if testMode == "Empty" then
	assert(calls == 0)
elseif testMode == "Timeout" then
	assert(calls == 4 and clock >= 8 and clock < 9)
else
	assert(calls == 31)
end
local root = Instance.new("Folder")
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
	local preview = ItemBuilder.Build(root, CFrame.new(), item)
	assert(preview.PrimaryPart and P.Count(preview) > 4, item.Id .. " missing preview geometry")
	validate(preview)
	preview:Destroy()
	local model = Models.Item(root, CFrame.new(), item)
	assert(model.PrimaryPart)
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
	local preview = Toilets.Build(root, CFrame.new(), tier)
	for _, name in ipairs({ "Bowl", "Tank", "Foot", "OpenLid", "FlushHandle", "Water", "Seat" }) do
		assert(preview:FindFirstChild(name), "Missing toilet component: " .. name)
	end
	preview:Destroy()
	plot.Toilet = Models.Toilet(plot.Model, plot.CFrame, tier)
	maxToilet = math.max(maxToilet, P.Count(plot.Toilet))
	local profile = { DisplaySlots = 100, Displays = {} }
	for slot = 1, 100 do
		profile.Displays[tostring(slot)] = maxItemId
	end
	plot.Profile = profile
	for page = 1, 20 do
		plot.Page = page
		World:RenderDisplays(plot)
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
	if testMode == "Ready" then
		assert(preloads == 31 and warnings == 0 and #services.ServerStorage:GetChildren() == 1)
		local a = Models.Toilet(root, CFrame.new(5, 2, 7), 2)
		local b = Models.Toilet(root, CFrame.new(-5, 2, -7), 2)
		assert(
			a.PrimaryPart ~= b.PrimaryPart and (a:GetPivot().Position - Vector3.new(5, 2, 7)).Magnitude < 0.0001,
			"Pivot/clone isolation failed"
		)
		a.PrimaryPart.TextureID = "mutated only in mock"
		a:Destroy()
		assert(b.PrimaryPart.TextureID ~= "mutated only in mock")
		b:Destroy()
	elseif testMode == "Denied" or testMode == "TextureFailure" then
		assert(
			warnings == 31 and #services.ServerStorage:GetChildren()[1]:GetChildren() == 0,
			"Failed templates leaked"
		)
	elseif testMode == "Mixed" then
		assert(warnings == 1 and hubMeshes > 0 and hubFallbacks > 0, "Mixed success/failure was not exercised")
	elseif testMode == "Timeout" then
		for _, co in ipairs(tasks) do
			while coroutine.status(co) ~= "dead" do
				assert(coroutine.resume(co))
			end
		end
		assert(calls == 31 and Loader.Status("Poop") == "Ready", "Late warm could not recover")
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
		"Headless %s checks passed: hub %d parts; worst plot + drop %d; largest toilet %d, item %d; all 31 asset paths covered; %d configured upload IDs. Startup calls: %d.",
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
