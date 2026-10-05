local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local Monetization = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Rules = require(game.ReplicatedStorage.Shared.MonetizationRules)
local RollService = require(script.Parent.RollService)
local FlushService = {}
function FlushService.Start(data, limiter, remotes, sync, world, events, monetization, rewards)
	local nextFlush, random = {}, Random.new()
	local function flush(player, automatic)
		if not automatic and not limiter:Allow(player, "Flush") then
			return
		end
		local profile, plot = data:Get(player), world.Assigned[player]
		local distance = monetization:Distance(player)
		if not profile or not plot or not Rules.InRange(distance, Monetization) then
			return
		end
		local now = os.clock()
		if now < (nextFlush[player] or 0) or (automatic and not limiter:Allow(player, "Flush")) then
			return
		end
		local toilet = Toilets[profile.ToiletTier]
		local cooldown = monetization:Cooldown(player, toilet.Cooldown)
		if not Rules.TryFlush(nextFlush, player, now, distance, cooldown, Monetization) then
			return
		end
		local item = RollService.Roll(Items, Toilets, profile.ToiletTier, function()
			return random:NextNumber()
		end, toilet.Luck * events:Multiplier() * monetization:Luck(player) * rewards:Luck(profile))
		profile.Stats.Flushes += 1
		profile.Inventory[item.Id] = (profile.Inventory[item.Id] or 0) + 1
		profile.Collection[item.Id] = (profile.Collection[item.Id] or 0) + 1
		events:Trigger(player, item, profile.Stats.Flushes)
		world:Animate(player, item, profile.Settings.SkipAnimation)
		remotes.Result:FireClient(player, "Flush", { ItemId = item.Id, Cooldown = cooldown })
		sync(player)
	end
	task.spawn(function()
		while not data.Stopping do
			task.wait(Monetization.AutoTick)
			events:Drain()
			for player, enabled in pairs(monetization.Auto) do
				if enabled then
					if monetization:CanAuto(player) then
						flush(player, true)
					else
						monetization:StopAuto(player)
					end
				end
			end
		end
	end)
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
