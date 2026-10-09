local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local index = require(Shared.IndexProgress).new(require(Shared.Config.Items), require(Shared.Config.IndexRewards))
local Rarities = require(Shared.Config.Rarities)
local Rewards = {}
function Rewards.Create(body, remotes)
	local frame = C.New("Frame", body, {
		Name = "IndexRewards",
		Visible = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.fromOffset(0, 60),
	})
	local scroll = C.Scroll(frame, UDim2.fromScale(1, 1))
	local content = C.New(
		"Frame",
		scroll,
		{ Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }
	)
	C.New("UIListLayout", content, { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
	local balance = C.Text(content, "Stamps: 0", UDim2.new(1, 0, 0, 36), nil, 22)
	balance.TextColor3 = C.Gold
	local status = C.BodyText(content, "Discover items. Claim permanent rewards.", UDim2.new(1, 0, 0, 36))
	status.LayoutOrder = 1
	local list = C.New("Frame", content, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	})
	C.Grid(list, 240, 160)
	local state, pending, rows = nil, {}, {}
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
		balance.Text = C.Commas(state.Stamps or 0) .. " Stamps  /  " .. cosmeticCount .. " Cosmetics"
		for _, reward in ipairs(index.Rewards) do
			local count = index:Count(state, reward)
			local claimed = (state.IndexClaims or {})[reward.Id] == true
			local row = rows[reward.Id]
			row.Progress.Text = (reward.Rarity or "Discoveries")
				.. "  "
				.. math.min(count, reward.Required)
				.. "/"
				.. reward.Required
			row.Bar.Set(count / reward.Required)
			row.Button.Text = if claimed
				then "Claimed"
				elseif pending[reward.Id] then "Saving..."
				elseif count >= reward.Required then "Claim"
				else "Locked"
			row.Button.Interactable = not claimed and not pending[reward.Id] and count >= reward.Required
			row.Marks(not claimed and count < reward.Required, claimed)
		end
	end
	for order, reward in ipairs(index.Rewards) do
		local color = if reward.Rarity == "Secret"
			then C.Purple
			elseif reward.Rarity and Rarities[reward.Rarity] then Rarities[reward.Rarity].Color
			else C.Gold
		local row = C.Card(list, color, true)
		row.LayoutOrder = order
		C.Icon(row, "Gem", UDim2.fromOffset(32, 32), UDim2.fromOffset(8, 10))
		C.Text(row, reward.Label, UDim2.new(1, -88, 0, 46), UDim2.fromOffset(44, 6), 21)
		local marks = C.StatusIcons(row, UDim2.fromOffset(24, 24), UDim2.new(1, -32, 0, 8))
		local progress = C.BodyText(row, "", UDim2.new(1, -20, 0, 28), UDim2.fromOffset(10, 60))
		local bar = C.ProgressBar(row, UDim2.new(1, -20, 0, 6), UDim2.fromOffset(10, 92), color)
		local button = C.Button(row, "Locked", UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 106), function()
			if not state or not rows[reward.Id].Button.Interactable then
				return
			end
			pending[reward.Id] = true
			update()
			remotes.ClaimIndexReward:FireServer(reward.Id)
			task.delay(10, function()
				pending[reward.Id] = nil
				update()
			end)
		end, C.Green, { TextSize = 19 })
		button.Interactable = false
		rows[reward.Id] = { Progress = progress, Bar = bar, Button = button, Marks = marks }
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
		Update = function(snapshot)
			state = snapshot
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
