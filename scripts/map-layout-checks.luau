-- Runs inside the production world harness, using actual imported mesh metadata.
local Layout = loadModule(node("src/shared/Config/MapLayout"))
local Chooser = loadModule(node("src/shared/PlotChooser"))
assert(#Layout.Plots == 12 and #Layout.Slots == 10)
assert(
	loadModule(node("src/shared/Config/Upgrades")).DisplayCapacity == #Layout.Slots,
	"Coin upgrades exceed physical plot capacity"
)
assert(Layout.PlotWidth * Layout.PlotDepth == 2.5 * 32 * 36)
assert(Layout.PromenadeWidth >= 24 and Layout.HubRadius >= 90)
local function distance(a, b)
	return math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2)
end
for i, a in ipairs(Layout.Plots) do
	assert(math.abs(a.Yaw) == 90, "Plots must face the promenade")
	assert(distance(a, { X = 0, Z = 0 }) > 160, "Hub-to-plot distance is too small")
	for j, b in ipairs(Layout.Plots) do
		if j > i then
			assert(
				math.abs(a.X - b.X) >= Layout.PlotDepth + 16 or math.abs(a.Z - b.Z) >= Layout.PlotWidth + 16,
				"Overlapping plot/garden envelopes"
			)
		end
	end
end
for i, a in ipairs(Layout.Stations) do
	assert(distance(a, { X = 0, Z = 0 }) >= 80, "Station overlaps castle circulation")
	for j, b in ipairs(Layout.Stations) do
		if j > i then
			assert(distance(a, b) >= 60, "Stations are crowded")
		end
	end
	for _, plot in ipairs(Layout.Plots) do
		assert(distance(a, plot) > 64, "Station overlaps plot")
	end
end
for i, a in ipairs(Layout.Slots) do
	assert(math.abs(a.X) >= 14 and math.abs(a.Z) <= 20, "Stand obstructs the central carpet")
	for j, b in ipairs(Layout.Slots) do
		if j > i then
			assert((a - b).Magnitude >= 8, "Overlapping display stands")
		end
	end
end
local referenced = {}
for _, list in ipairs({ Layout.Pieces, Layout.PlotPieces }) do
	for _, piece in ipairs(list) do
		assert(Catalog[piece.Asset] and importedTemplates[piece.Asset], "Missing template: " .. piece.Asset)
		referenced[piece.Asset] = true
		assert(piece.Position.Magnitude < 2000 and piece.Yaw == piece.Yaw)
		assert(piece.Scale > 0 and piece.Scale <= 12)
	end
end
for name, entry in pairs(Catalog) do
	if entry.Folder == "EnvTemplates" then
		assert(
			referenced[name] or name == "CollectCoinJar" or name == "HubEdgeStraight",
			"Unused environment template: " .. name
		)
	end
end
-- Every occupied cell is reachable by a four-neighbor walking graph. The grid is
-- sampled at avatar clearance, using ACTUAL collision proxies rather than claimed graph edges.
local surfaces, obstacles, boundaries = {}, {}, {}
for _, part in ipairs(root:GetDescendants()) do
	if isPart(part) and part.CanCollide then
		local p, size = part.CFrame.Position, part.Size
		local box = { X = p.X, Z = p.Z, W = size.X, D = size.Z, Top = p.Y + size.Y / 2 }
		if part.Name == "WalkFloor" or part.Name == "PierDeck" then
			table.insert(surfaces, box)
		elseif part.Name == "PlotFloor" then
			-- The 0.35-stud overlay remains walkable above the continuous island floor.
			assert(box.Top <= 0.36)
		elseif part.Name == "Boundary" or part.Name == "PierRail" or part.Name == "PierEnd" then
			table.insert(boundaries, box)
		else
			table.insert(obstacles, box)
		end
	end
