-- A central collection pedestal: bounded primitive geometry, independent of item builders.
local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local Config = require(game.ReplicatedStorage.Shared.Config.Income)
local V = require(game.ReplicatedStorage.Shared.Config.Visuals).Palette
local IncomeDisplay = {}
function IncomeDisplay.Refresh(plot, player, pending)
	if not plot.IncomePoint or not plot.IncomePoint.Parent then
		local offset = Config.CollectOffset
		local cf = plot.CFrame * CFrame.new(offset.X, offset.Y, offset.Z)
		local point = P.Cylinder(plot.Displays, "IncomeCollect", 1, 0.25, cf, V.Navy)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText, prompt.ObjectText = "Collect", "Display income"
		prompt.MaxActivationDistance = Config.CollectRange
		prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.F, Enum.KeyCode.ButtonY
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("IncomeOwnerUserId", player.UserId)
		prompt:SetAttribute("OwnerUserId", player.UserId)
		prompt.Parent = point
		plot.IncomePoint, plot.IncomePrompt, plot.IncomeCoins = point, prompt, {}
		for level = 1, 3 do
			local coin = P.Cylinder(
				plot.Displays,
				"PendingCoin",
				0.6,
				0.15,
				cf * CFrame.new((level % 2) * 0.14, 0.2 + level * 0.17, 0),
				V.Gold
			)
			plot.IncomeCoins[level] = coin
		end
	end
	plot.IncomePrompt.ObjectText = "Display income: " .. pending .. " coins"
	for level, coin in ipairs(plot.IncomeCoins) do
		coin.Transparency = if pending >= ({ 1, 10, 100 })[level] then 0 else 1
	end
end
return IncomeDisplay
