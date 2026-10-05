local Layout = require("../src/client/UI/Layout")
local function overlap(a, b)
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end
local cases = {
	{ 1920, 1080, false, 0, 36, 0, 0 },
	{ 1280, 720, false, 0, 36, 0, 0 },
	{ 375, 812, true, 0, 88, 0, 34 },
	{ 812, 375, true, 44, 36, 44, 21 },
	{ 1024, 768, true, 0, 36, 0, 20 },
	{ 768, 1024, true, 0, 36, 0, 20 },
	{ 1170, 540, true, 54, 36, 0, 21 },
}
for _, case in ipairs(cases) do
	local width, height, touch, left, top, right, bottom = table.unpack(case)
	local w, h = width - left - right, height - top - bottom
	local layout = Layout.Compute(w, h, touch)
	local elements = {
		Travel = layout.Travel,
		Settings = layout.Settings,
		Coins = layout.Coins,
		Boosts = layout.Boosts,
		Hint = layout.Hint,
		Action = layout.Action,
	}
	if not layout.Short then
		elements.Board = layout.Board
	end
	if layout.OffersVisible then
		elements.Offers = layout.Offers
	end
	for i, bounds in ipairs(layout.Nav) do
		elements["Nav" .. i] = bounds
	end
	for name, r in pairs(elements) do
		assert(r.W > 0 and r.H > 0, name .. " has no area")
		assert(
			r.X >= 0 and r.Y >= 0 and r.X + r.W <= w and r.Y + r.H <= h,
			string.format("%dx%d %s outside safe area", width, height, name)
		)
		for other, b in pairs(elements) do
			if name < other then
				assert(not overlap(r, b), string.format("%dx%d overlap: %s / %s", width, height, name, other))
			end
		end
	end
	-- Reveals replace the center hint/board; event banners replace travel/board.
	for name, r in pairs(elements) do
		if name ~= "Hint" and name ~= "Board" then
			assert(not overlap(r, layout.Reveal), string.format("%dx%d reveal overlaps %s", width, height, name))
			local coin = layout.CoinPopup
			local flight = { X = coin.X, Y = coin.Y - layout.CoinRise, W = coin.W, H = coin.H + layout.CoinRise }
			assert(not overlap(r, flight), string.format("%dx%d coin animation overlaps %s", width, height, name))
			assert(not overlap(layout.Reveal, flight), "Coin animation crosses reveal")
		end
		if name ~= "Action" then
			local p = layout.Pointer
			assert(
				not overlap(r, { X = p.X, Y = p.Y - 5, W = p.W, H = p.H + 10 }),
				string.format("%dx%d idle pointer overlaps %s", width, height, name)
			)
		end
		if name ~= "Travel" and name ~= "Board" then
			assert(not overlap(r, layout.Event), string.format("%dx%d event overlaps %s", width, height, name))
		end
	end
	assert(layout.Action.H >= 44 and layout.Settings.H >= 44)
	for _, nav in ipairs(layout.Nav) do
		assert(nav.W >= 44 and nav.H >= 44)
	end
	if touch then
		local controls = { { X = 0, Y = h - 120, W = 130, H = 120 }, { X = w - 110, Y = h - 120, W = 110, H = 120 } }
		for name, r in pairs(elements) do
			for _, reserved in ipairs(controls) do
				assert(
					not overlap(r, reserved),
					string.format("%dx%d %s overlaps mobile controls", width, height, name)
				)
			end
		end
	end
	local modal = Layout.Modal(w, h)
	assert(modal.X >= 0 and modal.Y >= 0 and modal.X + modal.W <= w and modal.Y + modal.H <= h)
	local bodyH = math.max(540, modal.H - 88)
	assert(bodyH - 196 >= 300, "Collection viewport collapses")
	local columns, cellW = Layout.Grid(modal.W - 60, 132, 14, 5)
	assert(cellW >= 132 and columns * cellW + (columns - 1) * 14 <= modal.W - 60)
	print(
		string.format(
			"PASS UI %dx%d -> safe %dx%d; %s; %d collection columns",
			width,
			height,
			w,
			h,
			if layout.Short then "short landscape" elseif layout.Portrait then "portrait" else "wide",
			columns
		)
	)
end
print("UI layout checks passed: safe areas, pairwise overlap, touch corners, modal scroll space, grid widths")
