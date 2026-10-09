local C = require(script.Parent.Components)
local Layout = require(script.Parent.Layout)
local Preview = require(script.Parent.Preview)
local Rarities = require(game.ReplicatedStorage.Shared.Config.Rarities)
local UserInputService = game:GetService("UserInputService")
local upgrades =
	require(game.ReplicatedStorage.Shared.UpgradeRules).new(require(game.ReplicatedStorage.Shared.Config.Upgrades))
local Reveal = {}
function Reveal.Create(parent, hud)
	local frame = C.Card(parent, C.Gold, true)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Name, frame.Visible = "FlushReveal", false
	local icon, currentItem
	local heading = C.Text(frame, "", UDim2.fromScale(0.67, 0.4), UDim2.fromScale(0.3, 0.08), 34)
	local rarity = C.Text(frame, "", UDim2.fromScale(0.67, 0.21), UDim2.fromScale(0.3, 0.51), 22)
	local odds = C.Text(frame, "", UDim2.fromScale(0.67, 0.17), UDim2.fromScale(0.3, 0.77), 18)
	local function resize()
		C.Place(
			frame,
			Layout.Compute(parent.AbsoluteSize.X, parent.AbsoluteSize.Y, UserInputService.TouchEnabled).Reveal
		)
		local short = parent.AbsoluteSize.Y < 300
		heading.Size = if short then UDim2.fromScale(0.67, 0.48) else UDim2.fromScale(0.67, 0.4)
		rarity.Position = if short then UDim2.fromScale(0.3, 0.61) else UDim2.fromScale(0.3, 0.51)
		rarity.Size = if short then UDim2.fromScale(0.67, 0.28) else UDim2.fromScale(0.67, 0.21)
		odds.Visible = not short
		if currentItem then
			rarity.Text = string.upper(currentItem.Rarity)
				.. (if short then " | 1 in " .. C.Commas(currentItem.Chance) else "")
		end
	end
	parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	local generation = 0
	return function(item, skip, cooldown)
		generation += 1
		local token = generation
		local color = if item.Rarity == "Secret" then C.Purple else Rarities[item.Rarity].Color
		frame.Background.UIStroke.Color, frame.Glow.UIStroke.Color = color, color
		heading.Text, rarity.Text, odds.Text = item.Name, string.upper(item.Rarity), "1 in " .. C.Commas(item.Chance)
		currentItem = item
		resize()
		rarity.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.25)
		if icon then
			icon:Destroy()
		end
		icon = Preview.Create(frame, UDim2.fromScale(0.25, 0.75), UDim2.fromScale(0.025, 0.12), item)
		frame.Visible = true
		local duration =
			math.min(if skip then 0.15 else math.huge, upgrades:Animation(cooldown or upgrades.Config.CooldownFloor))
		C.Sound(item.Rarity)
		hud.SetHintVisible(false)
		if not skip then
			C.Pop(frame)
			if Rarities[item.Rarity].Order >= 4 then
				C.Shine(frame)
			end
		end
		task.delay(duration, function()
			if generation == token then
				frame.Visible = false
				hud.SetHintVisible(true)
			end
		end)
	end
end
return Reveal
