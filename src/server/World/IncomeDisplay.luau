-- Existing aggregate-income remote is shared by the jar and the visible green pads.
local Kit = require(script.Parent.Kit)
local Config = require(game.ReplicatedStorage.Shared.Config.Income)
local IncomeDisplay = {}
function IncomeDisplay.Refresh(plot, player, pending)
	if not plot.IncomePoint or not plot.IncomePoint.Parent then
		local offset = Config.CollectOffset
		local cf = plot.CFrame * CFrame.new(offset.X, offset.Y - 1, offset.Z)
		local jar = Kit.Place(plot.Displays, { Asset = "CollectCoinJar", Position = Vector3.new(), Scale = 0.8 }, cf)
		local point = Kit.Proxy(plot.Displays, "IncomeCollect", cf * CFrame.new(0, 2, 0), Vector3.new(1, 1, 1), false)
		plot.IncomePoint, plot.IncomeCoins = point, {}
		plot.CollectPoints = plot.CollectPoints or {}
		table.insert(plot.CollectPoints, point)
		plot.IncomeLabel = Kit.Label(
			plot.Displays,
			"PendingIncome",
			cf * CFrame.new(0, 7, 0),
			Vector3.new(9, 3, 0.1),
			"",
			Color3.fromRGB(134, 255, 128),
			true,
			70
		)
		for _, target in ipairs(plot.CollectPoints) do
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText, prompt.ObjectText = "Collect", "All display income"
			prompt.MaxActivationDistance = Config.CollectRange
			prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.F, Enum.KeyCode.ButtonY
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("IncomeOwnerUserId", player.UserId)
			prompt:SetAttribute("OwnerUserId", player.UserId)
			prompt.Parent = target
			if target == point then
				plot.IncomePrompt = prompt
			end
		end
		jar:SetAttribute("IncomeJar", true)
	end
	plot.IncomePrompt.ObjectText = "All display income: " .. pending .. " coins"
	plot.IncomeLabel.Text = "COLLECT ALL\n$" .. pending
end
return IncomeDisplay
