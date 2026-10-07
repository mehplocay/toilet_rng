-- Production paid/earned cosmetics share a plot without tinting the sign UI.
do
	local check = test or function(name, callback)
		callback()
		print("PASS " .. name)
	end
	check(
		"plot color: textured/PBR finishes restore exactly; VIP/rebirth coexist; next owner cannot inherit tint",
		function()
			local config = H.Load("src/shared/Config/Monetization")
			local player, model = H.Instance.new("Player"), H.Instance.new("Model")
			player.UserId, player.DisplayName = 982, "Style Tester"
			local sign = H.Instance.new("TextLabel")
			sign.Parent = model
			local part = H.Instance.new("MeshPart")
			part.Name, part.Parent = "VisibleFloor", model
			part.Color, part.Material, part.MaterialVariant, part.TextureID =
				H.Color3.new(1, 1, 1), Enum.Material.Concrete, "ImportedVariant", "fixture-atlas"
			part:SetAttribute("PlotTint", "Floor")
			local appearances = {}
			for _, class in ipairs({ "SurfaceAppearance", "Texture", "Decal" }) do
				local appearance = H.Instance.new(class)
				appearance.Parent = part
				table.insert(appearances, appearance)
			end
			local outside = H.Instance.new("MeshPart")
			outside.Name, outside.Parent, outside.TextureID = "Decoration", model, "fixture-decoration"
			local original = part.Color
			local plot = { Owner = player, Model = model, Sign = sign }
			local world = { Assigned = { [player] = plot } }
			local cosmetics = H.Load("src/server/Services/CosmeticService").new(world)
			local rebirth = H.Load("src/server/World/RebirthCosmetics")
			local profile = { Settings = { PlotColor = "Sky" }, RebirthLevel = 6 }
			cosmetics:Apply(player, { CustomPlotColor = true, VIPPack = true }, profile)
			rebirth.Plot(plot, 6)
			assert(part.TextureID == "" and part.MaterialVariant == "" and part.Color.B == 240 / 255)
			assert(outside.TextureID == "fixture-decoration" and sign.VIPTrim and sign.RebirthTrim)
			for _, appearance in ipairs(appearances) do
				assert(appearance.Parent == nil)
			end
			local count = #model:GetDescendants()
			for _ = 1, 10 do
				cosmetics:Apply(player, { CustomPlotColor = true, VIPPack = true }, profile)
			end
			assert(#model:GetDescendants() == count)
			profile.Settings.PlotColor = "Default"
			cosmetics:Apply(player, { CustomPlotColor = true, VIPPack = true }, profile)
			assert(
				part.Color == original
					and part.TextureID == "fixture-atlas"
					and part.Material == Enum.Material.Concrete
					and part.MaterialVariant == "ImportedVariant"
			)
			for _, appearance in ipairs(appearances) do
				assert(appearance.Parent == part)
			end
			profile.Settings.PlotColor = "Lavender"
			cosmetics:Apply(player, { CustomPlotColor = true }, profile)
			cosmetics:Apply(player, {}, profile)
			assert(part.Color == original and part.TextureID == "fixture-atlas")
			cosmetics:Apply(player, { CustomPlotColor = true, VIPPack = true }, profile)
			cosmetics:ResetPlot(plot)
			assert(
				part.Color == original and not sign:FindFirstChild("VIPTrim") and not sign:FindFirstChild("RebirthTrim")
			)
			local nextOwner = H.Instance.new("Player")
			nextOwner.UserId, nextOwner.DisplayName = 983, "Next Owner"
			plot.Owner, world.Assigned[nextOwner] = nextOwner, plot
			cosmetics:Apply(nextOwner, {}, { Settings = { PlotColor = "Default" } })
			assert(part.TextureID == "fixture-atlas" and part.Color == original)
			cosmetics:Apply(nextOwner, { CustomPlotColor = true }, { Settings = { PlotColor = "Rose" } })
			cosmetics:Remove(player)
			assert(part.Color.R == 235 / 255 and part.TextureID == "", "Late leave reset the next owner's choice")
			cosmetics:Remove(nextOwner)
			assert(part.Color == original and part.TextureID == "fixture-atlas")
			for _, appearance in ipairs(appearances) do
				assert(appearance.Parent == part)
			end
			model:Destroy()
			player:Destroy()
			nextOwner:Destroy()
		end
	)
end
