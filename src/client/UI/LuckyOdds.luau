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
	local lines = { if odds and odds.Offer then "Rarity: current / with pass" else "Rarity: normal / Lucky" }
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
		local size = label.TextSize or 17
		label.TextSize = size
		local bounds = TextService:GetTextSize(label.Text, size, label.Font, Vector2.new(width - 4, 100000))
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
	local explanation = text(
		"Explanation",
		"Every toilet can drop all 47 items. Better toilets increase luck.\n10x luck for one flush, capped at 10x total. Full luck applies to every item check. Every flush awards one item.\nThese are actual outcomes after earlier rare checks. Odds change with your toilet, passes and free boosts; review again if they change.",
		1
	)
	local breakdown = C.BodyText(content, "", UDim2.new(1, 0, 0, 90))
	breakdown.Name, breakdown.LayoutOrder = "LuckBreakdown", 2
	breakdown.TextScaled, breakdown.TextWrapped, breakdown.TextYAlignment, breakdown.TextSize, breakdown.TextTruncate =
		false, true, Enum.TextYAlignment.Top, 17, Enum.TextTruncate.None
	local rarityText = text("RarityOdds", "", 3)
	local rows = {}
	local current, key, quote, readOnly
	local commerce = {}
	local button = C.Button(panel, "Use on next flush", UDim2.new(1, -28, 0, 50), UDim2.new(0, 14, 1, -64), function()
		if not current then
			return
		end
		if key then
			if onPurchase then
				onPurchase(if Config.Gamepasses[key] then "BuyPass" else "BuyProduct")
			end
			if Config.Gamepasses[key] then
				remotes.BuyPass:FireServer(key, current.Token)
			else
				remotes.BuyProduct:FireServer(key, quote or 0, current.Token)
			end
		else
			remotes.LuckyFlush:FireServer(current.Token)
		end
		panel.Visible = false
	end, C.Green, { Name = "ConfirmLucky" })
	local function updateButton(lucky)
		if readOnly then
			button.Text, button.Interactable = "Current item odds", false
			return
		end
		local product = key and Config.DeveloperProducts[key]
		button.Text = if key
			then "Continue to Roblox purchase"
			elseif lucky.Armed then "Ready for next flush"
			else "Use on next flush"
		button.Interactable = if key
			then (if Config.Gamepasses[key]
				then Config.Gamepasses[key].Id > 0
				else product ~= nil
					and commerce.CanResume ~= false
					and lucky.Count <= Config.LuckyFlushCap - product.LuckyCharges
					and (not commerce.PendingProduct or (commerce.PendingProduct == key and commerce.CanResume == true)))
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
					or (
						current
						and current.Token
							~= (
								(if key and Config.Gamepasses[key] then (lucky.PassOdds or {})[key] else lucky.Odds)
								or {}
							).Token
					)
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
		Show = function(lucky, productKey, amount, infoOnly)
			readOnly = infoOnly == true
			if not lucky or not lucky.Allowed or not lucky.Odds then
				return
			end
			current, key, quote =
				if productKey and Config.Gamepasses[productKey] then (lucky.PassOdds or {})[productKey] else lucky.Odds,
				productKey,
				amount
			if not current then
				return
			end
			breakdown.Text = string.format(
				"Current luck x%.4g / %s x%.4g\n%s\n%s",
				current.BaseLuck or 1,
				if current.Offer then "With pass" else "Lucky Flush",
				current.Luck or 10,
				if current.VIPLuck then "VIP +25% luck" else "VIP luck: inactive",
				if current.DoubleLuck then "2x Luck pass" else "2x Luck pass: inactive"
			)
			explanation.Text = (
				if current.Offer
					then Config.Gamepasses[current.Offer].Description
						.. " Every toilet can drop all 47 items. Current / with-pass odds below reflect your active boosts and full item pool. At the 10x cap, further boosts add no odds."
					else "Every toilet can drop all 47 items. Better toilets increase luck. 10x luck for one flush, capped at 10x total. Full luck applies to every item check. Every flush awards one item. At 10x total luck, a charge cannot improve odds. These are actual outcomes after earlier rare checks."
			)
				.. "\nVIP +25% luck and 2x Luck pass effects are listed separately below. Percentages are rounded; displayed totals may differ from 100%. Review again when your tier or boosts change."
			panel.TitleBar:FindFirstChildWhichIsA("TextLabel").Text = if current.Offer
				then Config.Gamepasses[current.Offer].Name .. " item odds"
				else "Lucky Flush odds"
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
						.. (if current.Offer then " / With pass " else " / Lucky ")
						.. Odds.Percent(item.Boosted),
					i + 3
				)
				row.LayoutOrder, row.TextXAlignment = i + 3, Enum.TextXAlignment.Left
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
