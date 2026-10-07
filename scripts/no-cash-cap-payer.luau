-- All passes from account creation; no consumable purchases, events, daily or offline grants.
local Long = require("./permanent-cohort")
local Short = require("./economy-cohort")
local Toilets = require("../src/shared/Config/Toilets")
local function p(values, f)
	return Short.Percentile(table.clone(values), f)
end
for _, arch in ipairs({ { "Normal", 0.75 }, { "Casual", 0.3 }, { "Grinder", 1 } }) do
	local passes = { UltimateBundle = true }
	local short = Short.Run(200, arch[2], false, nil, nil, 7, passes)
	local long = Long.Run(64, arch[2], 300, false, passes)
	print(arch[1] .. " all passes; tier p50/p90 minutes; rebirth/upgrade p50/p90 hours")
	for tier = 2, 7 do
		print(arch[1], Toilets[tier].Id, p(short.Tiers[tier], 0.5), p(short.Tiers[tier], 0.9))
	end
	for level = 1, 15 do
		print(arch[1], "R" .. level, p(long.Rebirths[level], 0.5), p(long.Rebirths[level], 0.9))
	end
	for id, levels in pairs(long.Levels) do
		local level = if id == "DisplaySlots" then 7 else #levels
		print(arch[1], id, level, p(levels[level], 0.5), p(levels[level], 0.9))
	end
end
