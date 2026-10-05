local Items = require("../src/shared/Config/Items")
local Config = require("../src/shared/Config/IndexRewards")
local Index = require("../src/shared/IndexProgress")
local Safe = require("../src/shared/SafeInventory")
local Display = require("../src/server/Services/DisplayService")
local Service = require("../src/server/Services/IndexService")
local Limiter = require("../src/server/Services/RateLimiter")
local Remotes = require("../src/shared/Config/Remotes")
local index = Index.new(Items, Config)

local function profile()
	local result = {
		Inventory = {},
		Collection = {},
		Displays = {},
		DisplaySlots = 3,
		Coins = 20,
		Stats = { Earned = 30 },
		RewardLuckExpires = 123,
	}
	index:Sanitize(result, nil)
	return result
end

local p = profile()
assert(p.Stamps == 0 and next(p.IndexClaims) == nil and next(p.IndexCosmetics) == nil)
assert(not index:Claim(p, "total:3").Success)
assert(not index:Claim(p, {}).Success and not index:Claim(p, "unknown").Success)
assert(index.ById["total:12"] == nil and index.ById["total:35"] == nil)
for _, item in ipairs(Items) do
	assert(index.ById["rarity:" .. item.Rarity])
end

-- Lifetime discovery counts, including sold-out items, never depend on inventory.
p.Collection = { Poop = 50, ToiletPaper = 1, Rat = 1, Unknown = 900 }
local total, rarities = index:Progress(p)
assert(total == 3 and rarities.Common.Discovered == 1 and rarities.Rare.Total == 2)
assert(not index:Claim(p, "rarity:Rare").Success)
assert(index:Claim(p, "total:3").Success and p.Stamps == 10)
assert(not index:Claim(p, "total:3").Success and p.Stamps == 10)
assert(index:Claim(p, "rarity:Common").Success and p.Stamps == 12)
assert(p.Coins == 20 and p.Stats.Earned == 30 and p.RewardLuckExpires == 123)
assert(next(p.Inventory) == nil)

-- Sanitizing a saved profile is repeatable and cannot mint another reward.
local saved = profile()
saved.Collection = table.clone(p.Collection)
index:Sanitize(saved, p)
assert(saved.Stamps == p.Stamps and saved.IndexClaims["total:3"])
assert(not index:Claim(saved, "total:3").Success)
for _, item in ipairs(Items) do
	p.Collection[item.Id] = 1
end
assert(index:Claim(p, "total:5").Success and p.DisplaySlots == 4)
assert(index:Claim(p, "total:8").Success and p.IndexCosmetics.PipeApprentice)
assert(index:Claim(p, "founding").Success and p.IndexCosmetics.FoundingFlush)
assert(not index:Claim(p, "founding").Success)
p.DisplaySlots = 9
index:Sanitize(saved, p)
assert(saved.DisplaySlots == 4 and saved.IndexCosmetics.PipeApprentice and saved.IndexCosmetics.FoundingFlush)
assert(index:Claim(p, "rarity:Rare").Success)
assert(p.DisplaySlots == 9) -- Existing expanded capacity is never reduced by claims.

local malformed = profile()
index:Sanitize(
	malformed,
	{ Stamps = 0 / 0, IndexClaims = { ["total:3"] = "true", unknown = true }, IndexCosmetics = { Unknown = true } }
)
assert(malformed.Stamps == 0 and next(malformed.IndexClaims) == nil and next(malformed.IndexCosmetics) == nil)
index:Sanitize(malformed, { Stamps = math.huge, IndexClaims = false })
assert(malformed.Stamps == 0)
index:Sanitize(malformed, { Stamps = 3.9, IndexClaims = { ["total:5"] = true } })
assert(malformed.Stamps == 3 and malformed.DisplaySlots == 4)
local capped = profile()
capped.Collection.Poop, capped.Stamps = 1, 9e15
assert(not index:Claim(capped, "rarity:Common").Success and not capped.IndexClaims["rarity:Common"])

-- New shipped items grow denominators without invalidating earlier claim IDs.
local expanded = table.clone(Items)
for n = #Items + 1, 35 do
	table.insert(expanded, { Id = "New" .. n, Rarity = "Rare" })
