-- Pure client observer: only confirmed snapshots/results produce economic feedback.
local Feedback = {}
function Feedback.new(audio, upgrades, rewards, monetization)
	local self = { Previous = nil, Boosts = {}, LastFlushId = 0 }
	function self:Luck(kind, expires, now)
		local active = (expires or 0) > now
		local previous = self.Boosts[kind]
		if previous ~= nil and previous ~= active then
			audio:Play(if active then "LuckStart" else "LuckEnd")
		end
		self.Boosts[kind] = active
	end
	function self:Tick(now)
		if self.ServerExpiry ~= nil then
			self:Luck("Server", self.ServerExpiry, now)
		end
		if self.PersonalExpiry ~= nil then
			self:Luck("Personal", self.PersonalExpiry, now)
		end
	end
	function self:ServerLuck(expires, now)
		self.ServerExpiry = expires
		self:Luck("Server", expires, now)
	end
	function self:State(state, now)
		self.ServerExpiry, self.PersonalExpiry = state.ServerLuckExpires or 0, state.RewardLuckExpires or 0
		self:Tick(now or 0)
		local before = self.Previous
		self.Previous = state
		if not before then
			return -- Loading/restoring a profile is not a new purchase or reward.
		end
		if state.AutoFlush ~= before.AutoFlush then
			audio:Play("AutoFlushToggle")
		end
		if
			monetization
			and (before.LifetimeFlushes or 0) < monetization.AutoFlushUnlock
			and (state.LifetimeFlushes or 0) >= monetization.AutoFlushUnlock
		then
			audio:Play("UpgradeMax")
		end
		-- Rebirth prunes inventory, displays and upgrades; never call these sales/removals.
		if (state.RebirthLevel or 0) ~= (before.RebirthLevel or 0) then
			return
		end
		if state.ToiletTier > before.ToiletTier then
			audio:Play("ToiletUpgrade")
		end
		local maxed, upgraded = false, false
		for _, track in ipairs(upgrades.Tracks) do
			local level = (state.Upgrades or {})[track.Id] or 0
			if level > ((before.Upgrades or {})[track.Id] or 0) then
				upgraded = true
				maxed = maxed
					or level >= track.MaxLevel
					or (track.Id == "DisplaySlots" and state.DisplaySlots >= upgrades.DisplayCapacity)
			end
		end
		if upgraded then
			audio:Play(if maxed then "UpgradeMax" else "UpgradeBuy")
		end
		local sold = 0
		for id, count in pairs(before.Inventory or {}) do
			sold += math.max(0, count - ((state.Inventory or {})[id] or 0))
		end
		if sold > 0 and state.Coins > before.Coins then
			-- Result.Sell.Coins is the balance, not the award. The snapshot delta is the award.
			audio:Play(if sold > 1 then "SellAll" else "Sell", state.Coins - before.Coins)
		end
		local placed, removed = false, false
		for slot, id in pairs(state.Displays or {}) do
			placed = placed or (before.Displays or {})[slot] ~= id
		end
		for slot, id in pairs(before.Displays or {}) do
			removed = removed or (state.Displays or {})[slot] ~= id
		end
		if placed then
			audio:Play("DisplayPlace")
		elseif removed then
			audio:Play("DisplayReturn")
		end
	end
	function self:Result(action, payload)
		if action == "Flush" then
			local id = payload.FlushId
			if type(id) == "number" then
				if id ~= id or id % 1 ~= 0 or id > 9e15 or id <= self.LastFlushId then
					return false
				end
				self.LastFlushId = id
			end
		elseif payload.Success == false then
			audio:Play(
				if action == "BuyPass" then "PurchaseFail" elseif action == "Display" then "DisplayLocked" else "Error"
			)
		elseif payload.Success == true then
			if action == "CollectIncome" then
				audio:Play("CoinCollect")
			elseif action == "Rebirth" then
				audio:Play("RebirthSuccess")
			elseif action == "ClaimIndexReward" then
				audio:Play("IndexClaim")
			elseif action == "ClaimReward" then
				audio:Play(if payload.Day == #rewards.BaseCoins then "DailyStreak" else "DailyClaim")
			elseif action == "BuyPass" then
				-- Existing protocol has no status enum; these exact server messages distinguish
				-- prompt acknowledgement, already-owned and durable purchase completion.
				if payload.Message == "Pass unlocked!" then
					audio:Play("PurchaseSuccess")
				elseif payload.Message == "Complete or close the Roblox purchase prompt." then
					audio:Play("PurchaseStart")
				end
			elseif action == "PlotColor" or action == "RefreshPasses" then
				audio:Play("Click")
			end
		end
		return true
	end
	return self
end
return Feedback