end
assert(#surfaces == #Layout.LandCells + 1 and #boundaries >= 40)
local function inside(x, z, b, margin)
	return math.abs(x - b.X) < b.W / 2 + margin and math.abs(z - b.Z) < b.D / 2 + margin
end
local function walkable(x, z)
	local floor = false
	for _, b in ipairs(surfaces) do
		if inside(x, z, b, 0.01) then
			floor = true
			break
		end
	end
	if not floor then
		return false
	end
	for _, list in ipairs({ obstacles, boundaries }) do
		for _, b in ipairs(list) do
			if inside(x, z, b, 2) then
				return false
			end
		end
	end
	return true
end
local function key(x, z)
	return x .. ":" .. z
end
local queue, visited = { { 0, -108 } }, { [key(0, -108)] = true }
local cursor = 1
while cursor <= #queue do
	local cell = queue[cursor]
	cursor += 1
	for _, delta in ipairs({ { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 } }) do
		local x, z = cell[1] + delta[1], cell[2] + delta[2]
		local id = key(x, z)
		if not visited[id] and walkable(x, z) then
			visited[id] = true
			table.insert(queue, { x, z })
		end
	end
end
local function reachable(x, z)
	assert(
		visited[key(math.floor(x / 4 + 0.5) * 4, math.floor(z / 4 + 0.5) * 4)],
		"Unreachable destination: " .. x .. ", " .. z
	)
end
for _, plot in ipairs(Layout.Plots) do
	reachable(plot.X, plot.Z)
	local yaw = math.rad(plot.Yaw)
	local cf = CFrame.new(plot.X, 0, plot.Z) * CFrame.Angles(0, yaw, 0)
	local spawn = (cf * CFrame.new(0, 4, 15)).Position
	reachable(spawn.X, spawn.Z)
	for _, slot in ipairs(Layout.Slots) do
		local point = (cf * CFrame.new(slot)).Position
		reachable(point.X, point.Z)
	end
end
for _, station in ipairs(Layout.Stations) do
	reachable(station.X, station.Z)
end
for _, x in ipairs({ -64, 0, 64 }) do
	reachable(x, 244)
end
reachable(0, -344)
-- No closed edge of a land tile lacks its safety wall (except the separately railed pier).
local cells = {}
for _, cell in ipairs(Layout.LandCells) do
	cells[key(cell[1], cell[2])] = true
end
for _, cell in ipairs(Layout.LandCells) do
	for _, d in ipairs({ { 48, 0 }, { -48, 0 }, { 0, 48 }, { 0, -48 } }) do
		if not cells[key(cell[1] + d[1], cell[2] + d[2])] then
			local x, z = cell[1] + d[1] / 2, cell[2] + d[2] / 2
			if not (x == 0 and z == -312) then
				local wall = false
				for _, b in ipairs(boundaries) do
					if inside(x, z, b, 0.01) then
						wall = true
						break
					end
				end
				assert(wall, "Unprotected island edge")
			end
		end
	end
end
-- Twelve-plot friendship selection uses physical nearest distance, not ring wraparound.
for mask = 0, 4095 do
	local owners = {}
	for i = 1, 12 do
		owners[i] = if bit32.band(mask, bit32.lshift(1, i - 1)) ~= 0 then i else false
	end
	for friend = 1, 12 do
		local chosen = Chooser.Choose(owners, { [friend] = true }, Layout.Plots)
		if chosen then
			assert(owners[chosen] == false)
			if owners[friend] then
				for candidate, owner in ipairs(owners) do
					if owner == false then
						assert(
							distance(Layout.Plots[chosen], Layout.Plots[friend])
								<= distance(Layout.Plots[candidate], Layout.Plots[friend]) + 0.001
						)
					end
				end
			end
		else
			assert(mask == 4095)
		end
	end
end
assert(hubCount + 12 * (maxPlot + maxItem) <= Layout.Budget.TotalParts, "Peak part budget")
assert(hubMeshes + 12 * (maxPlotMeshes + 2 * maxItemMeshes) <= Layout.Budget.Meshes, "Peak mesh budget")
assert(hubTriangles + 12 * (maxPlotTriangles + 2 * maxItemTriangles) <= Layout.Budget.Triangles, "Peak triangle budget")
assert(maxPlot + maxItem <= Layout.Budget.PlotParts)
assert(hubInstances + 12 * (maxPlotInstances + 2 * maxItemInstances) <= Layout.Budget.Instances, "Peak instance budget")
assert(12 * (maxPlotHighlights + 2 * maxItemHighlights) <= Layout.Budget.Highlights, "Peak highlight budget")
local persistent, persistentTriangles, beams = 0, 0, 0
for _, object in ipairs(root:GetDescendants()) do
	if object:GetAttribute("ResortSkyline") then
		persistent += 1
		persistentTriangles += Catalog[object:GetAttribute("MeshAsset")].Triangles
	end
	if object:IsA("Beam") then
		beams += 1
	end
	if isPart(object) and not object:IsA("MeshPart") and object.Transparency < 1 then
		assert(
			testMode == "Empty"
				or testMode == "Late"
				or testMode == "Invalid"
				or object.Parent:GetAttribute("MeshFallback"),
			"Visible non-kit geometry"
		)
	end
end
assert(persistent == 25 and persistentTriangles < 30000, "Skyline persistence budget")
assert(beams <= Layout.Budget.Beams)
print(
	string.format(
		"Peak envelope: %d parts, %d meshes, %d mesh triangles, %d instances; %d persistent skyline meshes / %d triangles; %d hub beams.",
		hubCount + 12 * (maxPlot + maxItem),
		hubMeshes + 12 * (maxPlotMeshes + 2 * maxItemMeshes),
		hubTriangles + 12 * (maxPlotTriangles + 2 * maxItemTriangles),
		hubInstances + 12 * (maxPlotInstances + 2 * maxItemInstances),
		persistent,
		persistentTriangles,
		beams
	)
)
print(
	string.format(
		"Map checks passed: 12 plots, 49,152 friend cases, %d reachable samples, 44 environment templates, separate walk/boundary collision and peak budgets.",
		#queue
	)
)
