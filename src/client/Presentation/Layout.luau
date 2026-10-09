local HUDLayout = require(if script then script.Parent.Parent.UI.Layout else "../UI/Layout")
local Layout = {}
function Layout.Compute(w, h, touch)
	w, h = math.max(1, w), math.max(1, h)
	local compactHUD = h < 500
	local portrait = w < 760 and h > w
	local model = math.min(w * 0.78, h * 0.43, 390)
	local center = h * 0.38
	local short = h < 360
	if short then
		model = math.max(40, math.min(model, h - 192))
	end
	return {
		Model = { X = (w - model) / 2, Y = if short then 48 else center - model / 2, W = model, H = model },
		Name = {
			X = 12,
			Y = if short then h - 136 else h * 0.63,
			W = math.max(1, w - 24),
			H = if short then 32 else h * 0.095,
		},
		Odds = {
			X = 12,
			Y = if short then h - 96 else h * 0.735,
			W = math.max(1, w - 24),
			H = if short then 32 else h * 0.08,
		},
		Skip = { X = (w - math.min(240, w - 24)) / 2, Y = h - 56, W = math.min(240, w - 24), H = 44 },
		Banner = { X = 0, Y = h * 0.34, W = w, H = math.min(120, h * 0.27) },
		Toast = if HUDLayout.IsPhone(w, h, touch)
			then HUDLayout.Toast(w, h, touch)
			elseif portrait then { X = 88, Y = math.max(174, h - 104), W = w - 106, H = 44 }
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
