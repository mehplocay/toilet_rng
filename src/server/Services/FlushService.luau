local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local leaderboardStats = require(game.ReplicatedStorage.Shared.LeaderboardStats).new(Items)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local Monetization = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Rules = require(game.ReplicatedStorage.Shared.MonetizationRules)
local RollService = require(script.Parent.RollService)
local ServiceCoins = require(script.Parent.ServiceCoinService)
local Presentation = require(script.Parent.FlushPresentation)
local upgrades =
	require(game.ReplicatedStorage.Shared.UpgradeRules).new(require(game.ReplicatedStorage.Shared.Config.Upgrades))
local FlushService = {}
function FlushService.Start(data, limiter, remotes, sync, world, events, monetization, rewards)
	local nextFlush, nextAuto, random = {}, {}, Random.new()
	local presentationSequence = {}
	local function flush(player, automatic)
		if not automatic and not limiter:Allow(player, "Flush") then
			return
		end
		local profile, plot = data:Get(player), world.Assigned[player]
		local distance = monetization:Distance(player)
		if not profile or not plot or plot.Owner ~= player or not Rules.InRange(distance, Monetization) then
			return
		end
		local now = os.clock()
		if now < (nextFlush[player] or 0) or (automatic and now < (nextAuto[player] or 0)) then
			return
		end
		local toilet = Toilets[profile.ToiletTier]
		local cooldown = upgrades:Cooldown(profile, monetization:Cooldown(player, toilet.Cooldown))
		if automatic and not limiter:Allow(player, "Flush") then
			return
		end
		local luck =
			upgrades:Luck(profile, toilet.Luck, events:Multiplier(), monetization:Luck(player), rewards:Luck(profile))
		local item, probability = RollService.Roll(Items, Toilets, profile.ToiletTier, function()
			return random:NextNumber()
		end, luck)
		if
			profile.Stats.Flushes >= 9e15
			or (profile.RunFlushes or 0) >= 9e15
			or (profile.Inventory[item.Id] or 0) >= 9e15
			or (profile.Collection[item.Id] or 0) >= 9e15
		then
			return
		end
		local serviceCoins = ServiceCoins.Grant(profile, toilet, upgrades:Cash(profile))
		if not serviceCoins then
			return
		end
		-- Eligibility, currency, cooldown and item commit without yielding.
		nextFlush[player] = now + cooldown
		nextAuto[player] = now + upgrades:AutoInterval(profile, cooldown)
		leaderboardStats:Record(profile, item)
		-- Profile editing/reset must not rewind this session's reveal/event dedupe ID.
		presentationSequence[player] = math.max((presentationSequence[player] or 0) + 1, profile.Stats.Flushes)
		profile.RunFlushes = (profile.RunFlushes or 0) + 1
		profile.Inventory[item.Id] = (profile.Inventory[item.Id] or 0) + 1
		profile.Collection[item.Id] = (profile.Collection[item.Id] or 0) + 1
		Presentation.Publish(player, profile, item, {
			ItemId = item.Id,
			Rarity = item.Rarity,
			Chance = item.Chance,
			Probability = probability,
			FlushId = presentationSequence[player],
			Cooldown = cooldown,
			ServiceCoins = serviceCoins,
			LuckMultiplier = luck,
			LuckCapped = luck >= upgrades.Config.LuckCap,
		}, world, events, remotes, upgrades:Animation(cooldown))
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
	-- Server-only hook: admin service performs authorization before calling it.
	world.ClearFlushCooldown = function(player)
		nextFlush[player], nextAuto[player] = nil, nil
	end
	remotes.Flush.OnServerEvent:Connect(function(player, ...)
		if select("#", ...) == 0 then
			flush(player)
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		nextFlush[player] = nil
		nextAuto[player] = nil
		presentationSequence[player] = nil
	end)
end
return FlushService
