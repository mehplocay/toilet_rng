local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local leaderboardStats = require(game.ReplicatedStorage.Shared.LeaderboardStats).new(Items)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local Rewards = require(game.ReplicatedStorage.Shared.Config.Rewards)
local upgrades =
	require(game.ReplicatedStorage.Shared.UpgradeRules).new(require(game.ReplicatedStorage.Shared.Config.Upgrades))
local index = require(game.ReplicatedStorage.Shared.IndexProgress).new(
	Items,
	require(game.ReplicatedStorage.Shared.Config.IndexRewards),
	upgrades
)
local Monetization = require(game.ReplicatedStorage.Shared.Config.Monetization)
local MonetizationRules = require(game.ReplicatedStorage.Shared.MonetizationRules)
local AudioSettings = require(game.ReplicatedStorage.Shared.AudioSettings)
local PresentationSettings = require(game.ReplicatedStorage.Shared.PresentationSettings)
local Audio = require(game.ReplicatedStorage.Shared.Config.Audio)
local income = require(game.ReplicatedStorage.Shared.IncomeAccrual).new(
	require(game.ReplicatedStorage.Shared.Config.Income),
	Items,
	upgrades
)

local DataService = {
	Profiles = {},
	Saving = {},
	Closing = {},
	NoPersistence = {},
	Loading = {},
	Sessions = {},
	LeaseExpires = {},
	Stopping = false,
}
local storeOk, store = pcall(DataStoreService.GetDataStore, DataStoreService, "ToiletRNG_v1")
if not storeOk then
	store = nil
	warn("DataStore unavailable; Studio players will use in-memory profiles.")
end
local LOCK_SECONDS = 180

local function integer(value, default)
	return if type(value) == "number"
			and value == value
			and value >= 0
			and value <= 9e15
		then math.floor(value)
		else default
end

function DataService.DefaultProfile()
	local settings = AudioSettings.Sanitize(nil, Audio.Defaults)
	settings.Sound, settings.SkipAnimation, settings.PlotColor = true, false, "Default"
	PresentationSettings.Apply(settings, PresentationSettings.Sanitize(nil))
	return {
		Version = 1,
		Upgrades = upgrades:Sanitize(nil),
		TutorialDone = false,
		Settings = settings,
		Coins = 0,
		LastClaimDay = 0,
		Streak = 0,
		RewardLuckExpires = 0,
		Inventory = {},
		Collection = {},
		Stamps = 0,
		IndexClaims = {},
		IndexCosmetics = {},
		ToiletTier = 1,
		DisplaySlots = 3,
		Displays = {},
		Income = income:Sanitize(nil),
		Stats = leaderboardStats:Sanitize(nil),
	}
end

