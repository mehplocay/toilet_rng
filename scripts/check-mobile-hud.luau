local Layout = require("../src/client/UI/Layout")
local Presentation = require("../src/client/Presentation/Layout")
local cases = {
	{ 375, 812, 0, 88, 0, 34 },
	{ 390, 844, 0, 88, 0, 34 },
	{ 360, 740, 0, 88, 0, 34 },
	{ 430, 932, 0, 88, 0, 34 },
	{ 812, 375, 44, 36, 44, 21 },
	{ 844, 390, 44, 36, 44, 21 },
	{ 740, 360, 44, 36, 44, 21 },
	{ 768, 1024, 0, 36, 0, 20 },
}
local function overlaps(a, b)
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end
for _, case in ipairs(cases) do
	local width, height, left, top, right, bottom = table.unpack(case)
	local w, h = width - left - right, height - top - bottom
	local l = Layout.Compute(w, h, true)
	if width == 768 then
		assert(not l.Phone, "Tablet must retain its existing layout")
		continue
	end
	assert(l.Phone and not l.OffersVisible)
	local elements = {
		Travel = l.Travel,
		Settings = l.Settings,
		Coins = l.Coins,
		Pending = l.PendingIncome,
		Status = l.Status,
		Action = l.Action,
		Hint = l.Hint,
		Celebrate = l.Celebrate,
		Admin = l.Admin,
	}
	for i, r in ipairs(l.Nav) do
		elements["Nav" .. i] = r
	end
	local zones = {
		{ X = 0, Y = h * 0.6, W = w * 0.28, H = h * 0.4 },
		{ X = w * 0.78, Y = h * 0.65, W = w * 0.22, H = h * 0.35 },
	}
	for name, r in pairs(elements) do
		assert(r.X >= 0 and r.Y >= 0 and r.X + r.W <= w and r.Y + r.H <= h, name .. " outside safe area")
		for _, zone in ipairs(zones) do
			assert(not overlaps(r, zone), name .. " in thumb zone")
		end
		local physical = { X = r.X + left - 2, Y = r.Y + top - 2, W = r.W + 4, H = r.H + 9 }
		for _, zone in ipairs({
			{ X = 0, Y = height * 0.6, W = width * 0.28, H = height * 0.4 },
			{ X = width * 0.78, Y = height * 0.65, W = width * 0.22, H = height * 0.35 },
		}) do
			assert(not overlaps(physical, zone), name .. " chrome in physical thumb zone")
		end
		for other, b in pairs(elements) do
			if name < other then
				assert(not overlaps(r, b), name .. " overlaps " .. other)
			end
		end
	end
	for _, r in ipairs(l.Nav) do
		assert(r.W >= 44 and r.H >= 44)
	end
	assert(l.Travel.W / 3 - 10 >= 44 and l.Travel.H >= 44)
	assert(l.Action.W - 80 >= 44 and l.Action.H >= 44 and l.AutoWidth >= 44)
	for _, r in ipairs({ l.Reveal, Presentation.Compute(w, h, true).Toast, Layout.Toast(w, h, true), l.CoinPopup }) do
		assert(not overlaps(r, l.Action))
		for _, nav in ipairs(l.Nav) do
			assert(not overlaps(r, nav))
		end
		for _, zone in ipairs(zones) do
			assert(not overlaps(r, zone))
		end
	end
	assert(not overlaps(l.Reveal, l.CoinPopup))
	print(string.format("PASS phone %dx%d safe %dx%d", width, height, w, h))
end
print("Dedicated phone geometry and unchanged small-tablet regression passed")
