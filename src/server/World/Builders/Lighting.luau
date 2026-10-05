local Lighting = game:GetService("Lighting")
local Visuals = require(game.ReplicatedStorage.Shared.Config.Visuals)
local Builder = {}
function Builder.Build()
	for key, value in pairs(Visuals.Lighting) do
		Lighting[key] = value
	end
	Lighting.ClockTime = 15.1
	Lighting.GeographicLatitude = 18
	Lighting.Ambient = Color3.fromRGB(66, 91, 155)
	Lighting.OutdoorAmbient = Color3.fromRGB(99, 149, 198)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 218, 160)
	for _, name in ipairs({ "ToyAtmosphere", "ToyBloom", "ToyColor", "ToySunRays", "IslandSky" }) do
		local old = Lighting:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "ToyAtmosphere"
	atmosphere.Color, atmosphere.Decay = Color3.fromRGB(148, 212, 255), Color3.fromRGB(255, 223, 172)
	atmosphere.Density, atmosphere.Offset, atmosphere.Haze, atmosphere.Glare = 0.22, 0.1, 1.1, 0.12
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "ToyBloom", 0.24, 24, 1.15
	bloom.Parent = Lighting
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name, correction.Saturation, correction.Contrast = "ToyColor", 0.18, 0.08
	correction.TintColor = Color3.fromRGB(255, 250, 244)
	correction.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Name, rays.Intensity, rays.Spread = "ToySunRays", 0.025, 0.7
	rays.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.Name, sky.StarCount, sky.SunAngularSize, sky.MoonAngularSize = "IslandSky", 0, 12, 0
	sky.CelestialBodiesShown = true
	-- Retain Roblox's built-in default sky textures; no unowned skybox assets.
	sky.Parent = Lighting
	local terrain = workspace.Terrain
	local oldClouds = terrain:FindFirstChild("IslandClouds")
	if oldClouds then
		oldClouds:Destroy()
	end
	local clouds = Instance.new("Clouds")
	clouds.Name, clouds.Cover, clouds.Density = "IslandClouds", 0.32, 0.45
	clouds.Color, clouds.Parent = Color3.fromRGB(255, 247, 232), terrain
end
return Builder
