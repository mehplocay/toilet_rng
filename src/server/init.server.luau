local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local definitions = require(ReplicatedStorage.Shared.Config.Remotes)
local folder = Instance.new("Folder")
folder.Name = definitions.Folder
local remotes = {}
for _, key in ipairs({ "Flush", "Sell", "BuyToilet", "Display", "State", "Result" }) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = definitions[key]
	remote.Parent = folder
	remotes[key] = remote
end
local data = require(script.Services.DataService)
local limiter = require(script.Services.RateLimiter).new(definitions.Limits)
local world = require(script.World.WorldService)
local function sync(player)
	local profile = data:Get(player)
	if profile then
		world:Refresh(player, profile)
		remotes.State:FireClient(player, {
			Coins = profile.Coins,
			Inventory = profile.Inventory,
			Collection = profile.Collection,
			ToiletTier = profile.ToiletTier,
			Displays = profile.Displays,
			DisplaySlots = profile.DisplaySlots,
		})
	end
end
world:Start(data)
require(script.Services.FlushService).Start(data, limiter, remotes, sync, world)
require(script.Services.EconomyService).Start(data, limiter, remotes, sync)
require(script.Services.DisplayService).Start(data, limiter, remotes, sync)
remotes.State.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) == 0 and limiter:Allow(player, "State") then
		sync(player)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	limiter:Remove(player)
end)
data.Loaded = sync
data:Start()
folder.Parent = ReplicatedStorage
