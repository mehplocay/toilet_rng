local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local definitions = require(ReplicatedStorage.Shared.Config.Remotes)
local folder = Instance.new("Folder")
folder.Name = definitions.Folder
local remotes = {}
for _, key in ipairs({ "Flush", "Sell", "BuyToilet", "Result" }) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = definitions[key]
	remote.Parent = folder
	remotes[key] = remote
end
local data = require(script.Services.DataService)
local limiter = require(script.Services.RateLimiter).new(definitions.Limits)
require(script.Services.FlushService).Start(data, limiter, remotes)
require(script.Services.EconomyService).Start(data, limiter, remotes)
Players.PlayerRemoving:Connect(function(player)
	limiter:Remove(player)
end)
data:Start()
folder.Parent = ReplicatedStorage
