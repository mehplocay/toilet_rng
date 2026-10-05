-- Terrain is ocean only. All visible land comes from Blender meshes in MapLayout.
local Island = {}
function Island.Height()
	return 0
end
function Island.Build(terrain)
	terrain.WaterColor = Color3.fromRGB(28, 185, 205)
	terrain.WaterTransparency, terrain.WaterReflectance = 0.25, 0.15
	terrain.WaterWaveSize, terrain.WaterWaveSpeed = 0.18, 7
	terrain:FillBlock(CFrame.new(0, -25, 0), Vector3.new(1536, 20, 1536), Enum.Material.Water)
end
return Island
