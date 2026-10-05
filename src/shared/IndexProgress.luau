-- Pure discovery, migration and reward logic shared by the server and collection UI.
local Index = {}
Index.__index = Index
local MAX_INTEGER = 9e15

local function integer(value)
	return if type(value) == "number"
			and value == value
			and value >= 0
			and value <= MAX_INTEGER
		then math.floor(value)
		else 0
end

function Index.new(items, config)
	local self = setmetatable({ Items = items, Config = config, Rewards = {}, ById = {} }, Index)
	local totals, known = {}, {}
	for _, item in ipairs(items) do
		totals[item.Rarity] = (totals[item.Rarity] or 0) + 1
		known[item.Id] = true
	end
	local function add(reward)
		table.insert(self.Rewards, reward)
		self.ById[reward.Id] = reward
	end
	for _, rarity in ipairs(config.RarityOrder) do
		if (totals[rarity] or 0) > 0 then
			local stamps = config.RarityStamps[rarity]
			add({
				Id = "rarity:" .. rarity,
				Rarity = rarity,
				Required = totals[rarity],
				Stamps = stamps,
				Label = rarity .. " complete: " .. stamps .. " Stamps",
			})
		end
	end
	for _, milestone in ipairs(config.Milestones) do
		-- Future content does not appear in current completion targets.
		if milestone.Count <= #items then
			local reward = table.clone(milestone)
			reward.Id, reward.Required = "total:" .. milestone.Count, milestone.Count
			add(reward)
		end
	end
	local foundingShipped = true
	for _, id in ipairs(config.FoundingItems) do
		if not known[id] then
			foundingShipped = false
		end
	end
	if foundingShipped then
		local reward = table.clone(config.FoundingReward)
		reward.Id, reward.Required, reward.Items = "founding", #config.FoundingItems, config.FoundingItems
		add(reward)
	end
	return self
end

function Index:Progress(profile)
	local total, rarities = 0, {}
	for _, item in ipairs(self.Items) do
		local rarity = rarities[item.Rarity] or { Discovered = 0, Total = 0 }
		rarities[item.Rarity] = rarity
		rarity.Total += 1
		if integer((profile.Collection or {})[item.Id]) > 0 then
			total += 1
			rarity.Discovered += 1
		end
	end
	return total, rarities
end

function Index:Count(profile, reward)
	if reward.Items then
		local count = 0
		for _, id in ipairs(reward.Items) do
			if integer((profile.Collection or {})[id]) > 0 then
				count += 1
			end
		end
		return count
	end
	local total, rarities = self:Progress(profile)
	return if reward.Rarity then rarities[reward.Rarity].Discovered else total
end

function Index:Sanitize(profile, raw)
	raw = if type(raw) == "table" then raw else {}
	profile.Stamps = integer(raw.Stamps)
	profile.IndexClaims, profile.IndexCosmetics = {}, {}
	-- Retain stable IDs for future milestones too; content growth cannot revoke a claim.
	local rewards = {}
	for _, rarity in ipairs(self.Config.RarityOrder) do
		rewards["rarity:" .. rarity] = {}
	end
	for _, milestone in ipairs(self.Config.Milestones) do
		rewards["total:" .. milestone.Count] = milestone
	end
	rewards.founding = self.Config.FoundingReward
	for id, reward in pairs(rewards) do
		if type(raw.IndexClaims) == "table" and raw.IndexClaims[id] == true then
			profile.IndexClaims[id] = true
			if reward.Cosmetic then
				profile.IndexCosmetics[reward.Cosmetic] = true
			end
			if reward.DisplaySlots then
				profile.DisplaySlots = math.max(profile.DisplaySlots, reward.DisplaySlots)
			end
		end
	end
	-- Do not invent physical copies for previously sold discoveries or auto-claim rewards.
end

function Index:Claim(profile, id)
	local reward = if type(id) == "string" then self.ById[id] else nil
	if not reward or (profile.IndexClaims or {})[id] or self:Count(profile, reward) < reward.Required then
		return { Success = false, Message = "This index reward is unavailable or already claimed." }
	end
	local stamps = integer(profile.Stamps)
	if stamps + (reward.Stamps or 0) > MAX_INTEGER then
		return { Success = false, Message = "Stamp limit reached." }
	end
	-- No yields: the claim marker and grant are changed together, then saved together.
	profile.IndexClaims = profile.IndexClaims or {}
	profile.IndexCosmetics = profile.IndexCosmetics or {}
	profile.IndexClaims[id] = true
	profile.Stamps = stamps + (reward.Stamps or 0)
	if reward.DisplaySlots then
		profile.DisplaySlots = math.max(profile.DisplaySlots, reward.DisplaySlots)
	end
	if reward.Cosmetic then
		profile.IndexCosmetics[reward.Cosmetic] = true
	end
	return { Success = true, Message = "Claimed: " .. reward.Label, RewardId = id }
end

return Index