end
local future = Index.new(expanded, Config)
index:Sanitize(saved, p)
assert(not future:Claim(saved, "rarity:Rare").Success)
local full = profile()
for _, item in ipairs(expanded) do
	full.Collection[item.Id] = 1
end
assert(future:Claim(full, "total:18").Success and full.DisplaySlots == 6 and full.Stamps == 40)
assert(future:Claim(full, "total:12").Success and full.DisplaySlots == 6)
assert(future:Claim(full, "total:35").Success and full.IndexCosmetics.FullIndexPlaque)

-- Single sales and Sell All use the same actual server sale logic.
local inv = profile()
inv.Inventory.Poop, inv.Collection.Poop = 4, 200
assert(Safe.Sellable(inv, "Poop") == 3)
assert(not Safe.Sell(inv, Items, "Poop", 4))
assert(Safe.Sell(inv, Items, "Poop", Safe.Sellable(inv, "Poop")))
assert(
	inv.Inventory.Poop == 1
		and inv.Collection.Poop == 200
		and inv.Coins == 20 + 3 * Items[1].Value
		and inv.Stats.Earned == 30 + 3 * Items[1].Value
)
assert(not Safe.Sell(inv, Items, "Poop", 1))
inv.Inventory.Poop = 5
assert(Display.Set(inv, "Poop", 1) and Display.Set(inv, "Poop", 2))
assert(Safe.Sellable(inv, "Poop") == 3)
assert(Safe.Sell(inv, Items, "Poop", 3) and inv.Inventory.Poop == 2)
assert(inv.Displays["1"] == "Poop" and inv.Displays["2"] == "Poop")
assert(Safe.Sellable(inv, "Poop") == 0 and not Safe.Sell(inv, Items, "Poop", 1))
assert(Display.Set(inv, nil, 1) and Safe.Sellable(inv, "Poop") == 1)
assert(Safe.Sell(inv, Items, "Poop", 1) and inv.Inventory.Poop == 1)
assert(not Safe.Sell(inv, Items, "Poop", 1)) -- Displayed first copy is usable but protected.
for _, count in ipairs({ 0, -1, 1.5, 0 / 0, math.huge, "1", {}, 1000001 }) do
	assert(not Safe.Sell(inv, Items, "Poop", count))
end
assert(not Safe.Sell(inv, Items, {}, 1) and not Safe.Sell(inv, Items, "Unknown", 1))
inv.Inventory.Poop, inv.Coins = 4, 9e15
assert(not Safe.Sell(inv, Items, "Poop", 1) and inv.Inventory.Poop == 4)
inv.Coins, inv.Stats.Earned = 0, 9e15
assert(not Safe.Sell(inv, Items, "Poop", 1) and inv.Inventory.Poop == 4)

-- Exercise the remote handler without Roblox: validation, limits and save-before-success.
local handler, saves, syncs, results = nil, 0, 0, {}
local remoteProfile, player = profile(), {}
remoteProfile.Collection = { Poop = 1, Rat = 1, Fish = 1 }
local data = {
	Saving = {},
	Get = function()
		return remoteProfile
	end,
	Save = function()
		saves += 1
		return true
	end,
}
local remotes = {
	ClaimIndexReward = { OnServerEvent = {
		Connect = function(_, callback)
			handler = callback
		end,
	} },
	Result = {
		FireClient = function(_, target, action, result)
			assert(target == player and action == "ClaimIndexReward" and saves > 0)
			table.insert(results, result)
		end,
	},
}
local limiter = Limiter.new(Remotes.Limits)
Service.Start(index, data, limiter, remotes, function()
	syncs += 1
end)
handler(player, "total:3", "extra")
handler(player, {})
assert(saves == 0 and #results == 0)
handler(player, "total:3")
assert(saves == 1 and syncs == 1 and #results == 1 and results[1].Success)
handler(player, "rarity:Common") -- Rate-limited even though eligible.
assert(saves == 1 and not remoteProfile.IndexClaims["rarity:Common"])
limiter:Remove(player)
handler(player, "total:3")
assert(saves == 1 and #results == 2 and not results[2].Success and remoteProfile.Stamps == 10)
data.Save = function()
	saves += 1
	return false
end
handler(player, "rarity:Common")
assert(saves == 2 and #results == 2) -- Never send success after failed persistence.
print(
	"Index checks passed: migration, lifetime counts, one-time rewards, safe sales, reservations, remote limits and persistence failure"
)
