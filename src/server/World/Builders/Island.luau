local Settings = require(game.ReplicatedStorage.Shared.Config.WorldModels).Terrain
local Island = {}

-- A flat playable core, a scalloped sand shore, and staggered distant ridgelines.
-- Shared with prop placement so decorations follow the generated ground surface.
function Island.Height(x, z)
	local radius = math.sqrt(x * x + z * z)
	local angle = math.atan2(z, x)
	if radius <= Settings.PlateauRadius then
		return -0.35
	end
	local shore = Settings.ShoreRadius + math.sin(angle * 5) * 5 + math.cos(angle * 9) * 3
	local t = math.clamp((radius - Settings.PlateauRadius) / (shore - Settings.PlateauRadius), 0, 1)
	local height = -0.35 - t * t * 21
	-- Low grassy headlands grow only outside the plot ring.
	local headland = math.max(0, math.sin(angle * 3 + 0.6)) ^ 8
	height += headland * 13 * math.exp(-((radius - 119) / 9) ^ 2)
	for index = 1, 11 do
		local a = index * math.pi * 2 / 11 + 0.15
		local r = 236 + (index % 3) * 17
		local dx, dz = x - math.cos(a) * r, z - math.sin(a) * r
		local distance = math.max(math.abs(dx) * 0.8 + math.abs(dz) * 0.35, math.abs(dz) * 1.1 + math.abs(dx) * 0.15)
		local peak = 42 + (index % 4) * 12
		height = math.max(height, peak - distance * (1.15 + index % 3 * 0.16))
		local shoulder = math.abs(dx - 22) * 0.7 + math.abs(dz + 12) * 1.1
		local spur = math.abs(dx + 18) * 1.1 + math.abs(dz - 19) * 0.65
		height = math.max(height, peak * 0.72 - shoulder, peak * 0.58 - spur)
	end
	return math.max(Settings.Bottom + 4, height)
end

function Island.Build(terrain)
	local c = Settings
	local start = os.clock()
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(91, 198, 78))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(249, 220, 146))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(99, 132, 163))
	terrain.WaterColor = Color3.fromRGB(29, 177, 215)
	terrain.WaterTransparency, terrain.WaterReflectance = 0.3, 0.12
	terrain.WaterWaveSize, terrain.WaterWaveSpeed = 0.18, 7
	local chunks = 0
	for x0 = -c.Extent, c.Extent - c.Chunk, c.Chunk do
		for z0 = -c.Extent, c.Extent - c.Chunk, c.Chunk do
			local materials, occupancy = {}, {}
			for x = 1, c.Chunk / c.Resolution do
				materials[x], occupancy[x] = {}, {}
				local wx = x0 + (x - 0.5) * c.Resolution
				for y = 1, (c.Top - c.Bottom) / c.Resolution do
					materials[x][y], occupancy[x][y] = {}, {}
				end
				for z = 1, c.Chunk / c.Resolution do
					local wz = z0 + (z - 0.5) * c.Resolution
					local height = Island.Height(wx, wz)
					local radius = math.sqrt(wx * wx + wz * wz)
					for y = 1, (c.Top - c.Bottom) / c.Resolution do
						local bottom = c.Bottom + (y - 1) * c.Resolution
						local fill = math.clamp((height - bottom) / c.Resolution, 0, 1)
						local material = Enum.Material.Air
						if fill > 0 then
							material = if radius > 180 or bottom < height - 7
								then Enum.Material.Rock
								elseif radius > 112 and height < 2 then Enum.Material.Sand
								else Enum.Material.Grass
						elseif bottom < c.WaterLevel then
							material, fill =
								Enum.Material.Water, math.clamp((c.WaterLevel - bottom) / c.Resolution, 0, 1)
						end
						materials[x][y][z], occupancy[x][y][z] = material, fill
					end
				end
			end
			terrain:WriteVoxels(
				Region3.new(Vector3.new(x0, c.Bottom, z0), Vector3.new(x0 + c.Chunk, c.Top, z0 + c.Chunk)),
				c.Resolution,
				materials,
				occupancy
			)
			chunks += 1
			task.wait()
		end
	end
	terrain:SetAttribute("WorldChunks", chunks)
	terrain:SetAttribute("WorldGenerationSeconds", os.clock() - start)
end

return Island
