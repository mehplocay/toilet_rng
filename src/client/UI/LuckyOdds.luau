local C = require(script.Parent.Components)
local Rarities = require(game.ReplicatedStorage.Shared.Config.Rarities)
local Odds = {}
function Odds.Percent(value)
	if value == 0 then
		return "0%"
	end
	-- Keep at least four places beyond the first nonzero digit, including tiny Secrets.
	local places = math.max(4, 4 - math.floor(math.log10(value * 100)))
	return string.format("%." .. math.min(14, places) .. "f%%", value * 100)
end
function Odds.RarityText(odds)
	local lines = { "Rarity: normal / Lucky" }
	local names = {}
	for name in pairs(Rarities) do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		return Rarities[a].Order < Rarities[b].Order
	end)
	for _, name in ipairs(names) do
		local entry = odds and odds.Rarities[name]
		table.insert(
			lines,
			name
				.. ": "
				.. (if entry then Odds.Percent(entry.Normal) .. " / " .. Odds.Percent(entry.Boosted) else "0% / 0%")
		)
	end
	return table.concat(lines, "\n") .. "\nRounded; totals may differ from 100%."
end
function Odds.Create(gui, remotes)
	local panel = C.Panel(gui, "Lucky Flush odds", C.Gold, 120)
	panel.ZIndex = 80
	for _, child in ipairs(panel:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.ZIndex += 40
		end
	end
	local body = panel.ContentScroll.Body
	local scroll = C.Scroll(body, UDim2.new(1, 0, 1, -64))
	local content = C.New(
		"Frame",
		scroll,
		{ Size = UDim2.new(1, -14, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }
	)
	C.New("UIListLayout", content, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	local explanation = C.BodyText(
		content,
		"10x luck for one flush, capped at 10x total. Rare diminishing returns still apply. Every flush awards one item. At 10x free luck, a charge cannot improve odds.\nPercentages are rounded; displayed totals may differ from 100%. Odds can change with your tier and free boosts; review again if they change.",
		UDim2.new(1, 0, 0, 134)
	)
	explanation.LayoutOrder = 1
	local rarityText = C.BodyText(content, "", UDim2.new(1, 0, 0, 216))
	rarityText.LayoutOrder, rarityText.TextXAlignment = 2, Enum.TextXAlignment.Left
	local rows = {}
	local current, key, quote
	local button = C.Button(body, "Use on next flush", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 1, -54), function()
		if not current then
			return
		end
		if key then
			remotes.BuyProduct:FireServer(key, quote or 0, current.Token)
		else
			remotes.LuckyFlush:FireServer(current.Token)
		end
		panel.Visible = false
	end, C.Green, { Name = "ConfirmLucky" })
	return {
		Panel = panel,
		Invalidate = function(lucky)
			if
				panel.Visible
				and (
					not lucky
					or not lucky.Allowed
					or not lucky.Odds
					or (current and current.Token ~= lucky.Odds.Token)
				)
			then
				panel.Visible = false
				current = nil
			end
		end,
		Close = function()
			panel.Visible = false
			current = nil
		end,
		Show = function(lucky, productKey, amount)
			if not lucky or not lucky.Allowed or not lucky.Odds then
				return
			end
			current, key, quote = lucky.Odds, productKey, amount
			rarityText.Text = Odds.RarityText(current)
			for _, row in ipairs(rows) do
				row:Destroy()
			end
			table.clear(rows)
			for i, item in ipairs(current.Items) do
				local row = C.BodyText(
					content,
					item.Name
						.. " ("
						.. item.Rarity
						.. ")\nNormal "
						.. Odds.Percent(item.Normal)
						.. " / Lucky "
						.. Odds.Percent(item.Boosted),
					UDim2.new(1, 0, 0, 60)
				)
				row.LayoutOrder, row.TextXAlignment = i + 2, Enum.TextXAlignment.Left
				table.insert(rows, row)
			end
			button.Text = if key then "Continue to Roblox purchase" else "Use on next flush"
			button.Interactable = key ~= nil or lucky.Count > 0
			panel.Visible = true
		end,
	}
end
return Odds
