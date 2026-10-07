local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false
require(script.Services.IconResolver).Start()
local definitions = require(ReplicatedStorage.Shared.Config.Remotes)
local AudioSettings = require(ReplicatedStorage.Shared.AudioSettings)
local TutorialProgress = require(ReplicatedStorage.Shared.TutorialProgress)
local folder = Instance.new("Folder")
folder.Name = definitions.Folder
local remotes = {}
for _, key in ipairs({
	"CheckGroup",
	"PromptInvite",
	"Flush",
	"PresentationSettings",
	"DropAnnouncement",
	"Sell",
	"BuyToilet",
	"BuyUpgrade",
	"Rebirth",
	"Display",
	"CollectIncome",
	"IncomePending",
	"State",
	"Result",
	"Event",
	"ServerLuck",
	"Settings",
	"AutoFlush",
	"PlayerActivity",
	"CollectOffline",
	"AnimationSkip",
	"PlotColor",
	"BuyPass",
	"BuyProduct",
	"ClaimVIP",
	"LuckyFlush",
	"RefreshPasses",
	"DevGrant",
	"TutorialDone",
	"TutorialReplay",
	"ClaimReward",
	"ClaimIndexReward",
}) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = definitions[key]
	remote.Parent = folder
	remotes[key] = remote
end
local data = require(script.Services.DataService)
local upgrades = require(ReplicatedStorage.Shared.UpgradeRules).new(require(ReplicatedStorage.Shared.Config.Upgrades))
local Toilets = require(ReplicatedStorage.Shared.Config.Toilets)
local IncomeConfig = require(ReplicatedStorage.Shared.Config.Income)
local income = require(ReplicatedStorage.Shared.IncomeAccrual).new(
	require(ReplicatedStorage.Shared.Config.Income),
	require(ReplicatedStorage.Shared.Config.Items),
	upgrades
)
local index = require(ReplicatedStorage.Shared.IndexProgress).new(
	require(ReplicatedStorage.Shared.Config.Items),
	require(ReplicatedStorage.Shared.Config.IndexRewards),
	upgrades
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
		monetization:Apply(player)
		world:Refresh(player, profile)
		world:RefreshIncome(player, income:PendingCoins(profile))
		remotes.State:FireClient(player, {
			Social = require(ReplicatedStorage.Shared.SocialBoostRules).Snapshot(profile),
			Commerce = monetization.Commerce and monetization.Commerce:Snapshot(profile, player),
			RebirthLevel = profile.RebirthLevel,
			RunFlushes = profile.RunFlushes,
			ProtectedInventory = profile.ProtectedInventory,
			Upgrades = profile.Upgrades,
			UpgradeStats = upgrades:Snapshot(
				profile,
				upgrades:Cooldown(profile, monetization:Cooldown(player, Toilets[profile.ToiletTier].Cooldown)),
				upgrades:Luck(
					profile,
					Toilets[profile.ToiletTier].Luck,
					events:Multiplier(),
					monetization:Luck(player),
					rewards:Luck(profile)
				),
				IncomeConfig.OfflineMinutes
			),
			Coins = profile.Coins,
			PendingCoins = income:PendingCoins(profile),
			OfflineIncome = income:OfflineSnapshot(profile),
			TutorialDone = profile.TutorialDone,
			TutorialStep = profile.TutorialStep,
			TutorialRun = profile.TutorialRun,
			LastClaimDay = profile.LastClaimDay,
			Streak = profile.Streak,
			RewardLuckExpires = profile.RewardLuckExpires,
			Settings = profile.Settings,
			OwnedPasses = monetization:EffectiveOwned(player),
			AutoFlush = monetization.Auto[player] == true,
			AutoStatus = monetization:AutoStatus(player),
			LifetimeFlushes = profile.Stats.Flushes,
			ServerLuckExpires = events.Expires,
			Inventory = profile.Inventory,
			Collection = profile.Collection,
			Stamps = profile.Stamps,
			IndexClaims = profile.IndexClaims,
			IndexCosmetics = monetization:EffectiveCosmetics(player, profile.IndexCosmetics),
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
require(script.Services.UpgradeService).Start(data, limiter, remotes, sync)
require(script.Services.RebirthService).Start(data, limiter, remotes, sync, events)
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
		TutorialProgress.Dismiss(profile)
		sync(player)
	end
end)
remotes.TutorialReplay.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 0 or not limiter:Allow(player, "TutorialReplay") then
		return
	end
	local profile = data:Get(player)
	if profile then
		TutorialProgress.Reset(profile)
		sync(player)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	limiter:Remove(player)
end)
monetization:Start(limiter, remotes, sync, data, world)
require(script.Services.PathBoostService).Start(data)
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
local admin = require(script.Services.AdminService).Start(data, sync, world, events, remotes)
local social = require(script.Services.SocialBoostService).Start(data, limiter, remotes, sync)
data.Loaded = function(player)
	social:Load(player)
	sync(player)
	monetization:Load(player)
	sync(player)
	task.spawn(function()
		admin:Grant(player)
	end)
end
data:Start()
folder.Parent = ReplicatedStorage
