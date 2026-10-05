-- Pure safe-area geometry, also executed by scripts/check-ui-layout.luau.
local Layout = {}
local function rect(x, y, w, h)
	return { X = math.floor(x), Y = math.floor(y), W = math.floor(w), H = math.floor(h) }
end
function Layout.Compute(w, h, touch)
	local portrait = w < 600 and h > w
	local short = h < 500
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
		OffersVisible = not compact,
		Nav = {},
	}
	if short then
		local side = 50
		local start = (w - (side * 5 + 12 * 4)) / 2
		for i = 1, 5 do
			result.Nav[i] = rect(start + (i - 1) * (side + 12), 66, side, side)
		end
		result.Coins = rect(12, 66, math.max(100, start - 24), 46)
		result.Boosts = rect(w - 152, 68, 140, 42)
		result.Hint = rect((w - 350) / 2, 126, 350, 76)
		result.Action = rect((w - 304) / 2, h - 74, 304, 62)
		result.Board = rect(0, 0, 0, 0)
	elseif portrait then
		for i = 1, 5 do
			result.Nav[i] = rect(10, 82 + (i - 1) * 66, 56, 56)
		end
		result.Coins = rect(14, h - 280, w - 28, 42)
		result.Boosts = rect(14, h - 230, w - 28, 34)
		result.Action = rect((w - 290) / 2, h - 184, 290, 58)
		result.Hint = rect(88, 114, w - 106, 106)
		result.Board = rect(88, 234, w - 106, 86)
	else
		local bottom = if touch then 130 else 20
		local available = h - bottom - 192
		local side = math.clamp(math.floor((available - 48) / 5), 56, 96)
		local navH = side * 5 + 12 * 4
		local navY = 100 + math.max(0, math.floor((available - navH) / 2))
		for i = 1, 5 do
			result.Nav[i] = rect(margin, navY + (i - 1) * (side + 12), side, side)
		end
		local actionW = if w < 1000 then 330 else 410
		local sideW = math.min(260, (w - actionW) / 2 - margin - 18)
		result.Coins = rect(margin, h - bottom - 72, sideW, 60)
		result.Boosts = rect(w - margin - sideW, h - bottom - 60, sideW, 48)
		result.Action = rect((w - actionW) / 2, h - bottom - 82, actionW, 82)
		result.Hint = rect((w - 440) / 2, math.max(182, h * 0.24), 440, 94)
		result.Board = rect((w - 340) / 2, 90, 340, 72)
	end
	result.Offers = rect(w - 190, math.max(190, h * 0.29), 168, 292)
	local flushW = result.Action.W - 96
	result.Pointer = if portrait
		then rect(result.Action.X + flushW * 0.78 - 16, result.Action.Y + result.Action.H + 6, 32, 32)
		elseif short then rect(result.Action.X + flushW * 0.8 - 16, result.Action.Y - 36, 32, 32)
		else rect(result.Action.X + flushW - 54, result.Action.Y - 54, 48, 48)
	result.Reveal = if portrait
		then rect(88, 150, w - 106, 150)
		else rect(
			(w - math.min(430, w - 100)) / 2,
			math.max(122, h * 0.39),
			math.min(430, w - 100),
			math.min(150, h * 0.23)
		)
	result.CoinPopup = if portrait
		then rect(88 + (w - 106) / 2 - 90, h - 324, 180, 36)
		else rect(result.Action.X + result.Action.W / 2 - 90, result.Action.Y - 46, 180, 36)
	result.CoinRise =
		math.min(if short then 0 else 42, math.max(0, result.CoinPopup.Y - result.Reveal.Y - result.Reveal.H - 8))
	local eventW = math.min(580, w - 90)
	result.Event = rect((w - eventW) / 2 - (if portrait then 24 else 0), 10, eventW, if short then 50 else 54)
	return result
end
function Layout.Modal(w, h)
	local width, height = math.min(1060, w - 24), math.min(730, h - 24)
	return rect((w - width) / 2, (h - height) / 2, width, height)
end
function Layout.Grid(width, minimum, gap, maximumColumns)
	local columns = math.max(1, math.floor((width + gap) / (minimum + gap)))
	columns = math.min(columns, maximumColumns or columns)
	return columns, math.floor((width - (columns - 1) * gap) / columns)
end
return Layout
