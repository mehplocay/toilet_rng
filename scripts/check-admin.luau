local Config = require("../src/shared/Config/Admin")
local Rules = require("../src/server/Admin/Rules")
local Authorization = require("../src/server/Admin/Authorization")
local items = require("../src/shared/Config/Items")
local rules = Rules.new(
	Config,
	items,
	require("../src/shared/Config/Toilets"),
	require("../src/shared/Config/Upgrades"),
	require("../src/shared/Config/Rebirth")
)
local now, calls = 0, 0
local config = table.clone(Config)
local auth = Authorization.new(config, function()
	return now
end, function(p)
	return p.Present
end, function()
	calls += 1
	return 77
end)
assert(auth:Allowed({ UserId = 1212975135, Name = "renamed", Present = true }))
for _, id in ipairs({ -1, 0, 1, 1212975134, 1212975136, 77 }) do
	assert(not auth:Allowed({ UserId = id, Name = "mehmetcayir2", DisplayName = "mehmetcayir2", Present = true }))
end
assert(calls == 0)
config.AllowGroupOwner = true
local groupOwner = { UserId = 77, Present = true }
assert(auth:Allowed(groupOwner) and auth:Allowed(groupOwner) and calls == 1)
now = 61
assert(auth:Allowed(groupOwner) and calls == 2)
groupOwner.Present = false
assert(not auth:Allowed(groupOwner))
auth:Remove(groupOwner)
assert(auth.Cache[groupOwner] == nil)
local failed = Authorization.new(config, function()
	return now
end, function()
	return true
end, function()
	error("offline")
end)
assert(not failed:Allowed({ UserId = 77 }))
for _, value in ipairs({ -1, 0 / 0, math.huge, -math.huge, 10001, 1.5, "1", false, {} }) do
	assert(not rules:Valid("Give", { ItemId = "Poop", Count = value }))
end
assert(rules:Valid("Give", { ItemId = "Poop", Count = 10000 }))
assert(not rules:Valid("Give", { ItemId = "unknown", Count = 1 }))
assert(not rules:Valid("Give", { ItemId = "Poop", Count = 1, Target = 77 }))
assert(not rules:Valid("Give", { ItemId = "Poop" }))
assert(not rules:Valid("RunCode", { Source = "print(1)" }))
assert(not rules:Valid("Upgrade", { Track = "LuckBoost", Level = 11 }))
assert(not rules:Valid("Import", { Json = string.rep("x", Config.MaxImportBytes + 1) }))
assert(not Rules.JsonTree({ Coins = math.huge }, Config))
local cycle = {}
cycle.Self = cycle
assert(not Rules.JsonTree(cycle, Config))
assert(Rules.JsonTree({ Coins = 10, Inventory = { Poop = 2 } }, Config))
print("Admin pure checks passed: identity, optional cached owner, fail-closed errors, bounds, whitelist, JSON budget")
