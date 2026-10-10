local C = require(script.Parent.Components)
local Schedule = require(game.ReplicatedStorage.Shared.RewardSchedule)
local Rewards = require(game.ReplicatedStorage.Shared.Config.Rewards)
local GuiService = game:GetService("GuiService")
local Leave = {}

function Leave.Create(root, remotes)
	local panel = C.Panel(root, "Leave already?", C.Gold, nil, true)
	panel.Name = "Leave"
	local body = panel.ContentScroll.Body
	C.Icon(body, "Door", UDim2.fromOffset(64, 64))
	local message = C.BodyText(
		body,
		"Your displays keep earning while you're away!",
		UDim2.new(1, -80, 0, 56),
		UDim2.fromOffset(80, 0)
	)
	message.Name = "AwayMessage"
	local daily = C.Text(body, "", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 64), 18)
	daily.Name, daily.TextColor3 = "DailyReady", C.Gold
	local snapshot, previousFocus
	local stay = C.Button(body, "Stay", UDim2.new(0.62, -6, 0, 52), UDim2.fromOffset(0, 96), function()
		panel.Visible = false
	end, C.Green, { TextSize = 26 })
	local leave = C.Button(body, "Leave", UDim2.new(0.38, -6, 0, 52), UDim2.new(0.62, 6, 0, 96), function()
		if not panel.Visible then
			return
		end
		panel.Visible = false
		remotes.LeaveRequest:FireServer()
	end, Color3.fromRGB(237, 61, 78), { TextSize = 22 })
	stay.SelectionOrder, leave.SelectionOrder = 1, 2
	stay.NextSelectionRight, leave.NextSelectionLeft = leave, stay
	local function updateDaily()
		local ready = snapshot
			and type(snapshot.LastClaimDay) == "number"
			and type(snapshot.Streak) == "number"
			and Schedule.Progress(snapshot.LastClaimDay, snapshot.Streak, workspace:GetServerTimeNow(), Rewards)
		daily.Text = if ready then "Daily reward ready!" else ""
	end
	local function resize()
		local width, height = math.min(480, root.AbsoluteSize.X - 24), math.min(252, root.AbsoluteSize.Y - 24)
		panel.Size = UDim2.fromOffset(width, height)
		panel.Position = UDim2.fromScale(0.5, 0.5)
		body.Size = UDim2.fromScale(1, 1)
		for _, object in ipairs(panel:GetDescendants()) do
			local constraint = object:FindFirstChildWhichIsA("UITextSizeConstraint")
			if constraint then
				constraint.MinTextSize = 14
			end
		end
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	root:GetAttributeChangedSignal("TutorialActive"):Connect(resize)
	-- CoreGui can consume Escape before the game's input binding sees it.
	local menuConnection = GuiService.MenuOpened:Connect(function()
		panel.Visible = false
	end)
	panel.Destroying:Connect(function()
		menuConnection:Disconnect()
	end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			resize()
			updateDaily()
			previousFocus = GuiService.SelectedObject
			GuiService.SelectedObject = stay
		else
			local ancestor = previousFocus
			while ancestor and ancestor ~= root do
				if ancestor:IsA("GuiObject") and not ancestor.Visible then
					previousFocus = nil
					break
				end
				ancestor = ancestor.Parent
			end
			GuiService.SelectedObject = if previousFocus
					and previousFocus.Parent
					and previousFocus.Visible
				then previousFocus
				else nil
		end
	end)

	resize()
	return {
		Panel = panel,
		Update = function(state)
			snapshot = state
			updateDaily()
		end,
	}
end
return Leave
