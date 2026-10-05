local Lighting = game:GetService("Lighting")
local Visuals = require(game.ReplicatedStorage.Shared.Config.Visuals)
local Builder = {}
function Builder.Build()
	for key, value in pairs(Visuals.Lighting) do
		Lighting[key] = value
	end
	for _, name in ipairs({ "ToyAtmosphere", "ToyBloom", "ToyColor", "ToySunRays" }) do
		local old = Lighting:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "ToyAtmosphere"
	atmosphere.Color, atmosphere.Decay = Color3.fromRGB(148, 212, 255), Color3.fromRGB(255, 223, 172)
	atmosphere.Density, atmosphere.Offset, atmosphere.Haze, atmosphere.Glare = 0.22, 0.25, 1, 0.08
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "ToyBloom", 0.16, 18, 1.2
	bloom.Parent = Lighting
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name, correction.Saturation, correction.Contrast = "ToyColor", 0.16, 0.035
	correction.TintColor = Color3.fromRGB(255, 250, 244)
	correction.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Name, rays.Intensity, rays.Spread = "ToySunRays", 0.025, 0.7
	rays.Parent = Lighting
end
return Builder
