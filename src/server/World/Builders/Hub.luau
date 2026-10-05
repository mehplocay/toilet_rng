local Shared = game.ReplicatedStorage.Shared
local Kit = require(script.Parent.Parent.Kit)
local Layout = require(Shared.Config.MapLayout)
local P = require(Shared.Visuals.Primitives)
local Hub = {}
local white, cyan = Color3.new(1, 1, 1), Color3.fromRGB(95, 255, 237)
local function board(parent, entry)
	local cf = CFrame.new(entry.X, 0, entry.Z)
	local model = Instance.new("Model")
	model.Name, model.Parent = entry.Key .. "Leaderboard", parent
	Kit.Proxy(model, "BoardFootprint", cf * CFrame.new(0, 18, 0), Vector3.new(46, 36, 8), true)
	Kit.Place(
		model,
		{ Asset = "GrassSlab", Position = Vector3.new(), Size = Vector3.new(36, 0.5, 29), Solid = { 18, 38, 83 } },
		cf * CFrame.new(0, 18, 0) * CFrame.Angles(math.pi / 2, 0, 0)
	)
	Kit.Place(model, {
		Asset = "MountainRidgeC",
		Position = Vector3.new(0, 33, 0),
		Size = Vector3.new(45, 5, 1),
		Solid = { 26, 70, 142 },
	}, cf)
	for _, x in ipairs({ -20, 20 }) do
		Kit.Place(model, { Asset = "RocksCrystals", Position = Vector3.new(x, 0, 0), Size = Vector3.new(5, 33, 5) }, cf)
		Kit.Beam(model, cf, "CrystalEdge", Vector3.new(x, 2, -3), Vector3.new(x, 34, -3), cyan, 0.35, 0.1)
	end
	Kit.Place(model, { Asset = "HubEdgeStraight", Position = Vector3.new(0, 0, 0), Size = Vector3.new(46, 1.4, 8) }, cf)
	Kit.Label(model, "Title", cf * CFrame.new(0, 35.6, -1), Vector3.new(36, 4.5, 0.1), entry.Title, white, false, 200)
	local heading = Kit.Label(
		model,
		"ServerRanking",
		cf * CFrame.new(0, 18.2, -0.35),
		Vector3.new(33, 27, 0.1),
		"THIS SERVER\nWaiting for players",
		white,
		false,
		150
	)
	Kit.Label(
		model,
		"Scope",
		cf * CFrame.new(0, 2.8, -2),
		Vector3.new(32, 1.5, 0.1),
		"THIS SERVER  /  UPDATES EVERY 10s",
		cyan,
		false,
		120
	)
	heading.Text = ""
	local rows = {}
	for rank = 1, 12 do
		local frame = Instance.new("Frame")
		frame.Name = "Rank" .. rank
		frame.Position, frame.Size = UDim2.fromScale(0.02, (rank - 1) / 12), UDim2.fromScale(0.96, 0.077)
		frame.BackgroundColor3 = if rank % 2 == 0 then Color3.fromRGB(29, 63, 116) else Color3.fromRGB(18, 42, 88)
		frame.BorderSizePixel, frame.Parent = 0, heading.Parent
		local name, value = Instance.new("TextLabel"), Instance.new("TextLabel")
		for _, label in ipairs({ name, value }) do
			label.BackgroundTransparency, label.TextScaled, label.RichText = 1, true, false
			label.Font, label.TextColor3 = Enum.Font.FredokaOne, white
			label.Text, label.Parent = "", frame
		end
		name.Position, name.Size = UDim2.fromScale(0.03, 0.1), UDim2.fromScale(0.60, 0.8)
		name.TextXAlignment = Enum.TextXAlignment.Left
		value.Position, value.Size = UDim2.fromScale(0.65, 0.1), UDim2.fromScale(0.32, 0.8)
		value.TextXAlignment, value.TextColor3 = Enum.TextXAlignment.Right, cyan
		if rank == 1 then
			name.Text = "Waiting for players"
		end
		rows[rank] = { Name = name, Value = value }
	end
	return rows
