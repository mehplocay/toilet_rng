local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Income)
local accounting = require(Shared.IncomeAccrual).new(Config, require(Shared.Config.Items))
local IncomeService = {}
function IncomeService.Start(data, limiter, remotes, sync, world)
	remotes.CollectIncome.OnServerEvent:Connect(function(player, ...)
		if not limiter:Allow(player, "CollectIncome") or select("#", ...) ~= 0 then
			return
		end
		local plot = world.Assigned[player]
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
		if
			not plot
			or plot.Owner ~= player
			or not plot.IncomePoint
			or not root
			or not humanoid
			or not (humanoid.Health > 0)
		then
			return
		end
		local distance = (root.Position - plot.IncomePoint.Position).Magnitude
		if distance ~= distance or distance < 0 or distance > Config.CollectRange then
			return
		end
		-- Get settles using server time only after verifying the acknowledged session lease.
		local profile = data:Get(player)
		if not profile or data.Saving[player] then
			return -- Never queue unbounded save waiters behind a slow backend.
		end
		local coins = accounting:Collect(profile)
		if coins == 0 then
			remotes.Result:FireClient(
				player,
				"CollectIncome",
				{ Success = false, Message = "No whole coins to collect, or your wallet is full." }
			)
			return
		end
		-- Debit, credit and timestamp are in one immutable profile snapshot before Save yields.
		if data:Save(player, false) and data:Get(player) == profile then
			sync(player)
			remotes.Result:FireClient(player, "CollectIncome", { Success = true, Coins = coins })
		end
	end)
	task.spawn(function()
		while not data.Stopping do
			task.wait(Config.RefreshSeconds)
			for player in pairs(data.Profiles) do
				local profile = data:Get(player)
				if profile then
					local pending = accounting:PendingCoins(profile)
					world:RefreshIncome(player, pending)
					remotes.IncomePending:FireClient(player, pending)
				end
			end
		end
	end)
end
return IncomeService
