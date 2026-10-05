local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Upgrades)
local Assets = require(Shared.Config.Assets)
local rules = require(Shared.UpgradeRules).new(Config)
local Tracks = {}
function Tracks.Create(body, remotes)
	local row = C.Scroll(body, UDim2.new(1, 0, 1, -146), UDim2.fromOffset(0, 110))
	row.Name, row.Visible = "PermanentUpgradeTracks", false
	C.Grid(row, 210, 300, 3)
	local latest, cards = nil, {}
	local colors = { C.Gold, C.Purple, C.Green, C.Blue, C.Purple, C.Gold }
	local descriptions = {
		CashBoost = "Sales, service and display income. Whole coins round down.",
		LuckBoost = "Multiplies tier and timed luck. Total luck stops at " .. Config.LuckCap .. "x.",
		FlushSpeed = "Shorter shared cooldown. Always at least " .. Config.CooldownFloor .. " seconds.",
		AutoFlushSpeed = "Faster auto interval, never below your flush cooldown. Free at 100 flushes.",
		DisplaySlots = "+1 display slot per purchase. Ten physical slots; index rewards kept.",
		OfflineTank = "More offline display income time. Pending coin limits still apply.",
	}
	for order, track in ipairs(Config.Tracks) do
		local card = C.Card(row, colors[order], false)
		card.Name, card.LayoutOrder = track.Id, order
		C.Icon(card, track.Icon, UDim2.fromOffset(48, 48), UDim2.fromOffset(10, 10), Assets.Icons[track.Icon])
		C.Text(card, track.Name, UDim2.new(1, -76, 0, 46), UDim2.fromOffset(66, 10), 23)
		local level = C.Text(card, "", UDim2.new(1, -20, 0, 28), UDim2.fromOffset(10, 63), 20)
		local effect = C.BodyText(card, "", UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 96))
		level.Name, effect.Name = "Level", "Effect"
		C.BodyText(card, descriptions[track.Id], UDim2.new(1, -20, 0, 65), UDim2.fromOffset(10, 139))
		local price = C.Text(card, "", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 207), 22)
		price.TextColor3 = C.Gold
		price.Name = "Price"
		local button = C.Button(card, "Buy", UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 246), function()
			if latest then
				remotes.BuyUpgrade:FireServer(track.Id, rules:Level(latest, track.Id))
			end
		end, C.Green)
		button.Interactable = false
		cards[track.Id] = { Level = level, Effect = effect, Price = price, Button = button }
	end
	if remotes.Result then
		local toast = C.Toast(body.Parent.Parent.Parent)
		remotes.Result.OnClientEvent:Connect(function(action, payload)
			if action == "BuyUpgrade" then
				toast(payload.Message, if payload.Success then C.Green else C.Gold)
			end
		end)
	end
	return {
		Frame = row,
		Update = function(state)
			latest = state
			local stats = state.UpgradeStats or {}
			for _, track in ipairs(Config.Tracks) do
				local card, level = cards[track.Id], rules:Level(state, track.Id)
				local price = rules:Price(track.Id, level)
				local full = track.Id == "DisplaySlots" and (state.DisplaySlots or 3) >= Config.DisplayCapacity
				card.Level.Text = "LEVEL " .. level .. " / " .. track.MaxLevel
				local effects = {
					CashBoost = string.format("+%d%% coins", math.round((rules:Cash(state) - 1) * 100)),
					LuckBoost = string.format(
						"+%d%% luck%s",
						math.round(level * track.Step * 100),
						if stats.LuckCapped then " | " .. Config.LuckCap .. "x CAP REACHED" else ""
					),
					FlushSpeed = string.format("%.2fs current cooldown", stats.Cooldown or 1.5),
					AutoFlushSpeed = string.format("%.2fs current auto interval", stats.AutoInterval or 3),
					DisplaySlots = tostring(state.DisplaySlots or 3) .. " slots unlocked",
					OfflineTank = tostring(stats.OfflineMinutes or 240) .. " minutes offline cap",
				}
				card.Effect.Text = effects[track.Id]
				card.Price.Text = if full then "PLOT FULL" elseif price then C.Commas(price) .. " Coins" else "MAX LEVEL"
				card.Button.Text = if full or not price then "Max" elseif state.Coins >= price then "Buy" else "Save up"
				card.Button.Interactable = price ~= nil and not full and state.Coins >= price
			end
		end,
	}
end
return Tracks
