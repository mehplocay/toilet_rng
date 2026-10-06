-- Run in both the UI harness and combined security audit, using production cosmetic builders.
do
	local check = test or function(name, callback)
		callback()
		print("PASS " .. name)
	end
	local function fixture()
		H.Reload("src/shared/Visuals/Primitives")
		local player = H.Instance.new("Player")
		player.UserId, player.DisplayName = 780, "Merged Tester"
		local function character()
			local model = H.Instance.new("Model")
			for _, name in ipairs({ "Head", "HumanoidRootPart" }) do
				local part = H.Instance.new("Part")
				part.Name, part.Parent = name, model
			end
			local humanoid = H.Instance.new("Humanoid")
			humanoid.NameDisplayDistance, humanoid.Parent = 100, model
			return model
		end
		player.Character = character()
		local model = H.Instance.new("Model")
		local anchor, sign, toilet = H.Instance.new("Part"), H.Instance.new("TextLabel"), H.Instance.new("Model")
		anchor.Parent, sign.Parent, toilet.Parent = model, model, model
		local plot =
			{ Owner = player, Model = model, PromptAnchor = anchor, IncomePoint = anchor, Sign = sign, Toilet = toilet }
		local service = H.Load("src/server/Services/CosmeticService").new({ Assigned = { [player] = plot } })
		return player, plot, service, character
	end
	check(
		"merged cosmetics: all rebirth levels and paid trail combinations use one trail and bounded effects",
		function()
			local player, plot, service = fixture()
			local profile = { Settings = { PlotColor = "Default" }, RebirthLevel = 0 }
			local rebirth = H.Load("src/server/World/RebirthCosmetics")
			for level = 0, 15 do
				profile.RebirthLevel = level
				for mask = 0, 7 do
					local owned = {
						SparkleTrail = mask % 2 == 1,
						VIPPack = math.floor(mask / 2) % 2 == 1,
						UltimateBundle = mask >= 4,
					}
					service:Apply(player, owned, profile)
					rebirth.Plot(plot, level)
					local root = player.Character.HumanoidRootPart
					local trails, emitters, attachments = 0, 0, 0
					for _, child in ipairs(root:GetChildren()) do
						trails += if child:IsA("Trail") then 1 else 0
						emitters += if child:IsA("ParticleEmitter") then 1 else 0
						attachments += if child:IsA("Attachment") then 1 else 0
					end
					assert(trails == (if level >= 4 or mask > 0 then 1 else 0))
					assert(attachments == 2 * trails and emitters == (if level < 4 and mask > 0 then 1 else 0))
					assert((root:FindFirstChild("RebirthTrail") ~= nil) == (level >= 4))
					if level < 4 and mask > 0 then
						local config = H.Load("src/shared/Config/Monetization")
						local rgb = if owned.VIPPack or owned.UltimateBundle
							then config.VIPTrailRGB
							else config.SparkleRGB
						assert(root.PassSparkleTrail.Color[1].R == rgb[1] / 255)
					end
					if level >= 6 and (owned.VIPPack or owned.UltimateBundle) then
						assert(plot.Sign.RebirthTrim.BorderStrokePosition == "BorderStrokePosition.Inner")
						assert(plot.Sign.VIPTrim.BorderStrokePosition == "BorderStrokePosition.Outer")
						assert(
							plot.Sign.VIPTrim.BorderOffset.Offset == 2
								and plot.Sign.RebirthTrim.ZIndex > plot.Sign.VIPTrim.ZIndex
						)
					end
					local count = #player.Character:GetDescendants() + #plot.Model:GetDescendants()
					service:Apply(player, owned, profile)
					rebirth.Plot(plot, level)
					assert(#player.Character:GetDescendants() + #plot.Model:GetDescendants() == count)
				end
			end
			assert(player.Character.RebirthAura and plot.Toilet.LegendSkin)
			-- Revoke both sources and verify fallback, name restoration, trim and aura removal.
			profile.RebirthLevel = 0
			service:Apply(player, { SparkleTrail = true }, profile)
			rebirth.Plot(plot, 0)
			assert(
				player.Character.HumanoidRootPart.PassSparkleTrail
					and not player.Character:FindFirstChild("RebirthAura")
			)
			service:Apply(player, {}, profile)
			assert(#player.Character.HumanoidRootPart:GetChildren() == 0 and #player.Character.Head:GetChildren() == 0)
			assert(player.Character.Humanoid.NameDisplayDistance == 100 and #plot.Sign:GetChildren() == 0)
			assert(
				not plot.Model:FindFirstChild("VIPPlotSign") and not plot.PromptAnchor:FindFirstChild("PassToiletGlow")
			)
			service:Remove(player)
			player.Character:Destroy()
			plot.Model:Destroy()
			player:Destroy()
		end
	)

	check(
		"merged cosmetics: respawn, leave, repeated cleanup and plot reassignment release effects and connections",
		function()
			local player, plot, service, character = fixture()
			local profile = { RebirthLevel = 15, Settings = { PlotColor = "Default" } }
			local previous = H.PlayerList
			H.PlayerList = { player }
			player._props.Parent = H.Services.Players
			service:Start({ [player] = { UltimateBundle = true } }, function()
				return profile
			end)
			H.Load("src/server/World/RebirthCosmetics").Plot(plot, 15)
			local old = player.Character
			player.CharacterRemoving:Fire(old)
			assert(
				#old.Head:GetChildren() == 0
					and #old.HumanoidRootPart:GetChildren() == 0
					and not old:FindFirstChild("RebirthAura")
			)
			assert(old.Humanoid.NameDisplayDistance == 100)
			player.Character = character()
			player.CharacterAdded:Fire(player.Character)
			table.remove(H.Spawned)()
			assert(player.Character.HumanoidRootPart.RebirthTrail and player.Character.Head.RebirthTitle)
			local connections = service.Connections[player]
			service:Remove(player)
			service:Remove(player)
			for _, connection in ipairs(connections) do
				assert(not connection.Connected)
			end
			assert(not next(service.Connections) and not next(service.PlayerPlots))
			assert(#player.Character.Head:GetChildren() == 0 and #player.Character.HumanoidRootPart:GetChildren() == 0)
			assert(#plot.Sign:GetChildren() == 0 and not plot.Toilet:FindFirstChild("LegendSkin"))
			assert(
				not player:GetAttribute("VIPStar")
					and not player:GetAttribute("Companion")
					and player:GetAttribute("RebirthChatLevel") == 0
			)
			service:Apply(player, { VIPPack = true }, profile)
			plot.Owner = H.Instance.new("Player")
			service:Remove(player)
			assert(plot.Sign.VIPTrim, "Departed player erased the reassigned plot")
			plot.Owner:Destroy()
			H.PlayerList = previous
			player._props.Parent = nil
			old:Destroy()
			player.Character:Destroy()
			plot.Model:Destroy()
			player:Destroy()
		end
	)

	check(
		"merged chat: rebirth tag, exactly one VIP/Star tag and rainbow/gold precedence preserve filtered content",
		function()
			local chat, players = H.Services.TextChatService, H.Services.Players
			local oldLookup, oldCallback = players.GetPlayerByUserId, chat.OnChatWindowAdded
			local window, sender = H.Instance.new("ChatWindowConfiguration"), H.Instance.new("Player")
			window.Parent = chat
			window.DeriveNewMessageProperties = function()
				return {}
			end
			players.GetPlayerByUserId = function()
				return sender
			end
			H.Reload("src/client/VIPChat").Start()
			local message =
				{ TextSource = { UserId = 780 }, PrefixText = '<font color="#FFFFFF"><b>FilteredName:</b></font>' }
			for _, level in ipairs({ 0, 8, 14 }) do
				for mask = 0, 15 do
					sender:SetAttribute("RebirthChatLevel", level)
					sender:SetAttribute("VIPStar", mask % 2 == 1 or mask >= 8)
					sender:SetAttribute("GoldenName", math.floor(mask / 2) % 2 == 1)
					sender:SetAttribute("RainbowName", math.floor(mask / 4) % 2 == 1)
					sender:SetAttribute("VIPPack", mask >= 8)
					local properties = chat.OnChatWindowAdded(message)
					if level == 0 and mask == 0 then
						assert(properties == nil)
						continue
					end
					assert(not properties.Text and properties.PrefixText:find("<b>FilteredName:</b>", 1, true))
					local _, stars = properties.PrefixText:gsub("\u{2605}", "")
					assert(stars == (if sender:GetAttribute("VIPStar") then 1 else 0))
					if level > 0 then
						local title = H.Load("src/shared/Config/Rebirth").Levels[level].Title
						assert(properties.PrefixText:find("[" .. title .. "]", 1, true))
						assert(properties.PrefixText:sub(1, 6) == "<font ")
					end
					if sender:GetAttribute("RainbowName") or sender:GetAttribute("GoldenName") then
						local expected = if sender:GetAttribute("RainbowName")
							then Color3.fromHSV((H.Now / 6) % 1, 0.75, 1)
							else Color3.fromRGB(255, 210, 65)
						assert(
							properties.PrefixTextProperties.TextColor3.R == expected.R
								and properties.PrefixTextProperties.TextColor3.G == expected.G
						)
					end
					assert(
						chat.OnChatWindowAdded(message).PrefixText == properties.PrefixText,
						"Repeated callback duplicated tags"
					)
				end
			end
			assert(message.PrefixText == '<font color="#FFFFFF"><b>FilteredName:</b></font>')
			assert(chat.OnChatWindowAdded({ PrefixText = "System" }) == nil)
			players.GetPlayerByUserId, chat.OnChatWindowAdded = oldLookup, oldCallback
			window:Destroy()
			sender:Destroy()
		end
	)
end
