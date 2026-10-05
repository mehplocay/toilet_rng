local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false
local definitions = require(ReplicatedStorage.Shared.Config.Remotes)
local AudioSettings = require(ReplicatedStorage.Shared.AudioSettings)
local folder = Instance.new("Folder")
folder.Name = definitions.Folder
local remotes = {}
for _, key in ipairs({
	"Flush",
	"PresentationSettings",
	"DropAnnouncement",
	"Sell",
	"BuyToilet",
	"Display",
	"CollectIncome",
	"IncomePending",
	"State",
	"Result",
	"Event",
	"ServerLuck",
	"Settings",
	"AutoFlush",
	"AnimationSkip",
	"PlotColor",
	"BuyPass",
	"RefreshPasses",
	"DevGrant",
	"TutorialDone",
	"ClaimReward",
	"ClaimIndexReward",
}) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = definitions[key]
	remote.Parent = folder
	remotes[key] = remote
end
local data = require(script.Services.DataService)
local income = require(ReplicatedStorage.Shared.IncomeAccrual).new(
	require(ReplicatedStorage.Shared.Config.Income),
	require(ReplicatedStorage.Shared.Config.Items)
)
local index = require(ReplicatedStorage.Shared.IndexProgress).new(
	require(ReplicatedStorage.Shared.Config.Items),
	require(ReplicatedStorage.Shared.Config.IndexRewards)
)
local limiter = require(script.Services.RateLimiter).new(definitions.Limits)
local world = require(script.World.WorldService)
local monetization = require(script.Services.MonetizationService)
local rewards = require(script.Services.RewardService).new(
	require(ReplicatedStorage.Shared.Config.Rewards),
	require(ReplicatedStorage.Shared.RewardSchedule),
	os.time
)
local events = require(script.Services.EventService).new(require(ReplicatedStorage.Shared.Config.Events), function()
	return workspace:GetServerTimeNow()
end, function(payload)
	remotes.Event:FireAllClients(payload)
end, function(expires)
	remotes.ServerLuck:FireAllClients(expires)
end)
local function sync(player)
	local profile = data:Get(player)
	if profile then
		world:Refresh(player, profile)
		world:RefreshIncome(player, income:PendingCoins(profile))
		monetization:Apply(player)
		remotes.State:FireClient(player, {
			Coins = profile.Coins,
			PendingCoins = income:PendingCoins(profile),
			TutorialDone = profile.TutorialDone,
			LastClaimDay = profile.LastClaimDay,
			Streak = profile.Streak,
			RewardLuckExpires = profile.RewardLuckExpires,
			Settings = profile.Settings,
			OwnedPasses = monetization.Owned[player] or {},
			AutoFlush = monetization.Auto[player] == true,
			LifetimeFlushes = profile.Stats.Flushes,
			ServerLuckExpires = events.Expires,
			Inventory = profile.Inventory,
			Collection = profile.Collection,
			Stamps = profile.Stamps,
			IndexClaims = profile.IndexClaims,
			IndexCosmetics = profile.IndexCosmetics,
			ToiletTier = profile.ToiletTier,
			Displays = profile.Displays,
			DisplaySlots = profile.DisplaySlots,
		})
	end
end
world:Start(data)
require(script.Services.FlushService).Start(data, limiter, remotes, sync, world, events, monetization, rewards)
require(script.Services.PresentationService).Start(data, limiter, remotes, sync, events)
rewards:Start(data, limiter, remotes, sync)
require(script.Services.IndexService).Start(index, data, limiter, remotes, sync)
require(script.Services.EconomyService).Start(data, limiter, remotes, sync)
require(script.Services.DisplayService).Start(data, limiter, remotes, sync)
require(script.Services.DevGrantService).Start(data, limiter, remotes, sync)
remotes.State.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) == 0 and limiter:Allow(player, "State") then
		sync(player)
	end
end)
-- This preference dismisses onboarding only; it grants no gameplay progression.
remotes.TutorialDone.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 0 or not limiter:Allow(player, "TutorialDone") then
		return
	end
	local profile = data:Get(player)
	if profile then
		profile.TutorialDone = true
		sync(player)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	limiter:Remove(player)
end)
monetization:Start(limiter, remotes, sync, data, world)
require(script.Services.IncomeService).Start(data, limiter, remotes, sync, world)
remotes.Settings.OnServerEvent:Connect(function(player, sound, ...)
	if select("#", ...) ~= 0 or not AudioSettings.ValidRequest(sound) or not limiter:Allow(player, "Settings") then
		return
	end
	local profile = data:Get(player)
	if profile then
		AudioSettings.Apply(profile.Settings, sound)
		sync(player)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	events:Remove(player)
end)
data.Loaded = function(player)
	sync(player)
	monetization:Load(player)
	sync(player)
end
data:Start()
folder.Parent = ReplicatedStorage
