-- Session-only admin testing, kept completely separate from Marketplace ownership.
local Unlocks = {}
function Unlocks.new(config, passes, clock)
	local self = { Players = {} }
	function self:Set(player, enabled)
		self.Players[player] = if enabled then clock() + config.MovementLeaseSeconds else nil
	end
	function self:Renew(player)
		if self.Players[player] and clock() < self.Players[player] then
			self:Set(player, true)
		end
	end
	function self:Owned(player, real)
		if not self.Players[player] or clock() >= self.Players[player] then
			return real
		end
		local owned = table.clone(real)
		for _, id in ipairs(passes.PassOrder) do
			owned[id] = true
		end
		return owned
	end
	function self:Cosmetics(player, real, rewards)
		if not self.Players[player] or clock() >= self.Players[player] then
			return real
		end
		local result = table.clone(real)
		for _, reward in ipairs(rewards.Milestones) do
			if reward.Cosmetic then
				result[reward.Cosmetic] = true
			end
		end
		if rewards.FoundingReward.Cosmetic then
			result[rewards.FoundingReward.Cosmetic] = true
		end
		return result
	end
	return self
end
return Unlocks
