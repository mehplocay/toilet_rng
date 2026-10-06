local Config = require("../src/shared/Config/Rewards")
local Schedule = require("../src/shared/RewardSchedule")
local Service = require("../src/server/Services/RewardService")
local Limiter = require("../src/server/Services/RateLimiter")
local Remotes = require("../src/shared/Config/Remotes")
local now = 20000 * Config.DaySeconds
local service = Service.new(Config, Schedule, function()
	return now
end)
local profile =
	{ LastClaimDay = 0, Streak = 0, Coins = 0, ToiletTier = 1, RewardLuckExpires = 0, Stats = { Earned = 0 } }
local ready, day = Schedule.Progress(0, 0, now, Config)
assert(ready and day == 1)
local boundary = now
ready, day = Schedule.Progress(19999, 3, boundary - 1, Config)
assert(not ready and day == 3)
local nextAt
ready, day, nextAt = Schedule.Progress(19999, 3, boundary, Config)
assert(ready and day == 4 and nextAt == boundary + Config.DaySeconds)
for index = 1, 7 do
	local result = service:Claim(profile)
	assert(result.Success and result.Day == index and result.Coins == Config.BaseCoins[index])
	local balance = profile.Coins
	assert(not service:Claim(profile).Success and profile.Coins == balance)
	ready, day = Schedule.Progress(profile.LastClaimDay, profile.Streak, now + Config.DaySeconds - 1, Config)
	assert(not ready and day == index)
	if index < 7 then
		assert(service:Luck(profile) == 1)
		now += Config.DaySeconds
	end
end
assert(profile.Coins == profile.Stats.Earned)
assert(service:Luck(profile) == 2)
local reloaded = table.clone(profile)
assert(service:Luck(reloaded) == 2)
now = profile.RewardLuckExpires - 1
assert(service:Luck(profile) == 2)
now += 1
assert(service:Luck(profile) == 1)
now = (profile.LastClaimDay + 1) * Config.DaySeconds
assert(service:Claim(profile).Day == 1)
now += 2 * Config.DaySeconds
assert(service:Claim(profile).Day == 1)
now -= Config.DaySeconds
assert(not service:Claim(profile).Success) -- Future claim dates cannot be claimed again.
now = (profile.LastClaimDay + 1) * Config.DaySeconds
profile.ToiletTier = 7
assert(service:Claim(profile).Coins == Config.BaseCoins[2] * Config.TierMultipliers[7])
now += Config.DaySeconds
profile.Coins = 9e15
local lastDay = profile.LastClaimDay
assert(not service:Claim(profile).Success and profile.LastClaimDay == lastDay)

-- Exercise the same remote callback used in Roblox, without engine dependencies.
local callback, saves, syncs, results = nil, 0, 0, 0
local player = {}
local data = {
	Saving = {},
	Get = function()
		return profile
	end,
	Save = function()
		saves += 1
		return true
	end,
}
local remotes = {
	ClaimReward = { OnServerEvent = {
		Connect = function(_, handler)
			callback = handler
		end,
	} },
	Result = {
		FireClient = function()
			results += 1
		end,
	},
}
local limiter = Limiter.new(Remotes.Limits)
service:Start(data, limiter, remotes, function()
	syncs += 1
end)
callback(player, "forged", 7)
assert(results == 0 and saves == 0)
profile.Coins = 0
callback(player)
assert(saves == 1 and syncs == 1 and results == 1)
callback(player)
assert(results == 1 and saves == 1) -- Rate limited, including malformed requests.
limiter:Remove(player)
callback(player)
assert(results == 2 and saves == 1) -- Duplicate claim rejected without another save.
limiter:Remove(player)
data.Get = function()
	return nil
end
callback(player)
assert(results == 2 and saves == 1) -- Loading/closing profiles cannot claim.
limiter:Remove(player)
data.Get = function()
	return profile
end
data.Save = function()
	return false
end
now += Config.DaySeconds
callback(player)
assert(results == 2 and syncs == 2) -- Failed persistence cannot report success.
print(
	"Reward checks passed: UTC boundaries, duplicate claims, missed days, cycle, tiers, boost expiry, validation and rate limits"
)

-- All paid combinations share the preview's schedule; upgrades never multiply a daily twice.
for _, double in ipairs({ false, true }) do
	for _, vip in ipairs({ false, true }) do
		for tier = 1, 7 do
			for rewardDay = 1, 7 do
				local expected = math.floor(
					Config.BaseCoins[rewardDay]
						* Config.TierMultipliers[tier]
						* (if double then 2 else 1)
						* (if vip then 1.25 else 1)
				)
				local function fresh()
					return {
						LastClaimDay = math.floor(now / Config.DaySeconds) - 1,
						Streak = rewardDay - 1,
						ToiletTier = tier,
						RewardLuckExpires = 0,
						Coins = 0,
						Stats = { Earned = 0 },
						RebirthLevel = 15,
						Upgrades = { CashBoost = 10 },
						Monetization = { Passes = { DoubleCash = double, VIPPack = vip } },
					}
				end
				for _, field in ipairs({ "Coins", "Earned" }) do
					local paidProfile = fresh()
					local balance = if field == "Coins" then paidProfile else paidProfile.Stats
					balance[field] = 9e15 - expected
					assert(service:Claim(paidProfile).Coins == expected and balance[field] == 9e15)
					paidProfile = fresh()
					balance = if field == "Coins" then paidProfile else paidProfile.Stats
					balance[field] = 9e15 - expected + 1
					local last = paidProfile.LastClaimDay
					assert(not service:Claim(paidProfile).Success)
					assert(balance[field] == 9e15 - expected + 1 and paidProfile.LastClaimDay == last)
					assert(paidProfile.Streak == rewardDay - 1 and paidProfile.RewardLuckExpires == 0)
				end
			end
		end
	end
end
print(
	"Reward merge checks passed: all tiers/days/paid factors, exact wallet/Earned ceilings and atomic overflow rejection"
)