local function sanitize(raw)
	local profile = DataService.DefaultProfile()
	if type(raw) ~= "table" then
		return profile
	end
	profile.TutorialDone = raw.TutorialDone == true
	MonetizationRules.RestoreSettings(profile.Settings, raw.Settings, Monetization)
	AudioSettings.Apply(profile.Settings, AudioSettings.Sanitize(raw.Settings, Audio.Defaults))
	PresentationSettings.Apply(profile.Settings, PresentationSettings.Sanitize(raw.Settings))
	profile.Coins = integer(raw.Coins, 0)
	profile.LastClaimDay = integer(raw.LastClaimDay, 0)
	profile.Streak = math.clamp(integer(raw.Streak, 0), 0, #Rewards.BaseCoins)
	if profile.LastClaimDay == 0 or profile.Streak == 0 then
		profile.LastClaimDay, profile.Streak = 0, 0
	end
	profile.RewardLuckExpires = integer(raw.RewardLuckExpires, 0)
	profile.ToiletTier = math.clamp(integer(raw.ToiletTier, 1), 1, #Toilets)
	profile.DisplaySlots = math.clamp(integer(raw.DisplaySlots, 3), 1, 100)
	upgrades:Restore(profile, raw.Upgrades)
	index:Sanitize(profile, raw)
	profile.Income = income:Sanitize(raw.Income, profile)
	for _, item in ipairs(Items) do
		profile.Inventory[item.Id] = integer(if type(raw.Inventory) == "table" then raw.Inventory[item.Id] else nil, 0)
		profile.Collection[item.Id] =
			integer(if type(raw.Collection) == "table" then raw.Collection[item.Id] else nil, 0)
	end
	profile.Stats = leaderboardStats:Sanitize(raw.Stats)
	-- Preserve display assignments only for known, owned items.
	local reserved = {}
	if type(raw.Displays) == "table" then
		for slot, id in pairs(raw.Displays) do
			local index = tonumber(slot)
			if
				index
				and index % 1 == 0
				and index >= 1
				and index <= profile.DisplaySlots
				and type(id) == "string"
				and (profile.Inventory[id] or 0) > (reserved[id] or 0)
				and not profile.Displays[tostring(index)]
			then
				profile.Displays[tostring(index)] = id
				reserved[id] = (reserved[id] or 0) + 1
			end
		end
	end
	return profile
end

local function retry(callback)
	for attempt = 1, 4 do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		warn("DataStore attempt failed:", result)
		if attempt < 4 then
			task.wait(2 ^ (attempt - 1))
		end
	end
	return false, nil
end

function DataService:Get(player)
	if self.Stopping or self.Closing[player] then
		return nil
	end
	if self.Profiles[player] and not self.NoPersistence[player] and os.time() >= (self.LeaseExpires[player] or 0) then
		self.Closing[player] = true
		player:Kick("Your data session expired. Please rejoin.")
		return nil
	end
	local profile = self.Profiles[player]
	if profile then
		-- Every gameplay mutation settles the previous display/tier first, without yielding.
		income:Settle(profile, os.time(), false)
	end
	return profile
end

local function finishLoad(self, player)
	self.Loading[player] = nil
	if self.Stopping or self.Closing[player] or player.Parent ~= Players then
		self:Close(player)
		return
	end
	if self.Loaded and self:Get(player) then
		self.Loaded(player)
	end
	if self.Stopping or self.Closing[player] or player.Parent ~= Players then
		self:Close(player)
	end
end

function DataService:Load(player)
	if
		self.Stopping
		or player.Parent ~= Players
		or self.Loading[player]
		or self.Profiles[player]
		or self.Closing[player]
	then
		return
	end
	self.Loading[player] = true
	-- A rejoin in this server must not share the departing Player's ownership token.
	local session = game.JobId .. ":" .. HttpService:GenerateGUID(false)
	if not store then
		if RunService:IsStudio() then
			self.Profiles[player] = DataService.DefaultProfile()
			self.NoPersistence[player] = true
			finishLoad(self, player)
			return
		end
		self.Loading[player], self.Closing[player] = nil, nil
		player:Kick("Your data could not be loaded safely. Please rejoin shortly.")
		return
	end
	local ok, record = retry(function()
		return store:UpdateAsync("Player_" .. player.UserId, function(old)
			if
				type(old) == "table"
				and type(old.Lock) == "table"
				and old.Lock.Session ~= session
				and type(old.Lock.Expires) == "number"
				and old.Lock.Expires > os.time()
			then
				return nil
			end
			local profile = sanitize(if type(old) == "table" then old.Data else nil)
			income:Settle(profile, os.time(), true)
			return {
				Data = profile,
				Lock = { Session = session, Expires = os.time() + LOCK_SECONDS },
			}
		end)
	end)
	if not ok or not record then
		if RunService:IsStudio() then
			self.Profiles[player] = DataService.DefaultProfile()
			self.NoPersistence[player] = true
			warn("DataStore unavailable or session lock held; using an in-memory Studio profile for " .. player.Name)
			finishLoad(self, player)
			return
		end
		self.Loading[player], self.Closing[player] = nil, nil
		player:Kick("Your data could not be loaded safely. Please rejoin shortly.")
		return
	end
	self.Profiles[player] = sanitize(record.Data)
	self.Sessions[player] = session
	self.LeaseExpires[player] = record.Lock.Expires
	finishLoad(self, player)
end

function DataService:Save(player, release)
	if self.NoPersistence[player] or not store and RunService:IsStudio() then
		self.NoPersistence[player] = true
		return true
	end
	if not store then
		self.Closing[player] = true
		player:Kick("Your data could not be saved safely. Please rejoin.")
		return false
	end
	while self.Saving[player] do
		task.wait(0.1)
	end
	local profile = self.Profiles[player]
	if not profile then
		return true
	end
	self.Saving[player] = true
	if not self.Closing[player] and os.time() < (self.LeaseExpires[player] or 0) then
		income:Settle(profile, os.time(), false)
	end
	-- Copy before UpdateAsync yields, so concurrent gameplay cannot mutate the snapshot.
	local snapshot = sanitize(profile)
	local session = self.Sessions[player]
	local ok, record = retry(function()
		return store:UpdateAsync("Player_" .. player.UserId, function(old)
			if
				not session
				or type(old) ~= "table"
				or type(old.Lock) ~= "table"
				or old.Lock.Session ~= session
				or integer(old.Lock.Expires, 0) <= os.time()
			then
				return nil
			end
			return {
				Data = snapshot,
				Lock = if release then nil else { Session = session, Expires = os.time() + LOCK_SECONDS },
			}
		end)
	end)
	self.Saving[player] = nil
	if not ok or not record then
		-- Stop mutations after failure rather than playing past the session lease.
		self.Closing[player] = true
		player:Kick("Your data could not be saved safely. Please rejoin.")
		return false
	end
	if not release then
		self.LeaseExpires[player] = record.Lock.Expires
	end
	return true
end

function DataService:Close(player)
	-- Freeze the departure timestamp before waiting behind an in-flight save.
	-- Otherwise backend latency could extend the offline cap after the player leaves.
	local profile = self.Profiles[player]
	if
		profile
		and not self.Closing[player]
		and (self.NoPersistence[player] or os.time() < (self.LeaseExpires[player] or 0))
	then
		income:Settle(profile, os.time(), false)
	end
	self.Closing[player] = true
	-- The load owns cleanup until its yielding acquisition has completed.
	if self.Loading[player] then
		return
	end
	self:Save(player, true)
	self.Profiles[player] = nil
	self.NoPersistence[player] = nil
	self.Sessions[player], self.LeaseExpires[player] = nil, nil
	self.Closing[player] = nil
end

function DataService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:Load(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:Close(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:Load(player)
		end)
	end
	task.spawn(function()
		while not self.Stopping do
			task.wait(60)
			for player in pairs(self.Profiles) do
				if not self.Stopping and not self.Closing[player] and not self.Saving[player] then
					task.spawn(function()
						self:Save(player, false)
					end)
				end
			end
		end
	end)
	game:BindToClose(function()
		self.Stopping = true
		local pending = 0
		for player in pairs(self.Profiles) do
			pending += 1
			task.spawn(function()
				self:Close(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while (pending > 0 or next(self.Loading) ~= nil or next(self.Saving) ~= nil) and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
