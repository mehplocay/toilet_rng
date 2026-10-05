local Layout = {}
function Layout.Compute(w, h)
	w, h = math.max(1, w), math.max(1, h)
	local short = h < 450
	local compactHUD = h < 500
	local portrait = w < 760 and h > w
	local model = math.min(w * 0.78, h * (if short then 0.43 else 0.48), 390)
	local center = h * 0.38
	return {
		Model = { X = (w - model) / 2, Y = center - model / 2, W = model, H = model },
		Name = { X = 12, Y = h * 0.63, W = math.max(1, w - 24), H = h * 0.095 },
		Odds = { X = 12, Y = h * 0.735, W = math.max(1, w - 24), H = h * 0.08 },
		Skip = { X = (w - math.min(240, w - 24)) / 2, Y = h - 56, W = math.min(240, w - 24), H = 44 },
		Banner = { X = 0, Y = h * 0.34, W = w, H = math.min(120, h * 0.27) },
		Toast = if portrait
			then { X = 88, Y = math.max(174, h - 104), W = w - 106, H = 44 }
			elseif compactHUD then { X = w - 142, Y = 146, W = 132, H = 44 }
			else { X = (w - 340) / 2, Y = 174, W = 340, H = 44 },
		List = {
			X = math.max(12, w - 372),
			Y = 60,
			W = math.min(360, w - 24),
			H = math.max(80, math.min(370, h - 192)),
		},
	}
end
return Layout
