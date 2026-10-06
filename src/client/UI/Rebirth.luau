local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Rebirth)
local rules = require(Shared.RebirthRules).new(Config)
local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Rebirth = {}
function Rebirth.Create(root, remotes)
	local panel = C.Panel(root, "REBIRTH", C.Purple, 1170)
	local toast = C.Toast(root)
	local body = panel.ContentScroll.Body
	C.Icon(body, "Crown", UDim2.fromOffset(62, 62), UDim2.fromOffset(4, 0))
	local level = C.Text(body, "REBIRTH 0", UDim2.new(1, -76, 0, 32), UDim2.fromOffset(72, 0), 26)
	local title = C.BodyText(body, "New Flusher", UDim2.new(1, -76, 0, 28), UDim2.fromOffset(72, 36))
	local current = C.BodyText(body, "", UDim2.new(1, -8, 0, 42), UDim2.fromOffset(4, 68))
	current.Name = "PermanentBonuses"
	local flushLabel = C.BodyText(body, "", UDim2.new(1, -8, 0, 28), UDim2.fromOffset(4, 116))
	local flushBar = C.ProgressBar(body, UDim2.new(1, -8, 0, 12), UDim2.fromOffset(4, 148), C.Purple)
	local tierLabel = C.BodyText(body, "", UDim2.new(1, -8, 0, 28), UDim2.fromOffset(4, 172))
	tierLabel.Name = "CoinGate"
	local tierBar = C.ProgressBar(body, UDim2.new(1, -8, 0, 12), UDim2.fromOffset(4, 204), C.Blue)
	for i, definition in ipairs({ { "RESETS", Config.ResetList, C.Gold }, { "KEEPS", Config.KeepList, C.Green } }) do
		local card = C.Card(body, definition[3])
		card.Name = definition[1]
		card.Size, card.Position = UDim2.new(0.5, -8, 0, 264), UDim2.new((i - 1) * 0.5, 4, 0, 232)
		C.Text(card, definition[1], UDim2.new(1, -12, 0, 30), UDim2.fromOffset(6, 6), 22)
		for row, text in ipairs(definition[2]) do
			local label = C.BodyText(card, text, UDim2.new(1, -12, 0, 34), UDim2.fromOffset(6, 40 + (row - 1) * 36))
			label.UITextSizeConstraint.MaxTextSize = 15
		end
	end
	local preview = C.BodyText(body, "", UDim2.new(1, -8, 0, 64), UDim2.fromOffset(4, 508))
	preview.Name, preview.TextColor3 = "NextBonus", C.Gold
	local perks = C.BodyText(body, "", UDim2.new(1, -8, 0, 346), UDim2.fromOffset(4, 578))
	perks.Name = "TokenPerks"
	local warning = C.BodyText(body, "", UDim2.new(1, -8, 0, 56), UDim2.fromOffset(4, 1010))
	local cashCaps =
		C.BodyText(body, require(Shared.Config.Cash).Explanation, UDim2.new(1, -8, 0, 70), UDim2.fromOffset(4, 930))
	cashCaps.Name = "CashCaps"
	local state, armedLevel, held, heldAt, pending = nil, nil, nil, 0, false
	local pendingAt = 0
	local confirm, update
	local holdBar = C.ProgressBar(body, UDim2.new(1, -8, 0, 10), UDim2.fromOffset(4, 1142), C.Gold)
	local function cancel()
		C.StopSound("RebirthHold")
		armedLevel, held = nil, nil
		holdBar.Set(0)
		if update then
			update()
		end
	end
	confirm = C.Button(body, "Loading...", UDim2.new(1, -8, 0, 58), UDim2.fromOffset(4, 1076), function()
		if state and not pending and rules:Eligible(state, rules:Level(state)) and armedLevel == nil then
			armedLevel = rules:Level(state)
			update()
		end
	end, C.Purple, { TextSize = 23 })
	confirm.Name = "Confirm"
	confirm.Interactable = false
	update = function()
		if not state then
			return
		end
		local count, bonus = rules:Level(state), rules:Bonus(state)
		local nextBonus = Config.Levels[count + 1]
		level.Text = "REBIRTH " .. count .. " / " .. #Config.Levels
		title.Text = bonus.Title
		current.Text = string.format(
			"Permanent (before caps): +%d%% cash / +%d%% luck / +%d%% speed",
			math.round(bonus.Cash * 100),
			math.round(bonus.Luck * 100),
			math.round(bonus.Speed * 100)
		)
		flushLabel.Text = C.Commas(state.RunFlushes or 0)
			.. " / "
			.. C.Commas(Config.RequiredFlushes)
			.. " flushes this run"
		flushBar.Set((state.RunFlushes or 0) / Config.RequiredFlushes)
		tierLabel.Text = if nextBonus
			then C.Commas(state.Coins) .. " / " .. C.Commas(nextBonus.RequiredCoins) .. " Coins required"
			else "All coin gates complete"
		tierBar.Set(if nextBonus then state.Coins / nextBonus.RequiredCoins else 1)
		preview.Text = if nextBonus
			then string.format(
				"NEXT: +%d%% cash / +%d%% luck / +%d%% speed\nStarter: %s Coins. Cash/luck caps and speed floor apply.",
				math.round(nextBonus.Cash * 100),
				math.round(nextBonus.Luck * 100),
				math.round(nextBonus.Speed * 100),
				C.Commas(nextBonus.StarterCoins)
			)
			else "MAX LEVEL - all permanent bonuses unlocked."
		perks.Text = if nextBonus
			then "NEXT LEVEL PERKS (cumulative)\n" .. table.concat(nextBonus.Perks, "\n")
			else "YOUR UNLOCKED PERKS\n" .. table.concat(bonus.Perks, "\n")
		warning.Text = if nextBonus
			then string.format(
				"%s wallet Coins + %s pending Coins reset.\nLoose items reset. Toilets, upgrades and displays stay.",
				C.Commas(state.Coins),
				C.Commas(state.PendingCoins or 0)
			)
			else "Your progress is safe. No further reset is available."
		local eligible = rules:Eligible(state, count)
		confirm.Interactable = eligible and not pending
		confirm.Text = if pending
			then "SAVING..."
			elseif not nextBonus then "MAX REBIRTH"
			elseif not eligible then "REQUIREMENTS NOT MET"
			elseif armedLevel ~= nil then "HOLD " .. Config.HoldSeconds .. " SECONDS TO RESET"
			else "REVIEWED - CONTINUE"
	end
	local function begin(input)
		if
			not panel.Visible
			or pending
			or armedLevel == nil
			or held
			or not state
			or not rules:Eligible(state, armedLevel)
		then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
			or input.KeyCode == Enum.KeyCode.Return
			or input.KeyCode == Enum.KeyCode.Space
		then
			held, heldAt = input, os.clock()
			C.Sound("RebirthHold")
		end
	end
	local connections = {}
	table.insert(connections, confirm.InputBegan:Connect(begin))
	table.insert(
		connections,
		Input.InputBegan:Connect(function(input)
			if
				game:GetService("GuiService").SelectedObject == confirm
				and (
					input.KeyCode == Enum.KeyCode.ButtonA
					or input.KeyCode == Enum.KeyCode.Return
					or input.KeyCode == Enum.KeyCode.Space
				)
			then
				begin(input)
			end
		end)
	)
	table.insert(
		connections,
		Input.InputEnded:Connect(function(input)
			if input == held then
				C.StopSound("RebirthHold")
				held = nil
				holdBar.Set(0)
			end
		end)
	)
	table.insert(
		connections,
		confirm.MouseLeave:Connect(function()
			C.StopSound("RebirthHold")
			held = nil
			holdBar.Set(0)
		end)
	)
	table.insert(connections, confirm.SelectionLost:Connect(cancel))
	table.insert(connections, panel.ContentScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(cancel))
	table.insert(connections, Input.WindowFocusReleased:Connect(cancel))
	table.insert(connections, panel:GetPropertyChangedSignal("Visible"):Connect(cancel))
	table.insert(
		connections,
		Run.Heartbeat:Connect(function()
			if pending and os.clock() - pendingAt >= Config.ResponseTimeout then
				pending = false
				cancel()
				remotes.State:FireServer()
				toast("No save confirmation yet. Check your level before retrying.", C.Gold)
			end
			if not held then
				return
			end
			if not panel.Visible or not state or not rules:Eligible(state, armedLevel) then
				cancel()
				return
			end
			local progress = (os.clock() - heldAt) / Config.HoldSeconds
			holdBar.Set(progress)
			if progress >= 1 then
				C.StopSound("RebirthHold")
				local expected = armedLevel
				pending, held, armedLevel = true, nil, nil
				pendingAt = os.clock()
				update()
				remotes.Rebirth:FireServer(expected)
			end
		end)
	)
	local celebration = C.Card(root, C.Gold, true)
	celebration.Name, celebration.Visible, celebration.ZIndex = "RebirthCelebration", false, 85
	celebration.AnchorPoint, celebration.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.35)
	local crown = C.Icon(celebration, "Crown", UDim2.fromOffset(72, 72), UDim2.new(0.5, -36, 0, 8))
	local celebrationText = C.Text(celebration, "", UDim2.new(1, -16, 0, 54), UDim2.fromOffset(8, 88), 26)
	table.insert(
		connections,
		remotes.Result.OnClientEvent:Connect(function(action, payload)
			if action ~= "Rebirth" then
				return
			end
			pending = false
			cancel()
			if payload.Success then
				panel.Visible = false
				toast("REBIRTH " .. payload.Level .. " - " .. Config.Levels[payload.Level].Title, C.Gold)
				if not state or not state.Settings or state.Settings.RevealIntensity ~= "Off" then
					celebration.Size = UDim2.fromOffset(math.min(440, root.AbsoluteSize.X - 48), 154)
					celebrationText.Text = "REBIRTH " .. payload.Level .. "\n" .. Config.Levels[payload.Level].Title
					celebration.Visible = true
					C.Pop(celebration)
					if not state or not state.Settings or state.Settings.RevealIntensity ~= "Reduced" then
						crown.Rotation = -18
						C.Tween(crown, 0.7, { Rotation = 18 })
					end
					task.delay(3, function()
						if celebration.Parent then
							celebration.Visible = false
						end
					end)
				end
			else
				toast(payload.Message, C.Gold)
			end
		end)
	)
	panel.Destroying:Connect(function()
		C.StopSound("RebirthHold")
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		celebration:Destroy()
	end)
	return {
		Panel = panel,
		Update = function(snapshot)
			if state and rules:Level(state) ~= rules:Level(snapshot) then
				pending = false
				cancel()
			end
			state = snapshot
			update()
		end,
	}
end
return Rebirth
