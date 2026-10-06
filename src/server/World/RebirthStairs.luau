-- Server refreshes after profile load and acknowledged rebirth saves; no polling or VFX workers.
local Config = game.ReplicatedStorage.Shared.Config
local Rebirth = require(Config.Rebirth)
local Rarities = require(Config.Rarities)
local Layout = require(Config.MapLayout)
local NumberFormat = require(game.ReplicatedStorage.Shared.NumberFormat)
local colors = {}
for _, rarity in pairs(Rarities) do
	colors[rarity.Order] = rarity.Color
end
local Stairs = {}
function Stairs.Refresh(plot, owner, profile)
	local level = if owner and profile then profile.RebirthLevel or 0 else 0
	local ownerId = if owner then owner.UserId else 0
	if plot.StairsOwnerId == ownerId and plot.StairsLevel == level then
		return
	end
	plot.StairsOwnerId, plot.StairsLevel = ownerId, level
	-- Five existing terraces follow the current milestone through the full 15-level cap.
	local first =
		math.clamp(level - Layout.Rebirth.Steps + 2, 1, math.max(1, #Rebirth.Levels - Layout.Rebirth.Steps + 1))
	local requirement = NumberFormat.Compact(Rebirth.RequiredFlushes)
		.. " flushes + "
		.. NumberFormat.Compact((Rebirth.Levels[level + 1] or Rebirth.Levels[#Rebirth.Levels]).RequiredCoins)
		.. " Coins"
	for index, step in ipairs(plot.RebirthSteps) do
		local milestone = first + index - 1
		local unlocked = owner ~= nil and milestone <= level
		local nextStep = owner ~= nil and level < #Rebirth.Levels and milestone == level + 1
		local color = colors[math.min(milestone + 1, Rarities.Godly.Order)]
		step.Label.Text = if unlocked
			then "Rebirth " .. milestone .. ": Unlocked"
			elseif nextStep then "Rebirth " .. milestone .. ":\n" .. requirement
			else "\u{1F512} Rebirth " .. milestone
		local reward = Rebirth.Levels[milestone]
		step.Label.Text ..= string.format(
			"\n+%d%% cash / +%d%% luck / +%d%% speed",
			math.round(reward.Cash * 100),
			math.round(reward.Luck * 100),
			math.round(reward.Speed * 100)
		)
		step.Label.TextColor3 = if unlocked or nextStep then color else colors[Rarities.Common.Order]
		step.Label.Parent.LightInfluence = 0
		for _, surface in ipairs(step.Surfaces) do
			local part = surface.Part
			part.Color = if unlocked or nextStep then color else surface.Color
			-- Static Neon on existing geometry gives glow without lights, particles or tweens.
			part.Material = if unlocked or nextStep then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end
return Stairs