end
function Hub.Build(root)
	local hub = Instance.new("Model")
	hub.Name, hub.Parent = "Hub", root
	local groups = {}
	for _, entry in ipairs(Layout.Pieces) do
		local group = entry.Group or "Scenery"
		if not groups[group] then
			local folder = Instance.new("Folder")
			folder.Name, folder.Parent = group, hub
			groups[group] = folder
		end
		Kit.Place(groups[group], entry)
	end
	local collision = Instance.new("Folder")
	collision.Name, collision.Parent = "Walkability", hub
	local occupied = {}
	for _, cell in ipairs(Layout.LandCells) do
		occupied[cell[1] .. ":" .. cell[2]] = true
	end
	for _, cell in ipairs(Layout.LandCells) do
		local x, z = cell[1], cell[2]
		Kit.Proxy(collision, "WalkFloor", CFrame.new(x, -0.5, z), Vector3.new(48, 1, 48), true)
		for _, direction in ipairs({ { 48, 0 }, { -48, 0 }, { 0, 48 }, { 0, -48 } }) do
			local dx, dz = direction[1], direction[2]
			if not occupied[(x + dx) .. ":" .. (z + dz)] then
				local cf = CFrame.new(x + dx / 2, 20, z + dz / 2)
				local size = if dx == 0 then Vector3.new(48, 40, 2) else Vector3.new(2, 40, 48)
				if x == 0 and z == -288 and dz == -48 then
					for _, side in ipairs({ -1, 1 }) do
						Kit.Proxy(collision, "Boundary", cf * CFrame.new(side * 14, 0, 0), Vector3.new(20, 40, 2), true)
					end
				else
					Kit.Proxy(collision, "Boundary", cf, size, true)
				end
			end
		end
	end
	Kit.Proxy(collision, "CastleFootprint", CFrame.new(0, 7, 0), Vector3.new(84, 14, 70), true)
	Kit.Proxy(collision, "PierDeck", CFrame.new(0, -0.5, -332), Vector3.new(8, 1, 40), true)
	for _, x in ipairs({ -5, 5 }) do
		Kit.Proxy(collision, "PierRail", CFrame.new(x, 20, -332), Vector3.new(2, 40, 40), true)
	end
	Kit.Proxy(collision, "PierEnd", CFrame.new(0, 20, -352), Vector3.new(12, 40, 2), true)
	-- Stable legacy travel anchors; coordinates also live in MapLayout for streamed-out travel.
	Kit.Proxy(hub, "SpawnPad", CFrame.new(Layout.HubArrival - Vector3.new(0, 4, 0)), Vector3.new(2, 0.1, 2), false)
	Kit.Proxy(
		hub,
		"ShowcaseStand",
		CFrame.new(Layout.ShopArrival - Vector3.new(0, 4, -8)),
		Vector3.new(2, 0.1, 2),
		false
	)
	for _, station in ipairs(Layout.Stations) do
		local cf = CFrame.new(station.X, 0.15, station.Z) * CFrame.Angles(0, math.rad(station.Yaw), 0)
		Kit.Label(
			hub,
			station.Name .. "Billboard",
			cf * CFrame.new(0, 26, 0),
			Vector3.new(22, 4.5, 0.1),
			string.upper(station.Name) .. (if station.ComingSoon then "\nComing soon" else ""),
			white,
			true,
			250
		)
		if not station.ComingSoon then
			local anchor =
				Kit.Proxy(hub, station.Name .. "Interaction", cf * CFrame.new(0, 3, -9), Vector3.new(1, 1, 1), false)
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText, prompt.ObjectText = "Open", station.Name
			prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 12, false
			prompt:SetAttribute("StationPanel", station.Panel)
			prompt.Parent = anchor
		end
	end
	Kit.Label(
		hub,
		"UpgradeHint",
		CFrame.new(66, 23, -66),
		Vector3.new(26, 2.6, 0.1),
		"Better toilets = new drops + higher odds!",
		Color3.fromRGB(139, 255, 155),
		true,
		120
	)
	for _, gate in ipairs({ { "SEWER", -64 }, { "SPACE", 0 }, { "HELL", 64 } }) do
		Kit.Label(
			hub,
			"PortalBillboard",
			CFrame.new(gate[2], 29, 260),
			Vector3.new(23, 7, 0.1),
			gate[1] .. "\nComing soon",
			white,
			true,
			200
		)
	end
	local boards = {}
	for _, entry in ipairs(Layout.Boards) do
		boards[entry.Key] = board(hub, entry)
	end
	local best = Kit.Label(
		hub,
		"BestFlushBoard",
		CFrame.new(0, 58, -37),
		Vector3.new(58, 12, 0.1),
		"BEST FLUSH EVER\nYour legendary moment starts here",
		Color3.fromRGB(255, 220, 100),
		true,
		350
	)
	Kit.Label(
		hub,
		"ResortBanner",
		CFrame.new(0, 15, -39),
		Vector3.new(60, 4, 0.1),
		"TOILETS MAKE DREAMS COME TRUE!",
		white,
		false,
		180
	)
	for _, x in ipairs({ -38, 38 }) do
		for _, z in ipairs({ -29, 29 }) do
			Kit.Beam(
				hub,
				CFrame.new(),
				"CastleAura",
				Vector3.new(x, 2, z),
				Vector3.new(x * 0.7, 112, z * 0.7),
				Color3.fromRGB(255, 212, 76),
				7,
				0.72
			)
		end
	end
	for _, x in ipairs({ -114, 114 }) do
		for _, z in ipairs({ -240, -144, -48, 48, 144, 240 }) do
			Kit.Chevron(hub, CFrame.new(x, 0.28, z) * CFrame.Angles(0, if z < 0 then math.pi else 0, 0), 2)
		end
	end
	for _, z in ipairs({ -124, 100, 204, 236 }) do
		Kit.Chevron(hub, CFrame.new(0, 0.28, z) * CFrame.Angles(0, math.pi, 0), 2.5)
	end
	for _, entry in ipairs(Layout.Wayfinding) do
		Kit.Chevron(hub, CFrame.new(entry.Position) * CFrame.Angles(0, math.rad(entry.Yaw), 0), entry.Scale)
	end
	hub:SetAttribute("PartCount", P.Count(hub))
	assert(P.Count(hub) <= Layout.Budget.HubParts, "Hub exceeds map budget")
	return boards, best
end
return Hub
