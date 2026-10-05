local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local C = require(script.Parent.Parent.UI.Components)
local Rules = require(game.ReplicatedStorage.Shared.PresentationRules)
local Rarities = require(game.ReplicatedStorage.Shared.Config.Rarities)
local Layout = require(script.Parent.Layout)
local PlayerList = {}
function PlayerList.Create(root)
	local panel = C.Card(root, C.Blue)
	panel.Name, panel.Visible, panel.ZIndex = "ServerPlayers", false, 65
	local heading =
		C.Text(panel, "PLAYER          COINS ↓     RAREST", UDim2.new(1, -52, 0, 44), UDim2.fromOffset(8, 0), 16)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	local close = C.Button(panel, "×", UDim2.fromOffset(44, 44), UDim2.new(1, -46, 0, 0), function()
		panel.Visible = false
	end, C.Blue)
	close.Name = "Close"
	local list = C.Scroll(panel, UDim2.new(1, -12, 1, -54), UDim2.fromOffset(6, 48))
	C.New("UIListLayout", list, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
	local rows, connections, elapsed, coreDisabled, previous = {}, {}, 0, false, true
	local function refresh()
		local sorted, present = {}, {}
		for _, player in ipairs(Players:GetPlayers()) do
			local stats = player:FindFirstChild("leaderstats")
			local coins, rarest = stats and stats:FindFirstChild("Coins"), stats and stats:FindFirstChild("Rarest")
			if coins and rarest then
				table.insert(sorted, {
					Player = player,
					Coins = Rules.Integer(coins.Value),
					Rarest = if Rarities[rarest.Value] then rarest.Value else "None",
				})
			end
		end
		table.sort(sorted, function(a, b)
			return if a.Coins == b.Coins then a.Player.UserId < b.Player.UserId else a.Coins > b.Coins
		end)
		for rank, entry in ipairs(sorted) do
			local player = entry.Player
			present[player] = true
			local row = rows[player]
			if not row then
				row = C.New("Frame", list, {
					Name = tostring(player.UserId),
					Size = UDim2.new(1, -6, 0, 44),
					BackgroundColor3 = C.Navy,
					BackgroundTransparency = 0.12,
				})
				local name = C.Text(row, player.Name, UDim2.fromScale(0.43, 1), UDim2.fromScale(0.02, 0), 16)
				name.Name = "PlayerName"
				name.TextTruncate, name.TextWrapped, name.RichText = Enum.TextTruncate.AtEnd, false, false
				name.TextXAlignment = Enum.TextXAlignment.Left
				C.Text(row, "", UDim2.fromScale(0.24, 1), UDim2.fromScale(0.45, 0), 17).Name = "Coins"
				C.Text(row, "", UDim2.fromScale(0.30, 1), UDim2.fromScale(0.70, 0), 15).Name = "Rarest"
				rows[player] = row
			end
			row.LayoutOrder = rank
			local stats = player:FindFirstChild("leaderstats")
			local rebirth = stats and stats:FindFirstChild("Rebirth")
			row.PlayerName.Text = "[R"
				.. tostring(if rebirth then Rules.Integer(rebirth.Value) else 0)
				.. "] "
				.. player.Name
			row.Coins.Text, row.Rarest.Text = Rules.Abbreviate(entry.Coins), entry.Rarest
			row.Rarest.TextColor3 = if entry.Rarest == "Secret"
				then C.Purple
				elseif Rarities[entry.Rarest] then Rarities[entry.Rarest].Color
				else C.Muted
		end
		for player, row in pairs(rows) do
			if not present[player] then
				row:Destroy()
				rows[player] = nil
			end
		end
	end
	local function resize()
		C.Place(panel, Layout.Compute(root.AbsoluteSize.X, root.AbsoluteSize.Y).List)
	end
	local function toggle()
		panel.Visible = not panel.Visible
		if panel.Visible then
			refresh()
		end
	end
	table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	table.insert(
		connections,
		Input.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.Tab then
				toggle()
			end
		end)
	)
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed < 1 then
				return
			end
			elapsed = 0
			if not coreDisabled then
				pcall(function()
					previous = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
					coreDisabled = true
				end)
			end
			if panel.Visible then
				refresh()
			end
		end)
	)
	resize()
	return {
		Toggle = toggle,
		Destroy = function()
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			if coreDisabled then
				pcall(function()
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, previous)
				end)
			end
			panel:Destroy()
		end,
	}
end
return PlayerList
