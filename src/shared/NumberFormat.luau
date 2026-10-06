-- Presentation only; wallet validation remains capped at 9e15 on the server.
local Format = {}
local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
function Format.Compact(value, decimals)
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return "0"
	end
	local index = 1
	while value >= 1000 and index < #suffixes do
		value /= 1000
		index += 1
	end
	local digits = if index > 1 then 1 else (decimals or 0)
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
