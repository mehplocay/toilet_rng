local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Income)
local accounting = require(Shared.IncomeAccrual).new(
	Config,
	require(Shared.Config.Items),
	require(Shared.UpgradeRules).new(require(Shared.Config.Upgrades))
)
local IncomeService = {}
function IncomeService.Start(data, limiter, remotes, sync, world)
	local function collect(player, slot, touching)
		if slot ~= nil and (type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > Config.MaxSlots) then
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
		local point = if slot then (plot.CollectSlots or {})[slot] else plot.IncomePoint
		if not point or not point.Parent then
			return
		end
		local distance = (root.Position - point.Position).Magnitude
		local range = if touching then Config.TouchRange elseif slot then Config.PadRange else Config.CollectRange
		if distance ~= distance or distance < 0 or distance > range then
			return
		end
		-- Get settles using server time only after verifying the acknowledged session lease.
		local profile = data:Get(player)
		if not profile then
			return
		end
		if data.Saving[player] then
			if not touching and limiter:Allow(player, "CollectIncome") then
				remotes.Result:FireClient(
					player,
					"CollectIncome",
					{ Success = false, Message = "Saving your last action. Please try collecting again." }
				)
			end
			return -- Never queue unbounded save waiters behind a slow backend.
		end
		if slot and slot > profile.DisplaySlots then
			return
		end
		-- Limb contacts on empty pads must not consume the owner's input budget.
		if touching and (profile.Income.Pending[tostring(slot)] or 0) < Config.UnitsPerCoin then
			return
		end
		if not limiter:Allow(player, "CollectIncome") then
			return
		end
		local available = if slot
			then accounting:WholeCoins(profile.Income.Pending[tostring(slot)] or 0)
			else accounting:PendingCoins(profile)
		if available > 0 and not limiter:Allow(player, "CollectIncomeSave") then
			remotes.Result:FireClient(
				player,
				"CollectIncome",
				{ Success = false, Message = "Collection is cooling down. Try again in a few seconds." }
			)
			return
		end
		local coins = accounting:Collect(profile, slot)
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
			remotes.Result:FireClient(player, "CollectIncome", { Success = true, Coins = coins, Slot = slot })
		end
	end
	world.CollectIncome = collect
	remotes.CollectIncome.OnServerEvent:Connect(function(player, ...)
		local count, slot = select("#", ...), ...
		if count > 1 or (count == 1 and slot == nil) then
			return
		end
		collect(player, slot, false)
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
