local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Upgrades)
local Income = require(Shared.Config.Income)
local Assets = require(Shared.Config.Assets)
local rules = require(Shared.UpgradeRules).new(Config)
local Tracks = {}
local Format = require(Shared.NumberFormat)
function Tracks.Create(body, remotes)
	local row = C.Scroll(body, UDim2.new(1, 0, 1, -146), UDim2.fromOffset(0, 110))
	row.Name, row.Visible = "PermanentUpgradeTracks", false
	C.Grid(row, 210, 350, 3)
	local latest, cards = nil, {}
	local colors = { C.Gold, C.Purple, C.Green, C.Blue, C.Purple, C.Gold }
	local descriptions = {
		CashBoost = require(Shared.Config.Cash).Explanation,
		LuckBoost = "Cap: 10x total (+900%). Full luck applies to every item check.",
		FlushSpeed = "Shorter shared cooldown. Always at least " .. Config.CooldownFloor .. " seconds.",
		AutoFlushSpeed = "Faster auto interval, never below your flush cooldown. Free at 100 flushes.",
		DisplaySlots = "+1 display slot per purchase. Ten physical slots; index rewards kept.",
		OfflineTank = "8 hours offline at base; upgrades extend time. Storage limits apply.",
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
		local progress = C.ProgressBar(card, UDim2.new(1, -20, 0, 8), UDim2.fromOffset(10, 208), colors[order])
		progress.Frame.Name = "Progress"
		local milestone = C.BodyText(card, "", UDim2.new(1, -20, 0, 36), UDim2.fromOffset(10, 219))
		milestone.Name = "Milestone"
		local price = C.Text(card, "", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 258), 22)
		price.TextColor3 = C.Gold
		price.Name = "Price"
		local button = C.Button(card, "Buy", UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 300), function()
			if latest then
				remotes.BuyUpgrade:FireServer(track.Id, rules:Level(latest, track.Id))
			end
		end, C.Green)
		button.Interactable = false
		cards[track.Id] = {
			Frame = card,
			Progress = progress,
			Milestone = milestone,
			Level = level,
			Effect = effect,
			Price = price,
			Button = button,
		}
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
		TutorialTarget = function()
			for _, track in ipairs(Config.Tracks) do
				if cards[track.Id].Button.Interactable then
					return cards[track.Id].Button
				end
			end
			return nil
		end,
		Update = function(state)
			local previous = latest
			latest = state
			local stats = state.UpgradeStats or {}
			for _, track in ipairs(Config.Tracks) do
				local card, level = cards[track.Id], rules:Level(state, track.Id)
				local price = rules:Price(track.Id, level)
				local full = track.Id == "DisplaySlots" and (state.DisplaySlots or 3) >= Config.DisplayCapacity
				card.Level.Text = level .. " / " .. track.MaxLevel
				card.Progress.Set(if full then 1 else level / track.MaxLevel)
				local title, nextLevel = rules:Milestone(state, track.Id)
				card.Milestone.Text = title .. (if nextLevel then " | Next title: " .. nextLevel else "")
				if previous and level > rules:Level(previous, track.Id) then
					C.Pop(card.Frame)
				end
				local effects = {
					CashBoost = Format.Compact(rules:Cash(state), 2) .. "x coins",
					LuckBoost = string.format(
						"Luck +%d%%%s",
						math.round(((stats.LuckMultiplier or 1) - 1) * 100),
						if stats.LuckCapped then " | " .. Config.LuckCap .. "x CAP REACHED" else ""
					),
					FlushSpeed = string.format("%.2fs current cooldown", stats.Cooldown or 1.5),
					AutoFlushSpeed = string.format("%.2fs current auto interval", stats.AutoInterval or 3),
					DisplaySlots = tostring(state.DisplaySlots or 3) .. " slots unlocked",
					OfflineTank = string
						.format("%.1f", (stats.OfflineMinutes or Income.OfflineMinutes) / 60)
						:gsub("%.0$", "") .. " hours offline cap",
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
