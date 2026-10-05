local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local Rewards = require(game.ReplicatedStorage.Shared.Config.Rewards)

local DataService = { Profiles = {}, Saving = {}, Closing = {}, NoPersistence = {}, Stopping = false }
local storeOk, store = pcall(DataStoreService.GetDataStore, DataStoreService, "ToiletRNG_v1")
if not storeOk then
	store = nil
	warn("DataStore unavailable; Studio players will use in-memory profiles.")
end
local session = game.JobId .. ":" .. HttpService:GenerateGUID(false)
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
	return {
		Version = 1,
		TutorialDone = false,
		Settings = { Sound = true },
		Coins = 0,
		LastClaimDay = 0,
		Streak = 0,
		RewardLuckExpires = 0,
		Inventory = {},
		Collection = {},
		ToiletTier = 1,
		DisplaySlots = 3,
		Displays = {},
		Stats = { Flushes = 0, Earned = 0 },
	}
end

local function sanitize(raw)
	local profile = DataService.DefaultProfile()
	if type(raw) ~= "table" then
		return profile
	end
	profile.TutorialDone = raw.TutorialDone == true
	if type(raw.Settings) == "table" and type(raw.Settings.Sound) == "boolean" then
		profile.Settings.Sound = raw.Settings.Sound
	end
	profile.Coins = integer(raw.Coins, 0)
	profile.LastClaimDay = integer(raw.LastClaimDay, 0)
	profile.Streak = math.clamp(integer(raw.Streak, 0), 0, #Rewards.BaseCoins)
	if profile.LastClaimDay == 0 or profile.Streak == 0 then
		profile.LastClaimDay, profile.Streak = 0, 0
	end
	profile.RewardLuckExpires = integer(raw.RewardLuckExpires, 0)
	profile.ToiletTier = math.clamp(integer(raw.ToiletTier, 1), 1, #Toilets)
	profile.DisplaySlots = math.clamp(integer(raw.DisplaySlots, 3), 1, 100)
	for _, item in ipairs(Items) do
		profile.Inventory[item.Id] = integer(if type(raw.Inventory) == "table" then raw.Inventory[item.Id] else nil, 0)
		profile.Collection[item.Id] =
			integer(if type(raw.Collection) == "table" then raw.Collection[item.Id] else nil, 0)
	end
	if type(raw.Stats) == "table" then
		profile.Stats.Flushes = integer(raw.Stats.Flushes, 0)
		profile.Stats.Earned = integer(raw.Stats.Earned, 0)
	end
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
	return self.Profiles[player]
end

function DataService:Load(player)
	if not store then
		if RunService:IsStudio() then
			self.Profiles[player] = DataService.DefaultProfile()
			self.NoPersistence[player] = true
			if self.Loaded and player.Parent == Players and not self.Stopping then
				self.Loaded(player)
			end
			if self.Stopping or player.Parent ~= Players then
				self:Close(player)
			end
			return
		end
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
			return {
				Data = sanitize(if type(old) == "table" then old.Data else nil),
				Lock = { Session = session, Expires = os.time() + LOCK_SECONDS },
			}
		end)
	end)
	if not ok or not record then
		if RunService:IsStudio() then
			self.Profiles[player] = DataService.DefaultProfile()
			self.NoPersistence[player] = true
			warn("DataStore unavailable or session lock held; using an in-memory Studio profile for " .. player.Name)
			if self.Loaded and player.Parent == Players and not self.Stopping then
				self.Loaded(player)
			end
			if self.Stopping or player.Parent ~= Players then
				self:Close(player)
			end
			return
		end
		player:Kick("Your data could not be loaded safely. Please rejoin shortly.")
		return
	end
	self.Profiles[player] = sanitize(record.Data)
	if self.Loaded and player.Parent == Players and not self.Stopping then
		self.Loaded(player)
	end
	if self.Stopping or player.Parent ~= Players then
		self:Close(player)
	end
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
	-- Copy before UpdateAsync yields, so concurrent gameplay cannot mutate the snapshot.
	local snapshot = sanitize(profile)
	local ok, record = retry(function()
		return store:UpdateAsync("Player_" .. player.UserId, function(old)
			if type(old) ~= "table" or type(old.Lock) ~= "table" or old.Lock.Session ~= session then
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
	return true
end

function DataService:Close(player)
	self.Closing[player] = true
	self:Save(player, true)
	self.Profiles[player] = nil
	self.NoPersistence[player] = nil
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
				if not self.Stopping and not self.Closing[player] then
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
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
