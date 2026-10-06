-- Compatibility entry point; the coin-gate economy supersedes the old reset-to-Basic model.
local C = require("./permanent-cohort")
local percentile = require("./economy-cohort").Percentile
local Config = require("../src/shared/Config/Rebirth")
local Balance = {}
function Balance.Run(population, uptime)
	return C.Run(population or 64, uptime or 0.75, 300)
end
function Balance.Print()
	local result = Balance.Run()
	for level, bonus in ipairs(Config.Levels) do
		print(
			string.format(
				"Rebirth %d | %.0f coins + %d fresh flushes | p50 %.2fh / p90 %.2fh",
				level,
				bonus.RequiredCoins,
				Config.RequiredFlushes,
				percentile(result.Rebirths[level], 0.5),
				percentile(result.Rebirths[level], 0.9)
			)
		)
	end
end
return Balance
