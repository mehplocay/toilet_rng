-- Each pad targets its saved slot; the central jar drains the complete ledger.
local Kit = require(script.Parent.Kit)
local Config = require(game.ReplicatedStorage.Shared.Config.Income)
local Layout = require(game.ReplicatedStorage.Shared.Config.MapLayout)
local IncomeDisplay = {}
function IncomeDisplay.Refresh(plot, player, pending)
	if not plot.IncomePoint or not plot.IncomePoint.Parent then
		local cf = plot.LayoutCFrame * CFrame.new(Layout.CollectPosition)
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
			local slot = target:GetAttribute("CollectSlot")
			if slot and not (plot.CollectSlots or {})[slot] then
				continue
			end
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "IncomePrompt"
			prompt.ActionText = if slot then "Collect" else "Collect All"
			prompt.ObjectText = if slot then "Display " .. slot .. " income" else "All display income"
			prompt.MaxActivationDistance = if slot then Config.PadRange else Config.CollectRange
			prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.F, Enum.KeyCode.ButtonY
			prompt.RequiresLineOfSight, prompt.HoldDuration, prompt.Enabled = false, 0, true
			prompt:SetAttribute("CollectSlot", slot)
			prompt:SetAttribute("IncomeOwnerUserId", player.UserId)
			prompt:SetAttribute("OwnerUserId", player.UserId)
			prompt.Parent = target
			if target == point then
				plot.IncomePrompt = prompt
			end
		end
		jar:SetAttribute("IncomeJar", true)
		local glow = Instance.new("PointLight")
		glow.Name, glow.Color, glow.Range, glow.Brightness, glow.Enabled =
			"IncomeGlow", Color3.fromRGB(134, 255, 128), 9, 0.3, false
		glow:SetAttribute("VisualIdle", true)
		glow:SetAttribute("IncomeGlow", true)
		glow:SetAttribute("IncomeReady", false)
		glow.Parent = point
	end
	plot.IncomePrompt.ObjectText = "All display income: " .. pending .. " coins"
	plot.IncomeLabel.Text = "COLLECT ALL\n$" .. pending
	for _, point in ipairs(plot.CollectPoints) do
		local slot = point:GetAttribute("CollectSlot")
		local ledger = plot.Profile and plot.Profile.Income
		local coins = if slot
			then math.floor(((ledger and ledger.Pending[tostring(slot)]) or 0) / Config.UnitsPerCoin)
			else pending
		local glow = point:FindFirstChild("IncomeGlow")
		if glow then
			glow:SetAttribute("IncomeReady", coins >= Config.GlowThreshold)
		end
		local prompt = point:FindFirstChild("IncomePrompt")
		if prompt and slot then
			prompt.ObjectText = "Display " .. slot .. ": $" .. coins
		end
	end
end
return IncomeDisplay
