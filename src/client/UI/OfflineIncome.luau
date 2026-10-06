local C = require(script.Parent.Components)
local Run = game:GetService("RunService")
local OfflineIncome = {}
function OfflineIncome.Create(root, remotes)
	local panel = C.Panel(root, "While you were away", C.Gold, 420)
	panel.Name = "OfflineIncome"
	local body = panel.ContentScroll.Body
	local function resize()
		panel.Size = UDim2.fromOffset(math.min(560, root.AbsoluteSize.X - 24), math.min(530, root.AbsoluteSize.Y - 24))
		body.Size = UDim2.new(1, -8, 0, 420)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	panel:GetPropertyChangedSignal("Visible"):Connect(resize)
	resize()
	C.Icon(body, "Coin", UDim2.fromOffset(64, 64), UDim2.new(0.5, -32, 0, 4))
	local away = C.BodyText(body, "", UDim2.new(1, -16, 0, 32), UDim2.fromOffset(8, 78))
	local amount = C.Text(body, "", UDim2.new(1, -16, 0, 64), UDim2.fromOffset(8, 116), 42)
	amount.TextColor3 = C.Gold
	local detail = C.BodyText(body, "", UDim2.new(1, -16, 0, 76), UDim2.fromOffset(8, 184))
	local status = C.BodyText(
		body,
		"You can also collect on your plot's pads.",
		UDim2.new(1, -16, 0, 48),
		UDim2.fromOffset(8, 350)
	)
	local shown, pending, sentAt, report = false, false, 0, nil
	local collect
	collect = C.Button(body, "Collect", UDim2.new(1, -16, 0, 66), UDim2.fromOffset(8, 274), function()
		if not report or pending then
			return
		end
		pending, sentAt = true, os.clock()
		collect.Text, collect.Interactable = "Collecting...", false
		remotes.CollectOffline:FireServer()
	end, C.Green, { Icon = "Coin", TextSize = 30 })
	collect.Name = "CollectOffline"
	local heartbeat = Run.Heartbeat:Connect(function()
		if pending and os.clock() - sentAt >= 15 then
			pending = false
			collect.Text, collect.Interactable = "Collect", report ~= nil
			status.Text = "Still checking. Retry or collect on your plot."
			remotes.State:FireServer()
		end
	end)
	panel.Destroying:Connect(function()
		heartbeat:Disconnect()
	end)
	return {
		Panel = panel,
		Update = function(state)
			report = state.OfflineIncome
			if not report or report.Coins < 1 then
				panel.Visible, pending = false, false
				collect.Interactable = false
				return
			end
			away.Text = if report.AwaySeconds < 3600
				then "Away for " .. math.max(1, math.floor(report.AwaySeconds / 60)) .. " minutes"
				else string.format("Away for %.1f hours", report.AwaySeconds / 3600)
			amount.Text = C.Commas(report.Coins) .. " Coins"
			detail.Text = if report.FullSeconds > 0
				then string.format(
					"Your tank was full for %.1f hours - upgrade Offline Tank!",
					report.FullSeconds / 3600
				)
				else "Your displayed items kept earning. Welcome back!"
			if report.Earned and report.Earned > report.Coins then
				detail.Text = "Earned " .. C.Commas(report.Earned) .. " Coins; some already collected.\n" .. detail.Text
			end
			collect.Interactable = not pending
			if not shown then
				shown, panel.Visible = true, true
			end
		end,
		Result = function(payload)
			if not pending then
				return
			end
			pending = false
			collect.Text, collect.Interactable = "Collect", report ~= nil
			if payload.Success then
				panel.Visible = report ~= nil
				status.Text = "Some coins remain. Make room in your wallet to collect them."
			else
				status.Text = payload.Message or "Please try again."
			end
		end,
	}
end
return OfflineIncome
