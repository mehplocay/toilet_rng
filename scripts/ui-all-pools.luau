do
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local items, toilets = H.Load("src/shared/Config/Items"), H.Load("src/shared/Config/Toilets")
	local roll = H.Load("src/server/Services/RollService")
	local ui = H.Load("src/client/UI/LuckyOdds").Create(root, remotes)
	local odds = { Token = "1:1:10", Items = {}, Rarities = {} }
	local normal, boosted = roll.Distribution(items, toilets, 1, 1), roll.Distribution(items, toilets, 1, 10)
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
	end
	for _, size in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		ui.Show({ Allowed = true, Count = 1, Odds = odds })
		H.Layout(root)
		local scroll, body = ui.Panel.ContentScroll, ui.Panel.ContentScroll.Body
		assert(body.Explanation.AbsolutePosition.Y - scroll.AbsolutePosition.Y <= 2, "Top gap returned")
		local previousBottom = scroll.AbsolutePosition.Y
		local labels = {}
		for _, label in ipairs(body:GetChildren()) do
			if label:IsA("TextLabel") then
				table.insert(labels, label)
			end
		end
		table.sort(labels, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		assert(#labels == #items + 3, "Odds list includes explanation, luck breakdown and rarity summary")
		for _, label in ipairs(labels) do
			assert(label.TextWrapped and not label.TextScaled and label.TextSize == 17)
			assert(label.TextTruncate == Enum.TextTruncate.None and label.TextYAlignment == Enum.TextYAlignment.Top)
			local right = label.AbsolutePosition.X + label.AbsoluteSize.X
			assert(right <= scroll.AbsolutePosition.X + scroll.AbsoluteSize.X - 8, "Right clipping")
			local bounds = H.Services.TextService:GetTextSize(
				label.Text,
				label.TextSize,
				label.Font,
				Vector2.new(label.AbsoluteSize.X - 4, 100000)
			)
			assert(label.AbsoluteSize.Y >= bounds.Y and label.AbsolutePosition.Y >= previousBottom)
			previousBottom = label.AbsolutePosition.Y + label.AbsoluteSize.Y
		end
		local confirm = ui.Panel.ConfirmLucky
		assert(scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y <= confirm.AbsolutePosition.Y)
		assert(confirm.AbsoluteSize.Y >= 44 and confirm.AbsoluteSize.X >= 44)
		local last = labels[#labels]
		scroll.CanvasPosition = Vector2.new(0, last.AbsolutePosition.Y - scroll.AbsolutePosition.Y)
		H.Layout(root)
		assert(math.abs(last.AbsolutePosition.Y - scroll.AbsolutePosition.Y) < 1)
		ui.Show({ Allowed = true, Count = 1, Odds = odds })
		assert(scroll.CanvasPosition.Y == 0, "Reopening must start at the disclosure")
	end
	ui.Invalidate({ Allowed = true, Count = 1, Odds = { Token = "2:1.12:10" } })
	assert(not ui.Panel.Visible, "Tier changes must invalidate the review")
	root:Destroy()
	print(
		"All-pools odds UI: 12 viewports, 47 wrapped rows, top alignment, scrolling and stale-tier review passed (mock font metrics)"
	)
end
