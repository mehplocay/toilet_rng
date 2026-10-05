local Shared = game.ReplicatedStorage.Shared
local P = require(Shared.Visuals.Primitives)
local Visuals, Style = require(Shared.Config.Visuals), require(Shared.Config.World)
local Settings = require(Shared.Config.WorldModels)
local Models = require(script.Parent.Parent.Models)
local Decor = require(script.Parent.Decor)
local Island = require(script.Parent.Island)
local V = Visuals.Palette
local Hub = {}
local function ground(cf)
	local position = cf.Position
	return cf + Vector3.new(0, Island.Height(position.X, position.Z) - 0.15 - position.Y, 0)
end
function Hub.Build(root)
	local hub = Instance.new("Model")
	hub.Name, hub.Parent = "Hub", root
	local random = Random.new(Settings.Seed)
	for x = -6, 5 do
		for z = -6, 5 do
			local tile = P.Part(
				hub,
				"PlazaTile",
				Vector3.new(5.92, 0.25, 5.92),
				CFrame.new(x * 6 + 3, 0.03, z * 6 + 3),
				Settings.PlazaTiles[(x + z) % 2 + 1]
			)
			tile.CanCollide = true
		end
	end
	for i = 1, 8 do
		local cf = CFrame.new(0, 0.19, 3) * CFrame.Angles(0, i * math.pi / 4, 0)
		P.Part(hub, "CompassInlay", Vector3.new(0.22, 0.04, 6), cf * CFrame.new(0, 0, 14), V.Gold)
		P.Part(
			hub,
			"CompassGem",
			Vector3.new(1.3, 0.05, 1.3),
			cf * CFrame.new(0, 0, 18) * CFrame.Angles(0, math.pi / 4, 0),
			V.Cyan
		)
	end
	for i = 1, Style.PlotCount do
		local angle = i * math.pi * 2 / Style.PlotCount
		local cf = CFrame.Angles(0, angle, 0)
		local pathColor = Settings.PathColors[(i - 1) % #Settings.PathColors + 1]
		for _, side in ipairs({ -1, 1 }) do
			P.Part(
				hub,
				"PlotPathStrip",
				Vector3.new(0.3, 0.12, 36),
				cf * CFrame.new(side * 3.2, 0.2, 53),
				pathColor,
				nil,
				Enum.Material.Neon
			)
		end
		for step = 0, 6 do
			local tile = P.Part(
				hub,
				"PlotPath",
				Vector3.new(7, 0.25, 5.2),
				cf * CFrame.new(0, 0.02, 37 + step * 5.3),
				if step % 2 == 0 then V.TileA else V.TileB
			)
			tile.CanCollide = true
		end
		local between = angle + math.pi / Style.PlotCount
		local treeRadius = if i == 4 or i == 6 or i == 10 then 112 else 53
		local tx, tz = math.sin(between) * treeRadius, math.cos(between) * treeRadius
		local treeCF = CFrame.new(tx, Island.Height(tx, tz), tz)
		Decor.Tree(hub, treeCF)
		Decor.Bush(hub, ground(treeCF * CFrame.new(4, 0, 1)))
		Decor.Flower(hub, ground(treeCF * CFrame.new(-3, 0, -2)), Color3.fromRGB(255, 111, 178))
		Decor.Bench(hub, CFrame.new(math.sin(between) * 32, 0, math.cos(between) * 32) * CFrame.Angles(0, between, 0))
		if i % 2 == 0 then
			Decor.Lamp(hub, cf * CFrame.new(6, 0, 38))
		end
		Decor.Cloud(hub, CFrame.new(math.sin(between) * 175, 53 + i % 3 * 8, math.cos(between) * 175), 6 + i % 3)
		if i % 2 == 0 then
			Decor.Cloud(hub, CFrame.new(math.sin(between + 0.4) * 235, 100 + i, math.cos(between + 0.4) * 235), 9)
		end
	end
	local fountain = CFrame.new(0, 0, 3)
	P.Cylinder(hub, "FountainStep", 9, 0.5, fountain * CFrame.new(0, 0.3, 0), V.TileA)
	P.Cylinder(hub, "FountainBasin", 7.5, 0.8, fountain * CFrame.new(0, 0.9, 0), V.Gold, Enum.Material.Metal)
	P.Cylinder(hub, "FountainWater", 6.8, 0.12, fountain * CFrame.new(0, 1.36, 0), V.Cyan)
	P.Ring(hub, "GoldenBasinRim", fountain * CFrame.new(0, 1.3, 0), 7.25, 7.25, 0.4, V.Gold, Enum.Material.Metal, 20)
	Decor.Trophy(hub, fountain * CFrame.new(0, 1.5, 0))
	Decor.Aura(hub, fountain * CFrame.new(0, 1.45, 0), 4.3, V.Gold)
	for i = 1, 4 do
		local a = i * math.pi / 2
		local nozzle = P.Ball(
			hub,
			"WaterJet",
			Vector3.new(0.4, 0.4, 0.4),
			fountain * CFrame.new(math.sin(a) * 2.5, 3.9, math.cos(a) * 2.5),
			V.Cyan,
			Enum.Material.Neon
		)
		local start = Instance.new("Attachment")
		start.CFrame = CFrame.Angles(0, 0, math.pi / 2)
		start.Parent = nozzle
		local finish = Instance.new("Attachment")
		finish.Position = Vector3.new(math.sin(a) * 3.2, -2.3, math.cos(a) * 3.2)
		finish.Parent = nozzle
		local beam = Instance.new("Beam")
		beam.Name, beam.Attachment0, beam.Attachment1 = "FountainStream", start, finish
		beam.FaceCamera, beam.Segments, beam.Width0, beam.Width1 = true, 6, 0.18, 0.12
		beam.CurveSize0, beam.CurveSize1, beam.LightEmission = 1.8, 1, 0.3
		beam.Color, beam.Transparency = ColorSequence.new(V.Cyan), NumberSequence.new(0.2)
		beam.Parent = nozzle
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.CFrame = "SpawnPad", Vector3.new(8, 0.4, 8), CFrame.new(0, 0.35, -24)
	spawn.Anchored, spawn.Neutral, spawn.CanTouch = true, true, false
	spawn.Color, spawn.Material = V.Cyan, Enum.Material.Neon
	spawn.TopSurface, spawn.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	spawn.Parent = hub
	Models.Label(spawn, "SPAWN\nWelcome to Toilet RNG!", Color3.new(1, 1, 1))
	P.Ring(hub, "SpawnHalo", CFrame.new(0, 0.45, -24), 5.7, 5.7, 0.18, V.Cyan, Enum.Material.Neon)
	for _, x in ipairs({ -22, 22 }) do
		P.Cylinder(hub, "BannerPost", 0.45, 14, CFrame.new(x, 7, 35), V.Gold, Enum.Material.Metal)
	end
	Decor.Sign(hub, CFrame.new(0, 13, 35), 42, 5, "TOILETS MAKE DREAMS COME TRUE!", V.Gold)
	local best =
		Decor.Sign(hub, CFrame.new(0, 17, 15), 27, 6, "BEST FLUSH EVER\nYour next flush could make history!", V.Gold)
	best.Parent.MaxDistance = 180
	for _, x in ipairs({ -14, 14 }) do
		P.Cylinder(hub, "RecordBoardPost", 0.25, 18, CFrame.new(x, 9, 15.5), V.Navy)
	end
	Decor.Sign(
		hub,
		CFrame.new(-36, 9, 17) * CFrame.Angles(0, -0.25, 0),
		16,
		5,
		"SHOP\nBetter toilets. Bigger dreams!",
		V.LeafLight
	)
	for tier = 1, 7 do
		local cf = CFrame.new((tier - 4) * 7, 0.4, 26)
		P.Cylinder(hub, "ShowcaseStand", 2.8, 0.6, cf, V.Navy)
		Models.Toilet(hub, cf * CFrame.new(0, 0.3, 0), tier)
	end
	local board = Decor.Sign(hub, CFrame.new(36, 9, 17) * CFrame.Angles(0, 0.25, 0), 17, 13, "Top Toilets", V.Gold)
	for _, portal in ipairs(Settings.Portals) do
		local position = Vector3.new(math.sin(portal.Angle) * 59, 0, math.cos(portal.Angle) * 59)
		Decor.Portal(hub, CFrame.lookAt(position, Vector3.new(0, 0, 0)), portal.Name, portal.Color)
	end
	-- Seeded coastal gardens sit beyond the playable plots; the central lanes stay clear.
	for i = 1, 32 do
		local angle = i * math.pi * 2 / 32 + random:NextNumber(-0.025, 0.025)
		local radius = random:NextNumber(112, 123)
		local x, z = math.sin(angle) * radius, math.cos(angle) * radius
		local cf = CFrame.new(x, Island.Height(x, z) - 0.15, z) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
		if i % 4 == 0 then
			Decor.Tree(hub, cf)
		end
		Decor.Bush(hub, ground(cf * CFrame.new(3, 0, 0)))
		if i % 2 == 0 then
			Decor.Rocks(hub, cf, random:NextNumber(1.2, 2))
		else
			Decor.Flower(hub, cf, Settings.PathColors[i % #Settings.PathColors + 1])
		end
		Decor.Foliage(hub, ground(cf * CFrame.new(-3, 0, -1)), random:NextNumber(0.65, 1.1))
	end
	-- Foreground framing for the spawn camera, without hiding the trophy or paths.
	for _, x in ipairs({ -18, 18 }) do
		local cf = CFrame.new(x, 0, -17)
		P.Cylinder(hub, "GardenPlanter", 2.8, 0.45, cf * CFrame.new(0, 0.3, 0), V.Navy)
		P.Cylinder(hub, "PlanterGrass", 2.5, 0.12, cf * CFrame.new(0, 0.57, 0), V.Grass)
		Decor.Bush(hub, cf * CFrame.new(0, 0.6, 0.4))
		Decor.Flower(hub, cf * CFrame.new(-1, 0.6, -1.3), Color3.fromRGB(255, 120, 177))
	end
	for _, x in ipairs({ -29, 29 }) do
		Decor.Tree(hub, CFrame.new(x, 0, -27))
		Decor.Foliage(hub, CFrame.new(x + 3, 0, -31), 1.35)
		Decor.Flower(hub, CFrame.new(x - 3, 0, -30), Color3.fromRGB(255, 120, 177))
	end
	hub:SetAttribute("PartCount", P.Count(hub))
	assert(P.Count(hub) <= Visuals.Budget.Hub, "Hub exceeds its visual part budget")
	return board, best
end
return Hub
