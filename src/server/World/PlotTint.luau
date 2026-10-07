-- Reversible solid finishes reuse imported geometry without atlas color multiplication.
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Tint = {}

function Tint.Capture(plot)
	if plot.TintSurfaces then
		return plot.TintSurfaces
	end
	local surfaces = {}
	for _, part in ipairs(plot.Model:GetDescendants()) do
		local role = part:GetAttribute("PlotTint")
		if part:IsA("BasePart") and (role or part.Name == "Lawn" or part.Name == "StoneBorder") then
			local finish = {
				Part = part,
				Role = if type(role) == "string" then role elseif part.Name == "StoneBorder" then "Trim" else "Floor",
				Color = part.Color,
				Material = part.Material,
				MaterialVariant = part.MaterialVariant,
				TextureID = if part:IsA("MeshPart") then part.TextureID else nil,
				Appearances = {},
			}
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture") then
					table.insert(finish.Appearances, child)
				end
			end
			table.insert(surfaces, finish)
		end
	end
	plot.TintSurfaces = surfaces
	return surfaces
end

function Tint.Apply(plot, rgb)
	local color = rgb and Color3.fromRGB(table.unpack(rgb))
	for _, finish in ipairs(Tint.Capture(plot)) do
		local part = finish.Part
		if part.Parent then
			if color then
				local style = Config.PlotColorStyle[finish.Role] or Config.PlotColorStyle.Floor
				part.Color = color:Lerp(Color3.fromRGB(table.unpack(style.RGB)), style.Blend)
				part.Material, part.MaterialVariant = Enum.Material.SmoothPlastic, ""
				if part:IsA("MeshPart") then
					part.TextureID = ""
				end
			else
				part.Color, part.Material, part.MaterialVariant = finish.Color, finish.Material, finish.MaterialVariant
				if part:IsA("MeshPart") then
					part.TextureID = finish.TextureID
				end
			end
			-- Preserve PBR objects, including maps that cannot be rewritten at runtime.
			for _, appearance in ipairs(finish.Appearances) do
				appearance.Parent = if color then nil else part
			end
		end
	end
end

function Tint.Reset(plot)
	Tint.Apply(plot, nil)
end
return Tint
