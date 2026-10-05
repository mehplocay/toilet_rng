local Shared = game.ReplicatedStorage.Shared
local Layout = require(Shared.Config.MapLayout)
local V = require(Shared.Config.Visuals)
local Rarities = require(Shared.Config.Rarities)
local Income = require(Shared.Config.Income)
local Items = require(Shared.Config.Items)
local accounting =
	require(Shared.IncomeAccrual).new(Income, Items, require(Shared.UpgradeRules).new(require(Shared.Config.Upgrades)))
local Kit = require(script.Parent.Kit)
local Models = require(script.Parent.Models)
local Rows = {}
local byId = {}
for _, item in ipairs(Items) do
	byId[item.Id] = item
end
function Rows.Build(plot, previewProfile)
	local profile = previewProfile or plot.Profile
	plot.Displays:ClearAllChildren()
	plot.CollectPoints, plot.IncomePoint = {}, nil
	local pageSize = V.Budget.DisplayPageSize
	local first = ((plot.Page or 1) - 1) * pageSize + 1
	local rates = accounting:Rates(profile)
	for position, offset in ipairs(Layout.Slots) do
		local slot = first + position - 1
		local cf = plot.LayoutCFrame * CFrame.new(offset)
		local stand = Kit.Place(plot.Displays, { Asset = "DisplayPedestal", Position = Vector3.new(), Scale = 2.1 }, cf)
		stand.Name = "Slot" .. slot
		stand:SetAttribute("DisplaySlot", slot)
		local padCF = cf * CFrame.new(if offset.X < 0 then 5 else -5, 0.02, 0)
		Kit.Place(plot.Displays, {
			Asset = "GrassSlab",
			Position = Vector3.new(),
			Size = Vector3.new(3.8, 0.14, 4.5),
			Solid = { 51, 240, 101 },
			Neon = true,
		}, padCF)
		local _, point = Kit.Label(
			plot.Displays,
			"CollectPad",
			padCF * CFrame.new(0, 0.18, 0) * CFrame.Angles(math.pi / 2, 0, 0),
			Vector3.new(3.4, 4, 0.05),
			"$",
			Color3.new(1, 1, 1),
			false,
			60
		)
		table.insert(plot.CollectPoints, point)
		local item = byId[profile.Displays[tostring(slot)]]
		if slot <= profile.DisplaySlots and item then
			local itemModel = Models.Item(plot.Displays, cf * CFrame.new(0, 3.45, 0), item, true)
			local color = if item.Rarity == "Secret" then V.Palette.Cyan else Rarities[item.Rarity].Color
			local rate = (rates[tostring(slot)] or 0) * 60 / Income.UnitsPerCoin
			Kit.Label(
				itemModel,
				"IncomeNametag",
				cf * CFrame.new(0, 7.5, 0),
				Vector3.new(7, 4, 0.1),
				item.Name
					.. "\n"
					.. item.Rarity
					.. "\n1 in "
					.. item.Chance
					.. "\n$"
					.. string.format("%.2f", rate)
					.. " / min",
				color,
				true,
				Layout.Labels.OccupiedDistance
			)
		else
			local unlocked = slot <= profile.DisplaySlots
			local lockSize = Layout.Labels.LockSize
			Kit.Label(
				plot.Displays,
				"EmptySlot",
				cf * CFrame.new(0, 3, 0),
				if unlocked then Vector3.new(4, 1.2, 0.1) else Vector3.new(lockSize, lockSize, 0.1),
				if unlocked then "Display " .. slot else "\u{1F512}",
				Color3.new(1, 1, 1),
				true,
				Layout.Labels.EmptyDistance
			)
		end
	end
	if profile.DisplaySlots > pageSize then
		Kit.Label(
			plot.Displays,
			"DisplayPage",
			plot.LayoutCFrame * CFrame.new(0, 3, -20),
			Vector3.new(10, 2, 0.1),
			"Display page " .. plot.Page .. "/" .. math.ceil(profile.DisplaySlots / pageSize),
			Color3.new(1, 1, 1),
			true,
			70
		)
	end
end
return Rows
