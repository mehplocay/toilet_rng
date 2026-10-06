do
	local root, remotes = H.Root(390, 722), H.Remotes()
	local config = H.Load("src/shared/Config/Monetization")
	local ui = H.Load("src/client/UI/Passes").Create(root, remotes)
	local body = ui.Panel.ContentScroll.Body
	local vip = ui.Panel:FindFirstChild("OfferGrid", true).VIPPack
	assert(#config.PassOrder == 15 and not ui.Panel:FindFirstChild("ExtraSlots", true))
	local bundleDescription = false
	for _, label in ipairs(ui.Panel:GetDescendants()) do
		if label:IsA("TextLabel") then
			assert(not string.find(label.Text, "Extra Slots", 1, true))
			assert(not string.find(label.Text, "+2 slots", 1, true))
			assert(not string.find(label.Text, "+2 display slots", 1, true))
			if string.find(label.Text, "All 14 other passes", 1, true) then
				bundleDescription = true
			end
		end
	end
	assert(bundleDescription, "Bundle card must promise all 14 other passes")
	local cashExplanation = false
	for _, label in ipairs(vip:GetDescendants()) do
		if label:IsA("TextLabel") and string.find(label.Text, "paid cap 3x on top", 1, true) then
			cashExplanation = string.find(label.Text, "Free cash cap 40x", 1, true) ~= nil
		end
	end
	assert(cashExplanation, "Premium VIP card must explain the separate cash caps")
	local luckyGrid = ui.Panel:FindFirstChild("LuckyGrid", true)
	local state =
		{ Settings = {}, OwnedPasses = {}, Commerce = { Quotes = {}, Lucky = { Allowed = false, Count = 3 } } }
	ui.Update(state)
	assert(not body.LuckyTab.Visible and not luckyGrid.Visible)
	local before = #H.Calls
	body.LuckyTab.Activated:Fire()
	assert(not luckyGrid.Visible and #H.Calls == before)
	local odds = {
		Token = "7:1:10",
		Items = {
			{ Id = "Poop", Name = "Poop", Rarity = "Common", Normal = 0.8, Boosted = 0.5 },
			{ Id = "Mystery", Name = "Mystery", Rarity = "Secret", Normal = 0.2, Boosted = 0.5 },
		},
		Rarities = { Common = { Normal = 0.8, Boosted = 0.5 }, Secret = { Normal = 0.2, Boosted = 0.5 } },
	}
	state.Commerce.Lucky = { Allowed = true, Count = 3, Odds = odds, PolicyRemaining = 120 }
	ui.Update(state)
	ui.Panel.Visible = true
	body.LuckyTab.Activated:Fire()
	assert(luckyGrid.Visible and body.LuckyTab.Visible)
	local format = H.Load("src/client/UI/LuckyOdds")
	assert(format.Percent(0) == "0%" and format.Percent(0.000001) == "0.00010000%")
	assert(string.find(format.RarityText(odds), "Secret: 20.0000% / 50.0000%", 1, true))
	local card = luckyGrid.LuckyFlush1.OfferCard
	assert(card.Buy.Text == "Coming soon" and not card.Buy.Interactable)
	local original = H.Services.MarketplaceService.GetProductInfoAsync
	config.DeveloperProducts.LuckyFlush1.Id = 123456
	H.Services.MarketplaceService.GetProductInfoAsync = function(_, id)
		return { IsForSale = true, PriceInRobux = if id == 123456 then 25 else 59 }
	end
	ui.Panel.Visible = false
	ui.Panel.Visible = true
	H.StartTasks()
	ui.Update(state)
	assert(card.Buy.Interactable)
	before = #H.Calls
	card.Buy.Activated:Fire()
	local dialog = root:FindFirstChild("Lucky Flush odds")
	assert(dialog.Visible and #H.Calls == before, "Purchase bypassed odds review")
	dialog:FindFirstChild("ConfirmLucky", true).Activated:Fire()
	assert(H.Calls[#H.Calls].Name == "BuyProduct" and H.Calls[#H.Calls].Args[3] == odds.Token)
	ui.Panel:FindFirstChild("UseLucky", true).Activated:Fire()
	assert(dialog.Visible)
	dialog:FindFirstChild("ConfirmLucky", true).Activated:Fire()
	assert(H.Calls[#H.Calls].Name == "LuckyFlush" and H.Calls[#H.Calls].Args[1] == odds.Token)
	for _, viewport in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = viewport[1], Y = viewport[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		H.Layout(root)
		body.PassesTab.Activated:Fire()
		H.Layout(root)
		H.Snapshot(root, "catalog2-vip-" .. viewport[1] .. "x" .. viewport[2])
		body.LuckyTab.Activated:Fire()
		H.Layout(root)
		H.Snapshot(root, "catalog2-lucky-" .. viewport[1] .. "x" .. viewport[2])
		ui.Panel:FindFirstChild("UseLucky", true).Activated:Fire()
		H.Layout(root)
		local confirm = dialog:FindFirstChild("ConfirmLucky", true)
		assert(confirm.AbsoluteSize.Y >= 44 and confirm.AbsoluteSize.X >= 100)
		assert(
			confirm.AbsolutePosition.Y >= 0 and confirm.AbsolutePosition.Y + confirm.AbsoluteSize.Y <= viewport[2],
			"Odds action must remain visible without outer scrolling"
		)
		H.Snapshot(root, "catalog2-odds-" .. viewport[1] .. "x" .. viewport[2])
		dialog.Visible = false
	end
	ui.Panel:FindFirstChild("UseLucky", true).Activated:Fire()
	H.Advance(121)
	assert(not body.LuckyTab.Visible and not dialog.Visible, "Expired eligibility remained visible")
	state.Commerce.Lucky.Allowed = false
	ui.Update(state)
	assert(not body.LuckyTab.Visible and not luckyGrid.Visible and not dialog.Visible)
	state.OwnedPasses = { UltimateBundle = true }
	ui.Update(state)
	for _, key in ipairs(config.PassOrder) do
		assert(ui.Panel:FindFirstChild("OfferGrid", true)[key].OfferCard.Buy.Text == "Owned")
	end
	config.DeveloperProducts.LuckyFlush1.Id = 0
	H.Services.MarketplaceService.GetProductInfoAsync = original
	root:Destroy()
end
do
	local root, remotes = H.Root(390, 722), H.Remotes()
	local format = H.Load("src/client/UI/LuckyOdds")
	local roll = H.Load("src/server/Services/RollService")
	local items, toilets = H.Load("src/shared/Config/Items"), H.Load("src/shared/Config/Toilets")
	local odds = { Token = "15:5:10", Items = {}, Rarities = {} }
	local normal, boosted = roll.Distribution(items, toilets, 15, 5), roll.Distribution(items, toilets, 15, 10)
	local expected = {}
	for i, entry in ipairs(normal) do
		local item = entry.Item
		odds.Items[i] = {
			Id = item.Id,
			Name = item.Name,
			Rarity = item.Rarity,
			BaseChance = item.Chance,
			Fallback = item.Id == "Poop",
			Normal = entry.Probability,
			Boosted = boosted[i].Probability,
		}
		local sum = odds.Rarities[item.Rarity] or { Normal = 0, Boosted = 0 }
		sum.Normal += entry.Probability
		sum.Boosted += boosted[i].Probability
		odds.Rarities[item.Rarity] = sum
		expected[item.Name .. " (" .. item.Rarity .. ")"] = "Current outcome: Normal "
			.. format.Percent(entry.Probability)
			.. " / Lucky "
			.. format.Percent(boosted[i].Probability)
	end
	local ui = format.Create(root, remotes)
	ui.Show({ Allowed = true, Count = 1, Odds = odds })
	local count = 0
	for _, label in ipairs(ui.Panel:GetDescendants()) do
		if label:IsA("TextLabel") then
			local firstLine = string.match(label.Text, "^[^\n]+")
			if firstLine and expected[firstLine] then
				assert(string.find(label.Text, expected[firstLine], 1, true), "Wrong displayed outcome: " .. firstLine)
				count += 1
			end
		end
	end
	assert(count == 47, "Lucky review must disclose every unlocked item")
	assert(string.find(format.RarityText(odds), "Celestial:", 1, true))
	root:Destroy()
end
print(
	"Catalog2 UI passed: fail-closed visibility, Coming soon, odds before prompt/use, tiny percentages, bundle ownership and responsive review"
)
do
	local root, remotes = H.Root(390, 722), H.Remotes()
	local player = H.Instance.new("Player")
	player.UserId = 710
	local character = H.Instance.new("Model")
	local hrp = H.Instance.new("Part")
	hrp.Name, hrp.Position, hrp.CFrame, hrp.Parent = "HumanoidRootPart", Vector3.new(), CFrame.new(), character
	local humanoid = H.Instance.new("Humanoid")
	humanoid.Health, humanoid.Parent = 100, character
	player.Character = character
	player:SetAttribute("Companion", true)
	local previous = H.PlayerList
	H.PlayerList = { player }
	local effects = H.Load("src/client/CatalogEffects").Start(root, player, remotes)
	local beat = H.Services.RunService.Heartbeat
	beat:Fire(0.11)
	assert(effects.Pets[player] and #effects.Pets[player]:GetChildren() == 7)
	local pet = effects.Pets[player]
	for _ = 1, 30 do
		beat:Fire(0.11)
	end
	assert(effects.Pets[player] == pet, "Companion rebuilt every tick")
	remotes.State.OnClientEvent:Fire({
		OwnedPasses = { DancePack = true, ConfettiReveal = true },
		Settings = { RevealIntensity = "Reduced" },
	})
	root.CelebrationMenu.Activated:Fire()
	assert(effects.Menu.Visible)
	effects.Menu:FindFirstChild("Celebration1", true).Activated:Fire()
	beat:Fire(2.1)
	local count = 0
	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "RevealConfetti" then
			count += 1
		end
	end
	assert(count <= 24 and count > 0)
	player.CharacterRemoving:Fire(character)
	player.Character = nil
	assert(not effects.Pets[player] and pet._dead and not effects.Menu.Visible)
	for _, child in ipairs(root:GetChildren()) do
		assert(child.Name ~= "RevealConfetti", "Respawn retained celebration particles")
	end
	beat:Fire(0.11)
	player.Character = character
	beat:Fire(0.11)
	pet = effects.Pets[player]
	assert(pet and not pet._dead)
	remotes.Result.OnClientEvent:Fire("Flush", {})
	remotes.State.OnClientEvent:Fire({
		OwnedPasses = { DancePack = true, ConfettiReveal = true },
		Settings = { RevealIntensity = "Off" },
	})
	for _, child in ipairs(root:GetChildren()) do
		assert(child.Name ~= "RevealConfetti")
	end
	humanoid.Health = 0
	beat:Fire(0.11)
	assert(not effects.Pets[player] and pet._dead)
	humanoid.Health = 100
	beat:Fire(0.11)
	pet = effects.Pets[player]
	H.PlayerList = {}
	beat:Fire(0.11)
	assert(not effects.Pets[player] and pet._dead)
	H.PlayerList = { player }
	beat:Fire(0.11)
	pet = effects.Pets[player]
	root:Destroy()
	assert(pet._dead and not next(effects.Pets))
	H.PlayerList = previous
	character:Destroy()
	player:Destroy()
end
print(
	"Catalog2 effects passed: seven-part companion, reuse/death/leave/teardown, menu toggle, bounded confetti and Off"
)

do
	-- Execute the actual cosmetic construction, not the full-client boot's primitive stub.
	H.Reload("src/shared/Visuals/Primitives")
	local player = H.Instance.new("Player")
	player.UserId, player.DisplayName = 720, "Golden Tester"
	local character = H.Instance.new("Model")
	local hrp = H.Instance.new("Part")
	hrp.Name, hrp.Parent = "HumanoidRootPart", character
	local head = H.Instance.new("Part")
	head.Name, head.Parent = "Head", character
	local humanoid = H.Instance.new("Humanoid")
	humanoid.NameDisplayDistance, humanoid.Parent = 100, character
	player.Character = character
	local model = H.Instance.new("Model")
	local anchor = H.Instance.new("Part")
	anchor.Parent = model
	local sign = H.Instance.new("TextLabel")
	sign.Parent = model
	local plot = { Model = model, PromptAnchor = anchor, IncomePoint = anchor, Sign = sign }
	local service = H.Load("src/server/Services/CosmeticService").new({ Assigned = { [player] = plot } })
	local profile = { Settings = { PlotColor = "Default" } }
	service:Apply(player, { VIPStar = true }, profile)
	assert(head.PassVIPStar:FindFirstChildWhichIsA("TextLabel").Text == "\u{2605}")
	service:Apply(player, { UltimateBundle = true }, profile)
	assert(
		player:GetAttribute("RainbowName") and player:GetAttribute("GoldenName") and player:GetAttribute("Companion")
	)
	assert(head.PassName.NameColor.Text == "Golden Tester" and humanoid.NameDisplayDistance == 0)
	assert(
		head.PassVIPStar:FindFirstChildWhichIsA("TextLabel").Text == H.Load("src/shared/Config/Monetization").VIPLabel
	)
	assert(sign.VIPTrim and anchor.PassToiletGlow and hrp.PassSparkleTrail)
	local count = #model:GetDescendants() + #character:GetDescendants()
	for _ = 1, 20 do
		service:Apply(player, { UltimateBundle = true }, profile)
	end
	assert(#model:GetDescendants() + #character:GetDescendants() == count)
	service:Apply(player, {}, profile)
	assert(not head:FindFirstChild("PassName") and humanoid.NameDisplayDistance == 100)
	service:Remove(player)
	assert(
		not sign:FindFirstChild("VIPTrim")
			and not anchor:FindFirstChild("PassToiletGlow")
			and not service.PlayerPlots[player]
	)
	model:Destroy()
	character:Destroy()
	player:Destroy()
end
print(
	"Catalog2 server cosmetics passed: bundle attributes, Star Tag/VIP distinction, name distance restore, gold trim/glow, idempotence and plot cleanup"
)

do
	local chat = H.Services.TextChatService
	local oldLookup = H.Services.Players.GetPlayerByUserId
	local oldCallback = chat.OnChatWindowAdded
	local window = H.Instance.new("ChatWindowConfiguration")
	window.Parent = chat
	window.DeriveNewMessageProperties = function()
		return {}
	end
	local sender = H.Instance.new("Player")
	sender.UserId = 730
	H.Services.Players.GetPlayerByUserId = function(_, id)
		return if id == 730 then sender else nil
	end
	H.Reload("src/client/VIPChat").Start()
	local message = { TextSource = { UserId = 730 }, PrefixText = '<font color="#FFFFFF"><b>FilteredName:</b></font>' }
	sender:SetAttribute("GoldenName", true)
	local properties = chat.OnChatWindowAdded(message)
	assert(
		properties.PrefixText == "<b>FilteredName:</b>" and properties.PrefixTextProperties.TextColor3.G == 210 / 255
	)
	sender:SetAttribute("RainbowName", true)
	properties = chat.OnChatWindowAdded(message)
	local expected = Color3.fromHSV((H.Now / 6) % 1, 0.75, 1)
	assert(
		properties.PrefixTextProperties.TextColor3.R == expected.R
			and properties.PrefixTextProperties.TextColor3.G == expected.G
	)
	sender:SetAttribute("VIPStar", true)
	sender:SetAttribute("VIPPack", true)
	properties = chat.OnChatWindowAdded(message)
	assert(string.find(properties.PrefixText, H.Load("src/shared/Config/Monetization").VIPLabel, 1, true))
	assert(string.find(properties.PrefixText, "FilteredName:", 1, true) and not properties.Text)
	assert(chat.OnChatWindowAdded({ PrefixText = "System" }) == nil)
	chat.OnChatWindowAdded = oldCallback
	H.Services.Players.GetPlayerByUserId = oldLookup
	window:Destroy()
	sender:Destroy()
end
print(
	"Catalog2 chat passed: native prefix markup, golden/rainbow precedence, VIP star and filtered content preservation"
)
