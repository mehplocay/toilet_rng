local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local definitions = require(ReplicatedStorage.Shared.Config.Remotes)
local folder = Instance.new("Folder")
folder.Name = definitions.Folder
local remotes = {}
for _, key in ipairs({
	"Flush",
	"Sell",
	"BuyToilet",
	"Display",
	"State",
	"Result",
	"Event",
	"ServerLuck",
	"Settings",
	"AutoFlush",
	"DevGrant",
	"TutorialDone",
	"ClaimReward",
}) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = definitions[key]
	remote.Parent = folder
	remotes[key] = remote
end
local data = require(script.Services.DataService)
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
		remotes.State:FireClient(player, {
			Coins = profile.Coins,
			TutorialDone = profile.TutorialDone,
			LastClaimDay = profile.LastClaimDay,
			Streak = profile.Streak,
			RewardLuckExpires = profile.RewardLuckExpires,
			Settings = profile.Settings,
			OwnedPasses = monetization.Owned[player] or {},
			AutoFlush = monetization.Auto[player] == true,
			ServerLuckExpires = events.Expires,
			Inventory = profile.Inventory,
			Collection = profile.Collection,
			ToiletTier = profile.ToiletTier,
			Displays = profile.Displays,
			DisplaySlots = profile.DisplaySlots,
		})
	end
end
world:Start(data)
require(script.Services.FlushService).Start(data, limiter, remotes, sync, world, events, monetization, rewards)
rewards:Start(data, limiter, remotes, sync)
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
monetization:Start(limiter, remotes, sync)
remotes.Settings.OnServerEvent:Connect(function(player, sound, ...)
	if select("#", ...) ~= 0 or type(sound) ~= "boolean" or not limiter:Allow(player, "Settings") then
		return
	end
	local profile = data:Get(player)
	if profile then
		profile.Settings.Sound = sound
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
