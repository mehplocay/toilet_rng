-- Cohort policy: reserve the most valuable owned copies, sell only the remainder.
-- Normal accounts retain three slots; ten slots models an already expanded plot.
local Items = require("../src/shared/Config/Items")
local Inventory = require("../src/shared/SafeInventory")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Income = require("../src/shared/IncomeAccrual").new(require("../src/shared/Config/Income"), Items, U)
local Config = require("../src/shared/Config/Income")
local ordered = table.clone(Items)
table.sort(ordered, function(a, b)
	local ar, br = Config.RarityRates[a.Rarity], Config.RarityRates[b.Rarity]
	return if ar ~= br then ar > br elseif a.Value ~= b.Value then a.Value > b.Value else a.Id < b.Id
end)
local D = {}
function D.Settle(p, seconds)
	Income:Settle(p, 1000 + math.floor(seconds), false)
	if seconds >= (p.NextCollection or 60) then
		Income:Collect(p)
		p.NextCollection = seconds + 60
	end
end
function D.ReserveAndSell(p)
	p.Displays = {}
	local slot = 0
	for _, item in ipairs(ordered) do
		for _ = 1, math.min(p.Inventory[item.Id] or 0, p.DisplaySlots - slot) do
			slot += 1
			p.Displays[tostring(slot)] = item.Id
		end
		local count = Inventory.Sellable(p, item.Id)
		if count > 0 then
			assert(Inventory.Sell(p, Items, item.Id, count, U:Cash(p)))
		end
	end
end
return D
