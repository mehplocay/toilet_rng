local Shared = game.ReplicatedStorage.Shared
local P = require(Shared.Visuals.Primitives)
local Visuals, Style, Items = require(Shared.Config.Visuals), require(Shared.Config.World), require(Shared.Config.Items)
local Models = require(script.Parent.Parent.Models)
local Decor = require(script.Parent.Decor)
local V = Visuals.Palette
local Hub = {}
function Hub.Build(root)
	local hub = Instance.new("Model")
	hub.Name, hub.Parent = "Hub", root
	local ground = P.Part(hub, "IslandLawn", Vector3.new(240, 2, 240), CFrame.new(0, -1.1, 0), V.Grass)
	ground.CanCollide, ground.CanQuery = true, true
	for x = -6, 5 do
		for z = -6, 5 do
			local tile = P.Part(
				hub,
				"PlazaTile",
				Vector3.new(5.92, 0.25, 5.92),
				CFrame.new(x * 6 + 3, 0.03, z * 6 + 3),
				if (x + z) % 2 == 0 then V.TileA else V.TileB
			)
			tile.CanCollide = true
		end
	end
	for i = 1, Style.PlotCount do
		local angle = i * math.pi * 2 / Style.PlotCount
		local cf = CFrame.Angles(0, angle, 0)
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
		local treeCF = CFrame.new(math.sin(between) * 53, 0, math.cos(between) * 53)
		Decor.Tree(hub, treeCF)
		Decor.Bush(hub, treeCF * CFrame.new(4, 0, 1))
		Decor.Flower(hub, treeCF * CFrame.new(-3, 0, -2), Color3.fromRGB(255, 111, 178))
		Decor.Bench(hub, CFrame.new(math.sin(between) * 32, 0, math.cos(between) * 32) * CFrame.Angles(0, between, 0))
		if i % 2 == 0 then
			Decor.Lamp(hub, cf * CFrame.new(6, 0, 38))
		end
		local cloud = CFrame.new(math.sin(between) * 135, 58 + i % 3 * 7, math.cos(between) * 135)
		for puff = -1, 1 do
			local part = P.Ball(
				hub,
				"CloudPuff",
				Vector3.new(16, 8 + (1 - math.abs(puff)) * 4, 12),
				cloud * CFrame.new(puff * 9, 0, 0),
				Color3.fromRGB(245, 253, 255)
			)
			part.CastShadow = false
		end
		Decor.Fence(hub, cf * CFrame.new(0, 0, 114), 26)
	end
	local fountain = CFrame.new(0, 0, 3)
	P.Cylinder(hub, "FountainStep", 9, 0.5, fountain * CFrame.new(0, 0.3, 0), V.TileA)
	P.Cylinder(hub, "FountainBasin", 7.5, 0.8, fountain * CFrame.new(0, 0.9, 0), V.Gold, Enum.Material.Metal)
	P.Cylinder(hub, "FountainWater", 6.8, 0.12, fountain * CFrame.new(0, 1.36, 0), V.Cyan)
	P.Ring(hub, "GoldenBasinRim", fountain * CFrame.new(0, 1.3, 0), 7.25, 7.25, 0.4, V.Gold, Enum.Material.Metal, 20)
	P.Cylinder(hub, "TrophyPlinth", 2.8, 2.8, fountain * CFrame.new(0, 2.9, 0), V.Gold, Enum.Material.Metal)
	for _, item in ipairs(Items) do
		if item.Id == "KingPoop" then
			local trophy = require(Shared.Visuals.Items).Build(hub, fountain * CFrame.new(0, 5.6, 0), item, true)
			trophy.Name = "KingPoopTrophy"
			trophy:ScaleTo(2.7)
		end
	end
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
	hub:SetAttribute("PartCount", P.Count(hub))
	assert(P.Count(hub) <= Visuals.Budget.Hub, "Hub exceeds its visual part budget")
	return board
end
return Hub
