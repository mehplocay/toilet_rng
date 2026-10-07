-- Shared presentation for all finite coin amounts, including scientific notation.
local Format = {}
local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local scales = { 1, 1e3, 1e6, 1e9, 1e12, 1e15, 1e18, 1e21, 1e24, 1e27, 1e30, 1e33 }
function Format.Compact(value, decimals)
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return "0"
	end
	if value >= 1e36 then
		return (string.format("%.2e", value):gsub("e%+0*", "e"))
	end
	local index = 1
	while index < #suffixes and value >= scales[index + 1] do
		index += 1
	end
	value /= scales[index]
	local digits = if index > 1
		then 1
		else math.clamp(
			if type(decimals) == "number" and decimals == decimals then math.floor(decimals) else 0,
			0,
			6
		)
	local scale = 10 ^ digits
	local rounded = math.floor(value * scale) / scale
	local text = string.format("%." .. digits .. "f", rounded)
	if digits > 0 then
		text = text:gsub("0+$", ""):gsub("%.$", "")
	end
	return text .. suffixes[index]
end
function Format.Rate(value)
	return Format.Compact(value, 2)
end
return Format
