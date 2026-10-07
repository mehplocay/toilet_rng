test(
	"plot color: handler validates ownership, IDs, payload and rate limit; persists through save/rejoin/rebirth",
	function()
		local e = server()
		local player, profile = rebirthReady(e, 972)
		local monetization = e:Load("src/server/Services/MonetizationService")
		-- Add a visible mesh to the server fixture, with faithful Color3 interpolation.
		local fromRGB = e.Globals.Color3.fromRGB
		e.Globals.Color3.fromRGB = function(r, g, b)
			local color = fromRGB(r, g, b)
			function color:Lerp(other, amount)
				return fromRGB(
					(self.R + (other.R - self.R) * amount) * 255,
					(self.G + (other.G - self.G) * amount) * 255,
					(self.B + (other.B - self.B) * amount) * 255
				)
			end
			return color
		end
		local plot = e.World.Assigned[player]
		local part = {
			Parent = plot.Model,
			Name = "InsetLawn",
			Color = fromRGB(255, 255, 255),
			TextureID = "fixture-atlas",
			Material = "fixture-material",
			MaterialVariant = "",
			IsA = function(_, class)
				return class == "BasePart" or class == "MeshPart"
			end,
			GetAttribute = function(_, key)
				return if key == "PlotTint" then "Floor" else nil
			end,
			GetChildren = function()
				return {}
			end,
		}
		plot.TintSurfaces = nil
		plot.Model.GetDescendants = function()
			return { part }
		end
		e:Fire("PlotColor", player, "Mint")
		assert(profile.Settings.PlotColor == "Default")
		monetization.Owned[player] = { CustomPlotColor = true }
		for _, bad in ipairs({ {}, 42, true, 0 / 0, "Unknown", string.rep("x", 10000) }) do
			e.Now += 2
			e:Fire("PlotColor", player, bad)
			assert(profile.Settings.PlotColor == "Default")
		end
		e.Now += 2
		e:Fire("PlotColor", player, "Mint", "extra")
		assert(profile.Settings.PlotColor == "Default")
		e:Fire("PlotColor", player, "Mint")
		assert(profile.Settings.PlotColor == "Mint")
		assert(
			part.TextureID == "" and part.Color.G == 210 / 255,
			"Remote selection did not immediately recolor the mesh"
		)
		local last = e.Results[#e.Results]
		assert(last.Payload[1].Settings.PlotColor == "Mint", "Selection did not sync instantly")
		e:Fire("PlotColor", player, "Mint")
		e:Fire("PlotColor", player, "Mint")
		e:Fire("PlotColor", player, "Rose")
		assert(profile.Settings.PlotColor == "Mint", "Rate limit bypass")
		e.Now += 6
		e:Fire("Rebirth", player, 0)
		local replacement = e.Data:Get(player)
		assert(replacement ~= profile and replacement.Settings.PlotColor == "Mint")
		assert(part.TextureID == "" and part.Color.G == 210 / 255)
		assert(e.Store.Records.Player_972.Data.Settings.PlotColor == "Mint")
		e.Data:Close(player)
		player.Parent = nil
		local joined, saved = e:Join(972)
		assert(saved.Settings.PlotColor == "Mint" and saved.RebirthLevel == 1)
		monetization.Owned[joined] = { CustomPlotColor = true }
		e:Fire("PlotColor", joined, "Default")
		assert(saved.Settings.PlotColor == "Default")
	end
)
