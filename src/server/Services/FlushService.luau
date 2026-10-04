local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local RollService = require(script.Parent.RollService)
local FlushService = {}
function FlushService.Start(data, limiter, remotes, sync, world)
	local nextFlush, random = {}, Random.new()
	local function flush(player)
		if not limiter:Allow(player, "Flush") then
			return
		end
		local profile, plot = data:Get(player), world.Assigned[player]
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not profile or not plot or not root or (root.Position - plot.CFrame.Position).Magnitude > 14 then
			return
		end
		local now = os.clock()
		if now < (nextFlush[player] or 0) then
			return
		end
		local toilet = Toilets[profile.ToiletTier]
		nextFlush[player] = now + toilet.Cooldown
		local item = RollService.Roll(Items, Toilets, profile.ToiletTier, function()
			return random:NextNumber()
		end)
		profile.Stats.Flushes += 1
		profile.Inventory[item.Id] = (profile.Inventory[item.Id] or 0) + 1
		profile.Collection[item.Id] = (profile.Collection[item.Id] or 0) + 1
		world:Animate(player, item)
		remotes.Result:FireClient(player, "Flush", { ItemId = item.Id, Cooldown = toilet.Cooldown })
		sync(player)
	end
	world.Flush = flush
	remotes.Flush.OnServerEvent:Connect(function(player, ...)
		if select("#", ...) == 0 then
			flush(player)
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		nextFlush[player] = nil
	end)
end
return FlushService
