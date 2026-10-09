local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Rebirth)
local requestLimit = require(Shared.Config.Remotes).Limits.Rebirth
local rules = require(Shared.RebirthRules).new(Config)
local Run = game:GetService("RunService")
local Rebirth = {}
function Rebirth.Create(root, remotes)
	local panel = C.Panel(root, "REBIRTH", C.Purple, 1146)
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
	local cashStacking =
		C.BodyText(body, require(Shared.Config.Cash).Explanation, UDim2.new(1, -8, 0, 70), UDim2.fromOffset(4, 930))
	cashStacking.Name = "CashStacking"
	local state, pending = nil, false
	local pendingAt, completedLevel, refreshRequested = 0, 0, false
	local retryAt = 0
	local confirm, update
	confirm = C.Button(body, "Loading...", UDim2.new(1, -8, 0, 58), UDim2.fromOffset(4, 1076), function()
		if
			panel.Visible
			and state
			and not pending
			and os.clock() >= retryAt
			and rules:Level(state) >= completedLevel
			and rules:Eligible(state, rules:Level(state))
		then
			local expected = rules:Level(state)
			-- Lock before sending so consecutive activations cannot submit twice.
			pending, pendingAt, refreshRequested = true, os.clock(), false
			update()
			remotes.Rebirth:FireServer(expected)
		end
	end, C.Purple, { TextSize = 23 })
	confirm.Name = "Confirm"
	confirm.Interactable = false
	local function resizeContent()
		local narrow = panel.Size.X.Offset < 560
		local reset, keep = body.RESETS, body.KEEPS
		reset.Size = UDim2.new(if narrow then 1 else 0.5, -8, 0, 264)
		keep.Size = reset.Size
		keep.Position = if narrow then UDim2.fromOffset(4, 508) else UDim2.new(0.5, 4, 0, 232)
		local offset = if narrow then 276 else 0
		local y = 508 + offset
		for _, label in ipairs({ preview, perks, cashStacking, warning }) do
			local measured = game:GetService("TextService"):GetTextSize(
				label.Text,
				14,
				label.Font,
				Vector2.new(math.max(100, panel.Size.X.Offset - 48), 100000)
			)
			local height = math.max(48, math.ceil(measured.Y) + 12)
			label.Position, label.Size = UDim2.fromOffset(4, y), UDim2.new(1, -8, 0, height)
			y += height + 12
		end
		confirm.Position = UDim2.fromOffset(4, y)
		body.Size = UDim2.new(1, -8, 0, y + 70)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeContent)
	panel:GetPropertyChangedSignal("Visible"):Connect(resizeContent)
	resizeContent()
	update = function()
		if not state then
			return
		end
		local count, bonus = rules:Level(state), rules:Bonus(state)
		local nextBonus = Config.Levels[count + 1]
		level.Text = "REBIRTH " .. count .. " / " .. #Config.Levels
		title.Text = bonus.Title
		current.Text = string.format(
			"Permanent: +%d%% cash / +%d%% luck / +%d%% speed",
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
				"NEXT: +%d%% cash / +%d%% luck / +%d%% speed\nStarter: %s Coins. Cash multiplies other bonuses. Luck stacks without a cap. Speed floor applies.",
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
		local eligible = count >= completedLevel and rules:Eligible(state, count)
		local missingFlushes = Config.RequiredFlushes - (state.RunFlushes or 0)
		confirm.Interactable = eligible and not pending and os.clock() >= retryAt
		confirm.Text = if pending
			then "SAVING..."
			elseif not nextBonus then "MAX REBIRTH"
			elseif count < completedLevel then "UPDATING..."
			elseif
				state.Coins < nextBonus.RequiredCoins and (state.RunFlushes or 0) < Config.RequiredFlushes
			then "NEED COINS + FLUSHES"
			elseif state.Coins < nextBonus.RequiredCoins then "NEED " .. C.Commas(
				nextBonus.RequiredCoins - state.Coins
			) .. " MORE COINS"
			elseif missingFlushes > 0 then "NEED " .. C.Commas(missingFlushes) .. (if missingFlushes == 1
				then " MORE FLUSH"
				else " MORE FLUSHES")
			elseif not eligible then "REQUIREMENTS NOT MET"
			elseif os.clock() < retryAt then "PLEASE WAIT"
			else "REBIRTH!"
		resizeContent()
	end
	local connections = {}
	table.insert(
		connections,
		Run.Heartbeat:Connect(function()
			if not pending and retryAt > 0 and os.clock() >= retryAt then
				retryAt = 0
				update()
			end
			if pending and not refreshRequested and os.clock() - pendingAt >= Config.ResponseTimeout then
				-- A timeout is not a failed transaction. Keep locked until its result.
				refreshRequested = true
				remotes.State:FireServer()
				toast("Still waiting for the server. Your rebirth will not be sent again.", C.Gold)
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
			if payload.Success then
				completedLevel = math.max(completedLevel, payload.Level)
			else
				-- An immediate retry must not be silently dropped by the server bucket.
				retryAt = pendingAt + 1 / requestLimit.Refill
			end
			update()
			if payload.Success then
				panel.Visible = false
				toast("REBIRTH " .. payload.Level .. " - " .. Config.Levels[payload.Level].Title, C.Gold)
				-- Phones already show the same result in the compact toast.
				if
					not C.Layout.IsPhone(
						root.AbsoluteSize.X,
						root.AbsoluteSize.Y,
						game:GetService("UserInputService").TouchEnabled
					) and (not state or not state.Settings or state.Settings.RevealIntensity ~= "Off")
				then
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
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		celebration:Destroy()
	end)
	return {
		Panel = panel,
		Update = function(snapshot)
			state = snapshot
			update()
		end,
	}
end
return Rebirth
