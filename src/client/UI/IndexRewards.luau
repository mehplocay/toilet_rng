local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local index = require(Shared.IndexProgress).new(require(Shared.Config.Items), require(Shared.Config.IndexRewards))
local Rewards = {}

function Rewards.Create(panel, remotes)
	local frame = C.New("Frame", panel, {
		Visible = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.94, 0.74),
		Position = UDim2.fromScale(0.03, 0.22),
	})
	local balance = C.Text(frame, "Stamps: 0 | Permanent, one-time rewards", UDim2.fromScale(1, 0.08))
	local status = C.Text(
		frame,
		"Discover items, then claim each reward once.",
		UDim2.fromScale(1, 0.07),
		UDim2.fromScale(0, 0.09)
	)
	local list = C.New("ScrollingFrame", frame, {
		Size = UDim2.fromScale(1, 0.82),
		Position = UDim2.fromScale(0, 0.18),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 5,
	})
	C.New("UIListLayout", list, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	local state, pending = nil, {}
	local buttons, progress = {}, {}
	local function update()
		if not state then
			return
		end
		local cosmeticCount = 0
		for _, owned in pairs(state.IndexCosmetics or {}) do
			if owned then
				cosmeticCount += 1
			end
		end
		balance.Text = "Stamps: " .. C.Commas(state.Stamps or 0) .. " | Cosmetic unlocks: " .. cosmeticCount
		for _, reward in ipairs(index.Rewards) do
			local count = index:Count(state, reward)
			local claimed = (state.IndexClaims or {})[reward.Id] == true
			progress[reward.Id].Text = (if reward.Rarity then reward.Rarity else "Discoveries")
				.. ": "
				.. count
				.. "/"
				.. reward.Required
			local button = buttons[reward.Id]
			button.Text = if claimed
				then "Claimed"
				elseif pending[reward.Id] then "Saving..."
				elseif count >= reward.Required then "Claim"
				else "Locked"
			button.Interactable = not claimed and not pending[reward.Id] and count >= reward.Required
		end
	end
	for order, reward in ipairs(index.Rewards) do
		local row = C.New("Frame", list, {
			Size = UDim2.new(1, -12, 0, 76),
			BackgroundColor3 = C.Navy,
			LayoutOrder = order,
		})
		C.Chrome(row, C.Navy)
		C.Text(row, reward.Label, UDim2.fromScale(0.75, 0.4), UDim2.fromScale(0.02, 0.07))
		progress[reward.Id] = C.Text(row, "", UDim2.fromScale(0.75, 0.32), UDim2.fromScale(0.02, 0.55))
		buttons[reward.Id] = C.Button(row, "Locked", UDim2.fromScale(0.2, 0.65), UDim2.fromScale(0.78, 0.18), function()
			if not state or not buttons[reward.Id].Interactable then
				return
			end
			pending[reward.Id] = true
			update()
			remotes.ClaimIndexReward:FireServer(reward.Id)
			-- A dropped/rate-limited request may be retried; the server enforces one-time grants.
			task.delay(10, function()
				pending[reward.Id] = nil
				update()
			end)
		end)
	end
	remotes.Result.OnClientEvent:Connect(function(action, result)
		if action ~= "ClaimIndexReward" then
			return
		end
		if result.RewardId then
			pending[result.RewardId] = nil
		end
		status.Text = result.Message
		update()
	end)
	return {
		Frame = frame,
		Update = function(newState)
			state = newState
			for id in pairs(pending) do
				if (state.IndexClaims or {})[id] then
					pending[id] = nil
				end
			end
			update()
		end,
	}
end

return Rewards
