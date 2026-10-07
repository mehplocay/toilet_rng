local RewardService = {}
local CashMath = require(if script then game.ReplicatedStorage.Shared.CashMath else "../../shared/CashMath")
local NumberFormat = require(if script then game.ReplicatedStorage.Shared.NumberFormat else "../../shared/NumberFormat")
local Paid = require(if script then game.ReplicatedStorage.Shared.PaidBenefits else "../../shared/PaidBenefits")
RewardService.__index = RewardService

function RewardService.new(config, schedule, clock)
	return setmetatable({ Config = config, Schedule = schedule, Clock = clock }, RewardService)
end

function RewardService:Luck(profile)
	return if profile and profile.RewardLuckExpires > self.Clock() then self.Config.LuckMultiplier else 1
end

function RewardService:Claim(profile)
	local now = self.Clock()
	local available, day = self.Schedule.Progress(profile.LastClaimDay, profile.Streak, now, self.Config)
	if not available then
		return { Success = false, Message = "Today's reward has already been claimed." }
	end
	-- Daily tuning is independent of display rates and coin/rebirth upgrades.
	-- Apply paid cash once; pending income already includes its own multipliers.
	local coins = math.floor(
		CashMath.Product(
			self.Schedule.Coins(day, profile.ToiletTier, self.Config),
			Paid.Cash(profile, 1),
			CashMath.Limit
		)
	)
	if not CashMath.CanGrant(profile, coins) then
		return { Success = false, Message = "Coin limit reached." }
	end
	-- No yields: eligibility and all reward mutations are one server-side operation.
	profile.LastClaimDay = math.floor(now / self.Config.DaySeconds)
	profile.Streak = day
	profile.Coins = CashMath.Credit(profile.Coins, coins)
	profile.Stats.Earned += coins
	if day == #self.Config.BaseCoins then
		profile.RewardLuckExpires = now + self.Config.LuckSeconds
	end
	return {
		Success = true,
		Day = day,
		Coins = coins,
		Message = "+" .. NumberFormat.Compact(coins) .. " Coins!" .. (if day == #self.Config.BaseCoins
			then " Luck x2 for 10 minutes!"
			else ""),
	}
end

function RewardService:Start(data, limiter, remotes, sync)
	remotes.ClaimReward.OnServerEvent:Connect(function(player, ...)
		if not limiter:Allow(player, "ClaimReward") or select("#", ...) ~= 0 then
			return
		end
		local profile = data:Get(player)
		if not profile or data.Saving[player] then
			return
		end
		local result = self:Claim(profile)
		if result.Success and not data:Save(player, false) then
			return
		end
		if data:Get(player) ~= profile then
			return
		end
		sync(player)
		remotes.Result:FireClient(player, "ClaimReward", result)
	end)
end

return RewardService
