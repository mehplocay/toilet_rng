-- Pure safe-area geometry, also executed by scripts/check-ui-layout.luau.
local Layout = {}
local function rect(x, y, w, h)
	return { X = math.floor(x), Y = math.floor(y), W = math.floor(w), H = math.floor(h) }
end
function Layout.Compute(w, h, touch)
	local portrait = w < 760 and h > w
	local short = h < 500 or (w >= 600 and h < 600)
	local compact = portrait or short or w < 1000
	local margin = if compact then 10 else 20
	local travelW = math.min(if compact then 330 else 580, w - 80)
	local travelH = if compact then 44 else 58
	local result = {
		Compact = compact,
		Portrait = portrait,
		Short = short,
		Travel = rect((w - travelW) / 2 - (if portrait then 24 else 0), 10, travelW, travelH),
		Settings = rect(w - margin - 44, 10, 44, 44),
		OffersVisible = not compact and h >= (if touch then 760 else 660),
		Nav = {},
	}
	if short then
		local side = 44
		local start = (w - (side * 6 + 8 * 5)) / 2
		for i = 1, 6 do
			result.Nav[i] = rect(start + (i - 1) * (side + 8), 66, side, side)
		end
		result.Coins = rect(12, 66, math.max(100, start - 24), 46)
		local boostW = math.min(140, start - 24)
		result.Boosts = rect(w - boostW - 12, 68, boostW, 44)
		local hintW = math.min(330, w - 280)
		result.Hint = rect((w - hintW) / 2, 126, hintW, math.min(60, h - 242))
		result.Action = rect((w - 304) / 2, h - 74, 304, 62)
		result.Board = rect(0, 0, 0, 0)
	elseif portrait then
		for i = 1, 6 do
			result.Nav[i] = rect(10, 66 + (i - 1) * 44, 44, 44)
		end
		result.Coins = rect(76, 74, w - 90, 38)
		result.Boosts = rect(76, 114, w - 90, 44)
		result.Action = rect((w - 290) / 2, h - 184, 290, 58)
		result.Hint = rect(76, 196, w - 90, 80)
		result.Board = rect(0, 0, 0, 0)
	else
		local bottom = if touch then 130 else 20
		local available = h - bottom - 200
		local side = math.clamp(math.floor((available - 40) / 6), 44, 96)
		local navH = side * 6 + 8 * 5
		local navY = 100 + math.min(0, available - navH) + math.max(0, math.floor((available - navH) / 2))
		for i = 1, 6 do
			result.Nav[i] = rect(margin, navY + (i - 1) * (side + 8), side, side)
		end
		local actionW = if w < 1000 then 330 else 410
		local sideW = math.min(260, (w - actionW) / 2 - margin - 18)
		result.Coins = rect(margin, h - bottom - 72, sideW, 60)
		result.Boosts = rect(w - margin - sideW, h - bottom - 60, sideW, 48)
		result.Action = rect((w - actionW) / 2, h - bottom - 82, actionW, 82)
		result.Hint = rect((w - 440) / 2, math.max(182, h * 0.24), 440, 94)
		result.Board = rect((w - 340) / 2, 90, 340, 72)
	end
	result.PendingIncome = if portrait
		then rect(76, 162, math.min(140, w - 90), 26)
		elseif short then rect(w - 132, 112, 120, 24)
		else rect(result.Coins.X, result.Coins.Y - 20, math.min(200, result.Coins.W), 18)
	result.Offers = rect(w - 190, math.max(190, h * 0.29), 168, 292)
	result.Celebration = if portrait
		then rect(w - 124, 162, 112, 44)
		elseif short then rect(12, 120, 112, 44)
		else rect(w - 136, result.Offers.Y - 56, 112, 44)
	result.SocialBoosts = if portrait
		then rect(76, 284, w - 90, 44)
		elseif short then rect(
			w - math.min(132, (w - math.min(330, w - 280)) / 2 - 24) - 12,
			138,
			math.min(132, (w - math.min(330, w - 280)) / 2 - 24),
			44
		)
		else rect(result.Boosts.X, result.Boosts.Y - 54, result.Boosts.W, 44)
	local flushW = result.Action.W - 96
	result.Pointer = if portrait
		then rect(result.Action.X + flushW * 0.78 - 16, result.Action.Y + result.Action.H + 6, 32, 32)
		elseif short then rect(result.Action.X + flushW * 0.8 - 16, result.Action.Y - 36, 32, 32)
		else rect(result.Action.X + flushW - 54, result.Action.Y - 54, 48, 48)
	result.Reveal = if portrait
		then rect(76, 196, w - 90, math.min(150, h - 438))
		else rect(
			(w - math.min(if short then 330 else 430, w - 100)) / 2,
			math.max(122, h * 0.39),
			math.min(if short then 330 else 430, w - 100),
			math.min(150, h * 0.23, result.Action.Y - 54 - math.max(122, h * 0.39))
		)
	result.CoinPopup = if portrait
		then rect(76 + (w - 90) / 2 - 90, h - 230, 180, 36)
		else rect(result.Action.X + result.Action.W / 2 - 90, result.Action.Y - 46, 180, 36)
	result.CoinRise =
		math.min(if short then 0 else 42, math.max(0, result.CoinPopup.Y - result.Reveal.Y - result.Reveal.H - 8))
	local eventW = math.min(580, w - 120)
	result.Event = rect((w - eventW) / 2 - (if portrait then 24 else 0), 10, eventW, if short then 50 else 54)
	return result
end
function Layout.Modal(w, h)
	local width, height = math.min(1060, w - 24), math.min(730, h - 24)
	return rect((w - width) / 2, (h - height) / 2, width, height)
end
function Layout.Toast(w, h, touch)
	local action = Layout.Compute(w, h, touch).Action
	local modal = Layout.Modal(w, h)
	local width = math.min(420, w - 48)
	return rect((w - width) / 2, math.max(modal.Y + 74, action.Y - 74), width, 64)
end
function Layout.Grid(width, minimum, gap, maximumColumns)
	local columns = math.max(1, math.floor((width + gap) / (minimum + gap)))
	columns = math.min(columns, maximumColumns or columns)
	return columns, math.floor((width - (columns - 1) * gap) / columns)
end
-- The top of each grid cell reserves space for the overflowing sculpture.
Layout.PassCard = {
	MinimumWidth = 224,
	CellHeight = 314,
	Top = 48,
	Height = 266,
	IconSize = 128,
	IconY = -48,
	TitleY = 88,
	TitleHeight = 40,
	DescriptionY = 134,
	DescriptionHeight = 24,
	StatusY = 164,
	StatusHeight = 24,
	ButtonY = 204,
	ButtonHeight = 50,
	GiftWidth = 72,
	Inset = 12,
	Gap = 10,
}
return Layout
