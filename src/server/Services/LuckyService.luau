-- Policy eligibility and exact odds are server-owned. Missing/expired lookups fail closed.
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Monetization)
local Items, Toilets = require(Shared.Config.Items), require(Shared.Config.Toilets)
local Roll = require(script.Parent.RollService)
local Upgrades = require(Shared.UpgradeRules).new(require(Shared.Config.Upgrades))
local Players = game:GetService("Players")
local Policy = game:GetService("PolicyService")
local Lucky = { Policies = {}, Armed = {}, Loading = {} }
function Lucky:Allowed(player)
	local entry = self.Policies[player]
	return player ~= nil and player.Parent == Players and entry ~= nil and entry.Allowed and os.clock() < entry.Expires
end
function Lucky:Refresh(player)
	if self.Loading[player] then
		return
	end
	self.Loading[player] = true
	-- Keep an unexpired verified result while refreshing; Allowed still checks its deadline.
	local ok, result = pcall(Policy.GetPolicyInfoForPlayerAsync, Policy, player)
	self.Loading[player] = nil
	if player.Parent ~= Players then
		return
	end
	self.Policies[player] = {
		Allowed = ok and type(result) == "table" and result.ArePaidRandomItemsRestricted == false,
		Expires = os.clock() + Config.PolicySeconds,
	}
	if not self:Allowed(player) then
		self.Armed[player] = nil
	end
	if self.Sync then
		self.Sync(player)
	end
end
function Lucky:Odds(profile)
	local base = Upgrades:Luck(
		profile,
		Toilets[profile.ToiletTier].Luck,
		self.Events:Multiplier(),
		1,
		self.Rewards:Luck(profile)
	)
	local boosted = math.min(Config.LuckyLuckCap, Upgrades.Config.LuckCap, base * Config.LuckyMultiplier)
	local normal = Roll.Distribution(Items, Toilets, profile.ToiletTier, base)
	local enhanced = Roll.Distribution(Items, Toilets, profile.ToiletTier, boosted)
	local rows, rarities = {}, {}
	for i, entry in ipairs(normal) do
		local item = entry.Item
		rows[i] = {
			Id = item.Id,
			Name = item.Name,
			Rarity = item.Rarity,
			BaseChance = item.Chance,
			Fallback = item.Id == "Poop",
			Normal = entry.Probability,
			Boosted = enhanced[i].Probability,
		}
		local rarity = rarities[item.Rarity] or { Normal = 0, Boosted = 0 }
		rarity.Normal += entry.Probability
		rarity.Boosted += enhanced[i].Probability
		rarities[item.Rarity] = rarity
	end
	return {
		Token = string.format("%d:%.17g:%.17g", profile.ToiletTier, base, boosted),
		BaseLuck = base,
		Luck = boosted,
		Items = rows,
		Rarities = rarities,
	}
end
function Lucky:Snapshot(player, profile)
	local allowed = self:Allowed(player)
	return {
		Allowed = allowed == true,
		PolicyRemaining = if allowed then math.max(0, self.Policies[player].Expires - os.clock()) else 0,
		Count = profile.Monetization.LuckyFlushes,
		Odds = if allowed then self:Odds(profile) else nil,
		Armed = self.Armed[player] ~= nil,
	}
end
function Lucky:Start(data, limiter, remotes, sync, events, rewards)
	self.Events, self.Rewards = events, rewards
	self.Sync = sync
	remotes.LuckyFlush.OnServerEvent:Connect(function(player, token, ...)
		if
			select("#", ...) ~= 0
			or type(token) ~= "string"
			or #token > 100
			or not limiter:Allow(player, "LuckyFlush")
		then
			return
		end
		local profile = data:Get(player)
		if not profile or not self:Allowed(player) or profile.Monetization.LuckyFlushes <= 0 then
			return
		end
		local odds = self:Odds(profile)
		if token == odds.Token then
			self.Armed[player] = token
		end
		sync(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.Policies[player], self.Armed[player], self.Loading[player] = nil, nil, nil
	end)
end
function Lucky:StartRefresh(data)
	task.spawn(function()
		while not data.Stopping do
			task.wait(Config.PolicySeconds / 2)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(function()
					self:Refresh(player)
				end)
			end
		end
	end)
end
return Lucky
