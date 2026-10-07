-- Run with imported and fallback templates in every world scenario.
do
	local tint = loadModule(node("src/server/World/PlotTint"))
	local config = loadModule(node("src/shared/Config/Monetization"))
	local layout = loadModule(node("src/shared/Config/MapLayout"))
	for index, placement in ipairs(layout.Plots) do
		local plot = Plot.Build(
			root,
			CFrame.new(placement.X, 0, placement.Z) * CFrame.Angles(0, math.rad(placement.Yaw), 0),
			index
		)
		local surfaces = tint.Capture(plot)
		local roles = { Floor = 0, Carpet = 0, Trim = 0 }
		local originals = {}
		for _, part in ipairs(plot.Model:GetDescendants()) do
			if part:IsA("BasePart") then
				originals[part] = {
					Color = part.Color,
					Size = part.Size,
					CFrame = part.CFrame,
					Texture = part.TextureID,
					Material = part.Material,
					Collide = part.CanCollide,
				}
			end
		end
		for _, surface in ipairs(surfaces) do
			roles[surface.Role] += 1
			local asset = surface.Part.Parent.Name
			assert(
				(surface.Role == "Floor" and asset == "PlotPlatform")
					or (surface.Role == "Carpet" and asset == "GrassSlab")
					or (surface.Role == "Trim" and (asset == "PlotFenceSection" or asset == "WoodenFence")),
				"Wrong mesh received a tint role"
			)
		end
		assert(
			#surfaces == 10 and roles.Floor == 1 and roles.Carpet == 1 and roles.Trim == 8,
			"Wrong visible plot pieces marked"
		)
		for _, choice in ipairs(config.PlotColors) do
			tint.Apply(plot, choice.RGB)
			for part, original in pairs(originals) do
				local role = part:GetAttribute("PlotTint")
				if role and choice.RGB then
					local style = config.PlotColorStyle[role]
					local expected = Color3.fromRGB(unpack(choice.RGB))
						:Lerp(Color3.fromRGB(unpack(style.RGB)), style.Blend)
					assert(
						math.abs(part.Color.R - expected.R) < 1e-9
							and math.abs(part.Color.G - expected.G) < 1e-9
							and math.abs(part.Color.B - expected.B) < 1e-9
					)
					assert(part.Material == Enum.Material.SmoothPlastic)
					if part:IsA("MeshPart") then
						assert(part.TextureID == "")
					end
				else
					assert(
						part.Color == original.Color and part.TextureID == original.Texture,
						"Tint escaped its authored pieces"
					)
				end
				assert(
					part.Size == original.Size
						and part.CFrame == original.CFrame
						and part.CanCollide == original.Collide
				)
			end
		end
		local owner = { UserId = 972 }
		World.Assigned[owner], plot.Owner = plot, owner
		World:Release(owner)
		assert(not plot.Owner and not World.Assigned[owner])
		tint.Reset(plot)
		for part, original in pairs(originals) do
			if part:GetAttribute("PlotTint") then
				assert(
					part.Color == original.Color
						and part.Material == original.Material
						and part.TextureID == original.Texture,
					"Release lost the original finish"
				)
			end
		end
		assert(tint.Capture(plot) == surfaces, "Originals recaptured after tint")
		plot.Model:Destroy()
	end
	print("Plot tint world: 12 rotated plots, 10 targeted pieces, all colors, geometry unchanged and exact reset")
end
