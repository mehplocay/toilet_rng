local TextService = game:GetService("TextService")
local C = require(script.Parent.Components)
local Rarities = require(game.ReplicatedStorage.Shared.Config.Rarities)
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Format = require(game.ReplicatedStorage.Shared.NumberFormat)
local SocialUI = require(script.Parent.SocialBoosts)
local Odds = {}
function Odds.Percent(value)
	assert(type(value) == "number" and value >= 0 and value <= 1, "Invalid probability")
	if value == 0 then
		return "0%"
	end
	if value == 1 then
		return "100% (certain)"
	end
	local percent = value * 100
	if percent < 1e-10 then
		return string.format("%.6g%%", percent)
	end
	local places = math.max(4, 4 - math.floor(math.log10(percent)))
	return string.format("%." .. math.min(14, places) .. "f%%", percent)
end
-- Largest-remainder rounding in exact integer units of 1e-12 percentage points.
-- Each complete displayed column sums to 100%; RNG always uses the raw probabilities.
function Odds.Column(rows, key)
	local scale, total, mass, units, order = 1e14, 0, 0, {}, {}
	for i, row in ipairs(rows) do
		local value = row[key]
		assert(type(value) == "number" and value >= 0 and value <= 1, "Invalid probability")
		local scaled = value * scale
		units[i] = math.floor(scaled)
		total += units[i]
		mass += value
		table.insert(order, { Index = i, Remainder = scaled - units[i] })
	end
	table.sort(order, function(a, b)
		return if a.Remainder == b.Remainder then a.Index < b.Index else a.Remainder > b.Remainder
	end)
	if math.abs(mass - 1) < 1e-12 then
		local remainder = scale - total
		assert(math.abs(remainder) <= #rows, "Invalid odds rounding remainder")
		for i = 1, math.abs(remainder) do
			local index = order[i].Index
			if remainder < 0 then
				-- Remove floating-point excess only from positive buckets, never a zero outcome.
				for _, candidate in ipairs(order) do
					if units[candidate.Index] > units[index] then
						index = candidate.Index
					end
				end
			end
			units[index] += if remainder >= 0 then 1 else -1
		end
	end
	local labels = {}
	for i, row in ipairs(rows) do
		local whole = math.floor(units[i] / 1e12)
		local fraction = string.format("%012.0f", units[i] % 1e12):gsub("0+$", "")
		local text = tostring(whole) .. (if #fraction > 0 then "." .. fraction else "") .. "%"
		if row[key] == 1 then
			text ..= " (certain)"
		elseif units[i] == scale then
			text ..= " (rounded; not certain)"
		elseif units[i] == 0 and row[key] > 0 then
			text ..= " (raw " .. Odds.Percent(row[key]) .. ")"
		end
		labels[i] = text
	end
	return labels, units
end
function Odds.RarityText(odds)
	local lines = { if odds and odds.Offer then "Rarity: current / with pass" else "Rarity: normal / Lucky" }
	local names, rows = {}, {}
	for name in pairs(Rarities) do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		return Rarities[a].Order < Rarities[b].Order
	end)
	for i, name in ipairs(names) do
		local entry = (odds and odds.Rarities[name]) or { Normal = 0, Boosted = 0 }
		rows[i] = {}
		for _, key in ipairs({ "Normal", "Boosted" }) do
			-- Summing item probabilities can exceed 1 by a floating-point rounding unit.
			assert(
				type(entry[key]) == "number" and entry[key] >= 0 and entry[key] <= 1 + 1e-12,
				"Invalid rarity probability"
			)
			rows[i][key] = math.min(1, entry[key])
		end
	end
	local normal, boosted = Odds.Column(rows, "Normal"), Odds.Column(rows, "Boosted")
	for i, name in ipairs(names) do
		table.insert(lines, name .. ": " .. normal[i] .. " / " .. boosted[i])
	end
	return table.concat(lines, "\n") .. "\nRounded to 12 decimal places; complete columns total 100%."
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
		"Every toilet can drop all 47 items. Better toilets increase luck.\nMultiplies your current luck by 10 for one flush, without a total cap. Each item check is base chance times luck, up to 100%. Every flush awards one item.\nThese are actual outcomes after earlier rare checks. Odds change with your toilet, passes and free boosts; review again if they change.",
		1
	)
	local breakdown = text("LuckBreakdown", "", 2)
	breakdown.Name, breakdown.LayoutOrder = "LuckBreakdown", 2
	breakdown.TextScaled, breakdown.TextWrapped, breakdown.TextYAlignment, breakdown.TextSize, breakdown.TextTruncate =
		false, true, Enum.TextYAlignment.Top, 17, Enum.TextTruncate.None
	local rarityText = text("RarityOdds", "", 3)
	local rows = {}
	local current, key, quote, readOnly
	local commerce = {}
	local breakdownBase = ""
	local inviteDeadlines = setmetatable({}, { __mode = "k" })
	local function inviteLeft(odds)
		if not inviteDeadlines[odds] then
			inviteDeadlines[odds] = os.clock() + (odds.InviteRemaining or 0)
		end
		return math.max(0, inviteDeadlines[odds] - os.clock())
	end
	local counting = false
	local function startInviteTimer()
		if counting or not current or (current.InviteLuck or 1) == 1 then
			return
		end
		counting = true
		task.spawn(function()
			while panel.Parent and panel.Visible and current do
				local left = inviteLeft(current)
				breakdown.Text = breakdownBase .. "\n" .. SocialUI.InviteText(left)
				if (current.InviteLuck or 1) > 1 and left == 0 then
					panel.Visible, current = false, nil
					break
				end
				task.wait(1)
			end
			counting = false
		end)
	end
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
			if lucky then
				if lucky.Odds then
					inviteLeft(lucky.Odds)
				end
				for _, odds in pairs(lucky.PassOdds or {}) do
					inviteLeft(odds)
				end
			end
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
			local remaining = inviteLeft(current)
			if (current.InviteLuck or 1) > 1 and remaining == 0 then
				panel.Visible, current = false, nil
				return
			end
			breakdown.Text = string.format(
				"Current luck x%s / %s x%s\n%s\n%s",
				Format.Luck(current.BaseLuck or 1, true),
				if current.Offer then "With pass" else "Lucky Flush",
				Format.Luck(current.Luck or 10, true),
				if current.VIPLuck then "VIP +25% luck" else "VIP luck: inactive",
				if current.DoubleLuck then "2x Luck pass" else "2x Luck pass: inactive"
			)
			breakdownBase = breakdown.Text
			breakdown.Text ..= "\n" .. SocialUI.InviteText(remaining)
			explanation.Text = (
				if current.Offer
					then Config.Gamepasses[current.Offer].Description
						.. " Every toilet can drop all 47 items. Current / with-pass odds below reflect your active boosts and full item pool. Luck stacks without a cap; each item check is at most 100%."
					else "Every toilet can drop all 47 items. Better toilets increase luck. Multiplies your current luck by 10 for one flush, without a total cap. Each item check is base chance times luck, up to 100%. Every flush awards one item. Earlier certain checks can leave later outcomes at 0%. These are actual outcomes after earlier rare checks."
			)
				.. "\nVIP +25% luck and 2x Luck pass effects are listed separately below. Percentages are rounded to 12 decimal places with totals preserved at 100%. Tiny nonzero outcomes also show their raw percentage. Review again when your tier or boosts change."
			panel.TitleBar:FindFirstChildWhichIsA("TextLabel").Text = if current.Offer
				then Config.Gamepasses[current.Offer].Name .. " item odds"
				else "Lucky Flush odds"
			rarityText.Text = Odds.RarityText(current)
			for _, row in ipairs(rows) do
				row:Destroy()
			end
			table.clear(rows)
			local normal, boosted = Odds.Column(current.Items, "Normal"), Odds.Column(current.Items, "Boosted")
			for i, item in ipairs(current.Items) do
				local row = text(
					item.Id,
					item.Name
						.. " ("
						.. item.Rarity
						.. ")\n"
						.. (if item.Fallback then "Fallback" else "Base check 1 in " .. C.Commas(item.BaseChance or 0))
						.. "\nCurrent outcome: Normal "
						.. normal[i]
						.. (if current.Offer then " / With pass " else " / Lucky ")
						.. boosted[i],
					i + 3
				)
				row.LayoutOrder, row.TextXAlignment = i + 3, Enum.TextXAlignment.Left
				table.insert(rows, row)
			end
			updateButton(lucky)
			scroll.CanvasPosition = Vector2.new()
			panel.Visible = true
			startInviteTimer()
			resize()
		end,
	}
end
return Odds
