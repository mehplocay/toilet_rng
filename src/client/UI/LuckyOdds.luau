local TextService = game:GetService("TextService")
local C = require(script.Parent.Components)
local Rarities = require(game.ReplicatedStorage.Shared.Config.Rarities)
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
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
function Odds.Create(gui, remotes, onPurchase)
	local panel = C.Panel(gui, "Lucky Flush odds", C.Gold, 120)
	panel.ZIndex = 80
	for _, child in ipairs(panel:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.ZIndex += 40
		end
	end
	-- One scroll viewport; measure wrapped text at its actual width, without text scaling.
	local scroll, content = panel.ContentScroll, panel.ContentScroll.Body
	scroll.Size = UDim2.new(1, -28, 1, -148)
	content.AutomaticSize = Enum.AutomaticSize.Y
	C.New("UIListLayout", content, { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
	local function fit(label)
		local width = math.max(8, scroll.AbsoluteSize.X - 20)
		local bounds = TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(width - 4, 100000))
		label.Size = UDim2.fromOffset(width, math.ceil(bounds.Y) + 6)
	end
	local function text(name, value, order)
		local label = C.BodyText(content, value, UDim2.new(1, -12, 0, 0))
		label.Name, label.LayoutOrder = name, order
		label.TextScaled, label.TextWrapped, label.TextSize = false, true, 17
		label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
		label.TextTruncate = Enum.TextTruncate.None
		label:GetPropertyChangedSignal("Text"):Connect(function()
			fit(label)
		end)
		fit(label)
		return label
	end
	local function resize()
		content.Size = UDim2.new(1, -8, 0, 0)
		for _, label in ipairs(content:GetChildren()) do
			if label:IsA("TextLabel") then
				fit(label)
			end
		end
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	text(
		"Explanation",
		"Every toilet can drop all 47 items. Better toilets increase luck.\n10x luck for one flush, capped at 10x total. Full luck applies to every item check. Every flush awards one item. At 10x free luck, a charge cannot improve odds.\nThese are actual outcomes after earlier rare checks. Odds change with your toilet and free boosts; review again if they change.",
		1
	)
	local rarityText = text("RarityOdds", "", 2)
	local rows = {}
	local current, key, quote
	local commerce = {}
	local button = C.Button(panel, "Use on next flush", UDim2.new(1, -28, 0, 50), UDim2.new(0, 14, 1, -64), function()
		if not current then
			return
		end
		if key then
			if onPurchase then
				onPurchase()
			end
			remotes.BuyProduct:FireServer(key, quote or 0, current.Token)
		else
			remotes.LuckyFlush:FireServer(current.Token)
		end
		panel.Visible = false
	end, C.Green, { Name = "ConfirmLucky" })
	local function updateButton(lucky)
		local product = key and Config.DeveloperProducts[key]
		button.Text = if key
			then "Continue to Roblox purchase"
			elseif lucky.Armed then "Ready for next flush"
			else "Use on next flush"
		button.Interactable = if key
			then product ~= nil
				and commerce.CanResume ~= false
				and lucky.Count <= Config.LuckyFlushCap - product.LuckyCharges
				and (not commerce.PendingProduct or (commerce.PendingProduct == key and commerce.CanResume == true))
			else lucky.Count > 0 and not lucky.Armed
	end
	return {
		Panel = panel,
		Invalidate = function(lucky, state)
			commerce = state or {}
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
			elseif panel.Visible then
				updateButton(lucky)
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
				local row = text(
					item.Id,
					item.Name
						.. " ("
						.. item.Rarity
						.. ")\n"
						.. (if item.Fallback then "Fallback" else "Base check 1 in " .. C.Commas(item.BaseChance or 0))
						.. "\nCurrent outcome: Normal "
						.. Odds.Percent(item.Normal)
						.. " / Lucky "
						.. Odds.Percent(item.Boosted),
					i + 2
				)
				row.LayoutOrder, row.TextXAlignment = i + 2, Enum.TextXAlignment.Left
				table.insert(rows, row)
			end
			updateButton(lucky)
			scroll.CanvasPosition = Vector2.new()
			panel.Visible = true
			resize()
		end,
	}
end
return Odds
