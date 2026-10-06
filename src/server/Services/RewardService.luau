local RewardService = {}
local NumberFormat = require(if script then game.ReplicatedStorage.Shared.NumberFormat else "../../shared/NumberFormat")
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
	local coins = self.Schedule.Coins(day, profile.ToiletTier, self.Config)
	if coins > 9e15 - profile.Coins or coins > 9e15 - profile.Stats.Earned then
		return { Success = false, Message = "Coin limit reached." }
	end
	-- No yields: eligibility and all reward mutations are one server-side operation.
	profile.LastClaimDay = math.floor(now / self.Config.DaySeconds)
	profile.Streak = day
	profile.Coins += coins
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
