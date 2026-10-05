local SafeInventory = {}

function SafeInventory.Sellable(profile, id)
	local displayed = 0
	for _, displayId in pairs(profile.Displays or {}) do
		if displayId == id then
			displayed += 1
		end
	end
	-- A displayed copy may also be the protected first copy; never double-reserve it.
	return math.max(0, (profile.Inventory[id] or 0) - math.max(1, displayed))
end

function SafeInventory.Sell(profile, items, id, count)
	if
		type(id) ~= "string"
		or type(count) ~= "number"
		or count ~= count
		or count < 1
		or count > 1000000
		or count % 1 ~= 0
	then
		return false
	end
	local item
	for _, candidate in ipairs(items) do
		if candidate.Id == id then
			item = candidate
			break
		end
	end
	if not item or SafeInventory.Sellable(profile, id) < count then
		return false
	end
	local value = item.Value * count
	if profile.Coins + value > 9e15 or profile.Stats.Earned + value > 9e15 then
		return false
	end
	profile.Inventory[id] -= count
	profile.Coins += value
	profile.Stats.Earned += value
	return true
end

return SafeInventory
