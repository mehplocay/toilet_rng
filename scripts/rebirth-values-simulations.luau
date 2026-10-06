-- Report every archetype even when requested timing targets fail.
local C = require("./permanent-cohort")
local percentile = require("./economy-cohort").Percentile
local Config = require("../src/shared/Config/Rebirth")
for _, archetype in ipairs({ { "Normal", 0.75 }, { "Casual", 0.3 }, { "Grinder", 1 } }) do
	local result = C.Run(64, archetype[2], 300)
	for level, row in ipairs(Config.Levels) do
		print(
			string.format(
				"%s | R%d | %.0f Coins | p50 %.3fh / p90 %.3fh",
				archetype[1],
				level,
				row.RequiredCoins,
				percentile(table.clone(result.Rebirths[level]), 0.5),
				percentile(table.clone(result.Rebirths[level]), 0.9)
			)
		)
	end
end
